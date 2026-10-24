import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// Opening the drawer without a sale. Recorded with a reason, and counted
/// per cashier at close day.
class CashEventRepository {
  CashEventRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<void> noSale({required String reason, required Staff actor, Staff? approver}) async {
    final clean = reason.trim();
    if (clean.isEmpty) throw ArgumentError('A no-sale needs a reason.');
    await _db.transaction(() async {
      final now = DateTime.now();
      final id = newId();
      await _db.insertTracked(
        _db.cashEvents,
        CashEventsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          kind: CashEventKind.noSale,
          reason: clean,
          staffId: actor.id,
          staffName: actor.name,
          approverName: Value(approver?.name),
        ),
      );
      // TODO(print): kick the cash drawer open here.
      await _audit.record(
        action: AuditAction.noSale,
        actor: actor,
        approver: approver,
        entity: 'cash_events',
        entityId: id,
        summary: 'Opened the drawer without a sale: $clean',
      );
    });
  }

  /// No-sales on this device since [from] (all time when null), per person.
  Future<Map<String, int>> noSalesSince(DateTime? from) async {
    final n = _db.cashEvents.id.count();
    final q = _db.selectOnly(_db.cashEvents)
      ..addColumns([_db.cashEvents.staffName, n])
      ..where(_db.cashEvents.deviceId.equals(_device.deviceId) &
          _db.cashEvents.kind.equalsValue(CashEventKind.noSale) &
          _db.cashEvents.deletedAt.isNull() &
          (from == null ? const Constant(true) : _db.cashEvents.createdAt.isBiggerThanValue(from)))
      ..groupBy([_db.cashEvents.staffName]);
    return {for (final r in await q.get()) r.read(_db.cashEvents.staffName)!: r.read(n) ?? 0};
  }
}
