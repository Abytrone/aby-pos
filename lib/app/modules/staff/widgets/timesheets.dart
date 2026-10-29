import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/csv.dart';
import '../../../core/period.dart';
import '../../../data/repositories/time_repository.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/files.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/period_bar.dart';
import '../../../ui/section_page.dart';

/// "7 h 30 min".
String hoursText(AppLocalizations l, int minutes) => l.timeHours(minutes ~/ 60, minutes % 60);

/// Staff → Timesheets (STF-04): hours per person for a week or any dates,
/// with late arrivals and early leaves, exported for wages.
class TimesheetsTab extends StatefulWidget {
  const TimesheetsTab({super.key});

  @override
  State<TimesheetsTab> createState() => _TimesheetsTabState();
}

class _TimesheetsTabState extends State<TimesheetsTab> {
  final TimeRepository _times = Get.find();
  ReportPeriod _period = ReportPeriod.thisWeek;
  late DateRange _range = DateRange.of(_period, DateTime.now());
  List<TimesheetEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _times.timesheet(_range);
    if (mounted) setState(() => _entries = list);
  }

  void _setPeriod(ReportPeriod p, {DateTime? start, DateTime? end}) {
    setState(() {
      _period = p;
      _range = DateRange.of(p, DateTime.now(), start: start, end: end);
    });
    _load();
  }

  Future<void> _export() async {
    final now = DateTime.now();
    final rows = [
      ['Name', 'Day', 'In', 'Out', 'Break (min)', 'Worked (min)', 'Late (min)', 'Early (min)'],
      for (final e in _entries)
        [
          e.staffName,
          formatDate(e.clockIn),
          formatTime(e.clockIn),
          e.clockOut == null ? '' : formatTime(e.clockOut!),
          '${e.breakMinutes}',
          '${e.workedMinutes(now)}',
          '${e.lateMinutes}',
          '${e.earlyMinutes}',
        ],
    ];
    await shareOrSaveText('timesheet-${_range.from.toIso8601String().substring(0, 10)}.csv', Csv.encode(rows));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final now = DateTime.now();
    final byPerson = <String, List<TimesheetEntry>>{};
    for (final e in _entries) {
      byPerson.putIfAbsent(e.staffName, () => []).add(e);
    }
    return Column(children: [
      PeriodBar(period: _period, range: _range, onChanged: _setPeriod),
      Expanded(
        child: byPerson.isEmpty
            ? EmptyState(icon: Icons.schedule, message: l.timeNone)
            : ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(onPressed: _export, icon: const Icon(Icons.download_outlined), label: Text(l.exportButton)),
                ),
                const SizedBox(height: AbySpace.s2),
                for (final MapEntry(key: name, value: list) in byPerson.entries)
                  GroupCard(
                    title: name,
                    children: [
                      InfoTile(
                        title: l.timeWorked,
                        subtitle: [
                          if (list.any((e) => e.lateMinutes > 0)) l.timeLateCount(list.where((e) => e.lateMinutes > 0).length),
                          if (list.any((e) => e.earlyMinutes > 0)) l.timeEarlyCount(list.where((e) => e.earlyMinutes > 0).length),
                        ].join('  ·  '),
                        value: hoursText(l, list.fold(0, (s, e) => s + e.workedMinutes(now))),
                      ),
                      for (final e in list)
                        InfoTile(
                          title: '${formatDate(e.clockIn)}  ·  ${formatTime(e.clockIn)} – ${e.clockOut == null ? l.timeStillIn : formatTime(e.clockOut!)}',
                          subtitle: [
                            if (e.breakMinutes > 0) l.timeBreak(e.breakMinutes),
                            if (e.lateMinutes > 0) l.timeLate(e.lateMinutes),
                            if (e.earlyMinutes > 0) l.timeEarly(e.earlyMinutes),
                          ].join('  ·  '),
                          value: hoursText(l, e.workedMinutes(now)),
                          leading: Icon(
                            e.lateMinutes > 0 || e.earlyMinutes > 0 ? Icons.warning_amber_rounded : Icons.schedule,
                            color: e.lateMinutes > 0 || e.earlyMinutes > 0 ? c.warning : c.inkMuted,
                          ),
                        ),
                    ],
                  ),
              ]),
      ),
    ]);
  }
}
