import 'catalog.dart';

/// One line in the cart. Identical picks (same product, variant and add-ons)
/// share a line and add to its quantity.
class CartLine {
  CartLine({
    required this.product,
    this.variant,
    List<Addon> addons = const [],
    this.quantity = 1,
  }) : addons = List<Addon>.unmodifiable(
            <Addon>[...addons]..sort((a, b) => a.id.compareTo(b.id)));

  final Product product;
  final Variant? variant;
  final List<Addon> addons;
  final int quantity;

  /// Identifies identical picks.
  String get key =>
      [product.id, variant?.id ?? '-', ...addons.map((a) => a.id)].join('|');

  /// Pesewas for one unit, including add-ons.
  int get unitPrice =>
      (variant?.price ?? product.basePrice) +
      addons.fold(0, (sum, a) => sum + a.price);

  /// Pesewas.
  int get lineTotal => unitPrice * quantity;

  String get title =>
      variant == null ? product.name : '${product.name}, ${variant!.name}';

  String get addonsLine => addons.map((a) => a.name).join(', ');

  CartLine copyWith({int? quantity}) => CartLine(
        product: product,
        variant: variant,
        addons: addons,
        quantity: quantity ?? this.quantity,
      );
}
