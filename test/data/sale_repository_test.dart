import 'dart:convert';

import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/repositories/audit_repository.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/day_close_repository.dart';
import 'package:aby_pos/app/data/repositories/outbox_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Fails on the first stock movement, after the sale and its first line
/// have been written in the transaction.
class ExplodingStock extends StockRepository {
  ExplodingStock(super.db, super.device);

  @override
  Future<void> record({
    required String productId,
    String? variantId,
    required int quantityChange,
    required StockReason reason,
    String? saleId,
    String? note,
    DateTime? at,
  }) =>
      throw StateError('disk full');
}

void main() {
  late AppDatabase db;
  late FakeDevice device;
  late SaleRepository repo;
  late StockRepository stock;
  late DayCloseRepository closes;
  late AuditRepository audit;
  late List<Product> menu;

  Product named(String name) => menu.firstWhere((p) => p.name == name);

  Future<int> count(String table) async {
    final row = await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle();
    return row.read<int>('n');
  }

  setUp(() async {
    db = memoryDb();
    device = FakeDevice((await db.readMeta(MetaKeys.deviceId))!);
    stock = StockRepository(db, device);
    audit = AuditRepository(db, device);
    closes = DayCloseRepository(db, device, audit);
    repo = SaleRepository(db, stock, closes, audit, device);
    menu = await CatalogRepository(db).products();
  });

  tearDown(() => db.close());

  test('seeds the Scoops Tamale menu without outbox rows', () async {
    final shop = await db.customSelect("SELECT value FROM settings WHERE key = 'shop.name'").getSingle();
    expect(AppSettings.shopName.decode(jsonDecode(shop.read<String>('value'))), 'Scoops Tamale');
    expect(menu.map((p) => p.name), containsAll(['Vanilla cone', 'Milkshake', 'Waffle']));
    final cup = named('Ice cream cup');
    expect(cup.variants.map((v) => v.price), [2000, 2500, 3200]);
    expect(cup.addons.map((a) => a.name), contains('Groundnut crunch'));
    expect(await count('outbox'), 0);
  });

  test('completeSale writes sale, lines, payment, stock and outbox together', () async {
    final cone = named('Vanilla cone');
    final lines = [
      CartLine(product: cone, variant: cone.variants[1], addons: [cone.addons.first], quantity: 2),
      CartLine(product: named('Milkshake')),
    ];

    final result = await repo.completeSale(
      cashier: cashier,
      lines: lines,
      payment: const PaymentInput.cash(tendered: 10000),
    );

    // (22 + 3) x 2 + 20 = 70.00
    expect(result.total, 7000);
    expect(result.changeDue, 3000);
    expect(result.number, 1);
    expect(result.displayNumber, '#00001');

    expect(await count('sales'), 1);
    expect(await count('sale_lines'), 2);
    expect(await count('payments'), 1);
    expect(await count('stock_movements'), 2);
    // 1 sale + 2 lines + 2 stock movements + 1 payment.
    expect(await count('outbox'), 6);

    final sale = await db.select(db.sales).getSingle();
    expect(sale.deviceId, device.deviceId);
    expect(sale.cashierName, 'Ama');
    expect(sale.cashierId, cashier.id);
    expect(sale.syncedAt, isNull);

    final payment = await db.select(db.payments).getSingle();
    expect(payment.amount, 7000);
    expect(payment.tendered, 10000);
    expect(payment.changeGiven, 3000);

    final coneLine = (await db.select(db.saleLines).get())
        .firstWhere((l) => l.productId == cone.id);
    expect(coneLine.unitPrice, 2500);
    expect(coneLine.lineTotal, 5000);
    expect(coneLine.addons.single.name, 'Sprinkles');

    expect(await stock.onHand(cone.id, variantId: cone.variants[1].id), -2);

    final saleOutbox = await (db.select(db.outbox)
          ..where((o) => o.entity.equals('sales')))
        .getSingle();
    expect(saleOutbox.recordId, sale.id);
    expect(saleOutbox.operation, OutboxOperation.insert);
    expect((jsonDecode(saleOutbox.payload) as Map<String, dynamic>)['total'], 7000);
  });

  test('numbers sales per device in sequence', () async {
    final line = CartLine(product: named('Waffle'));
    await repo.completeSale(cashier: cashier, lines: [line], payment: const PaymentInput.momo(momoReference: 'TX1'));
    final second = await repo.completeSale(
      cashier: cashier,
        lines: [line], payment: const PaymentInput.credit(customer: '024 000 0000'));
    expect(second.number, 2);
  });

  test('writes nothing when a step fails part-way', () async {
    final failing = SaleRepository(db, ExplodingStock(db, device), closes, audit, device);
    await expectLater(
      failing.completeSale(
      cashier: cashier,
        lines: [CartLine(product: named('Waffle'))],
        payment: const PaymentInput.cash(tendered: 2000),
      ),
      throwsStateError,
    );
    for (final table in ['sales', 'sale_lines', 'payments', 'stock_movements', 'outbox']) {
      expect(await count(table), 0, reason: table);
    }
  });

  test('writes nothing when a line points at an unknown product', () async {
    const ghost = Product(id: 'missing', categoryId: 'x', name: 'Ghost', basePrice: 100);
    await expectLater(
      repo.completeSale(
      cashier: cashier,
        lines: [CartLine(product: named('Waffle')), CartLine(product: ghost)],
        payment: const PaymentInput.cash(tendered: 5000),
      ),
      throwsA(anything),
    );
    for (final table in ['sales', 'sale_lines', 'payments', 'stock_movements', 'outbox']) {
      expect(await count(table), 0, reason: table);
    }
  });

  test('rejects bad payments before writing', () async {
    final lines = [CartLine(product: named('Waffle'))];
    await expectLater(
      repo.completeSale(cashier: cashier, lines: lines, payment: const PaymentInput.cash(tendered: 1000)),
      throwsA(isA<SaleException>()),
    );
    await expectLater(
      repo.completeSale(cashier: cashier, lines: lines, payment: const PaymentInput.momo(momoReference: '  ')),
      throwsA(isA<SaleException>()),
    );
    await expectLater(
      repo.completeSale(cashier: cashier, lines: lines, payment: const PaymentInput.credit(customer: '')),
      throwsA(isA<SaleException>()),
    );
    await expectLater(
      repo.completeSale(cashier: cashier, lines: const [], payment: const PaymentInput.cash(tendered: 0)),
      throwsA(isA<SaleException>()),
    );
    expect(await count('sales'), 0);
  });

  test('voidSale marks the sale, records who, restocks, and queues an update', () async {
    final waffle = named('Waffle');
    final done = await repo.completeSale(
      cashier: cashier,
      lines: [CartLine(product: waffle, quantity: 3)],
      payment: const PaymentInput.cash(tendered: 3600),
    );

    await repo.voidSale(done.saleId, actor: cashier, approver: owner);

    final sale = await db.select(db.sales).getSingle();
    expect(sale.status, SaleStatus.voided);
    expect(sale.voidedBy, 'Kofi');
    expect(sale.voidedById, owner.id);
    expect(sale.voidedAt, isNotNull);
    expect(await stock.onHand(waffle.id), 0);

    final updates = await (db.select(db.outbox)
          ..where((o) => o.operation.equalsValue(OutboxOperation.update)))
        .get();
    expect(updates.single.recordId, done.saleId);

    final entry = (await audit.list()).firstWhere((e) => e.action == AuditAction.saleVoided);
    expect(entry.actorName, 'Ama');
    expect(entry.approverName, 'Kofi');
    expect(entry.entityId, done.saleId);

    await expectLater(
      repo.voidSale(done.saleId, actor: owner),
      throwsA(isA<SaleException>()),
    );
  });

  test('watchToday lists sales with payments; summary skips voided', () async {
    final waffle = named('Waffle');
    final a = await repo.completeSale(
      cashier: cashier,
        lines: [CartLine(product: waffle)], payment: const PaymentInput.cash(tendered: 1200));
    await repo.completeSale(
      cashier: cashier,
        lines: [CartLine(product: waffle, quantity: 2)],
        payment: const PaymentInput.momo(momoReference: 'MP123'));
    await repo.voidSale(a.saleId, actor: owner);

    final sales = await repo.watchToday(dayStartMinutes: 0).first;
    expect(sales, hasLength(2));
    expect(sales.first.number, 2, reason: 'newest first');
    expect(sales.first.itemCount, 2);

    final summary = TodaySummary.fromSales(sales);
    expect(summary.count, 1);
    expect(summary.total, 2400);
    expect(summary.byMethod[PaymentMethod.momo], 2400);
    expect(summary.byMethod[PaymentMethod.cash], 0);
  });

  test('pending sales count counts each sale once', () async {
    final outbox = OutboxRepository(db);
    final done = await repo.completeSale(
      cashier: cashier,
        lines: [CartLine(product: named('Waffle'))],
        payment: const PaymentInput.cash(tendered: 1200));
    expect(await outbox.watchPendingSalesCount().first, 1);
    await repo.voidSale(done.saleId, actor: owner);
    expect(await outbox.watchPendingSalesCount().first, 1);
  });
}
