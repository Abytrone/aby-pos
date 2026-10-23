import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/pin_hasher.dart';
import '../database/app_database.dart';

class StaffException implements Exception {
  const StaffException(this.message);
  final String message;

  @override
  String toString() => 'StaffException: $message';
}

/// Staff and their PINs. Writes go through the outbox like everything else.
///
/// TODO(sync): the PIN hash syncs so staff can sign in on every till. Decide
/// with the API whether the server stores or re-hashes it.
class StaffRepository {
  StaffRepository(this._db, this._device);

  final AppDatabase _db;
  final DeviceInfo _device;

  Future<bool> hasStaff() async {
    final count = _db.staffMembers.id.count();
    final query = _db.selectOnly(_db.staffMembers)
      ..addColumns([count])
      ..where(_db.staffMembers.deletedAt.isNull());
    return (await query.map((r) => r.read(count)).getSingle() ?? 0) > 0;
  }

  /// Owners first, then by name. Includes inactive staff when asked.
  Future<List<Staff>> list({bool includeInactive = false}) async {
    final query = _db.select(_db.staffMembers)
      ..where((s) => s.deletedAt.isNull());
    if (!includeInactive) query.where((s) => s.active.equals(true));
    final rows = await query.get();
    final staff = rows.map(_toStaff).toList()
      ..sort((a, b) {
        if (a.role != b.role) return a.isOwner ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return staff;
  }

  Future<Staff> create({
    required String name,
    required StaffRole role,
    required String pin,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const StaffException('Enter a name.');
    if (!PinHasher.isValidPin(pin)) {
      throw const StaffException('The PIN must be ${PinHasher.pinLength} digits.');
    }
    final now = DateTime.now();
    final row = await _db.transaction(() async {
      if (await _activePinTaken(pin)) {
        throw const StaffException('Someone already uses that PIN. Pick another.');
      }
      return _db.insertTracked(
        _db.staffMembers,
        StaffMembersCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          name: trimmed,
          role: role,
          pinHash: PinHasher.hash(pin),
        ),
      );
    });
    return _toStaff(row);
  }

  /// True when [pin] is this person's PIN and they are active.
  Future<bool> verifyPin(String staffId, String pin) async {
    final row = await _row(staffId);
    return row != null && row.active && PinHasher.verify(pin, row.pinHash);
  }

  /// The active owner whose PIN this is, for approving a cashier's void.
  Future<Staff?> ownerWithPin(String pin) async {
    final owners = await (_db.select(_db.staffMembers)
          ..where((s) =>
              s.deletedAt.isNull() &
              s.active.equals(true) &
              s.role.equalsValue(StaffRole.owner)))
        .get();
    for (final o in owners) {
      if (PinHasher.verify(pin, o.pinHash)) return _toStaff(o);
    }
    return null;
  }

  Future<void> changePin(String staffId, String pin) async {
    if (!PinHasher.isValidPin(pin)) {
      throw const StaffException('The PIN must be ${PinHasher.pinLength} digits.');
    }
    await _db.transaction(() async {
      final row = await _row(staffId);
      if (row == null) throw const StaffException('Staff member not found.');
      if (await _activePinTaken(pin, except: staffId)) {
        throw const StaffException('Someone already uses that PIN. Pick another.');
      }
      await _db.updateTracked(
        _db.staffMembers,
        row.copyWith(pinHash: PinHasher.hash(pin), updatedAt: DateTime.now()),
      );
    });
  }

  /// Deactivated staff cannot sign in. The last active owner stays active.
  /// Reactivating does not re-check for a shared PIN (only hashes are
  /// stored); change the PIN afterwards if it may have been reused.
  Future<void> setActive(String staffId, {required bool active}) async {
    await _db.transaction(() async {
      final row = await _row(staffId);
      if (row == null) throw const StaffException('Staff member not found.');
      if (row.active == active) return;
      if (!active && row.role == StaffRole.owner) {
        final owners = (await list()).where((s) => s.isOwner);
        if (owners.length <= 1) {
          throw const StaffException('Keep at least one active owner.');
        }
      }
      await _db.updateTracked(
        _db.staffMembers,
        row.copyWith(active: active, updatedAt: DateTime.now()),
      );
    });
  }

  /// PINs identify the approver for voids, so active staff must not share one.
  Future<bool> _activePinTaken(String pin, {String? except}) async {
    final rows = await (_db.select(_db.staffMembers)
          ..where((s) => s.deletedAt.isNull() & s.active.equals(true)))
        .get();
    return rows.any((r) => r.id != except && PinHasher.verify(pin, r.pinHash));
  }

  Future<StaffRow?> _row(String id) =>
      (_db.select(_db.staffMembers)..where((s) => s.id.equals(id) & s.deletedAt.isNull()))
          .getSingleOrNull();

  Staff _toStaff(StaffRow r) =>
      Staff(id: r.id, name: r.name, role: r.role, active: r.active);
}
