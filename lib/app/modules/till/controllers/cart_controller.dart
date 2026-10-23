import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../core/tax.dart';
import '../../../models/cart_line.dart';
import '../../../models/catalog.dart';
import '../../../services/settings_service.dart';

/// The cart being rung up. Registered once (permanent) so the till and
/// checkout share it. All amounts are pesewas.
class CartController extends GetxController {
  final lines = <CartLine>[].obs;

  /// From settings (reactive inside Obx); off when settings are not loaded.
  TaxMode get taxMode => Get.isRegistered<SettingsService>()
      ? TaxMode.fromName(Get.find<SettingsService>().get(AppSettings.taxMode))
      : TaxMode.off;

  /// The lines as priced on the menu.
  int get subtotal => lines.fold(0, (sum, l) => sum + l.lineTotal);

  /// Tax in the prices (inclusive) or added on top (exclusive).
  int get taxTotal {
    final mode = taxMode;
    return lines.fold(
      0,
      (sum, l) => sum + computeTax(l.lineTotal, [for (final t in l.product.taxes) t.spec], mode).taxTotal,
    );
  }

  /// What the customer pays.
  int get total => taxMode == TaxMode.exclusive ? subtotal + taxTotal : subtotal;

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
  void add(Product product, {Variant? variant, List<Option> options = const []}) {
    final line = CartLine(product: product, variant: variant, options: options);
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

  /// After the menu changes, swap in the new product data (prices stay as
  /// the cart line was rung up only if the product is gone).
  void refreshProducts(List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final p = byId[line.product.id];
      final v = p?.variants.where((v) => v.id == line.variant.id).firstOrNull;
      if (p == null || v == null) continue;
      final options = [
        for (final o in line.options)
          p.groups.expand((g) => g.options).where((x) => x.id == o.id).firstOrNull ?? o,
      ];
      lines[i] = CartLine(product: p, variant: v, options: options, quantity: line.quantity);
    }
  }

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
