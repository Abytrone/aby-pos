import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/validators.dart';
import '../../../models/purchasing.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/dialogs.dart';

/// Name, contact and payment terms. [onSave] returns true when saved.
Future<void> showSupplierEditor({Supplier? supplier, required Future<bool> Function(SupplierDraft) onSave}) =>
    Get.dialog<void>(_SupplierEditor(supplier: supplier, onSave: onSave));

class _SupplierEditor extends StatefulWidget {
  const _SupplierEditor({this.supplier, required this.onSave});

  final Supplier? supplier;
  final Future<bool> Function(SupplierDraft) onSave;

  @override
  State<_SupplierEditor> createState() => _SupplierEditorState();
}

class _SupplierEditorState extends State<_SupplierEditor> {
  late final _name = TextEditingController(text: widget.supplier?.name ?? '');
  late final _phone = TextEditingController(
      text: widget.supplier?.phone == null ? '' : Validators.formatPhone(widget.supplier!.phone!));
  late final _email = TextEditingController(text: widget.supplier?.email ?? '');
  late final _address = TextEditingController(text: widget.supplier?.address ?? '');
  late final _terms = TextEditingController(text: widget.supplier?.paymentTermsDays?.toString() ?? '');
  late final _notes = TextEditingController(text: widget.supplier?.notes ?? '');
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _terms, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final phone = _phone.text.trim().isEmpty ? null : Validators.normalisePhone(_phone.text);
    if (_phone.text.trim().isNotEmpty && phone == null) return setState(() => _error = l.profilePhoneInvalid);
    final email = _email.text.trim().isEmpty ? null : Validators.normaliseEmail(_email.text);
    if (_email.text.trim().isNotEmpty && email == null) return setState(() => _error = l.profileEmailInvalid);
    final ok = await widget.onSave(SupplierDraft(
      id: widget.supplier?.id,
      name: _name.text,
      phone: phone,
      email: email,
      address: _address.text,
      notes: _notes.text,
      paymentTermsDays: int.tryParse(_terms.text.trim()),
    ));
    if (ok) goBack<void>();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    Widget gap() => const SizedBox(height: AbySpace.s3);
    return AlertDialog(
      title: Text(widget.supplier == null ? l.supplierNew : l.supplierEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _name,
              autofocus: widget.supplier == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.supplierName),
            ),
            gap(),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.profilePhone),
            ),
            gap(),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.profileEmail),
            ),
            gap(),
            TextField(controller: _address, decoration: InputDecoration(labelText: l.profileAddress)),
            gap(),
            TextField(
              controller: _terms,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: l.supplierTerms, helperText: l.supplierTermsHelp, suffixText: l.supplierDays),
            ),
            gap(),
            TextField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: l.profileNotes)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
