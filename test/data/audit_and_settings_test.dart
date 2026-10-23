import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/audit_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
  });

  tearDown(() => db.close());

  group('Audit log', () {
    Future<void> recordThree() async {
      await r.audit.record(action: AuditAction.signedIn, actor: owner, summary: 'Kofi signed in');
      await r.audit.record(
        action: AuditAction.saleVoided,
        actor: cashier,
        approver: owner,
        entity: 'sales',
        entityId: 's1',
        summary: 'Voided #00001',
      );
      await r.audit.record(
        action: AuditAction.settingChanged,
        actor: owner,
        summary: 'Changed shop.name',
        details: {'before': 'A', 'after': 'B'},
      );
    }

    test('entries chain by hash and the chain checks out', () async {
      await recordThree();
      final rows = await (db.select(db.auditLog)..orderBy([(a) => OrderingTerm(expression: a.seq)])).get();
      expect(rows.map((e) => e.seq), [1, 2, 3]);
      expect(rows.first.prevHash, AuditRepository.genesisHash);
      expect(rows[1].prevHash, rows[0].hash);
      expect(rows[2].prevHash, rows[1].hash);
      expect((await r.audit.verifyChain()).isIntact, isTrue);

      final entries = await r.audit.list();
      expect(entries.first.action, AuditAction.settingChanged, reason: 'newest first');
      expect(entries.first.details, {'before': 'A', 'after': 'B'});
      expect(entries[1].approverName, 'Kofi');
    });

    test('editing an entry in the database breaks the chain at that entry', () async {
      await recordThree();
      await db.customStatement("UPDATE audit_log SET summary = 'Nothing happened' WHERE seq = 2");
      final status = await r.audit.verifyChain();
      expect(status.isIntact, isFalse);
      expect(status.brokenAtSeq, 2);
    });

    test('deleting an entry breaks the chain', () async {
      await recordThree();
      await db.customStatement('DELETE FROM audit_log WHERE seq = 2');
      expect((await r.audit.verifyChain()).brokenAtSeq, 3);
    });

    test('changing who approved breaks the chain', () async {
      await recordThree();
      await db.customStatement("UPDATE audit_log SET approver_name = 'Ama' WHERE seq = 2");
      expect((await r.audit.verifyChain()).isIntact, isFalse);
    });

    test('each device keeps its own chain', () async {
      await recordThree();
      final other = AuditRepository(db, FakeDevice('other-device'));
      await other.record(action: AuditAction.signedIn, summary: 'On the other till');
      final rows = await (db.select(db.auditLog)..where((a) => a.deviceId.equals('other-device'))).get();
      expect(rows.single.seq, 1);
      expect(rows.single.prevHash, AuditRepository.genesisHash);
      expect((await r.audit.verifyChain()).isIntact, isTrue);
    });

    test('filters by person and action', () async {
      await recordThree();
      expect(await r.audit.list(actorId: cashier.id), hasLength(1));
      expect(await r.audit.list(actorId: owner.id), hasLength(3), reason: 'includes approvals');
      expect(await r.audit.list(actions: {AuditAction.signedIn}), hasLength(1));
    });
  });

  group('Settings', () {
    late SettingsService settings;

    setUp(() async {
      settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
    });

    test('reads the seeded shop name and defaults', () {
      expect(settings.get(AppSettings.shopName), 'Scoops Tamale');
      expect(settings.get(AppSettings.autoLockMinutes), 3);
      expect(settings.get(AppSettings.businessDayStart), 300);
      expect(settings.get(AppSettings.themeMode), 'system');
    });

    test('saves, reloads, and records the change with before and after', () async {
      await settings.set(AppSettings.autoLockMinutes, 10, by: owner);
      final fresh = SettingsService(SettingsRepository(db, r.device, r.audit));
      await fresh.load();
      expect(fresh.get(AppSettings.autoLockMinutes), 10);

      final entry = (await r.audit.list()).single;
      expect(entry.action, AuditAction.settingChanged);
      expect(entry.details, {'before': 3, 'after': 10});
      expect(entry.actorName, 'Kofi');
    });

    test('saving the same value does nothing', () async {
      await settings.set(AppSettings.autoLockMinutes, 3, by: owner);
      await settings.set(AppSettings.autoLockMinutes, 5, by: owner);
      await settings.set(AppSettings.autoLockMinutes, 5, by: owner);
      expect(await r.audit.list(), hasLength(1));
    });

    test('device settings stay on their device; shop settings are shared', () async {
      await settings.set(AppSettings.deviceName, 'Front counter', by: owner);
      await settings.set(AppSettings.shopPhone, '0244000000', by: owner);
      final other = SettingsService(SettingsRepository(db, FakeDevice('other-device'), r.audit));
      await other.load();
      expect(other.get(AppSettings.deviceName), '', reason: 'device setting not shared');
      expect(other.get(AppSettings.shopPhone), '0244000000');
    });

    test('a stored value of the wrong type falls back to the default', () async {
      await db.writeSettingRow('security.autoLockMinutes', SettingScope.shop, '"soon"', r.device.deviceId);
      await settings.load();
      expect(settings.get(AppSettings.autoLockMinutes), 3);
    });
  });
}
