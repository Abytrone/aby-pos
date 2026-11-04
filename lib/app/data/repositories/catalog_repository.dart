import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/catalog.dart';
import '../../models/drafts.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// Everything on the menu, read in one go.
class Catalogue {
  const Catalogue({
    required this.categories,
    required this.products,
    required this.groups,
    required this.taxRates,
  });

  final List<Category> categories;
  final List<Product> products;
  final List<OptionGroup> groups;
  final List<TaxRate> taxRates;

  Category? category(String id) =>
      categories.where((c) => c.id == id).firstOrNull;
}

class CatalogueException implements Exception {
  const CatalogueException(this.message);
  final String message;

  @override
  String toString() => 'CatalogueException: $message';
}

/// The menu: categories, products and their variants, option groups,
/// recipes, taxes and barcodes. Reads are plain; writes go through the
/// catalogue use cases (lib/app/domain), which check the rules first.
class CatalogRepository {
  CatalogRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  /// Fires when anything on the menu (or stock costs) changes, so the till
  /// can reload.
  Stream<void> watchChanges() => _db
      .tableUpdates(
        TableUpdateQuery.onAllTables([
          _db.categories,
          _db.products,
          _db.productVariants,
          _db.optionGroups,
          _db.optionItems,
          _db.productOptionGroups,
          _db.recipeItems,
          _db.stockItems,
          _db.taxRates,
          _db.productTaxes,
          _db.barcodes,
        ]),
      )
      .map((_) {});

  // ---------------------------------------------------------------------------
  // Reads

  Future<List<Category>> categories({bool includeInactive = false}) async {
    final query = _db.select(_db.categories)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([
        (c) => OrderingTerm(expression: c.sortOrder),
        (c) => OrderingTerm(expression: c.name),
      ]);
    if (!includeInactive) query.where((c) => c.active.equals(true));
    return [
      for (final r in await query.get())
        Category(
          id: r.id,
          name: r.name,
          tone: r.tone,
          parentId: r.parentId,
          active: r.active,
          sortOrder: r.sortOrder,
          icon: r.icon,
        ),
    ];
  }

  /// The menu. The till uses the default (sellable products only);
  /// Manage → Products asks for everything.
  Future<Catalogue> load({
    bool includeInactive = false,
    bool includeArchived = false,
  }) async {
    final stock = {
      for (final s in await (_db.select(
        _db.stockItems,
      )..where((s) => s.deletedAt.isNull())).get())
        s.id: s,
    };
    final recipeRows = await (_db.select(
      _db.recipeItems,
    )..where((r) => r.deletedAt.isNull())).get();
    List<RecipeLine> recipe(bool Function(RecipeItemRow) match) => [
      for (final r in recipeRows.where(match))
        if (stock[r.stockItemId] case final s?)
          RecipeLine(
            stockItemId: s.id,
            stockItemName: s.name,
            unit: s.unit,
            quantity: r.quantity,
            costMilli: s.costMilli,
          ),
    ];
    VariantStockLink? stockLink(VariantRow variant) {
      final stockItemId = variant.stockItemId;
      final item = stockItemId == null ? null : stock[stockItemId];
      return item == null
          ? null
          : VariantStockLink(
              stockItemId: item.id,
              stockItemName: item.name,
              unit: item.unit,
              quantity: variant.stockQuantity,
              costMilli: item.costMilli,
            );
    }

    final barcodeRows = await (_db.select(
      _db.barcodes,
    )..where((b) => b.deletedAt.isNull())).get();
    final barcodesByVariant = <String, List<String>>{};
    for (final b in barcodeRows) {
      barcodesByVariant.putIfAbsent(b.variantId, () => []).add(b.code);
    }

    final optionRows =
        await (_db.select(_db.optionItems)
              ..where((o) => o.deletedAt.isNull() & o.active.equals(true))
              ..orderBy([(o) => OrderingTerm(expression: o.sortOrder)]))
            .get();
    final groupRows =
        await (_db.select(_db.optionGroups)
              ..where((g) => g.deletedAt.isNull())
              ..orderBy([
                (g) => OrderingTerm(expression: g.sortOrder),
                (g) => OrderingTerm(expression: g.name),
              ]))
            .get();
    final groups = [
      for (final g in groupRows)
        if (includeInactive || g.active)
          OptionGroup(
            id: g.id,
            name: g.name,
            minSelect: g.minSelect,
            maxSelect: g.maxSelect,
            allowRepeat: g.allowRepeat,
            active: g.active,
            options: [
              for (final o in optionRows.where((o) => o.groupId == g.id))
                Option(
                  id: o.id,
                  groupId: g.id,
                  name: o.name,
                  priceDelta: o.priceDelta,
                  isDefault: o.isDefault,
                  variantId: o.variantId,
                  recipe: switch (recipe((r) => r.optionId == o.id)) {
                    final own when own.isNotEmpty || o.variantId == null => own,
                    _ => recipe((r) => r.variantId == o.variantId),
                  },
                ),
            ],
          ),
    ];
    final groupsById = {for (final g in groups) g.id: g};

    final taxRows =
        await (_db.select(_db.taxRates)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
            .get();
    final taxRates = [
      for (final t in taxRows)
        if (includeInactive || t.active)
          TaxRate(
            id: t.id,
            name: t.name,
            rateBp: t.rateBp,
            compound: t.compound,
            active: t.active,
          ),
    ];
    final taxById = {for (final t in taxRates) t.id: t};

    final variantRows =
        await (_db.select(_db.productVariants)
              ..where((v) => v.deletedAt.isNull() & v.active.equals(true))
              ..orderBy([(v) => OrderingTerm(expression: v.sortOrder)]))
            .get();
    final linkRows =
        await (_db.select(_db.productOptionGroups)
              ..where((l) => l.deletedAt.isNull())
              ..orderBy([(l) => OrderingTerm(expression: l.sortOrder)]))
            .get();
    final productTaxRows = await (_db.select(
      _db.productTaxes,
    )..where((t) => t.deletedAt.isNull())).get();

    final productQuery = _db.select(_db.products)
      ..where((p) => p.deletedAt.isNull())
      ..orderBy([
        (p) => OrderingTerm(expression: p.sortOrder),
        (p) => OrderingTerm(expression: p.name),
      ]);
    if (!includeInactive) productQuery.where((p) => p.active.equals(true));
    if (!includeArchived) productQuery.where((p) => p.archivedAt.isNull());

    final products = <Product>[];
    for (final p in await productQuery.get()) {
      final variants = [
        for (final v in variantRows.where((v) => v.productId == p.id))
          Variant(
            id: v.id,
            name: v.name,
            price: v.price,
            manualCost: v.manualCost,
            stockLink: stockLink(v),
            recipe: recipe((r) => r.variantId == v.id),
            barcodes: barcodesByVariant[v.id] ?? const [],
          ),
      ];
      if (variants.isEmpty) continue; // nothing to sell
      products.add(
        Product(
          id: p.id,
          categoryId: p.categoryId,
          name: p.name,
          detail: p.detail,
          description: p.description,
          active: p.active,
          archived: p.archivedAt != null,
          sellBy: p.sellBy,
          openPrice: p.openPrice,
          minPrice: p.minPrice,
          maxPrice: p.maxPrice,
          quickOrder: p.quickOrder,
          commission: p.commission,
          variants: variants,
          groups: [
            for (final l in linkRows.where((l) => l.productId == p.id))
              if (groupsById[l.groupId] case final g?
                  when g.active || includeInactive)
                g,
          ],
          taxes: [
            for (final t in productTaxRows.where((t) => t.productId == p.id))
              if (taxById[t.taxRateId] case final rate? when rate.active) rate,
          ],
        ),
      );
    }

    return Catalogue(
      categories: await categories(includeInactive: includeInactive),
      products: products,
      groups: groups,
      taxRates: taxRates,
    );
  }

  /// Older call sites (and the till) want just the sellable products.
  Future<List<Product>> products() async => (await load()).products;

  /// The variant with this barcode, and its product.
  Future<(String productId, String variantId)?> findBarcode(String code) async {
    final row =
        await (_db.select(_db.barcodes).join([
              innerJoin(
                _db.productVariants,
                _db.productVariants.id.equalsExp(_db.barcodes.variantId),
              ),
            ])..where(
              _db.barcodes.code.equals(code.trim()) &
                  _db.barcodes.deletedAt.isNull() &
                  _db.productVariants.active.equals(true),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    final v = row.readTable(_db.productVariants);
    return (v.productId, v.id);
  }

  /// The product name using [code], other than [exceptVariantIds].
  Future<String?> barcodeOwner(
    String code, {
    Set<String> exceptVariantIds = const {},
  }) async {
    final rows =
        await (_db.select(_db.barcodes).join([
              innerJoin(
                _db.productVariants,
                _db.productVariants.id.equalsExp(_db.barcodes.variantId),
              ),
              innerJoin(
                _db.products,
                _db.products.id.equalsExp(_db.productVariants.productId),
              ),
            ])..where(
              _db.barcodes.code.lower().equals(code.trim().toLowerCase()) &
                  _db.barcodes.deletedAt.isNull(),
            ))
            .get();
    for (final r in rows) {
      if (!exceptVariantIds.contains(r.readTable(_db.barcodes).variantId)) {
        return r.readTable(_db.products).name;
      }
    }
    return null;
  }

  /// The existing product with this name, including inactive or archived
  /// products. A linked stock item may intentionally share the same name.
  Future<String?> productNameOwner(
    String name, {
    String? exceptProductId,
  }) async {
    final rows =
        await (_db.select(_db.products)..where(
              (p) =>
                  p.deletedAt.isNull() &
                  p.name.lower().equals(name.trim().toLowerCase()),
            ))
            .get();
    return rows.where((p) => p.id != exceptProductId).firstOrNull?.name;
  }

  Future<Uint8List?> photo(String productId) async => (await (_db.select(
    _db.productPhotos,
  )..where((p) => p.productId.equals(productId))).getSingleOrNull())?.image;

  Future<Map<String, Uint8List>> allPhotos() async => {
    for (final p in await _db.select(_db.productPhotos).get())
      p.productId: p.image,
  };

  // ---------------------------------------------------------------------------
  // Writes (called by the catalogue use cases, inside their checks)

  /// Creates or updates a product with its variants, barcodes, recipes,
  /// option groups and taxes. Returns the product ID.
  Future<String> saveProduct(ProductDraft d, {required Staff by}) {
    return _db.transaction(() async {
      final now = clock.now();
      final isNew = d.id == null;
      final productId = d.id ?? newId();
      final nameOwner = await productNameOwner(d.name, exceptProductId: d.id);
      if (nameOwner != null) {
        throw CatalogueException(
          'A product named "$nameOwner" already exists.',
        );
      }
      for (final variant in d.variants) {
        final stockItemId = variant.stockItemId;
        if (stockItemId == null) continue;
        if (variant.recipe.isNotEmpty || variant.stockQuantity <= 0) {
          throw const CatalogueException(
            'A variant can use either a linked stock item or a recipe, with a positive quantity.',
          );
        }
        final item =
            await (_db.select(_db.stockItems)..where(
                  (s) => s.id.equals(stockItemId) & s.deletedAt.isNull(),
                ))
                .getSingleOrNull();
        final expectedUnit = switch (d.sellBy) {
          SellBy.each => StockUnit.piece,
          SellBy.kg => StockUnit.g,
          SellBy.litre => StockUnit.ml,
        };
        if (item == null || item.unit != expectedUnit) {
          throw const CatalogueException(
            'Choose a stock item with units that match how this product is sold.',
          );
        }
      }
      String? clean(String? v) =>
          v == null || v.trim().isEmpty ? null : v.trim();
      final changes = <String>[];

      Future<int?> quickOrder(int? current) async {
        if (!d.onQuickTab) return null;
        if (current != null) return current;
        final max = _db.products.quickOrder.max();
        final q = _db.selectOnly(_db.products)..addColumns([max]);
        return ((await q.map((r) => r.read(max)).getSingle()) ?? -1) + 1;
      }

      if (isNew) {
        await _db.insertTracked(
          _db.products,
          ProductsCompanion.insert(
            id: productId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            categoryId: d.categoryId,
            name: d.name.trim(),
            detail: Value(clean(d.detail)),
            description: Value(clean(d.description)),
            active: Value(d.active),
            sortOrder: const Value(1000),
            sellBy: Value(d.sellBy),
            openPrice: Value(d.openPrice),
            minPrice: Value(d.openPrice ? d.minPrice : null),
            maxPrice: Value(d.openPrice ? d.maxPrice : null),
            quickOrder: Value(await quickOrder(null)),
            commission: Value(d.commission),
          ),
        );
      } else {
        final row = await (_db.select(
          _db.products,
        )..where((p) => p.id.equals(productId))).getSingle();
        final updated = row.copyWith(
          categoryId: d.categoryId,
          name: d.name.trim(),
          detail: Value(clean(d.detail)),
          description: Value(clean(d.description)),
          active: d.active,
          sellBy: d.sellBy,
          openPrice: d.openPrice,
          minPrice: Value(d.openPrice ? d.minPrice : null),
          maxPrice: Value(d.openPrice ? d.maxPrice : null),
          quickOrder: Value(await quickOrder(row.quickOrder)),
          commission: Value(d.commission),
        );
        if (updated != row) {
          if (row.sellBy != updated.sellBy)
            changes.add('sold by ${updated.sellBy.name}');
          if (row.openPrice != updated.openPrice ||
              row.minPrice != updated.minPrice ||
              row.maxPrice != updated.maxPrice) {
            changes.add(
              updated.openPrice ? 'price typed at the till' : 'fixed price',
            );
          }
          if ((row.quickOrder == null) != (updated.quickOrder == null)) {
            changes.add(
              updated.quickOrder == null
                  ? 'off the Quick tab'
                  : 'on the Quick tab',
            );
          }
          if (row.name != updated.name) changes.add('name');
          if (row.categoryId != updated.categoryId) changes.add('category');
          if (row.active != updated.active)
            changes.add(updated.active ? 'back on the till' : 'off the till');
          if (row.detail != updated.detail ||
              row.description != updated.description)
            changes.add('description');
          await _db.updateTracked(
            _db.products,
            updated.copyWith(updatedAt: now),
          );
        }
      }

      // Variants: update those kept, add new ones, retire the rest.
      final existing =
          await (_db.select(_db.productVariants)..where(
                (v) =>
                    v.productId.equals(productId) &
                    v.deletedAt.isNull() &
                    v.active.equals(true),
              ))
              .get();
      final keptIds = <String>{};
      for (final (index, vd) in d.variants.indexed) {
        final current = vd.id == null
            ? null
            : existing.where((e) => e.id == vd.id).firstOrNull;
        final variantId = current?.id ?? newId();
        keptIds.add(variantId);
        if (current == null) {
          await _db.insertTracked(
            _db.productVariants,
            ProductVariantsCompanion.insert(
              id: variantId,
              createdAt: now,
              updatedAt: now,
              deviceId: _device.deviceId,
              productId: productId,
              name: Value(clean(vd.name)),
              price: vd.price,
              manualCost: Value(vd.manualCost),
              stockItemId: Value(vd.stockItemId),
              stockQuantity: Value(vd.stockQuantity),
              sortOrder: Value(index),
            ),
          );
          if (!isNew) changes.add('added ${clean(vd.name) ?? 'a variant'}');
        } else {
          final updated = current.copyWith(
            name: Value(clean(vd.name)),
            price: vd.price,
            manualCost: Value(vd.manualCost),
            stockItemId: Value(vd.stockItemId),
            stockQuantity: vd.stockQuantity,
            sortOrder: index,
          );
          if (updated != current) {
            await _db.updateTracked(
              _db.productVariants,
              updated.copyWith(updatedAt: now),
            );
          }
          if (current.price != vd.price) {
            await _audit.record(
              action: AuditAction.priceChanged,
              actor: by,
              entity: 'product_variants',
              entityId: variantId,
              summary:
                  '${d.name.trim()}${clean(vd.name) == null ? '' : ', ${clean(vd.name)}'}: '
                  '${formatMoney(current.price)} to ${formatMoney(vd.price)}',
              details: {'before': current.price, 'after': vd.price},
            );
          }
          if (current.manualCost != vd.manualCost) changes.add('cost');
          if (current.stockItemId != vd.stockItemId) {
            changes.add('inventory stock item');
          }
          if (current.stockQuantity != vd.stockQuantity) {
            changes.add('inventory quantity');
          }
        }
        if (await _replaceBarcodes(variantId, vd.barcodes))
          changes.add('barcodes');
        if (await _replaceRecipe(variantId: variantId, lines: vd.recipe))
          changes.add('recipe');
      }
      for (final old in existing.where((e) => !keptIds.contains(e.id))) {
        await _db.updateTracked(
          _db.productVariants,
          old.copyWith(active: false, updatedAt: now),
        );
        changes.add('removed ${old.name ?? 'a variant'}');
      }

      if (await _replaceLinks(productId, d.groupIds)) changes.add('options');
      if (await _replaceTaxes(productId, d.taxIds)) changes.add('taxes');

      if (isNew) {
        await _audit.record(
          action: AuditAction.productCreated,
          actor: by,
          entity: 'products',
          entityId: productId,
          summary: 'Added ${d.name.trim()}',
        );
      } else if (changes.isNotEmpty) {
        await _audit.record(
          action: AuditAction.productUpdated,
          actor: by,
          entity: 'products',
          entityId: productId,
          summary: '${d.name.trim()}: ${changes.toSet().join(', ')}',
        );
      }
      return productId;
    });
  }

  /// True when the set changed.
  /// Gives every listed variant that has no barcode an internal one
  /// (CAT-08): "ABY00001" and up, printed as Code 128. Returns how many.
  Future<int> generateBarcodes(
    Iterable<String> variantIds, {
    required Staff by,
  }) {
    return _db.transaction(() async {
      final have = {
        for (final b in await (_db.select(
          _db.barcodes,
        )..where((b) => b.deletedAt.isNull())).get())
          b.variantId,
      };
      final need = [
        for (final id in variantIds)
          if (!have.contains(id)) id,
      ];
      if (need.isEmpty) return 0;
      final last = await _db
          .customSelect(
            "SELECT COALESCE(MAX(CAST(SUBSTR(code, 4) AS INTEGER)), 0) AS n FROM barcodes WHERE code GLOB 'ABY[0-9]*'",
            readsFrom: {_db.barcodes},
          )
          .getSingle();
      var next = last.read<int>('n');
      final now = clock.now();
      for (final variantId in need) {
        next++;
        await _db.insertTracked(
          _db.barcodes,
          BarcodesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            code: 'ABY${next.toString().padLeft(5, '0')}',
            variantId: variantId,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.barcodesGenerated,
        actor: by,
        entity: 'barcodes',
        entityId: need.first,
        summary:
            'Made ${need.length} internal barcode${need.length == 1 ? '' : 's'}',
      );
      return need.length;
    });
  }

  Future<bool> _replaceBarcodes(String variantId, List<String> codes) async {
    final want = codes.map((c) => c.trim()).where((c) => c.isNotEmpty).toSet();
    final rows =
        await (_db.select(_db.barcodes)..where(
              (b) => b.variantId.equals(variantId) & b.deletedAt.isNull(),
            ))
            .get();
    final have = rows.map((r) => r.code).toSet();
    if (have.length == want.length && have.containsAll(want)) return false;
    for (final r in rows.where((r) => !want.contains(r.code))) {
      await _db.softDeleteTracked(_db.barcodes, r.id);
    }
    final now = clock.now();
    for (final code in want.difference(have)) {
      await _db.insertTracked(
        _db.barcodes,
        BarcodesCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          code: code,
          variantId: variantId,
        ),
      );
    }
    return true;
  }

  /// Replaces a variant's or an option's recipe. True when it changed.
  Future<bool> _replaceRecipe({
    String? variantId,
    String? optionId,
    required List<RecipeDraftLine> lines,
  }) async {
    final rows =
        await (_db.select(_db.recipeItems)..where(
              (r) =>
                  r.deletedAt.isNull() &
                  (variantId != null
                      ? r.variantId.equals(variantId)
                      : r.optionId.equals(optionId!)),
            ))
            .get();
    String key(String item, int qty) => '$item:$qty';
    final have = rows.map((r) => key(r.stockItemId, r.quantity)).toList()
      ..sort();
    final want =
        lines
            .where((l) => l.quantity > 0)
            .map((l) => key(l.stockItemId, l.quantity))
            .toList()
          ..sort();
    if (have.join(',') == want.join(',')) return false;
    for (final r in rows) {
      await _db.softDeleteTracked(_db.recipeItems, r.id);
    }
    final now = clock.now();
    for (final l in lines.where((l) => l.quantity > 0)) {
      await _db.insertTracked(
        _db.recipeItems,
        RecipeItemsCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          variantId: Value(variantId),
          optionId: Value(optionId),
          stockItemId: l.stockItemId,
          quantity: l.quantity,
        ),
      );
    }
    return true;
  }

  Future<bool> _replaceLinks(String productId, List<String> groupIds) async {
    final rows =
        await (_db.select(_db.productOptionGroups)
              ..where(
                (l) => l.productId.equals(productId) & l.deletedAt.isNull(),
              )
              ..orderBy([(l) => OrderingTerm(expression: l.sortOrder)]))
            .get();
    if (rows.map((r) => r.groupId).join(',') == groupIds.join(','))
      return false;
    for (final r in rows) {
      await _db.softDeleteTracked(_db.productOptionGroups, r.id);
    }
    final now = clock.now();
    for (final (i, groupId) in groupIds.indexed) {
      await _db.insertTracked(
        _db.productOptionGroups,
        ProductOptionGroupsCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          productId: productId,
          groupId: groupId,
          sortOrder: Value(i),
        ),
      );
    }
    return true;
  }

  Future<bool> _replaceTaxes(String productId, List<String> taxIds) async {
    final rows =
        await (_db.select(_db.productTaxes)..where(
              (t) => t.productId.equals(productId) & t.deletedAt.isNull(),
            ))
            .get();
    final have = rows.map((r) => r.taxRateId).toSet();
    final want = taxIds.toSet();
    if (have.length == want.length && have.containsAll(want)) return false;
    for (final r in rows.where((r) => !want.contains(r.taxRateId))) {
      await _db.softDeleteTracked(_db.productTaxes, r.id);
    }
    final now = clock.now();
    for (final id in want.difference(have)) {
      await _db.insertTracked(
        _db.productTaxes,
        ProductTaxesCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          productId: productId,
          taxRateId: id,
        ),
      );
    }
    return true;
  }

  /// Archived products disappear from the till and lists but stay in
  /// history and reports.
  Future<void> setArchived(
    String productId, {
    required bool archived,
    required Staff by,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.products,
      )..where((p) => p.id.equals(productId))).getSingle();
      final now = clock.now();
      await _db.updateTracked(
        _db.products,
        row.copyWith(archivedAt: Value(archived ? now : null), updatedAt: now),
      );
      await _audit.record(
        action: archived
            ? AuditAction.productArchived
            : AuditAction.productRestored,
        actor: by,
        entity: 'products',
        entityId: productId,
        summary: '${archived ? 'Archived' : 'Restored'} ${row.name}',
      );
    });
  }

  Future<void> setPhoto(String productId, Uint8List? image) async {
    if (image == null) {
      await (_db.delete(
        _db.productPhotos,
      )..where((p) => p.productId.equals(productId))).go();
    } else {
      await _db
          .into(_db.productPhotos)
          .insertOnConflictUpdate(
            ProductPhotosCompanion.insert(
              productId: productId,
              image: image,
              updatedAt: clock.now(),
            ),
          );
    }
  }

  Future<String> saveCategory(CategoryDraft d, {required Staff by}) {
    return _db.transaction(() async {
      final now = clock.now();
      final id = d.id ?? newId();
      if (d.id == null) {
        await _db.insertTracked(
          _db.categories,
          CategoriesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: d.name.trim(),
            tone: d.tone,
            parentId: Value(d.parentId),
            icon: Value(d.icon),
            sortOrder: const Value(1000),
          ),
        );
      } else {
        final row = await (_db.select(
          _db.categories,
        )..where((c) => c.id.equals(id))).getSingle();
        await _db.updateTracked(
          _db.categories,
          row.copyWith(
            name: d.name.trim(),
            tone: d.tone,
            parentId: Value(d.parentId),
            icon: Value(d.icon),
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.categorySaved,
        actor: by,
        entity: 'categories',
        entityId: id,
        summary:
            '${d.id == null ? 'Added' : 'Changed'} category ${d.name.trim()}',
      );
      return id;
    });
  }

  Future<void> setCategoryActive(
    String id, {
    required bool active,
    required Staff by,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.categories,
      )..where((c) => c.id.equals(id))).getSingle();
      await _db.updateTracked(
        _db.categories,
        row.copyWith(active: active, updatedAt: clock.now()),
      );
      await _audit.record(
        action: AuditAction.categorySaved,
        actor: by,
        entity: 'categories',
        entityId: id,
        summary: '${active ? 'Showed' : 'Hid'} category ${row.name}',
      );
    });
  }

  /// Products (not archived) in a category or its sub-categories.
  Future<int> productCount(String categoryId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS n FROM products p LEFT JOIN categories c ON c.id = p.category_id '
          'WHERE p.deleted_at IS NULL AND p.archived_at IS NULL AND (p.category_id = ? OR c.parent_id = ?)',
          variables: [
            Variable.withString(categoryId),
            Variable.withString(categoryId),
          ],
          readsFrom: {_db.products, _db.categories},
        )
        .getSingle();
    return row.read<int>('n');
  }

  Future<String> saveOptionGroup(OptionGroupDraft d, {required Staff by}) {
    return _db.transaction(() async {
      final now = clock.now();
      final groupId = d.id ?? newId();
      if (d.id == null) {
        await _db.insertTracked(
          _db.optionGroups,
          OptionGroupsCompanion.insert(
            id: groupId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: d.name.trim(),
            minSelect: Value(d.minSelect),
            maxSelect: Value(d.maxSelect),
            allowRepeat: Value(d.allowRepeat),
          ),
        );
      } else {
        final row = await (_db.select(
          _db.optionGroups,
        )..where((g) => g.id.equals(groupId))).getSingle();
        await _db.updateTracked(
          _db.optionGroups,
          row.copyWith(
            name: d.name.trim(),
            minSelect: d.minSelect,
            maxSelect: Value(d.maxSelect),
            allowRepeat: d.allowRepeat,
            updatedAt: now,
          ),
        );
      }
      final existing =
          await (_db.select(_db.optionItems)..where(
                (o) =>
                    o.groupId.equals(groupId) &
                    o.deletedAt.isNull() &
                    o.active.equals(true),
              ))
              .get();
      final kept = <String>{};
      for (final (i, od) in d.options.indexed) {
        final current = od.id == null
            ? null
            : existing.where((e) => e.id == od.id).firstOrNull;
        final optionId = current?.id ?? newId();
        kept.add(optionId);
        if (current == null) {
          await _db.insertTracked(
            _db.optionItems,
            OptionItemsCompanion.insert(
              id: optionId,
              createdAt: now,
              updatedAt: now,
              deviceId: _device.deviceId,
              groupId: groupId,
              name: od.name.trim(),
              priceDelta: Value(od.priceDelta),
              isDefault: Value(od.isDefault),
              sortOrder: Value(i),
              variantId: Value(od.variantId),
            ),
          );
        } else {
          final updated = current.copyWith(
            name: od.name.trim(),
            priceDelta: od.priceDelta,
            isDefault: od.isDefault,
            sortOrder: i,
            variantId: Value(od.variantId),
          );
          if (updated != current)
            await _db.updateTracked(
              _db.optionItems,
              updated.copyWith(updatedAt: now),
            );
        }
        await _replaceRecipe(optionId: optionId, lines: od.recipe);
      }
      for (final old in existing.where((e) => !kept.contains(e.id))) {
        await _db.updateTracked(
          _db.optionItems,
          old.copyWith(active: false, updatedAt: now),
        );
      }
      await _audit.record(
        action: AuditAction.optionGroupSaved,
        actor: by,
        entity: 'option_groups',
        entityId: groupId,
        summary:
            '${d.id == null ? 'Added' : 'Changed'} options ${d.name.trim()}',
      );
      return groupId;
    });
  }

  Future<void> setOptionGroupActive(
    String id, {
    required bool active,
    required Staff by,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.optionGroups,
      )..where((g) => g.id.equals(id))).getSingle();
      await _db.updateTracked(
        _db.optionGroups,
        row.copyWith(active: active, updatedAt: clock.now()),
      );
      await _audit.record(
        action: AuditAction.optionGroupSaved,
        actor: by,
        entity: 'option_groups',
        entityId: id,
        summary: '${active ? 'Turned on' : 'Turned off'} options ${row.name}',
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Price changes

  /// A new price from the start of [effectiveOn] (a business-day start).
  Future<String> schedulePrice(
    String variantId,
    int newPrice,
    DateTime effectiveOn, {
    required Staff by,
  }) async {
    if (newPrice < 0)
      throw const CatalogueException('Enter a price from GH₵ 0.00.');
    if (!effectiveOn.isAfter(clock.now())) {
      throw const CatalogueException(
        'Pick a day after today. To change it now, edit the price.',
      );
    }
    return _db.transaction(() async {
      final v = await (_db.select(
        _db.productVariants,
      )..where((x) => x.id.equals(variantId))).getSingle();
      final p = await (_db.select(
        _db.products,
      )..where((x) => x.id.equals(v.productId))).getSingle();
      final now = clock.now();
      final id = newId();
      await _db.insertTracked(
        _db.priceChanges,
        PriceChangesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          variantId: variantId,
          newPrice: newPrice,
          effectiveOn: effectiveOn,
          createdByName: by.name,
        ),
      );
      await _audit.record(
        action: AuditAction.priceScheduled,
        actor: by,
        entity: 'product_variants',
        entityId: variantId,
        summary:
            '${p.name}${v.name == null ? '' : ', ${v.name}'}: ${formatMoney(newPrice)} from '
            '${effectiveOn.toIso8601String().substring(0, 10)}',
        details: {'before': v.price, 'after': newPrice},
      );
      return id;
    });
  }

  Future<void> cancelScheduledPrice(String id, {required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.priceChanges,
      )..where((c) => c.id.equals(id))).getSingle();
      if (row.appliedAt != null || row.cancelledAt != null) return;
      await _db.updateTracked(
        _db.priceChanges,
        row.copyWith(cancelledAt: Value(clock.now()), updatedAt: clock.now()),
      );
      final label = (await variantLabels([row.variantId]))[row.variantId];
      await _audit.record(
        action: AuditAction.priceScheduleCancelled,
        actor: by,
        entity: 'product_variants',
        entityId: row.variantId,
        summary:
            '${label ?? 'A product'}: ${formatMoney(row.newPrice)} from '
            '${row.effectiveOn.toIso8601String().substring(0, 10)} called off',
      );
    });
  }

  /// Waiting to apply, soonest first.
  Future<List<ScheduledPrice>> scheduledPrices({String? productId}) async {
    final rows =
        await (_db.select(_db.priceChanges).join([
                innerJoin(
                  _db.productVariants,
                  _db.productVariants.id.equalsExp(_db.priceChanges.variantId),
                ),
                innerJoin(
                  _db.products,
                  _db.products.id.equalsExp(_db.productVariants.productId),
                ),
              ])
              ..where(
                _db.priceChanges.appliedAt.isNull() &
                    _db.priceChanges.cancelledAt.isNull() &
                    _db.priceChanges.deletedAt.isNull() &
                    (productId == null
                        ? const Constant(true)
                        : _db.products.id.equals(productId)),
              )
              ..orderBy([
                OrderingTerm(expression: _db.priceChanges.effectiveOn),
              ]))
            .get();
    return [
      for (final r in rows)
        ScheduledPrice(
          id: r.readTable(_db.priceChanges).id,
          variantId: r.readTable(_db.productVariants).id,
          productName: r.readTable(_db.products).name,
          variantName: r.readTable(_db.productVariants).name,
          oldPrice: r.readTable(_db.productVariants).price,
          newPrice: r.readTable(_db.priceChanges).newPrice,
          effectiveOn: r.readTable(_db.priceChanges).effectiveOn,
          createdByName: r.readTable(_db.priceChanges).createdByName,
        ),
    ];
  }

  /// Puts scheduled prices that are due into effect. Returns how many.
  Future<int> applyDuePrices({DateTime? now}) {
    return _db.transaction(() async {
      final at = now ?? clock.now();
      var applied = 0;
      for (final s in await scheduledPrices()) {
        if (s.effectiveOn.isAfter(at)) continue;
        final v = await (_db.select(
          _db.productVariants,
        )..where((x) => x.id.equals(s.variantId))).getSingle();
        await _db.updateTracked(
          _db.productVariants,
          v.copyWith(price: s.newPrice, updatedAt: at),
        );
        final c = await (_db.select(
          _db.priceChanges,
        )..where((x) => x.id.equals(s.id))).getSingle();
        await _db.updateTracked(
          _db.priceChanges,
          c.copyWith(appliedAt: Value(at), updatedAt: at),
        );
        await _audit.record(
          action: AuditAction.priceChanged,
          actorName: s.createdByName,
          entity: 'product_variants',
          entityId: s.variantId,
          summary:
              '${s.label}: ${formatMoney(s.oldPrice)} to ${formatMoney(s.newPrice)} (scheduled)',
          details: {'before': s.oldPrice, 'after': s.newPrice},
        );
        applied++;
      }
      return applied;
    });
  }

  /// "Product, variant" for each id still on file (archived too).
  Future<Map<String, String>> variantLabels(Iterable<String> variantIds) async {
    final ids = variantIds.toSet();
    if (ids.isEmpty) return {};
    final rows = await (_db.select(_db.productVariants).join([
      innerJoin(
        _db.products,
        _db.products.id.equalsExp(_db.productVariants.productId),
      ),
    ])..where(_db.productVariants.id.isIn(ids))).get();
    return {
      for (final r in rows)
        r.readTable(_db.productVariants).id: [
          r.readTable(_db.products).name,
          ?r.readTable(_db.productVariants).name,
        ].join(', '),
    };
  }

  /// Product and category names by id (archived too), for settings that
  /// pick items.
  Future<Map<String, String>> itemNames(Iterable<String> ids) async {
    final wanted = ids.toSet();
    if (wanted.isEmpty) return {};
    final products = await (_db.select(
      _db.products,
    )..where((p) => p.id.isIn(wanted))).get();
    final categories = await (_db.select(
      _db.categories,
    )..where((c) => c.id.isIn(wanted))).get();
    return {
      for (final c in categories) c.id: c.name,
      for (final p in products) p.id: p.name,
    };
  }

  /// Many prices at once (one audit entry listing them all).
  Future<void> bulkSetPrices(
    Map<String, int> newPrices, {
    required String description,
    required Staff by,
  }) {
    return _db.transaction(() async {
      final now = clock.now();
      final labels = await variantLabels(newPrices.keys);
      final changes = <Map<String, Object?>>[];
      for (final MapEntry(key: variantId, value: price) in newPrices.entries) {
        final v = await (_db.select(
          _db.productVariants,
        )..where((x) => x.id.equals(variantId))).getSingle();
        if (v.price == price) continue;
        changes.add({
          'id': variantId,
          'name': labels[variantId],
          'before': v.price,
          'after': price,
        });
        await _db.updateTracked(
          _db.productVariants,
          v.copyWith(price: price, updatedAt: now),
        );
      }
      if (changes.isEmpty) return;
      await _audit.record(
        action: AuditAction.pricesBulkChanged,
        actor: by,
        entity: 'product_variants',
        summary: '${changes.length} prices: $description',
        details: {'items': changes},
      );
    });
  }

  /// Puts the Quick tab in this order; products left out come off it.
  Future<void> setQuickTab(List<String> productIds) {
    return _db.transaction(() async {
      final now = clock.now();
      final rows = await (_db.select(
        _db.products,
      )..where((p) => p.quickOrder.isNotNull() | p.id.isIn(productIds))).get();
      for (final row in rows) {
        final index = productIds.indexOf(row.id);
        final order = index == -1 ? null : index;
        if (order != row.quickOrder) {
          await _db.updateTracked(
            _db.products,
            row.copyWith(quickOrder: Value(order), updatedAt: now),
          );
        }
      }
    });
  }

  /// Runs [action] in one transaction (imports).
  Future<T> transaction<T>(Future<T> Function() action) =>
      _db.transaction(action);

  Future<String> saveTaxRate(TaxRateDraft d, {required Staff by}) {
    return _db.transaction(() async {
      final now = clock.now();
      final id = d.id ?? newId();
      Map<String, Object?>? before;
      if (d.id == null) {
        await _db.insertTracked(
          _db.taxRates,
          TaxRatesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: d.name.trim(),
            rateBp: d.rateBp,
            compound: Value(d.compound),
          ),
        );
      } else {
        final row = await (_db.select(
          _db.taxRates,
        )..where((t) => t.id.equals(id))).getSingle();
        before = {
          'name': row.name,
          'rateBp': row.rateBp,
          'compound': row.compound,
        };
        await _db.updateTracked(
          _db.taxRates,
          row.copyWith(
            name: d.name.trim(),
            rateBp: d.rateBp,
            compound: d.compound,
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.taxRateSaved,
        actor: by,
        entity: 'tax_rates',
        entityId: id,
        summary: '${d.id == null ? 'Added' : 'Changed'} tax ${d.name.trim()}',
        details: {
          'before': ?before,
          'after': {
            'name': d.name.trim(),
            'rateBp': d.rateBp,
            'compound': d.compound,
          },
        },
      );
      return id;
    });
  }

  Future<void> setTaxRateActive(
    String id, {
    required bool active,
    required Staff by,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.taxRates,
      )..where((t) => t.id.equals(id))).getSingle();
      await _db.updateTracked(
        _db.taxRates,
        row.copyWith(active: active, updatedAt: clock.now()),
      );
      await _audit.record(
        action: AuditAction.taxRateSaved,
        actor: by,
        entity: 'tax_rates',
        entityId: id,
        summary: '${active ? 'Turned on' : 'Turned off'} tax ${row.name}',
      );
    });
  }
}
