import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/role_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../ui/l10n.dart';
import 'staff_controller.dart';

/// Roles: what each kind of staff member may do.
class RolesController extends GetxController {
  final RoleRepository _roles = Get.find();
  final AuthService _auth = Get.find();

  final roles = <Role>[].obs;
  final counts = <String, int>{}.obs;
  final message = RxnString();

  // The open editor. Null [editing] with an open editor means a new role.
  final editing = Rxn<Role>();
  final nameField = TextEditingController();
  final permissions = <Permission>{}.obs;
  final maxDiscount = 0.obs;
  final formError = RxnString();
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    nameField.dispose();
    super.onClose();
  }

  Future<void> load() async {
    roles.assignAll(await _roles.list());
    counts.assignAll(await _roles.staffCounts());
  }

  void startEdit(Role? role) {
    editing.value = role;
    nameField.text = role == null ? '' : role.name;
    permissions.assignAll(role?.permissions ?? {Permission.sell});
    maxDiscount.value = role?.maxDiscountPercent ?? 0;
    formError.value = null;
  }

  bool get editingOwner => editing.value?.isOwner ?? false;

  void toggle(Permission p, bool on) => on ? permissions.add(p) : permissions.remove(p);

  /// Returns true when saved.
  Future<bool> save() async {
    if (saving.value || editingOwner) return false;
    // No one can hand out more than they have (only owners have it all).
    final me = _auth.user;
    if (!me.isOwner && !me.role.permissions.containsAll(permissions)) {
      formError.value = appL10n().rolesCannotGrant;
      return false;
    }
    saving.value = true;
    formError.value = null;
    try {
      final role = editing.value;
      if (role == null) {
        await _roles.create(
          name: nameField.text,
          permissions: permissions.toSet(),
          maxDiscountPercent: maxDiscount.value,
          by: _auth.user,
        );
      } else {
        await _roles.update(
          role.id,
          name: nameField.text,
          permissions: permissions.toSet(),
          maxDiscountPercent: maxDiscount.value,
          by: _auth.user,
        );
      }
      message.value = appL10n().rolesSaved;
      await _afterChange();
      return true;
    } on StaffException catch (e) {
      formError.value = e.message;
      return false;
    } finally {
      saving.value = false;
    }
  }

  Future<void> delete(Role role) async {
    try {
      await _roles.delete(role.id, by: _auth.user);
      message.value = appL10n().rolesDeleted(role.name);
      await _afterChange();
    } on StaffException catch (e) {
      message.value = e.message;
    }
  }

  /// Role changes affect the people list and, possibly, the signed-in
  /// person's own permissions.
  Future<void> _afterChange() async {
    await load();
    if (Get.isRegistered<StaffController>()) await Get.find<StaffController>().load();
    final me = _auth.currentUser.value;
    if (me != null) {
      final updated = await Get.find<StaffRepository>().find(me.id);
      if (updated != null) _auth.currentUser.value = updated;
    }
  }
}
