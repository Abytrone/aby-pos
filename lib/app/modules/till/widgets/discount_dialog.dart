import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/discount.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/dialogs.dart';

/// What the discount dialog decided: a discount, or none (removed).
class DiscountChoice {
  const DiscountChoice(this.discount);
  final Discount? discount;
}

/// Pick a saved discount or type one (percent or amount), with a reason.
/// [base] is what it comes off (pesewas), for the preview. Null when
/// cancelled.
Future<DiscountChoice?> showDiscountDialog({
  required String title,
  required int base,
  required List<SavedDiscount> saved,
  required List<Reason> reasons,
  Discount? current,
}) =>
    Get.dialog<DiscountChoice>(
      _DiscountDialog(title: title, base: base, saved: saved, reasons: reasons, current: current),
    );

class _DiscountDialog extends StatefulWidget {
  const _DiscountDialog({
    required this.title,
    required this.base,
    required this.saved,
    required this.reasons,
    this.current,
  });

  final String title;
  final int base;
  final List<SavedDiscount> saved;
  final List<Reason> reasons;
  final Discount? current;

  @override
  State<_DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<_DiscountDialog> {
  late DiscountKind _kind = widget.current?.kind ?? DiscountKind.percent;
  late final _value = TextEditingController(text: _initialValue());
  late String? _savedId = widget.current?.savedId;
  late String? _reason = widget.current?.reason;
  String? _error;

  String _initialValue() {
    final d = widget.current;
    if (d == null) return '';
    return d.kind == DiscountKind.percent ? '${d.value}' : (d.value / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  SavedDiscount? get _saved => widget.saved.firstWhereOrNull((s) => s.id == _savedId);

  int? get _parsed {
    final text = _value.text.trim();
    if (_kind == DiscountKind.percent) {
      final n = int.tryParse(text);
      return n == null || n < 1 || n > 100 ? null : n;
    }
    final p = parseMoney(text);
    return p == null || p <= 0 ? null : p;
  }

  Discount? get _discount {
    final saved = _saved;
    final reason = _reason;
    if (reason == null) return null;
    if (saved != null) return saved.apply(reason: reason);
    final value = _parsed;
    return value == null ? null : Discount(kind: _kind, value: value, reason: reason);
  }

  void _pickSaved(SavedDiscount s) => setState(() {
        _savedId = _savedId == s.id ? null : s.id;
        if (_savedId != null) {
          _kind = s.kind;
          _value.text = s.kind == DiscountKind.percent ? '${s.value}' : (s.value / 100).toStringAsFixed(2);
        }
        _error = null;
      });

  void _apply() {
    final l = context.l10n;
    if (_reason == null) return setState(() => _error = l.discountPickReason);
    final d = _discount;
    if (d == null) return setState(() => _error = _kind == DiscountKind.percent ? l.discountPercentInvalid : l.discountAmountInvalid);
    goBack(result: DiscountChoice(d));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final preview = _discount?.amountOn(widget.base) ??
        (_parsed == null ? null : Discount(kind: _kind, value: _parsed!, reason: '').amountOn(widget.base));
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (widget.saved.isNotEmpty) ...[
              Text(l.discountSaved.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                for (final s in widget.saved)
                  OptionChip(label: s.name, trailing: s.label, selected: _savedId == s.id, onTap: () => _pickSaved(s)),
              ]),
              const SizedBox(height: AbySpace.s4),
            ],
            Row(children: [
              SegmentedButton<DiscountKind>(
                segments: [
                  const ButtonSegment(value: DiscountKind.percent, label: Text('%')),
                  const ButtonSegment(value: DiscountKind.amount, label: Text('GH₵')),
                ],
                selected: {_kind},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() {
                  _kind = v.single;
                  _savedId = null;
                  _error = null;
                }),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: TextField(
                  controller: _value,
                  autofocus: widget.saved.isEmpty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {
                    _savedId = null;
                    _error = null;
                  }),
                  decoration: InputDecoration(
                    labelText: _kind == DiscountKind.percent ? l.discountPercent : l.discountAmount,
                    suffixText: _kind == DiscountKind.percent ? '%' : null,
                    prefixText: _kind == DiscountKind.amount ? 'GH₵ ' : null,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: AbySpace.s4),
            Text(l.discountReason.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final r in widget.reasons)
                OptionChip(
                  label: r.name,
                  selected: _reason == r.name,
                  onTap: () => setState(() {
                    _reason = r.name;
                    _error = null;
                  }),
                ),
            ]),
            const SizedBox(height: AbySpace.s4),
            Row(children: [
              Text(l.discountOff, style: AbyText.body.copyWith(color: c.inkMuted)),
              const Spacer(),
              Text(preview == null ? '—' : '−${formatMoney(preview)}', style: AbyText.heading.copyWith(color: c.ink)),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        if (widget.current != null)
          TextButton(onPressed: () => goBack(result: const DiscountChoice(null)), child: Text(l.discountRemove)),
        OutlinedButton(onPressed: () => goBack<DiscountChoice>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _apply, child: Text(l.discountApply)),
      ],
    );
  }
}
