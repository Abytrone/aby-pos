import '../data/repositories/audit_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../models/audit.dart';
import '../models/drafts.dart';
import '../models/purchasing.dart';
import '../models/staff.dart';
import '../models/stock.dart';

/// What a delivery can change on a stock item.
enum DeliveryChange {
  /// The cost becomes this delivery's price (instead of the running
  /// average).
  cost,

  /// The item comes from this delivery's supplier.
  supplier,

  /// The usual order becomes what this delivery brought.
  orderQty,
}

/// One stock item on a delivery, and what the delivery would change on it.
class DeliveryUpdate {
  const DeliveryUpdate({required this.item, required this.line, required this.changes, this.supplierId});

  final StockItem item;
  final DeliveryLine line;

  /// Only what differs from the item now.
  final Set<DeliveryChange> changes;

  /// The delivery's supplier.
  final String? supplierId;
}

/// Updating stock items from a delivery record: its price as their cost,
/// its supplier as theirs, its quantity as their usual order.
abstract final class DeliveryUpdates {
  /// What [d] would change on each of its stock items ([items] by ID).
  /// Items that already match, or are gone, are left out.
  static List<DeliveryUpdate> plan(DeliveryDetail d, Map<String, StockItem> items) => [
        for (final line in d.lines)
          if (items[line.stockItemId] case final item?)
            () {
              final changes = {
                if (line.unitCostMilli != item.costMilli) DeliveryChange.cost,
                if (d.supplierId != null && d.supplierId != item.supplierId) DeliveryChange.supplier,
                if (line.quantity != item.reorderQty) DeliveryChange.orderQty,
              };
              return DeliveryUpdate(item: item, line: line, changes: changes, supplierId: d.supplierId);
            }(),
      ].where((u) => u.changes.isNotEmpty).toList();

  /// Saves the [chosen] changes for each update, and marks [delivery] as
  /// used so it is not offered again. Returns how many items changed. Each
  /// save is audited as a stock item change.
  static Future<int> apply(
    StockRepository stock,
    AuditRepository audit,
    StockReceipt delivery,
    List<(DeliveryUpdate, Set<DeliveryChange>)> chosen, {
    required Staff by,
  }) async {
    var changed = 0;
    for (final (u, picked) in chosen) {
      if (picked.isEmpty) continue;
      final i = u.item;
      await stock.saveItem(
        StockItemDraft(
          id: i.id,
          name: i.name,
          unit: i.unit,
          costMilli: picked.contains(DeliveryChange.cost) ? u.line.unitCostMilli : i.costMilli,
          reorderPoint: i.reorderPoint,
          reorderQty: picked.contains(DeliveryChange.orderQty) ? u.line.quantity : i.reorderQty,
          supplierId: picked.contains(DeliveryChange.supplier) ? u.supplierId : i.supplierId,
          tracksExpiry: i.tracksExpiry,
        ),
        by: by,
      );
      changed++;
    }
    if (changed > 0) {
      await audit.record(
        action: AuditAction.stockUpdatedFromDelivery,
        actor: by,
        entity: 'stock_receipts',
        entityId: delivery.id,
        summary: '${delivery.displayNumber}: $changed stock items updated from it',
      );
    }
    return changed;
  }

  /// When stock items were last updated from [delivery]; null if never.
  static Future<DateTime?> updatedAt(AuditRepository audit, StockReceipt delivery) async =>
      (await audit.list(entityId: delivery.id, actions: {AuditAction.stockUpdatedFromDelivery}, limit: 1)).firstOrNull?.at;
}
