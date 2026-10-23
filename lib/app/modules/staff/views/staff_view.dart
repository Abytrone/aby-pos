import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/staff.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../controllers/staff_controller.dart';
import '../widgets/staff_form.dart';

class StaffView extends GetView<StaffController> {
  const StaffView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AbySpace.s4),
            child: FilledButton(
              onPressed: () => _openForm(title: 'Add staff', withName: true, save: controller.addStaff),
              child: const Text('Add staff'),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final people = controller.staff.toList();
        return ListView.separated(
          padding: const EdgeInsets.all(AbySpace.s4),
          itemCount: people.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _StaffRow(
            person: people[i],
            isMe: people[i] == controller.me,
            onChangePin: () => _openForm(
              title: 'New PIN for ${people[i].name}',
              withName: false,
              save: () => controller.changePin(people[i]),
            ),
            onToggle: () async {
              await controller.setActive(people[i], active: !people[i].active);
              _showMessage();
            },
          ),
        );
      }),
    );
  }

  Future<void> _openForm({
    required String title,
    required bool withName,
    required Future<bool> Function() save,
  }) async {
    controller.resetForm();
    await Get.dialog<void>(AlertDialog(
      title: Text(title),
      content: StaffForm(withName: withName),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: const Text('Cancel')),
        Obx(() => FilledButton(
              onPressed: controller.saving.value
                  ? null
                  : () async {
                      if (await save()) Get.back<void>();
                    },
              child: const Text('Save'),
            )),
      ],
    ));
    _showMessage();
  }

  void _showMessage() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    Get.showSnackbar(GetSnackBar(message: text, duration: const Duration(seconds: 3)));
  }
}

class _StaffRow extends StatelessWidget {
  const _StaffRow({
    required this.person,
    required this.isMe,
    required this.onChangePin,
    required this.onToggle,
  });

  final Staff person;
  final bool isMe;
  final VoidCallback onChangePin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AbySize.tapPos + AbySpace.s4),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${person.name}${isMe ? ' (you)' : ''}',
                  style: AbyText.tile.copyWith(color: person.active ? c.ink : c.inkMuted)),
              Text(person.active ? person.role.label : '${person.role.label}, deactivated',
                  style: AbyText.caption.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
        TextButton(onPressed: onChangePin, child: const Text('Change PIN')),
        if (!isMe)
          TextButton(
            onPressed: onToggle,
            style: person.active ? TextButton.styleFrom(foregroundColor: c.danger) : null,
            child: Text(person.active ? 'Deactivate' : 'Reactivate'),
          ),
      ]),
    );
  }
}
