import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/aby_colors.dart';
import 'l10n.dart';

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
        OutlinedButton(
          onPressed: () => Get.back(result: false),
          child: Text(cancelLabel ?? context.l10n.commonCancel),
        ),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: c.danger) : null,
          onPressed: () => Get.back(result: true),
          child: Text(confirmLabel),
        ),
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
    Get.back(result: _field.text);
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
        OutlinedButton(onPressed: () => Get.back<String>(), child: Text(context.l10n.commonCancel)),
        FilledButton(onPressed: _submit, child: Text(widget.confirmLabel ?? context.l10n.commonSave)),
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
            onTap: () => Get.back(result: option),
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
  if (Get.isDialogOpen ?? false) Get.back<void>();
}
