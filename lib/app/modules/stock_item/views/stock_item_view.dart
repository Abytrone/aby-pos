import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/enums.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/section_page.dart';
import '../../stock/widgets/stock_item_editor.dart';
import '../controllers/stock_item_controller.dart';
import '../widgets/production.dart';
import '../widgets/quantity_dialog.dart';

String reasonLabel(AppLocalizations l, StockMovement m) => switch (m.reason) {
      StockReason.sale => l.moveSale,
      StockReason.restock => l.moveReceived,
      StockReason.waste => l.moveWaste(wasteLabel(l, WasteReason.values.byName(m.subReason ?? 'other'))),
      StockReason.adjustment => l.moveAdjustment,
      StockReason.count => l.moveCount,
      StockReason.returned => l.moveReturned,
      StockReason.production => l.moveProduction,
    };

String wasteLabel(AppLocalizations l, WasteReason r) => switch (r) {
      WasteReason.melted => l.wasteMelted,
      WasteReason.powerCut => l.wastePowerCut,
      WasteReason.expired => l.wasteExpired,
      WasteReason.damaged => l.wasteDamaged,
      WasteReason.staffMeal => l.wasteStaffMeal,
      WasteReason.sample => l.wasteSample,
      WasteReason.other => l.wasteOther,
    };

class StockItemView extends GetView<StockItemController> {
  const StockItemView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.item.value?.name ?? '')),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
      ),
      body: Obx(() {
        final item = controller.item.value;
        if (item == null) return const Center(child: CircularProgressIndicator());
        final moves = controller.movements.toList();
        final used = controller.usedBy.toList();
        final summary = _Summary(item: item, usedBy: used, view: this);
        final history = GroupCard(
          title: l.stockHistory,
          children: moves.isEmpty
              ? [InfoTile(title: l.stockNoMovements)]
              : [
                  for (final m in moves)
                    InfoTile(
                      title: reasonLabel(l, m),
                      subtitle: [formatDateTime(m.at), ?m.byName, ?m.note].join('  ·  '),
                      value: '${m.quantityChange > 0 ? '+' : ''}${formatQuantity(m.quantityChange, item.unit)}',
                    ),
                ],
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: context.isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 340, child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: summary)),
                    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: history)),
                  ])
                : ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [summary, const SizedBox(height: AbySpace.s4), history]),
          ),
        );
      }),
    );
  }

  void flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}

class _Summary extends GetView<StockItemController> {
  const _Summary({required this.item, required this.usedBy, required this.view});

  final StockItem item;
  final List<String> usedBy;
  final StockItemView view;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final bulk = DisplayUnit.bulk(item.unit);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AbySpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.stockOnHand.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            Text(item.onHandText, style: AbyText.title.copyWith(color: item.onHand < 0 ? c.danger : c.ink)),
            if (controller.canSeeCost)
              Text(l.stockWorth(formatMoney(item.value), formatMoney(item.bulkPrice), bulk.symbol),
                  style: AbyText.caption.copyWith(color: c.inkMuted)),
            if (item.reorderPoint != null)
              Text(
                l.stockReorderLine(formatQuantity(item.reorderPoint!, item.unit)),
                style: AbyText.caption.copyWith(color: item.isLow ? c.warning : c.inkMuted, fontWeight: FontWeight.w700),
              ),
            if (!item.active) Text(l.stockFilterRetired, style: AbyText.caption.copyWith(color: c.danger)),
          ]),
        ),
      ),
      const SizedBox(height: AbySpace.s3),
      if (controller.canEdit) ...[
        FilledButton.icon(
          onPressed: () async {
            await showQuantityDialog(context, item: item, mode: QuantityMode.waste);
            view.flush();
          },
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(l.stockLogWaste),
        ),
        const SizedBox(height: AbySpace.s2),
        OutlinedButton.icon(
          onPressed: () async {
            await showQuantityDialog(context, item: item, mode: QuantityMode.adjust);
            view.flush();
          },
          icon: const Icon(Icons.tune),
          label: Text(l.stockAdjust),
        ),
        const SizedBox(height: AbySpace.s2),
        OutlinedButton.icon(
          onPressed: () async {
            await showStockItemEditor(item: item, onSave: controller.save);
            view.flush();
          },
          icon: const Icon(Icons.edit_outlined),
          label: Text(l.stockEdit),
        ),
        TextButton(
          onPressed: () => controller.setActive(!item.active),
          child: Text(item.active ? l.stockRetire : l.stockRestore),
        ),
      ],
      const SizedBox(height: AbySpace.s3),
      Obx(() {
        final used = controller.used28.value;
        final suggestion = controller.suggestedLowLevel;
        final days = controller.daysLeft;
        return GroupCard(title: l.stockUsage, children: [
          InfoTile(
            title: l.stockUsePerDay,
            value: used == 0 ? l.stockNotUsed : formatQuantity((used / 28).ceil(), item.unit),
          ),
          if (days != null) InfoTile(title: l.stockLasts, value: l.settingsDays(days.floor())),
          if (suggestion != null)
            InfoTile(
              title: l.stockSuggestedLow,
              subtitle: l.stockSuggestedHelp,
              value: formatQuantity(suggestion, item.unit),
              trailing: controller.canEdit && suggestion != item.reorderPoint
                  ? TextButton(onPressed: controller.useSuggestion, child: Text(l.stockUseThis))
                  : null,
            ),
        ]);
      }),
      GroupCard(
        title: l.stockUsedBy,
        children: usedBy.isEmpty ? [InfoTile(title: l.stockUsedByNone)] : [for (final n in usedBy) InfoTile(title: n)],
      ),
      const SizedBox(height: AbySpace.s3),
      ProductionCard(item: item),
      if (item.tracksExpiry || controller.batches.isNotEmpty) ...[
        const SizedBox(height: AbySpace.s3),
        const BatchesCard(),
      ],
    ]);
  }
}
