import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../services/pin_hasher.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../widgets/option_chip.dart';
import '../controllers/staff_controller.dart';

/// Dialog body for adding someone ([withName]) or changing a PIN.
class StaffForm extends GetView<StaffController> {
  const StaffForm({super.key, required this.withName});

  final bool withName;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final pinFormat = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(PinHasher.pinLength),
    ];
    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (withName) ...[
            TextField(
              controller: controller.nameField,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AbySpace.s4),
            Obx(() => Wrap(spacing: AbySpace.s2, children: [
                  for (final role in StaffRole.values)
                    OptionChip(
                      label: role.label,
                      selected: controller.newRole.value == role,
                      onTap: () => controller.newRole.value = role,
                    ),
                ])),
            const SizedBox(height: AbySpace.s4),
          ],
          TextField(
            controller: controller.pinField,
            autofocus: !withName,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: pinFormat,
            decoration: InputDecoration(labelText: withName ? 'PIN' : 'New PIN'),
          ),
          const SizedBox(height: AbySpace.s4),
          TextField(
            controller: controller.confirmField,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: pinFormat,
            decoration: const InputDecoration(labelText: 'PIN again'),
          ),
          Obx(() => Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(controller.formError.value ?? '',
                    style: AbyText.caption.copyWith(color: c.danger)),
              )),
        ],
      ),
    );
  }
}
