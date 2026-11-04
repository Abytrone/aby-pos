import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/time_repository.dart';
import '../../../services/clock_service.dart';
import '../../../services/permission_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import 'correct_hours_dialog.dart';
import 'timesheets.dart' show hoursText;

/// An owner decides hours left open when a day closed: pay up to the last
/// sale, pay a set time, pay nothing, or set when the person really left.
/// Always with a reason; the decision is kept on the entry and in the
/// activity log. True once decided.
Future<bool> showReviewHours(TimesheetEntry entry) async =>
    await Get.dialog<bool>(_ReviewHours(entry: entry)) ?? false;

enum _Choice { toActivity, setTime, none }

class _ReviewHours extends StatefulWidget {
  const _ReviewHours({required this.entry});

  final TimesheetEntry entry;

  @override
  State<_ReviewHours> createState() => _ReviewHoursState();
}

class _ReviewHoursState extends State<_ReviewHours> {
  _Choice? _choice;
  final _minutes = TextEditingController();
  final _reason = TextEditingController();
  String? _error;
  var _saving = false;

  TimesheetEntry get e => widget.entry;

  @override
  void initState() {
    super.initState();
    _choice = e.lastActivityAt == null ? null : _Choice.toActivity;
  }

  @override
  void dispose() {
    _minutes.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final choice = _choice;
    if (choice == null) return setState(() => _error = l.reviewHoursNeedChoice);
    final int minutes;
    switch (choice) {
      case _Choice.toActivity:
        minutes = e.workedMinutes();
      case _Choice.none:
        minutes = 0;
      case _Choice.setTime:
        final m = int.tryParse(_minutes.text.trim());
        if (m == null || m < 0) return setState(() => _error = l.reviewHoursMinutesInvalid);
        minutes = m;
    }
    if (_reason.text.trim().isEmpty) return setState(() => _error = l.timeReasonHint);
    final auth = await Get.find<PermissionService>().authorize(Permission.manageStaff, reason: l.reviewHoursApproval);
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      await Get.find<TimeRepository>().review(
        e.id,
        minutes: minutes,
        reason: _reason.text,
        by: auth.actor,
        approver: auth.approver,
      );
      if (Get.isRegistered<ClockService>()) await Get.find<ClockService>().refresh();
      goBack(result: true);
      showMessage(l.reviewHoursSaved, tone: MessageTone.success);
    } on TimeClockException catch (x) {
      setState(() {
        _error = x.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    String when(DateTime d) => '${formatDate(d)}  ·  ${formatTime(d)}';
    final activity = e.lastActivityAt;
    return AlertDialog(
      title: Text(l.reviewHoursTitle(e.staffName)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.reviewHoursIn(when(e.clockIn)), style: AbyText.body.copyWith(color: c.ink)),
            Text(l.reviewHoursLeftOpen(e.leftOpenByName ?? '-'), style: AbyText.body.copyWith(color: c.inkMuted)),
            Text(
              activity == null ? l.reviewHoursNoActivity : l.reviewHoursLastActivity(when(activity)),
              style: AbyText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AbySpace.s3),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              if (activity != null)
                OptionChip(
                  label: l.reviewHoursPayToActivity(hoursText(l, e.workedMinutes())),
                  selected: _choice == _Choice.toActivity,
                  onTap: () => setState(() => _choice = _Choice.toActivity),
                ),
              OptionChip(
                label: l.reviewHoursPaySet,
                selected: _choice == _Choice.setTime,
                onTap: () => setState(() => _choice = _Choice.setTime),
              ),
              OptionChip(
                label: l.reviewHoursPayNone,
                selected: _choice == _Choice.none,
                onTap: () => setState(() => _choice = _Choice.none),
              ),
            ]),
            if (_choice == _Choice.setTime) ...[
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _minutes,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l.reviewHoursMinutes),
              ),
            ],
            const SizedBox(height: AbySpace.s3),
            TextField(controller: _reason, decoration: InputDecoration(labelText: l.reviewHoursReason, hintText: l.timeReasonHint)),
            const SizedBox(height: AbySpace.s2),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        // Setting the real time decides it too (with its own reason).
                        if (await showCorrectHours(e)) goBack(result: true);
                      },
                icon: const Icon(Icons.edit_calendar_outlined),
                label: Text(l.reviewHoursSetReal),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s2),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
          OutlinedButton(onPressed: () => goBack<bool>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}
