import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../core/denominations.dart';
import '../services/money.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'l10n.dart';

/// Count the drawer note by note and coin by coin; the total adds up as
/// you type. Null when cancelled.
Future<CashCount?> showCashCount({CashCount initial = const CashCount(), String? title}) =>
    Get.dialog<CashCount>(_CashCountDialog(initial: initial, title: title));

class _CashCountDialog extends StatefulWidget {
  const _CashCountDialog({required this.initial, this.title});

  final CashCount initial;
  final String? title;

  @override
  State<_CashCountDialog> createState() => _CashCountDialogState();
}

class _CashCountDialogState extends State<_CashCountDialog> {
  late CashCount _count = widget.initial;
  late final _fields = {
    for (final d in ghanaDenominations)
      d: TextEditingController(text: (widget.initial.pieces[d] ?? 0) == 0 ? '' : '${widget.initial.pieces[d]}'),
  };

  @override
  void dispose() {
    for (final f in _fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _set(int d, int n) {
    final v = n < 0 ? 0 : n;
    _fields[d]!.text = v == 0 ? '' : '$v';
    setState(() => _count = _count.withCount(d, v));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title ?? l.countCashTitle),
      content: SizedBox(
        width: 420,
        height: 520,
        child: Column(children: [
          Expanded(
            child: ListView(children: [
              for (final d in ghanaDenominations)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
                  child: Row(children: [
                    SizedBox(width: 80, child: Text(denominationLabel(d), style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700))),
                    IconButton(
                      tooltip: l.cartOneLess,
                      onPressed: () => _set(d, (_count.pieces[d] ?? 0) - 1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _fields[d],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(isDense: true, hintText: '0'),
                        onChanged: (v) => setState(() => _count = _count.withCount(d, int.tryParse(v) ?? 0)),
                      ),
                    ),
                    IconButton(
                      tooltip: l.cartOneMore,
                      onPressed: () => _set(d, (_count.pieces[d] ?? 0) + 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    Expanded(
                      child: Text(
                        formatMoney(d * (_count.pieces[d] ?? 0)),
                        textAlign: TextAlign.end,
                        style: AbyText.caption.copyWith(color: c.inkMuted),
                      ),
                    ),
                  ]),
                ),
            ]),
          ),
          const Divider(),
          Row(children: [
            Text(l.cartTotal, style: AbyText.body.copyWith(color: c.inkMuted)),
            const Spacer(),
            Text(formatMoney(_count.total), style: AbyText.title.copyWith(color: c.ink)),
          ]),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<CashCount>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Get.back(result: _count), child: Text(l.countCashUse)),
      ],
    );
  }
}
