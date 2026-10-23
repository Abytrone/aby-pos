import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/repositories/staff_repository.dart';
import '../../../models/enums.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../services/pin_hasher.dart';

/// Owner-only: add staff, change PINs, deactivate.
class StaffController extends GetxController {
  final StaffRepository _staff = Get.find();
  final AuthService _auth = Get.find();

  final staff = <Staff>[].obs;
  final message = RxnString();

  // The open add / change-PIN form.
  final nameField = TextEditingController();
  final pinField = TextEditingController();
  final confirmField = TextEditingController();
  final newRole = StaffRole.cashier.obs;
  final formError = RxnString();
  final saving = false.obs;

  Staff get me => _auth.user;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    nameField.dispose();
    pinField.dispose();
    confirmField.dispose();
    super.onClose();
  }

  Future<void> load() async =>
      staff.assignAll(await _staff.list(includeInactive: true));

  void resetForm() {
    nameField.clear();
    pinField.clear();
    confirmField.clear();
    newRole.value = StaffRole.cashier;
    formError.value = null;
  }

  String? _pinProblem() {
    if (!PinHasher.isValidPin(pinField.text)) {
      return 'The PIN must be ${PinHasher.pinLength} digits.';
    }
    if (pinField.text != confirmField.text) return "The PINs don't match.";
    return null;
  }

  /// Returns true when saved (the view closes the form).
  Future<bool> addStaff() => _save(() async {
        final person = await _staff.create(
          name: nameField.text,
          role: newRole.value,
          pin: pinField.text,
        );
        message.value = '${person.name} added.';
      });

  Future<bool> changePin(Staff person) => _save(() async {
        await _staff.changePin(person.id, pinField.text);
        message.value = 'PIN changed for ${person.name}.';
      });

  Future<bool> _save(Future<void> Function() action) async {
    if (saving.value) return false;
    final problem = _pinProblem();
    if (problem != null) {
      formError.value = problem;
      return false;
    }
    saving.value = true;
    formError.value = null;
    try {
      await action();
      await load();
      return true;
    } on StaffException catch (e) {
      formError.value = e.message;
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<void> setActive(Staff person, {required bool active}) async {
    if (person == me && !active) {
      message.value = "You can't deactivate yourself.";
      return;
    }
    try {
      await _staff.setActive(person.id, active: active);
      message.value = active ? '${person.name} can sign in again.' : '${person.name} deactivated.';
      await load();
    } on StaffException catch (e) {
      message.value = e.message;
    }
  }
}
