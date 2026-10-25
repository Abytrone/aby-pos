import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../ui/customer_picker.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
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
                  padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
    final l = context.l10n;
    return Obx(() {
      final remaining = controller.remaining;
      final taken = controller.taken.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l.checkoutTitle, style: AbyText.heading.copyWith(color: c.ink)),
              const Spacer(),
              IconButton(
                tooltip: l.checkoutBack,
                onPressed: controller.close,
                icon: Icon(Icons.close, color: c.inkMuted),
                constraints: const BoxConstraints(minWidth: AbySize.tapMin, minHeight: AbySize.tapMin),
              ),
            ],
          ),
          if (controller.customer != null)
            Text(
              [
                controller.customer!.name,
                if (controller.customer!.owed > 0) l.customerOwes(formatMoney(controller.customer!.owed)),
                if (controller.customer!.wallet > 0) l.customerWallet(formatMoney(controller.customer!.wallet)),
              ].join('  ·  '),
              style: AbyText.body.copyWith(color: c.inkMuted),
            ),
          Text(l.cartTotal.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          Text(formatMoney(controller.total), style: AbyText.total.copyWith(color: c.ink)),
          if (controller.credit > 0)
            _Line(label: l.checkoutReturned, value: '−${formatMoney(controller.fromExchange)}', color: c.success),
          for (final (i, p) in taken.indexed)
            _Line(
              label: p.label,
              value: formatMoney(p.amount ?? 0),
              onRemove: () => controller.removeTaken(i),
            ),
          if (controller.credit > 0 || taken.isNotEmpty)
            _Line(label: l.checkoutLeftToPay, value: formatMoney(remaining > 0 ? remaining : 0), strong: true),
          const SizedBox(height: AbySpace.s4),
          if (remaining > 0) ...[
            Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              children: [
                for (final m in controller.methods)
                  OptionChip(
                    label: m.name,
                    selected: controller.selected.value?.id == m.id,
                    onTap: () => controller.select(m),
                  ),
              ],
            ),
            const SizedBox(height: AbySpace.s4),
            if (controller.needsCustomer && controller.customer == null)
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await pickCustomer();
                  if (picked != null) controller.cart.customer.value = picked;
                },
                icon: const Icon(Icons.person_search),
                label: Text(l.checkoutChooseCustomer),
              )
            else
              const PaymentFields(),
          ],
          if (controller.owedBack > 0) ...[
            const SizedBox(height: AbySpace.s4),
            Text(l.checkoutGiveBack(formatMoney(controller.owedBack)), style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final m in controller.methods.where((m) => m.kind != PaymentMethod.credit))
                OptionChip(
                  label: m.name,
                  selected: controller.payBack.value?.id == m.id,
                  onTap: () => controller.payBack.value = m,
                ),
            ]),
          ],
          if (controller.error.value != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AbySpace.s4),
              child: Text(controller.error.value!, style: AbyText.body.copyWith(color: c.danger)),
            )
          else
            const SizedBox(height: AbySpace.s6),
          if (controller.canTakePart) ...[
            OutlinedButton(
              onPressed: controller.takePart,
              child: Text(l.checkoutTakePart(
                formatMoney(controller.isCash ? controller.tendered! : controller.amount!),
              )),
            ),
            const SizedBox(height: AbySpace.s2),
          ],
          FilledButton(
            onPressed: controller.canComplete ? controller.complete : null,
            child: controller.saving.value
                ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
                : Text(l.checkoutComplete),
          ),
        ],
      );
    });
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value, this.color, this.strong = false, this.onRemove});

  final String label;
  final String value;
  final Color? color;
  final bool strong;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final style = (strong ? AbyText.heading : AbyText.body).copyWith(color: color ?? c.ink);
    return Padding(
      padding: const EdgeInsets.only(top: AbySpace.s1),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        if (onRemove != null)
          IconButton(
            tooltip: context.l10n.checkoutRemovePayment,
            onPressed: onRemove,
            icon: Icon(Icons.close, size: 18, color: c.inkMuted),
          ),
      ]),
    );
  }
}
