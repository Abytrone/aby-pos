import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/staff.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/activity_controller.dart';
import '../widgets/activity_row.dart';

/// Manage → Activity: who did what, when, and who approved it.
class ActivityView extends GetView<ActivityController> {
  const ActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionPage(
      title: l.navActivity,
      subtitle: l.activitySubtitle,
      actions: [
        OutlinedButton.icon(
          onPressed: controller.refreshAll,
          icon: const Icon(Icons.refresh),
          label: Text(l.commonRefresh),
        ),
      ],
      bottom: const _Filters(),
      child: Obx(() {
        final entries = controller.entries.toList();
        final chain = controller.chain.value;
        return CustomScrollView(slivers: [
          if (chain != null)
            SliverToBoxAdapter(child: _ChainBanner(intact: chain.isIntact, brokenAt: chain.brokenAtSeq)),
          if (controller.loading.value)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (entries.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(l.activityEmpty)),
            )
          else
            SliverList.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => ActivityRow(entry: entries[i]),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AbySpace.s8)),
        ]);
      }),
    );
  }
}

class _Filters extends GetView<ActivityController> {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String filterLabel(ActivityFilter f) => switch (f) {
          ActivityFilter.all => l.activityFilterAll,
          ActivityFilter.important => l.activityFilterImportant,
          ActivityFilter.signIns => l.activityFilterSignIns,
          ActivityFilter.sales => l.activityFilterSales,
          ActivityFilter.staff => l.activityFilterStaff,
          ActivityFilter.catalogue => l.activityFilterCatalogue,
          ActivityFilter.settingsAndData => l.activityFilterSettings,
        };
    String rangeLabel(ActivityRange r) => switch (r) {
          ActivityRange.today => l.rangeToday,
          ActivityRange.week => l.rangeWeek,
          ActivityRange.month => l.rangeMonth,
          ActivityRange.all => l.rangeAll,
        };
    return Padding(
      padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
      child: Obx(() => Wrap(
            spacing: AbySpace.s2,
            runSpacing: AbySpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final f in ActivityFilter.values)
                ChoiceChip(
                  label: Text(filterLabel(f)),
                  selected: controller.filter.value == f,
                  onSelected: (_) => controller.filter.value = f,
                ),
              DropdownButton<ActivityRange>(
                value: controller.range.value,
                underline: const SizedBox.shrink(),
                items: [
                  for (final r in ActivityRange.values)
                    DropdownMenuItem(value: r, child: Text(rangeLabel(r))),
                ],
                onChanged: (r) => controller.range.value = r ?? ActivityRange.week,
              ),
              DropdownButton<Staff?>(
                value: controller.person.value,
                underline: const SizedBox.shrink(),
                hint: Text(l.activityEveryone),
                items: [
                  DropdownMenuItem<Staff?>(value: null, child: Text(l.activityEveryone)),
                  for (final p in controller.people) DropdownMenuItem<Staff?>(value: p, child: Text(p.name)),
                ],
                onChanged: (p) => controller.person.value = p,
              ),
            ],
          )),
    );
  }
}

class _ChainBanner extends StatelessWidget {
  const _ChainBanner({required this.intact, this.brokenAt});

  final bool intact;
  final int? brokenAt;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s1, AbySpace.s4, AbySpace.s3),
      padding: const EdgeInsets.all(AbySpace.s3),
      decoration: BoxDecoration(
        color: intact ? c.successSoft : c.dangerSoft,
        borderRadius: BorderRadius.circular(AbyRadius.sm),
      ),
      child: Row(children: [
        Icon(intact ? Icons.verified_outlined : Icons.gpp_bad_outlined, color: intact ? c.success : c.danger),
        const SizedBox(width: AbySpace.s3),
        Expanded(
          child: Text(
            intact ? l.activityChainIntact : l.activityChainBroken(brokenAt ?? 0),
            style: AbyText.body.copyWith(color: intact ? c.success : c.danger),
          ),
        ),
      ]),
    );
  }
}
