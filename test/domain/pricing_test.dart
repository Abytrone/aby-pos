import 'package:aby_pos/app/core/scale_barcode.dart';
import 'package:aby_pos/app/core/tax.dart';
import 'package:aby_pos/app/domain/pricing.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

const rice = Product(
  id: 'p-rice',
  categoryId: 'c-dry',
  name: 'Rice',
  sellBy: SellBy.kg,
  variants: [Variant(id: 'v-rice', price: 1500)],
);

const vat = TaxRate(id: 't-vat', name: 'VAT', rateBp: 1500);
const taxedWaffle = Product(
  id: 'p-waffle',
  categoryId: 'c-snacks',
  name: 'Waffle',
  variants: [Variant(id: 'v-waffle', price: 1150)],
  taxes: [vat],
);

Discount percent(int v) => Discount(kind: DiscountKind.percent, value: v, reason: 'Regular customer');
Discount amount(int v) => Discount(kind: DiscountKind.amount, value: v, reason: 'Staff');

/// Thirteen digits from twelve, with the EAN check digit.
String ean13(String twelve) {
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    sum += int.parse(twelve[i]) * (i.isEven ? 1 : 3);
  }
  return '$twelve${(10 - sum % 10) % 10}';
}

void main() {
  group('Discount', () {
    test('percentages round half up and never take more than the base', () {
      expect(percent(10).amountOn(1200), 120);
      expect(percent(15).amountOn(1050), 158, reason: '157.5 rounds up');
      expect(amount(5000).amountOn(1200), 1200);
      expect(percent(10).amountOn(0), 0);
    });

    test('the percentage of a sale an amount is, rounded up, for role limits', () {
      expect(Discount.percentOf(120, 1200), 10);
      expect(Discount.percentOf(121, 1200), 11);
      expect(Discount.percentOf(500, 0), 0);
    });

    test('round trip through JSON keeps the approval', () {
      final d = amount(500).copyWith(approvedBy: 'Kofi');
      final back = Discount.fromJson(d.toJson());
      expect(back.kind, DiscountKind.amount);
      expect(back.value, 500);
      expect(back.reason, 'Staff');
      expect(back.approvedBy, 'Kofi');
    });
  });

  group('CartPricing', () {
    test('allocate splits exactly, leftovers to the largest remainders', () {
      expect(CartPricing.allocate(100, [1, 1, 1]), [34, 33, 33]);
      expect(CartPricing.allocate(500, [1080, 2200]), [165, 335]);
      expect(CartPricing.allocate(0, [5, 5]), [0, 0]);
      expect(CartPricing.allocate(7, [0, 0]), [0, 0]);
      for (final amount in [1, 99, 1234]) {
        expect(CartPricing.allocate(amount, [17, 230, 5]).reduce((a, b) => a + b), amount);
      }
    });

    test('line discounts, then the order discount on what is left', () {
      final lines = [
        CartLine(product: waffle, discount: percent(10)),
        CartLine(product: vanillaCone, variant: double_),
      ];
      final p = CartPricing.of(lines, orderDiscount: amount(500));
      expect(p.subtotal, 3400);
      expect(p.lineDiscounts, 120);
      expect(p.orderDiscountAmount, 500);
      expect(p.lines.map((l) => l.orderShare), [165, 335]);
      expect(p.discountTotal, 620);
      expect(p.total, 2780);
      expect(p.lines.fold(0, (s, l) => s + l.net), p.total);
    });

    test('tax is worked out on the discounted price', () {
      final line = CartLine(product: taxedWaffle, quantity: 2);
      final inclusive = CartPricing.of([line], orderDiscount: percent(50), taxMode: TaxMode.inclusive);
      expect(inclusive.total, 1150);
      expect(inclusive.taxTotal, computeTax(1150, [vat.spec], TaxMode.inclusive).taxTotal);
      final exclusive = CartPricing.of([line], orderDiscount: percent(50), taxMode: TaxMode.exclusive);
      expect(exclusive.net, 1150);
      expect(exclusive.total, 1150 + 173);
    });

    test('weighed lines are priced per kg and round to the pesewa', () {
      expect(CartLine(product: rice, quantity: 1250).lineTotal, 1875);
      expect(CartLine(product: rice, quantity: 333).lineTotal, 500, reason: '499.5 rounds up');
      expect(CartLine(product: rice, quantity: 1250).quantityText, '1.25 kg');
      expect(CartLine(product: rice, quantity: 1250).count, 1);
    });

    test('an open or overridden price replaces the menu price', () {
      final line = CartLine(product: waffle, quantity: 2, customPrice: 1000, priceOverriddenBy: 'Kofi');
      expect(line.listPrice, 1200);
      expect(line.lineTotal, 2000);
      expect(line.priceOverridden, isTrue);
      expect(line.plain, isFalse);
    });
  });

  group('ScaleBarcode', () {
    test('EAN-13 check digits', () {
      expect(ScaleBarcode.isValidEan13('4006381333931'), isTrue);
      expect(ScaleBarcode.isValidEan13('4006381333932'), isFalse);
      expect(ScaleBarcode.isValidEan13('400638133393'), isFalse);
    });

    test('reads the item code and the weight or price after the prefix', () {
      final code = ean13('210012301250');
      final two = ScaleBarcode.parse(code, prefix: '21')!;
      expect(two.itemCode, '00123');
      expect(two.shortCode, '123');
      expect(two.value, 1250);
      final one = ScaleBarcode.parse(ean13('200012301250'), prefix: '2')!;
      expect(one.itemCode, '000123');
      expect(one.value, 1250);
    });

    test('off without a prefix, and only for matching, valid codes', () {
      final code = ean13('210012301250');
      expect(ScaleBarcode.parse(code, prefix: ''), isNull);
      expect(ScaleBarcode.parse(code, prefix: '22'), isNull);
      expect(ScaleBarcode.parse('2100123012509', prefix: '21'), isNull, reason: 'wrong check digit');
      expect(ScaleBarcode.parse('12', prefix: '21'), isNull);
    });
  });
}
