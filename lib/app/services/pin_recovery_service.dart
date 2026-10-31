import 'dart:convert';

import 'package:clock/clock.dart';

import '../core/license.dart';
import '../core/pin_reset.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../models/audit.dart';
import '../models/staff.dart';
import 'auth_service.dart';

/// A forgotten owner PIN, two ways back in: the owner's recovery code, or
/// a reset code from the Aby supplier, who signs this device's request with
/// the licence key (tool/license.dart reset). Either way the owner sets a
/// new PIN and gets a new recovery code.
class PinRecoveryService {
  PinRecoveryService(
    this._db,
    this._staff,
    this._auth,
    this._audit, {
    required this.deviceCode,
    this.publicKey = licensePublicKey,
  });

  final AppDatabase _db;
  final StaffRepository _staff;
  final AuthService _auth;
  final AuditRepository _audit;
  final Future<String> Function() deviceCode;
  final String publicKey;

  /// The request waiting for the supplier's answer. On this device only:
  /// a reset code works where it was asked for.
  static const _requestKey = 'pin.reset.request';
  static const requestLife = Duration(days: 7);

  /// The request to send for [number]: the one waiting when it is for the
  /// same number, so a reset code already on its way still works. Whether
  /// the number is an owner's is only checked when the reset code comes
  /// back, so asking tells nobody who the owners are.
  Future<PinResetRequest> request(String number) async {
    final open = await pending();
    if (open != null && open.staffNumber == number) return open;
    final device = await deviceCode();
    if (device.isEmpty) throw const StaffException('This device has no device code. Contact your Aby supplier.');
    final r = PinResetRequest.create(device, number);
    await _db.writeMeta(_requestKey, jsonEncode({...r.toJson(), 'at': clock.now().toIso8601String()}));
    return r;
  }

  /// The request waiting, unless it is older than [requestLife]. It
  /// survives closing the dialog and restarting the app, so the owner need
  /// not wait at the till for the supplier.
  Future<PinResetRequest?> pending() async => (await waiting())?.request;

  /// The request waiting and when it stops working, or null.
  Future<({PinResetRequest request, DateTime expires})?> waiting() async {
    final raw = await _db.readMeta(_requestKey);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final expires = DateTime.parse(j['at'] as String).add(requestLife);
      if (!clock.now().isBefore(expires)) return null;
      return (request: PinResetRequest.fromJson(j), expires: expires);
    } on Object {
      return null;
    }
  }

  /// Drops the waiting request. A reset code already made for it will not
  /// work. [reason] goes in the log.
  Future<void> cancelRequest({Staff? by, String reason = 'started again'}) async {
    final open = await pending();
    await _db.deleteMeta(_requestKey);
    if (open == null) return;
    await _audit.record(
      action: AuditAction.staffPinResetCancelled,
      actor: by,
      summary: 'PIN reset request for staff number ${open.staffNumber} cancelled: $reason',
    );
  }

  /// [who] just signed in with their PIN: when the open request is theirs,
  /// they remembered it, so the request goes and a reset code arriving
  /// later does nothing. True when there was one, to tell them.
  Future<bool> dropIfRemembered(Staff who) async {
    final open = await pending();
    if (open == null || open.staffNumber != who.number) return false;
    await cancelRequest(by: who, reason: 'they remembered their PIN');
    return true;
  }

  /// The owner the supplier's [resetCode] is for, or null when it does not
  /// answer the waiting request or that number is not an active owner's.
  Future<Staff?> redeem(String resetCode) async {
    final r = await pending();
    if (r == null || !await PinResetCodec.verify(resetCode, r, publicKey: publicKey)) return null;
    return _staff.ownerWithNumber(r.staffNumber);
  }

  /// The owner [recoveryCode] belongs to, or null. Throws
  /// [LockedOutException] after too many wrong tries.
  Future<Staff?> withRecoveryCode(String number, String recoveryCode) =>
      _auth.ownerWithRecoveryCode(number, recoveryCode);

  /// Sets [owner]'s new PIN and signs them in. Returns their new recovery
  /// code, to show once.
  Future<String> setNewPin(Staff owner, String pin, {required bool bySupplier}) async {
    final code = await _staff.resetForgottenPin(
      owner.id,
      pin,
      how: bySupplier ? 'a reset code from the Aby supplier' : 'their recovery code',
    );
    // In with a recovery code while a supplier request waits: it goes too.
    final open = await pending();
    if (open != null && open.staffNumber == owner.number) await _db.deleteMeta(_requestKey);
    await _auth.signInAs(owner, pin);
    return code;
  }
}
