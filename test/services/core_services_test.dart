import 'package:aby_pos/app/core/business_day.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:aby_pos/app/services/permission_service.dart';
import 'package:aby_pos/app/services/session_service.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BusinessDay', () {
    test('a sale after midnight belongs to the evening before', () {
      final day = BusinessDay.containing(DateTime(2026, 10, 24, 1, 30), startMinutes: 5 * 60);
      expect(day.start, DateTime(2026, 10, 23, 5));
      expect(day.end, DateTime(2026, 10, 24, 5));
      expect(day.date, DateTime(2026, 10, 23));
    });

    test('after the start time it is that day', () {
      final day = BusinessDay.containing(DateTime(2026, 10, 24, 5), startMinutes: 5 * 60);
      expect(day.start, DateTime(2026, 10, 24, 5));
      expect(day.contains(DateTime(2026, 10, 25, 4, 59)), isTrue);
      expect(day.contains(DateTime(2026, 10, 25, 5)), isFalse);
    });

    test('midnight start is the calendar day', () {
      final day = BusinessDay.containing(DateTime(2026, 12, 31, 23, 59), startMinutes: 0);
      expect(day.start, DateTime(2026, 12, 31));
      expect(day.end, DateTime(2027, 1, 1));
    });
  });

  group('PermissionService and SessionService', () {
    late AppDatabase db;
    late Repos r;
    late AuthService auth;
    late PermissionService permissions;
    late Staff kofi;
    late Staff ama;

    setUp(() async {
      Get.testMode = true;
      db = memoryDb();
      r = await Repos.open(db);
      auth = AuthService(r.staff, r.audit);
      permissions = PermissionService(auth);
      kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
    });

    tearDown(() async {
      Get.reset();
      await db.close();
    });

    test('someone with the permission authorises themselves, no prompt', () async {
      auth.signInAsNew(kofi);
      var prompted = false;
      permissions.prompter = (_, _) async {
        prompted = true;
        return null;
      };
      final result = await permissions.authorize(Permission.voidSale, reason: 'test');
      expect(result!.actor, kofi);
      expect(result.approver, isNull);
      expect(prompted, isFalse);
    });

    test('without it, the prompt brings an approver', () async {
      auth.signInAsNew(ama);
      Permission? asked;
      permissions.prompter = (p, _) async {
        asked = p;
        return kofi;
      };
      final result = await permissions.authorize(Permission.voidSale, reason: 'Void #00001');
      expect(asked, Permission.voidSale);
      expect(result!.actor, ama);
      expect(result.approver, kofi);
      expect(result.authority, kofi);
    });

    test('cancelled, or nobody signed in: not authorised', () async {
      expect(await permissions.authorize(Permission.sell, reason: 'x'), isNull);
      auth.signInAsNew(ama);
      permissions.prompter = (_, _) async => null;
      expect(await permissions.authorize(Permission.voidSale, reason: 'x'), isNull);
      permissions.prompter = null;
      expect(await permissions.authorize(Permission.voidSale, reason: 'x'), isNull);
    });

    test('the till locks after the idle time in settings, and not before', () async {
      final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
      var now = DateTime(2026, 10, 23, 12);
      final session = SessionService(auth, settings, clock: () => now);
      auth.signInAsNew(ama);
      session.touch();

      now = now.add(const Duration(minutes: 2));
      expect(await session.check(), isFalse);
      session.touch();
      now = now.add(const Duration(minutes: 3));
      expect(await session.check(), isTrue);
      expect(auth.isSignedIn, isFalse);
      expect((await r.audit.list()).first.summary, 'Till locked after no activity');

      await settings.set(AppSettings.autoLockMinutes, 0, by: kofi);
      auth.signInAsNew(ama);
      now = now.add(const Duration(hours: 5));
      expect(await session.check(), isFalse, reason: 'auto-lock off');
    });
  });
}
