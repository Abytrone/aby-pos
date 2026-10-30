import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/discount.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class DiscountException implements Exception {
  const DiscountException(this.message);
  final String message;

  @override
  String toString() => 'DiscountException: $message';
}

/// Saved discounts and the reasons lists the owner manages.
class DiscountRepository {
  DiscountRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<List<SavedDiscount>> discounts({bool includeInactive = false}) async {
    final query = _db.select(_db.discounts)
      ..where((d) => d.deletedAt.isNull())
      ..orderBy([(d) => OrderingTerm(expression: d.sortOrder), (d) => OrderingTerm(expression: d.name)]);
    if (!includeInactive) query.where((d) => d.active.equals(true));
    return [
      for (final r in await query.get())
        SavedDiscount(id: r.id, name: r.name, kind: r.kind, value: r.value, scope: r.scope, active: r.active),
    ];
  }

  Future<String> saveDiscount({
    String? id,
    required String name,
    required DiscountKind kind,
    required int value,
    required DiscountScope scope,
    required Staff by,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) throw const DiscountException('Enter a name.');
    if (kind == DiscountKind.percent && (value < 1 || value > 100)) {
      throw const DiscountException('A percentage is from 1 to 100.');
    }
    if (kind == DiscountKind.amount && value <= 0) throw const DiscountException('Enter an amount.');
    return _db.transaction(() async {
      final now = clock.now();
      final rowId = id ?? newId();
      if (id == null) {
        await _db.insertTracked(
          _db.discounts,
          DiscountsCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: clean,
            kind: kind,
            value: value,
            scope: scope,
          ),
        );
      } else {
        final row = await (_db.select(_db.discounts)..where((d) => d.id.equals(id))).getSingle();
        await _db.updateTracked(
          _db.discounts,
          row.copyWith(name: clean, kind: kind, value: value, scope: scope, updatedAt: now),
        );
      }
      await _audit.record(
        action: AuditAction.discountSaved,
        actor: by,
        entity: 'discounts',
        entityId: rowId,
        summary: '${id == null ? 'Added' : 'Changed'} discount $clean',
        details: {'kind': kind.name, 'value': value, 'scope': scope.name},
      );
      return rowId;
    });
  }

  Future<void> setDiscountActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.discounts)..where((d) => d.id.equals(id))).getSingle();
      await _db.updateTracked(_db.discounts, row.copyWith(active: active, updatedAt: clock.now()));
      await _audit.record(
        action: AuditAction.discountSaved,
        actor: by,
        entity: 'discounts',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} discount ${row.name}',
      );
    });
  }

  Future<List<Reason>> reasons(ReasonKind kind, {bool includeInactive = false}) async {
    final query = _db.select(_db.reasons)
      ..where((r) => r.kind.equalsValue(kind) & r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm(expression: r.sortOrder), (r) => OrderingTerm(expression: r.name)]);
    if (!includeInactive) query.where((r) => r.active.equals(true));
    return [for (final r in await query.get()) Reason(id: r.id, kind: r.kind, name: r.name, active: r.active)];
  }

  Future<String> saveReason({String? id, required ReasonKind kind, required String name, required Staff by}) async {
    final clean = name.trim();
    if (clean.isEmpty) throw const DiscountException('Enter the reason.');
    return _db.transaction(() async {
      final taken = await (_db.select(_db.reasons)
            ..where((r) =>
                r.kind.equalsValue(kind) & r.name.lower().equals(clean.toLowerCase()) & r.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();
      if (taken != null && taken.id != id) throw const DiscountException('That reason is already on the list.');
      final now = clock.now();
      final rowId = id ?? newId();
      if (id == null) {
        final max = _db.reasons.sortOrder.max();
        final q = _db.selectOnly(_db.reasons)
          ..addColumns([max])
          ..where(_db.reasons.kind.equalsValue(kind));
        final order = ((await q.map((r) => r.read(max)).getSingle()) ?? -1) + 1;
        await _db.insertTracked(
          _db.reasons,
          ReasonsCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            kind: kind,
            name: clean,
            sortOrder: Value(order),
          ),
        );
      } else {
        final row = await (_db.select(_db.reasons)..where((r) => r.id.equals(id))).getSingle();
        await _db.updateTracked(_db.reasons, row.copyWith(name: clean, updatedAt: now));
      }
      await _audit.record(
        action: AuditAction.reasonSaved,
        actor: by,
        entity: 'reasons',
        entityId: rowId,
        summary: '${id == null ? 'Added' : 'Changed'} reason "$clean" (${kind.name})',
      );
      return rowId;
    });
  }

  Future<void> setReasonActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.reasons)..where((r) => r.id.equals(id))).getSingle();
      await _db.updateTracked(_db.reasons, row.copyWith(active: active, updatedAt: clock.now()));
      await _audit.record(
        action: AuditAction.reasonSaved,
        actor: by,
        entity: 'reasons',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} reason "${row.name}" (${row.kind.name})',
      );
    });
  }
}
