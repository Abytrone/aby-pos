import 'dart:async';

import 'package:get/get.dart';

import '../core/settings.dart';
import '../routes/app_routes.dart';
import 'auth_service.dart';
import 'settings_service.dart';

/// Locks the till after the idle time in settings. The app root reports
/// every touch and key press through [touch]; the cart is kept on lock.
class SessionService extends GetxService {
  SessionService(this._auth, this._settings, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final AuthService _auth;
  final SettingsService _settings;
  final DateTime Function() _clock;

  late DateTime _lastActivity = _clock();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => check());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  void touch() => _lastActivity = _clock();

  /// Locks if idle too long. Returns true when it locked.
  Future<bool> check() async {
    final minutes = _settings.get(AppSettings.autoLockMinutes);
    if (minutes <= 0 || !_auth.isSignedIn) return false;
    if (_clock().difference(_lastActivity) < Duration(minutes: minutes)) return false;
    await lockNow(auto: true);
    return true;
  }

  Future<void> lockNow({bool auto = false}) async {
    await _auth.lock(auto: auto);
    if (Get.key.currentState != null) await Get.offAllNamed<void>(Routes.signIn);
  }
}
