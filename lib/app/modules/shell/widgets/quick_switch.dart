import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/staff.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/pin_pad.dart';
import '../../../ui/staff_avatar.dart';
import '../controllers/shell_controller.dart';
import '../../../ui/dialogs.dart';

/// Hand the till to someone else without going back to the start screen.
/// The cart stays.
Future<void> showQuickSwitch(ShellController controller) async {
  final people = await controller.switchCandidates();
  final selected = Rxn<Staff>(people.length == 1 ? people.first : null);
  await Get.dialog<void>(Builder(builder: (context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.userSwitchTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Obx(() {
            final person = selected.value;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (people.isEmpty) Text(l.userSwitchNobody),
                Wrap(
                  spacing: AbySpace.s2,
                  runSpacing: AbySpace.s2,
                  children: [
                    for (final p in people)
                      OptionChip(
                        leading: StaffAvatar(staff: p, radius: 14),
                        label: p.name,
                        trailing: roleName(l, p.role),
                        selected: person == p,
                        onTap: () => selected.value = p,
                      ),
                  ],
                ),
                if (person != null) ...[
                  const SizedBox(height: AbySpace.s4),
                  PinPad(
                    key: ValueKey(person.id),
                    title: l.pinFor(person.name),
                    onSubmit: (pin) async {
                      final error = await controller.switchTo(person, pin);
                      if (error == null) goBack<void>();
                      return error;
                    },
                  ),
                ],
              ],
            );
          }),
        ),
      ),
      actions: [
        DialogButtons(children: [OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        ]),
      ],
        );
  }));
}
