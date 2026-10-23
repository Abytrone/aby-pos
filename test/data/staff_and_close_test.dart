import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/role_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late RoleRepository roles;
  late Product waffle;

  Future<int> outboxFor(String entity) async {
    final rows = await (db.select(db.outbox)..where((o) => o.entity.equals(entity))).get();
    return rows.length;
  }

  Future<CompletedSale> sell({int quantity = 1, PaymentInput? payment}) => r.sales.completeSale(
        lines: [CartLine(product: waffle, quantity: quantity)],
        payment: payment ?? PaymentInput.cash(tendered: 1200 * quantity),
        cashier: cashier,
      );

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    roles = RoleRepository(db, r.device, r.audit);
    waffle = (await CatalogRepository(db).products()).firstWhere((p) => p.name == 'Waffle');
  });

  tearDown(() => db.close());

  group('Roles', () {
    test('a new database has the four built-in roles', () async {
      final list = await roles.list();
      expect(list.map((x) => x.builtIn), BuiltInRole.values);
      final cashierRow = list.firstWhere((x) => x.builtIn == BuiltInRole.cashier);
      expect(cashierRow.permissions, BuiltInRole.cashier.defaultPermissions);
      expect(list.first.allows(Permission.restoreBackup), isTrue, reason: 'owner allows everything');
    });

    test('custom roles can be created, changed and deleted, with audit entries', () async {
      final shift = await roles.create(
        name: 'Shift lead',
        permissions: {Permission.sell, Permission.voidSale},
        maxDiscountPercent: 20,
        by: owner,
      );
      await roles.update(shift.id,
          name: 'Shift lead', permissions: {Permission.sell}, maxDiscountPercent: 15, by: owner);
      final updated = (await roles.list()).firstWhere((x) => x.id == shift.id);
      expect(updated.permissions, {Permission.sell});
      expect(updated.maxDiscountPercent, 15);

      await roles.delete(shift.id, by: owner);
      expect((await roles.list()).any((x) => x.id == shift.id), isFalse);
      final actions = (await r.audit.list()).map((e) => e.action);
      expect(actions, containsAll([AuditAction.roleCreated, AuditAction.roleUpdated, AuditAction.roleDeleted]));
    });

    test('the Owner role cannot be changed and built-ins cannot be deleted', () async {
      await expectLater(
        roles.update(BuiltInRole.owner.id, name: 'Boss', permissions: {}, maxDiscountPercent: 0, by: owner),
        throwsA(isA<StaffException>()),
      );
      await expectLater(roles.delete(BuiltInRole.cashier.id, by: owner), throwsA(isA<StaffException>()));
    });

    test('a role in use cannot be deleted', () async {
      final custom = await roles.create(name: 'Helper', permissions: {Permission.sell}, maxDiscountPercent: 0, by: owner);
      await r.staff.create(name: 'Yaw', roleId: custom.id, pin: '4444', by: owner);
      await expectLater(roles.delete(custom.id, by: owner), throwsA(isA<StaffException>()));
    });
  });

  group('StaffRepository', () {
    test('creates staff with a hashed PIN, outbox row and audit entry', () async {
      expect(await r.staff.hasStaff(), isFalse);
      final kofi = await r.staff.create(name: ' Kofi ', roleId: BuiltInRole.owner.id, pin: '1234');
      expect(kofi.name, 'Kofi');
      expect(kofi.isOwner, isTrue);
      expect(await r.staff.verifyPin(kofi.id, '1234'), isTrue);
      expect(await r.staff.verifyPin(kofi.id, '4321'), isFalse);

      final row = await db.select(db.staffMembers).getSingle();
      expect(row.pinHash, isNot(contains('1234')));
      expect(await outboxFor('staff'), 1);
      expect((await r.audit.list()).single.action, AuditAction.staffAdded);
    });

    test('active staff cannot share a PIN', () async {
      await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      await expectLater(
        r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '1234', by: owner),
        throwsA(isA<StaffException>()),
      );
    });

    test('approverWithPin finds active people who hold the permission', () async {
      final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      final esi = await r.staff.create(name: 'Esi', roleId: BuiltInRole.manager.id, pin: '2222', by: kofi);
      await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
      expect(await r.staff.approverWithPin('1234', Permission.voidSale), kofi);
      expect(await r.staff.approverWithPin('2222', Permission.voidSale), esi);
      expect(await r.staff.approverWithPin('2222', Permission.restoreBackup), isNull,
          reason: 'managers cannot restore by default');
      expect(await r.staff.approverWithPin('5678', Permission.voidSale), isNull, reason: 'cashier');
    });

    test('the last active owner stays an owner and stays active', () async {
      final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      final ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
      await r.staff.setActive(ama.id, active: false, by: kofi);
      expect(await r.staff.verifyPin(ama.id, '5678'), isFalse);
      expect((await r.staff.list()).map((s) => s.name), ['Kofi']);
      expect(await r.staff.list(includeInactive: true), hasLength(2));
      await expectLater(r.staff.setActive(kofi.id, active: false, by: kofi), throwsA(isA<StaffException>()));
      await expectLater(r.staff.changeRole(kofi.id, BuiltInRole.cashier.id, by: kofi),
          throwsA(isA<StaffException>()));
    });

    test('changeRole and changePin are recorded', () async {
      final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      final ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
      await r.staff.changeRole(ama.id, BuiltInRole.manager.id, by: kofi);
      expect((await r.staff.find(ama.id))!.role.builtIn, BuiltInRole.manager);
      await r.staff.changePin(ama.id, '9999', by: kofi);
      expect(await r.staff.verifyPin(ama.id, '9999'), isTrue);
      final actions = (await r.audit.list()).map((e) => e.action);
      expect(actions, containsAll([AuditAction.staffRoleChanged, AuditAction.staffPinChanged]));
    });
  });

  group('AuthService', () {
    test('locks a person out after too many wrong PINs, and records it', () async {
      var now = DateTime(2026, 10, 23, 9);
      final auth = AuthService(r.staff, r.audit, clock: () => now);
      final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      final ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);

      for (var i = 1; i < AuthService.maxAttempts; i++) {
        expect(await auth.signIn(ama, '0000'), SignInResult.wrongPin);
      }
      expect(await auth.signIn(ama, '0000'), SignInResult.lockedOut);
      expect(await auth.signIn(ama, '5678'), SignInResult.lockedOut,
          reason: 'even the right PIN waits out the lockout');

      now = now.add(AuthService.lockout);
      expect(await auth.signIn(ama, '5678'), SignInResult.ok);
      expect(auth.user, ama);
      expect(auth.can(Permission.voidSale), isFalse);
      expect(auth.can(Permission.sell), isTrue);

      final actions = (await r.audit.list()).map((e) => e.action).toList();
      expect(actions.where((a) => a == AuditAction.signInFailed), hasLength(AuthService.maxAttempts - 1));
      expect(actions, containsAll([AuditAction.lockedOut, AuditAction.signedIn]));

      await auth.lock();
      expect(auth.isSignedIn, isFalse);
    });

    test('approval takes the PIN of someone with the permission and locks out guessing', () async {
      final auth = AuthService(r.staff, r.audit);
      final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      expect(await auth.approveWithPin('1234', Permission.voidSale), kofi);
      for (var i = 1; i < AuthService.maxAttempts; i++) {
        expect(await auth.approveWithPin('0000', Permission.voidSale), isNull);
      }
      await expectLater(auth.approveWithPin('0000', Permission.voidSale), throwsA(isA<LockedOutException>()));
      await expectLater(auth.approveWithPin('1234', Permission.voidSale), throwsA(isA<LockedOutException>()));
    });
  });

  group('DayCloseRepository', () {
    test('open period adds up completed sales by method', () async {
      await sell(quantity: 2);
      await sell(payment: const PaymentInput.momo(momoReference: 'MP1'));
      final voided = await sell();
      await r.sales.voidSale(voided.saleId, actor: owner);

      final period = await r.closes.openPeriod();
      expect(period.from, isNull);
      expect(period.salesCount, 2);
      expect(period.voidedCount, 1);
      expect(period.salesTotal, 3600);
      expect(period.cashTakings, 2400);
      expect(period.byMethod[PaymentMethod.momo], 1200);
      expect(period.expectedCash(5000), 7400);
    });

    test('closeDay records the count, the audit entry, and starts an empty period', () async {
      await sell(quantity: 2);
      final close = await r.closes.closeDay(
        openingFloat: 5000,
        countedCash: 7300,
        closedBy: owner,
        note: ' One note missing ',
      );
      expect(close.expectedCash, 7400);
      expect(close.difference, -100);
      expect(close.note, 'One note missing');
      expect(close.closedByName, 'Kofi');
      expect(await outboxFor('day_closes'), 1);
      expect((await r.audit.list()).first.summary, contains('short GH₵ 1.00'));

      final next = await r.closes.openPeriod();
      expect(next.from, close.closedAt);
      expect(next.salesCount, 0);
      expect(next.suggestedFloat, 5000);

      await sell();
      expect((await r.closes.openPeriod()).salesCount, 1);
      expect((await r.closes.history()).single.id, close.id);
    });

    test('sales in a closed day cannot be voided; later ones can', () async {
      final early = await sell();
      await r.closes.closeDay(openingFloat: 0, countedCash: 1200, closedBy: owner);
      final late = await sell();

      await expectLater(r.sales.voidSale(early.saleId, actor: owner), throwsA(isA<SaleException>()));
      await r.sales.voidSale(late.saleId, actor: owner);
    });

    test('an empty close keeps the previous boundary', () async {
      final first = await sell();
      await r.closes.closeDay(openingFloat: 0, countedCash: 1200, closedBy: owner);
      await r.closes.closeDay(openingFloat: 0, countedCash: 0, closedBy: owner);
      expect(await r.closes.closedUpTo(), first.number);
    });
  });
}
