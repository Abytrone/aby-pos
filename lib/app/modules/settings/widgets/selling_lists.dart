import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/discount_repository.dart';
import '../../../models/discount.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';

String reasonKindLabel(AppLocalizations l, ReasonKind k) => switch (k) {
      ReasonKind.discount => l.reasonsDiscount,
      ReasonKind.voidSale => l.reasonsVoid,
      ReasonKind.refund => l.reasonsRefund,
      ReasonKind.noSale => l.reasonsNoSale,
      ReasonKind.payIn => l.reasonsPayIn,
      ReasonKind.payOut => l.reasonsPayOut,
    };

String discountScopeLabel(AppLocalizations l, DiscountScope s) => switch (s) {
      DiscountScope.line => l.discountScopeLine,
      DiscountScope.order => l.discountScopeOrder,
      DiscountScope.any => l.discountScopeAny,
    };

/// Changes here need "Change settings" (or a PIN). Null when refused.
Future<Authorization?> _authorize() =>
    Get.find<PermissionService>().authorize(Permission.changeSettings, reason: appL10n().settingsApprovalReason);

/// Saved discounts: add, change, retire.
Future<void> showSavedDiscounts() => Get.dialog<void>(const _SavedDiscounts());

class _SavedDiscounts extends StatefulWidget {
  const _SavedDiscounts();

  @override
  State<_SavedDiscounts> createState() => _SavedDiscountsState();
}

class _SavedDiscountsState extends State<_SavedDiscounts> {
  final DiscountRepository _repo = Get.find();
  List<SavedDiscount> _list = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.discounts(includeInactive: true);
    if (mounted) setState(() => _list = list);
  }

  Future<void> _edit([SavedDiscount? d]) async {
    final saved = await Get.dialog<bool>(_DiscountEditor(discount: d));
    if (saved ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.settingsDiscounts),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.settingsDiscountsHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Flexible(
            child: _list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AbySpace.s4),
                    child: Text(l.discountsNone, style: AbyText.body.copyWith(color: c.inkMuted)),
                  )
                : ListView(shrinkWrap: true, children: [
                    for (final d in _list)
                      ListTile(
                        title: Text(d.name, style: TextStyle(color: d.active ? c.ink : c.inkMuted)),
                        subtitle: Text('${d.label}  ·  ${discountScopeLabel(l, d.scope)}'
                            '${d.active ? '' : '  ·  ${l.stockFilterRetired}'}'),
                        onTap: () => _edit(d),
                        trailing: TextButton(
                          onPressed: () async {
                            final auth = await _authorize();
                            if (auth == null) return;
                            await _repo.setDiscountActive(d.id, active: !d.active, by: auth.authority);
                            await _load();
                          },
                          child: Text(d.active ? l.stockRetire : l.stockRestore),
                        ),
                      ),
                  ]),
          ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(l.discountNew)),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}

class _DiscountEditor extends StatefulWidget {
  const _DiscountEditor({this.discount});

  final SavedDiscount? discount;

  @override
  State<_DiscountEditor> createState() => _DiscountEditorState();
}

class _DiscountEditorState extends State<_DiscountEditor> {
  late final _name = TextEditingController(text: widget.discount?.name ?? '');
  late DiscountKind _kind = widget.discount?.kind ?? DiscountKind.percent;
  late DiscountScope _scope = widget.discount?.scope ?? DiscountScope.any;
  late final _value = TextEditingController(
    text: switch (widget.discount) {
      null => '',
      final d when d.kind == DiscountKind.percent => '${d.value}',
      final d => (d.value / 100).toStringAsFixed(2),
    },
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final value = _kind == DiscountKind.percent ? int.tryParse(_value.text.trim()) : parseMoney(_value.text);
    if (value == null) {
      return setState(() => _error = _kind == DiscountKind.percent ? l.discountPercentInvalid : l.discountAmountInvalid);
    }
    final auth = await _authorize();
    if (auth == null) return;
    try {
      await Get.find<DiscountRepository>().saveDiscount(
        id: widget.discount?.id,
        name: _name.text,
        kind: _kind,
        value: value,
        scope: _scope,
        by: auth.authority,
      );
      goBack(result: true);
    } on DiscountException catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.discount == null ? l.discountNew : l.discountEdit),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _name,
            autofocus: widget.discount == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l.discountName, helperText: l.discountNameHelp),
          ),
          const SizedBox(height: AbySpace.s3),
          Row(children: [
            SegmentedButton<DiscountKind>(
              segments: const [
                ButtonSegment(value: DiscountKind.percent, label: Text('%')),
                ButtonSegment(value: DiscountKind.amount, label: Text('GH₵')),
              ],
              selected: {_kind},
              showSelectedIcon: false,
              onSelectionChanged: (v) => setState(() => _kind = v.single),
            ),
            const SizedBox(width: AbySpace.s3),
            Expanded(
              child: TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _kind == DiscountKind.percent ? l.discountPercent : l.discountAmount,
                  suffixText: _kind == DiscountKind.percent ? '%' : null,
                  prefixText: _kind == DiscountKind.amount ? 'GH₵ ' : null,
                ),
              ),
            ),
          ]),
          const SizedBox(height: AbySpace.s3),
          Text(l.discountScope.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
            for (final s in DiscountScope.values)
              OptionChip(label: discountScopeLabel(l, s), selected: _scope == s, onTap: () => setState(() => _scope = s)),
          ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s3),
              child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
            ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<bool>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}

/// One reasons list: add, rename, retire.
Future<void> showReasons(ReasonKind kind) => Get.dialog<void>(_Reasons(kind: kind));

class _Reasons extends StatefulWidget {
  const _Reasons({required this.kind});

  final ReasonKind kind;

  @override
  State<_Reasons> createState() => _ReasonsState();
}

class _ReasonsState extends State<_Reasons> {
  final DiscountRepository _repo = Get.find();
  List<Reason> _list = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.reasons(widget.kind, includeInactive: true);
    if (mounted) setState(() => _list = list);
  }

  Future<void> _edit([Reason? r]) async {
    final l = context.l10n;
    final name = await textInputDialog(title: r == null ? l.reasonNew : l.reasonEdit, label: l.reasonName, initial: r?.name ?? '');
    if (name == null) return;
    final auth = await _authorize();
    if (auth == null) return;
    try {
      await _repo.saveReason(id: r?.id, kind: widget.kind, name: name, by: auth.authority);
      await _load();
    } on DiscountException catch (e) {
      showMessage(e.message, tone: MessageTone.error);
    }
  }

  Future<void> _toggle(Reason r) async {
    final auth = await _authorize();
    if (auth == null) return;
    await _repo.setReasonActive(r.id, active: !r.active, by: auth.authority);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(reasonKindLabel(l, widget.kind)),
      content: SizedBox(
        width: 420,
        child: ListView(shrinkWrap: true, children: [
          for (final r in _list)
            ListTile(
              title: Text(r.name, style: TextStyle(color: r.active ? c.ink : c.inkMuted)),
              subtitle: r.active ? null : Text(l.stockFilterRetired),
              onTap: () => _edit(r),
              trailing: TextButton(onPressed: () => _toggle(r), child: Text(r.active ? l.stockRetire : l.stockRestore)),
            ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(l.reasonNew)),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}
