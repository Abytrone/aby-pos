import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'cash_event_repository.dart';

class SafeException implements Exception {
  const SafeException(this.message);
  final String message;

  @override
  String toString() => 'SafeException: $message';
}

class SafeEntry {
  const SafeEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.amount,
    required this.byName,
    this.bank,
    this.reference,
    this.note,
  });

  final String id;
  final DateTime at;
  final SafeEntryKind kind;

  /// Pesewas: + into the safe, − out of it.
  final int amount;
  final String byName;
  final String? bank;
  final String? reference;
  final String? note;
}

/// The shop's safe: drops from drawers in, bank deposits out. The balance
/// is the sum of its ledger.
class SafeRepository {
  SafeRepository(this._db, this._device, this._audit, this._cashEvents);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final CashEventRepository _cashEvents;

  Future<int> balance() async {
    final sum = _db.safeEntries.amount.sum();
    final q = _db.selectOnly(_db.safeEntries)
      ..addColumns([sum])
      ..where(_db.safeEntries.deletedAt.isNull());
    return await q.map((r) => r.read(sum)).getSingle() ?? 0;
  }

  Future<List<SafeEntry>> entries({int limit = 100}) async {
    final rows = await (_db.select(_db.safeEntries)
          ..where((e) => e.deletedAt.isNull())
          ..orderBy([
            (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
            (e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc),
          ])
          ..limit(limit))
        .get();
    return [
      for (final r in rows)
        SafeEntry(
          id: r.id,
          at: r.createdAt,
          kind: r.kind,
          amount: r.amount,
          byName: r.byName,
          bank: r.bank,
          reference: r.reference,
          note: r.note,
        ),
    ];
  }

  Future<String> _add(SafeEntryKind kind, int amount, Staff by, {String? bank, String? reference, String? note}) async {
    final now = DateTime.now();
    final id = newId();
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    await _db.insertTracked(
      _db.safeEntries,
      SafeEntriesCompanion.insert(
        id: id,
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        kind: kind,
        amount: amount,
        bank: Value(clean(bank)),
        reference: Value(clean(reference)),
        note: Value(clean(note)),
        byName: by.name,
      ),
    );
    return id;
  }

  /// Cash out of the drawer into the safe (keeps the drawer low).
  Future<void> drop(int amount, {required Staff actor, Staff? approver, String? note}) async {
    if (amount <= 0) throw const SafeException('Enter the amount.');
    await _db.transaction(() async {
      await _cashEvents.record(
        kind: CashEventKind.safeDrop,
        amount: -amount,
        reason: 'Safe drop',
        note: note,
        actor: actor,
        approver: approver,
      );
      final id = await _add(SafeEntryKind.drop, amount, approver ?? actor, note: note);
      await _audit.record(
        action: AuditAction.safeDrop,
        actor: actor,
        approver: approver,
        entity: 'safe_entries',
        entityId: id,
        summary: 'Moved ${formatMoney(amount)} from the drawer to the safe',
      );
    });
  }

  /// Cash from the safe to the bank, with the slip's reference and photo.
  Future<void> deposit(int amount, {required String bank, String? reference, String? note, Uint8List? slip, required Staff by}) async {
    if (amount <= 0) throw const SafeException('Enter the amount.');
    if (bank.trim().isEmpty) throw const SafeException('Enter the bank.');
    await _db.transaction(() async {
      final have = await balance();
      if (amount > have) throw SafeException('The safe only holds ${formatMoney(have)}.');
      final id = await _add(SafeEntryKind.deposit, -amount, by, bank: bank, reference: reference, note: note);
      if (slip != null) await _cashEvents.savePhoto(id, slip);
      await _audit.record(
        action: AuditAction.bankDeposit,
        actor: by,
        entity: 'safe_entries',
        entityId: id,
        summary: 'Banked ${formatMoney(amount)} at ${bank.trim()}${reference == null || reference.trim().isEmpty ? '' : ' (${reference.trim()})'}',
      );
    });
  }
}
