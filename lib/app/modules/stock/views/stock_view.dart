import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/stock_controller.dart';
import '../widgets/stock_item_editor.dart';

/// Manage → Stock.
class StockView extends GetView<StockController> {
  const StockView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    String filterLabel(StockFilter f) => switch (f) {
          StockFilter.all => l.stockFilterAll,
          StockFilter.low => l.stockFilterLow(controller.lowCount),
          StockFilter.retired => l.stockFilterRetired,
        };
    return SectionPage(
      title: l.navStock,
      actions: [
        if (controller.canEdit)
          FilledButton.icon(
            onPressed: () => showStockItemEditor(onSave: controller.saveItem).then((_) => _flush()),
            icon: const Icon(Icons.add),
            label: Text(l.stockNew),
          ),
      ],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
        child: Obx(() => Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    onChanged: (v) => controller.query.value = v,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: l.stockSearch,
                      isDense: true,
                    ),
                  ),
                ),
                for (final f in StockFilter.values)
                  ChoiceChip(
                    label: Text(filterLabel(f)),
                    selected: controller.filter.value == f,
                    onSelected: (_) => controller.filter.value = f,
                  ),
                if (controller.canSeeCost)
                  Text(l.stockTotalValue(formatMoney(controller.totalValue)),
                      style: AbyText.caption.copyWith(color: c.inkMuted, fontWeight: FontWeight.w700)),
              ],
            )),
      ),
      child: Obx(() {
        if (controller.loading.value) return const Center(child: CircularProgressIndicator());
        final items = controller.visible;
        if (items.isEmpty) return EmptyState(icon: Icons.inventory_2_outlined, message: l.stockNone);
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s8),
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _Row(item: items[i], showCost: controller.canSeeCost, onTap: () => controller.openItem(items[i])),
        );
      }),
    );
  }

  void _flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.showCost, required this.onTap});

  final StockItem item;
  final bool showCost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final negative = item.onHand < 0;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(item.name,
                  style: AbyText.body.copyWith(color: item.active ? c.ink : c.inkMuted, fontWeight: FontWeight.w700)),
              Text(
                [
                  unitLabel(l, item.unit),
                  if (showCost) l.stockCostEach(formatMoney(item.bulkPrice), DisplayUnit.bulk(item.unit).symbol),
                ].join('  ·  '),
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
            ]),
          ),
          if (item.isLow && item.active)
            Container(
              margin: const EdgeInsets.only(right: AbySpace.s3),
              padding: const EdgeInsets.symmetric(horizontal: AbySpace.s2, vertical: 2),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(999)),
              child: Text(l.stockLow, style: AbyText.label.copyWith(color: c.warning)),
            ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(item.onHandText,
                style: AbyText.price.copyWith(color: negative ? c.danger : c.ink)),
            if (showCost) Text(formatMoney(item.value), style: AbyText.caption.copyWith(color: c.inkMuted)),
          ]),
          const SizedBox(width: AbySpace.s2),
          Icon(Icons.chevron_right, color: c.inkMuted),
        ]),
      ),
    );
  }
}
