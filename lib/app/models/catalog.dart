import 'enums.dart';

class Category {
  const Category({required this.id, required this.name, required this.tone});

  final String id;
  final String name;
  final CategoryTone tone;
}

class Variant {
  const Variant({required this.id, required this.name, required this.price});

  final String id;
  final String name;

  /// Pesewas.
  final int price;
}

class Addon {
  const Addon({required this.id, required this.name, required this.price});

  final String id;
  final String name;

  /// Pesewas.
  final int price;
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.basePrice,
    this.detail,
    this.variants = const [],
    this.addons = const [],
  });

  final String id;
  final String categoryId;
  final String name;

  /// Size or pack line shown on the tile, e.g. "350 ml".
  final String? detail;

  /// Pesewas. Used when the product has no variants.
  final int basePrice;
  final List<Variant> variants;
  final List<Addon> addons;

  bool get hasVariants => variants.isNotEmpty;
  bool get hasOptions => variants.isNotEmpty || addons.isNotEmpty;

  /// The lowest price a customer can pay for this product, in pesewas.
  int get fromPrice => hasVariants
      ? variants.map((v) => v.price).reduce((a, b) => a < b ? a : b)
      : basePrice;

  /// Text for the tile's size line.
  String get sizeLine =>
      detail ?? (hasVariants ? variants.map((v) => v.name).join(' / ') : '');
}
