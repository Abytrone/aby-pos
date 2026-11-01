import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/enums.dart';
import '../../../models/stock.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/stock_item_controller.dart';
import '../views/stock_item_view.dart' show wasteLabel;
import '../../../ui/dialogs.dart';

enum QuantityMode { adjust, waste }

/// Log waste (how much, why) or correct stock (more or less, and why).
Future<void> showQuantityDialog(BuildContext context, {required StockItem item, required QuantityMode mode}) =>
    Get.dialog<void>(_QuantityDialog(item: item, mode: mode));

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.item, required this.mode});

  final StockItem item;
  final QuantityMode mode;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DisplayUnit _unit = DisplayUnit.small(widget.item.unit);
  WasteReason _reason = WasteReason.melted;
  bool _add = false;
  String? _error;

  StockItemController get _ctl => Get.find();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = widget.mode == QuantityMode.waste
        ? await _ctl.logWaste(_amount.text, _unit, reason: _reason, note: _note.text)
        : await _ctl.adjust(_amount.text, _unit, add: _add, note: _note.text);
    if (ok) {
      goBack<void>();
    } else if (mounted) {
      setState(() => _error = _ctl.message.value);
      _ctl.message.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final waste = widget.mode == QuantityMode.waste;
    final units = DisplayUnit.forBase(widget.item.unit);
    return AlertDialog(
      title: Text(waste ? l.stockLogWasteOf(widget.item.name) : l.stockAdjustOf(widget.item.name)),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!waste)
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.stockLess)),
                ButtonSegment(value: true, label: Text(l.stockMore)),
              ],
              selected: {_add},
              onSelectionChanged: (s) => setState(() => _add = s.first),
            ),
          const SizedBox(height: AbySpace.s3),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.stockQuantity, errorText: _error),
              ),
            ),
            if (units.length > 1) ...[
              const SizedBox(width: AbySpace.s2),
              DropdownButton<DisplayUnit>(
                value: _unit,
                items: [for (final u in units) DropdownMenuItem(value: u, child: Text(u.symbol))],
                onChanged: (u) => setState(() => _unit = u ?? _unit),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(left: AbySpace.s2),
                child: Text(_unit.symbol, style: AbyText.body.copyWith(color: c.inkMuted)),
              ),
          ]),
          if (waste) ...[
            const SizedBox(height: AbySpace.s3),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final r in WasteReason.values)
                ChoiceChip(
                  label: Text(wasteLabel(l, r)),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
            ]),
          ],
          const SizedBox(height: AbySpace.s3),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: waste ? l.stockNoteOptional : l.stockWhy),
          ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}
