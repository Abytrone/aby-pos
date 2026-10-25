import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/validators.dart';
import '../../../models/customer.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

/// Add or change a customer. [onSave] returns true when saved.
Future<void> showCustomerForm({Customer? customer, required Future<bool> Function(CustomerDraft) onSave}) =>
    Get.dialog<void>(_CustomerForm(customer: customer, onSave: onSave));

class _CustomerForm extends StatefulWidget {
  const _CustomerForm({this.customer, required this.onSave});

  final Customer? customer;
  final Future<bool> Function(CustomerDraft) onSave;

  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  Customer? get c => widget.customer;
  late final _name = TextEditingController(text: c?.name ?? '');
  late final _phone = TextEditingController(text: c?.phone == null ? '' : Validators.formatPhone(c!.phone!));
  late final _phone2 = TextEditingController(text: c?.phone2 == null ? '' : Validators.formatPhone(c!.phone2!));
  late final _location = TextEditingController(text: c?.location ?? '');
  late final _notes = TextEditingController(text: c?.notes ?? '');
  late final _tags = TextEditingController(text: c?.tags.join(', ') ?? '');
  late final _limit = TextEditingController(text: c?.creditLimit == null ? '' : (c!.creditLimit! / 100).toStringAsFixed(2));
  late final _days = TextEditingController(text: c?.dueDays?.toString() ?? '');
  late DateTime? _birthday = c?.birthday;
  String? _error;

  @override
  void dispose() {
    for (final x in [_name, _phone, _phone2, _location, _notes, _tags, _limit, _days]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final limit = _limit.text.trim().isEmpty ? null : parseMoney(_limit.text);
    if (_limit.text.trim().isNotEmpty && limit == null) return setState(() => _error = l.customerLimitInvalid);
    final ok = await widget.onSave(CustomerDraft(
      id: c?.id,
      name: _name.text,
      phone: _phone.text,
      phone2: _phone2.text,
      location: _location.text,
      notes: _notes.text,
      birthday: _birthday,
      tags: _tags.text.split(','),
      creditLimit: limit,
      dueDays: int.tryParse(_days.text.trim()),
    ));
    if (ok) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    Widget gap() => const SizedBox(height: AbySpace.s3);
    return AlertDialog(
      title: Text(c == null ? l.customerNew : l.customerEdit),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _name,
              autofocus: c == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.customerName),
            ),
            gap(),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.profilePhone, helperText: l.customerPhoneHelp),
            ),
            gap(),
            TextField(controller: _phone2, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.customerPhone2)),
            gap(),
            TextField(controller: _location, decoration: InputDecoration(labelText: l.customerLocation, helperText: l.customerLocationHelp)),
            gap(),
            Row(children: [
              Expanded(
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l.customerBirthday),
                  child: Text(_birthday == null ? l.settingsNotSet : formatDate(_birthday!)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _birthday ?? DateTime(2000),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _birthday = d);
                },
                child: Text(l.commonEdit),
              ),
            ]),
            gap(),
            TextField(controller: _tags, decoration: InputDecoration(labelText: l.customerTags, helperText: l.customerTagsHelp)),
            gap(),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _limit,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.customerLimit, prefixText: 'GH₵ ', helperText: l.customerLimitHelp),
                ),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l.customerDueDays, suffixText: l.supplierDays, helperText: l.customerDueDaysHelp),
                ),
              ),
            ]),
            gap(),
            TextField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: l.profileNotes)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: colors.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
