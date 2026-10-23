import 'catalog.dart';

/// One line in the cart. Identical picks (same product, variant and
/// options, repeats included) share a line and add to its quantity.
class CartLine {
  CartLine({
    required this.product,
    Variant? variant,
    List<Option> options = const [],
    this.quantity = 1,
  })  : variant = variant ?? product.variants.first,
        options = List<Option>.unmodifiable(<Option>[...options]..sort((a, b) => a.id.compareTo(b.id)));

  final Product product;
  final Variant variant;

  /// Picked options; an option picked twice appears twice.
  final List<Option> options;
  final int quantity;

  /// Identifies identical picks.
  String get key => [product.id, variant.id, ...options.map((o) => o.id)].join('|');

  /// Pesewas for one unit, options included.
  int get unitPrice => variant.price + options.fold(0, (sum, o) => sum + o.priceDelta);

  /// Pesewas.
  int get lineTotal => unitPrice * quantity;

  String get title => variant.name == null ? product.name : '${product.name}, ${variant.name}';

  /// "Sprinkles ×2, Chocolate sauce".
  String get optionsLine {
    final counts = <String, int>{};
    for (final o in options) {
      counts[o.name] = (counts[o.name] ?? 0) + 1;
    }
    return counts.entries.map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key).join(', ');
  }

  CartLine copyWith({int? quantity}) => CartLine(
        product: product,
        variant: variant,
        options: options,
        quantity: quantity ?? this.quantity,
      );
}
