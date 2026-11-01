import 'package:aby_pos/app/core/csv.dart';
import 'package:aby_pos/app/core/units.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/receiving_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_count_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/data/repositories/supplier_repository.dart';
import 'package:aby_pos/app/domain/audit_details.dart';
import 'package:aby_pos/app/domain/business_templates.dart';
import 'package:aby_pos/app/domain/catalogue_io.dart';
import 'package:aby_pos/app/domain/delivery_pdf.dart';
import 'package:aby_pos/app/domain/delivery_updates.dart';
import 'package:aby_pos/app/domain/catalogue_rules.dart';
import 'package:aby_pos/app/domain/inventory.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late SupplierRepository suppliers;
  late ReceivingRepository receiving;
  late StockCountRepository counts;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    suppliers = SupplierRepository(db, r.device, r.audit);
    receiving = ReceivingRepository(db, r.device, r.audit, r.stock, suppliers);
    counts = StockCountRepository(db, r.device, r.audit, r.stock);
  });
  tearDown(() => db.close());

  Future<StockItem> stockItem(String name) async => (await r.stock.items()).firstWhere((i) => i.name == name);
  Future<Product> product(String name) async =>
      (await r.catalog.load(includeInactive: true)).products.firstWhere((p) => p.name == name);

  group('Inventory', () {
    test('weighted average cost, and a fresh start when stock had run out', () {
      expect(Inventory.averageCost(onHand: 200, oldCostMilli: 80000, qty: 100, newCostMilli: 100000), 86667);
      expect(Inventory.averageCost(onHand: 0, oldCostMilli: 80000, qty: 10, newCostMilli: 90000), 90000);
      expect(Inventory.averageCost(onHand: -5, oldCostMilli: 80000, qty: 10, newCostMilli: 90000), 90000);
      expect(Inventory.averageCost(onHand: 10, oldCostMilli: 80000, qty: 0, newCostMilli: 90000), 80000);
    });

    test('suggested low level and days left come from recent use', () {
      // 280 used over 28 days: 10 a day, three days plus half again.
      expect(Inventory.suggestReorderPoint(used: 280), 45);
      expect(Inventory.suggestReorderPoint(used: 0), isNull);
      expect(Inventory.daysLeft(onHand: 100, used: 280), 10);
      expect(Inventory.daysLeft(onHand: -3, used: 280), 0);
      expect(Inventory.daysLeft(onHand: 100, used: 0), isNull);
    });
  });

  group('Csv', () {
    test('round trip keeps commas, quotes and line breaks', () {
      final rows = [
        ['product', 'note'],
        ['Cone, large', 'say "hi"'],
        ['Two\nlines', ' spaced '],
        ['', 'empty first'],
      ];
      expect(Csv.decode(Csv.encode(rows)), rows);
    });

    test('reads Excel files: byte-order mark, CRLF, and no final newline', () {
      expect(Csv.decode('﻿a,b\r\n1,2\r\n\r\n3,"4"'), [
        ['a', 'b'],
        ['1', '2'],
        ['3', '4'],
      ]);
    });
  });

  group('Receiving', () {
    test('a delivery adds stock, updates the average cost, and records what is owed', () async {
      final supplierId = await suppliers.save(
        const SupplierDraft(name: 'Tamale Wholesale', paymentTermsDays: 14),
        by: owner,
      );
      final cones = await stockItem('Wafer cones');
      expect(cones.onHand, 200);
      expect(cones.costMilli, 80000);

      final receipt = await receiving.receive(
        ReceiptDraft(
          supplierId: supplierId,
          invoiceRef: 'INV-77',
          lines: [ReceiptLineDraft(stockItemId: cones.id, quantity: 100, lineTotal: 10000)],
          paidNow: 4000,
          paidWith: SupplierPaymentMethod.momo,
        ),
        by: owner,
      );
      expect(receipt.displayNumber, 'DEL-0001');
      expect(receipt.supplierName, 'Tamale Wholesale');

      // Its own page and goods received note: lines, paid and owed.
      final detail = (await receiving.detail(receipt.id))!;
      expect(detail.lines.single.name, 'Wafer cones');
      expect(detail.lines.single.quantity, 100);
      expect(detail.lines.single.lineTotal, 10000);
      expect(detail.receipt.owed, 6000);
      expect(detail.receipt.invoiceRef, 'INV-77');
      final pdf = await DeliveryPdf.build(detail, shopName: 'Scoops Tamale');
      expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');

      // Updating the cones from the delivery record: its price (GH₵ 1.00
      // each, not the 0.87 average), its supplier and its quantity.
      final plan = DeliveryUpdates.plan(detail, {for (final i in await r.stock.items()) i.id: i});
      expect(plan.single.changes, {DeliveryChange.cost, DeliveryChange.supplier, DeliveryChange.orderQty});
      expect(await DeliveryUpdates.updatedAt(r.audit, receipt), isNull);
      expect(
        await DeliveryUpdates.apply(r.stock, r.audit, receipt, [(plan.single, {DeliveryChange.cost, DeliveryChange.supplier})], by: owner),
        1,
      );
      expect(await DeliveryUpdates.updatedAt(r.audit, receipt), isNotNull, reason: 'the delivery is marked as used');
      final updated = await stockItem('Wafer cones');
      expect(updated.costMilli, 100000);
      expect(updated.supplierId, supplierId);
      expect(updated.reorderQty, isNot(100), reason: 'left unticked');
      expect(updated.onHand, 300, reason: 'the stock count is the delivery itself, not changed again');
      final again = DeliveryUpdates.plan(detail, {for (final i in await r.stock.items()) i.id: i});
      expect(again.single.changes, {DeliveryChange.orderQty});
      await DeliveryUpdates.apply(r.stock, r.audit, receipt, [(again.single, {DeliveryChange.orderQty})], by: owner);
      expect(DeliveryUpdates.plan(detail, {for (final i in await r.stock.items()) i.id: i}), isEmpty);
      // Back to the average for the checks below.
      await r.stock.saveItem(
        StockItemDraft(id: updated.id, name: updated.name, unit: updated.unit, costMilli: 86667, reorderPoint: updated.reorderPoint),
        by: owner,
      );

      final after = await stockItem('Wafer cones');
      expect(after.onHand, 300);
      expect(after.costMilli, 86667);
      final move = (await r.stock.movements(cones.id)).first;
      expect(move.reason, StockReason.restock);
      expect(move.quantityChange, 100);

      expect((await suppliers.find(supplierId))!.balance, 6000);
      final ledger = await suppliers.ledger(supplierId);
      expect(ledger.map((e) => e.amount), unorderedEquals([10000, -4000]));

      await suppliers.recordPayment(supplierId, amount: 6000, method: SupplierPaymentMethod.cash, by: owner);
      expect((await suppliers.find(supplierId))!.balance, 0);
      expect(await suppliers.ledger(supplierId), hasLength(3));

      final list = await receiving.list();
      expect(list.single.lineCount, 1);
      expect(list.single.total, 10000);
      expect((await receiving.lines(receipt.id)).single.$2, '100 pcs');
      expect((await r.audit.verifyChain()).isIntact, isTrue);
    });

    test('delivery numbers count up', () async {
      final milk = await stockItem('Milk');
      ReceiptDraft paid(int total) => ReceiptDraft(
        lines: [ReceiptLineDraft(stockItemId: milk.id, quantity: 1000, lineTotal: total)],
        paidNow: total,
      );
      await receiving.receive(paid(2500), by: owner);
      final second = await receiving.receive(paid(2600), by: owner);
      expect(second.displayNumber, 'DEL-0002');
    });

    test('rejects bad deliveries without saving anything', () async {
      final supplierId = await suppliers.save(const SupplierDraft(name: 'Dairy Co'), by: owner);
      final milk = await stockItem('Milk');
      final line = ReceiptLineDraft(stockItemId: milk.id, quantity: 1000, lineTotal: 2500);
      final bad = [
        const ReceiptDraft(lines: []),
        ReceiptDraft(lines: [line], paidNow: 1000), // no supplier, not paid in full
        ReceiptDraft(supplierId: supplierId, lines: [line], paidNow: 3000), // paid more than the total
        ReceiptDraft(supplierId: supplierId, lines: [line, line]), // same item twice
        ReceiptDraft(lines: [ReceiptLineDraft(stockItemId: milk.id, quantity: 0, lineTotal: 0)]),
      ];
      for (final d in bad) {
        await expectLater(receiving.receive(d, by: owner), throwsA(isA<StockException>()));
      }
      expect(await receiving.list(), isEmpty);
      expect((await stockItem('Milk')).onHand, 10000);
      expect((await suppliers.find(supplierId))!.balance, 0);
    });

    test('a payment must be more than nothing', () async {
      final supplierId = await suppliers.save(const SupplierDraft(name: 'Dairy Co'), by: owner);
      await expectLater(
        suppliers.recordPayment(supplierId, amount: 0, method: SupplierPaymentMethod.cash, by: owner),
        throwsA(isA<StockException>()),
      );
    });
  });

  group('Stock counts', () {
    test('posting sets stock to what was found and values the difference', () async {
      final cones = await stockItem('Wafer cones');
      final sprinkles = await stockItem('Sprinkles');
      final id = await counts.start(blind: true, by: owner);
      await expectLater(counts.start(blind: false, by: owner), throwsA(isA<StockException>()));

      await counts.setCount(id, cones.id, 195, by: cashier);
      await counts.setCount(id, cones.id, 190, by: cashier); // corrected
      await counts.setCount(id, sprinkles.id, 2000, by: cashier);
      final lines = await counts.lines(id);
      expect(lines.firstWhere((l) => l.stockItemId == cones.id).difference, -10);
      expect(lines.where((l) => l.counted != null), hasLength(2));
      expect((await counts.open())!.lineCount, 2);

      final value = await counts.post(id, by: owner);
      expect(value, costOf(-10, cones.costMilli));
      expect(value, -800);
      expect((await stockItem('Wafer cones')).onHand, 190);
      expect((await stockItem('Sprinkles')).onHand, 2000);
      expect((await r.stock.movements(cones.id)).first.reason, StockReason.count);
      expect((await r.stock.movements(sprinkles.id)), hasLength(1), reason: 'no movement when the count matched');

      expect(await counts.open(), isNull);
      expect((await counts.find(id))!.status, StockCountStatus.posted);
      await expectLater(counts.post(id, by: owner), throwsA(isA<StockException>()));
      await expectLater(counts.setCount(id, cones.id, 1, by: owner), throwsA(isA<StockException>()));
    });

    test('sales during a count stay on top of the correction', () async {
      final tubs = await stockItem('Ice cream tubs, 500 ml');
      final id = await counts.start(blind: false, by: owner);
      await counts.setCount(id, tubs.id, 20, by: owner); // till expected 24
      await r.stock.adjust(tubs.id, -2, note: 'sold', by: owner); // after counting
      await counts.post(id, by: owner);
      expect((await stockItem('Ice cream tubs, 500 ml')).onHand, 18);
    });

    test('nothing counted cannot be posted; a cancelled count changes nothing', () async {
      final id = await counts.start(blind: false, by: owner);
      await expectLater(counts.post(id, by: owner), throwsA(isA<StockException>()));
      final cones = await stockItem('Wafer cones');
      await counts.setCount(id, cones.id, 5, by: owner);
      await counts.cancel(id, by: owner);
      expect(await counts.open(), isNull);
      expect((await counts.find(id))!.status, StockCountStatus.cancelled);
      expect((await stockItem('Wafer cones')).onHand, 200);
      expect(await r.audit.list(actions: {AuditAction.stockCountCancelled}), hasLength(1));
    });
  });

  group('Pricing', () {
    test('a scheduled price applies on its day, not before', () async {
      final waffle = await product('Waffle');
      final variantId = waffle.variants.single.id;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      await r.catalog.schedulePrice(variantId, 1400, day, by: owner);
      expect((await r.catalog.scheduledPrices()).single.oldPrice, 1200);

      expect(await r.catalog.applyDuePrices(), 0);
      expect((await product('Waffle')).variants.single.price, 1200);

      expect(await r.catalog.applyDuePrices(now: day.add(const Duration(hours: 1))), 1);
      expect((await product('Waffle')).variants.single.price, 1400);
      expect(await r.catalog.scheduledPrices(), isEmpty);
      expect(await r.audit.list(actions: {AuditAction.priceChanged}), hasLength(1));
    });

    test('a cancelled schedule never applies; today is not allowed', () async {
      final waffle = await product('Waffle');
      final variantId = waffle.variants.single.id;
      final id = await r.catalog.schedulePrice(variantId, 1400, DateTime.now().add(const Duration(days: 2)), by: owner);
      await r.catalog.cancelScheduledPrice(id, by: owner);
      expect(await r.catalog.scheduledPrices(), isEmpty);
      expect(await r.catalog.applyDuePrices(now: DateTime.now().add(const Duration(days: 5))), 0);
      expect((await r.audit.list(actions: {AuditAction.priceScheduleCancelled})).single.summary, startsWith('Waffle: GH₵ 14.00'));
      await expectLater(
        r.catalog.schedulePrice(variantId, 1400, DateTime.now().subtract(const Duration(minutes: 1)), by: owner),
        throwsA(isA<CatalogueException>()),
      );
    });

    test('bulk prices change together with one audit entry', () async {
      final cone = await product('Vanilla cone');
      final waffle = await product('Waffle');
      await r.catalog.bulkSetPrices(
        {
          cone.variants[0].id: 1600,
          cone.variants[1].id: 2200, // unchanged
          waffle.variants.single.id: 1300,
        },
        description: '+GH₵ 1.00',
        by: owner,
      );
      expect((await product('Vanilla cone')).variants.map((v) => v.price), [1600, 2200]);
      expect((await product('Waffle')).variants.single.price, 1300);
      final entries = await r.audit.list(actions: {AuditAction.pricesBulkChanged});
      expect(entries.single.summary, contains('2 prices'));
      // Names are kept with the prices, so the entry reads after a rename.
      final details = describeAuditDetails(entries.single) as PriceChanges;
      expect(details.rows.map((p) => (p.label, p.before, p.after)), [
        ('Vanilla cone, Single scoop', 1500, 1600),
        ('Waffle', 1200, 1300),
      ]);
    });
  });

  group('CatalogueIo', () {
    late CatalogueIo io;
    setUp(() => io = CatalogueIo(r.catalog, CatalogueRules(r.catalog), r.audit));

    test('export has one row per variant and reads back unchanged', () async {
      final csv = io.exportProducts(await r.catalog.load(includeInactive: true));
      final rows = Csv.decode(csv);
      expect(rows.first, CatalogueIo.productColumns);
      expect(rows.where((x) => x[1] == 'Ice cream cup'), hasLength(3));
      final preview = await io.previewProducts(csv);
      expect(preview.problems, isEmpty);
      expect(preview.drafts, isEmpty);
      expect(preview.unchanged, 6);
    });

    test('every kind of shop gets a sample that imports as it is', () async {
      for (final type in BusinessType.values) {
        final csv = io.sampleProducts(type);
        expect(Csv.decode(csv).first, CatalogueIo.productColumns, reason: type.name);
        final preview = await io.previewProducts(csv);
        expect(preview.problems, isEmpty, reason: type.name);
        expect(preview.canApply, isTrue, reason: type.name);
      }
    });

    test('the provision shop sample makes products with sizes, barcodes and pictured categories', () async {
      final preview = await io.previewProducts(io.sampleProducts(BusinessType.provision));
      await io.applyProducts(preview, by: owner);
      final rice = await product('Rice');
      expect(rice.variants.map((v) => (v.name, v.price)), [('1 kg', 2500), ('5 kg', 11500)]);
      expect((await product('Bottled water')).variants.single.barcodes, hasLength(2));
      expect((await product('Biscuits')).active, isFalse);
      final catalogue = await r.catalog.load(includeInactive: true);
      final toiletries = catalogue.categories.firstWhere((c) => c.name == 'Toiletries');
      expect(toiletries.picture, 'shopping-bag');
      expect(catalogue.categories.firstWhere((c) => c.name == 'Drinks').picture, 'cup-soda');
    });

    test('a price list with its own headings imports too', () async {
      const csv =
          '\uFEFFName,Selling Price,Cost price,Barcode,Department\n'
          'Sobolo,5.00,2.00,6001234567890,Drinks\n';
      final preview = await io.previewProducts(csv);
      expect(preview.problems, isEmpty);
      await io.applyProducts(preview, by: owner);
      final sobolo = await product('Sobolo');
      expect(sobolo.variants.single.price, 500);
      expect(sobolo.variants.single.manualCost, 200);
      expect(sobolo.variants.single.barcodes, ['6001234567890']);
    });

    test('import adds and updates, keeps recipes, and creates new categories', () async {
      const csv =
          'category,product,variant,price,cost\n'
          'Snacks,Waffle,,13.00,\n'
          'Drinks,Sobolo,,5.00,2.00\n'
          'Pastries,Meat pie,,8.00,\n'
          'Cones,Vanilla cone,Single scoop,15.00,\n';
      final preview = await io.previewProducts(csv);
      expect(preview.problems, isEmpty);
      expect(preview.newProducts, 2);
      expect(preview.updatedProducts, 1);
      expect(preview.unchanged, 1);
      expect(preview.newCategories, ['Pastries']);

      await io.applyProducts(preview, by: owner);
      final waffle = await product('Waffle');
      expect(waffle.variants.single.price, 1300);
      expect(waffle.variants.single.recipe, isNotEmpty);
      expect(waffle.groups, isNotEmpty);
      expect((await product('Sobolo')).variants.single.manualCost, 200);
      final catalogue = await r.catalog.load(includeInactive: true);
      final pie = catalogue.products.firstWhere((p) => p.name == 'Meat pie');
      expect(catalogue.category(pie.categoryId)!.name, 'Pastries');
      expect((await product('Vanilla cone')).variants, hasLength(2));
      expect(await r.audit.list(actions: {AuditAction.catalogueImported}), hasLength(1));
    });

    test('problems are reported by row and block the import', () async {
      const csv = 'category,product,price\nSnacks,Waffle,abc\nSnacks,,5.00\nDrinks,Sobolo,5.00\nDrinks,Kelewele,\n';
      final preview = await io.previewProducts(csv);
      expect(preview.problems.map((p) => p.row), containsAll([2, 3, 5]));
      expect(
        preview.problems.map((p) => p.row),
        isNot(contains(4)),
        reason: 'Sobolo is fine; the file still cannot be imported',
      );
      expect(preview.canApply, isFalse);
      await expectLater(io.applyProducts(preview, by: owner), throwsA(isA<CatalogueException>()));
      expect((await r.catalog.load()).products.where((p) => p.name == 'Sobolo'), isEmpty);
    });

    test('a file without product and price columns is refused', () async {
      final preview = await io.previewProducts('name,cost\nWaffle,1.00\n');
      expect(preview.problems.single.row, 1);
    });
  });
}
