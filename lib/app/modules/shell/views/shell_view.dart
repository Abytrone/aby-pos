import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../activity/views/activity_view.dart';
import '../../customers/views/customers_view.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../reports/views/reports_view.dart';
import '../../money/views/money_view.dart';
import '../../products/views/products_view.dart';
import '../../settings/views/settings_view.dart';
import '../../stock/views/stock_view.dart';
import '../../staff/views/staff_view.dart';
import '../../till/views/till_view.dart';
import '../../today/views/today_view.dart';
import '../controllers/shell_controller.dart';
import '../widgets/nav_rail.dart';
import '../widgets/shell_header.dart';

/// The app frame after sign-in: navigation, header, and the open section.
/// Sections keep their state while you move between them.
class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  Widget _build(ShellSection s) => switch (s) {
        ShellSection.sell => const TillView(),
        ShellSection.today => const TodayView(),
        ShellSection.dashboard => const DashboardView(),
        ShellSection.products => const ProductsView(),
        ShellSection.stock => const StockView(),
        ShellSection.customers => const CustomersView(),
        ShellSection.money => const MoneyView(),
        ShellSection.reports => const ReportsView(),
        ShellSection.staff => const StaffView(),
        ShellSection.activity => const ActivityView(),
        ShellSection.settings => const SettingsView(),
      };

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          final sections = controller.sections;
          final current = controller.section.value;
          final body = Column(
            children: [
              ShellHeader(controller: controller, showMark: !wide),
              Expanded(
                child: IndexedStack(
                  index: ShellSection.values.indexOf(current),
                  children: [
                    for (final s in ShellSection.values)
                      controller.visited.contains(s) && sections.contains(s)
                          ? _build(s)
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          );
          if (!wide) return body;
          return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            NavRail(sections: sections, selected: current, onSelect: controller.select),
            Expanded(child: body),
          ]);
        }),
      ),
      bottomNavigationBar: wide
          ? null
          : Obx(() {
              final sections = controller.sections;
              final current = controller.section.value;
              if (sections.length < 2) return const SizedBox.shrink();
              // Phones fit four places and "More".
              final shown = sections.length <= 5 ? sections : sections.take(4).toList();
              final more = sections.length <= 5 ? const <ShellSection>[] : sections.skip(4).toList();
              final index = shown.contains(current) ? shown.indexOf(current) : shown.length;
              return NavigationBar(
                height: 64,
                selectedIndex: index,
                onDestinationSelected: (i) {
                  if (i < shown.length) {
                    controller.select(shown[i]);
                  } else {
                    _showMore(context, more);
                  }
                },
                destinations: [
                  for (final s in shown)
                    NavigationDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.selectedIcon),
                      label: s.label(context.l10n),
                    ),
                  if (more.isNotEmpty)
                    NavigationDestination(
                      icon: const Icon(Icons.more_horiz),
                      label: more.contains(current) ? current.label(context.l10n) : context.l10n.commonMore,
                    ),
                ],
              );
            }),
    );
  }

  void _showMore(BuildContext context, List<ShellSection> more) {
    Get.bottomSheet<void>(
      SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final s in more)
            ListTile(
              minTileHeight: 56,
              leading: Icon(s.icon),
              title: Text(s.label(context.l10n)),
              onTap: () {
                Get.back<void>();
                controller.select(s);
              },
            ),
        ]),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
    );
  }
}
