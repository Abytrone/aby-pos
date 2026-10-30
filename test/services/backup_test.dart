import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/backup/backup_codec.dart';
import 'package:aby_pos/app/services/backup/backup_service.dart';
import 'package:aby_pos/app/services/hub/hub_service.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:aby_pos/app/services/training_service.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Value;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

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

    test('a header with bad fields is reported as damaged, not a crash', () async {
      Uint8List withHeader(Map<String, Object?> header) {
        final h = utf8.encode(jsonEncode(header));
        return (BytesBuilder()
              ..add(ascii.encode('ABYBAK1\n'))
              ..add((ByteData(4)..setUint32(0, h.length)).buffer.asUint8List())
              ..add(h)
              ..add(List.filled(32, 0)))
            .toBytes();
      }

      const ok = {'alg': 'pbkdf2-hmac-sha256', 'iterations': 1000, 'salt': 'AAAAAAAAAAAAAAAAAAAAAA=='};
      for (final header in [
        {'format': 'aby-backup', 'version': 1},
        {'format': 'aby-backup', 'version': 1, 'kdf': {...ok, 'salt': 'not base64!'}, 'cipher': {'nonce': 'AAAAAAAAAAAAAAAA'}},
        {'format': 'aby-backup', 'version': 1, 'kdf': {...ok, 'iterations': 'many'}, 'cipher': {'nonce': 'AAAAAAAAAAAAAAAA'}},
        {'format': 'aby-backup', 'version': 1, 'kdf': {...ok, 'iterations': 1 << 40}, 'cipher': {'nonce': 'AAAAAAAAAAAAAAAA'}},
        {'format': 'aby-backup', 'version': 1, 'kdf': ok, 'cipher': {'nonce': 'AAAA'}},
      ]) {
        await expectLater(BackupCodec.decrypt(withHeader(header), 'pw'), throwsA(isA<BackupDecryptException>()),
            reason: '$header');
      }
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
      final waffle = (await r.catalog.products()).firstWhere((x) => x.name == 'Waffle');
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

    test('the oldest backup restores even when the safety copy prunes it', () async {
      await db.writeSettingRow(AppSettings.backupsToKeep.key, AppSettings.backupsToKeep.scope, '2', r.device.deviceId);
      final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
      final keeping = BackupService(db, r.audit, settings,
          backupsDirectory: () async => Directory(p.join(tmp.path, 'backups')),
          tempDirectory: () async => tmp,
          liveDatabaseFile: () async => live,
          iterations: 1000);
      await keeping.createLocalBackup(record: false);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await keeping.createLocalBackup(record: false);
      final oldest = (await keeping.listLocalBackups()).last;

      await keeping.restore(await keeping.inspectFile(oldest.file), by: owner);
      dbClosed = true;
      expect(await oldest.file.exists(), isFalse, reason: 'pruned by the safety copy');
      expect(keeping.closedForRestore, isTrue);
      final restored = sqlite3.open(live.path, mode: OpenMode.readOnly);
      try {
        expect(restored.select('SELECT COUNT(*) AS n FROM sales').first['n'], 1);
      } finally {
        restored.close();
      }
      expect(await File('${live.path}.restoring').exists(), isFalse);
    });

    test('restore leaves the backup file as it was and drops training flags', () async {
      await db.writeMeta(TrainingService.metaKey, '1'); // a training copy's backup
      final backup = await backups.createLocalBackup(record: false);
      final before = await backup.file.readAsBytes();

      await backups.restore(await backups.inspectFile(backup.file), by: owner);
      dbClosed = true;
      expect(await backup.file.readAsBytes(), before);
      final restored = sqlite3.open(live.path, mode: OpenMode.readOnly);
      try {
        expect(restored.select('SELECT 1 FROM meta WHERE key = ?', [TrainingService.metaKey]), isEmpty);
      } finally {
        restored.close();
      }
    });

    test('a backup is dated by its name', () async {
      final backup = await backups.createLocalBackup(record: false);
      await backup.file.setLastModified(DateTime(2001));
      final listed = (await backups.listLocalBackups()).single;
      expect(listed.createdAt.difference(backup.createdAt).inSeconds.abs(), lessThan(1));
    });

    test('a decrypted copy is deleted when discarded, a local file is not', () async {
      await backups.setBackupPassword('tamale-2026');
      final exported = await backups.exportEncrypted(password: 'tamale-2026', shopName: 'Scoops Tamale', by: owner);
      final preview = await backups.inspectFile(exported, password: 'tamale-2026');
      expect(preview.temporary, isTrue);
      await backups.discard(preview);
      expect(await File(preview.databasePath).exists(), isFalse);

      final local = (await backups.listLocalBackups()).first;
      final plain = await backups.inspectFile(local.file);
      await backups.discard(plain);
      expect(await local.file.exists(), isTrue);
    });

    group("another device's backup", () {
      late File backup;

      setUp(() async {
        // A backup made on another device, which synced with a hub.
        backup = (await backups.createLocalBackup(record: false)).file;
        final other = sqlite3.open(backup.path);
        try {
          other.execute("UPDATE meta SET value = 'other-device' WHERE key = ?", [MetaKeys.deviceId]);
          for (final (k, v) in [('hub.role', 'member'), ('hub.secret', 'theirs'), ('hub.cursor', '99'), ('hub.epoch', 'e1')]) {
            other.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [k, v]);
          }
        } finally {
          other.close();
        }
        // This device is the hub, and has revoked a lost till.
        await db.writeMeta('hub.role', 'hub');
        await db.into(db.hubDevices).insert(HubDevicesCompanion.insert(
              deviceId: 'lost-till',
              name: 'Lost till',
              secret: 's',
              pairedAt: DateTime(2026),
              revokedAt: Value(DateTime(2026, 2)),
            ));
      });

      String? meta(Database d, String key) =>
          d.select('SELECT value FROM meta WHERE key = ?', [key]).firstOrNull?['value'] as String?;

      test('is asked about, and by default this device stays itself', () async {
        final preview = await backups.inspectFile(backup);
        expect(preview.fromThisDevice, isFalse);
        expect(preview.linked, isTrue);

        await backups.restore(preview, by: owner);
        dbClosed = true;
        final restored = sqlite3.open(live.path, mode: OpenMode.readOnly);
        try {
          expect(meta(restored, MetaKeys.deviceId), r.device.deviceId);
          expect(meta(restored, 'hub.role'), 'hub');
          expect(meta(restored, 'hub.secret'), isNull, reason: 'not the backup link');
          expect(meta(restored, HubService.epochKey), isNull, reason: 'a new log generation');
          expect(meta(restored, HubService.resyncKey), '1');
          final devices = restored.select('SELECT device_id, revoked_at FROM hub_devices');
          expect(devices.single['device_id'], 'lost-till');
          expect(devices.single['revoked_at'], isNotNull, reason: 'still revoked');
        } finally {
          restored.close();
        }
      });

      test('replacing that device takes its identity and hub link', () async {
        await backups.restore(await backups.inspectFile(backup), by: owner, replacing: true);
        dbClosed = true;
        final restored = sqlite3.open(live.path, mode: OpenMode.readOnly);
        try {
          expect(meta(restored, MetaKeys.deviceId), 'other-device');
          expect(meta(restored, 'hub.role'), 'member');
          expect(meta(restored, 'hub.secret'), 'theirs');
          expect(meta(restored, HubService.cursorKey), '0', reason: 'pulls everything again');
          expect(meta(restored, HubService.resyncKey), '1');
        } finally {
          restored.close();
        }
      });
    });

    group('in training', () {
      setUp(() => Get.put(TrainingService(db))..active.value = true);
      tearDown(() => Get.delete<TrainingService>(force: true));

      test('nothing is backed up or restored', () async {
        expect(await backups.autoBackupIfDue(), isNull);
        await expectLater(backups.createLocalBackup(), throwsA(isA<BackupException>()));
        Get.find<TrainingService>().active.value = false;
        final backup = await backups.createLocalBackup(record: false);
        final preview = await backups.inspectFile(backup.file);
        Get.find<TrainingService>().active.value = true;

        await expectLater(backups.restore(preview, by: owner), throwsA(isA<BackupException>()));
        expect(await live.exists(), isFalse, reason: 'the real data is untouched');
        expect(backups.closedForRestore, isFalse);
      });
    });
  });
}
