import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class PayMethodException implements Exception {
  const PayMethodException(this.message);
  final String message;

  @override
  String toString() => 'PayMethodException: $message';
}

/// The shop's payment methods (Settings → Payments).
class PayMethodRepository {
  PayMethodRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<List<PayMethod>> list({bool includeInactive = false}) async {
    final query = _db.select(_db.payMethods)
      ..where((m) => m.deletedAt.isNull())
      ..orderBy([(m) => OrderingTerm(expression: m.sortOrder), (m) => OrderingTerm(expression: m.name)]);
    if (!includeInactive) query.where((m) => m.active.equals(true));
    return [for (final r in await query.get()) _toModel(r)];
  }

  PayMethod _toModel(PayMethodRow r) => PayMethod(
        id: r.id,
        name: r.name,
        kind: r.kind,
        builtIn: r.builtIn,
        active: r.active,
        needsReference: r.needsReference,
        shortReference: r.shortReference,
        merchantNumber: r.merchantNumber,
      );

  Future<String> save({
    String? id,
    required String name,
    required PaymentMethod kind,
    required bool needsReference,
    required bool shortReference,
    String? merchantNumber,
    required Staff by,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) throw const PayMethodException('Enter a name.');
    if (kind == PaymentMethod.exchange) throw const PayMethodException('Pick what kind of payment it is.');
    final number = merchantNumber?.trim().isEmpty ?? true ? null : merchantNumber!.trim();
    return _db.transaction(() async {
      final now = clock.now();
      final rowId = id ?? newId();
      if (id == null) {
        final max = _db.payMethods.sortOrder.max();
        final q = _db.selectOnly(_db.payMethods)..addColumns([max]);
        await _db.insertTracked(
          _db.payMethods,
          PayMethodsCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: clean,
            kind: kind,
            needsReference: Value(needsReference),
            shortReference: Value(shortReference),
            merchantNumber: Value(number),
            sortOrder: Value(((await q.map((r) => r.read(max)).getSingle()) ?? -1) + 1),
          ),
        );
      } else {
        final row = await (_db.select(_db.payMethods)..where((m) => m.id.equals(id))).getSingle();
        // Built-in cash stays cash: the drawer count depends on it.
        await _db.updateTracked(
          _db.payMethods,
          row.copyWith(
            name: clean,
            kind: row.builtIn == 'cash' ? PaymentMethod.cash : kind,
            needsReference: needsReference,
            shortReference: shortReference,
            merchantNumber: Value(number),
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.payMethodSaved,
        actor: by,
        entity: 'pay_methods',
        entityId: rowId,
        summary: '${id == null ? 'Added' : 'Changed'} payment method $clean',
      );
      return rowId;
    });
  }

  Future<void> setActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.payMethods)..where((m) => m.id.equals(id))).getSingle();
      if (!active && row.builtIn == 'cash') throw const PayMethodException('Cash is always on.');
      await _db.updateTracked(_db.payMethods, row.copyWith(active: active, updatedAt: clock.now()));
      await _audit.record(
        action: AuditAction.payMethodSaved,
        actor: by,
        entity: 'pay_methods',
        entityId: id,
        summary: '${active ? 'Switched on' : 'Switched off'} payment method ${row.name}',
      );
    });
  }
}
