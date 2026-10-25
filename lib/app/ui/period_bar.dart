import 'package:flutter/material.dart';

import '../core/period.dart';
import '../theme/aby_theme.dart';
import 'format.dart';
import 'l10n.dart';
import 'option_chip.dart';

String periodLabel(AppLocalizations l, ReportPeriod p) => switch (p) {
      ReportPeriod.today => l.periodToday,
      ReportPeriod.thisWeek => l.periodThisWeek,
      ReportPeriod.thisMonth => l.periodThisMonth,
      ReportPeriod.lastMonth => l.periodLastMonth,
      ReportPeriod.custom => l.periodCustom,
    };

/// Today / this week / this month / last month / chosen dates.
class PeriodBar extends StatelessWidget {
  const PeriodBar({super.key, required this.period, required this.range, required this.onChanged});

  final ReportPeriod period;
  final DateRange range;
  final void Function(ReportPeriod period, {DateTime? start, DateTime? end}) onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s1),
        children: [
          for (final p in ReportPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: AbySpace.s2),
              child: OptionChip(
                label: p == ReportPeriod.custom && period == p
                    ? '${formatDate(range.from)} – ${formatDate(range.lastDay)}'
                    : periodLabel(l, p),
                selected: period == p,
                onTap: () async {
                  if (p != ReportPeriod.custom) return onChanged(p);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: DateTimeRange(start: range.from, end: range.lastDay),
                  );
                  if (picked != null) onChanged(p, start: picked.start, end: picked.end);
                },
              ),
            ),
        ],
      ),
    );
  }
}
