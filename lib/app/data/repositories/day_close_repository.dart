import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/day_close.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// End-of-day cash-up for this device's drawer.
class DayCloseRepository {
  DayCloseRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<DayCloseRow?> _lastClose() => (_db.select(_db.dayCloses)
        ..where((d) => d.deviceId.equals(_device.deviceId) & d.deletedAt.isNull())
        ..orderBy([(d) => OrderingTerm(expression: d.lastSaleNumber, mode: OrderingMode.desc)])
        ..limit(1))
      .getSingleOrNull();

  /// The highest sale number already in a closed day, or 0.
  Future<int> closedUpTo() async => (await _lastClose())?.lastSaleNumber ?? 0;

  /// Takings since the last close.
  Future<OpenPeriod> openPeriod() async {
    final last = await _lastClose();
    final after = last?.lastSaleNumber ?? 0;

    final totals = await _db.customSelect(
      'SELECT '
      "COALESCE(SUM(CASE WHEN status = 'completed' THEN 1 END), 0) AS sales_count, "
      "COALESCE(SUM(CASE WHEN status = 'voided' THEN 1 END), 0) AS voided_count, "
      "COALESCE(SUM(CASE WHEN status = 'completed' THEN total END), 0) AS sales_total, "
      'COALESCE(MAX(number), 0) AS last_number '
      'FROM sales WHERE device_id = ? AND number > ? AND deleted_at IS NULL',
      variables: [Variable.withString(_device.deviceId), Variable.withInt(after)],
      readsFrom: {_db.sales},
    ).getSingle();

    final methods = await _db.customSelect(
      'SELECT p.method AS method, SUM(p.amount) AS amount '
      'FROM payments p JOIN sales s ON s.id = p.sale_id '
      "WHERE s.device_id = ? AND s.number > ? AND s.status = 'completed' "
      'AND s.deleted_at IS NULL AND p.deleted_at IS NULL '
      'GROUP BY p.method',
      variables: [Variable.withString(_device.deviceId), Variable.withInt(after)],
      readsFrom: {_db.sales, _db.payments},
    ).get();

    final byMethod = {for (final m in PaymentMethod.values) m: 0};
    for (final row in methods) {
      byMethod[PaymentMethod.values.byName(row.read<String>('method'))] =
          row.read<int>('amount');
    }

    return OpenPeriod(
      from: last?.closedAt,
      salesCount: totals.read<int>('sales_count'),
      voidedCount: totals.read<int>('voided_count'),
      salesTotal: totals.read<int>('sales_total'),
      byMethod: byMethod,
      suggestedFloat: last?.openingFloat ?? 0,
      lastSaleNumber: totals.read<int>('last_number'),
    );
  }

  /// Closes the day: works out the takings again inside the transaction so
  /// a sale finished a moment ago is never missed, and records the count.
  Future<DayClose> closeDay({
    required int openingFloat,
    required int countedCash,
    required Staff closedBy,
    String? note,
  }) {
    if (openingFloat < 0 || countedCash < 0) {
      throw ArgumentError('Amounts cannot be negative.');
    }
    return _db.transaction(() async {
      final period = await openPeriod();
      final last = await closedUpTo();
      final now = DateTime.now();
      final trimmedNote = note?.trim();
      final row = await _db.insertTracked(
        _db.dayCloses,
        DayClosesCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          periodStart: Value(period.from),
          closedAt: now,
          // An empty period keeps the previous boundary.
          lastSaleNumber: period.lastSaleNumber > last ? period.lastSaleNumber : last,
          closedById: closedBy.id,
          closedByName: closedBy.name,
          salesCount: period.salesCount,
          voidedCount: period.voidedCount,
          salesTotal: period.salesTotal,
          cashTakings: period.cashTakings,
          momoTakings: period.byMethod[PaymentMethod.momo] ?? 0,
          creditTakings: period.byMethod[PaymentMethod.credit] ?? 0,
          openingFloat: openingFloat,
          expectedCash: period.expectedCash(openingFloat),
          countedCash: countedCash,
          note: Value(trimmedNote == null || trimmedNote.isEmpty ? null : trimmedNote),
        ),
      );
      final close = _toModel(row);
      final diff = close.difference;
      await _audit.record(
        action: AuditAction.dayClosed,
        actor: closedBy,
        entity: 'day_closes',
        entityId: close.id,
        summary: 'Closed day: ${close.salesCount} sales, ${formatMoney(close.salesTotal)}, '
            '${diff == 0 ? 'balanced' : '${diff > 0 ? 'over' : 'short'} ${formatMoney(diff.abs())}'}',
      );
      return close;
    });
  }

  /// Most recent first.
  Future<List<DayClose>> history({int limit = 14}) async {
    final rows = await (_db.select(_db.dayCloses)
          ..where((d) => d.deviceId.equals(_device.deviceId) & d.deletedAt.isNull())
          ..orderBy([(d) => OrderingTerm(expression: d.lastSaleNumber, mode: OrderingMode.desc),
                     (d) => OrderingTerm(expression: d.closedAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
    return rows.map(_toModel).toList();
  }

  DayClose _toModel(DayCloseRow r) => DayClose(
        id: r.id,
        periodStart: r.periodStart,
        closedAt: r.closedAt,
        closedByName: r.closedByName,
        salesCount: r.salesCount,
        salesTotal: r.salesTotal,
        openingFloat: r.openingFloat,
        expectedCash: r.expectedCash,
        countedCash: r.countedCash,
        momoTakings: r.momoTakings,
        creditTakings: r.creditTakings,
        note: r.note,
      );
}
