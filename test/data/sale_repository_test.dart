import 'dart:convert';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/core/tax.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/outbox_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Fails on the first stock movement, after the sale and its lines have
/// been written in the transaction.
class ExplodingStock extends StockRepository {
  ExplodingStock(super.db, super.device, super.audit);

  @override
  Future<void> record({
    String? stockItemId,
    String? productId,
    String? variantId,
    required int quantityChange,
    required StockReason reason,
    String? subReason,
    int? unitCostMilli,
    String? saleId,
    String? refId,
    String? note,
    String? byName,
    DateTime? at,
  }) =>
      throw StateError('disk full');
}

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);
  Option option(String name) => menu.groups.expand((g) => g.options).firstWhere((o) => o.name == name);

  Future<int> count(String table, [String where = '']) async {
    final row = await db.customSelect('SELECT COUNT(*) AS n FROM $table $where').getSingle();
    return row.read<int>('n');
  }

  Future<int> onHand(String stockName) async {
    final item = (await r.stock.items()).firstWhere((s) => s.name == stockName);
    return item.onHand;
  }

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await CatalogRepository(db, r.device, r.audit).load();
  });

  tearDown(() => db.close());

  test('seeds the Scoops Tamale menu with stock, recipes and opening stock', () async {
    final shop = await db.customSelect("SELECT value FROM settings WHERE key = 'shop.name'").getSingle();
    expect(AppSettings.shopName.decode(jsonDecode(shop.read<String>('value'))), 'Scoops Tamale');
    expect(menu.products.map((p) => p.name), containsAll(['Vanilla cone', 'Milkshake', 'Waffle']));
    final cup = named('Ice cream cup');
    expect(cup.variants.map((v) => v.price), [2000, 2500, 3200]);
    expect(cup.groups.single.options.map((o) => o.name), contains('Groundnut crunch'));
    final single = named('Vanilla cone').variants.first;
    expect(single.recipe.map((x) => (x.stockItemName, x.quantity)), [('Wafer cones', 1), ('Vanilla ice cream', 80)]);
    // 1 cone at GH₵ 0.80 + 80 ml at GH₵ 45/L (3.60) = GH₵ 4.40
    expect(single.cost, 440);
    expect(await onHand('Wafer cones'), 200);
    expect(await count('outbox'), 0);
  });

  test('completeSale writes the sale, lines, payment, stock used and outbox together', () async {
    final cone = named('Vanilla cone');
    final lines = [
      CartLine(product: cone, variant: cone.variants[1], options: [option('Sprinkles')], quantity: 2),
      CartLine(product: named('Milkshake')),
    ];

    final result = await r.sales.completeSale(
      lines: lines,
      payment: const PaymentInput.cash(tendered: 10000),
      cashier: cashier,
    );

    // (22 + 3) x 2 + 20 = 70.00
    expect(result.total, 7000);
    expect(result.changeDue, 3000);
    expect(result.displayNumber, '#00001');

    expect(await count('sales'), 1);
    expect(await count('sale_lines'), 2);
    expect(await count('payments'), 1);
    // Cones, vanilla (cone + milkshake, summed), sprinkles, milk.
    expect(await count('stock_movements', "WHERE reason = 'sale'"), 4);
    expect(await count('sale_taxes'), 0, reason: 'tax is off');

    expect(await onHand('Wafer cones'), 198);
    expect(await onHand('Vanilla ice cream'), 20000 - 160 * 2 - 100);
    expect(await onHand('Sprinkles'), 2000 - 10 * 2);
    expect(await onHand('Milk'), 10000 - 200);

    final coneLine = (await db.select(db.saleLines).get()).firstWhere((l) => l.productId == cone.id);
    expect(coneLine.unitPrice, 2500);
    expect(coneLine.lineTotal, 5000);
    expect(coneLine.addons.single.name, 'Sprinkles');
    // Per cone: 0.80 cone + 160 ml × 4.5p (7.20) + 10 g × 4p (0.40) = 8.40; two of them.
    expect(coneLine.costTotal, 1680);

    final sale = await db.select(db.sales).getSingle();
    final saleOutbox = await (db.select(db.outbox)..where((o) => o.entity.equals('sales'))).getSingle();
    expect(saleOutbox.recordId, sale.id);
    expect((jsonDecode(saleOutbox.payload) as Map<String, dynamic>)['total'], 7000);
  });

  test('tax: inclusive prices keep the total; exclusive adds tax on top', () async {
    final rates = menu.taxRates;
    final waffleBase = named('Waffle');
    final taxed = Product(
      id: waffleBase.id,
      categoryId: waffleBase.categoryId,
      name: waffleBase.name,
      variants: waffleBase.variants,
      taxes: rates,
    );

    final inclusive = await r.sales.completeSale(
      lines: [CartLine(product: taxed)],
      payment: const PaymentInput.cash(tendered: 1200),
      cashier: cashier,
      taxMode: TaxMode.inclusive,
    );
    expect(inclusive.total, 1200);

    final exclusive = await r.sales.completeSale(
      lines: [CartLine(product: taxed)],
      payment: const PaymentInput.cash(tendered: 5000),
      cashier: cashier,
      taxMode: TaxMode.exclusive,
    );
    // 12.00 + NHIL 0.30 + GETFund 0.30 + VAT 15% of 12.60 (1.89) = 14.49
    expect(exclusive.total, 1449);

    final taxes = await db.select(db.saleTaxes).get();
    expect(taxes.where((t) => t.saleId == exclusive.saleId).map((t) => t.amount).toList()..sort(), [30, 30, 189]);
    final sale = await (db.select(db.sales)..where((s) => s.id.equals(exclusive.saleId))).getSingle();
    expect(sale.taxTotal, 249);
  });

  test('numbers sales per device in sequence', () async {
    final line = CartLine(product: named('Waffle'));
    await r.sales.completeSale(lines: [line], payment: const PaymentInput.momo(momoReference: 'TX1'), cashier: cashier);
    final second = await r.sales.completeSale(
        lines: [line], payment: const PaymentInput.cash(tendered: 1200), cashier: cashier);
    expect(second.number, 2);
  });

  test('writes nothing when a step fails part-way', () async {
    final failing = SaleRepository(db, ExplodingStock(db, r.device, r.audit), r.closes, r.audit, r.device);
    final before = await count('stock_movements');
    await expectLater(
      failing.completeSale(
        lines: [CartLine(product: named('Waffle'))],
        payment: const PaymentInput.cash(tendered: 2000),
        cashier: cashier,
      ),
      throwsStateError,
    );
    for (final table in ['sales', 'sale_lines', 'payments', 'outbox']) {
      expect(await count(table), 0, reason: table);
    }
    expect(await count('stock_movements'), before);
  });

  test('writes nothing when a line points at an unknown product', () async {
    const ghost = Product(id: 'missing', categoryId: 'x', name: 'Ghost', variants: [Variant(id: 'vx', price: 100)]);
    await expectLater(
      r.sales.completeSale(
        lines: [CartLine(product: named('Waffle')), CartLine(product: ghost)],
        payment: const PaymentInput.cash(tendered: 5000),
        cashier: cashier,
      ),
      throwsA(anything),
    );
    for (final table in ['sales', 'sale_lines', 'payments', 'outbox']) {
      expect(await count(table), 0, reason: table);
    }
  });

  test('rejects bad payments before writing', () async {
    final lines = [CartLine(product: named('Waffle'))];
    for (final payment in const [
      PaymentInput.cash(tendered: 1000),
      PaymentInput.momo(momoReference: '  '),
      PaymentInput.credit(customer: ''),
    ]) {
      await expectLater(
        r.sales.completeSale(lines: lines, payment: payment, cashier: cashier),
        throwsA(isA<SaleException>()),
      );
    }
    await expectLater(
      r.sales.completeSale(lines: const [], payment: const PaymentInput.cash(tendered: 0), cashier: cashier),
      throwsA(isA<SaleException>()),
    );
    expect(await count('sales'), 0);
  });

  test('voidSale marks the sale, records who, and puts back exactly what it used', () async {
    final cone = named('Vanilla cone');
    final done = await r.sales.completeSale(
      lines: [CartLine(product: cone, options: [option('Sprinkles'), option('Sprinkles')], quantity: 3)],
      payment: const PaymentInput.cash(tendered: 10000),
      cashier: cashier,
    );
    expect(await onHand('Sprinkles'), 2000 - 60);

    await r.sales.voidSale(done.saleId, actor: cashier, approver: owner);

    final sale = await db.select(db.sales).getSingle();
    expect(sale.status, SaleStatus.voided);
    expect(sale.voidedBy, 'Kofi');
    expect(await onHand('Sprinkles'), 2000);
    expect(await onHand('Wafer cones'), 200);
    expect(await onHand('Vanilla ice cream'), 20000);

    final entry = (await r.audit.list()).firstWhere((e) => e.action == AuditAction.saleVoided);
    expect(entry.actorName, 'Ama');
    expect(entry.approverName, 'Kofi');

    await expectLater(r.sales.voidSale(done.saleId, actor: owner), throwsA(isA<SaleException>()));
  });

  test('watchToday lists sales with payments; summary skips voided', () async {
    final waffle = named('Waffle');
    final a = await r.sales.completeSale(
        lines: [CartLine(product: waffle)], payment: const PaymentInput.cash(tendered: 1200), cashier: cashier);
    await r.sales.completeSale(
        lines: [CartLine(product: waffle, quantity: 2)],
        payment: const PaymentInput.momo(momoReference: 'MP123'),
        cashier: cashier);
    await r.sales.voidSale(a.saleId, actor: owner);

    final sales = await r.sales.watchToday(dayStartMinutes: 0).first;
    expect(sales, hasLength(2));
    expect(sales.first.number, 2, reason: 'newest first');
    expect(sales.first.itemCount, 2);

    final summary = TodaySummary.fromSales(sales);
    expect(summary.count, 1);
    expect(summary.total, 2400);
    expect(summary.byMethod[PaymentMethod.momo], 2400);
  });

  test('pending sales count counts each sale once', () async {
    final outbox = OutboxRepository(db);
    final done = await r.sales.completeSale(
        lines: [CartLine(product: named('Waffle'))],
        payment: const PaymentInput.cash(tendered: 1200),
        cashier: cashier);
    expect(await outbox.watchPendingSalesCount().first, 1);
    await r.sales.voidSale(done.saleId, actor: owner);
    expect(await outbox.watchPendingSalesCount().first, 1);
  });

  test('stock corrections and waste are recorded with their value', () async {
    final cones = (await r.stock.items()).firstWhere((s) => s.name == 'Wafer cones');
    await r.stock.logWaste(cones.id, 5, reason: WasteReason.damaged, by: cashier);
    await r.stock.adjust(cones.id, 3, note: 'Found a box', by: owner);
    expect(await onHand('Wafer cones'), 198);
    final waste = (await r.audit.list(actions: {AuditAction.stockWasted})).single;
    expect(waste.details!['value'], 400, reason: '5 cones at GH₵ 0.80');
    await expectLater(r.stock.adjust(cones.id, 1, note: ' ', by: owner), throwsA(isA<StockException>()));
  });
}
