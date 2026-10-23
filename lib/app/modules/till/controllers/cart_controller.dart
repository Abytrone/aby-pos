import 'dart:async';

import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../core/tax.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/parked_order_repository.dart';
import '../../../domain/pricing.dart';
import '../../../models/audit.dart';
import '../../../models/cart_line.dart';
import '../../../models/catalog.dart';
import '../../../models/discount.dart';
import '../../../models/enums.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';

/// The cart being rung up. Registered once (permanent) so the till and
/// checkout share it. All amounts are pesewas.
///
/// The cart is saved on the device as it changes, so a crash or power cut
/// loses nothing. Taking something out (a line, a quantity, the whole cart)
/// is written to the activity log: ringing up and removing is how cash goes
/// missing.
class CartController extends GetxController {
  final lines = <CartLine>[].obs;
  final orderDiscount = Rxn<Discount>();
  final note = RxnString();
  final orderType = Rxn<OrderType>();

  /// Set when the cart came back from a parked order, so parking it again
  /// keeps the name.
  final parkedName = RxnString();

  Timer? _saveTimer;
  bool _restored = false;

  ParkedOrderRepository? get _store =>
      Get.isRegistered<ParkedOrderRepository>() ? Get.find<ParkedOrderRepository>() : null;

  @override
  void onInit() {
    super.onInit();
    everAll([lines, orderDiscount, note, orderType, parkedName], (_) => _saveSoon());
  }

  @override
  void onClose() {
    _saveTimer?.cancel();
    super.onClose();
  }

  /// From settings (reactive inside Obx); off when settings are not loaded.
  TaxMode get taxMode => Get.isRegistered<SettingsService>()
      ? TaxMode.fromName(Get.find<SettingsService>().get(AppSettings.taxMode))
      : TaxMode.off;

  CartPricing get pricing => CartPricing.of(lines, orderDiscount: orderDiscount.value, taxMode: taxMode);

  /// The lines as priced, before discounts.
  int get subtotal => pricing.subtotal;

  int get discountTotal => pricing.discountTotal;

  /// Tax in the prices (inclusive) or added on top (exclusive).
  int get taxTotal => pricing.taxTotal;

  /// What the customer pays.
  int get total => pricing.total;

  int get itemCount => lines.fold(0, (sum, l) => sum + l.count);
  bool get isEmpty => lines.isEmpty;

  /// How many of a product are in the cart, across all its lines.
  int countFor(String productId) =>
      lines.where((l) => l.product.id == productId).fold(0, (sum, l) => sum + l.count);

  /// Change to give back, or 0 when the cash given does not cover the total.
  int changeDue(int tendered) => tendered > total ? tendered - total : 0;

  CartLine? line(String key) => lines.firstWhereOrNull((l) => l.key == key);

  /// Adds [quantity] of a pick (grams or ml for weighed products). A plain
  /// identical pick already in the cart goes up instead of adding a line.
  CartLine add(
    Product product, {
    Variant? variant,
    List<Option> options = const [],
    int quantity = 1,
    int? customPrice,
  }) {
    final line = CartLine(
      product: product,
      variant: variant,
      options: options,
      quantity: quantity,
      customPrice: customPrice,
    );
    final index = line.plain ? lines.indexWhere((l) => l.plain && l.pickKey == line.pickKey) : -1;
    if (index == -1) {
      lines.add(line);
      return line;
    }
    final merged = lines[index].copyWith(quantity: lines[index].quantity + quantity);
    lines[index] = merged;
    return merged;
  }

  void increment(String key) {
    final l = line(key);
    if (l != null && !l.weighed) setQuantity(key, l.quantity + 1);
  }

  /// Removes the line when its quantity reaches zero.
  void decrement(String key) {
    final l = line(key);
    if (l == null) return;
    if (l.weighed || l.quantity <= 1) {
      remove(key);
    } else {
      setQuantity(key, l.quantity - 1);
    }
  }

  /// Sets the quantity; 0 or less removes the line.
  void setQuantity(String key, int quantity) {
    final index = lines.indexWhere((l) => l.key == key);
    if (index == -1) return;
    final old = lines[index];
    if (quantity <= 0) {
      remove(key);
      return;
    }
    if (quantity == old.quantity) return;
    final updated = old.copyWith(quantity: quantity);
    lines[index] = updated;
    if (quantity < old.quantity) {
      final gone = old.copyWith(quantity: old.quantity - quantity);
      _recordRemoval('Took ${gone.quantityText} × ${old.title} (${formatMoney(old.lineTotal - updated.lineTotal)}) off the cart');
    }
  }

  void remove(String key) {
    final l = line(key);
    if (l == null) return;
    lines.removeWhere((x) => x.key == key);
    _recordRemoval('Removed ${l.quantityText} × ${l.title} (${formatMoney(l.netTotal)}) from the cart');
  }

  /// Empties the cart by hand (recorded). See [reset] after a sale.
  void clear() {
    if (lines.isEmpty) return;
    final summary = 'Cleared the cart: $itemCount items, ${formatMoney(total)}';
    reset();
    _record(AuditAction.cartCleared, summary);
  }

  /// Empties the cart after a sale or parking it (nothing to record).
  void reset() {
    lines.clear();
    orderDiscount.value = null;
    note.value = null;
    orderType.value = null;
    parkedName.value = null;
  }

  void setLineNote(String key, String? text) =>
      _update(key, (l) => l.copyWith(note: text == null || text.trim().isEmpty ? null : text.trim()));

  void setLineDiscount(String key, Discount? discount) => _update(key, (l) => l.copyWith(discount: discount));

  /// An open price typed at the till, or an override ([by] is whoever's
  /// permission allowed it). Null [price] goes back to the menu price.
  void setLinePrice(String key, int? price, {String? by}) =>
      _update(key, (l) => l.copyWith(customPrice: price, priceOverriddenBy: price == null ? null : by));

  /// Swaps the size or options, keeping quantity, note and discount. An
  /// overridden price goes back to the menu price for the new pick.
  void replacePick(String key, {required Variant variant, required List<Option> options}) => _update(
        key,
        (l) => CartLine(
          id: l.id,
          product: l.product,
          variant: variant,
          options: options,
          quantity: l.quantity,
          customPrice: l.product.openPrice ? l.customPrice : null,
          note: l.note,
          discount: l.discount,
        ),
      );

  void setOrderNote(String? text) => note.value = text == null || text.trim().isEmpty ? null : text.trim();

  void _update(String key, CartLine Function(CartLine) change) {
    final index = lines.indexWhere((l) => l.key == key);
    if (index != -1) lines[index] = change(lines[index]);
  }

  /// After the menu changes, swap in the new product data. Lines whose
  /// product, size or option is gone keep what was rung up.
  void refreshProducts(List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    for (var i = 0; i < lines.length; i++) {
      final fresh = CartLine.fromJson(lines[i].toJson(), byId);
      if (fresh != null) lines[i] = fresh;
    }
  }

  // ---------------------------------------------------------------------------
  // Saving and parking

  /// Everything in the cart, as JSON (saved cart and parked orders).
  Map<String, dynamic> snapshot() => {
        'lines': [for (final l in lines) l.toJson()],
        if (orderDiscount.value != null) 'orderDiscount': orderDiscount.value!.toJson(),
        'note': ?note.value,
        'orderType': ?orderType.value?.name,
      };

  /// Replaces the cart with [json], looked up against [products]. Returns
  /// how many lines were dropped because they are no longer on the menu.
  int load(Map<String, dynamic> json, List<Product> products, {String? parkedAs}) {
    final byId = {for (final p in products) p.id: p};
    final raw = (json['lines'] as List? ?? const []).cast<Map<dynamic, dynamic>>();
    final restored = [for (final l in raw) CartLine.fromJson(Map<String, dynamic>.from(l), byId)];
    lines.assignAll(restored.nonNulls);
    final d = json['orderDiscount'];
    orderDiscount.value = d == null ? null : Discount.fromJson(Map<String, dynamic>.from(d as Map));
    note.value = json['note'] as String?;
    final type = json['orderType'] as String?;
    orderType.value = type == null ? null : OrderType.values.asNameMap()[type];
    parkedName.value = parkedAs;
    return restored.length - lines.length;
  }

  /// Adds [json]'s lines to this cart (merging a parked order in).
  int merge(Map<String, dynamic> json, List<Product> products) {
    final byId = {for (final p in products) p.id: p};
    final raw = (json['lines'] as List? ?? const []).cast<Map<dynamic, dynamic>>();
    var dropped = 0;
    for (final l in raw) {
      final line = CartLine.fromJson(Map<String, dynamic>.from(l), byId);
      if (line == null) {
        dropped++;
      } else {
        lines.add(line);
      }
    }
    return dropped;
  }

  /// Once per run: brings back the cart that was on the till when the app
  /// last stopped. Returns lines dropped, or null if there was nothing.
  Future<int?> restoreSaved(List<Product> products) async {
    if (_restored) return null;
    _restored = true;
    final saved = await _store?.loadCurrent();
    if (saved == null || !isEmpty) return null;
    final parkedAs = saved['parkedName'] as String?;
    return load(saved, products, parkedAs: parkedAs);
  }

  void _saveSoon() {
    final store = _store;
    if (store == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), () {
      store.saveCurrent(isEmpty ? null : {...snapshot(), 'parkedName': ?parkedName.value});
    });
  }

  void _recordRemoval(String summary) => _record(AuditAction.cartLinesRemoved, summary);

  void _record(AuditAction action, String summary) {
    if (!Get.isRegistered<AuditRepository>() || !Get.isRegistered<AuthService>()) return;
    final user = Get.find<AuthService>().currentUser.value;
    unawaited(Get.find<AuditRepository>().record(action: action, actor: user, summary: summary));
  }
}
