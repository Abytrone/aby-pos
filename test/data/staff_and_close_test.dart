import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/day_close_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late FakeDevice device;
  late StaffRepository staff;
  late DayCloseRepository closes;
  late SaleRepository sales;
  late Product waffle;

  Future<int> outboxFor(String entity) async {
    final rows = await (db.select(db.outbox)..where((o) => o.entity.equals(entity))).get();
    return rows.length;
  }

  Future<CompletedSale> sell({int quantity = 1, PaymentInput? payment}) => sales.completeSale(
        lines: [CartLine(product: waffle, quantity: quantity)],
        payment: payment ?? PaymentInput.cash(tendered: 1200 * quantity),
        cashier: cashier,
      );

  setUp(() async {
    db = memoryDb();
    device = FakeDevice((await db.readMeta(MetaKeys.deviceId))!);
    staff = StaffRepository(db, device);
    closes = DayCloseRepository(db, device);
    sales = SaleRepository(db, StockRepository(db, device), closes, device);
    waffle = (await CatalogRepository(db).products()).firstWhere((p) => p.name == 'Waffle');
  });

  tearDown(() => db.close());

  group('StaffRepository', () {
    test('creates staff with a hashed PIN and an outbox row', () async {
      expect(await staff.hasStaff(), isFalse);
      final kofi = await staff.create(name: ' Kofi ', role: StaffRole.owner, pin: '1234');
      expect(kofi.name, 'Kofi');
      expect(await staff.hasStaff(), isTrue);
      expect(await staff.verifyPin(kofi.id, '1234'), isTrue);
      expect(await staff.verifyPin(kofi.id, '4321'), isFalse);

      final row = await db.select(db.staffMembers).getSingle();
      expect(row.pinHash, isNot(contains('1234')));
      expect(await outboxFor('staff'), 1);
    });

    test('active staff cannot share a PIN', () async {
      await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
      await expectLater(
        staff.create(name: 'Ama', role: StaffRole.cashier, pin: '1234'),
        throwsA(isA<StaffException>()),
      );
    });

    test('ownerWithPin finds active owners only', () async {
      final kofi = await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
      await staff.create(name: 'Ama', role: StaffRole.cashier, pin: '5678');
      expect(await staff.ownerWithPin('1234'), kofi);
      expect(await staff.ownerWithPin('5678'), isNull, reason: 'cashier');
    });

    test('deactivated staff cannot sign in; the last owner stays', () async {
      final kofi = await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
      final ama = await staff.create(name: 'Ama', role: StaffRole.cashier, pin: '5678');
      await staff.setActive(ama.id, active: false);
      expect(await staff.verifyPin(ama.id, '5678'), isFalse);
      expect((await staff.list()).map((s) => s.name), ['Kofi']);
      expect((await staff.list(includeInactive: true)), hasLength(2));
      await expectLater(staff.setActive(kofi.id, active: false), throwsA(isA<StaffException>()));
    });

    test('changePin replaces the PIN and queues an update', () async {
      final kofi = await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
      await staff.changePin(kofi.id, '9999');
      expect(await staff.verifyPin(kofi.id, '1234'), isFalse);
      expect(await staff.verifyPin(kofi.id, '9999'), isTrue);
      expect(await outboxFor('staff'), 2);
    });
  });

  group('AuthService', () {
    test('locks a person out after too many wrong PINs', () async {
      var now = DateTime(2026, 10, 23, 9);
      final auth = AuthService(staff, clock: () => now);
      final ama = await staff.create(name: 'Ama', role: StaffRole.cashier, pin: '5678');

      for (var i = 1; i < AuthService.maxAttempts; i++) {
        expect(await auth.signIn(ama, '0000'), SignInResult.wrongPin);
      }
      expect(await auth.signIn(ama, '0000'), SignInResult.lockedOut);
      expect(await auth.signIn(ama, '5678'), SignInResult.lockedOut,
          reason: 'even the right PIN waits out the lockout');

      now = now.add(AuthService.lockout);
      expect(await auth.signIn(ama, '5678'), SignInResult.ok);
      expect(auth.user, ama);
      expect(auth.isOwner, isFalse);
    });

    test('owner approval takes owner PINs and locks out guessing', () async {
      final auth = AuthService(staff);
      final kofi = await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
      expect(await auth.approveAsOwner('1234'), kofi);
      for (var i = 1; i < AuthService.maxAttempts; i++) {
        expect(await auth.approveAsOwner('0000'), isNull);
      }
      await expectLater(auth.approveAsOwner('0000'), throwsA(isA<LockedOutException>()));
      await expectLater(auth.approveAsOwner('1234'), throwsA(isA<LockedOutException>()));
    });
  });

  group('DayCloseRepository', () {
    test('open period adds up completed sales by method', () async {
      await sell(quantity: 2);
      await sell(payment: const PaymentInput.momo(momoReference: 'MP1'));
      final voided = await sell();
      await sales.voidSale(voided.saleId, by: owner);

      final period = await closes.openPeriod();
      expect(period.from, isNull);
      expect(period.salesCount, 2);
      expect(period.voidedCount, 1);
      expect(period.salesTotal, 3600);
      expect(period.cashTakings, 2400);
      expect(period.byMethod[PaymentMethod.momo], 1200);
      expect(period.expectedCash(5000), 7400);
    });

    test('closeDay records the count and the next period starts empty', () async {
      await sell(quantity: 2);
      final close = await closes.closeDay(
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

      final next = await closes.openPeriod();
      expect(next.from, close.closedAt);
      expect(next.salesCount, 0);
      expect(next.suggestedFloat, 5000);

      await sell();
      expect((await closes.openPeriod()).salesCount, 1);
      expect((await closes.history()).single.id, close.id);
    });

    test('sales in a closed day cannot be voided; later ones can', () async {
      final early = await sell();
      await closes.closeDay(openingFloat: 0, countedCash: 1200, closedBy: owner);
      final late = await sell();

      await expectLater(
        sales.voidSale(early.saleId, by: owner),
        throwsA(isA<SaleException>()),
      );
      await sales.voidSale(late.saleId, by: owner);
    });

    test('an empty close keeps the previous boundary', () async {
      final first = await sell();
      await closes.closeDay(openingFloat: 0, countedCash: 1200, closedBy: owner);
      await closes.closeDay(openingFloat: 0, countedCash: 0, closedBy: owner);
      expect(await closes.closedUpTo(), first.number);
    });
  });
}
