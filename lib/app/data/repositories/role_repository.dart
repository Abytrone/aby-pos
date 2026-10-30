import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/permissions.dart';
import '../../models/audit.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'staff_repository.dart';

/// Roles: the built-in four plus any the owner makes.
class RoleRepository {
  RoleRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<List<Role>> list() async {
    final rows = await (_db.select(_db.roles)
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([
            (r) => OrderingTerm(expression: r.sortOrder),
            (r) => OrderingTerm(expression: r.name),
          ]))
        .get();
    return rows.map(roleFromRow).toList();
  }

  /// Active staff per role ID.
  Future<Map<String, int>> staffCounts() async {
    final count = _db.staffMembers.id.count();
    final query = _db.selectOnly(_db.staffMembers)
      ..addColumns([_db.staffMembers.roleId, count])
      ..where(_db.staffMembers.deletedAt.isNull() & _db.staffMembers.active.equals(true))
      ..groupBy([_db.staffMembers.roleId]);
    return {
      for (final r in await query.get()) r.read(_db.staffMembers.roleId)!: r.read(count) ?? 0,
    };
  }

  Future<Role> create({
    required String name,
    required Set<Permission> permissions,
    required int maxDiscountPercent,
    required Staff by,
  }) async {
    final trimmed = _checkName(name);
    return _db.transaction(() async {
      final now = clock.now();
      final row = await _db.insertTracked(
        _db.roles,
        RolesCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          name: trimmed,
          permissions: Value(permissions),
          maxDiscountPercent: Value(maxDiscountPercent.clamp(0, 100)),
          sortOrder: const Value(100),
        ),
      );
      await _audit.record(
        action: AuditAction.roleCreated,
        actor: by,
        entity: 'roles',
        entityId: row.id,
        summary: 'Created role $trimmed',
        details: {'after': _describe(row.permissions, row.maxDiscountPercent)},
      );
      return roleFromRow(row);
    });
  }

  /// The Owner role cannot be changed.
  Future<void> update(
    String roleId, {
    required String name,
    required Set<Permission> permissions,
    required int maxDiscountPercent,
    required Staff by,
  }) async {
    final trimmed = _checkName(name);
    return _db.transaction(() async {
      final row = await _row(roleId);
      if (row.builtIn == BuiltInRole.owner.name) {
        throw const StaffException('The Owner role always has every permission.');
      }
      await _db.updateTracked(
        _db.roles,
        row.copyWith(
          name: trimmed,
          permissions: permissions,
          maxDiscountPercent: maxDiscountPercent.clamp(0, 100),
          updatedAt: clock.now(),
        ),
      );
      await _audit.record(
        action: AuditAction.roleUpdated,
        actor: by,
        entity: 'roles',
        entityId: roleId,
        summary: 'Changed role $trimmed',
        details: {
          'before': _describe(row.permissions, row.maxDiscountPercent),
          'after': _describe(permissions, maxDiscountPercent),
        },
      );
    });
  }

  /// Only roles the owner made, and only when nobody active has them.
  Future<void> delete(String roleId, {required Staff by}) {
    return _db.transaction(() async {
      final row = await _row(roleId);
      if (row.builtIn != null) {
        throw const StaffException("Built-in roles can't be deleted.");
      }
      if ((await staffCounts())[roleId] case final n? when n > 0) {
        throw StaffException('$n ${n == 1 ? 'person has' : 'people have'} this role. '
            'Give them another role first.');
      }
      final now = clock.now();
      await _db.updateTracked(_db.roles, row.copyWith(deletedAt: Value(now), updatedAt: now));
      await _audit.record(
        action: AuditAction.roleDeleted,
        actor: by,
        entity: 'roles',
        entityId: roleId,
        summary: 'Deleted role ${row.name}',
      );
    });
  }

  Future<RoleRow> _row(String id) async {
    final row = await (_db.select(_db.roles)..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
        .getSingleOrNull();
    if (row == null) throw const StaffException('Role not found.');
    return row;
  }

  String _checkName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const StaffException('Enter a role name.');
    return trimmed;
  }

  Map<String, dynamic> _describe(Set<Permission> permissions, int maxDiscount) => {
        'permissions': (permissions.map((p) => p.name).toList()..sort()),
        'maxDiscountPercent': maxDiscount,
      };
}

Role roleFromRow(RoleRow r) => Role(
      id: r.id,
      name: r.name,
      builtIn: BuiltInRole.values.where((b) => b.name == r.builtIn).firstOrNull,
      permissions: r.permissions,
      maxDiscountPercent: r.maxDiscountPercent,
    );
