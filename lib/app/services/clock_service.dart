import 'dart:async';

import 'package:get/get.dart';

import '../core/settings.dart';
import '../data/repositories/time_repository.dart';
import '../models/staff.dart';
import 'auth_service.dart';
import 'settings_service.dart';

/// Whether the signed-in person is clocked in (STF-04), kept up to date for
/// the user menu and the "clock in to sell" rule.
class ClockService extends GetxService {
  ClockService(this._times, this._auth, this._settings);

  final TimeRepository _times;
  final AuthService _auth;
  final SettingsService _settings;

  final state = Rxn<ClockedIn>();
  StreamSubscription<Staff?>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _auth.currentUser.listen((_) => unawaited(refresh()));
    unawaited(refresh());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> refresh() async {
    final me = _auth.currentUser.value;
    state.value = me == null ? null : await _times.current(me.id);
  }

  bool get clockedIn => state.value != null;

  /// Selling waits for clocking in when the shop asks for it.
  bool get mayNotSell => _settings.get(AppSettings.clockInToSell) && !clockedIn;

  /// ...and for the end of a break.
  bool get mustEndBreak => _settings.get(AppSettings.clockInToSell) && (state.value?.onBreak ?? false);

  /// Right after signing in: asks someone not clocked in to clock in, when
  /// the shop wants that before selling. Pay asks again if they say no.
  Future<void> offerAfterSignIn(Future<bool> Function() ask) async {
    await refresh();
    if (!mayNotSell || !await ask()) return;
    try {
      await clockIn();
    } on TimeClockException {
      // Clocked in on another till meanwhile: nothing to do.
      await refresh();
    }
  }

  Future<void> clockIn() async {
    await _times.clockIn(_auth.user);
    await refresh();
  }

  Future<void> clockOut() async {
    await _times.clockOut(_auth.user);
    await refresh();
  }

  Future<void> toggleBreak() async {
    if (state.value?.onBreak ?? false) {
      await _times.endBreak(_auth.user);
    } else {
      await _times.startBreak(_auth.user);
    }
    await refresh();
  }
}
