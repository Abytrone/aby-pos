import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/units.dart';
import '../../domain/inventory.dart';
import '../../models/audit.dart';
import '../../models/drafts.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../models/stock.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../branch_scope.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class StockException implements Exception {
  const StockException(this.message);
  final String message;

  @override
  String toString() => 'StockException: $message';
}

/// Stock items and the stock ledger. Stock is never stored as a level:
/// every change is a movement, and stock on hand is their sum.
class StockRepository {
  StockRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  // ---------------------------------------------------------------------------
  // Items

  /// Stock items with what is on hand now, by name.
  Future<List<StockItem>> items({bool includeInactive = false}) async {
    final query = _db.select(_db.stockItems)
      ..where((s) => s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm(expression: s.name)]);
    if (!includeInactive) query.where((s) => s.active.equals(true));
    final levels = await onHandAll();
    return [for (final r in await query.get()) _toItem(r, levels[r.id] ?? 0)];
  }

  Future<StockItem?> item(String id) async {
    final row = await (_db.select(
      _db.stockItems,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toItem(row, await onHand(id));
  }

  /// Updates as stock moves (for lists that should stay current).
  Stream<void> watchChanges() => _db
      .tableUpdates(
        TableUpdateQuery.onAllTables([_db.stockItems, _db.stockMovements]),
      )
      .map((_) {});

  StockItem _toItem(StockItemRow r, int onHand) => StockItem(
    id: r.id,
    name: r.name,
    unit: r.unit,
    costMilli: r.costMilli,
    onHand: onHand,
    reorderPoint: r.reorderPoint,
    reorderQty: r.reorderQty,
    supplierId: r.supplierId,
    active: r.active,
    tracksExpiry: r.tracksExpiry,
    batchYield: r.batchYield,
  );

  Future<String> saveItem(
    StockItemDraft d, {
    required Staff by,
    bool createNew = false,
  }) async {
    final name = d.name.trim();
    if (name.isEmpty) throw const StockException('Enter a name.');
    if (d.costMilli < 0)
      throw const StockException('The cost cannot be negative.');
    return _db.transaction(() async {
      final now = clock.now();
      final creating = d.id == null || createNew;
      final id = d.id ?? newId();
      final named =
          await (_db.select(_db.stockItems)..where(
                (s) =>
                    s.deletedAt.isNull() &
                    s.name.lower().equals(name.toLowerCase()),
              ))
              .get();
      if (named.any((s) => creating || s.id != id)) {
        throw StockException('A stock item named "$name" already exists.');
      }
      if (creating) {
        await _db.insertTracked(
          _db.stockItems,
          StockItemsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: name,
            unit: d.unit,
            costMilli: Value(d.costMilli),
            reorderPoint: Value(d.reorderPoint),
            reorderQty: Value(d.reorderQty),
            supplierId: Value(d.supplierId),
            tracksExpiry: Value(d.tracksExpiry),
          ),
        );
      } else {
        final row = await (_db.select(
          _db.stockItems,
        )..where((s) => s.id.equals(id))).getSingle();
        if (row.unit != d.unit &&
            (await onHand(id) != 0 || await hasProductUsage(id))) {
          throw const StockException(
            'The unit cannot change while the item has stock or is used by a product or recipe.',
          );
        }
        await _db.updateTracked(
          _db.stockItems,
          row.copyWith(
            name: name,
            unit: d.unit,
            costMilli: d.costMilli,
            reorderPoint: Value(d.reorderPoint),
            reorderQty: Value(d.reorderQty),
            supplierId: Value(d.supplierId),
            tracksExpiry: d.tracksExpiry,
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.stockItemSaved,
        actor: by,
        entity: 'stock_items',
        entityId: id,
        summary: '${creating ? 'Added' : 'Changed'} stock item $name',
      );
      return id;
    });
  }

  Future<void> setItemActive(
    String id, {
    required bool active,
    required Staff by,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.stockItems,
      )..where((s) => s.id.equals(id))).getSingle();
      await _db.updateTracked(
        _db.stockItems,
        row.copyWith(active: active, updatedAt: clock.now()),
      );
      await _audit.record(
        action: AuditAction.stockItemSaved,
        actor: by,
        entity: 'stock_items',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} stock item ${row.name}',
      );
    });
  }

  /// Products and options that use this item directly or in a recipe.
  Future<List<String>> usedBy(String stockItemId) async {
    final rows = await _db
        .customSelect(
          'SELECT name FROM ('
          '  SELECT DISTINCT COALESCE(p.name, o.name) AS name FROM recipe_items r '
          '  LEFT JOIN product_variants v ON v.id = r.variant_id AND v.active = 1 '
          '  LEFT JOIN products p ON p.id = v.product_id AND p.archived_at IS NULL '
          '  LEFT JOIN option_items o ON o.id = r.option_id AND o.active = 1 '
          '  WHERE r.stock_item_id = ? AND r.deleted_at IS NULL AND (p.id IS NOT NULL OR o.id IS NOT NULL) '
          '  UNION '
          '  SELECT DISTINCT p.name AS name FROM product_variants v '
          '  JOIN products p ON p.id = v.product_id AND p.archived_at IS NULL '
          '  WHERE v.stock_item_id = ? AND v.active = 1 AND v.deleted_at IS NULL'
          ') WHERE name IS NOT NULL ORDER BY name',
          variables: [
            Variable.withString(stockItemId),
            Variable.withString(stockItemId),
          ],
          readsFrom: {
            _db.recipeItems,
            _db.productVariants,
            _db.products,
            _db.optionItems,
          },
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  /// Whether changing this item's unit would reinterpret an existing product
  /// link or recipe amount.
  Future<bool> hasProductUsage(String stockItemId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS ('
          '  SELECT 1 FROM product_variants v '
          '  WHERE v.stock_item_id = ? AND v.deleted_at IS NULL '
          '  UNION ALL '
          '  SELECT 1 FROM recipe_items r '
          '  WHERE r.stock_item_id = ? AND r.deleted_at IS NULL'
          ') AS used',
          variables: [
            Variable.withString(stockItemId),
            Variable.withString(stockItemId),
          ],
          readsFrom: {_db.productVariants, _db.recipeItems},
        )
        .getSingle();
    return row.read<int>('used') != 0;
  }

  // ---------------------------------------------------------------------------
  // Levels and movements

  /// This device's branch: stock is counted per branch (MDV-02).
  Future<BranchFilter> _here() => _db.branchFilterFor(_device.deviceId);

  /// Sum of a stock item's movements at this branch, in base units.
  Future<int> onHand(String stockItemId) async {
    final here = await _here();
    final sum = _db.stockMovements.quantityChange.sum();
    final query = _db.selectOnly(_db.stockMovements)
      ..addColumns([sum])
      ..where(
        _db.stockMovements.stockItemId.equals(stockItemId) &
            _db.stockMovements.deletedAt.isNull() &
            here.on(_db.stockMovements.deviceId),
      );
    return (await query.map((r) => r.read(sum)).getSingle()) ?? 0;
  }

  /// (stock item, quantity, cost per base unit now) for a variant or option.
  Future<List<(String, int, int)>> recipe({
    String? variantId,
    String? optionId,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT r.stock_item_id AS item, r.quantity AS qty, s.cost_milli AS cost '
          'FROM recipe_items r JOIN stock_items s ON s.id = r.stock_item_id '
          'WHERE r.deleted_at IS NULL AND ${variantId != null ? 'r.variant_id' : 'r.option_id'} = ?',
          variables: [Variable.withString(variantId ?? optionId!)],
          readsFrom: {_db.recipeItems, _db.stockItems},
        )
        .get();
    return [
      for (final r in rows)
        (r.read<String>('item'), r.read<int>('qty'), r.read<int>('cost')),
    ];
  }

  /// Direct stock link when present, otherwise the variant's recipe.
  Future<List<(String, int, int)>> variantUsage(String variantId) async {
    final link = await _db
        .customSelect(
          'SELECT v.stock_item_id AS item, v.stock_quantity AS qty, s.cost_milli AS cost '
          'FROM product_variants v JOIN stock_items s ON s.id = v.stock_item_id '
          'WHERE v.id = ? AND v.stock_item_id IS NOT NULL AND s.deleted_at IS NULL',
          variables: [Variable.withString(variantId)],
          readsFrom: {_db.productVariants, _db.stockItems},
        )
        .get();
    if (link.isNotEmpty) {
      return [
        for (final r in link)
          (r.read<String>('item'), r.read<int>('qty'), r.read<int>('cost')),
      ];
    }
    return recipe(variantId: variantId);
  }

  /// An option's recipe, or the linked product variant for a combo part.
  Future<List<(String, int, int)>> optionUsage(String optionId) async {
    final own = await recipe(optionId: optionId);
    if (own.isNotEmpty) return own;
    final option =
        await (_db.select(_db.optionItems)
              ..where((o) => o.id.equals(optionId) & o.deletedAt.isNull()))
            .getSingleOrNull();
    final variantId = option?.variantId;
    return variantId == null ? const [] : variantUsage(variantId);
  }

  /// On hand at this branch (or [scope]) for every stock item that has moved.
  Future<Map<String, int>> onHandAll({BranchFilter? scope}) async {
    final here = scope ?? await _here();
    final sum = _db.stockMovements.quantityChange.sum();
    final query = _db.selectOnly(_db.stockMovements)
      ..addColumns([_db.stockMovements.stockItemId, sum])
      ..where(
        _db.stockMovements.stockItemId.isNotNull() &
            _db.stockMovements.deletedAt.isNull() &
            here.on(_db.stockMovements.deviceId),
      )
      ..groupBy([_db.stockMovements.stockItemId]);
    return {
      for (final r in await query.get())
        r.read(_db.stockMovements.stockItemId)!: r.read(sum) ?? 0,
    };
  }

  /// Base units used by sales and waste since [since], per stock item (for
  /// reorder suggestions and days of stock left).
  Future<Map<String, int>> usedSince(DateTime since) async {
    final here = await _here();
    final rows = await _db
        .customSelect(
          'SELECT stock_item_id AS item, -SUM(quantity_change) AS used FROM stock_movements '
          "WHERE stock_item_id IS NOT NULL AND deleted_at IS NULL AND reason IN ('sale', 'waste') "
          'AND created_at >= ? AND ${here.sql('device_id')} GROUP BY stock_item_id',
          variables: [Variable.withDateTime(since), ...here.variables],
          readsFrom: {_db.stockMovements},
        )
        .get();
    return {for (final r in rows) r.read<String>('item'): r.read<int>('used')};
  }

  /// Newest first.
  Future<List<StockMovement>> movements(
    String stockItemId, {
    int limit = 100,
  }) async {
    final here = await _here();
    final rows =
        await (_db.select(_db.stockMovements)
              ..where(
                (m) =>
                    m.stockItemId.equals(stockItemId) &
                    m.deletedAt.isNull() &
                    here.on(m.deviceId),
              )
              ..orderBy([
                (m) => OrderingTerm(
                  expression: m.createdAt,
                  mode: OrderingMode.desc,
                ),
                (m) => OrderingTerm(expression: m.id, mode: OrderingMode.desc),
              ])
              ..limit(limit))
            .get();
    return [
      for (final r in rows)
        StockMovement(
          id: r.id,
          at: r.createdAt,
          quantityChange: r.quantityChange,
          reason: r.reason,
          subReason: r.subReason,
          note: r.note,
          byName: r.byName,
          saleId: r.saleId,
          refId: r.refId,
        ),
    ];
  }

  /// Appends a movement (and its outbox row). Runs inside the caller's
  /// transaction when there is one. Pass [stockItemId] for v5 movements;
  /// [productId] only for history written before stock items existed.
  Future<void> record({
    String? stockItemId,
    String? productId,
    String? variantId,
    required int quantityChange,
    required StockReason reason,
    String? subReason,
    int? unitCostMilli,
    String? saleId,
    String? refId,
    String? note,
    String? byName,
    DateTime? at,
  }) async {
    final now = at ?? clock.now();
    await _db.insertTracked(
      _db.stockMovements,
      StockMovementsCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        stockItemId: Value(stockItemId),
        productId: Value(productId),
        variantId: Value(variantId),
        quantityChange: quantityChange,
        reason: reason,
        subReason: Value(subReason),
        unitCostMilli: Value(unitCostMilli),
        saleId: Value(saleId),
        refId: Value(refId),
        note: Value(note),
        byName: Value(byName),
      ),
    );
  }

  /// Corrects stock by [change] base units (found more, or less, than the
  /// till thinks) with a note. Audited.
  Future<void> adjust(
    String stockItemId,
    int change, {
    required String note,
    required Staff by,
  }) async {
    if (change == 0) throw const StockException('Enter a change.');
    if (note.trim().isEmpty) throw const StockException('Say why.');
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.stockItems,
      )..where((s) => s.id.equals(stockItemId))).getSingle();
      await record(
        stockItemId: stockItemId,
        quantityChange: change,
        reason: StockReason.adjustment,
        unitCostMilli: row.costMilli,
        note: note.trim(),
        byName: by.name,
      );
      await _audit.record(
        action: AuditAction.stockAdjusted,
        actor: by,
        entity: 'stock_items',
        entityId: stockItemId,
        summary:
            '${row.name}: ${change > 0 ? '+' : ''}${formatQuantity(change, row.unit)} (${note.trim()})',
        details: {'change': change, 'value': costOf(change, row.costMilli)},
      );
    });
  }

  /// Stock lost: melted, expired, dropped. Audited with its value.
  Future<void> logWaste(
    String stockItemId,
    int quantity, {
    required WasteReason reason,
    String? note,
    required Staff by,
  }) async {
    if (quantity <= 0) throw const StockException('Enter how much was lost.');
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.stockItems,
      )..where((s) => s.id.equals(stockItemId))).getSingle();
      final value = costOf(quantity, row.costMilli);
      await record(
        stockItemId: stockItemId,
        quantityChange: -quantity,
        reason: StockReason.waste,
        subReason: reason.name,
        unitCostMilli: row.costMilli,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        byName: by.name,
      );
      await _audit.record(
        action: AuditAction.stockWasted,
        actor: by,
        entity: 'stock_items',
        entityId: stockItemId,
        summary:
            '${row.name}: ${formatQuantity(quantity, row.unit)} lost (${reason.name}), ${formatMoney(value)}',
        details: {'quantity': quantity, 'value': value, 'reason': reason.name},
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Batches and expiry (INV-07)

  /// Batches with what is left. What is in stock is the latest-expiring
  /// stock: sales and waste are taken from the batch that expires first.
  /// Batches with no date go last.
  Future<List<BatchLeft>> batches({String? stockItemId}) async {
    final here = await _here();
    final query = _db.select(_db.stockBatches)
      ..where((b) => b.deletedAt.isNull() & here.on(b.deviceId));
    if (stockItemId != null)
      query.where((b) => b.stockItemId.equals(stockItemId));
    final rows = await query.get();
    if (rows.isEmpty) return const [];
    final ids = {for (final r in rows) r.stockItemId};
    final items = {
      for (final i in await (_db.select(
        _db.stockItems,
      )..where((s) => s.id.isIn(ids))).get())
        i.id: i,
    };
    final levels = await onHandAll();
    final byItem = <String, List<StockBatchRow>>{};
    for (final r in rows) {
      byItem.putIfAbsent(r.stockItemId, () => []).add(r);
    }
    final out = <BatchLeft>[];
    for (final MapEntry(key: itemId, value: list) in byItem.entries) {
      final item = items[itemId];
      if (item == null) continue;
      // Latest expiry first: these are what is still on the shelf.
      list.sort((a, b) {
        final ea = a.expiresOn, eb = b.expiresOn;
        if (ea == null || eb == null)
          return ea == null ? (eb == null ? 0 : -1) : 1;
        final byDate = eb.compareTo(ea);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });
      var stock = levels[itemId] ?? 0;
      for (final b in list) {
        final left = stock <= 0 ? 0 : (stock < b.quantity ? stock : b.quantity);
        stock -= left;
        out.add(
          BatchLeft(
            id: b.id,
            stockItemId: itemId,
            itemName: item.name,
            unit: item.unit,
            quantity: b.quantity,
            left: left,
            receivedAt: b.createdAt,
            batchNo: b.batchNo,
            expiresOn: b.expiresOn,
          ),
        );
      }
    }
    out.sort((a, b) {
      final ea = a.expiresOn, eb = b.expiresOn;
      if (ea == null || eb == null)
        return ea == null ? (eb == null ? 0 : 1) : -1;
      return ea.compareTo(eb);
    });
    return out;
  }

  /// Batches still in stock that expire within [days] (or have expired).
  Future<List<BatchLeft>> expiring({int days = 30, DateTime? now}) async {
    final at = now ?? clock.now();
    return [
      for (final b in await batches())
        if (b.left > 0 && (b.daysLeft(at) ?? days + 1) <= days) b,
    ];
  }

  /// Records a batch received (inside the delivery's transaction).
  Future<void> addBatch({
    required String stockItemId,
    required int quantity,
    String? receiptId,
    String? batchNo,
    DateTime? expiresOn,
  }) {
    final now = clock.now();
    final no = batchNo?.trim();
    return _db.insertTracked(
      _db.stockBatches,
      StockBatchesCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        stockItemId: stockItemId,
        receiptId: Value(receiptId),
        batchNo: Value(no == null || no.isEmpty ? null : no),
        expiresOn: Value(expiresOn),
        quantity: quantity,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Production (INV-09)

  /// The batch recipe of an item made here, or null.
  Future<ProductionRecipe?> productionRecipe(String madeItemId) async {
    final item = await (_db.select(
      _db.stockItems,
    )..where((s) => s.id.equals(madeItemId))).getSingleOrNull();
    final batch = item?.batchYield;
    if (batch == null) return null;
    final rows =
        await (_db.select(_db.recipeItems)
              ..where(
                (r) => r.madeItemId.equals(madeItemId) & r.deletedAt.isNull(),
              )
              ..orderBy([
                (r) => OrderingTerm(expression: r.createdAt),
                (r) => OrderingTerm(expression: r.id),
              ]))
            .get();
    return ProductionRecipe(
      batchYield: batch,
      lines: [for (final r in rows) (r.stockItemId, r.quantity)],
    );
  }

  /// Makes [madeItemId] something made here: one batch of [lines] makes
  /// [batchYield] base units. A null [batchYield] stops it being made here.
  Future<void> saveProductionRecipe(
    String madeItemId, {
    required int? batchYield,
    required List<(String, int)> lines,
    required Staff by,
  }) async {
    if (batchYield != null && batchYield <= 0)
      throw const StockException('Enter how much one batch makes.');
    if (lines.any((l) => l.$1 == madeItemId))
      throw const StockException('An item cannot be made from itself.');
    if (lines.any((l) => l.$2 <= 0))
      throw const StockException('Each ingredient needs an amount.');
    return _db.transaction(() async {
      final now = clock.now();
      final item = await (_db.select(
        _db.stockItems,
      )..where((s) => s.id.equals(madeItemId))).getSingle();
      await _db.updateTracked(
        _db.stockItems,
        item.copyWith(batchYield: Value(batchYield), updatedAt: now),
      );
      final old =
          await (_db.select(_db.recipeItems)..where(
                (r) => r.madeItemId.equals(madeItemId) & r.deletedAt.isNull(),
              ))
              .get();
      for (final r in old) {
        await _db.softDeleteTracked(_db.recipeItems, r.id);
      }
      if (batchYield != null) {
        for (final (stockItemId, quantity) in lines) {
          await _db.insertTracked(
            _db.recipeItems,
            RecipeItemsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              deviceId: _device.deviceId,
              stockItemId: stockItemId,
              quantity: quantity,
              madeItemId: Value(madeItemId),
            ),
          );
        }
      }
      await _audit.record(
        action: AuditAction.stockItemSaved,
        actor: by,
        entity: 'stock_items',
        entityId: madeItemId,
        summary: batchYield == null
            ? '${item.name} is no longer made here'
            : '${item.name}: one batch makes ${formatQuantity(batchYield, item.unit)} from ${lines.length} ingredients',
      );
    });
  }

  /// A production run: [amount] base units of [madeItemId] made. The
  /// ingredients come off stock in proportion to the batch recipe, and the
  /// made item goes up at what they cost. Returns that cost (pesewas).
  Future<int> produce(
    String madeItemId,
    int amount, {
    String? note,
    required Staff by,
  }) async {
    if (amount <= 0) throw const StockException('Enter how much was made.');
    final recipe = await productionRecipe(madeItemId);
    if (recipe == null || recipe.lines.isEmpty)
      throw const StockException('Set what it is made from first.');
    return _db.transaction(() async {
      final now = clock.now();
      final made = await (_db.select(
        _db.stockItems,
      )..where((s) => s.id.equals(madeItemId))).getSingle();
      final runId = newId();
      var costMilliTotal = 0;
      for (final (itemId, perBatch) in recipe.lines) {
        final ingredient = await (_db.select(
          _db.stockItems,
        )..where((s) => s.id.equals(itemId))).getSingle();
        final take =
            (perBatch * amount + recipe.batchYield ~/ 2) ~/ recipe.batchYield;
        if (take <= 0) continue;
        costMilliTotal += take * ingredient.costMilli;
        await record(
          stockItemId: itemId,
          quantityChange: -take,
          reason: StockReason.production,
          unitCostMilli: ingredient.costMilli,
          refId: runId,
          note: 'For ${formatQuantity(amount, made.unit)} ${made.name}',
          byName: by.name,
          at: now,
        );
      }
      final unitCost = (costMilliTotal + amount ~/ 2) ~/ amount;
      final before = await onHand(madeItemId);
      await record(
        stockItemId: madeItemId,
        quantityChange: amount,
        reason: StockReason.production,
        unitCostMilli: unitCost,
        refId: runId,
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
        byName: by.name,
        at: now,
      );
      final average = Inventory.averageCost(
        onHand: before,
        oldCostMilli: made.costMilli,
        qty: amount,
        newCostMilli: unitCost,
      );
      if (average != made.costMilli) {
        await _db.updateTracked(
          _db.stockItems,
          made.copyWith(costMilli: average, updatedAt: now),
        );
      }
      final cost = (costMilliTotal + 500) ~/ 1000;
      await _audit.record(
        action: AuditAction.stockProduced,
        actor: by,
        entity: 'stock_items',
        entityId: madeItemId,
        summary:
            'Made ${formatQuantity(amount, made.unit)} ${made.name} (${formatMoney(cost)} of ingredients)',
        details: {'amount': amount, 'cost': cost},
      );
      return cost;
    });
  }
}
