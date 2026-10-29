import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../core/settings.dart';
import '../data/database/app_database.dart';
import '../ui/alert_text.dart';
import '../ui/l10n.dart';
import 'alert_service.dart';
import 'auth_service.dart';
import 'settings_service.dart';
import 'training_service.dart';

/// Shows a notification outside the app.
abstract interface class Notifier {
  /// False when this device cannot show them.
  Future<bool> init();
  Future<void> show(int id, String title, String body);
}

/// Android and Windows notifications through flutter_local_notifications.
class PluginNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  Future<bool> init() async {
    if (!Platform.isAndroid && !Platform.isWindows) return false;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          windows: WindowsInitializationSettings(
            appName: 'Aby',
            appUserModelId: 'Aby.POS',
            guid: '6c1d5f0e-8a2b-4b6e-9f3a-2d7c8e4b1a90',
          ),
        ),
      );
      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }
      return true;
    } on Object {
      // A missing plugin (tests) or an unpackaged Windows build that cannot
      // register: the dashboard still shows the alerts.
      return false;
    }
  }

  @override
  Future<void> show(int id, String title, String body) => _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails('alerts', 'Alerts', channelDescription: 'Things in the shop that need attention'),
          windows: WindowsNotificationDetails(),
        ),
      );
}

/// Turns the dashboard's alerts into phone / Windows notifications, with no
/// internet: each kind at most once a day, or again when it grows (one more
/// item low). Each person can turn kinds off for themselves.
class NotificationService extends GetxService {
  NotificationService(this._db, this._settings, this._alerts, {Notifier? notifier, this.every = const Duration(minutes: 30)})
      : _notifier = notifier ?? PluginNotifier();

  final AppDatabase _db;
  final SettingsService _settings;
  final AlertService _alerts;
  final Notifier _notifier;
  final Duration every;

  static const _sentKey = 'notify.sent';
  static String _offKey(String staffId) => 'notify.off:$staffId';

  bool _ready = false;
  Timer? _timer;

  /// Starts checking. Called once the app is up (not in onInit, so tests
  /// that do not want it are not left with a timer).
  Future<void> start() async {
    _ready = await _notifier.init();
    if (!_ready) return;
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => unawaited(check()));
    // A moment after start, so the first screen is not slowed.
    Timer(const Duration(seconds: 20), () => unawaited(check()));
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  String? get _staffId => Get.isRegistered<AuthService>() ? Get.find<AuthService>().currentUser.value?.id : null;

  /// The kinds [staffId] turned off.
  Future<Set<AlertKind>> offFor(String staffId) async {
    final raw = await _db.readMeta(_offKey(staffId));
    if (raw == null) return {};
    final byName = AlertKind.values.asNameMap();
    return {for (final n in (jsonDecode(raw) as List).cast<String>()) ?byName[n]};
  }

  Future<void> setOff(String staffId, Set<AlertKind> off) =>
      _db.writeMeta(_offKey(staffId), jsonEncode([for (final k in off) k.name]));

  /// Shows what is new since the last notifications. Returns what it showed
  /// (for tests).
  Future<List<Alert>> check({DateTime? now, bool force = false}) async {
    if (!_ready && !force) return const [];
    if (!_settings.get(AppSettings.notifications)) return const [];
    if (Get.isRegistered<TrainingService>() && Get.find<TrainingService>().active.value) return const [];
    final at = now ?? DateTime.now();
    final day = '${at.year}-${at.month}-${at.day}';
    final staff = _staffId;
    final off = staff == null ? <AlertKind>{} : await offFor(staff);
    final raw = await _db.readMeta(_sentKey);
    final sent = raw == null ? <String, dynamic>{} : jsonDecode(raw) as Map<String, dynamic>;
    final shown = <Alert>[];
    final l = appL10n();
    final shop = _settings.get(AppSettings.shopName);
    for (final a in await _alerts.current(now: at)) {
      if (off.contains(a.kind)) continue;
      final last = sent[a.kind.name] as Map<String, dynamic>?;
      if (last != null && last['day'] == day && (last['count'] as int) >= a.count) continue;
      await _notifier.show(a.kind.index, shop, alertText(l, a));
      sent[a.kind.name] = {'day': day, 'count': a.count};
      shown.add(a);
    }
    if (shown.isNotEmpty) await _db.writeMeta(_sentKey, jsonEncode(sent));
    return shown;
  }
}
