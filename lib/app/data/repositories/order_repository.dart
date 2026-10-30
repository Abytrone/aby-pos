import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/order.dart';
import '../database/app_database.dart';

/// Orders with queue numbers moving through prep (SEL-11): New →
/// Preparing → Ready → Collected.
class OrderRepository {
  OrderRepository(this._db);

  final AppDatabase _db;

  static const _open = [OrderStatus.fresh, OrderStatus.preparing, OrderStatus.ready];

  SimpleSelectStatement<$SalesTable, SaleRow> _query() => _db.select(_db.sales)
    ..where((s) =>
        s.orderStatus.isInValues(_open) &
        s.status.equalsValue(SaleStatus.completed) &
        s.deletedAt.isNull() &
        // An order left open for more than a day is not shown.
        s.createdAt.isBiggerThanValue(clock.now().subtract(const Duration(days: 1))))
    ..orderBy([(s) => OrderingTerm(expression: s.createdAt), (s) => OrderingTerm(expression: s.id)]);

  Future<List<OpenOrder>> _withLines(List<SaleRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r.id];
    final lines = await (_db.select(_db.saleLines)
          ..where((l) => l.saleId.isIn(ids) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final customerIds = {for (final r in rows) ?r.customerId};
    final names = customerIds.isEmpty
        ? const <String, String>{}
        : {
            for (final c in await (_db.select(_db.customers)..where((c) => c.id.isIn(customerIds))).get()) c.id: c.name,
          };
    return [
      for (final r in rows)
        OpenOrder(
          saleId: r.id,
          number: r.orderNumber ?? 0,
          saleNumber: r.number,
          status: r.orderStatus!,
          at: r.createdAt,
          statusAt: r.orderStatusAt ?? r.createdAt,
          note: r.note,
          orderType: r.orderType,
          customerName: r.customerId == null ? null : names[r.customerId],
          lines: [
            for (final l in lines.where((l) => l.saleId == r.id))
              OrderLine(
                title: l.variantName == null || l.variantName!.isEmpty ? l.productName : '${l.productName}, ${l.variantName}',
                quantity: l.quantity,
                sellBy: l.sellBy,
                options: [for (final a in l.addons) a.name],
                note: l.note,
              ),
          ],
        ),
    ];
  }

  Future<List<OpenOrder>> open() async => _withLines(await _query().get());

  /// Open orders, again whenever a sale changes.
  Stream<List<OpenOrder>> watchOpen() => _query().watch().asyncMap(_withLines);

  /// Moves an order on (or back). Prep status is not money, so it is not in
  /// the activity log.
  Future<void> setStatus(String saleId, OrderStatus status) async {
    final row = await (_db.select(_db.sales)..where((s) => s.id.equals(saleId))).getSingleOrNull();
    if (row == null || row.orderNumber == null) return;
    final now = clock.now();
    await _db.updateTracked(_db.sales, row.copyWith(orderStatus: Value(status), orderStatusAt: Value(now), updatedAt: now));
  }
}
