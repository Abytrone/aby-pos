import '../data/repositories/catalog_repository.dart';
import '../models/catalog.dart';
import '../models/drafts.dart';
import '../models/staff.dart';

/// The rules for changing the menu. Controllers call these, never the
/// repository's write methods directly, so every path checks the same
/// things. Messages are for the person editing.
class CatalogueRules {
  CatalogueRules(this._catalog);

  final CatalogRepository _catalog;

  /// Highest price we accept, in pesewas (GH₵ 1,000,000).
  static const maxPrice = 100000000;

  Future<String> saveProduct(ProductDraft d, {required Staff by}) async {
    if (d.name.trim().isEmpty) throw const CatalogueException('Enter the product name.');
    final categories = await _catalog.categories(includeInactive: true);
    if (!categories.any((c) => c.id == d.categoryId)) {
      throw const CatalogueException('Pick a category.');
    }
    if (d.variants.isEmpty) throw const CatalogueException('Add at least one price.');
    if (d.variants.length > 1) {
      final names = <String>{};
      for (final v in d.variants) {
        final name = v.name?.trim() ?? '';
        if (name.isEmpty) throw const CatalogueException('Give each size or variant a name.');
        if (!names.add(name.toLowerCase())) {
          throw CatalogueException('Two variants are called "$name".');
        }
      }
    }
    final seen = <String>{};
    final ownIds = {for (final v in d.variants) ?v.id};
    for (final v in d.variants) {
      if (v.price < 0 || v.price > maxPrice) throw const CatalogueException('Enter a price from GH₵ 0.00.');
      if ((v.manualCost ?? 0) < 0) throw const CatalogueException('A cost cannot be negative.');
      for (final code in v.barcodes.map((c) => c.trim()).where((c) => c.isNotEmpty)) {
        if (!seen.add(code)) throw CatalogueException('Barcode $code is used twice here.');
        final owner = await _catalog.barcodeOwner(code, exceptVariantIds: ownIds);
        if (owner != null) throw CatalogueException('Barcode $code already belongs to $owner.');
      }
      final items = <String>{};
      for (final r in v.recipe) {
        if (r.quantity <= 0) throw const CatalogueException('Each recipe amount must be more than 0.');
        if (!items.add(r.stockItemId)) {
          throw const CatalogueException('A recipe lists the same stock item twice.');
        }
      }
    }
    return _catalog.saveProduct(d, by: by);
  }

  Future<String> saveOptionGroup(OptionGroupDraft d, {required Staff by}) async {
    if (d.name.trim().isEmpty) throw const CatalogueException('Enter a name for the options.');
    if (d.options.isEmpty) throw const CatalogueException('Add at least one option.');
    if (d.minSelect < 0) throw const CatalogueException('The minimum cannot be negative.');
    final max = d.maxSelect;
    if (max != null) {
      if (max < 1) throw const CatalogueException('The maximum must be at least 1.');
      if (max < d.minSelect) throw const CatalogueException('The maximum is below the minimum.');
      if (!d.allowRepeat && max > d.options.length) {
        throw const CatalogueException('The maximum is more than the number of options.');
      }
    }
    if (!d.allowRepeat && d.minSelect > d.options.length) {
      throw const CatalogueException('The minimum is more than the number of options.');
    }
    final defaults = d.options.where((o) => o.isDefault).length;
    if (max != null && defaults > max) throw const CatalogueException('More options are ticked by default than allowed.');
    final names = <String>{};
    for (final o in d.options) {
      if (o.name.trim().isEmpty) throw const CatalogueException('Give each option a name.');
      if (!names.add(o.name.trim().toLowerCase())) {
        throw CatalogueException('Two options are called "${o.name.trim()}".');
      }
      if (o.priceDelta < 0 || o.priceDelta > maxPrice) throw const CatalogueException('Enter a price from GH₵ 0.00.');
    }
    return _catalog.saveOptionGroup(d, by: by);
  }

  Future<String> saveCategory(CategoryDraft d, {required Staff by}) async {
    if (d.name.trim().isEmpty) throw const CatalogueException('Enter the category name.');
    final parentId = d.parentId;
    if (parentId != null) {
      if (parentId == d.id) throw const CatalogueException('A category cannot be inside itself.');
      final all = await _catalog.categories(includeInactive: true);
      final parent = all.where((c) => c.id == parentId).firstOrNull;
      if (parent == null) throw const CatalogueException('Pick a category to put it in.');
      if (parent.parentId != null) {
        throw const CatalogueException('Categories go two levels deep at most.');
      }
      if (d.id != null && all.any((c) => c.parentId == d.id)) {
        throw const CatalogueException('This category has its own sub-categories, so it cannot go inside another.');
      }
    }
    return _catalog.saveCategory(d, by: by);
  }

  Future<String> saveTaxRate(TaxRateDraft d, {required Staff by}) async {
    if (d.name.trim().isEmpty) throw const CatalogueException('Enter the tax name.');
    if (d.rateBp <= 0 || d.rateBp > 5000) throw const CatalogueException('Enter a rate between 0.01% and 50%.');
    return _catalog.saveTaxRate(d, by: by);
  }

  /// A copy of [p] named "… (copy)", off the till until it is checked.
  /// Barcodes are not copied (they must be unique).
  Future<String> duplicateProduct(Product p, {required Staff by}) => _catalog.saveProduct(
        ProductDraft(
          categoryId: p.categoryId,
          name: '${p.name} (copy)',
          detail: p.detail,
          description: p.description,
          active: false,
          variants: [
            for (final v in p.variants)
              VariantDraft(
                name: v.name,
                price: v.price,
                manualCost: v.manualCost,
                recipe: [
                  for (final r in v.recipe) RecipeDraftLine(stockItemId: r.stockItemId, quantity: r.quantity),
                ],
              ),
          ],
          groupIds: [for (final g in p.groups) g.id],
          taxIds: [for (final t in p.taxes) t.id],
        ),
        by: by,
      );
}
