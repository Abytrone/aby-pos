import 'package:drift/drift.dart';

import '../../core/permissions.dart';
import '../../models/audit.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/pin_hasher.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'role_repository.dart';

class StaffException implements Exception {
  const StaffException(this.message);
  final String message;

  @override
  String toString() => 'StaffException: $message';
}

/// Staff and their PINs. Every change writes the outbox and the audit log
/// in the same transaction.
///
/// TODO(sync): the PIN hash syncs so staff can sign in on every till. Decide
/// with the API whether the server stores or re-hashes it.
class StaffRepository {
  StaffRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<bool> hasStaff() async {
    final count = _db.staffMembers.id.count();
    final query = _db.selectOnly(_db.staffMembers)
      ..addColumns([count])
      ..where(_db.staffMembers.deletedAt.isNull());
    return (await query.map((r) => r.read(count)).getSingle() ?? 0) > 0;
  }

  /// Owners first, then by name. Includes inactive staff when asked.
  Future<List<Staff>> list({bool includeInactive = false}) async {
    final rows = await _joined(includeInactive: includeInactive);
    return rows
      ..sort((a, b) {
        if (a.isOwner != b.isOwner) return a.isOwner ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  Future<Staff?> find(String id) async =>
      (await _joined(includeInactive: true, id: id)).firstOrNull;

  Future<List<Staff>> _joined({required bool includeInactive, String? id}) async {
    final query = _db.select(_db.staffMembers).join([
      innerJoin(_db.roles, _db.roles.id.equalsExp(_db.staffMembers.roleId)),
    ])
      ..where(_db.staffMembers.deletedAt.isNull());
    if (!includeInactive) query.where(_db.staffMembers.active.equals(true));
    if (id != null) query.where(_db.staffMembers.id.equals(id));
    final rows = await query.get();
    return [
      for (final r in rows) _toStaff(r.readTable(_db.staffMembers), roleFromRow(r.readTable(_db.roles))),
    ];
  }

  /// [by] is null only for the very first owner, created at setup.
  Future<Staff> create({
    required String name,
    required String roleId,
    required String pin,
    Staff? by,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const StaffException('Enter a name.');
    _checkPin(pin);
    return _db.transaction(() async {
      if (await _activePinTaken(pin)) {
        throw const StaffException('Someone already uses that PIN. Pick another.');
      }
      final now = DateTime.now();
      final row = await _db.insertTracked(
        _db.staffMembers,
        StaffMembersCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          name: trimmed,
          roleId: roleId,
          pinHash: PinHasher.hash(pin),
        ),
      );
      final staff = (await find(row.id))!;
      await _audit.record(
        action: AuditAction.staffAdded,
        actor: by ?? staff,
        entity: 'staff',
        entityId: staff.id,
        summary: 'Added ${staff.name} as ${staff.role.name}',
      );
      return staff;
    });
  }

  /// True when [pin] is this person's PIN and they are active.
  Future<bool> verifyPin(String staffId, String pin) async {
    final row = await _row(staffId);
    return row != null && row.active && PinHasher.verify(pin, row.pinHash);
  }

  /// The active person with this PIN who is allowed [permission], for
  /// approving something the signed-in person cannot do.
  /// The active person with this PIN who may do [permission] (and give a
  /// discount of [discountPercent], when asked).
  Future<Staff?> approverWithPin(String pin, Permission permission, {int? discountPercent}) async {
    final need = ApprovalNeed(permission, discountPercent: discountPercent);
    for (final s in await list()) {
      if (!need.allows(s)) continue;
      final row = await _row(s.id);
      if (row != null && PinHasher.verify(pin, row.pinHash)) return s;
    }
    return null;
  }

  Future<void> changePin(String staffId, String pin, {required Staff by}) async {
    _checkPin(pin);
    await _db.transaction(() async {
      final row = await _requireRow(staffId);
      if (await _activePinTaken(pin, except: staffId)) {
        throw const StaffException('Someone already uses that PIN. Pick another.');
      }
      await _db.updateTracked(
        _db.staffMembers,
        row.copyWith(pinHash: PinHasher.hash(pin), updatedAt: DateTime.now()),
      );
      await _audit.record(
        action: AuditAction.staffPinChanged,
        actor: by,
        entity: 'staff',
        entityId: staffId,
        summary: 'Changed PIN for ${row.name}',
      );
    });
  }

  Future<void> changeRole(String staffId, String roleId, {required Staff by}) async {
    await _db.transaction(() async {
      final before = (await find(staffId))!;
      if (before.role.id == roleId) return;
      if (before.isOwner && before.active) await _requireAnotherOwner(staffId);
      final row = await _requireRow(staffId);
      await _db.updateTracked(
        _db.staffMembers,
        row.copyWith(roleId: roleId, updatedAt: DateTime.now()),
      );
      final after = (await find(staffId))!;
      await _audit.record(
        action: AuditAction.staffRoleChanged,
        actor: by,
        entity: 'staff',
        entityId: staffId,
        summary: '${after.name}: ${before.role.name} to ${after.role.name}',
        details: {'before': before.role.id, 'after': after.role.id},
      );
    });
  }

  /// Deactivated staff cannot sign in. The last active owner stays active.
  /// Reactivating does not re-check for a shared PIN (only hashes are
  /// stored); change the PIN afterwards if it may have been reused.
  Future<void> setActive(String staffId, {required bool active, required Staff by}) async {
    await _db.transaction(() async {
      final row = await _requireRow(staffId);
      if (row.active == active) return;
      final person = (await find(staffId))!;
      if (!active && person.isOwner) await _requireAnotherOwner(staffId);
      await _db.updateTracked(
        _db.staffMembers,
        row.copyWith(active: active, updatedAt: DateTime.now()),
      );
      await _audit.record(
        action: active ? AuditAction.staffReactivated : AuditAction.staffDeactivated,
        actor: by,
        entity: 'staff',
        entityId: staffId,
        summary: '${active ? 'Reactivated' : 'Deactivated'} ${row.name}',
      );
    });
  }

  Future<StaffProfile?> profile(String id) async {
    final staff = await find(id);
    final row = await _row(id);
    if (staff == null || row == null) return null;
    return StaffProfile(
      staff: staff,
      joinedAt: row.createdAt,
      phone: row.phone,
      email: row.email,
      address: row.address,
      emergencyName: row.emergencyName,
      emergencyPhone: row.emergencyPhone,
      idNumber: row.idNumber,
      dateOfBirth: row.dateOfBirth,
      startedOn: row.startedOn,
      notes: row.notes,
    );
  }

  /// Saves profile details. Values should already be normalised (see
  /// Validators). The audit entry lists what changed, with the Ghana Card
  /// number masked.
  Future<void> updateDetails(String staffId, StaffDetails d, {required Staff by}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw const StaffException('Enter a name.');
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    await _db.transaction(() async {
      final row = await _requireRow(staffId);
      final updated = row.copyWith(
        name: name,
        phone: Value(clean(d.phone)),
        email: Value(clean(d.email)),
        address: Value(clean(d.address)),
        emergencyName: Value(clean(d.emergencyName)),
        emergencyPhone: Value(clean(d.emergencyPhone)),
        idNumber: Value(clean(d.idNumber)),
        dateOfBirth: Value(d.dateOfBirth),
        startedOn: Value(d.startedOn),
        notes: Value(clean(d.notes)),
      );
      final before = _auditView(row);
      final after = _auditView(updated);
      final changed = [for (final k in after.keys) if (before[k] != after[k]) k];
      if (changed.isEmpty) return;
      await _db.updateTracked(_db.staffMembers, updated.copyWith(updatedAt: DateTime.now()));
      await _audit.record(
        action: AuditAction.staffDetailsChanged,
        actor: by,
        entity: 'staff',
        entityId: staffId,
        summary: 'Changed ${changed.join(', ')} for $name',
        details: {
          'before': {for (final k in changed) k: before[k]},
          'after': {for (final k in changed) k: after[k]},
        },
      );
    });
  }

  /// Profile fields as the audit log shows them.
  Map<String, Object?> _auditView(StaffRow r) {
    final id = r.idNumber;
    String? day(DateTime? t) => t?.toIso8601String().substring(0, 10);
    return {
      'name': r.name,
      'phone': r.phone,
      'email': r.email,
      'address': r.address,
      'emergencyName': r.emergencyName,
      'emergencyPhone': r.emergencyPhone,
      'idNumber': id == null || id.length < 4 ? id : '…${id.substring(id.length - 4)}',
      'dateOfBirth': day(r.dateOfBirth),
      'startedOn': day(r.startedOn),
      'notes': r.notes,
    };
  }

  /// Someone changing their own PIN must know the current one.
  Future<void> changeOwnPin(Staff me, String currentPin, String newPin) async {
    if (!await verifyPin(me.id, currentPin)) {
      throw const StaffException('The current PIN is wrong.');
    }
    await changePin(me.id, newPin, by: me);
  }

  Future<Uint8List?> photo(String staffId) async {
    final row = await (_db.select(_db.staffPhotos)..where((p) => p.staffId.equals(staffId)))
        .getSingleOrNull();
    return row?.image;
  }

  /// [image] should already be small (the UI scales it to 320 px).
  Future<void> setPhoto(String staffId, Uint8List? image, {required Staff by}) async {
    await _db.transaction(() async {
      final row = await _requireRow(staffId);
      if (image == null) {
        await (_db.delete(_db.staffPhotos)..where((p) => p.staffId.equals(staffId))).go();
      } else {
        await _db.into(_db.staffPhotos).insertOnConflictUpdate(
              StaffPhotosCompanion.insert(staffId: staffId, image: image, updatedAt: DateTime.now()),
            );
      }
      await _audit.record(
        action: AuditAction.staffDetailsChanged,
        actor: by,
        entity: 'staff',
        entityId: staffId,
        summary: '${image == null ? 'Removed' : 'Changed'} photo for ${row.name}',
      );
    });
  }

  Future<void> _requireAnotherOwner(String exceptId) async {
    final owners = (await list()).where((s) => s.isOwner && s.id != exceptId);
    if (owners.isEmpty) throw const StaffException('Keep at least one active owner.');
  }

  void _checkPin(String pin) {
    if (!PinHasher.isValidPin(pin)) {
      throw const StaffException('The PIN must be ${PinHasher.pinLength} digits.');
    }
  }

  /// PINs identify approvers, so active staff must not share one.
  Future<bool> _activePinTaken(String pin, {String? except}) async {
    final rows = await (_db.select(_db.staffMembers)
          ..where((s) => s.deletedAt.isNull() & s.active.equals(true)))
        .get();
    return rows.any((r) => r.id != except && PinHasher.verify(pin, r.pinHash));
  }

  Future<StaffRow?> _row(String id) =>
      (_db.select(_db.staffMembers)..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
          .getSingleOrNull();

  Future<StaffRow> _requireRow(String id) async {
    final row = await _row(id);
    if (row == null) throw const StaffException('Staff member not found.');
    return row;
  }

  Staff _toStaff(StaffRow r, Role role) =>
      Staff(id: r.id, name: r.name, role: role, active: r.active);
}
