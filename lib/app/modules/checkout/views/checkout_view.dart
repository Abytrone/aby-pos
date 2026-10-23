import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../widgets/option_chip.dart';
import '../controllers/checkout_controller.dart';
import '../widgets/payment_fields.dart';
import '../widgets/sale_complete.dart';

/// Checkout as a sheet over the till: a side panel on wide screens, a
/// bottom sheet on phones.
class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.close();
      },
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= 840;
          final panel = Container(
            width: wide ? 480 : double.infinity,
            height: wide ? constraints.maxHeight : null,
            constraints: BoxConstraints(
              maxHeight: wide ? double.infinity : constraints.maxHeight * 0.92,
            ),
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: wide
                  ? const BorderRadius.horizontal(left: Radius.circular(AbyRadius.lg))
                  : const BorderRadius.vertical(top: Radius.circular(AbyRadius.lg)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AbySpace.s6),
                child: Obx(() {
                  final done = controller.completed.value;
                  if (done != null) {
                    return SaleComplete(sale: done, onNewSale: controller.close);
                  }
                  return const _PaymentForm();
                }),
              ),
            ),
          );
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: controller.close,
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
                ),
              ),
              Align(
                alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: panel,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _PaymentForm extends GetView<CheckoutController> {
  const _PaymentForm();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Payment', style: AbyText.heading.copyWith(color: c.ink)),
            const Spacer(),
            IconButton(
              tooltip: 'Back to the till',
              onPressed: controller.close,
              icon: Icon(Icons.close, color: c.inkMuted),
              constraints: const BoxConstraints(
                minWidth: AbySize.tapMin,
                minHeight: AbySize.tapMin,
              ),
            ),
          ],
        ),
        Text('TOTAL', style: AbyText.label.copyWith(color: c.inkMuted)),
        Obx(() => Text(
              formatMoney(controller.total),
              style: AbyText.total.copyWith(color: c.ink),
            )),
        const SizedBox(height: AbySpace.s6),
        Obx(() => Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              children: [
                for (final m in PaymentMethod.values)
                  OptionChip(
                    label: m.label,
                    selected: controller.method.value == m,
                    onTap: () => controller.selectMethod(m),
                  ),
              ],
            )),
        const SizedBox(height: AbySpace.s6),
        const PaymentFields(),
        Obx(() {
          final message = controller.error.value;
          if (message == null) return const SizedBox(height: AbySpace.s6);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AbySpace.s4),
            child: Text(message, style: AbyText.body.copyWith(color: c.danger)),
          );
        }),
        Obx(() => FilledButton(
              onPressed: controller.canComplete ? controller.complete : null,
              child: controller.saving.value
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : const Text('Complete sale'),
            )),
      ],
    );
  }
}
