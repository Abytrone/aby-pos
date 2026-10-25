import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/charts.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/period_bar.dart';
import '../../../ui/section_page.dart';
import '../controllers/reports_controller.dart';

/// "+12%" against the period before, or nothing when there was nothing.
String? changeText(int now, int before) {
  if (before == 0) return null;
  final pct = ((now - before) * 100 / before).round();
  return '${pct >= 0 ? '+' : ''}$pct%';
}

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tabs = [
      (l.reportSales, const _SalesTab()),
      (l.reportTimes, const _TimesTab()),
      (l.reportProducts, const _ProductsTab()),
      (l.reportPayments, const _PaymentsTab()),
      (l.reportStaff, const _StaffTab()),
      (l.reportCustomers, const _CustomersTab()),
      (l.reportStockTax, const _StockTaxTab()),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: SectionPage(
        title: l.navReports,
        actions: [
          if (controller.canExport)
            OutlinedButton.icon(
              onPressed: controller.accountantPack,
              icon: const Icon(Icons.folder_zip_outlined),
              label: Text(l.reportAccountant),
            ),
        ],
        bottom: Column(mainAxisSize: MainAxisSize.min, children: [
          Obx(() => PeriodBar(period: controller.period.value, range: controller.range.value, onChanged: controller.setPeriod)),
          TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [for (final (t, _) in tabs) Tab(text: t)]),
        ]),
        child: Obx(() => controller.loading.value
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(children: [for (final (_, w) in tabs) w])),
      ),
    );
  }
}

/// A number card with the change against the period before.
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.change});

  final String label;
  final String value;
  final String? change;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AbySpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AbyRadius.md),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s1),
        Text(value, style: AbyText.heading.copyWith(color: c.ink, fontFeatures: const [FontFeature.tabularFigures()])),
        if (change != null)
          Text(change!, style: AbyText.caption.copyWith(color: change!.startsWith('-') ? c.danger : c.success, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(onPressed: onPressed, icon: const Icon(Icons.download_outlined), label: Text(context.l10n.exportButton)),
      );
}

class _SalesTab extends GetView<ReportsController> {
  const _SalesTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final s = controller.sales.value;
      final b = controller.before.value;
      final series = s.series;
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        Wrap(spacing: AbySpace.s3, runSpacing: AbySpace.s3, children: [
          _Figure(label: l.reportNetSales, value: formatMoney(s.net), change: changeText(s.net, b.net)),
          _Figure(label: l.reportSalesCount, value: '${s.count}', change: changeText(s.count, b.count)),
          _Figure(label: l.reportAverageSale, value: formatMoney(s.averageSale), change: changeText(s.averageSale, b.averageSale)),
          _Figure(label: l.reportItemsPerSale, value: s.itemsPerSale.toStringAsFixed(1)),
        ]),
        const SizedBox(height: AbySpace.s4),
        GroupCard(title: l.reportBreakdown, children: [
          InfoTile(title: l.profitSales, value: formatMoney(s.gross)),
          InfoTile(title: l.profitDiscounts, value: '−${formatMoney(s.discounts)}'),
          InfoTile(title: l.profitRefunds, value: '−${formatMoney(s.refunds)}'),
          InfoTile(title: l.reportNetSales, value: formatMoney(s.net)),
          InfoTile(title: l.reportTax, value: formatMoney(s.tax)),
          if (s.voided > 0) InfoTile(title: l.closeVoided(s.voided)),
        ]),
        if (series.isNotEmpty)
          GroupCard(title: l.reportByDay, children: [
            Padding(
              padding: const EdgeInsets.all(AbySpace.s3),
              child: BarStrip(
                values: [for (final (_, v) in series) v],
                labels: [for (final (d, _) in series) series.length > 40 ? '${d.day}/${d.month}' : '${d.day}'],
              ),
            ),
          ]),
        _ExportButton(onPressed: controller.exportSales),
      ]);
    });
  }
}

class _TimesTab extends GetView<ReportsController> {
  const _TimesTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final grid = controller.hours.toList();
      if (grid.isEmpty) return const SizedBox.shrink();
      final byHour = [for (var h = 0; h < 24; h++) grid.fold(0, (s, r) => s + r[h])];
      final open = [for (var h = 0; h < 24; h++) if (byHour[h] > 0) h];
      final from = open.isEmpty ? 8 : open.first, to = open.isEmpty ? 21 : open.last;
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        Text(l.reportTimesHelp, style: AbyText.caption.copyWith(color: Theme.of(context).extension<AbyColors>()!.inkMuted)),
        const SizedBox(height: AbySpace.s3),
        GroupCard(title: l.reportByHour, children: [
          Padding(
            padding: const EdgeInsets.all(AbySpace.s3),
            child: BarStrip(values: byHour.sublist(from, to + 1), labels: [for (var h = from; h <= to; h++) '$h']),
          ),
        ]),
        GroupCard(title: l.reportHeatmap, children: [
          Padding(
            padding: const EdgeInsets.all(AbySpace.s3),
            child: Heatmap(grid: grid, dayLabels: [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun]),
          ),
        ]),
      ]);
    });
  }
}

class _ProductsTab extends GetView<ReportsController> {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final cost = controller.canSeeCost;
    return Obx(() {
      final list = controller.products.toList();
      final byCategory = <String, int>{};
      for (final p in list) {
        byCategory[p.category] = (byCategory[p.category] ?? 0) + p.revenue;
      }
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        GroupCard(
          title: l.reportProducts,
          footer: l.reportAbcHelp,
          children: list.isEmpty
              ? [InfoTile(title: l.todayNoSales)]
              : [
                  for (final p in list)
                    InfoTile(
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: p.grade == 'A' ? c.successSoft : (p.grade == 'B' ? c.blueSoft : c.surfaceSunken),
                        child: Text(p.grade, style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w800)),
                      ),
                      title: p.name,
                      subtitle: [
                        p.category,
                        l.reportSold(p.quantity),
                        if (cost) l.reportProfitLine(formatMoney(p.profit), p.marginPercent?.toString() ?? '–'),
                      ].join('  ·  '),
                      value: formatMoney(p.revenue),
                    ),
                ],
        ),
        if (byCategory.isNotEmpty)
          GroupCard(title: l.reportByCategory, children: [
            for (final e in byCategory.entries) InfoTile(title: e.key.isEmpty ? '–' : e.key, value: formatMoney(e.value)),
          ]),
        if (controller.options.isNotEmpty)
          GroupCard(title: l.reportOptions, children: [
            for (final e in controller.options.entries) InfoTile(title: e.key, value: '${e.value}'),
          ]),
        GroupCard(
          title: l.reportSlow,
          footer: l.reportSlowHelp,
          children: controller.slow.isEmpty
              ? [InfoTile(title: l.reportSlowNone)]
              : [
                  for (final (name, last) in controller.slow)
                    InfoTile(title: name, value: last == null ? l.reportNeverSold : formatDate(last)),
                ],
        ),
        _ExportButton(onPressed: controller.exportProducts),
      ]);
    });
  }
}

class _PaymentsTab extends GetView<ReportsController> {
  const _PaymentsTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() => ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
          GroupCard(
            title: l.reportPayments,
            children: controller.payments.isEmpty
                ? [InfoTile(title: l.todayNoSales)]
                : [for (final e in controller.payments.entries) InfoTile(title: e.key, value: formatMoney(e.value))],
          ),
          GroupCard(title: l.closeRounding, children: [InfoTile(title: l.closeRounding, value: formatMoney(controller.rounding.value))]),
        ]));
  }
}

class _StaffTab extends GetView<ReportsController> {
  const _StaffTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() => ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
          for (final s in controller.staff)
            GroupCard(title: s.name, children: [
              InfoTile(title: l.reportSalesCount, value: '${s.sales}'),
              InfoTile(title: l.reportNetSales, value: formatMoney(s.total)),
              InfoTile(title: l.reportAverageSale, value: formatMoney(s.average)),
              InfoTile(title: l.profitDiscounts, value: formatMoney(s.discounts)),
              InfoTile(title: l.reportVoids, value: '${s.voids}'),
              InfoTile(title: l.reportRefundsGiven, value: '${s.refunds}'),
              InfoTile(title: l.reportNoSales, value: '${s.noSales}'),
              if (s.shorts > 0) InfoTile(title: l.reportShorts(s.shorts), value: formatMoney(s.shortTotal)),
            ]),
          if (controller.staff.isEmpty) InfoTile(title: l.todayNoSales),
          _ExportButton(onPressed: controller.exportStaff),
        ]));
  }
}

class _CustomersTab extends GetView<ReportsController> {
  const _CustomersTab();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final c = controller.customers.value;
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        Wrap(spacing: AbySpace.s3, runSpacing: AbySpace.s3, children: [
          _Figure(label: l.reportNewCustomers, value: '${c.newCustomers}'),
          _Figure(label: l.reportReturning, value: '${c.returning}'),
          _Figure(label: l.reportOwed, value: formatMoney(c.owed)),
          _Figure(label: l.reportOverdue, value: formatMoney(c.overdue)),
          _Figure(label: l.reportWallets, value: formatMoney(c.wallets)),
        ]),
        const SizedBox(height: AbySpace.s4),
        GroupCard(
          title: l.reportTopCustomers,
          children: c.top.isEmpty
              ? [InfoTile(title: l.todayNoSales)]
              : [for (final (name, v) in c.top) InfoTile(title: name, value: formatMoney(v))],
        ),
      ]);
    });
  }
}

class _StockTaxTab extends GetView<ReportsController> {
  const _StockTaxTab();

  String _reason(AppLocalizations l, String r) => switch (StockReason.values.asNameMap()[r]) {
        StockReason.sale => l.moveSale,
        StockReason.restock => l.moveReceived,
        StockReason.waste => l.profitWaste,
        StockReason.adjustment => l.moveAdjustment,
        StockReason.count => l.moveCount,
        StockReason.returned => l.moveReturned,
        null => r,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Obx(() {
      final s = controller.stockTax.value;
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        if (controller.canSeeCost)
          Wrap(children: [_Figure(label: l.reportStockValue, value: formatMoney(s.stockValue))]),
        const SizedBox(height: AbySpace.s4),
        if (controller.canSeeCost)
          GroupCard(title: l.reportMovements, children: [
            for (final e in s.movements.entries) InfoTile(title: _reason(l, e.key), value: formatMoney(e.value)),
            if (s.movements.isEmpty) InfoTile(title: l.stockNoMovements),
          ]),
        if (s.waste.isNotEmpty && controller.canSeeCost)
          GroupCard(title: l.profitWaste, children: [for (final (n, v) in s.waste) InfoTile(title: n, value: formatMoney(v))]),
        if (s.countDifferences.isNotEmpty && controller.canSeeCost)
          GroupCard(title: l.profitCounts, children: [for (final (n, v) in s.countDifferences) InfoTile(title: n, value: formatMoney(v))]),
        GroupCard(
          title: l.reportTax,
          children: s.taxes.isEmpty
              ? [InfoTile(title: l.reportNoTax)]
              : [for (final (name, bp, v) in s.taxes) InfoTile(title: '$name ${(bp / 100).toStringAsFixed(bp % 100 == 0 ? 0 : 1)}%', value: formatMoney(v))],
        ),
      ]);
    });
  }
}
