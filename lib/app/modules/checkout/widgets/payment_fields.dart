import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../controllers/checkout_controller.dart';

/// The fields for the chosen payment method.
class PaymentFields extends GetView<CheckoutController> {
  const PaymentFields({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => switch (controller.method.value) {
          PaymentMethod.cash => const _CashFields(),
          PaymentMethod.momo => TextField(
              key: const ValueKey('momo'),
              controller: controller.momoField,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'MoMo transaction reference',
                helperText: 'Required. Copy it from the payment message.',
              ),
            ),
          PaymentMethod.credit => TextField(
              key: const ValueKey('credit'),
              controller: controller.customerField,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Customer name or phone',
                helperText: 'Written in the credit book for this sale.',
              ),
            ),
        });
  }
}

class _CashFields extends GetView<CheckoutController> {
  const _CashFields();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('cash'),
          controller: controller.tenderedField,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          textInputAction: TextInputAction.done,
          style: AbyText.heading.copyWith(color: c.ink),
          decoration: const InputDecoration(
            labelText: 'Cash given',
            prefixText: 'GH₵ ',
          ),
        ),
        const SizedBox(height: AbySpace.s3),
        Obx(() => Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              children: [
                for (final amount in controller.quickCash)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(96, AbySize.tapPos),
                    ),
                    onPressed: () => controller.setTendered(amount),
                    child: Text(amount == controller.total
                        ? 'Exact'
                        : formatMoney(amount)),
                  ),
              ],
            )),
        const SizedBox(height: AbySpace.s4),
        Obx(() {
          final tendered = controller.tendered;
          final short = tendered != null && controller.cashShort;
          return Container(
            padding: const EdgeInsets.all(AbySpace.s4),
            decoration: BoxDecoration(
              color: short ? c.dangerSoft : c.surfaceSunken,
              borderRadius: BorderRadius.circular(AbyRadius.md),
            ),
            child: Row(
              children: [
                Text(
                  short ? 'Still to pay' : 'Change due',
                  style: AbyText.body.copyWith(color: short ? c.danger : c.inkMuted),
                ),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatMoney(short ? controller.total - tendered : controller.changeDue),
                      style: AbyText.title.copyWith(
                        color: short ? c.danger : c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
