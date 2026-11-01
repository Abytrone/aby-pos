import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/csv.dart';
import '../../../core/period.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/time_repository.dart';
import '../../../domain/documents/report_docs.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/export_dialog.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/period_bar.dart';
import '../../../ui/section_page.dart';
import 'correct_hours_dialog.dart';

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
      ['Name', 'Day', 'In', 'Out', 'Break (min)', 'Worked (min)', 'Late (min)', 'Early (min)', 'Check', 'Corrected'],
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
          if (e.tooLong(now)) 'Over 16 hours' else if (e.stillIn) 'Still clocked in' else '',
          e.note ?? '',
        ],
    ];
    await exportDocument(
      ReportDocs.timesheet(_entries, shopName: Get.find<SettingsService>().get(AppSettings.shopName), range: _range, now: now),
      fileStem: 'timesheet-${_range.from.toIso8601String().substring(0, 10)}',
      csv: Csv.encode(rows));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final now = DateTime.now();
    // By person, not name: two people may share a name, and a rename keeps
    // one card. The card shows the latest name.
    final byPerson = <String, List<TimesheetEntry>>{};
    for (final e in _entries) {
      byPerson.putIfAbsent(e.staffId, () => []).add(e);
    }
    final canCorrect = Get.find<AuthService>().can(Permission.manageStaff);
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
                for (final list in byPerson.values)
                  GroupCard(
                    title: list.last.staffName,
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
                            if (e.tooLong(now)) l.timeTooLong,
                            if (e.breakMinutes > 0) l.timeBreak(e.breakMinutes),
                            if (e.lateMinutes > 0) l.timeLate(e.lateMinutes),
                            if (e.earlyMinutes > 0) l.timeEarly(e.earlyMinutes),
                            if (e.note != null) l.timeCorrectedNote(e.note!),
                          ].join('  ·  '),
                          value: hoursText(l, e.workedMinutes(now)),
                          leading: Icon(
                            e.tooLong(now) || e.lateMinutes > 0 || e.earlyMinutes > 0 ? Icons.warning_amber_rounded : Icons.schedule,
                            color: e.tooLong(now) ? c.danger : (e.lateMinutes > 0 || e.earlyMinutes > 0 ? c.warning : c.inkMuted),
                          ),
                          onTap: canCorrect
                              ? () async {
                                  if (await showCorrectHours(e)) await _load();
                                }
                              : null,
                        ),
                    ],
                  ),
              ]),
      ),
    ]);
  }
}
