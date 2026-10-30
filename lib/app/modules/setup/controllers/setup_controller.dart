import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../domain/business_templates.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/pin_hasher.dart';
import '../../../services/settings_service.dart';
import '../../../services/template_service.dart';
import '../../../ui/l10n.dart';
import '../../settings/controllers/backup_controller.dart';

/// First run: name the shop and create the owner, or restore a backup.
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
      _auth.signInAsNew(owner);
      await Get.offAllNamed<void>(Routes.shell);
    } on StaffException catch (e) {
      error.value = e.message;
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
