import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/permissions.dart';
import '../core/validators.dart';
import '../data/repositories/customer_repository.dart';
import '../models/customer.dart';
import '../services/auth_service.dart';
import '../services/money.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'l10n.dart';
import 'dialogs.dart';

/// Find a customer by phone (4 digits are enough) or name, or add one with
/// just a name and phone. Null when cancelled.
Future<Customer?> pickCustomer() => Get.dialog<Customer>(const _CustomerPicker());

class _CustomerPicker extends StatefulWidget {
  const _CustomerPicker();

  @override
  State<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends State<_CustomerPicker> {
  final CustomerRepository _repo = Get.find();
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  List<Customer> _results = const [];
  bool _adding = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _find('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_search, _name, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () => _find(text));
  }

  Future<void> _find(String text) async {
    final list = await _repo.list(query: text, limit: 30);
    if (mounted) setState(() => _results = list);
  }

  void _startAdding() {
    final text = _search.text.trim();
    final isPhone = Validators.normalisePhone(text) != null;
    _phone.text = isPhone ? text : '';
    _name.text = isPhone ? '' : text;
    setState(() => _adding = true);
  }

  Future<void> _add() async {
    try {
      final id = await _repo.save(CustomerDraft(name: _name.text, phone: _phone.text), by: Get.find<AuthService>().user);
      goBack(result: await _repo.find(id));
    } on CustomerException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final canAdd = Get.find<AuthService>().can(Permission.sell);
    return AlertDialog(
      title: Text(_adding ? l.customerQuickAdd : l.customerPick),
      content: SizedBox(
        width: 440,
        height: _adding ? null : 420,
        child: _adding
            ? Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _name,
                  autofocus: _name.text.isEmpty,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: l.customerName),
                ),
                const SizedBox(height: AbySpace.s3),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: l.profilePhone, helperText: l.customerPhoneHelp),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AbySpace.s3),
                    child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
                  ),
              ])
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: _changed,
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.customerSearchHint),
                ),
                const SizedBox(height: AbySpace.s2),
                Expanded(
                  child: _results.isEmpty
                      ? Center(child: Text(l.customersNone, style: AbyText.body.copyWith(color: c.inkMuted)))
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final x = _results[i];
                            return ListTile(
                              title: Text(x.name),
                              subtitle: Text([
                                if (x.phone != null) Validators.formatPhone(x.phone!),
                                if (x.owed > 0) l.customerOwes(formatMoney(x.owed)),
                                if (x.wallet > 0) l.customerWallet(formatMoney(x.wallet)),
                              ].join('  ·  ')),
                              onTap: () => goBack(result: x),
                            );
                          },
                        ),
                ),
              ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<Customer>(), child: Text(l.commonCancel)),
          if (_adding)
            FilledButton(onPressed: _add, child: Text(l.commonSave))
          else if (canAdd)
            FilledButton.icon(onPressed: _startAdding, icon: const Icon(Icons.person_add_alt), label: Text(l.customerNew)),
        ]),
      ],
    );
  }
}
