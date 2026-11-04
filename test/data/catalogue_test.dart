import 'package:aby_pos/app/core/tax.dart';
import 'package:aby_pos/app/core/units.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/domain/catalogue_rules.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('computeTax', () {
    const nhil = TaxRateSpec(id: 'n', name: 'NHIL', rateBp: 250);
    const getfund = TaxRateSpec(id: 'g', name: 'GETFund', rateBp: 250);
    const vat = TaxRateSpec(id: 'v', name: 'VAT', rateBp: 1500, compound: true);

    test('exclusive adds levies, then VAT on top of them', () {
      final r = computeTax(10000, [nhil, getfund, vat], TaxMode.exclusive);
      expect(r.base, 10000);
      expect(r.taxes.map((t) => t.amount), [250, 250, 1575]);
      expect(r.total, 12075);
    });

    test('inclusive splits the price so the parts add up exactly', () {
      final r = computeTax(12075, [nhil, getfund, vat], TaxMode.inclusive);
      expect(r.base, 10000);
      expect(r.total, 12075);
      for (final price in [1, 99, 1500, 2200, 12345, 999999]) {
        final x = computeTax(price, [nhil, getfund, vat], TaxMode.inclusive);
        expect(x.base + x.taxTotal, price, reason: '$price');
      }
    });

    test('off, or no rates, means no tax', () {
      expect(computeTax(1500, [vat], TaxMode.off).taxTotal, 0);
      expect(computeTax(1500, const [], TaxMode.exclusive).total, 1500);
    });
  });

  group('units', () {
    test('format and parse in friendly units', () {
      expect(formatQuantity(12, StockUnit.piece), '12 pcs');
      expect(formatQuantity(750, StockUnit.g), '750 g');
      expect(formatQuantity(2500, StockUnit.g), '2.5 kg');
      expect(formatQuantity(1250, StockUnit.ml), '1.25 L');
      expect(formatQuantity(-1500, StockUnit.ml), '-1.5 L');
      expect(parseQuantity('2.5', DisplayUnit.kg), 2500);
      expect(parseQuantity('80', DisplayUnit.ml), 80);
      expect(
        parseQuantity('1.5', DisplayUnit.g),
        isNull,
        reason: 'no fractions of a gram',
      );
      expect(parseQuantity('abc', DisplayUnit.l), isNull);
    });

    test('costs stay exact in thousandths of a pesewa', () {
      // GH₵ 33 for 24 cones: 137.5 pesewas each.
      final perCone = costMilliFromPrice(3300, DisplayUnit.piece) ~/ 24;
      expect(perCone, 137500);
      expect(costOf(24, perCone), 3300);
      // GH₵ 45 per litre: 4.5 pesewas per ml.
      final perMl = costMilliFromPrice(4500, DisplayUnit.l);
      expect(perMl, 4500);
      expect(costOf(80, perMl), 360);
      expect(priceForUnit(perMl, DisplayUnit.l), 4500);
    });
  });

  group('CatalogueRules', () {
    late AppDatabase db;
    late Repos r;
    late CatalogRepository catalog;
    late CatalogueRules rules;
    late String categoryId;
    late String cones;

    setUp(() async {
      db = memoryDb();
      r = await Repos.open(db);
      catalog = CatalogRepository(db, r.device, r.audit);
      rules = CatalogueRules(catalog);
      categoryId = (await catalog.categories()).first.id;
      cones = (await r.stock.items())
          .firstWhere((s) => s.name == 'Wafer cones')
          .id;
    });

    tearDown(() => db.close());

    test(
      'a new product with sizes, recipes and barcodes is saved and audited',
      () async {
        final id = await rules.saveProduct(
          ProductDraft(
            categoryId: categoryId,
            name: 'Kids cone',
            variants: [
              VariantDraft(
                name: 'Small',
                price: 800,
                barcodes: ['600123'],
                recipe: [RecipeDraftLine(stockItemId: cones, quantity: 1)],
              ),
              const VariantDraft(name: 'Big', price: 1000, manualCost: 300),
            ],
          ),
          by: owner,
        );
        final p = (await catalog.load()).products.firstWhere((x) => x.id == id);
        expect(p.variants.map((v) => v.name), ['Small', 'Big']);
        expect(p.variants.first.cost, 80);
        expect(p.variants.last.cost, 300);
        expect(p.variants.first.barcodes, ['600123']);
        expect(await catalog.findBarcode('600123'), (id, p.variants.first.id));
        expect((await r.audit.list()).first.action, AuditAction.productCreated);
      },
    );

    test(
      'a direct stock link supplies cost and deducts its configured quantity',
      () async {
        final before = await r.stock.onHand(cones);
        final id = await rules.saveProduct(
          ProductDraft(
            categoryId: categoryId,
            name: 'Soda six-pack',
            variants: [
              VariantDraft(price: 300, stockItemId: cones, stockQuantity: 6),
            ],
          ),
          by: owner,
        );
        final product = (await catalog.load()).products.singleWhere(
          (p) => p.id == id,
        );
        expect(product.variants.single.recipe, isEmpty);
        expect(product.variants.single.stockLink?.quantity, 6);
        expect(product.variants.single.cost, 480);
        expect(await r.stock.usedBy(cones), contains('Soda six-pack'));

        await r.sales.completeSale(
          lines: [CartLine(product: product)],
          payment: const PaymentInput.cash(tendered: 500),
          cashier: cashier,
        );
        expect(await r.stock.onHand(cones), before - 6);

        await rules.saveProduct(
          ProductDraft(
            id: id,
            categoryId: product.categoryId,
            name: product.name,
            variants: [
              VariantDraft(
                id: product.variants.single.id,
                price: product.variants.single.price,
                stockItemId: cones,
                stockQuantity: 5,
              ),
            ],
          ),
          by: owner,
        );
        final linkAudit = (await r.audit.list(
          actions: {AuditAction.productUpdated},
        )).single;
        expect(linkAudit.summary, contains('inventory quantity'));
      },
    );

    test('rules: names, duplicate sizes, barcodes already used', () async {
      Future<void> fails(ProductDraft d) => expectLater(
        rules.saveProduct(d, by: owner),
        throwsA(isA<CatalogueException>()),
      );
      await fails(
        ProductDraft(
          categoryId: categoryId,
          name: ' ',
          variants: const [VariantDraft(price: 100)],
        ),
      );
      await fails(
        ProductDraft(
          categoryId: 'nope',
          name: 'X',
          variants: const [VariantDraft(price: 100)],
        ),
      );
      await fails(
        ProductDraft(categoryId: categoryId, name: 'X', variants: const []),
      );
      await fails(
        ProductDraft(
          categoryId: categoryId,
          name: 'X',
          variants: const [
            VariantDraft(name: 'Small', price: 100),
            VariantDraft(name: 'small', price: 200),
          ],
        ),
      );
      await rules.saveProduct(
        ProductDraft(
          categoryId: categoryId,
          name: 'A',
          variants: const [
            VariantDraft(price: 100, barcodes: ['111']),
          ],
        ),
        by: owner,
      );
      await fails(
        ProductDraft(
          categoryId: categoryId,
          name: ' a ',
          variants: const [VariantDraft(price: 100)],
        ),
      );
      await fails(
        ProductDraft(
          categoryId: categoryId,
          name: 'B',
          variants: const [
            VariantDraft(price: 100, barcodes: [' 111 ']),
          ],
        ),
      );
    });

    test('changing a price is recorded with before and after; removed sizes are retired', () async {
      final cone = (await catalog.load()).products.firstWhere(
        (p) => p.name == 'Vanilla cone',
      );
      final single = cone.variants.first;
      await rules.saveProduct(
        ProductDraft(
          id: cone.id,
          categoryId: cone.categoryId,
          name: cone.name,
          variants: [
            VariantDraft(id: single.id, name: single.name, price: 1600),
          ],
          groupIds: [for (final g in cone.groups) g.id],
        ),
        by: owner,
      );
      final after = (await catalog.load()).products.firstWhere(
        (p) => p.id == cone.id,
      );
      expect(after.variants.single.price, 1600);
      expect(
        after.variants.single.recipe,
        isEmpty,
        reason: 'the recipe was not in the draft',
      );
      final price = (await r.audit.list(actions: {AuditAction.priceChanged}))
          .single;
      expect(price.details, {'before': 1500, 'after': 1600});
      expect(
        (await r.audit.list(actions: {AuditAction.productUpdated}))
            .single
            .summary,
        contains('removed Double scoop'),
      );
    });

    test('archived products leave the till but stay readable', () async {
      final waffle = (await catalog.load()).products.firstWhere(
        (p) => p.name == 'Waffle',
      );
      await catalog.setArchived(waffle.id, archived: true, by: owner);
      expect(
        (await catalog.load()).products.any((p) => p.id == waffle.id),
        isFalse,
      );
      expect(
        (await catalog.load(includeArchived: true)).products
            .firstWhere((p) => p.id == waffle.id)
            .archived,
        isTrue,
      );
    });

    test('option groups: rules are checked', () async {
      Future<void> fails(OptionGroupDraft d) => expectLater(
        rules.saveOptionGroup(d, by: owner),
        throwsA(isA<CatalogueException>()),
      );
      await fails(const OptionGroupDraft(name: 'Sugar', options: []));
      await fails(
        const OptionGroupDraft(
          name: 'Sugar',
          minSelect: 2,
          maxSelect: 1,
          options: [OptionDraft(name: 'Less')],
        ),
      );
      await fails(
        const OptionGroupDraft(
          name: 'Sugar',
          minSelect: 2,
          options: [OptionDraft(name: 'Less')],
        ),
      );
      final id = await rules.saveOptionGroup(
        const OptionGroupDraft(
          name: 'Sugar',
          minSelect: 1,
          maxSelect: 1,
          options: [
            OptionDraft(name: 'Normal', isDefault: true),
            OptionDraft(name: 'Less'),
          ],
        ),
        by: owner,
      );
      final g = (await catalog.load()).groups.firstWhere((x) => x.id == id);
      expect(g.required, isTrue);
      expect(g.defaults.single.name, 'Normal');
      expect(g.accepts(1), isTrue);
      expect(g.accepts(2), isFalse);
    });

    test('categories go two levels deep at most', () async {
      final top = await rules.saveCategory(
        const CategoryDraft(name: 'Ice cream', tone: CategoryTone.blue),
        by: owner,
      );
      final sub = await rules.saveCategory(
        CategoryDraft(name: 'Cones', tone: CategoryTone.coral, parentId: top),
        by: owner,
      );
      await expectLater(
        rules.saveCategory(
          CategoryDraft(name: 'Deep', tone: CategoryTone.coral, parentId: sub),
          by: owner,
        ),
        throwsA(isA<CatalogueException>()),
      );
    });
  });

  group('one-tap and picker rules', () {
    test('a tap opens the picker for sizes or options; it can go in as it stands when defaults cover it', () {
      expect(waffle.oneTap, isFalse, reason: 'optional toppings are offered');
      expect(waffle.addsAsIs, isTrue, reason: 'a plain waffle is fine');
      expect(vanillaCone.oneTap, isFalse, reason: 'two sizes');
      expect(vanillaCone.addsAsIs, isFalse);
      const sugar = OptionGroup(
        id: 'g',
        name: 'Sugar',
        minSelect: 1,
        maxSelect: 1,
        options: [Option(id: 'a', groupId: 'g', name: 'Normal')],
      );
      const tea = Product(
        id: 't',
        categoryId: 'c',
        name: 'Tea',
        variants: [Variant(id: 'vt', price: 500)],
        groups: [sugar],
      );
      expect(tea.oneTap, isFalse);
      expect(tea.addsAsIs, isFalse, reason: 'sugar must be chosen');
      const sugarWithDefault = OptionGroup(
        id: 'g',
        name: 'Sugar',
        minSelect: 1,
        maxSelect: 1,
        options: [
          Option(id: 'a', groupId: 'g', name: 'Normal', isDefault: true),
        ],
      );
      const tea2 = Product(
        id: 't',
        categoryId: 'c',
        name: 'Tea',
        variants: [Variant(id: 'vt', price: 500)],
        groups: [sugarWithDefault],
      );
      expect(tea2.oneTap, isFalse);
      expect(tea2.addsAsIs, isTrue);
      const water = Product(
        id: 'w',
        categoryId: 'c',
        name: 'Water',
        variants: [Variant(id: 'vw', price: 300)],
      );
      expect(water.oneTap, isTrue);
    });

    test('repeated options price and key correctly', () {
      final line = CartLine(
        product: waffle,
        options: [sprinkles, sprinkles, crunch],
      );
      expect(line.unitPrice, 1200 + 300 + 300 + 500);
      expect(line.optionsLine, 'Groundnut crunch, Sprinkles ×2');
      expect(
        CartLine(
          product: waffle,
          options: [crunch, sprinkles, sprinkles],
        ).pickKey,
        line.pickKey,
      );
    });
  });
}
