import 'dart:convert';

import 'package:get/get.dart';

import '../core/permissions.dart';
import '../data/database/app_database.dart';
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
///
/// Lockouts are kept in [db] (this device only), so restarting the app does
/// not give a guesser fresh tries.
class AuthService extends GetxService {
  AuthService(this._staff, this._audit, {DateTime Function()? clock, this.db})
      : _clock = clock ?? DateTime.now;

  final StaffRepository _staff;
  final AuditRepository _audit;
  final DateTime Function() _clock;
  final AppDatabase? db;

  static const maxAttempts = 5;

  /// The first lockout. Each one after it doubles, up to [longestLockout].
  static const lockout = Duration(seconds: 30);
  static const longestLockout = Duration(minutes: 15);

  /// A lockout this long ago is forgiven: the next starts at [lockout] again.
  static const forgiveAfter = Duration(hours: 1);

  static const _metaKey = 'auth.lockouts';

  /// How long the [n]th lockout in a row lasts (from 1).
  static Duration lockoutNumber(int n) {
    final d = lockout * (1 << (n - 1).clamp(0, 10));
    return d > longestLockout ? longestLockout : d;
  }

  final currentUser = Rxn<Staff>();

  final _failures = <String, int>{};
  final _lockedUntil = <String, DateTime>{};

  /// Lockouts in a row per key, and when the last one ends.
  final _lockouts = <String, ({int count, DateTime until})>{};
  Future<void>? _loaded;

  Future<void> _load() => _loaded ??= () async {
        final text = await db?.readMeta(_metaKey);
        if (text == null) return;
        try {
          for (final e in (jsonDecode(text) as Map<String, dynamic>).entries) {
            final v = e.value as Map<String, dynamic>;
            final until = DateTime.parse(v['until'] as String);
            _lockouts[e.key] = (count: v['count'] as int, until: until);
            if (until.isAfter(_clock())) _lockedUntil[e.key] = until;
          }
        } on Object {
          // Unreadable: start again rather than keep anyone out.
        }
      }();

  Future<void> _save() async {
    final now = _clock();
    _lockouts.removeWhere((_, v) => now.difference(v.until) > forgiveAfter);
    if (db == null) return;
    if (_lockouts.isEmpty) return db!.deleteMeta(_metaKey);
    await db!.writeMeta(_metaKey, jsonEncode({
      for (final e in _lockouts.entries) e.key: {'count': e.value.count, 'until': e.value.until.toIso8601String()},
    }));
  }

  Future<void> _succeeded(String key) async {
    _failures.remove(key);
    if (_lockouts.remove(key) != null) await _save();
  }

  /// Lockout key for approvals, which are not tied to one person.
  static const _approvalKey = '#approval';

  /// Lockout key for recovery codes.
  static const _recoveryKey = '#recovery';

  bool get isSignedIn => currentUser.value != null;

  /// The signed-in person. Only call where sign-in is guaranteed (the
  /// routes are guarded by AuthMiddleware).
  Staff get user => currentUser.value!;

  bool can(Permission permission) => currentUser.value?.can(permission) ?? false;

  /// Time left before [key] (a staff number) may try again, or null.
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

  /// Signs in whoever has this staff number and PIN (at [atBranch], when
  /// given). A wrong number and a wrong PIN look the same, so the screen
  /// gives away nothing about who works here. [maxAttempts] wrong tries in
  /// a row lock that number for [lockout], longer each time.
  Future<SignInResult> signIn(String number, String pin, {String? atBranch}) async {
    await _load();
    if (lockedFor(number) != null) return SignInResult.lockedOut;
    final person = await _staff.withNumber(number, pin, atBranch: atBranch);
    if (person != null) return _signedIn(number, person);
    final owner = (await _staff.list()).where((s) => s.number == number).firstOrNull;
    return _wrongPin(number, owner, owner?.name ?? 'staff number $number');
  }

  /// Signs in [staff], already known (a badge, or the only person on this
  /// till). Shares the lockout of their staff number.
  Future<SignInResult> signInAs(Staff staff, String pin) async {
    final key = staff.number ?? staff.id;
    await _load();
    if (lockedFor(key) != null) return SignInResult.lockedOut;
    if (await _staff.verifyPin(staff.id, pin)) return _signedIn(key, staff);
    return _wrongPin(key, staff, staff.name);
  }

  Future<SignInResult> _signedIn(String key, Staff staff) async {
    await _succeeded(key);
    // Reload so a role changed on another screen takes effect.
    currentUser.value = await _staff.find(staff.id) ?? staff;
    await _audit.record(action: AuditAction.signedIn, actor: staff, summary: '${staff.name} signed in');
    return SignInResult.ok;
  }

  Future<SignInResult> _wrongPin(String key, Staff? staff, String who) async {
    final locked = await _fail(key);
    await _audit.record(
      action: locked ? AuditAction.lockedOut : AuditAction.signInFailed,
      actor: staff,
      summary: locked ? '$who locked out after $maxAttempts wrong PINs' : 'Wrong PIN for $who',
    );
    return locked ? SignInResult.lockedOut : SignInResult.wrongPin;
  }

  /// The person with this staff number and PIN who may do [permission], or
  /// null. Throws [LockedOutException] after [maxAttempts] wrong tries.
  Future<Staff?> approveWithPin(String number, String pin, Permission permission, {int? discountPercent}) async {
    await _load();
    final wait = lockedFor(_approvalKey);
    if (wait != null) throw LockedOutException(wait);
    final approver = await _staff.approverWithPin(number, pin, permission, discountPercent: discountPercent);
    if (approver != null) {
      await _succeeded(_approvalKey);
      return approver;
    }
    if (await _fail(_approvalKey)) {
      await _audit.record(
        action: AuditAction.approvalRefused,
        actor: currentUser.value,
        summary: 'Approval locked after $maxAttempts wrong PINs (${permission.name})',
      );
      throw LockedOutException(lockedFor(_approvalKey) ?? lockout);
    }
    return null;
  }

  /// The signed-in person's own PIN, asked again before something
  /// sensitive. Shares their sign-in lockout; does not sign in again.
  Future<SignInResult> confirmOwnPin(String pin) async {
    final me = user;
    final key = me.number ?? me.id;
    await _load();
    if (lockedFor(key) != null) return SignInResult.lockedOut;
    if (await _staff.verifyPin(me.id, pin)) {
      await _succeeded(key);
      return SignInResult.ok;
    }
    return _wrongPin(key, me, me.name);
  }

  /// The owner with this staff number and recovery code, or null. Throws
  /// [LockedOutException] after [maxAttempts] wrong tries.
  Future<Staff?> ownerWithRecoveryCode(String number, String code) async {
    await _load();
    final wait = lockedFor(_recoveryKey);
    if (wait != null) throw LockedOutException(wait);
    final owner = await _staff.ownerWithRecoveryCode(number, code);
    if (owner != null) {
      await _succeeded(_recoveryKey);
      return owner;
    }
    final locked = await _fail(_recoveryKey);
    await _audit.record(
      action: locked ? AuditAction.lockedOut : AuditAction.signInFailed,
      summary: locked
          ? 'Recovery codes locked after $maxAttempts wrong tries'
          : 'Wrong recovery code for staff number $number',
    );
    if (locked) throw LockedOutException(lockedFor(_recoveryKey) ?? lockout);
    return null;
  }

  /// Counts a wrong PIN. Returns true when that starts a lockout.
  Future<bool> _fail(String key) async {
    final failures = (_failures[key] ?? 0) + 1;
    if (failures >= maxAttempts) {
      _failures.remove(key);
      final now = _clock();
      final last = _lockouts[key];
      final count = last == null || now.difference(last.until) > forgiveAfter ? 1 : last.count + 1;
      final until = now.add(lockoutNumber(count));
      _lockedUntil[key] = until;
      _lockouts[key] = (count: count, until: until);
      await _save();
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
