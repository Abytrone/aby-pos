import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../domain/business_templates.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/hub/hub_service.dart';
import '../../../services/pin_hasher.dart';
import '../../../services/settings_service.dart';
import '../../../services/template_service.dart';
import '../../../ui/l10n.dart';
import '../../../ui/recovery_code_dialog.dart';
import '../../settings/controllers/backup_controller.dart';
import '../../settings/widgets/hub_devices.dart';

/// First run: name the shop and create the owner, join the shop's hub, or
/// restore a backup.
class SetupController extends GetxController {
  final StaffRepository _staff = Get.find();
  final AuthService _auth = Get.find();
  final SettingsService _settings = Get.find();

  /// Blank until the shop is named ("My shop" is only the fallback).
  late final shopField = TextEditingController(
    text: _settings.get(AppSettings.shopName) == AppSettings.shopName.defaultValue ? '' : _settings.get(AppSettings.shopName),
  );
  final nameField = TextEditingController();
  final pinField = TextEditingController();
  final confirmField = TextEditingController();

  final saving = false.obs;
  final error = RxnString();

  /// The kind of shop (APP-04): sets up categories and features.
  final type = BusinessType.iceCream.obs;

  void pickType(BusinessType t) => type.value = t;

  @override
  void onClose() {
    shopField.dispose();
    nameField.dispose();
    pinField.dispose();
    confirmField.dispose();
    super.onClose();
  }

  Future<void> createOwner() async {
    if (saving.value) return;
    final l = appL10n();
    final pin = pinField.text;
    if (shopField.text.trim().isEmpty) {
      error.value = l.setupShopNameMissing;
      return;
    }
    if (nameField.text.trim().isEmpty) {
      error.value = l.setupNameMissing;
      return;
    }
    if (!PinHasher.isValidPin(pin)) {
      error.value = l.pinMustBeDigits(PinHasher.pinLength);
      return;
    }
    if (pin != confirmField.text) {
      error.value = l.pinMismatch;
      return;
    }
    saving.value = true;
    error.value = null;
    try {
      final owner = await _staff.create(
        name: nameField.text,
        roleId: BuiltInRole.owner.id,
        pin: pin,
      );
      await _settings.set(AppSettings.shopName, shopField.text.trim(), by: owner);
      await TemplateService(Get.find<CatalogRepository>(), _settings).apply(type.value, by: owner);
      final recoveryCode = await _staff.newRecoveryCode(owner.id, by: owner);
      _auth.signInAsNew(owner);
      await showRecoveryCode(recoveryCode);
      await Get.offAllNamed<void>(Routes.shell);
    } on StaffException catch (e) {
      error.value = e.message;
    } finally {
      saving.value = false;
    }
  }

  /// Joined the hub but did not finish taking the shop's data.
  bool get joined => Get.find<HubService>().role.value == HubRole.member;

  /// Another till for a shop that already runs Aby: join its hub and take
  /// everything from it, then sign in as one of its staff. The pairing code
  /// is the hub's say-so. A device that joined but did not finish syncing
  /// (the Wi-Fi dropped) tries again.
  Future<void> joinHub() async {
    if (saving.value) return;
    final l = appL10n();
    final hub = Get.find<HubService>();
    final JoinTarget? target;
    if (hub.role.value == HubRole.none) {
      target = await pickHubToJoin();
      if (target == null) return;
    } else {
      target = null;
    }
    saving.value = true;
    error.value = null;
    try {
      if (target != null) {
        final name = _settings.get(AppSettings.deviceName);
        await hub.join(target.urls, target.code, hubId: target.hubId, deviceName: name.isEmpty ? null : name, fresh: true);
      } else {
        await hub.syncNow();
      }
      final problem = hub.problem.value;
      if (problem != null) {
        error.value = hubErrorText(l, problem);
      } else if (!await _staff.hasStaff()) {
        error.value = l.setupJoinNoStaff;
      } else {
        // Starts again with the hub's settings, at sign-in.
        await AppRestarter.restart();
      }
    } on HubException catch (e) {
      error.value = hubErrorText(l, e.error);
    } finally {
      saving.value = false;
    }
  }

  /// Moving to a new device: bring everything back from a backup file.
  Future<void> restore() {
    final backups = Get.isRegistered<BackupController>()
        ? Get.find<BackupController>()
        : Get.put(BackupController());
    return backups.restoreFromFile(fromSetup: true);
  }
}
