import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/time_repository.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../services/clock_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

/// Correct a stretch on the timesheet (STF-04): a forgotten clock out, or a
/// time put in wrong. Someone who may manage staff does it, with a reason.
/// True once saved.
Future<bool> showCorrectHours(TimesheetEntry entry) async =>
    await Get.dialog<bool>(_CorrectHours(entry: entry)) ?? false;

/// Let staff correct only their own open entry's missed clock-out, when the
/// owner has enabled it.
Future<bool> showCorrectMissedClockOut(TimesheetEntry entry) async =>
    await Get.dialog<bool>(_CorrectHours(entry: entry, selfCorrection: true)) ?? false;

class _CorrectHours extends StatefulWidget {
  const _CorrectHours({required this.entry, this.selfCorrection = false});

  final TimesheetEntry entry;
  final bool selfCorrection;

  @override
  State<_CorrectHours> createState() => _CorrectHoursState();
}

class _CorrectHoursState extends State<_CorrectHours> {
  late DateTime _in = widget.entry.clockIn;
  // A forgotten clock out starts at the clock in, to be moved forward.
  late DateTime? _out = widget.entry.clockOut ??
      (widget.selfCorrection ? _suggestedClockOut(widget.entry.clockIn) : widget.entry.clockIn);
  var _stillIn = false;
  late final _break = TextEditingController(text: '${widget.entry.breakMinutes}');
  final _reason = TextEditingController();
  String? _error;
  var _saving = false;

  @override
  void dispose() {
    _break.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime from) async {
    final first = widget.selfCorrection ? DateUtils.dateOnly(_in) : from.subtract(const Duration(days: 60));
    final day = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: first,
      lastDate: DateTime.now(),
    );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(from));
    if (time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final l = context.l10n;
    var minutes = int.tryParse(_break.text.trim()) ?? 0;
    if (_reason.text.trim().isEmpty) {
      setState(() => _error = l.timeReasonHint);
      return;
    }
    final Staff actor;
    Staff? approver;
    if (widget.selfCorrection) {
      final current = Get.find<AuthService>().currentUser.value;
      if (current == null ||
          current.id != widget.entry.staffId ||
          !Get.find<SettingsService>().get(AppSettings.allowMissedClockOutEdit)) {
        return setState(() => _error = l.missedClockOutEditUnavailable);
      }
      actor = current;
      final breakStartedAt = widget.entry.breakStartedAt;
      if (breakStartedAt != null) {
        if (_out!.isBefore(breakStartedAt)) {
          setState(() => _error = l.timeClockOutBeforeBreak);
          return;
        }
        minutes += _out!.difference(breakStartedAt).inMinutes;
      }
    } else {
      final auth = await Get.find<PermissionService>().authorize(Permission.manageStaff, reason: l.timeCorrectApproval);
      if (auth == null) return;
      actor = auth.actor;
      approver = auth.approver;
    }
    setState(() => _saving = true);
    try {
      await Get.find<TimeRepository>().correct(
        widget.entry.id,
        clockIn: _in,
        clockOut: _stillIn ? null : _out,
        breakMinutes: minutes,
        reason: _reason.text,
        by: actor,
        approver: approver,
      );
      await Get.find<ClockService>().refresh();
      goBack(result: true);
      showMessage(l.timeCorrected, tone: MessageTone.success);
    } on TimeClockException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    String when(DateTime d) => '${formatDate(d)}  ·  ${formatTime(d)}';
    return AlertDialog(
      title: Text('${l.timeCorrectTitle}: ${widget.entry.staffName}'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.timeCorrectHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s3),
            if (!widget.selfCorrection)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.timeClockInAt),
                subtitle: Text(when(_in)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final d = await _pick(_in);
                  if (d != null) setState(() => _in = d);
                },
              ),
            if (!widget.selfCorrection && widget.entry.stillIn)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.timeStillClockedIn),
                value: _stillIn,
                onChanged: (v) => setState(() => _stillIn = v),
              ),
            if (!_stillIn)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.timeClockOutAt),
                subtitle: Text(when(_out!)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final d = await _pick(_out!);
                  if (d != null) setState(() => _out = d);
                },
              ),
            const SizedBox(height: AbySpace.s2),
            if (!widget.selfCorrection) ...[
              TextField(
                controller: _break,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: l.timeBreakMinutes),
              ),
              const SizedBox(height: AbySpace.s3),
            ],
            TextField(
              controller: _reason,
              decoration: InputDecoration(labelText: l.timeReason, hintText: l.timeReasonHint),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
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

DateTime _suggestedClockOut(DateTime clockIn) {
  final suggested = clockIn.add(const Duration(hours: 8));
  final now = DateTime.now();
  return suggested.isAfter(now) ? now : suggested;
}
