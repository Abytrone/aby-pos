import 'package:get/get.dart';

import '../core/permissions.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../models/audit.dart';
import '../models/staff.dart';

enum SignInResult { ok, wrongPin, lockedOut }

/// Too many wrong PINs; try again after [wait].
class LockedOutException implements Exception {
  const LockedOutException(this.wait);
  final Duration wait;
}

/// Who is on the till right now. Held in memory only: restarting the app
/// signs everyone out. Sign-ins, failures and locks go to the audit log.
class AuthService extends GetxService {
  AuthService(this._staff, this._audit, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final StaffRepository _staff;
  final AuditRepository _audit;
  final DateTime Function() _clock;

  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  final currentUser = Rxn<Staff>();

  final _failures = <String, int>{};
  final _lockedUntil = <String, DateTime>{};

  /// Lockout key for approvals, which are not tied to one person.
  static const _approvalKey = '#approval';

  bool get isSignedIn => currentUser.value != null;

  /// The signed-in person. Only call where sign-in is guaranteed (the
  /// routes are guarded by AuthMiddleware).
  Staff get user => currentUser.value!;

  bool can(Permission permission) => currentUser.value?.can(permission) ?? false;

  /// Time left before [key] (a staff ID) may try again, or null.
  Duration? lockedFor(String key) {
    final until = _lockedUntil[key];
    if (until == null) return null;
    final left = until.difference(_clock());
    if (left <= Duration.zero) {
      _lockedUntil.remove(key);
      return null;
    }
    return left;
  }

  /// [maxAttempts] wrong PINs in a row lock that person out for [lockout].
  Future<SignInResult> signIn(Staff staff, String pin) async {
    if (lockedFor(staff.id) != null) return SignInResult.lockedOut;
    if (await _staff.verifyPin(staff.id, pin)) {
      _failures.remove(staff.id);
      // Reload so a role changed on another screen takes effect.
      currentUser.value = await _staff.find(staff.id) ?? staff;
      await _audit.record(action: AuditAction.signedIn, actor: staff, summary: '${staff.name} signed in');
      return SignInResult.ok;
    }
    final locked = _fail(staff.id);
    await _audit.record(
      action: locked ? AuditAction.lockedOut : AuditAction.signInFailed,
      actor: staff,
      summary: locked
          ? '${staff.name} locked out after $maxAttempts wrong PINs'
          : 'Wrong PIN for ${staff.name}',
    );
    return locked ? SignInResult.lockedOut : SignInResult.wrongPin;
  }

  /// The person with this PIN who may do [permission], or null for a wrong
  /// PIN. Throws [LockedOutException] after [maxAttempts] wrong PINs.
  Future<Staff?> approveWithPin(String pin, Permission permission, {int? discountPercent}) async {
    final wait = lockedFor(_approvalKey);
    if (wait != null) throw LockedOutException(wait);
    final approver = await _staff.approverWithPin(pin, permission, discountPercent: discountPercent);
    if (approver != null) {
      _failures.remove(_approvalKey);
      return approver;
    }
    if (_fail(_approvalKey)) {
      await _audit.record(
        action: AuditAction.approvalRefused,
        actor: currentUser.value,
        summary: 'Approval locked after $maxAttempts wrong PINs (${permission.name})',
      );
      throw const LockedOutException(lockout);
    }
    return null;
  }

  /// Counts a wrong PIN. Returns true when that starts a lockout.
  bool _fail(String key) {
    final failures = (_failures[key] ?? 0) + 1;
    if (failures >= maxAttempts) {
      _failures.remove(key);
      _lockedUntil[key] = _clock().add(lockout);
      return true;
    }
    _failures[key] = failures;
    return false;
  }

  /// Signs in without a PIN, straight after the owner account is created.
  void signInAsNew(Staff staff) => currentUser.value = staff;

  /// Back to sign-in. [auto] when the idle timer did it.
  Future<void> lock({bool auto = false}) async {
    final who = currentUser.value;
    if (who == null) return;
    currentUser.value = null;
    await _audit.record(
      action: AuditAction.locked,
      actor: who,
      summary: auto ? 'Till locked after no activity' : '${who.name} locked the till',
    );
  }
}
