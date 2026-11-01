import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/l10n.dart';
import '../../../ui/staff_pin_entry.dart';
import '../controllers/shell_controller.dart';
import '../../../ui/dialogs.dart';

/// Hand the till to someone else without going back to the start screen.
/// The cart stays. The next person types their staff number and PIN; no
/// names are listed.
Future<void> showQuickSwitch(ShellController controller) async {
  var switched = false;
  await Get.dialog<void>(Builder(builder: (context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.userSwitchTitle),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: StaffPinEntry(
            onSubmit: (number, pin) async {
              final error = await controller.switchTo(number!, pin);
              if (error == null) {
                switched = true;
                goBack<void>();
              }
              return error;
            },
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        ]),
      ],
        );
  }));
  if (switched) await controller.offerClockIn();
}
