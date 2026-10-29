import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/purchasing.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'stock_repository.dart';

/// Orders to suppliers (INV-03): made from what is running low, shared as a
/// PDF, then received in one or more deliveries.
class PurchaseOrderRepository {
  PurchaseOrderRepository(this._db, this._device, this._audit, this._stock);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final StockRepository _stock;

  Future<List<PurchaseOrder>> _load(List<PurchaseOrderRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r.id];
    final lines = await (_db.select(_db.purchaseOrderLines)
          ..where((l) => l.orderId.isIn(ids) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final items = {for (final i in await _db.select(_db.stockItems).get()) i.id: i};
    final suppliers = {for (final s in await _db.select(_db.suppliers).get()) s.id: s};
    return [
      for (final r in rows)
        PurchaseOrder(
          id: r.id,
          number: r.number,
          supplierId: r.supplierId,
          supplierName: suppliers[r.supplierId]?.name ?? '?',
          supplierPhone: suppliers[r.supplierId]?.phone,
          status: r.status,
          at: r.createdAt,
          byName: r.byName,
          expectedOn: r.expectedOn,
          note: r.note,
          lines: [
            for (final l in lines.where((l) => l.orderId == r.id))
              PurchaseOrderLine(
                stockItemId: l.stockItemId,
                name: items[l.stockItemId]?.name ?? '?',
                unit: items[l.stockItemId]?.unit ?? StockUnit.piece,
                quantity: l.quantity,
                received: l.received,
                unitCostMilli: l.unitCostMilli,
              ),
          ],
        ),
    ];
  }

  /// Newest first; [open] only those still waiting for (some of) the goods.
  Future<List<PurchaseOrder>> list({bool open = false, String? supplierId}) async {
    final q = _db.select(_db.purchaseOrders)
      ..where((o) => o.deletedAt.isNull())
      ..orderBy([(o) => OrderingTerm.desc(o.number)]);
    if (open) q.where((o) => o.status.isInValues([PurchaseOrderStatus.open, PurchaseOrderStatus.partial]));
    if (supplierId != null) q.where((o) => o.supplierId.equals(supplierId));
    return _load(await q.get());
  }

  Future<PurchaseOrder?> find(String id) async =>
      (await _load(await (_db.select(_db.purchaseOrders)..where((o) => o.id.equals(id))).get())).firstOrNull;

  /// What to order from [supplierId]: its items at or below their low level,
  /// as (stock item ID, base units): the usual order, or enough to get back
  /// to twice the low level.
  Future<List<(String, int)>> suggestions(String supplierId) async => [
        for (final i in await _stock.items())
          if (i.supplierId == supplierId && i.isLow)
            (i.id, i.reorderQty ?? (i.reorderPoint! * 2 - i.onHand).clamp(1, 1 << 31)),
      ];

  Future<PurchaseOrder> create(PurchaseOrderDraft d, {required Staff by}) async {
    final lines = [for (final l in d.lines) if (l.$2 > 0) l];
    if (lines.isEmpty) throw const StockException('Add what to order.');
    if ({for (final l in lines) l.$1}.length != lines.length) throw const StockException('An item is on the order twice.');
    return _db.transaction(() async {
      final now = DateTime.now();
      final id = newId();
      final max = _db.purchaseOrders.number.max();
      final number = ((await (_db.selectOnly(_db.purchaseOrders)
                    ..addColumns([max])
                    ..where(_db.purchaseOrders.deviceId.equals(_device.deviceId)))
                  .map((r) => r.read(max))
                  .getSingle()) ??
              0) +
          1;
      await _db.insertTracked(
        _db.purchaseOrders,
        PurchaseOrdersCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          number: number,
          supplierId: d.supplierId,
          status: PurchaseOrderStatus.open,
          expectedOn: Value(d.expectedOn),
          note: Value(d.note?.trim().isEmpty ?? true ? null : d.note!.trim()),
          byName: by.name,
        ),
      );
      final items = {for (final i in await _db.select(_db.stockItems).get()) i.id: i};
      for (final (itemId, quantity) in lines) {
        await _db.insertTracked(
          _db.purchaseOrderLines,
          PurchaseOrderLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            orderId: id,
            stockItemId: itemId,
            quantity: quantity,
            unitCostMilli: Value(items[itemId]?.costMilli ?? 0),
          ),
        );
      }
      final order = (await find(id))!;
      await _audit.record(
        action: AuditAction.purchaseOrderSaved,
        actor: by,
        entity: 'purchase_orders',
        entityId: id,
        summary: '${order.displayNumber} to ${order.supplierName}: ${lines.length} items',
      );
      return order;
    });
  }

  Future<void> cancel(String id, {required Staff by}) => _db.transaction(() async {
        final row = await (_db.select(_db.purchaseOrders)..where((o) => o.id.equals(id))).getSingle();
        if (row.status == PurchaseOrderStatus.received) throw const StockException('This order has been received.');
        final now = DateTime.now();
        await _db.updateTracked(_db.purchaseOrders, row.copyWith(status: PurchaseOrderStatus.cancelled, updatedAt: now));
        await _audit.record(
          action: AuditAction.purchaseOrderSaved,
          actor: by,
          entity: 'purchase_orders',
          entityId: id,
          summary: 'Cancelled ${formatPurchaseOrderNumber(row.number)}',
        );
      });

  /// A delivery against the order: adds to what each line has received and
  /// moves the order to partly or fully received. Inside the delivery's
  /// transaction.
  Future<void> applyDelivery(String orderId, Map<String, int> received) async {
    final row = await (_db.select(_db.purchaseOrders)..where((o) => o.id.equals(orderId))).getSingleOrNull();
    if (row == null) return;
    final now = DateTime.now();
    final lines = await (_db.select(_db.purchaseOrderLines)..where((l) => l.orderId.equals(orderId) & l.deletedAt.isNull())).get();
    var complete = true;
    for (final l in lines) {
      final got = received[l.stockItemId] ?? 0;
      final total = l.received + got;
      if (got > 0) await _db.updateTracked(_db.purchaseOrderLines, l.copyWith(received: total, updatedAt: now));
      if (total < l.quantity) complete = false;
    }
    await _db.updateTracked(
      _db.purchaseOrders,
      row.copyWith(status: complete ? PurchaseOrderStatus.received : PurchaseOrderStatus.partial, updatedAt: now),
    );
  }
}
