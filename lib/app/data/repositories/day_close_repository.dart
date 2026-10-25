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
import 'cash_event_repository.dart';
import 'customer_repository.dart';

/// End-of-day cash-up for this device's drawer.
class DayCloseRepository {
  DayCloseRepository(this._db, this._device, this._audit, [this._cashEvents, this._customers]);

  final CustomerRepository? _customers;

  final CashEventRepository? _cashEvents;

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

    // Refunds since the last close (numbered per device, like sales).
    final afterRefund = last?.lastRefundNumber ?? 0;
    final refunds = await _db.customSelect(
      'SELECT COUNT(*) AS n, COALESCE(SUM(total), 0) AS total, COALESCE(MAX(number), 0) AS last_number '
      'FROM refunds WHERE device_id = ? AND number > ? AND deleted_at IS NULL',
      variables: [Variable.withString(_device.deviceId), Variable.withInt(afterRefund)],
      readsFrom: {_db.refunds},
    ).getSingle();
    final refundMethods = await _db.customSelect(
      'SELECT p.method AS method, SUM(p.amount) AS amount FROM refund_payments p '
      'JOIN refunds r ON r.id = p.refund_id '
      'WHERE r.device_id = ? AND r.number > ? AND r.deleted_at IS NULL AND p.deleted_at IS NULL '
      'GROUP BY p.method',
      variables: [Variable.withString(_device.deviceId), Variable.withInt(afterRefund)],
      readsFrom: {_db.refunds, _db.refundPayments},
    ).get();
    final rounding = await _db.customSelect(
      "SELECT COALESCE(SUM(rounding), 0) AS r FROM sales WHERE device_id = ? AND number > ? AND status = 'completed' "
      'AND deleted_at IS NULL',
      variables: [Variable.withString(_device.deviceId), Variable.withInt(after)],
      readsFrom: {_db.sales},
    ).getSingle();

    return OpenPeriod(
      from: last?.closedAt,
      salesCount: totals.read<int>('sales_count'),
      voidedCount: totals.read<int>('voided_count'),
      salesTotal: totals.read<int>('sales_total'),
      byMethod: byMethod,
      suggestedFloat: last?.openingFloat ?? 0,
      lastSaleNumber: totals.read<int>('last_number'),
      lastRefundNumber: refunds.read<int>('last_number'),
      refundsCount: refunds.read<int>('n'),
      refundsTotal: refunds.read<int>('total'),
      refundsByMethod: {
        for (final r in refundMethods)
          if (PaymentMethod.values.byName(r.read<String>('method')) != PaymentMethod.exchange)
            PaymentMethod.values.byName(r.read<String>('method')): r.read<int>('amount'),
      },
      rounding: rounding.read<int>('r'),
      noSales: await _cashEvents?.noSalesSince(last?.closedAt) ?? const {},
      customerMoney: await _customers?.moneyInSince(last?.closedAt) ?? const {},
    );
  }

  /// Closes the day: works out the takings again inside the transaction so
  /// a sale finished a moment ago is never missed, and records the count.
  Future<DayClose> closeDay({
    required int openingFloat,
    required int countedCash,
    required Staff closedBy,
    String? note,
  }) async {
    if (openingFloat < 0 || countedCash < 0) {
      throw ArgumentError('Amounts cannot be negative.');
    }
    return _db.transaction(() async {
      final period = await openPeriod();
      final last = await closedUpTo();
      final lastRefund = (await _lastClose())?.lastRefundNumber ?? 0;
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
          lastRefundNumber: Value(
            period.lastRefundNumber > lastRefund ? period.lastRefundNumber : lastRefund,
          ),
          refundsTotal: Value(period.refundsTotal),
          cashRefunds: Value(period.cashRefunds),
          otherTakings: Value(period.otherTakings),
          roundingTotal: Value(period.rounding),
          noSaleCount: Value(period.noSaleCount),
          customerCash: Value(period.customerCash),
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
        refundsTotal: r.refundsTotal,
        cashRefunds: r.cashRefunds,
        otherTakings: r.otherTakings,
        noSaleCount: r.noSaleCount,
        customerCash: r.customerCash,
      );
}
