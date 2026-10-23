import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/option_chip.dart';
import '../controllers/till_controller.dart';

/// Pick a size and toppings, then add to the cart.
class VariantSheet extends GetView<TillController> {
  const VariantSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s6, AbySpace.s4, AbySpace.s6, AbySpace.s4),
        child: Obx(() {
          final product = controller.pickerProduct.value;
          if (product == null) return const SizedBox.shrink();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(product.name, style: AbyText.heading.copyWith(color: c.ink)),
              if (product.hasVariants) ...[
                const SizedBox(height: AbySpace.s4),
                Text('SIZE', style: AbyText.label.copyWith(color: c.inkMuted)),
                const SizedBox(height: AbySpace.s2),
                Wrap(
                  spacing: AbySpace.s2,
                  runSpacing: AbySpace.s2,
                  children: [
                    for (final v in product.variants)
                      OptionChip(
                        label: v.name,
                        trailing: formatMoney(v.price),
                        selected: controller.pickerVariant.value?.id == v.id,
                        onTap: () => controller.pickVariant(v),
                      ),
                  ],
                ),
              ],
              if (product.addons.isNotEmpty) ...[
                const SizedBox(height: AbySpace.s4),
                Text('TOPPINGS', style: AbyText.label.copyWith(color: c.inkMuted)),
                const SizedBox(height: AbySpace.s2),
                Wrap(
                  spacing: AbySpace.s2,
                  runSpacing: AbySpace.s2,
                  children: [
                    for (final a in product.addons)
                      OptionChip(
                        label: a.name,
                        trailing: '+${formatMoney(a.price)}',
                        selected: controller.isAddonPicked(a),
                        onTap: () => controller.toggleAddon(a),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AbySpace.s6),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back<void>(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AbySpace.s3),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        controller.confirmPick();
                        Get.back<void>();
                      },
                      child: Text('Add ${formatMoney(controller.pickerPrice)}'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
