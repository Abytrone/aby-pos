import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';

import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'l10n.dart';

/// Closes the top dialog, sheet or page with [result]. Use this, not
/// Get.back: while a message from [showMessage] is up, Get.back closes the
/// message and leaves the dialog open.
void goBack<T>({T? result}) {
  final navigator = Get.key.currentState;
  if (navigator != null && navigator.canPop()) navigator.pop<T>(result);
}

/// Yes/no question. [danger] colours the confirm button red.
Future<bool> confirmDialog({
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool danger = false,
}) async {
  final result = await Get.dialog<bool>(Builder(builder: (context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        DialogButtons(children: [
                  OutlinedButton(
            onPressed: () => goBack(result: false),
            child: Text(cancelLabel ?? context.l10n.commonCancel),
          ),
          FilledButton(
            style: danger ? FilledButton.styleFrom(backgroundColor: c.danger) : null,
            onPressed: () => goBack(result: true),
            child: Text(confirmLabel),
                  ),
        ]),
      ],
    );
  }));
  return result ?? false;
}

/// A one-line message at the bottom of the screen.
void showMessage(String message) {
  if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
  Get.showSnackbar(GetSnackBar(
    message: message,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(12),
    borderRadius: 14,
  ));
}

/// Asks for a single line of text. Returns null when cancelled.
Future<String?> textInputDialog({
  required String title,
  required String label,
  String initial = '',
  String? helper,
  bool obscure = false,
  TextInputType? keyboardType,
  String? Function(String value)? validate,
  String? confirmLabel,
}) =>
    Get.dialog<String>(_TextInputDialog(
      title: title,
      label: label,
      initial: initial,
      helper: helper,
      obscure: obscure,
      keyboardType: keyboardType,
      validate: validate,
      confirmLabel: confirmLabel,
    ));

/// Owns its text field, so it outlives the closing animation.
class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.label,
    required this.initial,
    this.helper,
    this.obscure = false,
    this.keyboardType,
    this.validate,
    this.confirmLabel,
  });

  final String title;
  final String label;
  final String initial;
  final String? helper;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String value)? validate;
  final String? confirmLabel;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  late final _field = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _submit() {
    final message = widget.validate?.call(_field.text);
    if (message != null) return setState(() => _error = message);
    goBack(result: _field.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: _field,
          autofocus: true,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            labelText: widget.label,
            helperText: widget.helper,
            helperMaxLines: 3,
            errorText: _error,
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<String>(), child: Text(context.l10n.commonCancel)),
          FilledButton(onPressed: _submit, child: Text(widget.confirmLabel ?? context.l10n.commonSave)),
        ]),
      ],
    );
  }
}

/// Pick one of [options]. Returns null when cancelled.
Future<T?> choiceDialog<T>({
  required String title,
  required List<T> options,
  required String Function(T option) label,
  T? selected,
}) {
  return Get.dialog<T>(Builder(builder: (context) {
    return SimpleDialog(
      title: Text(title),
      children: [
        for (final option in options)
          ListTile(
            minTileHeight: 56,
            title: Text(label(option)),
            trailing: option == selected ? const Icon(Icons.check) : null,
            onTap: () => goBack(result: option),
          ),
      ],
    );
  }));
}

bool _progressOpen = false;

/// A blocking "working on it" dialog for slow steps (encrypting, restoring).
void showProgress(String message) {
  if (_progressOpen) return;
  _progressOpen = true;
  Get.dialog<void>(
    PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ]),
      ),
    ),
    barrierDismissible: false,
  );
}

void hideProgress() {
  if (!_progressOpen) return;
  _progressOpen = false;
  if (Get.isDialogOpen ?? false) goBack<void>();
}

/// A dialog's buttons, side by side. When they fit, one row at the end
/// (as Material lays them out). When they don't (phones), two to a row at
/// equal widths, with the last, main button across the bottom when there
/// is an odd number. Material would stack them one above the other instead.
class DialogButtons extends MultiChildRenderObjectWidget {
  const DialogButtons({super.key, required super.children});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderDialogButtons();
}

class _ButtonsParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDialogButtons extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _ButtonsParentData>, RenderBoxContainerDefaultsMixin<RenderBox, _ButtonsParentData> {
  static const _gap = AbySpace.s2;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ButtonsParentData) child.parentData = _ButtonsParentData();
  }

  List<RenderBox> get _buttons {
    final out = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      out.add(child);
      child = childAfter(child);
    }
    return out;
  }

  @override
  double computeMinIntrinsicWidth(double height) => _buttons.fold(0, (m, b) => math.max(m, b.getMinIntrinsicWidth(height)));

  @override
  double computeMaxIntrinsicWidth(double height) {
    final buttons = _buttons;
    if (buttons.isEmpty) return 0;
    return buttons.fold<double>(0, (s, b) => s + b.getMaxIntrinsicWidth(height)) + _gap * (buttons.length - 1);
  }

  @override
  double computeMinIntrinsicHeight(double width) => _arrange(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) => computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _arrange(constraints, dry: true);

  @override
  void performLayout() => size = _arrange(constraints, dry: false);

  Size _arrange(BoxConstraints c, {required bool dry}) {
    final buttons = _buttons;
    if (buttons.isEmpty) return c.smallest;
    Size measure(RenderBox b, BoxConstraints bc) {
      if (dry) return b.getDryLayout(bc);
      b.layout(bc, parentUsesSize: true);
      return b.size;
    }

    void place(RenderBox b, Offset at) {
      if (!dry) (b.parentData! as _ButtonsParentData).offset = at;
    }

    final natural = buttons.fold<double>(0, (s, b) => s + b.getMaxIntrinsicWidth(double.infinity)) + _gap * (buttons.length - 1);
    if (natural <= c.maxWidth) {
      final sizes = [for (final b in buttons) measure(b, BoxConstraints(maxWidth: c.maxWidth))];
      final used = sizes.fold<double>(0, (s, z) => s + z.width) + _gap * (buttons.length - 1);
      final height = sizes.fold<double>(0, (m, z) => math.max(m, z.height));
      final size = c.constrain(Size(used, height));
      var x = size.width - used;
      for (var i = 0; i < buttons.length; i++) {
        place(buttons[i], Offset(x, (height - sizes[i].height) / 2));
        x += sizes[i].width + _gap;
      }
      return size;
    }
    // Two to a row; an odd last one (the main button) gets a row to itself.
    final width = c.maxWidth;
    final half = (width - _gap) / 2;
    var y = 0.0;
    for (var i = 0; i < buttons.length; i += 2) {
      final pair = i + 1 < buttons.length;
      if (pair) {
        final a = measure(buttons[i], BoxConstraints.tightFor(width: half));
        final b = measure(buttons[i + 1], BoxConstraints.tightFor(width: half));
        final h = math.max(a.height, b.height);
        place(buttons[i], Offset(0, y + (h - a.height) / 2));
        place(buttons[i + 1], Offset(half + _gap, y + (h - b.height) / 2));
        y += h + _gap;
      } else {
        final a = measure(buttons[i], BoxConstraints.tightFor(width: width));
        place(buttons[i], Offset(0, y));
        y += a.height + _gap;
      }
    }
    return c.constrain(Size(width, y - _gap));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => defaultHitTestChildren(result, position: position);
}
