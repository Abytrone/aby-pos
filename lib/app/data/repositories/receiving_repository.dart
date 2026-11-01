import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/units.dart';
import '../../domain/inventory.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/purchasing.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'purchase_order_repository.dart';
import 'stock_repository.dart';
import 'supplier_repository.dart';

/// Deliveries ("goods received"): stock in, average cost updated, and what
/// is owed to the supplier, all in one transaction.
class ReceivingRepository {
  ReceivingRepository(this._db, this._device, this._audit, this._stock, this._suppliers, [this._orders]);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final StockRepository _stock;
  final SupplierRepository _suppliers;
  final PurchaseOrderRepository? _orders;

  Future<StockReceipt> receive(ReceiptDraft d, {required Staff by}) async {
    if (d.lines.isEmpty) throw const StockException('Add what was delivered.');
    final seen = <String>{};
    for (final l in d.lines) {
      if (l.quantity <= 0) throw const StockException('Each amount must be more than 0.');
      if (l.lineTotal < 0) throw const StockException('A cost cannot be negative.');
      if (!seen.add(l.stockItemId)) throw const StockException('An item is on the delivery twice.');
    }
    final total = d.total;
    if (d.paidNow < 0 || d.paidNow > total) {
      throw const StockException('Paid now must be between nothing and the delivery total.');
    }
    if (d.supplierId == null && d.paidNow != total) {
      throw const StockException('Without a supplier, the delivery must be paid in full.');
    }

    return _db.transaction(() async {
      final now = clock.now();
      final id = newId();
      final max = _db.stockReceipts.number.max();
      final numberQuery = _db.selectOnly(_db.stockReceipts)
        ..addColumns([max])
        ..where(_db.stockReceipts.deviceId.equals(_device.deviceId));
      final number = ((await numberQuery.map((r) => r.read(max)).getSingle()) ?? 0) + 1;

      await _db.insertTracked(
        _db.stockReceipts,
        StockReceiptsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          number: number,
          supplierId: Value(d.supplierId),
          invoiceRef: Value(d.invoiceRef?.trim().isEmpty ?? true ? null : d.invoiceRef!.trim()),
          total: total,
          paidNow: Value(d.paidNow),
          note: Value(d.note?.trim().isEmpty ?? true ? null : d.note!.trim()),
          receivedById: by.id,
          receivedByName: by.name,
          purchaseOrderId: Value(d.purchaseOrderId),
        ),
      );

      for (final l in d.lines) {
        final item = await (_db.select(_db.stockItems)..where((s) => s.id.equals(l.stockItemId))).getSingle();
        // Thousandths of a pesewa per base unit, rounded.
        final unitCost = (l.lineTotal * 1000 + l.quantity ~/ 2) ~/ l.quantity;
        await _db.insertTracked(
          _db.stockReceiptLines,
          StockReceiptLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            receiptId: id,
            stockItemId: l.stockItemId,
            quantity: l.quantity,
            unitCostMilli: unitCost,
            lineTotal: l.lineTotal,
          ),
        );
        final onHand = await _stock.onHand(l.stockItemId);
        await _stock.record(
          stockItemId: l.stockItemId,
          quantityChange: l.quantity,
          reason: StockReason.restock,
          unitCostMilli: unitCost,
          refId: id,
          byName: by.name,
          at: now,
        );
        if (l.batchNo != null || l.expiresOn != null) {
          await _stock.addBatch(
            stockItemId: l.stockItemId,
            quantity: l.quantity,
            receiptId: id,
            batchNo: l.batchNo,
            expiresOn: l.expiresOn,
          );
        }
        final average = Inventory.averageCost(
          onHand: onHand,
          oldCostMilli: item.costMilli,
          qty: l.quantity,
          newCostMilli: unitCost,
        );
        if (average != item.costMilli) {
          await _db.updateTracked(_db.stockItems, item.copyWith(costMilli: average, updatedAt: now));
        }
      }

      if (d.purchaseOrderId != null) {
        await _orders?.applyDelivery(d.purchaseOrderId!, {for (final l in d.lines) l.stockItemId: l.quantity});
      }

      String? supplierName;
      if (d.supplierId != null) {
        supplierName = (await _suppliers.find(d.supplierId!))?.name;
        await _suppliers.addEntry(
          supplierId: d.supplierId!,
          kind: SupplierEntryKind.purchase,
          amount: total,
          byName: by.name,
          receiptId: id,
          reference: d.invoiceRef,
        );
        if (d.paidNow > 0) {
          await _suppliers.addEntry(
            supplierId: d.supplierId!,
            kind: SupplierEntryKind.payment,
            amount: -d.paidNow,
            byName: by.name,
            method: d.paidWith ?? SupplierPaymentMethod.cash,
            receiptId: id,
            note: 'Paid on delivery',
          );
        }
      }

      final receipt = StockReceipt(
        id: id,
        number: number,
        at: now,
        total: total,
        paidNow: d.paidNow,
        receivedByName: by.name,
        lineCount: d.lines.length,
        supplierName: supplierName,
        invoiceRef: d.invoiceRef,
      );
      await _audit.record(
        action: AuditAction.stockReceived,
        actor: by,
        entity: 'stock_receipts',
        entityId: id,
        summary:
            '${receipt.displayNumber}: ${d.lines.length} items, ${formatMoney(total)}'
            '${supplierName == null ? '' : ' from $supplierName'}'
            '${d.paidNow < total ? ', ${formatMoney(total - d.paidNow)} owed' : ''}',
      );
      return receipt;
    });
  }

  /// Newest first.
  Future<List<StockReceipt>> list({int limit = 50, String? supplierId}) async {
    final query =
        _db.select(_db.stockReceipts).join([
            leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.stockReceipts.supplierId)),
          ])
          ..where(_db.stockReceipts.deletedAt.isNull())
          ..orderBy([
            OrderingTerm(expression: _db.stockReceipts.createdAt, mode: OrderingMode.desc),
            OrderingTerm(expression: _db.stockReceipts.id, mode: OrderingMode.desc),
          ])
          ..limit(limit);
    if (supplierId != null) query.where(_db.stockReceipts.supplierId.equals(supplierId));
    final rows = await query.get();
    final counts = <String, int>{};
    for (final l in await (_db.select(_db.stockReceiptLines)..where((l) => l.deletedAt.isNull())).get()) {
      counts[l.receiptId] = (counts[l.receiptId] ?? 0) + 1;
    }
    return [
      for (final r in rows)
        () {
          final rc = r.readTable(_db.stockReceipts);
          return StockReceipt(
            id: rc.id,
            number: rc.number,
            at: rc.createdAt,
            total: rc.total,
            paidNow: rc.paidNow,
            receivedByName: rc.receivedByName,
            lineCount: counts[rc.id] ?? 0,
            supplierName: r.readTableOrNull(_db.suppliers)?.name,
            invoiceRef: rc.invoiceRef,
          );
        }(),
    ];
  }

  /// One delivery with its lines, supplier phone and order number.
  Future<DeliveryDetail?> detail(String receiptId) async {
    final row = await (_db.select(_db.stockReceipts)..where((r) => r.id.equals(receiptId))).getSingleOrNull();
    if (row == null) return null;
    final supplier = row.supplierId == null
        ? null
        : await (_db.select(_db.suppliers)..where((s) => s.id.equals(row.supplierId!))).getSingleOrNull();
    final order = row.purchaseOrderId == null
        ? null
        : await (_db.select(_db.purchaseOrders)..where((o) => o.id.equals(row.purchaseOrderId!))).getSingleOrNull();
    final rows = await (_db.select(_db.stockReceiptLines).join([
      innerJoin(_db.stockItems, _db.stockItems.id.equalsExp(_db.stockReceiptLines.stockItemId)),
    ])
          ..where(_db.stockReceiptLines.receiptId.equals(receiptId) & _db.stockReceiptLines.deletedAt.isNull())
          ..orderBy([OrderingTerm(expression: _db.stockReceiptLines.createdAt), OrderingTerm(expression: _db.stockReceiptLines.id)]))
        .get();
    final lines = [
      for (final r in rows)
        () {
          final line = r.readTable(_db.stockReceiptLines);
          final item = r.readTable(_db.stockItems);
          return DeliveryLine(
            name: item.name,
            unit: item.unit,
            quantity: line.quantity,
            unitCostMilli: line.unitCostMilli,
            lineTotal: line.lineTotal,
          );
        }(),
    ];
    return DeliveryDetail(
      receipt: StockReceipt(
        id: row.id,
        number: row.number,
        at: row.createdAt,
        total: row.total,
        paidNow: row.paidNow,
        receivedByName: row.receivedByName,
        lineCount: lines.length,
        supplierName: supplier?.name,
        invoiceRef: row.invoiceRef,
      ),
      lines: lines,
      supplierPhone: supplier?.phone,
      note: row.note,
      orderNumber: order == null ? null : formatPurchaseOrderNumber(order.number),
    );
  }

  /// "12 pcs Wafer cones, GH₵ 9.60" lines for one delivery.
  Future<List<(String name, String quantity, int total)>> lines(String receiptId) async {
    final rows = await (_db.select(_db.stockReceiptLines).join([
      innerJoin(_db.stockItems, _db.stockItems.id.equalsExp(_db.stockReceiptLines.stockItemId)),
    ])..where(_db.stockReceiptLines.receiptId.equals(receiptId))).get();
    return [
      for (final r in rows)
        (
          r.readTable(_db.stockItems).name,
          formatQuantity(r.readTable(_db.stockReceiptLines).quantity, r.readTable(_db.stockItems).unit),
          r.readTable(_db.stockReceiptLines).lineTotal,
        ),
    ];
  }
}
