import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/repositories/staff_repository.dart';
import '../../../models/enums.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';
import '../../../services/pin_hasher.dart';

/// First run: create the owner, then go straight to the till.
class SetupController extends GetxController {
  final StaffRepository _staff = Get.find();
  final AuthService _auth = Get.find();
  final DeviceService _device = Get.find();

  final nameField = TextEditingController();
  final pinField = TextEditingController();
  final confirmField = TextEditingController();

  final saving = false.obs;
  final error = RxnString();

  String get shopName => _device.shopName;

  @override
  void onClose() {
    nameField.dispose();
    pinField.dispose();
    confirmField.dispose();
    super.onClose();
  }

  Future<void> createOwner() async {
    if (saving.value) return;
    final pin = pinField.text;
    if (nameField.text.trim().isEmpty) {
      error.value = 'Enter your name.';
      return;
    }
    if (!PinHasher.isValidPin(pin)) {
      error.value = 'The PIN must be ${PinHasher.pinLength} digits.';
      return;
    }
    if (pin != confirmField.text) {
      error.value = "The PINs don't match.";
      return;
    }
    saving.value = true;
    error.value = null;
    try {
      final owner = await _staff.create(
        name: nameField.text,
        role: StaffRole.owner,
        pin: pin,
      );
      _auth.signInAsNew(owner);
      await Get.offAllNamed<void>(Routes.till);
    } on StaffException catch (e) {
      error.value = e.message;
    } finally {
      saving.value = false;
    }
  }
}
