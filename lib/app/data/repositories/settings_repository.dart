import 'dart:convert';

import 'package:clock/clock.dart';
import '../../core/settings.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// Reads and writes settings rows. Shop settings are shared by every device;
/// device settings belong to this device only.
class SettingsRepository {
  SettingsRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  /// Current values by key: every shop setting, plus this device's settings.
  Future<Map<String, Object?>> loadAll() async {
    final rows = await (_db.select(_db.settings)..where((s) => s.deletedAt.isNull())).get();
    final values = <String, Object?>{};
    for (final r in rows) {
      final mine = r.scope == SettingScope.shop ||
          r.id == settingRowId(r.key, SettingScope.device, _device.deviceId);
      if (mine) values[r.key] = jsonDecode(r.value);
    }
    return values;
  }

  /// Saves a value (outbox and audit entry in one transaction). Does nothing
  /// when the value is unchanged.
  Future<void> write<T extends Object>(Setting<T> setting, T value, {required Staff by}) {
    return _db.transaction(() async {
      final id = settingRowId(setting.key, setting.scope, _device.deviceId);
      final existing = await (_db.select(_db.settings)..where((s) => s.id.equals(id)))
          .getSingleOrNull();
      final encoded = jsonEncode(value);
      // Saving the value already in effect (stored, or the default) is no change.
      if ((existing?.value ?? jsonEncode(setting.defaultValue)) == encoded) return;
      final now = clock.now();
      if (existing == null) {
        await _db.insertTracked(
          _db.settings,
          SettingsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            key: setting.key,
            scope: setting.scope,
            value: encoded,
          ),
        );
      } else {
        await _db.updateTracked(_db.settings, existing.copyWith(value: encoded, updatedAt: now));
      }
      if (!setting.audited) return;
      final before = existing == null ? setting.defaultValue : jsonDecode(existing.value);
      await _audit.record(
        action: AuditAction.settingChanged,
        actor: by,
        entity: 'settings',
        entityId: setting.key,
        summary: 'Changed ${setting.key}',
        details: {'before': before, 'after': value},
      );
    });
  }
}
