import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/alert_text.dart';
import '../../../ui/charts.dart';
import '../../../ui/insight_text.dart';
import '../../../ui/branch_picker.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../../reports/views/reports_view.dart' show changeText;
import '../controllers/dashboard_controller.dart';
import '../../../ui/dialogs.dart';

String dashboardCardLabel(AppLocalizations l, DashboardCard c) => switch (c) {
      DashboardCard.insights => l.insightsTitle,
      DashboardCard.sales => l.dashSales,
      DashboardCard.payments => l.reportPayments,
      DashboardCard.hours => l.reportByHour,
      DashboardCard.topProducts => l.dashTop,
      DashboardCard.shift => l.dashDrawer,
      DashboardCard.alerts => l.dashAlerts,
    };

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionPage(
      title: l.navDashboard,
      actions: [
        BranchPicker(onChanged: controller.load),
        IconButton(tooltip: l.dashRefresh, onPressed: controller.load, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: l.dashArrange, onPressed: () => Get.dialog<void>(_Arrange(ctl: controller)), icon: const Icon(Icons.tune)),
      ],
      child: Obx(() {
        if (controller.loading.value) return const Center(child: CircularProgressIndicator());
        return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
          for (final card in controller.cards) _card(context, card),
        ]);
      }),
    );
  }

  Widget _card(BuildContext context, DashboardCard card) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final t = controller.today.value;
    final w = controller.lastWeek.value;
    return switch (card) {
      DashboardCard.insights => controller.insights.isEmpty
          ? const SizedBox.shrink()
          : GroupCard(title: l.insightsTitle, children: [
              for (final i in controller.insights)
                InfoTile(
                  leading: Icon(Icons.lightbulb_outline, color: c.blue),
                  title: insightText(l, i),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(onPressed: () => insightAction(i), child: Text(insightActionLabel(l, i))),
                    PopupMenuButton<VoidCallback>(
                      tooltip: l.commonMore,
                      onSelected: (f) => f(),
                      itemBuilder: (_) => [
                        PopupMenuItem(value: () => controller.dismiss(i), child: Text(l.insightDismiss)),
                        PopupMenuItem(value: () => controller.turnOff(i.kind), child: Text(l.insightTurnOff)),
                      ],
                    ),
                  ]),
                ),
            ]),
      DashboardCard.sales => GroupCard(title: l.dashSales, children: [
          InfoTile(
            title: l.reportNetSales,
            subtitle: [l.dashLastWeek(formatMoney(w.net)), ?changeText(t.net, w.net)].join('  ·  '),
            value: formatMoney(t.net),
          ),
          InfoTile(title: l.reportSalesCount, subtitle: l.dashLastWeekCount(w.count), value: '${t.count}'),
          InfoTile(title: l.reportAverageSale, value: formatMoney(t.averageSale)),
        ]),
      DashboardCard.payments => GroupCard(
          title: l.reportPayments,
          children: controller.payments.isEmpty
              ? [InfoTile(title: l.todayNoSales)]
              : [for (final e in controller.payments.entries) InfoTile(title: e.key, value: formatMoney(e.value))],
        ),
      DashboardCard.hours => () {
          final hours = controller.hours.toList();
          final open = [for (var h = 0; h < 24; h++) if (hours[h] > 0) h];
          final from = open.isEmpty ? 8 : (open.first < 8 ? open.first : 8);
          final to = open.isEmpty ? 21 : (open.last > 21 ? open.last : 21);
          final now = DateTime.now().hour;
          return GroupCard(title: l.reportByHour, children: [
            Padding(
              padding: const EdgeInsets.all(AbySpace.s3),
              child: BarStrip(
                values: hours.sublist(from, to + 1),
                labels: [for (var h = from; h <= to; h++) '$h'],
                height: 100,
                highlight: now >= from && now <= to ? now - from : null,
              ),
            ),
          ]);
        }(),
      DashboardCard.topProducts => GroupCard(
          title: l.dashTop,
          children: controller.top.isEmpty
              ? [InfoTile(title: l.todayNoSales)]
              : [for (final p in controller.top) InfoTile(title: p.name, subtitle: l.reportSold(p.quantity), value: formatMoney(p.revenue))],
        ),
      DashboardCard.shift => () {
          final p = controller.period.value;
          if (p == null) return const SizedBox.shrink();
          final float = p.shiftFloat ?? p.suggestedFloat;
          return GroupCard(title: l.dashDrawer, children: [
            InfoTile(
              title: p.shiftOpenedBy == null ? l.dashDayNotStarted : l.dashDayStartedBy(p.shiftOpenedBy!),
              value: formatMoney(p.expectedCash(float)),
              subtitle: l.closeExpected,
            ),
          ]);
        }(),
      DashboardCard.alerts => GroupCard(
          title: l.dashAlerts,
          children: controller.alerts.isEmpty
              ? [InfoTile(leading: Icon(Icons.check_circle_outline, color: c.success), title: l.dashAllGood)]
              : [
                  for (final a in controller.alerts)
                    InfoTile(leading: Icon(Icons.warning_amber_rounded, color: c.warning), title: alertText(l, a)),
                ],
        ),
    };
  }
}

/// Reorder the cards and choose which show.
class _Arrange extends StatefulWidget {
  const _Arrange({required this.ctl});

  final DashboardController ctl;

  @override
  State<_Arrange> createState() => _ArrangeState();
}

class _ArrangeState extends State<_Arrange> {
  late final List<DashboardCard> _order = [
    ...widget.ctl.cards,
    ...DashboardCard.values.where((c) => !widget.ctl.cards.contains(c)),
  ];
  late final Set<DashboardCard> _shown = {...widget.ctl.cards};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.dashArrange),
      content: SizedBox(
        width: 400,
        height: 420,
        child: ReorderableListView.builder(
          itemCount: _order.length,
          onReorderItem: (from, to) => setState(() => _order.insert(to, _order.removeAt(from))),
          itemBuilder: (_, i) => CheckboxListTile(
            key: ValueKey(_order[i]),
            value: _shown.contains(_order[i]),
            onChanged: (v) => setState(() => (v ?? false) ? _shown.add(_order[i]) : _shown.remove(_order[i])),
            title: Text(dashboardCardLabel(l, _order[i])),
            secondary: const Icon(Icons.drag_indicator),
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () async {
              await widget.ctl.setLayout([for (final c in _order) if (_shown.contains(c)) c]);
              goBack<void>();
            },
            child: Text(l.commonSave),
          ),
        ]),
      ],
    );
  }
}
