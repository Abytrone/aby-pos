import 'enums.dart';

/// What editing forms produce. Use cases check them; repositories save them.
/// An ID of null means "new".

class RecipeDraftLine {
  const RecipeDraftLine({required this.stockItemId, required this.quantity});

  final String stockItemId;

  /// Base units.
  final int quantity;
}

class VariantDraft {
  const VariantDraft({
    this.id,
    this.name,
    required this.price,
    this.manualCost,
    this.barcodes = const [],
    this.recipe = const [],
  });

  final String? id;
  final String? name;

  /// Pesewas.
  final int price;
  final int? manualCost;
  final List<String> barcodes;
  final List<RecipeDraftLine> recipe;
}

class ProductDraft {
  const ProductDraft({
    this.id,
    required this.categoryId,
    required this.name,
    this.detail,
    this.description,
    this.active = true,
    required this.variants,
    this.groupIds = const [],
    this.taxIds = const [],
    this.sellBy = SellBy.each,
    this.openPrice = false,
    this.minPrice,
    this.maxPrice,
    this.onQuickTab = false,
  });

  final String? id;
  final String categoryId;
  final String name;
  final String? detail;
  final String? description;
  final bool active;
  final List<VariantDraft> variants;
  final List<String> groupIds;
  final List<String> taxIds;
  final SellBy sellBy;
  final bool openPrice;

  /// Pesewas; optional limits for an open price.
  final int? minPrice;
  final int? maxPrice;
  final bool onQuickTab;

  ProductDraft copyWith({String? categoryId}) => ProductDraft(
        id: id,
        categoryId: categoryId ?? this.categoryId,
        name: name,
        detail: detail,
        description: description,
        active: active,
        variants: variants,
        groupIds: groupIds,
        taxIds: taxIds,
        sellBy: sellBy,
        openPrice: openPrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        onQuickTab: onQuickTab,
      );
}

class OptionDraft {
  const OptionDraft({
    this.id,
    required this.name,
    this.priceDelta = 0,
    this.isDefault = false,
    this.recipe = const [],
    this.variantId,
  });

  final String? id;
  final String name;
  final int priceDelta;
  final bool isDefault;
  final List<RecipeDraftLine> recipe;

  /// A combo part's product variant; its recipe is used instead.
  final String? variantId;
}

class OptionGroupDraft {
  const OptionGroupDraft({
    this.id,
    required this.name,
    this.minSelect = 0,
    this.maxSelect,
    this.allowRepeat = false,
    required this.options,
  });

  final String? id;
  final String name;
  final int minSelect;
  final int? maxSelect;
  final bool allowRepeat;
  final List<OptionDraft> options;
}

class CategoryDraft {
  const CategoryDraft({this.id, required this.name, required this.tone, this.parentId});

  final String? id;
  final String name;
  final CategoryTone tone;
  final String? parentId;
}

class TaxRateDraft {
  const TaxRateDraft({this.id, required this.name, required this.rateBp, this.compound = false});

  final String? id;
  final String name;
  final int rateBp;
  final bool compound;
}

class StockItemDraft {
  const StockItemDraft({
    this.id,
    required this.name,
    required this.unit,
    required this.costMilli,
    this.reorderPoint,
    this.reorderQty,
    this.supplierId,
  });

  final String? id;
  final String name;
  final StockUnit unit;
  final int costMilli;
  final int? reorderPoint;
  final int? reorderQty;
  final String? supplierId;
}
