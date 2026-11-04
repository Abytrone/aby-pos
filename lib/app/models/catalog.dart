import '../core/tax.dart';
import '../core/units.dart';
import '../domain/category_icons.dart';
import 'enums.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.tone,
    this.parentId,
    this.active = true,
    this.sortOrder = 0,
    this.icon,
  });

  final String id;
  final String name;
  final CategoryTone tone;

  /// The picture the owner picked for products without a photo, if any.
  final String? icon;

  /// The picture to draw: the one picked, else a guess from the name.
  String get picture => categoryIconFor(name: name, tone: tone, picked: icon);

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

/// One inventory item directly linked to a sellable variant.
class VariantStockLink {
  const VariantStockLink({
    required this.stockItemId,
    required this.stockItemName,
    required this.unit,
    required this.quantity,
    required this.costMilli,
  });

  final String stockItemId;
  final String stockItemName;
  final StockUnit unit;

  /// Base units consumed for one sell unit.
  final int quantity;

  /// Thousandths of a pesewa per base unit.
  final int costMilli;

  int get cost => costOf(quantity, costMilli);

  RecipeLine get asRecipeLine => RecipeLine(
        stockItemId: stockItemId,
        stockItemName: stockItemName,
        unit: unit,
        quantity: quantity,
        costMilli: costMilli,
      );
}

/// What is sold and priced. Simple products have one variant with no name.
class Variant {
  const Variant({
    required this.id,
    required this.price,
    this.name,
    this.manualCost,
    this.stockLink,
    this.recipe = const [],
    this.barcodes = const [],
  });

  final String id;
  final String? name;

  /// Pesewas.
  final int price;

  /// Pesewas, when neither a stock link nor recipe supplies the cost.
  final int? manualCost;
  final VariantStockLink? stockLink;
  final List<RecipeLine> recipe;
  final List<String> barcodes;

  /// Pesewas: recipe cost, direct stock cost, or manual cost, in that order.
  int? get cost => recipe.isNotEmpty
      ? recipe.fold<int>(0, (s, r) => s + r.cost)
      : stockLink?.cost ?? manualCost;

  /// The one stock item this uses, when there is exactly one (so the till
  /// can show "12 left").
  RecipeLine? get soleStockItem => stockLink?.asRecipeLine ?? (recipe.length == 1 ? recipe.single : null);
}

class Option {
  const Option({
    required this.id,
    required this.groupId,
    required this.name,
    this.priceDelta = 0,
    this.isDefault = false,
    this.recipe = const [],
    this.variantId,
  });

  final String id;
  final String groupId;
  final String name;

  /// Pesewas added to the price.
  final int priceDelta;
  final bool isDefault;

  /// What it uses up: its own recipe, or for a combo part with none, the
  /// linked variant's.
  final List<RecipeLine> recipe;

  /// A combo part: this option is that product variant (CAT-04).
  final String? variantId;

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
    this.sellBy = SellBy.each,
    this.openPrice = false,
    this.minPrice,
    this.maxPrice,
    this.quickOrder,
    this.commission,
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

  /// Counted, or weighed / measured with the price per kg or litre.
  final SellBy sellBy;

  /// The price is typed at the till, between [minPrice] and [maxPrice]
  /// (pesewas, either optional). The variant price is the suggestion.
  final bool openPrice;
  final int? minPrice;
  final int? maxPrice;

  /// Position on the till's Quick tab; null when not on it.
  final int? quickOrder;

  /// Pesewas of commission per one sold (STF-07).
  final int? commission;

  bool get weighed => sellBy != SellBy.each;

  /// Needs something typed (a price or a weight) before it goes in the cart.
  bool get needsEntry => weighed || openPrice;

  /// "kg", "L", or null when counted.
  String? get perUnit => switch (sellBy) {
        SellBy.each => null,
        SellBy.kg => 'kg',
        SellBy.litre => 'L',
      };

  bool get isSimple => variants.length == 1 && variants.single.name == null;

  /// Something to choose: more than one variant, or option groups.
  bool get hasChoices => variants.length > 1 || groups.isNotEmpty;

  /// One tap is enough: one variant and nothing to add. Anything with
  /// options opens the picker, so the toppings are offered every time.
  bool get oneTap => variants.length == 1 && groups.isEmpty;

  /// Can go in as it stands: one variant, and every required group is
  /// covered by its defaults (a long press adds it so).
  bool get addsAsIs =>
      variants.length == 1 && groups.every((g) => !g.required || g.accepts(g.defaults.length));

  /// The lowest price before options, in pesewas.
  int get fromPrice => variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);

  bool get pricesDiffer => variants.any((v) => v.price != fromPrice);

  /// Text for the tile's size line.
  String get sizeLine =>
      detail ?? (variants.length > 1 ? variants.map((v) => v.name ?? '').join(' / ') : '');

  Variant variant(String id) => variants.firstWhere((v) => v.id == id);
}

/// A price waiting to take effect.
class ScheduledPrice {
  const ScheduledPrice({
    required this.id,
    required this.variantId,
    required this.productName,
    required this.oldPrice,
    required this.newPrice,
    required this.effectiveOn,
    required this.createdByName,
    this.variantName,
  });

  final String id;
  final String variantId;
  final String productName;
  final String? variantName;

  /// Pesewas.
  final int oldPrice;
  final int newPrice;
  final DateTime effectiveOn;
  final String createdByName;

  String get label => variantName == null ? productName : '$productName, $variantName';
}
