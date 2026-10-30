import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/branch.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../branch_scope.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class BranchException implements Exception {
  const BranchException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Branches and which devices are in them (MDV-02).
class BranchRepository {
  BranchRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Branch _branch(BranchRow r) => Branch(id: r.id, name: r.name, address: r.address, phone: r.phone, active: r.active);

  /// Main branch first, then by name.
  Future<List<Branch>> list({bool includeInactive = false}) async {
    final rows = await (_db.select(_db.branches)..where((b) => b.deletedAt.isNull())).get();
    final out = [for (final r in rows) if (includeInactive || r.active) _branch(r)];
    out.sort((a, b) => a.id == mainBranchId ? -1 : b.id == mainBranchId ? 1 : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  Stream<void> watch() =>
      _db.tableUpdates(TableUpdateQuery.onAllTables([_db.branches, _db.deviceBranches])).map((_) {});

  /// This device's branch.
  Future<String> currentId() => _db.branchOf(_device.deviceId);

  Future<Branch> current() async {
    final id = await currentId();
    final row = await (_db.select(_db.branches)..where((b) => b.id.equals(id))).getSingleOrNull();
    return row == null ? Branch(id: id, name: id) : _branch(row);
  }

  Future<String> save(BranchDraft d, {required Staff by}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw const BranchException('Enter a name.');
    final others = await list(includeInactive: true);
    if (others.any((b) => b.id != d.id && b.name.toLowerCase() == name.toLowerCase())) {
      throw const BranchException('There is already a branch with that name.');
    }
    String? clean(String? s) => s == null || s.trim().isEmpty ? null : s.trim();
    final now = clock.now();
    return _db.transaction(() async {
      final id = d.id ?? newId();
      final existing = d.id == null ? null : await (_db.select(_db.branches)..where((b) => b.id.equals(id))).getSingleOrNull();
      if (existing == null) {
        await _db.insertTracked(
          _db.branches,
          BranchesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: name,
            address: Value(clean(d.address)),
            phone: Value(clean(d.phone)),
          ),
        );
      } else {
        await _db.updateTracked(
          _db.branches,
          existing.copyWith(name: name, address: Value(clean(d.address)), phone: Value(clean(d.phone)), updatedAt: now),
        );
      }
      await _audit.record(
        action: AuditAction.branchSaved,
        actor: by,
        entity: 'branches',
        entityId: id,
        summary: existing == null ? 'Added branch $name' : 'Changed branch $name',
      );
      return id;
    });
  }

  /// Closes a branch (its history stays). The main branch, and a branch
  /// with devices still in it, cannot be closed.
  Future<void> setActive(String id, {required bool active, required Staff by}) async {
    if (id == mainBranchId && !active) throw const BranchException('The main branch cannot be closed.');
    final devices = await (_db.select(_db.deviceBranches)..where((d) => d.branchId.equals(id) & d.deletedAt.isNull())).get();
    if (!active && devices.isNotEmpty) throw const BranchException('Move its devices to another branch first.');
    await _db.transaction(() async {
      final row = await (_db.select(_db.branches)..where((b) => b.id.equals(id))).getSingle();
      await _db.updateTracked(_db.branches, row.copyWith(active: active, updatedAt: clock.now()));
      await _audit.record(
        action: AuditAction.branchSaved,
        actor: by,
        entity: 'branches',
        entityId: id,
        summary: active ? 'Reopened branch ${row.name}' : 'Closed branch ${row.name}',
      );
    });
  }

  /// Puts a device in a branch. Its sales and stock movements, past ones
  /// too, then count for that branch.
  Future<void> placeDevice(String branchId, {String? deviceId, String? deviceName, required Staff by}) async {
    final device = deviceId ?? _device.deviceId;
    final branch = await (_db.select(_db.branches)..where((b) => b.id.equals(branchId))).getSingleOrNull();
    if (branch == null || !branch.active) throw const BranchException('Choose an open branch.');
    final now = clock.now();
    await _db.transaction(() async {
      final existing = await (_db.select(_db.deviceBranches)..where((d) => d.id.equals(device))).getSingleOrNull();
      if (existing == null) {
        await _db.insertTracked(
          _db.deviceBranches,
          DeviceBranchesCompanion.insert(
            id: device,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            branchId: branchId,
            deviceName: Value(deviceName),
          ),
        );
      } else {
        await _db.updateTracked(
          _db.deviceBranches,
          existing.copyWith(branchId: branchId, deviceName: Value(deviceName ?? existing.deviceName), deletedAt: const Value(null), updatedAt: now),
        );
      }
      await _audit.record(
        action: AuditAction.deviceBranchChanged,
        actor: by,
        entity: 'device_branches',
        entityId: device,
        summary: '${deviceName ?? 'This device'} is now at ${branch.name}',
      );
    });
  }

  /// Device ID → branch ID, for devices placed in a branch.
  Future<Map<String, String>> placements() async => {
        for (final d in await (_db.select(_db.deviceBranches)..where((d) => d.deletedAt.isNull())).get()) d.id: d.branchId,
      };
}
