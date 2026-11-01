import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/time_repository.dart';
import '../../../services/permission_service.dart';
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

class _CorrectHours extends StatefulWidget {
  const _CorrectHours({required this.entry});

  final TimesheetEntry entry;

  @override
  State<_CorrectHours> createState() => _CorrectHoursState();
}

class _CorrectHoursState extends State<_CorrectHours> {
  late DateTime _in = widget.entry.clockIn;
  // A forgotten clock out starts at the clock in, to be moved forward.
  late DateTime? _out = widget.entry.clockOut ?? widget.entry.clockIn;
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
    final day = await showDatePicker(
      context: context,
      initialDate: from,
      firstDate: from.subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(from));
    if (time == null) return null;
    return DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final l = context.l10n;
    final minutes = int.tryParse(_break.text.trim()) ?? 0;
    if (_reason.text.trim().isEmpty) return setState(() => _error = l.timeReasonHint);
    final auth = await Get.find<PermissionService>().authorize(Permission.manageStaff, reason: l.timeCorrectApproval);
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      await Get.find<TimeRepository>().correct(
        widget.entry.id,
        clockIn: _in,
        clockOut: _stillIn ? null : _out,
        breakMinutes: minutes,
        reason: _reason.text,
        by: auth.actor,
        approver: auth.approver,
      );
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
            if (widget.entry.stillIn)
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
            TextField(
              controller: _break,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.timeBreakMinutes),
            ),
            const SizedBox(height: AbySpace.s3),
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
