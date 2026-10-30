import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/staff.dart';
import '../database/app_database.dart';

/// Read-only figures for a staff profile, from sales, day closes and the
/// activity log.
class StaffStatsRepository {
  StaffStatsRepository(this._db);

  final AppDatabase _db;

  /// [todayStart] is the start of the current business day.
  Future<StaffStats> stats(String staffId, {required DateTime todayStart, DateTime? now}) async {
    final at = now ?? clock.now();
    final monthAgo = at.subtract(const Duration(days: 30));

    Future<(int, int)> sales(DateTime from) async {
      final row = await _db.customSelect(
        'SELECT COUNT(*) AS n, COALESCE(SUM(total), 0) AS t FROM sales '
        "WHERE cashier_id = ? AND status = 'completed' AND deleted_at IS NULL AND created_at >= ?",
        variables: [Variable.withString(staffId), Variable.withDateTime(from)],
        readsFrom: {_db.sales},
      ).getSingle();
      return (row.read<int>('n'), row.read<int>('t'));
    }

    Future<int> auditCount(AuditAction action, {String column = 'actor_id', DateTime? from}) async {
      final row = await _db.customSelect(
        'SELECT COUNT(*) AS n FROM audit_log WHERE $column = ? AND action = ?'
        '${from == null ? '' : ' AND at_ms >= ?'}',
        variables: [
          Variable.withString(staffId),
          Variable.withString(action.name),
          if (from != null) Variable.withInt(from.toUtc().millisecondsSinceEpoch),
        ],
        readsFrom: {_db.auditLog},
      ).getSingle();
      return row.read<int>('n');
    }

    final today = await sales(todayStart);
    final month = await sales(monthAgo);

    // A void the person did without approval, or asked for with one.
    final voidsAsked = await auditCount(AuditAction.saleVoided);
    final voidsApproved = await auditCount(AuditAction.saleVoided, column: 'approver_id');

    final closes = await _db.customSelect(
      'SELECT COUNT(*) AS n, COALESCE(SUM(counted_cash - expected_cash), 0) AS d '
      'FROM day_closes WHERE closed_by_id = ? AND deleted_at IS NULL',
      variables: [Variable.withString(staffId)],
      readsFrom: {_db.dayCloses},
    ).getSingle();

    final lastSignIn = await _db.customSelect(
      'SELECT MAX(at_ms) AS t FROM audit_log WHERE actor_id = ? AND action = ?',
      variables: [Variable.withString(staffId), Variable.withString(AuditAction.signedIn.name)],
      readsFrom: {_db.auditLog},
    ).getSingle();
    final lastMs = lastSignIn.read<int?>('t');

    return StaffStats(
      salesToday: today.$1,
      takingsToday: today.$2,
      sales30Days: month.$1,
      takings30Days: month.$2,
      voidsAsked: voidsAsked,
      voidsApproved: voidsApproved,
      closes: closes.read<int>('n'),
      closeDifference: closes.read<int>('d'),
      failedSignIns30Days: await auditCount(AuditAction.signInFailed, from: monthAgo) +
          await auditCount(AuditAction.lockedOut, from: monthAgo),
      lastSignIn: lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
    );
  }
}
