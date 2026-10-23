import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/catalog.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../controllers/till_controller.dart';

/// "Pick 1", "Up to 3", "Pick 1 to 2", "Optional".
String groupRule(AppLocalizations l, OptionGroup g) {
  final max = g.maxSelect;
  if (g.minSelect > 0 && max == g.minSelect) return l.groupPickExactly(g.minSelect);
  if (g.minSelect > 0 && max != null) return l.groupPickBetween(g.minSelect, max);
  if (g.minSelect > 0) return l.groupPickAtLeast(g.minSelect);
  if (max != null) return l.groupUpTo(max);
  return l.groupOptional;
}

/// Pick a size and options, then add to the cart.
class VariantSheet extends GetView<TillController> {
  const VariantSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AbySpace.s6, AbySpace.s4, AbySpace.s6, AbySpace.s4),
          child: Obx(() {
            final product = controller.pickerProduct.value;
            if (product == null) return const SizedBox.shrink();
            final picked = controller.pickerOptions.toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(product.name, style: AbyText.heading.copyWith(color: c.ink)),
                if (product.variants.length > 1) ...[
                  const SizedBox(height: AbySpace.s4),
                  Text(l.pickerSize.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s2),
                  Wrap(
                    spacing: AbySpace.s2,
                    runSpacing: AbySpace.s2,
                    children: [
                      for (final v in product.variants)
                        OptionChip(
                          label: v.name ?? product.name,
                          trailing: formatMoney(v.price),
                          selected: controller.pickerVariant.value?.id == v.id,
                          onTap: () => controller.pickVariant(v),
                        ),
                    ],
                  ),
                ],
                for (final g in product.groups) ...[
                  const SizedBox(height: AbySpace.s4),
                  Row(children: [
                    Text(g.name.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                    const SizedBox(width: AbySpace.s2),
                    Text(
                      groupRule(l, g),
                      style: AbyText.caption.copyWith(
                        color: g.accepts(picked.where((o) => o.groupId == g.id).length) ? c.inkMuted : c.danger,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AbySpace.s2),
                  Wrap(
                    spacing: AbySpace.s2,
                    runSpacing: AbySpace.s2,
                    children: [
                      for (final o in g.options)
                        _OptionPick(
                          option: o,
                          count: picked.where((p) => p.id == o.id).length,
                          canRemoveOne: g.allowRepeat,
                          onTap: () => controller.tapOption(g, o),
                          onRemove: () => controller.removeOneOption(o),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AbySpace.s6),
                Row(
                  children: [
                    OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
                    const SizedBox(width: AbySpace.s3),
                    Expanded(
                      child: FilledButton(
                        onPressed: controller.pickerValid
                            ? () {
                                controller.confirmPick();
                                Get.back<void>();
                              }
                            : null,
                        child: Text(l.pickerAdd(formatMoney(controller.pickerPrice))),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _OptionPick extends StatelessWidget {
  const _OptionPick({
    required this.option,
    required this.count,
    required this.canRemoveOne,
    required this.onTap,
    required this.onRemove,
  });

  final Option option;
  final int count;
  final bool canRemoveOne;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final chip = OptionChip(
      label: count > 1 ? '${option.name} ×$count' : option.name,
      trailing: option.priceDelta == 0 ? null : '+${formatMoney(option.priceDelta)}',
      selected: count > 0,
      onTap: onTap,
    );
    if (!canRemoveOne || count == 0) return chip;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      chip,
      IconButton(
        tooltip: context.l10n.pickerRemoveOne,
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle_outline),
      ),
    ]);
  }
}
