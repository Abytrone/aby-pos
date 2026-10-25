import 'dart:typed_data';

import 'package:aby_pos/app/core/denominations.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/safe_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);

  Future<void> sellCash(String product) => r.sales.completeSale(
        lines: [CartLine(product: named(product))],
        payments: [const PaymentInput.cash(tendered: 100000)],
        cashier: cashier,
      );

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
  });
  tearDown(() => db.close());

  test('a cash count adds up and keeps its breakdown', () {
    const count = CashCount({20000: 1, 2000: 3, 50: 4});
    expect(count.total, 20000 + 6000 + 200);
    expect(CashCount.fromJson(count.toJson()).pieces, {20000: 1, 2000: 3, 50: 4});
    expect(count.withCount(2000, -1).pieces[2000], 0);
    expect(denominationLabel(20000), 'GH₵ 200');
    expect(denominationLabel(50), '50p');
  });

  group('Shifts', () {
    test('one open shift; close day uses its float and closes it', () async {
      await r.shifts.open(float: 5000, count: const CashCount({2000: 2, 1000: 1}), by: cashier);
      await expectLater(r.shifts.open(float: 100, by: cashier), throwsA(isA<StateError>()));
      await sellCash('Waffle');

      final period = await r.closes.openPeriod();
      expect(period.shiftFloat, 5000);
      expect(period.shiftOpenedBy, 'Ama');
      expect(period.expectedCash(5000), 6200);

      final close = await r.closes.closeDay(
        openingFloat: period.shiftFloat!,
        countedCash: 6100,
        cashCount: const CashCount({5000: 1, 1000: 1, 100: 1}),
        varianceReason: 'Gave too much change',
        closedBy: cashier,
      );
      expect(close.difference, -100);
      expect(close.floatCount.total, 5000);
      expect(close.cashCount.total, 6100);
      expect(close.varianceReason, 'Gave too much change');
      expect(await r.shifts.current(), isNull);
      expect((await r.closes.varianceByPerson())['Ama'], (1, 100, 0));
    });
  });

  group('Pay in, pay out, safe', () {
    test('cash in and out moves what the drawer should hold, with a photo', () async {
      await sellCash('Waffle'); // 12.00
      await r.cashEvents.payInOrOut(payIn: true, amount: 5000, reason: 'Change from the bank', actor: owner);
      await r.cashEvents.payInOrOut(
        payIn: false,
        amount: 2000,
        reason: 'Ice',
        note: 'Mr Issah',
        photo: Uint8List.fromList([1, 2, 3]),
        actor: cashier,
        approver: owner,
      );
      final period = await r.closes.openPeriod();
      expect(period.payIns, 5000);
      expect(period.payOuts, 2000);
      expect(period.expectedCash(1000), 1000 + 1200 + 5000 - 2000);

      final events = await r.cashEvents.since(null);
      final out = events.firstWhere((e) => e.kind == CashEventKind.payOut);
      expect(out.amount, -2000);
      expect(out.hasPhoto, isTrue);
      expect(await r.cashEvents.photo(out.id), [1, 2, 3]);
      expect((await r.audit.list(actions: {AuditAction.cashPaidOut})).single.approverName, 'Kofi');
    });

    test('a safe drop leaves the drawer and enters the safe; deposits leave the safe', () async {
      await sellCash('Milkshake'); // 20.00
      await r.safe.drop(1500, actor: cashier, approver: owner);
      expect(await r.safe.balance(), 1500);
      final period = await r.closes.openPeriod();
      expect(period.safeDrops, 1500);
      expect(period.expectedCash(0), 500);

      await expectLater(r.safe.deposit(2000, bank: 'GCB', by: owner), throwsA(isA<SafeException>()));
      await expectLater(r.safe.deposit(500, bank: ' ', by: owner), throwsA(isA<SafeException>()));
      await r.safe.deposit(1000, bank: 'GCB Tamale', reference: 'SL-88', slip: Uint8List.fromList([9]), by: owner);
      expect(await r.safe.balance(), 500);
      final entries = await r.safe.entries();
      expect(entries.first.kind, SafeEntryKind.deposit);
      expect(entries.first.bank, 'GCB Tamale');
      expect(await r.cashEvents.photo(entries.first.id), [9]);
      expect(await r.audit.list(actions: {AuditAction.bankDeposit}), hasLength(1));

      final close = await r.closes.closeDay(openingFloat: 0, countedCash: 500, closedBy: owner);
      expect(close.difference, 0);
      expect(close.safeDrops, 1500);
    });
  });

  group('MoMo check', () {
    test('sale payments and customer repayments by MoMo, ticked or flagged, with charges', () async {
      final momo = (await r.payMethods.list()).firstWhere((m) => m.name == 'MTN MoMo');
      await r.sales.completeSale(
        lines: [CartLine(product: named('Waffle'))],
        payments: [PaymentInput.from(momo, reference: 'MP-1')],
        cashier: cashier,
      );
      final id = await r.customers.save(const CustomerDraft(name: 'Ama'), by: owner);
      final ama = (await r.customers.find(id))!;
      await r.sales.completeSale(
        lines: [CartLine(product: named('Milkshake'))],
        payments: [PaymentInput.from((await r.payMethods.list()).firstWhere((m) => m.name == 'Credit (book)'))],
        cashier: cashier,
        customer: ama,
      );
      await r.customers.repay(id, amount: 2000, method: momo, reference: 'MP-2', by: cashier);

      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      final end = start.add(const Duration(days: 1));
      var items = await r.momo.items(start, end);
      expect(items.map((i) => (i.source, i.amount, i.reference)), [('sale', 1200, 'MP-1'), ('customer', 2000, 'MP-2')]);
      expect(items.every((i) => i.matched == null), isTrue);

      await r.momo.check(items[0], true, by: owner);
      await r.momo.check(items[1], false, by: owner);
      items = await r.momo.items(start, end);
      expect(items.map((i) => i.matched), [true, false]);
      expect(await r.audit.list(actions: {AuditAction.momoChecked}), hasLength(1), reason: 'only missing ones');
      await r.momo.check(items[1], null, by: owner);
      expect((await r.momo.items(start, end))[1].matched, isNull);

      await r.momo.setCharges(today, 64, by: owner);
      await r.momo.setCharges(today, 70, by: owner);
      expect(await r.momo.charges(today), 70);
    });
  });
}
