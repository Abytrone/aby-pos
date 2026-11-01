import '../core/csv.dart';
import '../core/units.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../models/audit.dart';
import '../models/drafts.dart';
import '../models/enums.dart';
import '../models/staff.dart';
import '../models/stock.dart';
import '../services/money.dart';
import 'catalogue_io.dart' show ImportProblem;
import 'catalogue_rules.dart';

/// One stock item an import would add or change. [setOnHand] is the
/// count the file gives (base units), null to leave it as it is.
class StockImportItem {
  const StockImportItem({required this.draft, required this.onHandNow, this.setOnHand});

  final StockItemDraft draft;
  final int onHandNow;
  final int? setOnHand;

  int get change => setOnHand == null ? 0 : setOnHand! - onHandNow;
}

/// What a stock import would do, worked out before anything is saved.
class StockImportPreview {
  const StockImportPreview({
    required this.items,
    required this.newItems,
    required this.updatedItems,
    required this.unchanged,
    required this.problems,
  });

  final List<StockImportItem> items;
  final int newItems;
  final int updatedItems;
  final int unchanged;
  final List<ImportProblem> problems;

  /// Items whose count the import changes.
  int get recounted => items.where((i) => i.change != 0).length;

  bool get canApply => problems.isEmpty && items.isNotEmpty;
}

/// How a price is worked out from a cost: a margin is the share of the
/// price that is profit (cost 60, 40% margin: 100); a markup is added to
/// the cost (cost 60, 40% markup: 84).
enum PriceRule { margin, markup }

/// The price for [cost] pesewas, rounded up to [step] pesewas (0: to the
/// pesewa), so the profit is never less than asked. Null when it cannot be
/// worked out: no cost, or a margin of 100% or more.
int? priceFromCost(int cost, int percent, PriceRule rule, {int step = 0}) {
  if (cost <= 0 || percent < 0) return null;
  final int raw;
  switch (rule) {
    case PriceRule.margin:
      if (percent >= 100) return null;
      raw = (cost * 100 + (100 - percent) - 1) ~/ (100 - percent);
    case PriceRule.markup:
      raw = (cost * (100 + percent) + 99) ~/ 100;
  }
  return step <= 0 ? raw : (raw + step - 1) ~/ step * step;
}

/// One product to make from a stock item: sold one at a time, or by the
/// kg or litre for items kept in grams or millilitres.
class StockProductPlan {
  const StockProductPlan({
    required this.item,
    required this.sellBy,
    required this.recipeQuantity,
    required this.cost,
    this.alreadySold = false,
    this.nameTaken = false,
  });

  final StockItem item;
  final SellBy sellBy;

  /// Base units of the item used per one sold (or per kg / litre).
  final int recipeQuantity;

  /// Pesewas at cost for one sold (or per kg / litre).
  final int cost;

  /// A product's recipe already uses the item.
  final bool alreadySold;

  /// A product already has the item's name.
  final bool nameTaken;

  /// Ticked to begin with: new to the menu, with a cost to price from.
  bool get suggested => !alreadySold && !nameTaken && cost > 0;

  /// "per kg", "per L", or nothing for pieces.
  String get per => switch (sellBy) {
        SellBy.each => '',
        SellBy.kg => 'kg',
        SellBy.litre => 'L',
      };
}

/// Stock items to and from CSV (the same columns stock export writes), and
/// products made from stock items in bulk, priced at a margin.
class StockIo {
  StockIo(this._db, this._stock, this._catalog, this._rules, this._audit);

  final AppDatabase _db;
  final StockRepository _stock;
  final CatalogRepository _catalog;
  final CatalogueRules _rules;
  final AuditRepository _audit;

  static const stockColumns = ['stock_item', 'unit', 'cost_per', 'cost', 'on_hand', 'low_below'];

  static const requiredColumns = {'stock_item'};

  /// Other headings spreadsheets use for the same columns.
  static const _aliases = {
    'name': 'stock_item',
    'item': 'stock_item',
    'item_name': 'stock_item',
    'stock': 'stock_item',
    'stock_name': 'stock_item',
    'ingredient': 'stock_item',
    'product': 'stock_item',
    'uom': 'unit',
    'units': 'unit',
    'per': 'cost_per',
    'cost_unit': 'cost_per',
    'unit_cost': 'cost',
    'cost_price': 'cost',
    'buying_price': 'cost',
    'purchase_price': 'cost',
    'price': 'cost',
    'quantity': 'on_hand',
    'qty': 'on_hand',
    'in_stock': 'on_hand',
    'stock_on_hand': 'on_hand',
    'count': 'on_hand',
    'reorder_point': 'low_below',
    'reorder_level': 'low_below',
    'reorder_at': 'low_below',
    'low_stock': 'low_below',
    'minimum': 'low_below',
    'min': 'low_below',
  };

  static String columnFor(String heading) {
    final h = heading.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_').replaceAll(RegExp(r'[^a-z_]'), '');
    return _aliases[h] ?? h;
  }

  /// "kg" → kg, "pieces" → piece; null when not a unit.
  static DisplayUnit? displayUnitFor(String text) => switch (text.trim().toLowerCase().replaceAll('.', '')) {
        'piece' || 'pieces' || 'pcs' || 'pc' || 'each' || 'unit' || 'units' || 'ea' => DisplayUnit.piece,
        'g' || 'gram' || 'grams' || 'gm' => DisplayUnit.g,
        'kg' || 'kgs' || 'kilo' || 'kilos' || 'kilogram' || 'kilograms' => DisplayUnit.kg,
        'ml' || 'millilitre' || 'millilitres' || 'milliliter' || 'milliliters' => DisplayUnit.ml,
        'l' || 'litre' || 'litres' || 'liter' || 'liters' || 'ltr' => DisplayUnit.l,
        _ => null,
      };

  /// A filled-in example to start from.
  String sampleStock() => Csv.encode([
        stockColumns,
        ['Vanilla ice cream', 'ml', 'L', '45.00', '20', '5'],
        ['Wafer cones', 'piece', 'pcs', '0.60', '400', '100'],
        ['Sugar', 'g', 'kg', '14.00', '12.5', '2'],
        ['Bottled water', 'piece', 'pcs', '2.10', '48', '12'],
      ]);

  /// Reads a CSV and works out what would change. Nothing is saved.
  Future<StockImportPreview> previewStock(String csv) async {
    final rows = Csv.decode(csv);
    StockImportPreview fail(String message) => StockImportPreview(
          items: const [],
          newItems: 0,
          updatedItems: 0,
          unchanged: 0,
          problems: [ImportProblem(1, message)],
        );
    if (rows.isEmpty) return fail('The file is empty.');
    final header = [for (final h in rows.first) columnFor(h)];
    int col(String name) => header.indexOf(name);
    if (col('stock_item') < 0) return fail('The first row needs at least a "stock_item" column.');
    String cell(List<String> r, String name) {
      final i = col(name);
      return i < 0 || i >= r.length ? '' : r[i].trim();
    }

    final existing = {for (final i in await _stock.items(includeInactive: true)) i.name.toLowerCase(): i};
    final problems = <ImportProblem>[];
    final items = <StockImportItem>[];
    final seen = <String>{};
    var created = 0, updated = 0, unchanged = 0;
    for (final (i, r) in rows.skip(1).indexed) {
      final rowNo = i + 2;
      if (r.every((c) => c.trim().isEmpty)) continue;
      final name = cell(r, 'stock_item');
      if (name.isEmpty) {
        problems.add(ImportProblem(rowNo, 'No stock item name.'));
        continue;
      }
      if (!seen.add(name.toLowerCase())) {
        problems.add(ImportProblem(rowNo, '$name is in the file twice.'));
        continue;
      }
      final old = existing[name.toLowerCase()];

      // The unit it is kept in, and the unit the cost and counts are in.
      final unitText = cell(r, 'unit');
      final perText = cell(r, 'cost_per');
      final unitAsTyped = unitText.isEmpty ? null : displayUnitFor(unitText);
      final per = perText.isEmpty ? null : displayUnitFor(perText);
      if (unitText.isNotEmpty && unitAsTyped == null) {
        problems.add(ImportProblem(rowNo, 'Check the unit for $name: piece, g or ml.'));
        continue;
      }
      if (perText.isNotEmpty && per == null) {
        problems.add(ImportProblem(rowNo, 'Check cost_per for $name: pcs, g, kg, ml or L.'));
        continue;
      }
      final unit = unitAsTyped?.base ?? per?.base ?? old?.unit ?? StockUnit.piece;
      final counted = per ?? (unitAsTyped != null && unitAsTyped.factor > 1 ? unitAsTyped : DisplayUnit.bulk(unit));
      if (counted.base != unit) {
        problems.add(ImportProblem(rowNo, '$name is kept in ${unit.name} but costed per ${counted.symbol}.'));
        continue;
      }
      if (old != null && old.unit != unit && old.onHand != 0) {
        problems.add(ImportProblem(rowNo, '$name has stock in ${old.unit.name}: count it to 0 before changing its unit.'));
        continue;
      }

      final costText = cell(r, 'cost');
      final cost = costText.isEmpty ? null : parseMoney(costText);
      if (costText.isNotEmpty && (cost == null || cost < 0)) {
        problems.add(ImportProblem(rowNo, 'Check the cost for $name.'));
        continue;
      }
      final onHandText = cell(r, 'on_hand');
      final onHand = onHandText.isEmpty ? null : parseQuantity(onHandText, counted);
      if (onHandText.isNotEmpty && (onHand == null || onHand < 0)) {
        problems.add(ImportProblem(rowNo, 'Check on_hand for $name.'));
        continue;
      }
      final lowText = cell(r, 'low_below');
      final low = lowText.isEmpty ? null : parseQuantity(lowText, counted);
      if (lowText.isNotEmpty && (low == null || low < 0)) {
        problems.add(ImportProblem(rowNo, 'Check low_below for $name.'));
        continue;
      }

      final draft = StockItemDraft(
        id: old?.id,
        name: old?.name ?? name,
        unit: unit,
        costMilli: cost == null ? (old?.costMilli ?? 0) : costMilliFromPrice(cost, counted),
        reorderPoint: lowText.isEmpty ? old?.reorderPoint : low,
        reorderQty: old?.reorderQty,
        supplierId: old?.supplierId,
        tracksExpiry: old?.tracksExpiry ?? false,
      );
      final item = StockImportItem(draft: draft, onHandNow: old?.onHand ?? 0, setOnHand: onHand);
      if (old == null) {
        created++;
      } else if (draft.unit == old.unit &&
          draft.costMilli == old.costMilli &&
          draft.reorderPoint == old.reorderPoint &&
          item.change == 0) {
        unchanged++;
        continue;
      } else {
        updated++;
      }
      items.add(item);
    }
    return StockImportPreview(
      items: items,
      newItems: created,
      updatedItems: updated,
      unchanged: unchanged,
      problems: problems,
    );
  }

  /// Saves a preview: all of it, or none of it. Counts that change are
  /// recorded as adjustments, so the stock history shows the import.
  Future<void> applyStock(StockImportPreview preview, {required Staff by}) async {
    if (!preview.canApply) throw const StockException('Fix the problems in the file first.');
    await _db.transaction(() async {
      for (final i in preview.items) {
        final id = await _stock.saveItem(i.draft, by: by);
        if (i.change != 0) await _stock.adjust(id, i.change, note: 'Stock import', by: by);
      }
      await _audit.record(
        action: AuditAction.stockImported,
        actor: by,
        summary: 'Imported ${preview.newItems} new and ${preview.updatedItems} changed stock items',
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Products from stock

  /// A plan for each active stock item that is not made here: what the
  /// product would sell by and cost, and whether it is already on the menu.
  Future<List<StockProductPlan>> productPlans() async {
    final items = (await _stock.items()).where((i) => i.active && !i.madeHere);
    final used = {
      for (final r in await _db
          .customSelect(
            'SELECT DISTINCT r.stock_item_id AS id FROM recipe_items r '
            'JOIN product_variants v ON v.id = r.variant_id AND v.active = 1 '
            'JOIN products p ON p.id = v.product_id AND p.archived_at IS NULL '
            'WHERE r.deleted_at IS NULL',
            readsFrom: {_db.recipeItems, _db.productVariants, _db.products},
          )
          .get())
        r.read<String>('id'),
    };
    final names = {
      for (final p in (await _catalog.load(includeInactive: true)).products.where((p) => !p.archived)) p.name.toLowerCase(),
    };
    return [
      for (final i in items)
        () {
          final per = i.unit == StockUnit.piece ? 1 : 1000;
          return StockProductPlan(
            item: i,
            sellBy: switch (i.unit) {
              StockUnit.piece => SellBy.each,
              StockUnit.g => SellBy.kg,
              StockUnit.ml => SellBy.litre,
            },
            recipeQuantity: per,
            cost: costOf(per, i.costMilli),
            alreadySold: used.contains(i.id),
            nameTaken: names.contains(i.name.toLowerCase()),
          );
        }(),
    ];
  }

  /// Makes a product for each plan at its price ([prices]: stock item ID →
  /// pesewas), in [categoryId] or a new category called [newCategory]. Each
  /// product's recipe uses its stock item, so selling it takes stock off.
  /// Returns how many were made.
  Future<int> createProducts(
    List<StockProductPlan> plans, {
    required Map<String, int> prices,
    String? categoryId,
    String? newCategory,
    bool onTill = true,
    required Staff by,
  }) async {
    if (plans.isEmpty) throw const CatalogueException('Tick at least one stock item.');
    if (categoryId == null && (newCategory == null || newCategory.trim().isEmpty)) {
      throw const CatalogueException('Pick a category.');
    }
    for (final p in plans) {
      if (prices[p.item.id] == null) throw CatalogueException('Enter a price for ${p.item.name}.');
    }
    return _db.transaction(() async {
      final category = categoryId ??
          await _rules.saveCategory(CategoryDraft(name: newCategory!.trim(), tone: CategoryTone.blue), by: by);
      for (final p in plans) {
        await _rules.saveProduct(
          ProductDraft(
            categoryId: category,
            name: p.item.name,
            active: onTill,
            sellBy: p.sellBy,
            variants: [
              VariantDraft(
                price: prices[p.item.id]!,
                recipe: [RecipeDraftLine(stockItemId: p.item.id, quantity: p.recipeQuantity)],
              ),
            ],
          ),
          by: by,
        );
      }
      await _audit.record(
        action: AuditAction.productsFromStock,
        actor: by,
        summary: 'Made ${plans.length} products from stock',
      );
      return plans.length;
    });
  }
}
