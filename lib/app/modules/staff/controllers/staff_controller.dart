import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/role_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/pin_hasher.dart';
import '../../../ui/l10n.dart';

/// People: add staff, change PINs and roles, deactivate.
class StaffController extends GetxController {
  final StaffRepository _staff = Get.find();
  final RoleRepository _roles = Get.find();
  final AuthService _auth = Get.find();

  final staff = <Staff>[].obs;
  final roles = <Role>[].obs;
  final message = RxnString();

  // The open add / change-PIN form.
  final nameField = TextEditingController();
  final pinField = TextEditingController();
  final confirmField = TextEditingController();
  final newRole = Rxn<Role>();
  final formError = RxnString();
  final saving = false.obs;

  Staff get me => _auth.user;
  bool get canManageRoles => _auth.can(Permission.manageRoles);

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

  Future<void> openProfile(Staff person) async {
    await Get.toNamed<void>(Routes.staffProfile, arguments: person.id);
    await load();
  }

  Future<void> load() async {
    roles.assignAll(await _roles.list());
    staff.assignAll(await _staff.list(includeInactive: true));
  }

  /// Only owners can make someone an owner.
  List<Role> get assignableRoles => [
        for (final r in roles)
          if (!r.isOwner || me.isOwner) r,
      ];

  void resetForm() {
    nameField.clear();
    pinField.clear();
    confirmField.clear();
    newRole.value = roles.firstWhereOrNull((r) => r.builtIn == BuiltInRole.cashier);
    formError.value = null;
  }

  String? _pinProblem() {
    final l = appL10n();
    if (!PinHasher.isValidPin(pinField.text)) return l.pinMustBeDigits(PinHasher.pinLength);
    if (pinField.text != confirmField.text) return l.pinMismatch;
    return null;
  }

  /// Returns true when saved (the view closes the form).
  Future<bool> addStaff() => _save(() async {
        final role = newRole.value;
        if (role == null) throw StaffException(appL10n().staffPickRole);
        final person = await _staff.create(
          name: nameField.text,
          roleId: role.id,
          pin: pinField.text,
          by: me,
        );
        message.value = appL10n().staffAdded(person.name, person.number ?? '');
      });

  Future<bool> changePin(Staff person) => _save(() async {
        await _staff.changePin(person.id, pinField.text, by: me);
        message.value = appL10n().staffPinChanged(person.name);
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

  Future<void> changeRole(Staff person, Role role) async {
    try {
      await _staff.changeRole(person.id, role.id, by: me);
      message.value = appL10n().staffRoleChanged(person.name);
      await load();
    } on StaffException catch (e) {
      message.value = e.message;
    }
  }

  Future<void> setActive(Staff person, {required bool active}) async {
    final l = appL10n();
    if (person == me && !active) {
      message.value = l.staffCantDeactivateSelf;
      return;
    }
    try {
      await _staff.setActive(person.id, active: active, by: me);
      message.value = active ? l.staffReactivated(person.name) : l.staffDeactivated(person.name);
      await load();
    } on StaffException catch (e) {
      message.value = e.message;
    }
  }
}
