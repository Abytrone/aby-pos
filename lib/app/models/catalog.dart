import '../core/tax.dart';
import '../core/units.dart';
import 'enums.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.tone,
    this.parentId,
    this.active = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final CategoryTone tone;

  /// Set for a sub-category.
  final String? parentId;
  final bool active;
  final int sortOrder;
}

/// One stock item in a recipe: "80 ml Vanilla ice cream".
class RecipeLine {
  const RecipeLine({
    required this.stockItemId,
    required this.stockItemName,
    required this.unit,
    required this.quantity,
    required this.costMilli,
  });

  final String stockItemId;
  final String stockItemName;
  final StockUnit unit;

  /// Base units.
  final int quantity;

  /// Thousandths of a pesewa per base unit, as it stands now.
  final int costMilli;

  /// Pesewas.
  int get cost => costOf(quantity, costMilli);
}

/// What is sold and priced. Simple products have one variant with no name.
class Variant {
  const Variant({
    required this.id,
    required this.price,
    this.name,
    this.manualCost,
    this.recipe = const [],
    this.barcodes = const [],
  });

  final String id;
  final String? name;

  /// Pesewas.
  final int price;

  /// Pesewas, when there is no recipe.
  final int? manualCost;
  final List<RecipeLine> recipe;
  final List<String> barcodes;

  /// Pesewas: from the recipe if there is one, else the manual cost.
  int? get cost => recipe.isNotEmpty ? recipe.fold<int>(0, (s, r) => s + r.cost) : manualCost;

  /// The one stock item this uses, when there is exactly one (so the till
  /// can show "12 left").
  RecipeLine? get soleStockItem => recipe.length == 1 ? recipe.single : null;
}

class Option {
  const Option({
    required this.id,
    required this.groupId,
    required this.name,
    this.priceDelta = 0,
    this.isDefault = false,
    this.recipe = const [],
  });

  final String id;
  final String groupId;
  final String name;

  /// Pesewas added to the price.
  final int priceDelta;
  final bool isDefault;
  final List<RecipeLine> recipe;

  int get cost => recipe.fold(0, (s, r) => s + r.cost);
}

/// A set of choices on a product with rules: "Toppings (up to 3)",
/// "Sugar (pick 1)".
class OptionGroup {
  const OptionGroup({
    required this.id,
    required this.name,
    required this.options,
    this.minSelect = 0,
    this.maxSelect,
    this.allowRepeat = false,
    this.active = true,
  });

  final String id;
  final String name;
  final List<Option> options;
  final int minSelect;

  /// Null: no limit.
  final int? maxSelect;
  final bool allowRepeat;
  final bool active;

  bool get required => minSelect > 0;

  /// Options picked when the picker opens.
  List<Option> get defaults => options.where((o) => o.isDefault).toList();

  /// Whether [picked] options (repeats counted) satisfy the rules.
  bool accepts(int picked) => picked >= minSelect && (maxSelect == null || picked <= maxSelect!);
}

class TaxRate {
  const TaxRate({
    required this.id,
    required this.name,
    required this.rateBp,
    this.compound = false,
    this.active = true,
  });

  final String id;
  final String name;

  /// Basis points: 1500 = 15%.
  final int rateBp;
  final bool compound;
  final bool active;

  TaxRateSpec get spec => TaxRateSpec(id: id, name: name, rateBp: rateBp, compound: compound);

  /// "15%", "2.5%".
  String get percent {
    final whole = rateBp ~/ 100;
    final frac = (rateBp % 100).toString().padLeft(2, '0').replaceFirst(RegExp(r'0+$'), '');
    return '$whole${frac.isEmpty ? '' : '.$frac'}%';
  }
}

class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.variants,
    this.detail,
    this.description,
    this.groups = const [],
    this.taxes = const [],
    this.active = true,
    this.archived = false,
  });

  final String id;
  final String categoryId;
  final String name;

  /// Short line for the till tile, e.g. "350 ml".
  final String? detail;
  final String? description;

  /// At least one.
  final List<Variant> variants;
  final List<OptionGroup> groups;
  final List<TaxRate> taxes;
  final bool active;
  final bool archived;

  bool get isSimple => variants.length == 1 && variants.single.name == null;

  /// Something to choose: more than one variant, or option groups.
  bool get hasChoices => variants.length > 1 || groups.isNotEmpty;

  /// One tap is enough: one variant, and every required group is covered
  /// by its defaults.
  bool get oneTap =>
      variants.length == 1 && groups.every((g) => !g.required || g.accepts(g.defaults.length));

  /// The lowest price before options, in pesewas.
  int get fromPrice => variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  bool get pricesDiffer => variants.any((v) => v.price != fromPrice);

  /// Text for the tile's size line.
  String get sizeLine =>
      detail ?? (variants.length > 1 ? variants.map((v) => v.name ?? '').join(' / ') : '');

  Variant variant(String id) => variants.firstWhere((v) => v.id == id);
}
