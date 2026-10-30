import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/denominations.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class Shift {
  const Shift({
    required this.id,
    required this.openedAt,
    required this.openedByName,
    required this.openingFloat,
    this.floatCount = const CashCount(),
  });

  final String id;
  final DateTime openedAt;
  final String openedByName;

  /// Pesewas.
  final int openingFloat;
  final CashCount floatCount;
}

/// A drawer's shift on this device: opened with a counted float, closed by
/// close day (the Z report). One open shift at a time.
class ShiftRepository {
  ShiftRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<Shift?> current() async {
    final row = await (_db.select(_db.shifts)
          ..where((s) => s.deviceId.equals(_device.deviceId) & s.status.equalsValue(ShiftStatus.open) & s.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row == null
        ? null
        : Shift(
            id: row.id,
            openedAt: row.createdAt,
            openedByName: row.openedByName,
            openingFloat: row.openingFloat,
            floatCount: CashCount.fromJson(row.floatCount),
          );
  }

  /// Opens the drawer's shift with the float in it.
  Future<String> open({required int float, CashCount? count, required Staff by}) async {
    if (float < 0) throw ArgumentError('The float cannot be negative.');
    if (await current() != null) throw StateError('A shift is already open on this till.');
    return _db.transaction(() async {
      final now = clock.now();
      final id = newId();
      await _db.insertTracked(
        _db.shifts,
        ShiftsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          status: ShiftStatus.open,
          openedById: by.id,
          openedByName: by.name,
          openingFloat: float,
          floatCount: Value(count == null || count.isEmpty ? null : count.toJson()),
        ),
      );
      await _audit.record(
        action: AuditAction.shiftOpened,
        actor: by,
        entity: 'shifts',
        entityId: id,
        summary: 'Opened the shift with a float of ${formatMoney(float)}',
      );
      return id;
    });
  }

  /// Marks the shift closed by [closeId]. Inside close day's transaction.
  Future<void> close(String shiftId, String closeId) async {
    final row = await (_db.select(_db.shifts)..where((s) => s.id.equals(shiftId))).getSingle();
    await _db.updateTracked(
      _db.shifts,
      row.copyWith(status: ShiftStatus.closed, closeId: Value(closeId), updatedAt: clock.now()),
    );
  }
}
