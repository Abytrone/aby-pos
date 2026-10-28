import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/pay_method_repository.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/permission_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';

String payKindLabel(AppLocalizations l, PaymentMethod k) => switch (k) {
      PaymentMethod.cash => l.payKindCash,
      PaymentMethod.momo => l.payKindMomo,
      PaymentMethod.credit => l.payKindCredit,
      PaymentMethod.card => l.payKindCard,
      PaymentMethod.bank => l.payKindBank,
      PaymentMethod.cheque => l.payKindCheque,
      PaymentMethod.exchange => l.payKindExchange,
      PaymentMethod.other => l.payKindOther,
      PaymentMethod.wallet => l.payKindWallet,
      PaymentMethod.voucher => l.payKindVoucher,
    };

Future<Authorization?> _authorize() =>
    Get.find<PermissionService>().authorize(Permission.changeSettings, reason: appL10n().settingsApprovalReason);

/// The shop's payment methods: switch on, rename, add the shop's number.
Future<void> showPayMethods() => Get.dialog<void>(const _PayMethods());

class _PayMethods extends StatefulWidget {
  const _PayMethods();

  @override
  State<_PayMethods> createState() => _PayMethodsState();
}

class _PayMethodsState extends State<_PayMethods> {
  final PayMethodRepository _repo = Get.find();
  List<PayMethod> _list = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.list(includeInactive: true);
    if (mounted) setState(() => _list = list);
  }

  Future<void> _toggle(PayMethod m, bool on) async {
    final auth = await _authorize();
    if (auth == null) return;
    try {
      await _repo.setActive(m.id, active: on, by: auth.authority);
    } on PayMethodException catch (e) {
      showMessage(e.message);
    }
    await _load();
  }

  Future<void> _edit([PayMethod? m]) async {
    if (await Get.dialog<bool>(_PayMethodEditor(method: m)) ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.settingsPayMethods),
      content: SizedBox(
        width: 480,
        child: ListView(shrinkWrap: true, children: [
          for (final m in _list)
            SwitchListTile(
              value: m.active,
              onChanged: m.builtIn == 'cash' ? null : (v) => _toggle(m, v),
              title: Text(m.name),
              subtitle: Text(
                [
                  payKindLabel(l, m.kind),
                  if (m.needsReference) l.payNeedsReference,
                  ?m.merchantNumber,
                ].join('  ·  '),
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
              secondary: IconButton(tooltip: l.commonEdit, icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(m)),
            ),
        ]),
      ),
      actions: [
        OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(l.payMethodNew)),
        FilledButton(onPressed: () => Get.back<void>(), child: Text(l.commonDone)),
      ],
    );
  }
}

class _PayMethodEditor extends StatefulWidget {
  const _PayMethodEditor({this.method});

  final PayMethod? method;

  @override
  State<_PayMethodEditor> createState() => _PayMethodEditorState();
}

class _PayMethodEditorState extends State<_PayMethodEditor> {
  late final _name = TextEditingController(text: widget.method?.name ?? '');
  late final _number = TextEditingController(text: widget.method?.merchantNumber ?? '');
  late PaymentMethod _kind = widget.method?.kind ?? PaymentMethod.momo;
  late bool _needsReference = widget.method?.needsReference ?? true;
  late bool _short = widget.method?.shortReference ?? false;
  String? _error;

  bool get _isCash => widget.method?.builtIn == 'cash';

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = await _authorize();
    if (auth == null) return;
    try {
      await Get.find<PayMethodRepository>().save(
        id: widget.method?.id,
        name: _name.text,
        kind: _kind,
        needsReference: !_isCash && _needsReference,
        shortReference: _short,
        merchantNumber: _number.text,
        by: auth.authority,
      );
      Get.back(result: true);
    } on PayMethodException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.method == null ? l.payMethodNew : l.payMethodEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _name, decoration: InputDecoration(labelText: l.payMethodName)),
            if (!_isCash) ...[
              const SizedBox(height: AbySpace.s3),
              Text(l.payMethodKind.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                for (final k in PaymentMethod.values.where((k) => k != PaymentMethod.exchange))
                  OptionChip(label: payKindLabel(l, k), selected: _kind == k, onTap: () => setState(() => _kind = k)),
              ]),
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _number,
                decoration: InputDecoration(labelText: l.payMerchantNumber, helperText: l.payMerchantNumberHelp, helperMaxLines: 2),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.payNeedsReference),
                subtitle: Text(l.payNeedsReferenceHelp),
                value: _needsReference,
                onChanged: (v) => setState(() => _needsReference = v),
              ),
              if (_needsReference)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.payShortReference),
                  subtitle: Text(l.payShortReferenceHelp),
                  value: _short,
                  onChanged: (v) => setState(() => _short = v),
                ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<bool>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
