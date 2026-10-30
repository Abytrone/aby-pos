import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;

import '../../../app.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../services/accounts_export_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/device_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/status_service.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/files.dart';
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
  final AccountsExportService _accounts = Get.find();

  final query = ''.obs;
  final search = TextEditingController();

  /// The open tab, kept while the app runs so Settings opens where it was.
  final tab = 0.obs;
  final lastLocalBackup = Rxn<DateTime>();
  final lastOffsiteBackup = Rxn<DateTime>();
  final lastAccountsPack = Rxn<DateTime>();
  final accountsFolder = ''.obs;

  static const comfortSettings = {
    'device.theme',
    'device.largeText',
    'device.language',
    'device.tileSize',
    'device.productView',
    'device.notifications',
  };

  @override
  void onInit() {
    super.onInit();
    refreshBackupTimes();
  }

  @override
  void onClose() {
    search.dispose();
    super.onClose();
  }

  void clearSearch() {
    search.clear();
    query.value = '';
  }

  Future<void> refreshBackupTimes() async {
    lastLocalBackup.value = await _backups.lastLocalBackupAt();
    lastOffsiteBackup.value = await _backups.lastOffsiteBackupAt();
    lastAccountsPack.value = await _accounts.lastExportAt();
    // Shown only where a folder can be chosen.
    if (_accounts.isOn && canChooseAccountsFolder) accountsFolder.value = (await _accounts.folder()).path;
  }

  bool get canChooseAccountsFolder => AccountsExportService.canChooseFolder;

  /// Turning it on saves last month's pack straight away.
  Future<void> setAccountsMonthly(bool on) async {
    await save(AppSettings.accountsMonthly, on);
    if (on && _settings.get(AppSettings.accountsMonthly)) await _exportNow();
    await Get.find<StatusService>().refresh(checkChain: false);
  }

  Future<void> chooseAccountsFolder() async {
    final path = await pickFolder(appL10n().accountsFolder);
    if (path == null) return;
    await save(AppSettings.accountsFolder, path);
    // A pack that failed to save goes to the new folder now.
    await _exportNow();
    await Get.find<StatusService>().refresh(checkChain: false);
  }

  Future<void> shareLatestAccounts() async {
    final file = await _accounts.latest();
    if (file == null) return showMessage(appL10n().accountsNone);
    await shareOrSaveBytes(p.basename(file.path), await file.readAsBytes());
  }

  Future<void> _exportNow() async {
    final l = appL10n();
    final saved = await _accounts.exportIfDue();
    if (saved.isNotEmpty) {
      showMessage(l.accountsSaved(p.basename(saved.last.path)));
    } else if (await _accounts.problem() != null) {
      showMessage(l.statusAccountsFailed);
    }
    await refreshBackupTimes();
  }

  /// Reactive: whether the signed-in person sees the whole of Settings
  /// rather than only their comfort choices.
  bool get seesShopSettings => _auth.can(Permission.changeSettings) || _auth.can(Permission.manageDevices);

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
