import '../core/csv.dart';
import '../core/units.dart';
import '../data/repositories/catalog_repository.dart';
import '../models/audit.dart';
import '../models/catalog.dart';
import '../models/drafts.dart';
import '../models/enums.dart';
import '../models/staff.dart';
import '../models/stock.dart';
import '../data/repositories/audit_repository.dart';
import '../services/money.dart';
import 'catalogue_rules.dart';

/// One problem in an import file. [row] counts from 1 for the header.
class ImportProblem {
  const ImportProblem(this.row, this.message);
  final int row;
  final String message;
}

/// What an import would do, worked out before anything is saved.
class ImportPreview {
  const ImportPreview({
    required this.drafts,
    required this.newProducts,
    required this.updatedProducts,
    required this.unchanged,
    required this.newCategories,
    required this.problems,
  });

  /// Product name → draft (new or updated).
  final List<ProductDraft> drafts;
  final int newProducts;
  final int updatedProducts;
  final int unchanged;
  final List<String> newCategories;
  final List<ImportProblem> problems;

  bool get canApply => problems.isEmpty && drafts.isNotEmpty;
}

/// Products to and from CSV, so a shop with hundreds of items can start
/// from a spreadsheet. Import only adds products and updates prices, costs
/// and barcodes: it never removes variants, recipes, options or taxes.
class CatalogueIo {
  CatalogueIo(this._catalog, this._rules, this._audit);

  final CatalogRepository _catalog;
  final CatalogueRules _rules;
  final AuditRepository _audit;

  static const productColumns = ['category', 'product', 'variant', 'price', 'cost', 'barcodes', 'tile_line', 'on_till'];

  static String _money(int? p) => p == null ? '' : '${p ~/ 100}.${(p % 100).toString().padLeft(2, '0')}';

  /// One row per variant.
  String exportProducts(Catalogue c) {
    final rows = <List<String>>[productColumns];
    for (final p in c.products.where((p) => !p.archived)) {
      final category = c.category(p.categoryId)?.name ?? '';
      for (final v in p.variants) {
        rows.add([
          category,
          p.name,
          v.name ?? '',
          _money(v.price),
          _money(v.recipe.isEmpty ? v.manualCost : null),
          v.barcodes.join('|'),
          p.detail ?? '',
          p.active ? 'yes' : 'no',
        ]);
      }
    }
    return Csv.encode(rows);
  }

  String exportStock(List<StockItem> items) {
    final rows = <List<String>>[
      ['stock_item', 'unit', 'cost_per', 'cost', 'on_hand', 'low_below'],
    ];
    for (final i in items.where((i) => i.active)) {
      final bulk = DisplayUnit.bulk(i.unit);
      rows.add([
        i.name,
        i.unit.name,
        bulk.symbol,
        _money(i.bulkPrice),
        quantityIn(i.onHand, bulk),
        i.reorderPoint == null ? '' : quantityIn(i.reorderPoint!, bulk),
      ]);
    }
    return Csv.encode(rows);
  }

  /// Reads a CSV and works out what would change. Nothing is saved.
  Future<ImportPreview> previewProducts(String csv) async {
    final rows = Csv.decode(csv);
    final problems = <ImportProblem>[];
    if (rows.isEmpty) {
      return const ImportPreview(drafts: [], newProducts: 0, updatedProducts: 0, unchanged: 0, newCategories: [], problems: [ImportProblem(1, 'The file is empty.')]);
    }
    final header = [for (final h in rows.first) h.trim().toLowerCase().replaceAll(' ', '_')];
    int col(String name) => header.indexOf(name);
    if (col('product') < 0 || col('price') < 0) {
      return ImportPreview(
        drafts: const [],
        newProducts: 0,
        updatedProducts: 0,
        unchanged: 0,
        newCategories: const [],
        problems: const [ImportProblem(1, 'The first row needs at least "product" and "price" columns.')],
      );
    }
    String cell(List<String> r, String name) {
      final i = col(name);
      return i < 0 || i >= r.length ? '' : r[i].trim();
    }

    final catalogue = await _catalog.load(includeInactive: true);
    final categoriesByName = {for (final c in catalogue.categories) c.name.toLowerCase(): c};
    final productsByName = {
      for (final p in catalogue.products.where((p) => !p.archived)) p.name.toLowerCase(): p,
    };

    // Group rows by product.
    final grouped = <String, List<(int, List<String>)>>{};
    for (final (i, r) in rows.skip(1).indexed) {
      final name = cell(r, 'product');
      if (name.isEmpty) {
        problems.add(ImportProblem(i + 2, 'No product name.'));
        continue;
      }
      grouped.putIfAbsent(name.toLowerCase(), () => []).add((i + 2, r));
    }

    final drafts = <ProductDraft>[];
    final newCategories = <String>{};
    var created = 0;
    var updated = 0;
    var unchanged = 0;
    for (final entry in grouped.values) {
      final first = entry.first.$2;
      final name = cell(first, 'product');
      final existing = productsByName[name.toLowerCase()];
      final categoryName = cell(first, 'category');
      String? categoryId = existing?.categoryId;
      if (categoryName.isNotEmpty) {
        final match = categoriesByName[categoryName.toLowerCase()];
        if (match != null) {
          categoryId = match.id;
        } else {
          newCategories.add(categoryName);
          categoryId = 'new:$categoryName';
        }
      }
      if (categoryId == null) {
        problems.add(ImportProblem(entry.first.$1, 'No category for $name.'));
        continue;
      }

      final variants = <VariantDraft>[
        for (final v in existing?.variants ?? const <Variant>[])
          VariantDraft(
            id: v.id,
            name: v.name,
            price: v.price,
            manualCost: v.manualCost,
            barcodes: v.barcodes,
            recipe: [for (final r in v.recipe) RecipeDraftLine(stockItemId: r.stockItemId, quantity: r.quantity)],
          ),
      ];
      var changed = existing == null;
      for (final (rowNo, r) in entry) {
        final price = parseMoney(cell(r, 'price'));
        if (price == null) {
          problems.add(ImportProblem(rowNo, 'Check the price for $name.'));
          continue;
        }
        final costText = cell(r, 'cost');
        final cost = costText.isEmpty ? null : parseMoney(costText);
        if (costText.isNotEmpty && cost == null) {
          problems.add(ImportProblem(rowNo, 'Check the cost for $name.'));
          continue;
        }
        final variantName = cell(r, 'variant');
        final barcodesText = cell(r, 'barcodes');
        final barcodes = barcodesText.isEmpty
            ? null
            : barcodesText.split(RegExp(r'[|;]')).map((b) => b.trim()).where((b) => b.isNotEmpty).toList();
        final index = variants.indexWhere((v) => (v.name ?? '').toLowerCase() == variantName.toLowerCase() ||
            (variants.length == 1 && v.name == null && variantName.isEmpty));
        if (index == -1) {
          variants.add(VariantDraft(name: variantName.isEmpty ? null : variantName, price: price, manualCost: cost, barcodes: barcodes ?? const []));
          changed = true;
        } else {
          final old = variants[index];
          final next = VariantDraft(
            id: old.id,
            name: old.name,
            price: price,
            manualCost: costText.isEmpty ? old.manualCost : cost,
            barcodes: barcodes ?? old.barcodes,
            recipe: old.recipe,
          );
          if (next.price != old.price ||
              next.manualCost != old.manualCost ||
              next.barcodes.join('|') != old.barcodes.join('|')) {
            changed = true;
          }
          variants[index] = next;
        }
      }
      // Two unnamed variants: the second needs a name.
      if (variants.length > 1 && variants.any((v) => (v.name ?? '').isEmpty)) {
        problems.add(ImportProblem(entry.first.$1, '$name has several prices: give each a variant name.'));
        continue;
      }
      final onTill = cell(first, 'on_till').toLowerCase();
      final tile = cell(first, 'tile_line');
      final draft = ProductDraft(
        id: existing?.id,
        categoryId: categoryId,
        name: existing?.name ?? name,
        detail: tile.isEmpty ? existing?.detail : tile,
        description: existing?.description,
        active: onTill.isEmpty ? (existing?.active ?? true) : !['no', 'false', '0', 'off'].contains(onTill),
        variants: variants,
        groupIds: [for (final g in existing?.groups ?? const <OptionGroup>[]) g.id],
        taxIds: [for (final t in existing?.taxes ?? const <TaxRate>[]) t.id],
      );
      if (existing != null && (draft.active != existing.active || draft.detail != existing.detail)) changed = true;
      if (!changed) {
        unchanged++;
        continue;
      }
      existing == null ? created++ : updated++;
      drafts.add(draft);
    }
    return ImportPreview(
      drafts: drafts,
      newProducts: created,
      updatedProducts: updated,
      unchanged: unchanged,
      newCategories: newCategories.toList(),
      problems: problems,
    );
  }

  /// Saves a preview: all of it, or none of it.
  Future<void> applyProducts(ImportPreview preview, {required Staff by}) async {
    if (!preview.canApply) throw const CatalogueException('Fix the problems in the file first.');
    await _catalog.transaction(() async {
      final created = <String, String>{};
      for (final name in preview.newCategories) {
        created[name] = await _rules.saveCategory(CategoryDraft(name: name, tone: CategoryTone.blue), by: by);
      }
      for (final d in preview.drafts) {
        final categoryId = d.categoryId.startsWith('new:') ? created[d.categoryId.substring(4)]! : d.categoryId;
        await _rules.saveProduct(
          ProductDraft(
            id: d.id,
            categoryId: categoryId,
            name: d.name,
            detail: d.detail,
            description: d.description,
            active: d.active,
            variants: d.variants,
            groupIds: d.groupIds,
            taxIds: d.taxIds,
          ),
          by: by,
        );
      }
      await _audit.record(
        action: AuditAction.catalogueImported,
        actor: by,
        summary: 'Imported ${preview.newProducts} new and ${preview.updatedProducts} changed products',
      );
    });
  }
}
