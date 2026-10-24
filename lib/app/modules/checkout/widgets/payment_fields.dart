import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/checkout_controller.dart';

/// The fields for the chosen payment method.
class PaymentFields extends GetView<CheckoutController> {
  const PaymentFields({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final m = controller.selected.value;
      if (m == null) return const SizedBox.shrink();
      if (m.isCash) return const _CashFields();
      return Column(
        key: ValueKey(m.id),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (m.merchantNumber != null) _PayTo(name: m.name, number: m.merchantNumber!),
          TextField(
            controller: controller.amountField,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            decoration: InputDecoration(
              labelText: l.checkoutAmount,
              prefixText: 'GH₵ ',
              hintText: (controller.remaining / 100).toStringAsFixed(2),
              helperText: l.checkoutAmountHelp,
            ),
          ),
          if (m.needsReference) ...[
            const SizedBox(height: AbySpace.s3),
            TextField(
              controller: controller.referenceField,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l.checkoutReference(m.name),
                helperText: m.shortReference ? l.checkoutReferenceShort : l.checkoutReferenceHelp,
                helperMaxLines: 2,
              ),
            ),
          ],
          if (m.kind == PaymentMethod.credit) ...[
            const SizedBox(height: AbySpace.s3),
            TextField(
              controller: controller.customerField,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.checkoutCustomer, helperText: l.checkoutCustomerHelp),
            ),
          ],
        ],
      );
    });
  }
}

/// The shop's number, large, with a QR code the customer can scan.
class _PayTo extends StatelessWidget {
  const _PayTo({required this.name, required this.number});

  final String name;
  final String number;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AbySpace.s4),
      padding: const EdgeInsets.all(AbySpace.s4),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.md)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.l10n.checkoutPayTo(name).toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s1),
            SelectableText(number, style: AbyText.title.copyWith(color: c.ink)),
          ]),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(AbySpace.s1),
          child: QrImageView(data: number, size: 96, padding: EdgeInsets.zero),
        ),
      ]),
    );
  }
}

class _CashFields extends GetView<CheckoutController> {
  const _CashFields();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
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
          decoration: InputDecoration(labelText: l.checkoutCashGiven, prefixText: 'GH₵ '),
        ),
        const SizedBox(height: AbySpace.s3),
        Obx(() => Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              children: [
                for (final amount in controller.quickCash)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(96, AbySize.tapPos)),
                    onPressed: () => controller.setTendered(amount),
                    child: Text(amount == controller.cashDue ? l.checkoutExact : formatMoney(amount)),
                  ),
              ],
            )),
        Obx(() => controller.rounding == 0
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: AbySpace.s2),
                child: Text(
                  l.checkoutRounded(formatMoney(controller.cashDue), formatMoney(controller.rounding.abs())),
                  style: AbyText.caption.copyWith(color: c.inkMuted),
                ),
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
                  short ? l.checkoutStillToPay : l.checkoutChange,
                  style: AbyText.body.copyWith(color: short ? c.danger : c.inkMuted),
                ),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatMoney(short ? controller.cashDue - tendered : controller.changeDue),
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
