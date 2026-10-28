import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/voucher_repository.dart';
import 'package:aby_pos/app/domain/loyalty.dart';
import 'package:aby_pos/app/domain/promotions.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;
  late Customer ama;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);
  Future<Customer> fresh() async => (await r.customers.find(ama.id))!;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    final id = await r.customers.save(const CustomerDraft(name: 'Ama', phone: '0241234567'), by: owner);
    ama = (await r.customers.find(id))!;
  });
  tearDown(() => db.close());

  Future<CompletedSale> sell(List<CartLine> lines, {LoyaltyConfig loyalty = const LoyaltyConfig(), List<PaymentInput>? payments, Customer? customer}) =>
      r.sales.completeSale(
        lines: lines,
        payments: payments ?? [const PaymentInput.cash(tendered: 100000)],
        cashier: cashier,
        customer: customer ?? ama,
        loyalty: loyalty,
      );

  group('Loyalty', () {
    test('stamps: one per item, then the next is free and the stamps are used', () async {
      final waffles = LoyaltyConfig(
        style: LoyaltyStyle.stamps,
        stampsForReward: 3,
        stampTarget: PromoTarget(products: {named('Waffle').id}),
      );
      await sell([CartLine(product: named('Waffle'), quantity: 2), CartLine(product: named('Milkshake'))], loyalty: waffles);
      expect((await fresh()).loyalty, 2, reason: 'milkshakes do not earn');
      await sell([CartLine(product: named('Waffle'))], loyalty: waffles);
      expect((await fresh()).loyalty, 3);
      expect(Loyalty.available(waffles, LoyaltyStatus(balance: (await fresh()).loyalty)), isA<FreeItemReward>());

      final free = await sell([CartLine(product: named('Waffle'), quantity: 2)], loyalty: waffles);
      expect(free.total, 1200, reason: 'one of the two waffles free');
      expect((await fresh()).loyalty, 1, reason: '3 used, 1 earned (the free one earns none)');
      final line = (await (db.select(db.saleLines)..where((l) => l.saleId.equals(free.saleId))).get()).single;
      expect(line.promotionName, Loyalty.stampsName);
    });

    test('points: earned per cedi, used in whole rewards, and they expire when idle', () async {
      const points = LoyaltyConfig(style: LoyaltyStyle.points, pointsPerCedi: 10, pointsForReward: 100, rewardValue: 500, expireDays: 30);
      await sell([CartLine(product: named('Waffle'))], loyalty: points);
      expect((await fresh()).loyalty, 120, reason: 'GH₵ 12 at 10 points per cedi');
      final paid = await sell([CartLine(product: named('Milkshake'))], loyalty: points);
      expect(paid.total, 1500, reason: 'one reward of GH₵ 5');
      expect((await fresh()).loyalty, 120 - 100 + 150);

      // Idle for 31 days: they go.
      await db.customStatement('UPDATE customer_ledger SET created_at = created_at - 31 * 86400');
      final status = await r.customers.loyaltyStatus(ama.id, points, byName: 'Kofi');
      expect(status.balance, 0);
      expect((await fresh()).loyalty, 0);
    });

    test('Gold: spend in 90 days gives a percent off everything', () async {
      const gold = LoyaltyConfig(style: LoyaltyStyle.tiers, goldSpend: 2000, goldPercent: 10);
      final first = await sell([CartLine(product: named('Waffle'))], loyalty: gold);
      expect(first.total, 1200, reason: 'not Gold yet');
      final second = await sell([CartLine(product: named('Milkshake'))], loyalty: gold);
      expect(second.total, 2000, reason: 'GH₵ 12 is below GH₵ 20');
      final third = await sell([CartLine(product: named('Milkshake'))], loyalty: gold);
      expect(third.total, 1800, reason: 'Gold now: 10% off');
    });
  });

  group('Gift vouchers', () {
    test('sold as money in, spent in parts, refused when expired or short', () async {
      final cash = (await r.payMethods.list()).firstWhere((m) => m.isCash);
      final v = await r.vouchers.issue(amount: 5000, method: cash, shopName: 'Scoops Tamale', by: owner);
      expect(v.code, matches(RegExp(r'^SCO-[A-Z2-9]{4}$')));
      expect(v.balance, 5000);
      expect((await r.payMethods.list()).map((m) => m.kind), contains(PaymentMethod.voucher), reason: 'switched on by the sale');
      expect((await r.customers.moneyInSince(null))[PaymentMethod.cash], 5000, reason: 'counts in the drawer');

      final voucher = (await r.payMethods.list(includeInactive: true)).firstWhere((m) => m.kind == PaymentMethod.voucher);
      final sale = await sell(
        [CartLine(product: named('Milkshake'))],
        payments: [PaymentInput.from(voucher, reference: v.code.toLowerCase())],
      );
      expect(sale.total, 2000);
      expect((await r.vouchers.find(v.code))!.balance, 3000);

      await expectLater(
        sell([CartLine(product: named('Ice cream tub'))], payments: [PaymentInput.from(voucher, reference: v.code)]),
        throwsA(isA<SaleException>().having((e) => e.message, 'message', contains('GH₵ 30.00 left'))),
      );
      await expectLater(
        sell([CartLine(product: named('Waffle'))], payments: [PaymentInput.from(voucher, reference: 'NOPE-1234')]),
        throwsA(isA<SaleException>()),
      );

      final old = await r.vouchers.issue(
        amount: 1000,
        method: cash,
        shopName: 'Scoops Tamale',
        by: owner,
        expiresOn: DateTime.now().subtract(const Duration(days: 1)),
      );
      await expectLater(r.vouchers.check(old.code, 100), throwsA(isA<VoucherException>()));
      await expectLater(
        r.vouchers.issue(amount: 1000, method: voucher, shopName: 'S', by: owner),
        throwsA(isA<VoucherException>()),
      );
      expect((await r.vouchers.list()).map((x) => x.code), containsAll([v.code, old.code]));
    });
  });

  test('a void puts back credit owed, wallet money, stamps and voucher money', () async {
    const stamps = LoyaltyConfig(style: LoyaltyStyle.stamps, stampsForReward: 9);
    final cash = (await r.payMethods.list()).firstWhere((m) => m.isCash);
    final v = await r.vouchers.issue(amount: 1000, method: cash, shopName: 'Scoops', by: owner);
    final voucher = (await r.payMethods.list(includeInactive: true)).firstWhere((m) => m.kind == PaymentMethod.voucher);
    final sale = await sell(
      [CartLine(product: named('Waffle'), quantity: 2)],
      loyalty: stamps,
      payments: [
        PaymentInput.from(voucher, reference: v.code, amount: 1000),
        const PaymentInput.credit(customer: 'Ama'),
      ],
    );
    expect((await fresh()).owed, 1400);
    expect((await fresh()).loyalty, 2);
    expect((await r.vouchers.find(v.code))!.balance, 0);

    await r.sales.voidSale(sale.saleId, actor: owner, reason: 'Wrong order');
    final after = await fresh();
    expect((after.owed, after.loyalty), (0, 0));
    expect(await r.customers.openDebts(ama.id), isEmpty);
    expect((await r.vouchers.find(v.code))!.balance, 1000);
  });
}
