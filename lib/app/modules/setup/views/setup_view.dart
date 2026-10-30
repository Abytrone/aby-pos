import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../domain/business_templates.dart';
import '../../../services/pin_hasher.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../controllers/setup_controller.dart';

class SetupView extends GetView<SetupController> {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AbyMark(size: 56)),
                  const SizedBox(height: AbySpace.s4),
                  Text(l.setupTitle,
                      textAlign: TextAlign.center,
                      style: AbyText.title.copyWith(color: c.ink)),
                  const SizedBox(height: AbySpace.s2),
                  Text(
                    l.setupIntro(PinHasher.pinLength),
                    textAlign: TextAlign.center,
                    style: AbyText.body.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(height: AbySpace.s6),
                  Text(l.setupShopType, style: AbyText.label.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s2),
                  Obx(() => Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                        for (final t in BusinessType.values)
                          OptionChip(
                            label: businessTypeLabel(l, t),
                            selected: controller.type.value == t,
                            onTap: () => controller.pickType(t),
                          ),
                      ])),
                  const SizedBox(height: AbySpace.s4),
                  TextField(
                    controller: controller.shopField,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l.setupShopName),
                  ),
                  const SizedBox(height: AbySpace.s4),
                  TextField(
                    controller: controller.nameField,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l.setupYourName),
                  ),
                  const SizedBox(height: AbySpace.s4),
                  TextField(
                    controller: controller.pinField,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: pinFormat,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l.pinLabel),
                  ),
                  const SizedBox(height: AbySpace.s4),
                  TextField(
                    controller: controller.confirmField,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: pinFormat,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => controller.createOwner(),
                    decoration: InputDecoration(labelText: l.pinAgainLabel),
                  ),
                  Obx(() => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AbySpace.s4),
                        child: Text(controller.error.value ?? '',
                            style: AbyText.body.copyWith(color: c.danger)),
                      )),
                  Obx(() => FilledButton(
                        onPressed: controller.saving.value ? null : controller.createOwner,
                        child: Text(l.setupCreateOwner),
                      )),
                  const SizedBox(height: AbySpace.s6),
                  const Divider(),
                  const SizedBox(height: AbySpace.s3),
                  Text(l.setupJoinHelp,
                      textAlign: TextAlign.center,
                      style: AbyText.body.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s2),
                  Obx(() => OutlinedButton.icon(
                        onPressed: controller.saving.value ? null : controller.joinHub,
                        icon: const Icon(Icons.hub_outlined),
                        label: Text(controller.joined ? l.setupJoinRetry : l.setupJoinHub),
                      )),
                  const SizedBox(height: AbySpace.s4),
                  Text(l.setupMovingDevice,
                      textAlign: TextAlign.center,
                      style: AbyText.body.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s2),
                  OutlinedButton.icon(
                    onPressed: controller.restore,
                    icon: const Icon(Icons.settings_backup_restore),
                    label: Text(l.setupRestore),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String businessTypeLabel(AppLocalizations l, BusinessType t) => switch (t) {
      BusinessType.iceCream => l.shopTypeIceCream,
      BusinessType.provision => l.shopTypeProvision,
      BusinessType.chopBar => l.shopTypeChopBar,
      BusinessType.pharmacy => l.shopTypePharmacy,
      BusinessType.salon => l.shopTypeSalon,
      BusinessType.phones => l.shopTypePhones,
      BusinessType.boutique => l.shopTypeBoutique,
      BusinessType.building => l.shopTypeBuilding,
      BusinessType.other => l.shopTypeOther,
    };
