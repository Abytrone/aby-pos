import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/pin_reset.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../services/pin_hasher.dart';
import '../../../services/pin_recovery_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

/// "Forgot your PIN?": an owner proves who they are with their recovery
/// code or a reset code from the Aby supplier, then sets a new PIN. Returns
/// the owner's new recovery code once they are signed in, or null.
///
/// The supplier may take hours to answer, so a request stays open on this
/// till (PinRecoveryService.requestLife). With one open, the dialog opens
/// on it, ready for the reset code.
Future<String?> showForgotPin() => Get.dialog<String>(const _ForgotPin());

enum _Step { choose, recoveryCode, supplier, newPin }

class _ForgotPin extends StatefulWidget {
  const _ForgotPin();

  @override
  State<_ForgotPin> createState() => _ForgotPinState();
}

class _ForgotPinState extends State<_ForgotPin> {
  final PinRecoveryService _recovery = Get.find();
  final _number = TextEditingController();
  final _code = TextEditingController();
  final _reset = TextEditingController();
  final _pin = TextEditingController();
  final _confirm = TextEditingController();

  var _step = _Step.choose;
  PinResetRequest? _request;

  /// When [_request] stops working.
  DateTime? _expires;

  /// A request was already open when the dialog opened.
  bool _resumed = false;
  Staff? _owner;
  bool _bySupplier = false;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _resume();
  }

  Future<void> _resume() async {
    final open = await _recovery.waiting();
    if (open == null || !mounted) return;
    setState(() {
      _request = open.request;
      _expires = open.expires;
      _number.text = open.request.staffNumber;
      _resumed = true;
      _step = _Step.supplier;
    });
  }

  @override
  void dispose() {
    for (final c in [_number, _code, _reset, _pin, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _go(_Step step) => setState(() {
        _step = step;
        _error = null;
      });

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on StaffException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkRecoveryCode() => _run(() async {
        final l = appL10n();
        try {
          final owner = await _recovery.withRecoveryCode(_number.text, _code.text);
          if (owner == null) {
            _error = l.recoveryCodeWrong;
            return;
          }
          _owner = owner;
          _bySupplier = false;
          _step = _Step.newPin;
        } on LockedOutException catch (e) {
          _error = l.pinTooManyTries(e.wait.inSeconds);
        }
      });

  Future<void> _askSupplier() => _run(() async {
        _request = await _recovery.request(_number.text);
        _expires = (await _recovery.waiting())?.expires;
      });

  Future<void> _startAgain() => _run(() async {
        await _recovery.cancelRequest();
        _request = null;
        _expires = null;
        _resumed = false;
        _reset.clear();
      });

  Future<void> _checkResetCode() => _run(() async {
        final owner = await _recovery.redeem(_reset.text);
        if (owner == null) {
          _error = appL10n().supplierResetWrong;
          return;
        }
        _owner = owner;
        _bySupplier = true;
        _step = _Step.newPin;
      });

  Future<void> _save() => _run(() async {
        final l = appL10n();
        if (!PinHasher.isValidPin(_pin.text)) {
          _error = l.pinMustBeDigits(PinHasher.pinLength);
          return;
        }
        if (_pin.text != _confirm.text) {
          _error = l.pinMismatch;
          return;
        }
        final code = await _recovery.setNewPin(_owner!, _pin.text, bySupplier: _bySupplier);
        goBack(result: code);
      });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final number = TextField(
      controller: _number,
      autofocus: true,
      keyboardType: TextInputType.number,
      inputFormatters: [...digits, LengthLimitingTextInputFormatter(StaffRepository.numberLength)],
      decoration: InputDecoration(labelText: l.staffNumberTitle),
      onChanged: (_) => setState(() {
        // A request is for one number.
        if (_request?.staffNumber != _number.text) _request = null;
      }),
    );

    final (List<Widget> body, Widget? primary) = switch (_step) {
      _Step.choose => (
          [
            Text(l.forgotPinIntro, style: AbyText.body.copyWith(color: c.ink)),
            const SizedBox(height: AbySpace.s4),
            FilledButton(onPressed: () => _go(_Step.recoveryCode), child: Text(l.forgotPinUseCode)),
            const SizedBox(height: AbySpace.s2),
            OutlinedButton(onPressed: () => _go(_Step.supplier), child: Text(l.forgotPinAskSupplier)),
          ],
          null,
        ),
      _Step.recoveryCode => (
          [
            number,
            const SizedBox(height: AbySpace.s3),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: l.recoveryCodeLabel, hintText: 'XXXX-XXXX-XXXX'),
              onSubmitted: (_) => _checkRecoveryCode(),
            ),
          ],
          FilledButton(onPressed: _busy ? null : _checkRecoveryCode, child: Text(l.commonContinue)),
        ),
      _Step.supplier => (
          [
            if (_request == null) ...[
              number,
              const SizedBox(height: AbySpace.s3),
              OutlinedButton(
                onPressed: _busy || _number.text.length != StaffRepository.numberLength ? null : _askSupplier,
                child: Text(l.supplierGetRequest),
              ),
            ] else ...[
              // Fixed while the request is open: it is for this number.
              Text(l.staffNumberLabel(_request!.staffNumber), style: AbyText.body.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              if (!_resumed) ...[
                Text(l.supplierRequestIntro, style: AbyText.body.copyWith(color: c.ink)),
                const SizedBox(height: AbySpace.s2),
              ],
              Container(
                padding: const EdgeInsets.all(AbySpace.s3),
                decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.md)),
                child: Row(children: [
                  Expanded(
                    child: SelectableText(
                      _request!.code,
                      style: AbyText.body.copyWith(color: c.ink, fontFamily: AbyText.mono, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: l.commonCopy,
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _request!.code));
                      showMessage(l.commonCopied, tone: MessageTone.success);
                    },
                  ),
                ]),
              ),
              if (_expires != null) ...[
                const SizedBox(height: AbySpace.s3),
                Container(
                  padding: const EdgeInsets.all(AbySpace.s3),
                  decoration: BoxDecoration(color: c.blueSoft, borderRadius: BorderRadius.circular(AbyRadius.md)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.schedule, size: 20, color: c.blue),
                    const SizedBox(width: AbySpace.s2),
                    Expanded(
                      child: Text(l.supplierWaitNote(formatDate(_expires!)),
                          style: AbyText.caption.copyWith(color: c.ink)),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _reset,
                autofocus: _resumed,
                minLines: 2,
                maxLines: 4,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(labelText: l.supplierResetCode, hintText: 'ABYP.…'),
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: _busy ? null : _startAgain, child: Text(l.supplierStartAgain)),
              ),
            ],
          ],
          _request == null
              ? null
              : FilledButton(
                  onPressed: _busy || _reset.text.trim().isEmpty ? null : _checkResetCode,
                  child: Text(l.commonContinue),
                ),
        ),
      _Step.newPin => (
          [
            TextField(
              controller: _pin,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [...digits, LengthLimitingTextInputFormatter(PinHasher.pinLength)],
              decoration: InputDecoration(labelText: l.pinNewLabel),
            ),
            const SizedBox(height: AbySpace.s3),
            TextField(
              controller: _confirm,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [...digits, LengthLimitingTextInputFormatter(PinHasher.pinLength)],
              decoration: InputDecoration(labelText: l.pinAgainLabel),
              onSubmitted: (_) => _save(),
            ),
          ],
          FilledButton(onPressed: _busy ? null : _save, child: Text(l.newPinSave)),
        ),
    };

    return AlertDialog(
      title: Text(switch (_step) {
        _Step.newPin => l.newPinTitle,
        _Step.supplier when _resumed => l.supplierWaiting,
        _ => l.forgotPinLink,
      }),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...body,
              if (_error != null) ...[
                const SizedBox(height: AbySpace.s3),
                Text(_error!, style: AbyText.caption.copyWith(color: c.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [
          OutlinedButton(
            onPressed: () => goBack<String>(),
            // The request stays open: closing is not giving up.
            child: Text(_step == _Step.supplier && _request != null ? l.forgotPinCloseForNow : l.commonCancel),
          ),
          ?primary,
        ]),
      ],
    );
  }
}
