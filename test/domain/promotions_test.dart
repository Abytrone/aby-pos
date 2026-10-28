import 'package:aby_pos/app/domain/pricing.dart';
import 'package:aby_pos/app/domain/promotions.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const shake = Product(
  id: 'p-shake',
  categoryId: 'c-drinks',
  name: 'Milkshake',
  variants: [Variant(id: 'v-shake', price: 2000)],
);

Promotion promo(
  PromotionKind kind,
  PromoRule rule, {
  String name = 'Deal',
  bool stackable = false,
  int days = 127,
  int? from,
  int? to,
  DateTime? startsOn,
  DateTime? endsOn,
}) =>
    Promotion(
      id: name,
      name: name,
      kind: kind,
      rule: rule,
      stackable: stackable,
      days: days,
      fromMinute: from,
      toMinute: to,
      startsOn: startsOn,
      endsOn: endsOn,
    );

// Wednesday 28 October 2026, 15:00.
final at = DateTime(2026, 10, 28, 15);

void main() {
  const cones = PromoTarget(categories: {'c-cones'});

  test('percent off: a happy hour only in its hours and on its days', () {
    final happy = promo(PromotionKind.percentOff, const PromoRule(target: cones, percent: 15),
        name: 'Happy hour', from: 14 * 60, to: 16 * 60, days: 0x1F);
    final lines = [CartLine(product: vanillaCone, quantity: 2), CartLine(product: waffle)];
    final r = PromotionEngine.apply(lines, [happy], at);
    expect(r.off, [450, 0], reason: '15% of 2 x 15.00');
    expect(r.names.first, ['Happy hour']);
    expect(PromotionEngine.apply(lines, [happy], DateTime(2026, 10, 28, 16)).total, 0, reason: 'ends at 4 pm');
    expect(PromotionEngine.apply(lines, [happy], DateTime(2026, 10, 31, 15)).total, 0, reason: 'not on Saturday');
    final late = promo(PromotionKind.percentOff, const PromoRule(percent: 10), from: 22 * 60, to: 2 * 60);
    expect(late.runsAt(DateTime(2026, 10, 28, 23, 30)), isTrue, reason: 'windows can pass midnight');
    expect(late.runsAt(DateTime(2026, 10, 28, 3)), isFalse);
    final dated = promo(PromotionKind.percentOff, const PromoRule(percent: 10), endsOn: DateTime(2026, 10, 27));
    expect(dated.runsAt(at), isFalse);
  });

  test('buy 2 get 1 free: the cheapest item is free, and it repeats', () {
    final deal = promo(PromotionKind.buyGet, const PromoRule(target: cones, quantity: 2, rewardQuantity: 1, percent: 100));
    final lines = [
      CartLine(product: vanillaCone, variant: double_, quantity: 2),
      CartLine(product: vanillaCone, quantity: 1),
    ];
    var r = PromotionEngine.apply(lines, [deal], at);
    expect(r.off, [0, 1500]);
    r = PromotionEngine.apply([CartLine(product: vanillaCone, quantity: 6)], [deal], at);
    expect(r.off.single, 3000, reason: 'two free out of six');
    expect(PromotionEngine.apply([CartLine(product: vanillaCone, quantity: 2)], [deal], at).total, 0,
        reason: 'the third cone must be in the cart');
  });

  test('bundle price, quantity price and spend rewards', () {
    final bundle = promo(PromotionKind.bundle,
        const PromoRule(parts: [cones, PromoTarget(products: {'p-shake'})], amount: 3200));
    final lines = [CartLine(product: vanillaCone), CartLine(product: shake)];
    final r = PromotionEngine.apply(lines, [bundle], at);
    expect(r.total, 1500 + 2000 - 3200);
    expect(r.off, [129, 171], reason: 'shared in proportion');

    final tubs = promo(PromotionKind.quantityBreak,
        const PromoRule(target: PromoTarget(products: {'p-waffle'}), quantity: 6, amount: 1000));
    expect(PromotionEngine.apply([CartLine(product: waffle, quantity: 5)], [tubs], at).total, 0);
    expect(PromotionEngine.apply([CartLine(product: waffle, quantity: 6)], [tubs], at).total, 6 * 200);

    final free = promo(PromotionKind.spend,
        const PromoRule(threshold: 5000, spendReward: SpendReward.free, reward: PromoTarget(products: {'p-waffle'})));
    final big = [CartLine(product: vanillaCone, variant: double_, quantity: 2), CartLine(product: waffle)];
    expect(PromotionEngine.apply(big, [free], at).off, [0, 1200]);
    expect(PromotionEngine.apply(big.sublist(0, 1), [free], at).total, 0, reason: 'no waffle in the cart');
    final pct = promo(PromotionKind.spend, const PromoRule(threshold: 5000, percent: 10));
    expect(PromotionEngine.apply(big, [pct], at).total, 560);
  });

  test('the best deal wins; stacking ones add on; nothing goes below zero', () {
    final ten = promo(PromotionKind.percentOff, const PromoRule(percent: 10), name: 'Ten');
    final twenty = promo(PromotionKind.percentOff, const PromoRule(target: cones, percent: 20), name: 'Twenty');
    final lines = [CartLine(product: vanillaCone), CartLine(product: waffle)];
    final r = PromotionEngine.apply(lines, [ten, twenty], at);
    expect(r.total, 300, reason: 'Twenty saves 3.00, Ten saves 2.70');
    expect(r.names[0], ['Twenty']);

    final stack = promo(PromotionKind.percentOff, const PromoRule(percent: 100), name: 'All', stackable: true);
    final both = PromotionEngine.apply(lines, [twenty, stack], at);
    expect(both.off, [1500, 1200], reason: 'never more than the line');
  });

  test('pricing: promotions come off before the order discount and show on the line', () {
    final happy = promo(PromotionKind.percentOff, const PromoRule(percent: 50), name: 'Half');
    final lines = [CartLine(product: waffle, quantity: 2)];
    final pricing = CartPricing.of(
      lines,
      orderDiscount: const Discount(kind: DiscountKind.percent, value: 10, reason: 'Staff'),
      promotions: PromotionEngine.apply(lines, [happy], at),
    );
    expect(pricing.lines.single.promotion, 1200);
    expect(pricing.lines.single.promotionNames, ['Half']);
    expect(pricing.orderDiscountAmount, 120, reason: '10% of what is left');
    expect(pricing.total, 2400 - 1200 - 120);
    expect(pricing.discountTotal, 1320);
    expect(pricing.promotionTotal, 1200);
  });

  test('rules round trip as JSON', () {
    const rule = PromoRule(
      target: cones,
      reward: PromoTarget(products: {'p-waffle'}),
      parts: [cones],
      percent: 100,
      quantity: 2,
      spendReward: SpendReward.free,
    );
    final back = PromoRule.decode(rule.encode());
    expect(back.target.categories, {'c-cones'});
    expect(back.reward.products, {'p-waffle'});
    expect(back.parts.single.categories, {'c-cones'});
    expect((back.percent, back.quantity, back.spendReward), (100, 2, SpendReward.free));
  });
}
