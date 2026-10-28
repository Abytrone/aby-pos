import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/promotion_repository.dart';
import 'package:aby_pos/app/data/repositories/receipt_repository.dart';
import 'package:aby_pos/app/domain/promotions.dart';
import 'package:aby_pos/app/domain/receipt/receipt_builder.dart';
import 'package:aby_pos/app/domain/receipt/receipt_doc.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;
  late PromotionRepository promotions;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    promotions = PromotionRepository(db, r.device, r.audit);
  });
  tearDown(() => db.close());

  test('promotions are saved, listed, changed and deleted, with the activity log', () async {
    final id = await promotions.save(
      const Promotion(id: '', name: 'Happy hour', kind: PromotionKind.percentOff, rule: PromoRule(percent: 15), fromMinute: 840, toMinute: 960),
      by: owner,
    );
    var list = await promotions.list();
    expect(list.single.name, 'Happy hour');
    expect(list.single.fromMinute, 840);
    expect(list.single.rule.percent, 15);
    await promotions.save(
      Promotion(id: id, name: 'Happy hour', kind: PromotionKind.percentOff, rule: const PromoRule(percent: 20), active: false),
      by: owner,
    );
    list = await promotions.list();
    expect((list.single.rule.percent, list.single.active), (20, false));
    await promotions.delete(id, by: owner);
    expect(await promotions.list(), isEmpty);
    expect(await r.audit.list(actions: {AuditAction.promotionSaved}), hasLength(3));
  });

  test('a sale with a promotion: saved on the line, refunds, receipts and reports count it', () async {
    final half = Promotion(
      id: 'p1',
      name: 'Waffle Wednesday',
      kind: PromotionKind.percentOff,
      rule: PromoRule(target: PromoTarget(products: {named('Waffle').id}), percent: 50),
    );
    final sale = await r.sales.completeSale(
      lines: [
        CartLine(product: named('Waffle'), quantity: 2),
        CartLine(product: named('Milkshake'), discount: const Discount(kind: DiscountKind.amount, value: 200, reason: 'Staff')),
      ],
      payments: [const PaymentInput.cash(tendered: 10000)],
      cashier: cashier,
      promotions: [half],
    );
    expect(sale.total, 2400 - 1200 + 2000 - 200);

    final lines = await (db.select(db.saleLines)..where((l) => l.saleId.equals(sale.saleId))).get();
    final waffleLine = lines.firstWhere((l) => l.productName == 'Waffle');
    expect((waffleLine.discount, waffleLine.promotion, waffleLine.promotionName), (1200, 1200, 'Waffle Wednesday'));
    final saleRow = await (db.select(db.sales)..where((s) => s.id.equals(sale.saleId))).getSingle();
    expect(saleRow.discountTotal, 1400);

    // A refund gives back what was paid, after the promotion.
    final refundable = (await r.refunds.refundable(sale.saleId))!;
    expect(refundable.lines.firstWhere((l) => l.title.startsWith('Waffle')).paid, 1200);

    // The receipt shows the promotion apart from the manual discount.
    final data = (await ReceiptRepository(db).sale(sale.saleId))!;
    final w = data.lines.firstWhere((l) => l.name == 'Waffle');
    expect((w.discount, w.promotion), (0, 1200));
    final text = ReceiptBuilder.sale(data, const ReceiptDesign(shopName: 'S')).toText(Paper.mm80);
    expect(RegExp(r'Waffle Wednesday\s+-12\.00').hasMatch(text), isTrue);
    expect(RegExp(r'Discount\s+-2\.00').hasMatch(text), isTrue);

    // Reports: promotions inside discounts; the cashier only gave the 2.00.
    final month = DateRange.of(ReportPeriod.thisMonth, DateTime.now());
    final s = await r.reports.sales(month);
    expect((s.discounts, s.promotions), (1400, 1200));
    expect((await r.reports.staff(month)).firstWhere((x) => x.name == 'Ama').discounts, 200);
    expect((await r.reports.products(month)).firstWhere((p) => p.name == 'Waffle').revenue, 1200);
  });

  test('combos: an option linked to a product uses up its recipe', () async {
    final shake = named('Milkshake');
    await r.catalog.saveOptionGroup(
      OptionGroupDraft(
        name: 'Pick a drink',
        minSelect: 1,
        maxSelect: 1,
        options: [OptionDraft(name: 'Milkshake', variantId: shake.variants.single.id)],
      ),
      by: owner,
    );
    menu = await r.catalog.load(includeInactive: true);
    final drink = menu.groups.firstWhere((g) => g.name == 'Pick a drink').options.single;
    expect(drink.variantId, shake.variants.single.id);
    expect(drink.recipe.map((x) => x.stockItemName), containsAll(['Milk']), reason: "the milkshake's recipe");

    final milk = (await r.stock.items()).firstWhere((i) => i.name == 'Milk');
    await r.sales.completeSale(
      lines: [CartLine(product: named('Waffle'), options: [drink])],
      payments: [const PaymentInput.cash(tendered: 5000)],
      cashier: cashier,
    );
    final after = (await r.stock.items()).firstWhere((i) => i.name == 'Milk');
    expect(milk.onHand - after.onHand, 200);
  });
}
