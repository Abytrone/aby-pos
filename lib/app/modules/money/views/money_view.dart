import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../models/expense.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/section_page.dart';
import '../controllers/money_controller.dart';
import '../widgets/money_dialogs.dart';

String periodLabel(AppLocalizations l, MoneyPeriod p) => switch (p) {
      MoneyPeriod.today => l.periodToday,
      MoneyPeriod.thisWeek => l.periodThisWeek,
      MoneyPeriod.thisMonth => l.periodThisMonth,
      MoneyPeriod.lastMonth => l.periodLastMonth,
      MoneyPeriod.custom => l.periodCustom,
    };

/// Manage → Money: expenses, profit and the owner's money.
class MoneyView extends GetView<MoneyController> {
  const MoneyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profit = controller.canSeeProfit;
    return DefaultTabController(
      length: profit ? 3 : 2,
      child: SectionPage(
        title: l.navMoney,
        actions: [
          FilledButton.icon(
            onPressed: () => showExpenseDialog(controller).then((_) => _flush()),
            icon: const Icon(Icons.add),
            label: Text(l.expenseNew),
          ),
          PopupMenuButton<String>(
            tooltip: l.commonMore,
            onSelected: (v) => switch (v) {
              'recurring' => showRecurringDialog(controller),
              'categories' => showExpenseCategories(controller),
              'took' => showOwnerMoneyDialog(controller, OwnerMoneyKind.drawing),
              _ => showOwnerMoneyDialog(controller, OwnerMoneyKind.capital),
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'recurring', child: Text(l.recurringTitle)),
              PopupMenuItem(value: 'categories', child: Text(l.expenseCategories)),
              PopupMenuItem(value: 'took', child: Text(l.ownerTook)),
              PopupMenuItem(value: 'put', child: Text(l.ownerPut)),
            ],
          ),
        ],
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 56,
            child: Obx(() => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s1),
                  children: [
                    for (final p in MoneyPeriod.values)
                      Padding(
                        padding: const EdgeInsets.only(right: AbySpace.s2),
                        child: OptionChip(
                          label: p == MoneyPeriod.custom && controller.period.value == p
                              ? '${formatDate(controller.from.value)} – ${formatDate(controller.to.value.subtract(const Duration(days: 1)))}'
                              : periodLabel(l, p),
                          selected: controller.period.value == p,
                          onTap: () async {
                            if (p != MoneyPeriod.custom) return controller.setPeriod(p);
                            final range = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (range != null) await controller.setPeriod(p, start: range.start, end: range.end);
                          },
                        ),
                      ),
                  ],
                )),
          ),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l.moneyExpenses),
              if (profit) Tab(text: l.moneyProfit),
              Tab(text: l.moneyOwner),
            ],
          ),
        ]),
        child: Obx(() {
          if (controller.loading.value) return const Center(child: CircularProgressIndicator());
          return TabBarView(children: [
            _ExpensesTab(ctl: controller, onChanged: _flush),
            if (profit) _ProfitTab(ctl: controller),
            _OwnerTab(ctl: controller),
          ]);
        }),
      ),
    );
  }

  void _flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({required this.ctl, required this.onChanged});

  final MoneyController ctl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final due = ctl.due.toList();
      final list = ctl.expenses.toList();
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        for (final r in due)
          Card(
            margin: const EdgeInsets.only(bottom: AbySpace.s3),
            color: c.warningSoft,
            child: Padding(
              padding: const EdgeInsets.all(AbySpace.s3),
              child: Row(children: [
                Icon(Icons.event_repeat, color: c.warning),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: Text(l.recurringDue(r.name, formatMoney(r.amount), r.dayOfMonth),
                      style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                ),
                TextButton(onPressed: () => ctl.skip(r), child: Text(l.recurringSkip)),
                FilledButton(onPressed: () => ctl.confirm(r), child: Text(l.recurringConfirm)),
              ]),
            ),
          ),
        Text(l.expensesTotal(formatMoney(ctl.expenseTotal)), style: AbyText.heading.copyWith(color: c.ink)),
        const SizedBox(height: AbySpace.s3),
        if (ctl.byCategory.isNotEmpty)
          GroupCard(title: l.expensesByCategory, children: [
            for (final e in ctl.byCategory.entries) InfoTile(title: e.key, value: formatMoney(e.value)),
          ]),
        GroupCard(
          title: l.moneyExpenses,
          children: list.isEmpty
              ? [InfoTile(title: l.expensesNone)]
              : [
                  for (final Expense e in list)
                    InfoTile(
                      leading: Icon(e.hasPhoto ? Icons.receipt_long : Icons.receipt_long_outlined, color: c.inkMuted),
                      title: e.categoryName,
                      subtitle: [formatDate(e.day), moneySourceLabel(l, e.paidFrom), ?e.supplierName, ?e.note, e.byName].join('  ·  '),
                      value: formatMoney(e.amount),
                    ),
                ],
        ),
      ]);
    });
  }
}

class _ProfitTab extends StatelessWidget {
  const _ProfitTab({required this.ctl});

  final MoneyController ctl;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final p = ctl.pnl.value;
      final before = ctl.previous.value;
      if (p == null) return const SizedBox.shrink();
      Widget row(String label, int now, int? then, {bool strong = false, bool minus = false}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
            child: Row(children: [
              Expanded(child: Text(label, style: (strong ? AbyText.heading : AbyText.body).copyWith(color: strong ? c.ink : c.inkMuted))),
              SizedBox(
                width: 130,
                child: Text(
                  '${minus && now != 0 ? '−' : ''}${formatMoney(now.abs())}${now < 0 && !minus ? ' ↓' : ''}',
                  textAlign: TextAlign.end,
                  style: (strong ? AbyText.heading : AbyText.body).copyWith(
                    color: strong && now < 0 ? c.danger : c.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: Text(
                  then == null ? '' : formatMoney(then.abs()),
                  textAlign: TextAlign.end,
                  style: AbyText.caption.copyWith(color: c.inkMuted, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            ]),
          );
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AbySpace.s4),
            child: Column(children: [
              Row(children: [
                const Spacer(),
                SizedBox(width: 130, child: Text(l.profitThisPeriod, textAlign: TextAlign.end, style: AbyText.label.copyWith(color: c.inkMuted))),
                SizedBox(width: 110, child: Text(l.profitBefore, textAlign: TextAlign.end, style: AbyText.label.copyWith(color: c.inkMuted))),
              ]),
              row(l.profitSales, p.sales, before?.sales),
              row(l.profitDiscounts, p.discounts, before?.discounts, minus: true),
              row(l.profitRefunds, p.refunds, before?.refunds, minus: true),
              row(l.profitTax, p.tax, before?.tax, minus: true),
              const Divider(),
              row(l.profitNetSales, p.netSales, before?.netSales, strong: true),
              row(l.profitCost, p.costOfGoods, before?.costOfGoods, minus: true),
              const Divider(),
              row(l.profitGross, p.grossProfit, before?.grossProfit, strong: true),
              if (p.grossMarginPercent != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l.profitMargin(p.grossMarginPercent!), style: AbyText.caption.copyWith(color: c.inkMuted)),
                ),
              for (final e in p.expenses.entries) row(e.key, e.value, before?.expenses[e.key], minus: true),
              if (p.expenses.isEmpty) row(l.moneyExpenses, 0, before?.expenseTotal, minus: true),
              row(l.profitWaste, p.waste, before?.waste, minus: true),
              if (p.countDifference != 0 || (before?.countDifference ?? 0) != 0)
                row(l.profitCounts, p.countDifference, before?.countDifference),
              const Divider(),
              row(l.profitNet, p.netProfit, before?.netProfit, strong: true),
            ]),
          ),
        ),
        const SizedBox(height: AbySpace.s3),
        Text(l.profitHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s4),
        GroupCard(title: l.moneyOwner, children: [
          InfoTile(title: l.ownerTookTotal, value: formatMoney(p.drawings)),
          InfoTile(title: l.ownerPutTotal, value: formatMoney(p.capital)),
          InfoTile(title: l.ownerTakeHome, subtitle: l.ownerTakeHomeHelp, value: formatMoney(p.drawings - p.capital)),
        ]),
      ]);
    });
  }
}

class _OwnerTab extends StatelessWidget {
  const _OwnerTab({required this.ctl});

  final MoneyController ctl;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final list = ctl.owner.toList();
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        Text(l.ownerHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s3),
        Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
          FilledButton.icon(
            onPressed: () => showOwnerMoneyDialog(ctl, OwnerMoneyKind.drawing),
            icon: const Icon(Icons.north_east),
            label: Text(l.ownerTook),
          ),
          OutlinedButton.icon(
            onPressed: () => showOwnerMoneyDialog(ctl, OwnerMoneyKind.capital),
            icon: const Icon(Icons.south_west),
            label: Text(l.ownerPut),
          ),
        ]),
        const SizedBox(height: AbySpace.s4),
        GroupCard(title: l.moneyOwner, children: [
          InfoTile(title: l.ownerTookTotal, value: formatMoney(ctl.drawings)),
          InfoTile(title: l.ownerPutTotal, value: formatMoney(ctl.capital)),
        ]),
        GroupCard(
          title: l.ownerEntries,
          children: list.isEmpty
              ? [InfoTile(title: l.ownerNone)]
              : [
                  for (final o in list)
                    InfoTile(
                      title: o.kind == OwnerMoneyKind.drawing ? l.ownerTook : l.ownerPut,
                      subtitle: [formatDateTime(o.at), moneySourceLabel(l, o.source), ?o.note, o.byName].join('  ·  '),
                      value: '${o.kind == OwnerMoneyKind.drawing ? '−' : '+'}${formatMoney(o.amount)}',
                    ),
                ],
        ),
      ]);
    });
  }
}
