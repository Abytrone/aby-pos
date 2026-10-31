import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../core/settings.dart';
import '../services/pin_hasher.dart';
import '../services/settings_service.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_icons.dart';
import '../theme/aby_theme.dart';
import 'l10n.dart';

/// How PINs are typed on this device (Settings → Security → PIN keypad).
enum PinPadMode {
  /// The keypad, in order. Typing on a keyboard folds it away.
  standard,

  /// The digits change places every time, and keys do not flash when
  /// pressed, so no one learns a PIN from where a finger lands.
  shuffled,

  /// No keypad on screen: a keyboard (or the device's own number keyboard).
  keyboard;

  static PinPadMode fromSetting(String v) => values.asNameMap()[v] ?? standard;
}

/// A 4-digit PIN keypad. Holds only the digits typed so far; [onSubmit]
/// decides whether the PIN is right and returns an error message, or null
/// when it is accepted. A hardware keyboard always works: the top row or
/// the number pad, Backspace to fix a digit, Esc to start again.
///
/// With [reveal] it takes something that is not secret, such as a staff
/// number: the digits show as typed and the keys never shuffle.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onSubmit,
    this.title,
    this.mode,
    this.length = PinHasher.pinLength,
    this.reveal = false,
    this.error,
  });

  final String? title;
  final Future<String?> Function(String pin) onSubmit;

  /// Null: this device's setting.
  final PinPadMode? mode;

  /// Digits to take before [onSubmit].
  final int length;
  final bool reveal;

  /// Shown until the first digit, e.g. why the pad came back.
  final String? error;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  final _focus = FocusNode(debugLabel: 'pin pad');
  final _field = TextEditingController();
  final _random = Random.secure();
  late PinPadMode _mode =
      widget.mode ??
      (Get.isRegistered<SettingsService>()
          ? PinPadMode.fromSetting(Get.find<SettingsService>().get(AppSettings.pinPad))
          : PinPadMode.standard);
  String _pin = '';
  late String? _error = widget.error;
  bool _busy = false;

  /// Someone typed on a keyboard: the keypad folds away for this entry.
  bool _typing = false;
  late List<String> _digits = _layout();

  /// Desktops nearly always have a keyboard, so say it works.
  static final _desktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  List<String> _layout() {
    final digits = [for (var i = 1; i <= 9; i++) '$i', '0'];
    if (_mode == PinPadMode.shuffled && !widget.reveal) digits.shuffle(_random);
    return digits;
  }

  @override
  void dispose() {
    _focus.dispose();
    _field.dispose();
    super.dispose();
  }

  Future<void> _digit(String d) async {
    if (_busy || _pin.length >= widget.length) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < widget.length) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
      _error = error;
      // A fresh layout for every try, so a second look teaches nothing.
      _digits = _layout();
    });
    _field.clear();
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _clear() {
    if (_busy) return;
    setState(() => _pin = '');
    _field.clear();
  }

  void _tap(String d) {
    if (_mode == PinPadMode.shuffled && !widget.reveal) HapticFeedback.selectionClick();
    _digit(d);
  }

  static final _numpad = {
    for (var i = 0; i <= 9; i++)
      [
        LogicalKeyboardKey.numpad0,
        LogicalKeyboardKey.numpad1,
        LogicalKeyboardKey.numpad2,
        LogicalKeyboardKey.numpad3,
        LogicalKeyboardKey.numpad4,
        LogicalKeyboardKey.numpad5,
        LogicalKeyboardKey.numpad6,
        LogicalKeyboardKey.numpad7,
        LogicalKeyboardKey.numpad8,
        LogicalKeyboardKey.numpad9,
      ][i]: '$i',
  };

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final char = event.character;
    final digit = char != null && RegExp(r'^\d$').hasMatch(char) ? char : _numpad[event.logicalKey];
    if (digit != null) {
      if (!_typing) setState(() => _typing = true);
      _digit(digit);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape && _pin.isNotEmpty) {
      _clear();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Keyboard mode: what the device keyboard typed.
  void _onField(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < _pin.length) {
      setState(() => _pin = digits);
      return;
    }
    for (final d in digits.substring(_pin.length).split('')) {
      _digit(d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final keyboardOnly = _mode == PinPadMode.keyboard;
    final showKeys = !keyboardOnly && !_typing;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final quiet = _mode == PinPadMode.shuffled && !widget.reveal;

    final dots = Semantics(
      label: widget.reveal ? _pin : l.pinDigitsEntered(_pin.length, widget.length),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < widget.length; i++)
            if (widget.reveal)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AbySpace.s1),
                width: 40,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AbyRadius.md),
                  border: Border.all(
                    color: _error != null && _pin.isEmpty
                        ? c.danger
                        : i == _pin.length
                            ? c.ink
                            : c.lineStrong,
                    width: 2,
                  ),
                ),
                child: Text(i < _pin.length ? _pin[i] : '', style: AbyText.title.copyWith(color: c.ink)),
              )
            else
            AnimatedContainer(
              duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: AbySpace.s2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? c.ink : Colors.transparent,
                border: Border.all(color: _error != null && _pin.isEmpty ? c.danger : c.lineStrong, width: 2),
              ),
            ),
        ],
      ),
    );

    final hint = keyboardOnly || _typing || _desktop
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AbyIcon(AbyIcons.keyboard, size: 16, color: c.inkMuted),
              const SizedBox(width: AbySpace.s1),
              Flexible(
                child: Text(
                  widget.reveal
                      ? (keyboardOnly || _typing ? l.digitsTypeOnKeyboard : l.digitsKeyboardWorks)
                      : (keyboardOnly || _typing ? l.pinTypeOnKeyboard : l.pinKeyboardWorks),
                  textAlign: TextAlign.center,
                  style: AbyText.caption.copyWith(color: c.inkMuted),
                ),
              ),
            ],
          )
        : null;

    final body = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Text(widget.title!,
                  textAlign: TextAlign.center,
                  style: AbyText.heading.copyWith(color: c.ink)),
              const SizedBox(height: AbySpace.s4),
            ],
          if (keyboardOnly)
            // The field sits over the dots: tapping them brings up the
            // device's number keyboard; nothing typed is ever shown.
            Stack(
              alignment: Alignment.center,
                children: [
                dots,
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _field,
                      autofocus: true,
                      obscureText: !widget.reveal,
                      enableSuggestions: false,
                      autocorrect: false,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      onChanged: _onField,
                    ),
                  ),
                ),
              ],
            )
          else
            dots,
            SizedBox(
              height: 40,
              child: Center(
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_error ?? '',
                        textAlign: TextAlign.center,
                        style: AbyText.caption.copyWith(color: c.danger)),
              ),
            ),
          AnimatedSize(
            duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: showKeys
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var r = 0; r < 3; r++)
              _KeyRow(children: [for (final d in _digits.sublist(r * 3, r * 3 + 3)) _Key(label: d, quiet: quiet, onTap: () => _tap(d))]),
            _KeyRow(children: [
                          _Key(icon: AbyIcons.x, semantic: l.pinClear, onTap: _clear, subtle: true),
              _Key(label: _digits[9], quiet: quiet, onTap: () => _tap(_digits[9])),
              _Key(icon: AbyIcons.delete, semantic: l.pinDelete, onTap: _backspace, subtle: true),
                        ],
                      ),
                      if (hint != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AbySpace.s1),
                          child: hint,
                        ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ?hint,
                      TextButton(
                        onPressed: () => setState(() {
                          _typing = false;
                          if (keyboardOnly) _mode = PinPadMode.shuffled;
                          _digits = _layout();
                        }),
                        child: Text(l.pinShowKeypad),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );

    if (keyboardOnly) return body;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      // A tap anywhere on the pad takes the keyboard back.
      child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _focus.requestFocus, child: body),
    );
  }
}

class _KeyRow extends StatelessWidget {
  const _KeyRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AbySpace.s2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key({this.label, this.icon, this.semantic, required this.onTap, this.quiet = false, this.subtle = false});

  final String? label;

  /// An [AbyIcons] asset.
  final String? icon;
  final String? semantic;
  final VoidCallback onTap;

  /// No press flash, so a watcher cannot see which key was hit.
  final bool quiet;

  /// Clear and delete: drawn lighter than the digits.
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: subtle ? Colors.transparent : c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: subtle ? Colors.transparent : c.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          canRequestFocus: false,
          splashFactory: quiet ? NoSplash.splashFactory : null,
          highlightColor: quiet ? Colors.transparent : null,
          onTap: onTap,
          child: Center(
            child: icon != null
                ? AbyIcon(icon!, size: 24, color: c.inkMuted, semanticLabel: semantic)
                : Text(label!,
                    style: AbyText.title.copyWith(color: c.ink, fontSize: 26)),
          ),
        ),
      ),
    );
  }
}
