import 'package:get/get.dart';

import '../../../app.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../services/auth_service.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/device_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';

/// Manage → Settings. Shop settings need "Change settings" (or approval);
/// comfort settings for this device (theme, text size, language) do not.
class SettingsController extends GetxController {
  final SettingsService _settings = Get.find();
  final PermissionService _permissions = Get.find();
  final AuthService _auth = Get.find();
  final BackupService _backups = Get.find();
  final DeviceService _device = Get.find();
  final AppDatabase _db = Get.find();

  final query = ''.obs;
  final lastLocalBackup = Rxn<DateTime>();
  final lastOffsiteBackup = Rxn<DateTime>();

  static const comfortSettings = {
    'device.theme',
    'device.largeText',
    'device.language',
    'device.tileSize',
    'device.notifications',
  };

  @override
  void onInit() {
    super.onInit();
    refreshBackupTimes();
  }

  Future<void> refreshBackupTimes() async {
    lastLocalBackup.value = await _backups.lastLocalBackupAt();
    lastOffsiteBackup.value = await _backups.lastOffsiteBackupAt();
  }

  T value<T extends Object>(Setting<T> s) => _settings.get(s);

  String get deviceId => _device.deviceId;
  int get schemaVersion => _db.schemaVersion;

  Future<void> save<T extends Object>(Setting<T> setting, T newValue) async {
    if (_settings.get(setting) == newValue) return;
    final l = appL10n();
    final by = comfortSettings.contains(setting.key)
        ? _auth.user
        : (await _permissions.authorize(Permission.changeSettings, reason: l.settingsApprovalReason))
            ?.authority;
    if (by == null) return;
    await _settings.set(setting, newValue, by: by);
    if (setting.key == AppSettings.themeMode.key) AppRestarter.applyTheme(newValue as String);
    showMessage(l.settingsSaved);
  }

  /// Several settings with one approval (printer setup, receipt design).
  /// False when nothing was saved because approval was refused. The caller
  /// closes its dialog, then says so ([saved]).
  Future<bool> saveAll(List<(Setting<Object>, Object)> values) async {
    final changed = [for (final v in values) if (_settings.get(v.$1) != v.$2) v];
    if (changed.isEmpty) return true;
    final l = appL10n();
    final by = (await _permissions.authorize(Permission.changeSettings, reason: l.settingsApprovalReason))?.authority;
    if (by == null) return false;
    for (final (setting, value) in changed) {
      await _settings.set(setting, value, by: by);
    }
    return true;
  }

  void saved() => showMessage(appL10n().settingsSaved);

  /// "Change settings", or an approver's PIN.
  Future<bool> authorizeChange() async =>
      await _permissions.authorize(Permission.changeSettings, reason: appL10n().settingsApprovalReason) != null;
}
