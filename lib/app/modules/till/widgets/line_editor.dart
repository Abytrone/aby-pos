import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/cart_line.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/till_controller.dart';
import '../views/till_view.dart' show showPicker;
import 'discount_dialog.dart';
import '../../../ui/dialogs.dart';

/// Change one cart line: quantity (or weight), price, discount, note, the
/// size and options, or take it off.
Future<void> showLineEditor(TillController till, CartLine line) =>
    Get.dialog<void>(_LineEditor(till: till, lineKey: line.key));

class _LineEditor extends StatefulWidget {
  const _LineEditor({required this.till, required this.lineKey});

  final TillController till;
  final String lineKey;

  @override
  State<_LineEditor> createState() => _LineEditorState();
}

class _LineEditorState extends State<_LineEditor> {
  TillController get till => widget.till;
  CartLine? get line => till.cart.line(widget.lineKey);

  late final CartLine _start = line!;
  late final _quantity = TextEditingController(
    text: _start.weighed ? quantityIn(_start.quantity, _unit) : '${_start.quantity}',
  );
  late final _price = TextEditingController(text: (_start.unitPrice / 100).toStringAsFixed(2));
  late final _note = TextEditingController(text: _start.note ?? '');
  String? _error;

  DisplayUnit get _unit => _start.product.sellBy == SellBy.litre ? DisplayUnit.l : DisplayUnit.kg;

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _note.dispose();
    super.dispose();
  }

  void _step(int by) {
    final n = (int.tryParse(_quantity.text.trim()) ?? _start.quantity) + by;
    _quantity.text = '${n < 1 ? 1 : n}';
    setState(() {});
  }

  Future<void> _discount() async {
    final current = line;
    if (current == null) return;
    final choice = await showDiscountDialog(
      title: context.l10n.lineDiscountTitle(current.title),
      base: current.lineTotal,
      saved: till.savedDiscounts.where((d) => d.forLines).toList(),
      reasons: till.discountReasons.toList(),
      current: current.discount,
    );
    if (choice == null) return;
    await till.setLineDiscount(widget.lineKey, choice.discount);
    if (mounted) setState(() {});
  }

  void _changePick() {
    final current = line;
    if (current == null) return;
    goBack<void>();
    till.openPicker(current.product, editing: current);
    showPicker(context, till);
  }

  Future<void> _done() async {
    final l = context.l10n;
    final current = line;
    if (current == null) return goBack<void>();
    final quantity = current.weighed ? parseQuantity(_quantity.text, _unit) : int.tryParse(_quantity.text.trim());
    if (quantity == null || quantity < 1) {
      return setState(() => _error = current.weighed ? l.tillWeightInvalid : l.lineQuantityInvalid);
    }
    final price = parseMoney(_price.text);
    if (price == null) return setState(() => _error = l.tillPriceInvalid);
    if (price != current.unitPrice) {
      final error = await till.setLinePrice(widget.lineKey, price);
      if (error != null) return setState(() => _error = error);
    }
    till.cart.setQuantity(widget.lineKey, quantity);
    till.cart.setLineNote(widget.lineKey, _note.text);
    goBack<void>();
  }

  Future<void> _remove() async {
    till.cart.remove(widget.lineKey);
    goBack<void>();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final current = line;
    if (current == null) return const SizedBox.shrink();
    final per = current.product.perUnit;
    return AlertDialog(
      title: Text(current.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (current.options.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AbySpace.s3),
                  child: Text('+ ${current.optionsLine}', style: AbyText.caption.copyWith(color: c.inkMuted)),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!current.weighed) ...[
                    IconButton.outlined(
                      tooltip: l.cartOneLess,
                      onPressed: () => _step(-1),
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: AbySpace.s2),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _quantity,
                      keyboardType: TextInputType.numberWithOptions(decimal: current.weighed),
                      inputFormatters: current.weighed ? null : [FilteringTextInputFormatter.digitsOnly],
                      textAlign: current.weighed ? TextAlign.start : TextAlign.center,
                      decoration: InputDecoration(
                        labelText: current.weighed
                            ? (current.product.sellBy == SellBy.litre ? l.entryVolume : l.entryWeight)
                            : l.lineQuantity,
                        suffixText: current.weighed ? _unit.symbol : null,
                      ),
                    ),
                  ),
                  if (!current.weighed) ...[
                    const SizedBox(width: AbySpace.s2),
                    IconButton.outlined(tooltip: l.cartOneMore, onPressed: () => _step(1), icon: const Icon(Icons.add)),
                  ],
                ],
              ),
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: per == null ? l.linePrice : l.entryPricePerLabel(per),
                  prefixText: 'GH₵ ',
                  helperText: current.product.openPrice
                      ? null
                      : current.priceOverridden
                      ? l.lineMenuPrice(formatMoney(current.listPrice))
                      : l.linePriceHelp,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.lineNote, helperText: l.lineNoteHelp),
              ),
              const SizedBox(height: AbySpace.s2),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_offer_outlined),
                title: Text(current.discount == null ? l.lineAddDiscount : l.lineDiscount),
                subtitle: current.discount == null
                    ? null
                    : Text(
                        '${current.discount!.name ?? current.discount!.label}  ·  −${formatMoney(current.discountAmount)}'
                        '  ·  ${current.discount!.reason}',
                      ),
                onTap: _discount,
              ),
              if (current.product.hasChoices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune),
                  title: Text(l.lineChangePick),
                  onTap: _changePick,
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AbySpace.s2),
                  child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [
              TextButton(
            onPressed: _remove,
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l.lineRemove),
          ),
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _done, child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}
