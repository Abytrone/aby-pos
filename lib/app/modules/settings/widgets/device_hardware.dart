import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../models/scale.dart';
import '../../../services/alert_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/printing/bluetooth_link.dart';
import '../../../services/printing/printer_link.dart';
import '../../../services/scale/scale_service.dart';
import '../../../services/scale/serial_port.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/settings_controller.dart';
import '../../../ui/dialogs.dart';

/// Scales this device can talk to: COM ports on Windows, Bluetooth on
/// Android.
ScaleKind? get scaleKindHere => Platform.isWindows ? ScaleKind.serial : (Platform.isAndroid ? ScaleKind.bluetooth : null);

String scaleRequestLabel(AppLocalizations l, ScaleRequest r) => switch (r) {
      ScaleRequest.none => l.scaleRequestNone,
      ScaleRequest.w => l.scaleRequestLetter('W'),
      ScaleRequest.p => l.scaleRequestLetter('P'),
      ScaleRequest.enq => l.scaleRequestEnq,
    };

/// Settings → Scale: the port (or paired scale), its speed, how to ask for a
/// weight, and "Read the scale" to check.
Future<void> showScaleSetup(SettingsController settings) => Get.dialog<void>(_ScaleSetup(settings: settings));

class _ScaleSetup extends StatefulWidget {
  const _ScaleSetup({required this.settings});

  final SettingsController settings;

  @override
  State<_ScaleSetup> createState() => _ScaleSetupState();
}

class _ScaleSetupState extends State<_ScaleSetup> {
  final _service = Get.find<ScaleService>();
  late final ScaleTarget? _current = _service.scale;
  late final ScaleKind _kind = scaleKindHere ?? ScaleKind.serial;
  late String? _address = _current?.address;
  late int _baud = _current?.baud ?? 9600;
  late ScaleRequest _request = _current?.request ?? ScaleRequest.none;

  /// (name, address).
  List<(String, String)> _found = const [];
  bool _busy = false;
  String? _message;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _find();
  }

  void _say(String message, {bool failed = false}) => setState(() {
        _message = message;
        _failed = failed;
      });

  Future<void> _find() async {
    try {
      final found = _kind == ScaleKind.serial ? [for (final p in serialPorts()) (p, p)] : await pairedBluetooth();
      if (!mounted) return;
      setState(() => _found = found);
      // appL10n: this can run inside initState, before context is usable.
      if (found.isEmpty) _say(appL10n().scaleNoneFound);
    } on PrinterException catch (e) {
      if (mounted) _say(e.message, failed: true);
    }
  }

  ScaleTarget? get _target {
    final a = _address;
    if (a == null) return null;
    final name = _found.where((f) => f.$2 == a).firstOrNull?.$1 ?? _current?.name;
    return ScaleTarget(kind: _kind, address: a, name: name, baud: _baud, request: _request);
  }

  Future<void> _read() async {
    final t = _target;
    final l = context.l10n;
    if (t == null) return _say(l.scaleChooseFirst, failed: true);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final grams = await _service.readGrams(target: t);
      if (mounted) _say(l.scaleReadOk((grams / 1000).toStringAsFixed(3)));
    } on ScaleException catch (e) {
      if (mounted) _say(e.message, failed: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final t = _target;
    if (t == null) return _say(context.l10n.scaleChooseFirst, failed: true);
    if (!await widget.settings.saveAll([(AppSettings.scale, t.encode())])) return;
    goBack<void>();
    widget.settings.saved();
  }

  Future<void> _remove() async {
    if (!await widget.settings.saveAll([(AppSettings.scale, '')])) return;
    goBack<void>();
    widget.settings.saved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final serial = _kind == ScaleKind.serial;
    return AlertDialog(
      title: Text(l.scaleTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(serial ? l.scaleSerialHelp : l.scaleBluetoothHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s3),
            DropdownButtonFormField<String>(
              initialValue: _found.any((f) => f.$2 == _address) ? _address : null,
              isExpanded: true,
              decoration: InputDecoration(labelText: serial ? l.scalePort : l.scaleDevice),
              items: [
                for (final (name, address) in _found)
                  DropdownMenuItem(value: address, child: Text(name == address ? name : '$name  ($address)', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => _address = v),
            ),
            if (serial) ...[
              const SizedBox(height: AbySpace.s4),
              Text(l.scaleBaud, style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              SegmentedButton<int>(
                segments: [for (final b in ScaleTarget.bauds) ButtonSegment(value: b, label: Text('$b'))],
                selected: {_baud},
                onSelectionChanged: (s) => setState(() => _baud = s.first),
              ),
            ],
            const SizedBox(height: AbySpace.s4),
            DropdownButtonFormField<ScaleRequest>(
              initialValue: _request,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.scaleRequest, helperText: l.scaleRequestHelp),
              items: [
                for (final r in ScaleRequest.values) DropdownMenuItem(value: r, child: Text(scaleRequestLabel(l, r))),
              ],
              onChanged: (v) => setState(() => _request = v ?? ScaleRequest.none),
            ),
            const SizedBox(height: AbySpace.s4),
            OutlinedButton.icon(
              onPressed: _busy ? null : _read,
              icon: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.scale_outlined),
              label: Text(l.scaleRead),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s2),
                child: Text(_message!, style: AbyText.caption.copyWith(color: _failed ? c.danger : c.success)),
              ),
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
              if (_current != null) TextButton(onPressed: _remove, child: Text(l.scaleRemove)),
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}

String alertKindLabel(AppLocalizations l, AlertKind k) => switch (k) {
      AlertKind.lowStock => l.notifyLowStock,
      AlertKind.expiring => l.notifyExpiring,
      AlertKind.creditOverdue => l.notifyCredit,
      AlertKind.backup => l.notifyBackup,
      AlertKind.dayNotClosed => l.notifyDayOpen,
      AlertKind.parkedOld => l.notifyParked,
      AlertKind.expenseDue => l.notifyExpenses,
    };

/// Which notifications the signed-in person gets. Their own choice: no
/// approval needed.
Future<void> showNotificationChoices() async {
  final staff = Get.find<AuthService>().currentUser.value;
  if (staff == null) return;
  final service = Get.find<NotificationService>();
  final off = await service.offFor(staff.id);
  await Get.dialog<void>(StatefulBuilder(builder: (context, setState) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.notifyTitle),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.notifyHelp(staff.name), style: AbyText.caption),
          for (final k in AlertKind.values)
            SwitchListTile(
              title: Text(alertKindLabel(l, k)),
              value: !off.contains(k),
              contentPadding: EdgeInsets.zero,
              onChanged: (on) async {
                setState(() => on ? off.remove(k) : off.add(k));
                await service.setOff(staff.id, off);
              },
            ),
        ]),
      ),
      actions: [
        DialogButtons(children: [FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
        );
  }));
}
