import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/sale.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// One MoMo payment to tick off against the MoMo statement.
class MomoItem {
  const MomoItem({
    required this.source,
    required this.id,
    required this.at,
    required this.amount,
    required this.methodName,
    this.reference,
    this.label,
    this.matched,
  });

  /// 'sale' or 'customer'.
  final String source;
  final String id;
  final DateTime at;

  /// Pesewas.
  final int amount;
  final String methodName;
  final String? reference;

  /// "#00142" or the customer's name.
  final String? label;

  /// True ticked, false marked missing, null not checked yet.
  final bool? matched;
}

/// End-of-day MoMo checks: every MoMo payment with its reference, ticked
/// against the statement on the owner's phone; charges on their own line.
// TODO(sync): later the MoMo API (INT-02) or a statement CSV ticks these.
class MomoRepository {
  MomoRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  /// MoMo money in from [from] to [to]: sale payments and customer
  /// repayments / top-ups. Oldest first.
  Future<List<MomoItem>> items(DateTime from, DateTime to) async {
    final checks = {
      for (final c in await (_db.select(_db.momoChecks)..where((c) => c.deletedAt.isNull())).get()) '${c.source}:${c.itemId}': c.matched,
    };
    final sales = await _db.customSelect(
      'SELECT p.id AS id, p.created_at AS at, p.amount AS amount, p.momo_reference AS ref, '
      "COALESCE(p.method_name, 'MoMo') AS name, s.number AS number FROM payments p JOIN sales s ON s.id = p.sale_id "
      "WHERE p.method = 'momo' AND s.status = 'completed' AND p.deleted_at IS NULL AND p.created_at >= ? AND p.created_at < ?",
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {_db.payments, _db.sales},
    ).get();
    final customers = await _db.customSelect(
      "SELECT l.id AS id, l.created_at AS at, ABS(l.amount) AS amount, l.reference AS ref, COALESCE(l.method_name, 'MoMo') AS name, "
      "c.name AS who FROM customer_ledger l JOIN customers c ON c.id = l.customer_id WHERE l.method = 'momo' "
      "AND l.kind IN ('repayment', 'topUp') AND l.deleted_at IS NULL AND l.created_at >= ? AND l.created_at < ?",
      variables: [Variable.withDateTime(from), Variable.withDateTime(to)],
      readsFrom: {_db.customerLedger, _db.customers},
    ).get();
    DateTime at(QueryRow r) => DateTime.fromMillisecondsSinceEpoch(r.read<int>('at') * 1000);
    final items = [
      for (final r in sales)
        MomoItem(
          source: 'sale',
          id: r.read<String>('id'),
          at: at(r),
          amount: r.read<int>('amount'),
          methodName: r.read<String>('name'),
          reference: r.read<String?>('ref'),
          label: formatSaleNumber(r.read<int>('number')),
          matched: checks['sale:${r.read<String>('id')}'],
        ),
      for (final r in customers)
        MomoItem(
          source: 'customer',
          id: r.read<String>('id'),
          at: at(r),
          amount: r.read<int>('amount'),
          methodName: r.read<String>('name'),
          reference: r.read<String?>('ref'),
          label: r.read<String>('who'),
          matched: checks['customer:${r.read<String>('id')}'],
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));
    return items;
  }

  /// Ticks ([matched] true) or flags ([matched] false) one payment; null
  /// clears the check.
  Future<void> check(MomoItem item, bool? matched, {required Staff by}) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.momoChecks)
            ..where((c) => c.source.equals(item.source) & c.itemId.equals(item.id)))
          .getSingleOrNull();
      final now = clock.now();
      if (existing == null) {
        if (matched == null) return;
        await _db.insertTracked(
          _db.momoChecks,
          MomoChecksCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            source: item.source,
            itemId: item.id,
            matched: matched,
            byName: by.name,
          ),
        );
      } else {
        await _db.updateTracked(
          _db.momoChecks,
          existing.copyWith(
            matched: matched ?? existing.matched,
            byName: by.name,
            deletedAt: Value(matched == null ? now : null),
            updatedAt: now,
          ),
        );
      }
      if (matched == false) {
        await _audit.record(
          action: AuditAction.momoChecked,
          actor: by,
          entity: item.source == 'sale' ? 'payments' : 'customer_ledger',
          entityId: item.id,
          summary: 'MoMo ${formatMoney(item.amount)} (${item.reference ?? 'no reference'}, ${item.label ?? ''}) '
              'is not on the MoMo statement',
        );
      }
    });
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Charges and e-levy taken off for [day] (pesewas).
  Future<int> charges(DateTime day) async {
    final row = await (_db.select(_db.momoCharges)
          ..where((c) => c.day.equals(_day(day)) & c.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row?.amount ?? 0;
  }

  Future<void> setCharges(DateTime day, int amount, {String? note, required Staff by}) {
    return _db.transaction(() async {
      final d = _day(day);
      final row = await (_db.select(_db.momoCharges)..where((c) => c.day.equals(d) & c.deletedAt.isNull())).getSingleOrNull();
      final now = clock.now();
      if (row == null) {
        await _db.insertTracked(
          _db.momoCharges,
          MomoChargesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            day: d,
            amount: amount,
            note: Value(note),
            byName: by.name,
          ),
        );
      } else {
        if (row.amount == amount && row.note == note) return;
        await _db.updateTracked(_db.momoCharges, row.copyWith(amount: amount, note: Value(note), byName: by.name, updatedAt: now));
      }
      await _audit.record(
        action: AuditAction.momoChargesSet,
        actor: by,
        entity: 'momo_charges',
        summary:
            'MoMo charges for ${d.toIso8601String().substring(0, 10)}: '
            '${row == null ? formatMoney(amount) : '${formatMoney(row.amount)} to ${formatMoney(amount)}'}',
        details: {'before': ?row?.amount, 'after': amount},
      );
    });
  }
}
