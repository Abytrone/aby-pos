import 'package:get/get.dart';

import '../data/repositories/staff_repository.dart';
import '../models/staff.dart';

enum SignInResult { ok, wrongPin, lockedOut }

/// Too many wrong PINs; try again after [wait].
class LockedOutException implements Exception {
  const LockedOutException(this.wait);
  final Duration wait;
}

/// Who is on the till right now. Held in memory only: restarting the app
/// signs everyone out.
class AuthService extends GetxService {
  AuthService(this._staff, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final StaffRepository _staff;
  final DateTime Function() _clock;

  static const maxAttempts = 5;
  static const lockout = Duration(seconds: 30);

  final currentUser = Rxn<Staff>();

  final _failures = <String, int>{};
  final _lockedUntil = <String, DateTime>{};

  /// Lockout key for owner approvals, which are not tied to one person.
  static const _approvalKey = '#approval';

  bool get isSignedIn => currentUser.value != null;
  bool get isOwner => currentUser.value?.isOwner ?? false;

  /// The signed-in person. Only call where sign-in is guaranteed (the
  /// routes are guarded by AuthMiddleware).
  Staff get user => currentUser.value!;

  /// Time left before [staffId] may try again, or null.
  Duration? lockedFor(String staffId) {
    final until = _lockedUntil[staffId];
    if (until == null) return null;
    final left = until.difference(_clock());
    if (left <= Duration.zero) {
      _lockedUntil.remove(staffId);
      return null;
    }
    return left;
  }

  /// [maxAttempts] wrong PINs in a row lock that person out for [lockout].
  Future<SignInResult> signIn(Staff staff, String pin) async {
    if (lockedFor(staff.id) != null) return SignInResult.lockedOut;
    if (await _staff.verifyPin(staff.id, pin)) {
      _failures.remove(staff.id);
      currentUser.value = staff;
      return SignInResult.ok;
    }
    return _fail(staff.id) ? SignInResult.lockedOut : SignInResult.wrongPin;
  }

  /// The owner whose PIN this is (for approving a cashier's void), or null.
  /// Throws [LockedOutException] after [maxAttempts] wrong PINs.
  Future<Staff?> approveAsOwner(String pin) async {
    final wait = lockedFor(_approvalKey);
    if (wait != null) throw LockedOutException(wait);
    final owner = await _staff.ownerWithPin(pin);
    if (owner != null) {
      _failures.remove(_approvalKey);
      return owner;
    }
    if (_fail(_approvalKey)) throw const LockedOutException(lockout);
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

  void signOut() => currentUser.value = null;
}
