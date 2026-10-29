import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/stock_repository.dart';
import '../../../core/units.dart';
import '../../../models/stock.dart';
import '../../../services/branch_service.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/purchasing_controller.dart';
import '../controllers/stock_controller.dart';
import '../widgets/purchase_orders_tab.dart';
import '../widgets/purchasing_tabs.dart';
import '../widgets/supplier_editor.dart';
import '../widgets/transfers_tab.dart';
import '../widgets/stock_item_editor.dart';

/// Manage → Stock: items, deliveries, counts and suppliers.
class StockView extends GetView<StockController> {
  const StockView({super.key});

  /// Transfers only where there is another branch to send to.
  @override
  Widget build(BuildContext context) => Obx(() => _page(context, branches: Get.find<BranchService>().many));

  Widget _page(BuildContext context, {required bool branches}) {
    final l = context.l10n;
    final purchasing = Get.find<PurchasingController>();
    return DefaultTabController(
      key: ValueKey(branches),
      length: branches ? 6 : 5,
      child: Builder(builder: (context) {
        final tabs = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabs,
          builder: (context, _) => SectionPage(
            title: l.navStock,
            actions: [
              ...switch (tabs.index) {
                0 => [
                    if (controller.canEdit)
                      FilledButton.icon(
                        onPressed: () => showStockItemEditor(onSave: controller.saveItem).then((_) => _flush(controller.message)),
                        icon: const Icon(Icons.add),
                        label: Text(l.stockNew),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async => showExpiring(await Get.find<StockRepository>().expiring(days: 30)),
                      icon: const Icon(Icons.event_busy_outlined),
                      label: Text(l.expiryTitle),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.exportStock,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(l.exportButton),
                    ),
                  ],
                1 => [
                    if (purchasing.canReceive)
                      FilledButton.icon(
                        onPressed: purchasing.receive,
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: Text(l.receiveNew),
                      ),
                  ],
                2 => [
                    if (purchasing.canReceive)
                      FilledButton.icon(
                        onPressed: () => showNewPurchaseOrder(purchasing).then((_) => flushPurchasing(purchasing)),
                        icon: const Icon(Icons.add),
                        label: Text(l.poNew),
                      ),
                  ],
                3 => [
                    if (purchasing.canCount)
                      Obx(() => FilledButton.icon(
                            onPressed: () => _startCount(purchasing),
                            icon: const Icon(Icons.fact_check_outlined),
                            label: Text(purchasing.openCount.value == null ? l.countStart : l.countContinue),
                          )),
                  ],
                5 => [
                    if (canSendStock)
                      FilledButton.icon(
                        onPressed: showNewTransfer,
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: Text(l.transferNew),
                      ),
                  ],
                _ => [
                    if (purchasing.canReceive)
                      FilledButton.icon(
                        onPressed: () => showSupplierEditor(onSave: purchasing.saveSupplier).then((_) => _flush(purchasing.message)),
                        icon: const Icon(Icons.add),
                        label: Text(l.supplierNew),
                      ),
                  ],
              },
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: l.stockItemsTab),
                Tab(text: l.deliveriesTab),
                Tab(text: l.poTab),
                Tab(text: l.countsTab),
                Tab(text: l.suppliersTab),
                if (branches) Tab(text: l.transfersTab),
              ],
            ),
            child: TabBarView(children: [
              const _Items(),
              const DeliveriesTab(),
              const PurchaseOrdersTab(),
              const CountsTab(),
              const SuppliersTab(),
              if (branches) const TransfersTab(),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _startCount(PurchasingController purchasing) async {
    if (purchasing.openCount.value != null) {
      await purchasing.startOrContinueCount(blind: true);
      return;
    }
    final l = appL10n();
    final blind = await choiceDialog<bool>(
      title: l.countStart,
      options: const [true, false],
      label: (b) => b ? l.countBlind : l.countOpen,
    );
    if (blind == null) return;
    await purchasing.startOrContinueCount(blind: blind);
    _flush(purchasing.message);
  }
}

void _flush(RxnString message) {
  final text = message.value;
  if (text == null) return;
  message.value = null;
  showMessage(text);
}

class _Items extends GetView<StockController> {
  const _Items();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    String filterLabel(StockFilter f) => switch (f) {
          StockFilter.all => l.stockFilterAll,
          StockFilter.low => l.stockFilterLow(controller.lowCount),
          StockFilter.retired => l.stockFilterRetired,
        };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s3, AbySpace.s4, AbySpace.s2),
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
      Expanded(
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
      ),
    ]);
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
