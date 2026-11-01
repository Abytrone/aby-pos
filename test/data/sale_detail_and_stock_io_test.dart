import 'package:aby_pos/app/core/units.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/receipt_repository.dart';
import 'package:aby_pos/app/domain/catalogue_io.dart';
import 'package:aby_pos/app/domain/catalogue_rules.dart';
import 'package:aby_pos/app/domain/stock_io.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late StockIo io;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    io = StockIo(db, r.stock, r.catalog, CatalogueRules(r.catalog), r.audit);
  });
  tearDown(() => db.close());

  Future<Product> product(String name) async =>
      (await r.catalog.load(includeInactive: true)).products.firstWhere((p) => p.name == name);
  Future<StockItem> stockItem(String name) async =>
      (await r.stock.items(includeInactive: true)).firstWhere((i) => i.name == name);

  group('A sale in full', () {
    test('discounts with reasons and approvers, a changed price, a weighed line, profit and history', () async {
      final sugar = await stockItem('Waffle mix');
      final rules = CatalogueRules(r.catalog);
      final cones = (await r.catalog.categories()).first.id;
      await rules.saveProduct(
        ProductDraft(
          categoryId: cones,
          name: 'Sugar (loose)',
          sellBy: SellBy.kg,
          variants: [
            VariantDraft(price: 2000, recipe: [RecipeDraftLine(stockItemId: sugar.id, quantity: 1000)]),
          ],
        ),
        by: owner,
      );
      final waffle = await product('Waffle');
      final cone = await product('Vanilla cone');
      final loose = await product('Sugar (loose)');
      final done = await r.sales.completeSale(
        lines: [
          CartLine(
            product: waffle,
            quantity: 2,
            discount: const Discount(kind: DiscountKind.percent, value: 20, reason: 'Damaged', approvedBy: 'Kofi'),
          ),
          CartLine(product: cone, customPrice: 1000, priceOverriddenBy: 'Kofi'),
          CartLine(product: loose, quantity: 534),
        ],
        payment: const PaymentInput.cash(tendered: 5000),
        cashier: cashier,
        orderDiscount: const Discount(kind: DiscountKind.amount, value: 100, reason: 'Regular customer', name: 'Loyal'),
      );

      final d = (await ReceiptRepository(db).detail(done.saleId))!;
      expect(d.lines, hasLength(3));
      final w = d.lines.firstWhere((l) => l.line.name == 'Waffle');
      expect(w.discount!.reason, 'Damaged');
      expect(w.discount!.approvedBy, 'Kofi');
      expect(w.line.discount, 480, reason: '20% of 24.00');
      final c = d.lines.firstWhere((l) => l.line.name == 'Vanilla cone');
      expect(c.priceChanged, isTrue);
      expect(c.priceOverriddenBy, 'Kofi');
      expect(c.listPrice, 1500);
      expect(d.orderDiscount!.name, 'Loyal');
      expect(d.receipt.orderDiscount, 100);
      expect(d.cost, greaterThan(0));
      expect(d.profit, d.takings - d.cost);
      expect(d.margin, isNotNull);

      final history = await r.audit.list(entityId: done.saleId);
      expect(history.map((e) => e.action), containsAll([AuditAction.discountsGiven, AuditAction.priceOverridden]));

      // The list row: a weighed line is one item, not 534.
      final sale = (await r.sales.watchToday(dayStartMinutes: 0).first).single;
      expect(sale.itemCount, 4);
      expect(sale.items, ['2 x Waffle', 'Vanilla cone (Single scoop)', 'Sugar (loose)']);
      expect(sale.discountTotal, 580);
    });
  });

  group('Prices from costs', () {
    test('margin is a share of the price, markup is added to the cost; both round up', () {
      expect(priceFromCost(600, 40, PriceRule.margin), 1000);
      expect(priceFromCost(600, 40, PriceRule.markup), 840);
      expect(priceFromCost(210, 30, PriceRule.margin), 300);
      expect(priceFromCost(333, 50, PriceRule.margin), 666);
      expect(priceFromCost(333, 50, PriceRule.margin, step: 50), 700);
      expect(priceFromCost(100, 0, PriceRule.margin), 100);
      expect(priceFromCost(100, 100, PriceRule.margin), isNull);
      expect(priceFromCost(0, 30, PriceRule.markup), isNull);
    });
  });

  group('Stock import', () {
    test('adds new items, updates costs and counts as adjustments, reads other headings', () async {
      final before = await stockItem('Sprinkles');
      final preview = await io.previewStock(
        'Item name,UOM,Per,Unit cost,Qty,Reorder level\n'
        'Bottled water,pcs,pcs,2.10,48,12\n'
        'Sprinkles,g,kg,50.00,3.5,\n'
        'Coconut flakes,,kg,30,1.25,0.5\n',
      );
      expect(preview.problems, isEmpty);
      expect(preview.newItems, 2);
      expect(preview.updatedItems, 1);
      expect(preview.recounted, 3);
      await io.applyStock(preview, by: owner);

      final water = await stockItem('Bottled water');
      expect(water.unit, StockUnit.piece);
      expect(water.onHand, 48);
      expect(water.reorderPoint, 12);
      expect(water.bulkPrice, 210);
      final flakes = await stockItem('Coconut flakes');
      expect(flakes.unit, StockUnit.g, reason: 'kg means grams are kept');
      expect(flakes.onHand, 1250);
      expect(flakes.reorderPoint, 500);
      final sprinkles = await stockItem('Sprinkles');
      expect(sprinkles.onHand, 3500);
      expect(sprinkles.bulkPrice, 5000);
      expect(sprinkles.reorderPoint, before.reorderPoint, reason: 'empty keeps it');
      final moves = await r.stock.movements(sprinkles.id);
      expect(moves.first.note, 'Stock import');
      expect(await r.audit.list(actions: {AuditAction.stockImported}), hasLength(1));

      // The same file again changes nothing.
      final again = await io.previewStock(
        'stock_item,unit,cost_per,cost,on_hand,low_below\nBottled water,piece,pcs,2.10,48,12\n',
      );
      expect(again.unchanged, 1);
      expect(again.canApply, isFalse);
    });

    test('problems point at the row', () async {
      final preview = await io.previewStock(
        'stock_item,unit,cost_per,cost,on_hand\n'
        'Cups,boxes,,1.00,\n'
        'Sugar,piece,kg,1.00,\n'
        ',piece,,1,\n'
        'Lids,piece,,abc,\n'
        'Lids,piece,,1,\n',
      );
      // Row 6 repeats Lids, already in the file at row 5.
      expect(preview.problems.map((p) => p.row), [2, 3, 4, 5, 6]);
      expect(preview.canApply, isFalse);
      expect((await io.previewStock('name\n')).problems, isEmpty);
      expect((await io.previewStock('product,price\nA,1\n')).problems, isEmpty, reason: '"product" reads as the item');
      expect((await io.previewStock('cost\n1\n')).problems.single.row, 1);
    });

    test('the export reads back in', () async {
      final items = await r.stock.items(includeInactive: true);
      final csv = CatalogueIo(r.catalog, CatalogueRules(r.catalog), r.audit).exportStock(items);
      final preview = await io.previewStock(csv);
      expect(preview.problems, isEmpty);
      expect(preview.newItems, 0);
    });
  });

  group('Products from stock', () {
    test('plans flag items already sold; made products sell from their stock item at the price asked', () async {
      final water = await r.stock.saveItem(
        StockItemDraft(name: 'Bottled water', unit: StockUnit.piece, costMilli: costMilliFromPrice(210, DisplayUnit.piece)),
        by: owner,
      );
      await r.stock.adjust(water, 24, note: 'Opening', by: owner);
      final plans = await io.productPlans();
      final cones = plans.firstWhere((p) => p.item.name == 'Wafer cones');
      expect(cones.alreadySold, isTrue);
      expect(cones.suggested, isFalse);
      final plan = plans.firstWhere((p) => p.item.id == water);
      expect(plan.suggested, isTrue);
      expect(plan.cost, 210);
      final sugar = plans.firstWhere((p) => p.item.name == 'Groundnut crunch');
      expect(sugar.sellBy, SellBy.kg);
      expect(sugar.recipeQuantity, 1000);

      final made = await io.createProducts(
        [plan, sugar],
        prices: {water: priceFromCost(plan.cost, 30, PriceRule.margin)!, sugar.item.id: 2000},
        newCategory: 'Shop items',
        by: owner,
      );
      expect(made, 2);
      final bottle = await product('Bottled water');
      expect(bottle.variants.single.price, 300);
      expect(bottle.variants.single.recipe.single.stockItemId, water);
      expect((await product('Groundnut crunch')).sellBy, SellBy.kg);
      expect((await r.catalog.categories()).map((c) => c.name), contains('Shop items'));

      await r.sales.completeSale(
        lines: [CartLine(product: bottle, quantity: 2)],
        payment: const PaymentInput.cash(tendered: 1000),
        cashier: cashier,
      );
      expect((await stockItem('Bottled water')).onHand, 22);
      expect((await io.productPlans()).firstWhere((p) => p.item.id == water).alreadySold, isTrue);
      expect(await r.audit.list(actions: {AuditAction.productsFromStock}), hasLength(1));
    });
  });
}
