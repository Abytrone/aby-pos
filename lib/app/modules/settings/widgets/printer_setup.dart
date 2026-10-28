import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../domain/receipt/receipt_doc.dart';
import '../../../models/receipt.dart';
import '../../../services/printing/bluetooth_link.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/printing/printer_link.dart';
import '../../../services/printing/windows_spooler.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/settings_controller.dart';

String printerKindLabel(AppLocalizations l, PrinterKind k) => switch (k) {
      PrinterKind.network => l.printerNetwork,
      PrinterKind.windows => l.printerWindows,
      PrinterKind.bluetooth => l.printerBluetooth,
    };

/// The kinds of printer this device can talk to.
List<PrinterKind> availableKinds() => [
      PrinterKind.network,
      if (Platform.isWindows) PrinterKind.windows,
      if (Platform.isAndroid) PrinterKind.bluetooth,
    ];

/// Settings → Receipt printer: which printer, its paper, and a test page.
/// [kitchen]: the printer for kitchen tickets instead.
Future<void> showPrinterSetup(SettingsController settings, {bool kitchen = false}) =>
    Get.dialog<void>(_PrinterSetup(settings: settings, kitchen: kitchen));

class _PrinterSetup extends StatefulWidget {
  const _PrinterSetup({required this.settings, this.kitchen = false});

  final SettingsController settings;
  final bool kitchen;

  @override
  State<_PrinterSetup> createState() => _PrinterSetupState();
}

class _PrinterSetupState extends State<_PrinterSetup> {
  final _print = Get.find<PrintService>();
  late final Setting<String> _setting = widget.kitchen ? AppSettings.kitchenPrinter : AppSettings.receiptPrinter;
  late final PrinterTarget? _current = PrinterTarget.decode(widget.settings.value(_setting));
  late PrinterKind _kind = _current?.kind ?? availableKinds().last;
  late final _address = TextEditingController(text: _current?.kind == PrinterKind.network ? _current!.address : '');
  late int _paper = widget.settings.value(AppSettings.paperWidth);

  /// Windows printers or paired Bluetooth devices: (name, address).
  List<(String, String)> _found = const [];
  String? _picked;
  bool _busy = false;
  String? _message;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (_current != null && _current.kind != PrinterKind.network) _picked = _current.address;
    _find();
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _find() async {
    if (_kind == PrinterKind.network) return;
    setState(() => _busy = true);
    try {
      final found = _kind == PrinterKind.windows
          ? [for (final n in windowsPrinters()) (n, n)]
          : await pairedBluetooth();
      if (!mounted) return;
      setState(() {
        _found = found;
        // appL10n: this can run inside initState, before context is usable.
        _message = found.isEmpty ? appL10n().printerNoneFound : null;
        _failed = false;
      });
    } on PrinterException catch (e) {
      if (mounted) _say(e.message, failed: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String message, {bool failed = false}) => setState(() {
        _message = message;
        _failed = failed;
      });

  PrinterTarget? get _target {
    if (_kind == PrinterKind.network) {
      final a = _address.text.trim();
      return a.isEmpty ? null : PrinterTarget(kind: _kind, address: a);
    }
    final hit = _found.where((f) => f.$2 == _picked).firstOrNull;
    if (hit != null) return PrinterTarget(kind: _kind, address: hit.$2, name: hit.$1);
    return _current != null && _current.kind == _kind && _current.address == _picked ? _current : null;
  }

  Future<void> _test() async {
    final t = _target;
    final l = context.l10n;
    if (t == null) return _say(l.printerChooseFirst, failed: true);
    setState(() {
      _busy = true;
      _message = null;
    });
    final error = await _print.test(t, Paper.fromMillimetres(_paper));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = error != null;
      _message = error ?? l.printerTestSent;
    });
  }

  Future<void> _save() async {
    final t = _target;
    final l = context.l10n;
    if (t == null) return _say(l.printerChooseFirst, failed: true);
    final ok = await widget.settings.saveAll([
      (_setting, t.encode()),
      if (!widget.kitchen) (AppSettings.paperWidth, _paper),
    ]);
    if (!ok) return;
    Get.back<void>();
    widget.settings.saved();
  }

  Future<void> _remove() async {
    if (!await widget.settings.saveAll([(_setting, '')])) return;
    Get.back<void>();
    widget.settings.saved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final kinds = availableKinds();
    return AlertDialog(
      title: Text(widget.kitchen ? l.kitchenPrinterTitle : l.printerTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (kinds.length > 1)
              SegmentedButton<PrinterKind>(
                segments: [for (final k in kinds) ButtonSegment(value: k, label: Text(printerKindLabel(l, k)))],
                selected: {_kind},
                onSelectionChanged: (s) {
                  setState(() {
                    _kind = s.first;
                    _found = const [];
                    _picked = null;
                    _message = null;
                  });
                  _find();
                },
              ),
            const SizedBox(height: AbySpace.s4),
            if (_kind == PrinterKind.network)
              TextField(
                controller: _address,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(labelText: l.printerAddress, helperText: l.printerAddressHelp),
              )
            else ...[
              Text(_kind == PrinterKind.windows ? l.printerWindowsHelp : l.printerBluetoothHelp,
                  style: AbyText.caption.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              RadioGroup<String>(
                groupValue: _picked,
                onChanged: (v) => setState(() => _picked = v),
                child: Column(children: [
                  for (final (name, address) in _found)
                    RadioListTile<String>(
                      value: address,
                      title: Text(name),
                      subtitle: name == address ? null : Text(address),
                      contentPadding: EdgeInsets.zero,
                    ),
                ]),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(onPressed: _busy ? null : _find, icon: const Icon(Icons.refresh), label: Text(l.printerLookAgain)),
              ),
            ],
            // Kitchen tickets are 80 mm.
            if (!widget.kitchen) ...[
              const SizedBox(height: AbySpace.s4),
              Text(l.printerPaper, style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              SegmentedButton<int>(
                segments: const [ButtonSegment(value: 58, label: Text('58 mm')), ButtonSegment(value: 80, label: Text('80 mm'))],
                selected: {_paper},
                onSelectionChanged: (s) => setState(() => _paper = s.first),
              ),
            ],
            const SizedBox(height: AbySpace.s4),
            OutlinedButton.icon(
              onPressed: _busy ? null : _test,
              icon: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.receipt_long_outlined),
              label: Text(l.printerTest),
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
        if (_current != null) TextButton(onPressed: _remove, child: Text(l.printerRemove)),
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
