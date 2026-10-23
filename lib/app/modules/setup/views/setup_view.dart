import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../services/pin_hasher.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../controllers/setup_controller.dart';

class SetupView extends GetView<SetupController> {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final pinFormat = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(PinHasher.pinLength),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AbySpace.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AbyMark(size: 56)),
                  const SizedBox(height: AbySpace.s4),
                  Text('Set up ${controller.shopName}',
                      textAlign: TextAlign.center,
                      style: AbyText.title.copyWith(color: c.ink)),
                  const SizedBox(height: AbySpace.s2),
                  Text(
                    "You're the owner. Pick a ${PinHasher.pinLength}-digit PIN to "
                    'sign in and to approve voids. You can add cashiers later.',
                    textAlign: TextAlign.center,
                    style: AbyText.body.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: AbySpace.s6),
                  TextField(
                    controller: controller.nameField,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Your name'),
                  ),
                  const SizedBox(height: AbySpace.s4),
                  TextField(
                    controller: controller.pinField,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: pinFormat,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'PIN'),
                  ),
                  const SizedBox(height: AbySpace.s4),
                  TextField(
                    controller: controller.confirmField,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: pinFormat,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.createOwner(),
                    decoration: const InputDecoration(labelText: 'PIN again'),
                  ),
                  Obx(() => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AbySpace.s4),
                        child: Text(controller.error.value ?? '',
                            style: AbyText.body.copyWith(color: c.danger)),
                      )),
                  Obx(() => FilledButton(
                        onPressed: controller.saving.value ? null : controller.createOwner,
                        child: const Text('Create owner and start'),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
