import '../core/units.dart';
import '../services/ids.dart';
import 'catalog.dart';
import 'discount.dart';
import 'enums.dart';

/// One line in the cart. Plain identical picks (same product, variant and
/// options, repeats included, and nothing changed by hand) share a line and
/// add to its quantity.
class CartLine {
  CartLine({
    String? id,
    required this.product,
    Variant? variant,
    List<Option> options = const [],
    this.quantity = 1,
    this.customPrice,
    this.priceOverriddenBy,
    this.note,
    this.discount,
  })  : id = id ?? newId(),
        variant = variant ?? product.variants.first,
        options = List<Option>.unmodifiable(<Option>[...options]..sort((a, b) => a.id.compareTo(b.id)));

  /// Stable for the life of the line (steppers, edits, removal).
  final String id;
  final Product product;
  final Variant variant;

  /// Picked options; an option picked twice appears twice.
  final List<Option> options;

  /// How many; for weighed products, grams or millilitres.
  final int quantity;

  /// Pesewas for one (per kg or litre when weighed), typed for an
  /// open-price product or set by a price override.
  final int? customPrice;

  /// Who allowed the price override; null for open prices.
  final String? priceOverriddenBy;
  final String? note;
  final Discount? discount;

  String get key => id;

  /// Identifies identical picks.
  String get pickKey => [product.id, variant.id, ...options.map((o) => o.id)].join('|');

  bool get weighed => product.weighed;

  /// Nothing set by hand, so another identical tap can add to it.
  bool get plain =>
      customPrice == null && note == null && discount == null && !weighed && !product.openPrice;

  bool get priceOverridden => customPrice != null && priceOverriddenBy != null;

  /// Pesewas for one (per kg or litre when weighed), options included, as
  /// on the menu.
  int get listPrice => variant.price + options.fold(0, (sum, o) => sum + o.priceDelta);

  /// Pesewas for one, as charged.
  int get unitPrice => customPrice ?? listPrice;

  /// Pesewas before discounts. Weighed lines round to the pesewa.
  int get lineTotal => weighed ? (unitPrice * quantity + 500) ~/ 1000 : unitPrice * quantity;

  /// Pesewas off this line (the order discount comes on top).
  int get discountAmount => discount?.amountOn(lineTotal) ?? 0;

  int get netTotal => lineTotal - discountAmount;

  /// Items for the cart count: a weighed line is one item.
  int get count => weighed ? 1 : quantity;

  /// "3", or "1.25 kg" for a weighed line.
  String get quantityText =>
      weighed ? formatQuantity(quantity, product.sellBy == SellBy.kg ? StockUnit.g : StockUnit.ml) : '$quantity';

  String get title => variant.name == null ? product.name : '${product.name}, ${variant.name}';

  /// "Sprinkles ×2, Chocolate sauce".
  String get optionsLine {
    final counts = <String, int>{};
    for (final o in options) {
      counts[o.name] = (counts[o.name] ?? 0) + 1;
    }
    return counts.entries.map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key).join(', ');
  }

  static const _keep = Object();

  /// Pass null to clear [customPrice], [note] or [discount].
  CartLine copyWith({
    Product? product,
    Variant? variant,
    List<Option>? options,
    int? quantity,
    Object? customPrice = _keep,
    Object? priceOverriddenBy = _keep,
    Object? note = _keep,
    Object? discount = _keep,
  }) =>
      CartLine(
        id: id,
        product: product ?? this.product,
        variant: variant ?? this.variant,
        options: options ?? this.options,
        quantity: quantity ?? this.quantity,
        customPrice: identical(customPrice, _keep) ? this.customPrice : customPrice as int?,
        priceOverriddenBy:
            identical(priceOverriddenBy, _keep) ? this.priceOverriddenBy : priceOverriddenBy as String?,
        note: identical(note, _keep) ? this.note : note as String?,
        discount: identical(discount, _keep) ? this.discount : discount as Discount?,
      );

  /// For the saved cart and parked orders. Products are stored by ID and
  /// looked up again on the way back.
  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': product.id,
        'variantId': variant.id,
        'optionIds': [for (final o in options) o.id],
        'quantity': quantity,
        'customPrice': ?customPrice,
        'priceOverriddenBy': ?priceOverriddenBy,
        'note': ?note,
        if (discount != null) 'discount': discount!.toJson(),
      };

  /// Null when the product, variant or an option is no longer on the menu.
  static CartLine? fromJson(Map<String, dynamic> json, Map<String, Product> products) {
    final product = products[json['productId']];
    final variant = product?.variants.where((v) => v.id == json['variantId']).firstOrNull;
    if (product == null || variant == null) return null;
    final all = {for (final o in product.groups.expand((g) => g.options)) o.id: o};
    final options = <Option>[];
    for (final id in (json['optionIds'] as List).cast<String>()) {
      final o = all[id];
      if (o == null) return null;
      options.add(o);
    }
    return CartLine(
      id: json['id'] as String?,
      product: product,
      variant: variant,
      options: options,
      quantity: json['quantity'] as int,
      customPrice: json['customPrice'] as int?,
      priceOverriddenBy: json['priceOverriddenBy'] as String?,
      note: json['note'] as String?,
      discount: json['discount'] == null ? null : Discount.fromJson(Map<String, dynamic>.from(json['discount'] as Map)),
    );
  }
}
