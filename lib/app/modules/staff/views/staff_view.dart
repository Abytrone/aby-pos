import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/staff.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/section_page.dart';
import '../../../ui/staff_avatar.dart';
import '../controllers/roles_controller.dart';
import '../controllers/staff_controller.dart';
import '../widgets/role_editor.dart';
import '../widgets/staff_form.dart';
import '../widgets/timesheets.dart';

/// Manage → Staff: people, and (with permission) roles.
class StaffView extends GetView<StaffController> {
  const StaffView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final withRoles = controller.canManageRoles;
    return DefaultTabController(
      length: withRoles ? 3 : 2,
      child: SectionPage(
        title: l.navStaff,
        actions: [
          FilledButton.icon(
            onPressed: () => _openStaffForm(title: l.staffAdd, withName: true, save: controller.addStaff),
            icon: const Icon(Icons.person_add_alt),
            label: Text(l.staffAdd),
          ),
          if (withRoles)
            OutlinedButton.icon(
              onPressed: () => _openRoleEditor(null),
              icon: const Icon(Icons.add),
              label: Text(l.rolesAdd),
            ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [Tab(text: l.staffPeople), Tab(text: l.timeTab), if (withRoles) Tab(text: l.staffRoles)],
        ),
        child: TabBarView(children: [_People(view: this), const TimesheetsTab(), if (withRoles) _Roles(view: this)]),
      ),
    );
  }

  Future<void> _openStaffForm({
    required String title,
    required bool withName,
    required Future<bool> Function() save,
  }) async {
    controller.resetForm();
    await Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(title),
        content: StaffForm(withName: withName),
        actions: [
          DialogButtons(children: [
                    OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
            Obx(() => FilledButton(
                  onPressed: controller.saving.value
                      ? null
                      : () async {
                          if (await save()) goBack<void>();
                        },
                  child: Text(l.commonSave),
                ),
                    ),
          ]),
        ],
      );
    }));
    _flush(controller.message);
  }

  Future<void> _openRoleEditor(Role? role) async {
    final roles = Get.find<RolesController>();
    roles.startEdit(role);
    await Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(role == null ? l.rolesAdd : roleName(l, role)),
        content: const RoleEditor(),
        actions: [
          DialogButtons(children: [
                    OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
            if (!roles.editingOwner)
              Obx(() => FilledButton(
                    onPressed: roles.saving.value
                        ? null
                        : () async {
                            if (await roles.save()) goBack<void>();
                          },
                    child: Text(l.commonSave),
                  ),
                      ),
          ]),
        ],
      );
    }));
    _flush(roles.message);
  }

  void _flush(RxnString message) {
    final text = message.value;
    if (text == null) return;
    message.value = null;
    showMessage(text);
  }
}

enum _PersonAction { changePin, changeRole, toggleActive }

class _People extends GetView<StaffController> {
  const _People({required this.view});

  final StaffView view;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final people = controller.staff.toList();
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: people.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final person = people[i];
          final isMe = person == controller.me;
          return InkWell(
            onTap: () => controller.openProfile(person),
            child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AbySize.tapPos + AbySpace.s4),
            child: Row(children: [
              StaffAvatar(staff: person, radius: 22),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isMe ? l.staffYou(person.name) : person.name,
                        style: AbyText.tile.copyWith(color: person.active ? c.ink : c.inkMuted)),
                    Text(
                      [
                        if (person.number != null) l.staffNumberLabel(person.number!),
                        person.active ? roleName(l, person.role) : l.staffDeactivatedRole(roleName(l, person.role)),
                      ].join(' · '),
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_PersonAction>(
                tooltip: l.commonMore,
                onSelected: (action) => _act(context, person, action),
                itemBuilder: (_) => [
                  PopupMenuItem(value: _PersonAction.changePin, child: Text(l.staffChangePin)),
                  if (!isMe && (!person.isOwner || controller.me.isOwner))
                    PopupMenuItem(value: _PersonAction.changeRole, child: Text(l.staffChangeRole)),
                  if (!isMe)
                    PopupMenuItem(
                      value: _PersonAction.toggleActive,
                      child: Text(person.active ? l.staffDeactivate : l.staffReactivate),
                    ),
                ],
              ),
            ]),
          ),
          );
        },
      );
    });
  }

  Future<void> _act(BuildContext context, Staff person, _PersonAction action) async {
    final l = context.l10n;
    switch (action) {
      case _PersonAction.changePin:
        await view._openStaffForm(
          title: l.staffNewPinFor(person.name),
          withName: false,
          save: () => controller.changePin(person),
        );
      case _PersonAction.changeRole:
        final role = await choiceDialog<Role>(
          title: l.staffChangeRoleFor(person.name),
          options: controller.assignableRoles,
          label: (r) => roleName(l, r),
          selected: person.role,
        );
        if (role != null) await controller.changeRole(person, role);
        view._flush(controller.message);
      case _PersonAction.toggleActive:
        if (person.active) {
          final ok = await confirmDialog(
            title: l.staffDeactivateTitle(person.name),
            message: l.staffDeactivateBody,
            confirmLabel: l.staffDeactivate,
            danger: true,
          );
          if (!ok) return;
        }
        await controller.setActive(person, active: !person.active);
        view._flush(controller.message);
    }
  }
}

class _Roles extends GetView<RolesController> {
  const _Roles({required this.view});

  final StaffView view;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final roles = controller.roles.toList();
      final counts = Map<String, int>.from(controller.counts);
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: roles.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final role = roles[i];
          final n = counts[role.id] ?? 0;
          return InkWell(
            onTap: () => view._openRoleEditor(role),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AbySize.tapPos + AbySpace.s4),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(roleName(l, role), style: AbyText.tile.copyWith(color: c.ink)),
                      Text(
                        [
                          l.rolesPeople(n),
                          role.isOwner ? l.rolesEverything : l.rolesPermissionCount(role.permissions.length),
                          if (role.builtIn != null) l.rolesBuiltIn,
                        ].join('  ·  '),
                        style: AbyText.caption.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (role.builtIn == null)
                  IconButton(
                    tooltip: l.rolesDelete,
                    icon: Icon(Icons.delete_outline, color: c.danger),
                    onPressed: () async {
                      final ok = await confirmDialog(
                        title: l.rolesDeleteTitle(role.name),
                        message: l.rolesDeleteBody,
                        confirmLabel: l.rolesDelete,
                        danger: true,
                      );
                      if (!ok) return;
                      await controller.delete(role);
                      view._flush(controller.message);
                    },
                  ),
                Icon(Icons.chevron_right, color: c.inkMuted),
              ]),
            ),
          );
        },
      );
    });
  }
}
