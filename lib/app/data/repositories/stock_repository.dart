import 'package:drift/drift.dart';

import '../../core/units.dart';
import '../../models/audit.dart';
import '../../models/drafts.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../models/stock.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
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
    final row = await (_db.select(_db.stockItems)..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toItem(row, await onHand(id));
  }

  /// Updates as stock moves (for lists that should stay current).
  Stream<void> watchChanges() =>
      _db.tableUpdates(TableUpdateQuery.onAllTables([_db.stockItems, _db.stockMovements])).map((_) {});

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
  );

  Future<String> saveItem(StockItemDraft d, {required Staff by}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw const StockException('Enter a name.');
    if (d.costMilli < 0) throw const StockException('The cost cannot be negative.');
    return _db.transaction(() async {
      final now = DateTime.now();
      final id = d.id ?? newId();
      if (d.id == null) {
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
          ),
        );
      } else {
        final row = await (_db.select(_db.stockItems)..where((s) => s.id.equals(id))).getSingle();
        if (row.unit != d.unit && await onHand(id) != 0) {
          throw const StockException('The unit can only change while nothing is in stock.');
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
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.stockItemSaved,
        actor: by,
        entity: 'stock_items',
        entityId: id,
        summary: '${d.id == null ? 'Added' : 'Changed'} stock item $name',
      );
      return id;
    });
  }

  Future<void> setItemActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.stockItems)..where((s) => s.id.equals(id))).getSingle();
      await _db.updateTracked(_db.stockItems, row.copyWith(active: active, updatedAt: DateTime.now()));
      await _audit.record(
        action: AuditAction.stockItemSaved,
        actor: by,
        entity: 'stock_items',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} stock item ${row.name}',
      );
    });
  }

  /// Products whose recipes use the item (names), so the owner knows what a
  /// change affects.
  Future<List<String>> usedBy(String stockItemId) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT COALESCE(p.name, o.name) AS name FROM recipe_items r '
          'LEFT JOIN product_variants v ON v.id = r.variant_id AND v.active = 1 '
          'LEFT JOIN products p ON p.id = v.product_id AND p.archived_at IS NULL '
          'LEFT JOIN option_items o ON o.id = r.option_id AND o.active = 1 '
          'WHERE r.stock_item_id = ? AND r.deleted_at IS NULL AND (p.id IS NOT NULL OR o.id IS NOT NULL) '
          'ORDER BY name',
          variables: [Variable.withString(stockItemId)],
          readsFrom: {_db.recipeItems, _db.productVariants, _db.products, _db.optionItems},
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toList();
  }

  // ---------------------------------------------------------------------------
  // Levels and movements

  /// Sum of a stock item's movements, in base units.
  Future<int> onHand(String stockItemId) async {
    final sum = _db.stockMovements.quantityChange.sum();
    final query = _db.selectOnly(_db.stockMovements)
      ..addColumns([sum])
      ..where(_db.stockMovements.stockItemId.equals(stockItemId) & _db.stockMovements.deletedAt.isNull());
    return (await query.map((r) => r.read(sum)).getSingle()) ?? 0;
  }

  /// (stock item, quantity, cost per base unit now) for a variant or option.
  Future<List<(String, int, int)>> recipe({String? variantId, String? optionId}) async {
    final rows = await _db.customSelect(
      'SELECT r.stock_item_id AS item, r.quantity AS qty, s.cost_milli AS cost '
      'FROM recipe_items r JOIN stock_items s ON s.id = r.stock_item_id '
      'WHERE r.deleted_at IS NULL AND ${variantId != null ? 'r.variant_id' : 'r.option_id'} = ?',
      variables: [Variable.withString(variantId ?? optionId!)],
      readsFrom: {_db.recipeItems, _db.stockItems},
    ).get();
    return [for (final r in rows) (r.read<String>('item'), r.read<int>('qty'), r.read<int>('cost'))];
  }

  /// On hand for every stock item that has moved.
  Future<Map<String, int>> onHandAll() async {
    final sum = _db.stockMovements.quantityChange.sum();
    final query = _db.selectOnly(_db.stockMovements)
      ..addColumns([_db.stockMovements.stockItemId, sum])
      ..where(_db.stockMovements.stockItemId.isNotNull() & _db.stockMovements.deletedAt.isNull())
      ..groupBy([_db.stockMovements.stockItemId]);
    return {for (final r in await query.get()) r.read(_db.stockMovements.stockItemId)!: r.read(sum) ?? 0};
  }

  /// Base units used by sales and waste since [since], per stock item (for
  /// reorder suggestions and days of stock left).
  Future<Map<String, int>> usedSince(DateTime since) async {
    final rows = await _db
        .customSelect(
          'SELECT stock_item_id AS item, -SUM(quantity_change) AS used FROM stock_movements '
          "WHERE stock_item_id IS NOT NULL AND deleted_at IS NULL AND reason IN ('sale', 'waste') "
          'AND created_at >= ? GROUP BY stock_item_id',
          variables: [Variable.withDateTime(since)],
          readsFrom: {_db.stockMovements},
        )
        .get();
    return {for (final r in rows) r.read<String>('item'): r.read<int>('used')};
  }

  /// Newest first.
  Future<List<StockMovement>> movements(String stockItemId, {int limit = 100}) async {
    final rows =
        await (_db.select(_db.stockMovements)
              ..where((m) => m.stockItemId.equals(stockItemId) & m.deletedAt.isNull())
              ..orderBy([
                (m) => OrderingTerm(expression: m.createdAt, mode: OrderingMode.desc),
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
    final now = at ?? DateTime.now();
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
  Future<void> adjust(String stockItemId, int change, {required String note, required Staff by}) async {
    if (change == 0) throw const StockException('Enter a change.');
    if (note.trim().isEmpty) throw const StockException('Say why.');
    return _db.transaction(() async {
      final row = await (_db.select(_db.stockItems)..where((s) => s.id.equals(stockItemId))).getSingle();
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
        summary: '${row.name}: ${change > 0 ? '+' : ''}${formatQuantity(change, row.unit)} (${note.trim()})',
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
      final row = await (_db.select(_db.stockItems)..where((s) => s.id.equals(stockItemId))).getSingle();
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
        summary: '${row.name}: ${formatQuantity(quantity, row.unit)} lost (${reason.name}), ${formatMoney(value)}',
        details: {'quantity': quantity, 'value': value, 'reason': reason.name},
      );
    });
  }
}
