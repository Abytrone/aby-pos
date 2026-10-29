import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../services/backup/backup_codec.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/training_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/status_service.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

/// Backup flows for Settings, the status centre and first-run setup.
/// Dialogs are opened from here because each flow is a short conversation
/// (password, preview, confirm) around one service call.
class BackupController extends GetxController {
  final BackupService _backups = Get.find();
  final PermissionService _permissions = Get.find();
  final AuthService _auth = Get.find();
  final SettingsService _settings = Get.find();
  final StatusService _status = Get.find();

  final localBackups = <LocalBackup>[].obs;
  final hasPassword = false.obs;
  final busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshList();
  }

  Future<void> refreshList() async {
    hasPassword.value = await _backups.hasBackupPassword();
    try {
      localBackups.assignAll(await _backups.listLocalBackups());
    } catch (_) {
      // No storage folder available (e.g. in tests): show none.
      localBackups.clear();
    }
  }

  /// Backups and restores belong to the real data, not the training copy.
  bool get _training => Get.isRegistered<TrainingService>() && Get.find<TrainingService>().active.value;

  Future<void> backUpNow() => _training ? Future<void>.sync(() => showMessage(appL10n().trainingNoBackups)) : _guard(() async {
        await _backups.createLocalBackup(by: _auth.currentUser.value);
        await refreshList();
        await _status.refresh(checkChain: false);
        showMessage(appL10n().backupDone);
      });

  /// Set or change the backup password. Old backup files keep the password
  /// they were made with.
  Future<bool> setPassword() async {
    final l = appL10n();
    final auth = await _permissions.authorize(Permission.exportData, reason: l.backupPasswordSet);
    if (auth == null) return false;
    final first = await textInputDialog(
      title: l.backupPasswordSet,
      label: l.backupPasswordNew,
      helper: l.backupPasswordHelp,
      obscure: true,
      validate: (v) => v.length < BackupService.minPasswordLength
          ? l.backupPasswordTooShort(BackupService.minPasswordLength)
          : null,
    );
    if (first == null) return false;
    final again = await textInputDialog(
      title: l.backupPasswordSet,
      label: l.backupPasswordAgain,
      obscure: true,
      validate: (v) => v == first ? null : l.backupPasswordMismatch,
    );
    if (again == null) return false;
    await _backups.setBackupPassword(first);
    hasPassword.value = true;
    showMessage(l.backupPasswordSaved);
    return true;
  }

  /// Encrypt a fresh backup and send it somewhere off this device.
  Future<void> sendOffDevice() async {
    if (_training) return showMessage(appL10n().trainingNoBackups);
    final l = appL10n();
    final auth = await _permissions.authorize(Permission.exportData, reason: l.backupSend);
    if (auth == null) return;
    if (!await _backups.hasBackupPassword() && !await setPassword()) return;

    final password = await textInputDialog(
      title: l.backupSend,
      label: l.backupPassword,
      helper: l.backupSendHelp,
      obscure: true,
      confirmLabel: l.commonContinue,
    );
    if (password == null) return;
    if (!await _backups.checkBackupPassword(password)) {
      showMessage(l.backupPasswordWrong);
      return;
    }

    File? file;
    await _guard(() async {
      file = await _backups.exportEncrypted(
        password: password,
        shopName: _settings.get(AppSettings.shopName),
        by: auth.authority,
      );
    }, progress: l.backupEncrypting);
    final out = file;
    if (out == null) return;

    final where = await choiceDialog<_Destination>(
      title: l.backupWhere,
      options: _Destination.values,
      label: (d) => d == _Destination.share ? l.backupShare : l.backupSaveToFolder,
    );
    if (where == null) return;
    final sent = where == _Destination.share ? await _share(out) : await _saveToFolder(out);
    if (sent) {
      await _backups.markOffsiteDone(where: where.name, by: auth.authority);
      await _status.refresh(checkChain: false);
      showMessage(l.backupSent);
    }
  }

  Future<bool> _share(File file) async {
    final l = appL10n();
    final result = await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      subject: l.backupShareSubject(_settings.get(AppSettings.shopName)),
    ));
    if (result.status == ShareResultStatus.unavailable) {
      showMessage(l.backupShareUnavailable);
      return false;
    }
    return result.status == ShareResultStatus.success;
  }

  Future<bool> _saveToFolder(File file) async {
    final saved = await FilePicker.saveFile(
      dialogTitle: appL10n().backupSaveToFolder,
      fileName: file.uri.pathSegments.last,
      bytes: await file.readAsBytes(),
    );
    return saved != null;
  }

  /// Restore one of this device's own backups.
  Future<void> restoreLocal(LocalBackup backup) async {
    final l = appL10n();
    final auth = await _permissions.authorize(Permission.restoreBackup, reason: l.backupRestore);
    if (auth == null) return;
    await _inspectAndRestore(backup.file, byStaff: auth.authority);
  }

  /// Restore from a file (`.abybak` from another device, or a copied
  /// `.sqlite`). [fromSetup]: first run, nobody to authorise yet.
  Future<void> restoreFromFile({bool fromSetup = false}) async {
    if (_training) return showMessage(appL10n().trainingNoBackups);
    final l = appL10n();
    Authorization? auth;
    if (!fromSetup) {
      auth = await _permissions.authorize(Permission.restoreBackup, reason: l.backupRestore);
      if (auth == null) return;
    }
    final picked = await FilePicker.pickFile(dialogTitle: l.backupPickFile);
    if (picked == null) return;
    // Android may hand back a content URI with no file path: copy it first.
    var path = picked.path;
    if (path == null) {
      final tmp = await getTemporaryDirectory();
      final copy = File('${tmp.path}${Platform.pathSeparator}${picked.name}');
      final sink = copy.openWrite();
      await sink.addStream(picked.readAsByteStream());
      await sink.close();
      path = copy.path;
    }
    await _inspectAndRestore(File(path), byStaff: auth?.authority);
  }

  Future<void> _inspectAndRestore(File file, {Staff? byStaff}) async {
    final l = appL10n();
    BackupPreview? preview;
    String? password;
    final head = await file.openRead(0, 16).expand((chunk) => chunk).toList();
    final encrypted = BackupCodec.looksLikeBackup(Uint8List.fromList(head));
    while (preview == null) {
      if (encrypted) {
        password = await textInputDialog(
          title: l.backupRestore,
          label: l.backupPassword,
          obscure: true,
          confirmLabel: l.commonContinue,
        );
        if (password == null) return;
      }
      try {
        await _guard(() async {
          preview = await _backups.inspectFile(file, password: password);
        }, progress: l.backupChecking, rethrowErrors: true);
      } on BackupDecryptException catch (e) {
        showMessage(_decryptMessage(l, e));
        if (!encrypted) return;
      } on BackupException catch (e) {
        showMessage(e.message);
        return;
      }
    }
    final p = preview!;
    final ok = await confirmDialog(
      title: l.backupRestoreConfirmTitle,
      message: l.backupRestoreConfirmBody(
        p.shopName,
        p.salesCount,
        p.lastSaleAt == null ? l.backupNoSales : formatDateTime(p.lastSaleAt!),
      ),
      confirmLabel: l.backupRestore,
      danger: true,
    );
    if (!ok) return;
    await _guard(() => _backups.restore(p, by: byStaff), progress: l.backupRestoring);
    await AppRestarter.restart();
  }

  String _decryptMessage(AppLocalizations l, BackupDecryptException e) =>
      e.message.startsWith('Wrong') ? l.backupPasswordWrong : e.message;

  Future<void> _guard(
    Future<void> Function() action, {
    String? progress,
    bool rethrowErrors = false,
  }) async {
    if (busy.value) return;
    busy.value = true;
    if (progress != null) showProgress(progress);
    try {
      await action();
    } catch (e) {
      if (rethrowErrors) rethrow;
      showMessage(e is BackupException ? e.message : appL10n().backupFailed);
    } finally {
      if (progress != null) hideProgress();
      busy.value = false;
    }
  }
}

enum _Destination { share, folder }
