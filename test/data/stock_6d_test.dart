import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/purchase_order_repository.dart';
import 'package:aby_pos/app/data/repositories/receiving_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/data/repositories/supplier_repository.dart';
import 'package:aby_pos/app/domain/purchase_order_pdf.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late SupplierRepository suppliers;
  late PurchaseOrderRepository orders;
  late ReceivingRepository receiving;

  Future<StockItem> item(String name) async => (await r.stock.items()).firstWhere((i) => i.name == name);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    suppliers = SupplierRepository(db, r.device, r.audit);
    orders = PurchaseOrderRepository(db, r.device, r.audit, r.stock);
    receiving = ReceivingRepository(db, r.device, r.audit, r.stock, suppliers, orders);
  });
  tearDown(() => db.close());

  test('purchase orders: suggested from low items, received in two deliveries', () async {
    final supplierId = await suppliers.save(const SupplierDraft(name: 'Fan Milk depot', phone: '0302000000'), by: owner);
    final cones = await item('Wafer cones');
    await r.stock.saveItem(
      StockItemDraft(id: cones.id, name: cones.name, unit: cones.unit, costMilli: cones.costMilli, reorderPoint: 300, reorderQty: 500, supplierId: supplierId),
      by: owner,
    );
    final suggested = await orders.suggestions(supplierId);
    expect(suggested, [(cones.id, 500)]);

    final po = await orders.create(PurchaseOrderDraft(supplierId: supplierId, lines: suggested, note: 'Before Friday'), by: owner);
    expect(po.displayNumber, 'PO-0001');
    expect(po.status, PurchaseOrderStatus.open);
    expect(po.lines.single.estimate, 500 * cones.costMilli ~/ 1000);
    expect(String.fromCharCodes((await PurchaseOrderPdf.build(po, shopName: 'Scoops Tamale')).sublist(0, 5)), '%PDF-');

    final first = await receiving.receive(
      ReceiptDraft(
        supplierId: supplierId,
        purchaseOrderId: po.id,
        lines: [ReceiptLineDraft(stockItemId: cones.id, quantity: 200, lineTotal: 2000)],
      ),
      by: owner,
    );
    var now = (await orders.find(po.id))!;
    expect(now.status, PurchaseOrderStatus.partial);
    expect(now.lines.single.outstanding, 300);
    expect((await orders.list(open: true)).single.id, po.id);
    final receipt = await (db.select(db.stockReceipts)..where((x) => x.id.equals(first.id))).getSingle();
    expect(receipt.purchaseOrderId, po.id);

    await receiving.receive(
      ReceiptDraft(
        supplierId: supplierId,
        purchaseOrderId: po.id,
        lines: [ReceiptLineDraft(stockItemId: cones.id, quantity: 300, lineTotal: 3000)],
      ),
      by: owner,
    );
    now = (await orders.find(po.id))!;
    expect(now.status, PurchaseOrderStatus.received);
    expect(await orders.list(open: true), isEmpty);
    await expectLater(orders.cancel(po.id, by: owner), throwsA(isA<StockException>()));

    final other = await orders.create(PurchaseOrderDraft(supplierId: supplierId, lines: [(cones.id, 10)]), by: owner);
    await orders.cancel(other.id, by: owner);
    expect((await orders.find(other.id))!.status, PurchaseOrderStatus.cancelled);
    expect(await r.audit.list(actions: {AuditAction.purchaseOrderSaved}), hasLength(3));
  });

  test('batches: what is in stock is the latest-expiring; the expiry list and alert', () async {
    final milk = await item('Milk');
    expect(milk.tracksExpiry, isTrue, reason: 'dairy on in the ice cream shop');
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    await receiving.receive(
      ReceiptDraft(lines: [
        ReceiptLineDraft(stockItemId: milk.id, quantity: 4000, lineTotal: 10000, batchNo: 'A1', expiresOn: day.add(const Duration(days: 3))),
      ], paidNow: 10000),
      by: owner,
    );
    await receiving.receive(
      ReceiptDraft(lines: [
        ReceiptLineDraft(stockItemId: milk.id, quantity: 5000, lineTotal: 12500, batchNo: 'B2', expiresOn: day.add(const Duration(days: 20))),
      ], paidNow: 12500),
      by: owner,
    );
    // 10 L opening stock (no batch) + 4 L + 5 L = 19 L in stock.
    var batches = await r.stock.batches(stockItemId: milk.id);
    expect([for (final b in batches) (b.batchNo, b.left)], [('A1', 4000), ('B2', 5000)]);
    expect((await r.stock.expiring(days: 7)).single.batchNo, 'A1');

    // Use 12 L: the opening stock has no batch and goes... the batches keep
    // the latest-expiring 7 L: all of B2 and 2 L of A1.
    await r.stock.adjust(milk.id, -12000, note: 'Used', by: owner);
    batches = await r.stock.batches(stockItemId: milk.id);
    expect([for (final b in batches) (b.batchNo, b.left)], [('A1', 2000), ('B2', 5000)]);

    await r.stock.adjust(milk.id, -3000, note: 'Used', by: owner);
    expect(await r.stock.expiring(days: 7), isEmpty, reason: 'A1 is used up');
    batches = await r.stock.batches(stockItemId: milk.id);
    expect(batches.firstWhere((b) => b.batchNo == 'B2').left, 4000);
  });

  test('production: a batch recipe, then a run takes ingredients and adds the made item at their cost', () async {
    final milk = await item('Milk');
    final vanilla = await item('Vanilla ice cream');
    final baseId = await r.stock.saveItem(const StockItemDraft(name: 'Milkshake base', unit: StockUnit.ml, costMilli: 0), by: owner);
    await expectLater(
      r.stock.saveProductionRecipe(baseId, batchYield: 4000, lines: [(baseId, 100)], by: owner),
      throwsA(isA<StockException>()),
    );
    await expectLater(r.stock.produce(baseId, 1000, by: owner), throwsA(isA<StockException>()));

    await r.stock.saveProductionRecipe(baseId, batchYield: 4000, lines: [(milk.id, 3000), (vanilla.id, 1000)], by: owner);
    final recipe = (await r.stock.productionRecipe(baseId))!;
    expect(recipe.batchYield, 4000);
    expect(recipe.lines, [(milk.id, 3000), (vanilla.id, 1000)]);
    expect((await r.stock.item(baseId))!.madeHere, isTrue);

    final cost = await r.stock.produce(baseId, 2000, by: owner);
    final after = await r.stock.item(baseId);
    expect(after!.onHand, 2000);
    expect((await item('Milk')).onHand, milk.onHand - 1500);
    expect((await item('Vanilla ice cream')).onHand, vanilla.onHand - 500);
    final expectedMilli = 1500 * milk.costMilli + 500 * vanilla.costMilli;
    expect(cost, (expectedMilli + 500) ~/ 1000);
    expect(after.costMilli, (expectedMilli + 1000) ~/ 2000);
    final moves = await r.stock.movements(milk.id);
    expect(moves.first.reason, StockReason.production);
    expect(await r.audit.list(actions: {AuditAction.stockProduced}), hasLength(1));

    // Not made here any more.
    await r.stock.saveProductionRecipe(baseId, batchYield: null, lines: const [], by: owner);
    expect(await r.stock.productionRecipe(baseId), isNull);
  });
}
