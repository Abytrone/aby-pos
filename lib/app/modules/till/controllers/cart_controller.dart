import 'package:get/get.dart';

import '../../../models/cart_line.dart';
import '../../../models/catalog.dart';

/// The cart being rung up. Registered once (permanent) so the till and
/// checkout share it. All amounts are pesewas.
class CartController extends GetxController {
  final lines = <CartLine>[].obs;

  int get total => lines.fold(0, (sum, l) => sum + l.lineTotal);
  int get itemCount => lines.fold(0, (sum, l) => sum + l.quantity);
  bool get isEmpty => lines.isEmpty;

  /// How many of a product are in the cart, across all its lines.
  int countFor(String productId) => lines
      .where((l) => l.product.id == productId)
      .fold(0, (sum, l) => sum + l.quantity);

  /// Change to give back, or 0 when the cash given does not cover the total.
  int changeDue(int tendered) => tendered > total ? tendered - total : 0;

  /// Adds one of a pick. An identical pick already in the cart goes up by
  /// one instead of adding a new line.
  void add(Product product, {Variant? variant, List<Addon> addons = const []}) {
    final line = CartLine(product: product, variant: variant, addons: addons);
    final index = lines.indexWhere((l) => l.key == line.key);
    if (index == -1) {
      lines.add(line);
    } else {
      lines[index] = lines[index].copyWith(quantity: lines[index].quantity + 1);
    }
  }

  void increment(String key) => _changeQuantity(key, 1);

  /// Removes the line when its quantity reaches zero.
  void decrement(String key) => _changeQuantity(key, -1);

  void remove(String key) => lines.removeWhere((l) => l.key == key);

  void clear() => lines.clear();

  void _changeQuantity(String key, int by) {
    final index = lines.indexWhere((l) => l.key == key);
    if (index == -1) return;
    final quantity = lines[index].quantity + by;
    if (quantity < 1) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(quantity: quantity);
    }
  }
}
