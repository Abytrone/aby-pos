import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/backup/backup_codec.dart';
import 'package:aby_pos/app/services/backup/backup_service.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  group('BackupCodec', () {
    final data = Uint8List.fromList(utf8.encode('SQLite format 3\u0000 pretend database bytes'));

    test('encrypts and decrypts with the right password', () async {
      final file = await BackupCodec.encrypt(data, 'correct horse', iterations: 1000);
      expect(BackupCodec.looksLikeBackup(file), isTrue);
      expect(utf8.decode(file, allowMalformed: true), isNot(contains('pretend database')));
      expect(await BackupCodec.decrypt(file, 'correct horse'), data);
    });

    test('a wrong password fails', () async {
      final file = await BackupCodec.encrypt(data, 'correct horse', iterations: 1000);
      await expectLater(BackupCodec.decrypt(file, 'wrong horse'), throwsA(isA<BackupDecryptException>()));
    });

    test('changing any byte, header included, fails', () async {
      final file = await BackupCodec.encrypt(data, 'pw', iterations: 1000);
      for (final index in [12, 40, file.length - 20, file.length - 1]) {
        final tampered = Uint8List.fromList(file)..[index] ^= 0x01;
        await expectLater(BackupCodec.decrypt(tampered, 'pw'), throwsA(isA<BackupDecryptException>()),
            reason: 'byte $index');
      }
    });

    test('other files are rejected', () async {
      await expectLater(BackupCodec.decrypt(data, 'pw'), throwsA(isA<BackupDecryptException>()));
    });
  });

  group('BackupService', () {
    late Directory tmp;
    late AppDatabase db;
    late Repos r;
    late BackupService backups;
    late File live;
    var dbClosed = false;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('aby-backup-test');
      dbClosed = false;
      db = memoryDb();
      r = await Repos.open(db);
      final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
      live = File(p.join(tmp.path, 'live', 'aby_pos.sqlite'));
      await live.parent.create();
      backups = BackupService(
        db,
        r.audit,
        settings,
        backupsDirectory: () async => Directory(p.join(tmp.path, 'backups')),
        tempDirectory: () async => tmp,
        liveDatabaseFile: () async => live,
        iterations: 1000,
      );
      final waffle = (await CatalogRepository(db).products()).firstWhere((x) => x.name == 'Waffle');
      await r.sales.completeSale(
        lines: [CartLine(product: waffle, quantity: 2)],
        payment: const PaymentInput.cash(tendered: 2400),
        cashier: cashier,
      );
    });

    tearDown(() async {
      if (!dbClosed) await db.close();
      await tmp.delete(recursive: true);
    });

    test('a local backup is a checked copy, recorded in meta and the activity log', () async {
      final backup = await backups.createLocalBackup(by: owner);
      expect(await backup.file.exists(), isTrue);
      expect(await backups.lastLocalBackupAt(), isNotNull);

      final preview = await backups.inspectFile(backup.file);
      expect(preview.shopName, 'Scoops Tamale');
      expect(preview.salesCount, 1);
      expect(preview.schemaVersion, db.schemaVersion);
      expect((await r.audit.list()).first.action, AuditAction.backupCreated);
    });

    test('only the newest backups are kept', () async {
      await db.writeSettingRow(AppSettings.backupsToKeep.key, AppSettings.backupsToKeep.scope, '2', r.device.deviceId);
      final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
      final keeping = BackupService(db, r.audit, settings,
          backupsDirectory: () async => Directory(p.join(tmp.path, 'backups')),
          tempDirectory: () async => tmp,
          liveDatabaseFile: () async => live,
          iterations: 1000);
      for (var i = 0; i < 3; i++) {
        await keeping.createLocalBackup(record: false);
        await Future<void>.delayed(const Duration(milliseconds: 5)); // distinct file names
      }
      expect(await keeping.listLocalBackups(), hasLength(2));
    });

    test('the daily backup runs once, then waits', () async {
      expect(await backups.autoBackupIfDue(), isNotNull);
      expect(await backups.autoBackupIfDue(), isNull);
    });

    test('off-device backups need the backup password and are encrypted', () async {
      expect(await backups.hasBackupPassword(), isFalse);
      await expectLater(backups.setBackupPassword('short'), throwsA(isA<BackupException>()));
      await backups.setBackupPassword('tamale-2026');
      await expectLater(
        backups.exportEncrypted(password: 'nope', shopName: 'Scoops Tamale', by: owner),
        throwsA(isA<BackupException>()),
      );
      final file = await backups.exportEncrypted(password: 'tamale-2026', shopName: 'Scoops Tamale', by: owner);
      expect(p.basename(file.path), startsWith('Scoops-Tamale-'));
      expect(p.extension(file.path), '.abybak');

      await expectLater(backups.inspectFile(file, password: 'nope'), throwsA(isA<BackupDecryptException>()));
      final preview = await backups.inspectFile(file, password: 'tamale-2026');
      expect(preview.salesCount, 1);

      expect(await backups.lastOffsiteBackupAt(), isNull, reason: 'only once it has left the device');
      await backups.markOffsiteDone(where: 'share', by: owner);
      expect(await backups.lastOffsiteBackupAt(), isNotNull);
    });

    test('a file that is not a database is refused', () async {
      final junk = File(p.join(tmp.path, 'junk.sqlite'))..writeAsStringSync('hello');
      await expectLater(backups.inspectFile(junk), throwsA(isA<BackupException>()));
    });

    test('restore replaces the live database, keeps a safety copy, and is recorded after restart', () async {
      await backups.setBackupPassword('tamale-2026');
      final exported = await backups.exportEncrypted(password: 'tamale-2026', shopName: 'Scoops Tamale', by: owner);
      final preview = await backups.inspectFile(exported, password: 'tamale-2026');
      final before = (await backups.listLocalBackups()).length;

      await backups.restore(preview, by: owner);
      dbClosed = true; // restore closes it; the app restarts to reopen
      expect(await live.exists(), isTrue);
      expect((await backups.listLocalBackups()).length, before + 1, reason: 'safety copy');

      // What the app does after restarting.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final reopened = AppDatabase(NativeDatabase(live), false);
      final again = await Repos.open(reopened);
      final settings = SettingsService(SettingsRepository(reopened, again.device, again.audit));
      await settings.load();
      final service = BackupService(reopened, again.audit, settings,
          backupsDirectory: () async => Directory(p.join(tmp.path, 'backups')),
          tempDirectory: () async => tmp,
          liveDatabaseFile: () async => live);
      await service.finishPendingRestore();
      await service.finishPendingRestore(); // only once

      final entries = await again.audit.list(actions: {AuditAction.backupRestored});
      expect(entries.single.actorName, 'Kofi');
      expect(entries.single.summary, contains('1 sales'));
      final sales = await reopened.select(reopened.sales).get();
      expect(sales, hasLength(1));
      expect((await again.audit.verifyChain()).isIntact, isTrue);
      await reopened.close();
    });
  });
}
