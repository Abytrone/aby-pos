import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/csv.dart';
import '../../../core/period.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/time_repository.dart';
import '../../../models/enums.dart';
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
import 'review_hours_dialog.dart';

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

  /// Everything waiting for an owner's decision, whatever the dates shown.
  List<TimesheetEntry> _review = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _times.timesheet(_range);
    final review = await _times.needingReview();
    if (mounted) {
      setState(() {
        _entries = list;
        _review = review;
      });
    }
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
          '${e.payableMinutes(now)}',
          '${e.lateMinutes}',
          '${e.earlyMinutes}',
          if (e.tooLong(now)) 'Over 16 hours' else e.statusNote,
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
        child: byPerson.isEmpty && _review.isEmpty
            ? EmptyState(icon: Icons.schedule, message: l.timeNone)
            : ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
                if (_review.isNotEmpty) ...[
                  GroupCard(
                    title: l.reviewQueueTitle,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s2, AbySpace.s4, AbySpace.s2),
                        child: Text(l.reviewQueueHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
                      ),
                      for (final e in _review)
                        InfoTile(
                          title: '${e.staffName}  ·  ${formatDate(e.clockIn)}  ·  ${formatTime(e.clockIn)}',
                          subtitle: e.lastActivityAt == null
                              ? l.reviewHoursNoActivity
                              : l.reviewHoursLastActivity('${formatDate(e.lastActivityAt!)}  ·  ${formatTime(e.lastActivityAt!)}'),
                          leading: Icon(Icons.rule_rounded, color: c.warning),
                          value: l.timeNotPaidYet,
                          onTap: canCorrect
                              ? () async {
                                  if (await showReviewHours(e)) await _load();
                                }
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: AbySpace.s2),
                ],
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
                          if (list.any((e) => e.needsReview)) l.timeWaitingCount(list.where((e) => e.needsReview).length),
                        ].join('  ·  '),
                        value: hoursText(l, list.fold(0, (s, e) => s + e.payableMinutes(now))),
                      ),
                      for (final e in list)
                        InfoTile(
                          title: '${formatDate(e.clockIn)}  ·  ${formatTime(e.clockIn)} – ${e.clockOut != null ? formatTime(e.clockOut!) : (e.unconfirmed ? l.timeUnconfirmedShort : l.timeStillIn)}',
                          subtitle: [
                            if (e.missedClockOut(now)) l.timeMissedClockOut,
                            if (e.tooLong(now)) l.timeTooLong,
                            if (e.breakMinutes > 0) l.timeBreak(e.breakMinutes),
                            if (e.lateMinutes > 0) l.timeLate(e.lateMinutes),
                            if (e.earlyMinutes > 0) l.timeEarly(e.earlyMinutes),
                            if (e.unconfirmed) l.timeUnconfirmed,
                            if (e.closeSource == ClockOutSource.auto) l.timeAutoClockOut,
                            if (e.review == TimeReview.approved && e.approvedByName != null && e.approvalNote != null)
                              l.timeDecidedBy(e.approvedByName!, e.approvalNote!),
                            if (e.note != null) l.timeCorrectedNote(e.note!),
                          ].join('  ·  '),
                          value: e.needsReview ? l.timeNotPaidYet : hoursText(l, e.payableMinutes(now)),
                          leading: Icon(
                            e.needsReview
                                ? Icons.rule_rounded
                                : (e.missedClockOut(now) || e.tooLong(now) || e.lateMinutes > 0 || e.earlyMinutes > 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.schedule),
                            color: e.tooLong(now)
                                ? c.danger
                                : (e.needsReview || e.missedClockOut(now) || e.lateMinutes > 0 || e.earlyMinutes > 0
                                    ? c.warning
                                    : c.inkMuted),
                          ),
                          onTap: canCorrect
                              ? () async {
                                  final done = e.needsReview ? await showReviewHours(e) : await showCorrectHours(e);
                                  if (done) await _load();
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
