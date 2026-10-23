import 'package:aby_pos/app/modules/till/controllers/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

void main() {
  late CartController cart;

  setUp(() {
    Get.testMode = true;
    cart = Get.put(CartController());
  });

  tearDown(Get.reset);

  test('starts empty', () {
    expect(cart.isEmpty, isTrue);
    expect(cart.total, 0);
    expect(cart.itemCount, 0);
  });

  test('uses the base price for products without variants', () {
    cart.add(waffle);
    expect(cart.total, 1200);
  });

  test('uses the variant price and adds add-ons per unit', () {
    cart.add(vanillaCone, variant: double_, addons: [sprinkles, crunch]);
    // 22.00 + 3.00 + 5.00
    expect(cart.lines.single.unitPrice, 3000);
    cart.increment(cart.lines.single.key);
    expect(cart.lines.single.quantity, 2);
    expect(cart.total, 6000);
  });

  test('identical picks share a line, whatever the add-on order', () {
    cart.add(vanillaCone, variant: single, addons: [sprinkles, crunch]);
    cart.add(vanillaCone, variant: single, addons: [crunch, sprinkles]);
    expect(cart.lines, hasLength(1));
    expect(cart.lines.single.quantity, 2);
  });

  test('different sizes or toppings get their own lines', () {
    cart.add(vanillaCone, variant: single);
    cart.add(vanillaCone, variant: double_);
    cart.add(vanillaCone, variant: single, addons: [sprinkles]);
    expect(cart.lines, hasLength(3));
    expect(cart.countFor(vanillaCone.id), 3);
    // 15 + 22 + 18
    expect(cart.total, 5500);
  });

  test('decrement removes the line at zero; remove and clear empty it', () {
    cart.add(waffle);
    cart.add(vanillaCone, variant: single);
    final waffleKey = cart.lines.first.key;
    cart.decrement(waffleKey);
    expect(cart.lines, hasLength(1));
    cart.remove(cart.lines.single.key);
    expect(cart.isEmpty, isTrue);
    cart.add(waffle);
    cart.clear();
    expect(cart.total, 0);
  });

  test('change due', () {
    cart.add(vanillaCone, variant: double_, addons: [sprinkles]); // 25.00
    cart.add(waffle); // 12.00
    expect(cart.total, 3700);
    expect(cart.changeDue(5000), 1300);
    expect(cart.changeDue(3700), 0);
    expect(cart.changeDue(2000), 0, reason: 'short cash gives no change');
  });
}
