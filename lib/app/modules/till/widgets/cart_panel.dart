import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/tax.dart';
import '../../../models/cart_line.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/cart_controller.dart';

/// The current sale: lines with steppers, the subtotal and the Pay button.
class CartPanel extends StatelessWidget {
  const CartPanel({super.key, required this.onPay});

  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final c = Theme.of(context).extension<AbyColors>()!;
    return Obx(() {
      final lines = cart.lines.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AbySpace.s4, AbySpace.s3, AbySpace.s2, AbySpace.s2),
            child: Row(
              children: [
                Text('Current sale', style: AbyText.heading.copyWith(color: c.ink)),
                const Spacer(),
                if (lines.isNotEmpty)
                  TextButton(onPressed: cart.clear, child: const Text('Clear')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AbySpace.s6),
                      child: Text(
                        'Tap a product to add it.',
                        style: AbyText.body.copyWith(color: c.inkMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: AbySpace.s4),
                    itemBuilder: (_, i) => _CartLineRow(
                      line: lines[i],
                      onAdd: () => cart.increment(lines[i].key),
                      onSubtract: () => cart.decrement(lines[i].key),
                      onRemove: () => cart.remove(lines[i].key),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AbySpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (cart.taxTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AbySpace.s1),
                    child: Row(children: [
                      Text(
                        cart.taxMode == TaxMode.inclusive ? context.l10n.cartTaxIncluded : context.l10n.cartTax,
                        style: AbyText.caption.copyWith(color: c.inkMuted),
                      ),
                      const Spacer(),
                      Text(formatMoney(cart.taxTotal), style: AbyText.caption.copyWith(color: c.inkMuted)),
                    ]),
                  ),
                Row(
                  children: [
                    Text(context.l10n.cartTotal, style: AbyText.body.copyWith(color: c.inkMuted)),
                    const Spacer(),
                    Text(
                      formatMoney(cart.total),
                      style: AbyText.heading.copyWith(
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AbySpace.s3),
                AbyPayButton(
                  amount: toCedisForDisplay(cart.total),
                  onPressed: lines.isEmpty ? null : onPay,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.onAdd,
    required this.onSubtract,
    required this.onRemove,
  });

  final CartLine line;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s2, AbySpace.s1, AbySpace.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.title, style: AbyText.tile.copyWith(color: c.ink)),
                    if (line.options.isNotEmpty)
                      Text(
                        '+ ${line.optionsLine}',
                        style: AbyText.caption.copyWith(color: c.inkMuted),
                      ),
                    Text(
                      '${formatMoney(line.unitPrice)} each',
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: Icon(Icons.close, color: c.inkMuted),
                constraints: const BoxConstraints(
                  minWidth: AbySize.tapMin,
                  minHeight: AbySize.tapMin,
                ),
              ),
            ],
          ),
          const SizedBox(height: AbySpace.s1),
          Row(
            children: [
              _StepButton(icon: Icons.remove, tooltip: 'One less', onPressed: onSubtract),
              SizedBox(
                width: 44,
                child: Text(
                  '${line.quantity}',
                  textAlign: TextAlign.center,
                  style: AbyText.price.copyWith(color: c.ink),
                ),
              ),
              _StepButton(icon: Icons.add, tooltip: 'One more', onPressed: onAdd),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: AbySpace.s3),
                child: Text(
                  formatMoney(line.lineTotal),
                  style: AbyText.price.copyWith(color: c.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: c.ink),
      style: IconButton.styleFrom(
        minimumSize: const Size(AbySize.tapMin, AbySize.tapMin),
        side: BorderSide(color: c.lineStrong, width: 1.5),
      ),
    );
  }
}
