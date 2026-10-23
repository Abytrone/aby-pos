import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/pin_hasher.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';

/// A 4-digit PIN keypad. Holds only the digits typed so far; [onSubmit]
/// decides whether the PIN is right and returns an error message, or null
/// when it is accepted. A hardware keyboard works too (Windows tills).
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onSubmit, this.title});

  final String? title;
  final Future<String?> Function(String pin) onSubmit;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  final _focus = FocusNode();
  String _pin = '';
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _digit(String d) async {
    if (_busy || _pin.length >= PinHasher.pinLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length < PinHasher.pinLength) return;
    setState(() => _busy = true);
    final error = await widget.onSubmit(_pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
      _error = error;
    });
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final char = event.character;
    if (char != null && RegExp(r'^\d$').hasMatch(char)) {
      _digit(char);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: ConstrainedBox(
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
            Semantics(
              label: '${_pin.length} of ${PinHasher.pinLength} digits entered',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < PinHasher.pinLength; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: AbySpace.s2),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length ? c.ink : Colors.transparent,
                        border: Border.all(color: c.lineStrong, width: 2),
                      ),
                    ),
                ],
              ),
            ),
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
            for (final row in const [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
            ])
              _KeyRow(children: [for (final d in row) _Key(label: d, onTap: () => _digit(d))]),
            _KeyRow(children: [
              const SizedBox(width: 80, height: 64),
              _Key(label: '0', onTap: () => _digit('0')),
              _Key(icon: Icons.backspace_outlined, semantic: 'Delete', onTap: _backspace),
            ]),
          ],
        ),
      ),
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
  const _Key({this.label, this.icon, this.semantic, required this.onTap});

  final String? label;
  final IconData? icon;
  final String? semantic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return SizedBox(
      width: 80,
      height: 64,
      child: Material(
        color: c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: c.line, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          onTap: onTap,
          child: Center(
            child: icon != null
                ? Icon(icon, color: c.ink, semanticLabel: semantic)
                : Text(label!,
                    style: AbyText.title.copyWith(color: c.ink, fontSize: 26)),
          ),
        ),
      ),
    );
  }
}
