import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../activity/views/activity_view.dart';
import '../../settings/views/settings_view.dart';
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
              return NavigationBar(
                height: 64,
                selectedIndex: sections.indexOf(current).clamp(0, sections.length - 1),
                onDestinationSelected: (i) => controller.select(sections[i]),
                destinations: [
                  for (final s in sections)
                    NavigationDestination(
                      icon: Icon(s.icon),
                      selectedIcon: Icon(s.selectedIcon),
                      label: s.label(context.l10n),
                    ),
                ],
              );
            }),
    );
  }
}
