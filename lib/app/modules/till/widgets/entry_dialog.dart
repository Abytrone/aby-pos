import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../services/scale/scale_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/till_controller.dart';
import '../../../ui/dialogs.dart';

/// The price for an open-price product and / or the weight for a weighed
/// one, before it goes in the cart.
Future<void> showEntryDialog(TillController controller) =>
    Get.dialog<void>(_EntryDialog(controller: controller)).whenComplete(controller.closePicker);

class _EntryDialog extends StatefulWidget {
  const _EntryDialog({required this.controller});

  final TillController controller;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final product = widget.controller.pickerProduct.value!;
  late final variant = widget.controller.pickerVariant.value!;
  late final _price = TextEditingController(
    text: product.openPrice && variant.price > 0 ? (variant.price / 100).toStringAsFixed(2) : '',
  );
  final _amount = TextEditingController();
  String? _error;

  /// This device's scale, for products sold by the kilo.
  late final ScaleService? _scale =
      product.sellBy == SellBy.kg && Get.isRegistered<ScaleService>() && Get.find<ScaleService>().hasScale
          ? Get.find<ScaleService>()
          : null;
  bool _weighing = false;

  @override
  void initState() {
    super.initState();
    if (_scale != null) _readScale();
  }

  Future<void> _readScale() async {
    setState(() {
      _weighing = true;
      _error = null;
    });
    try {
      final grams = await _scale!.readGrams();
      if (!mounted) return;
      _amount.text = (grams / 1000).toStringAsFixed(3);
    } on ScaleException catch (e) {
      if (mounted) _error = e.message;
    } finally {
      if (mounted) setState(() => _weighing = false);
    }
  }

  DisplayUnit get _unit => product.sellBy == SellBy.litre ? DisplayUnit.l : DisplayUnit.kg;

  @override
  void dispose() {
    _price.dispose();
    _amount.dispose();
    super.dispose();
  }

  int? get _priceValue => product.openPrice ? parseMoney(_price.text) : variant.price;
  int? get _amountValue => product.weighed ? parseQuantity(_amount.text, _unit) : null;

  /// What the line will cost, when it can be worked out.
  int? get _lineTotal {
    final price = _priceValue;
    if (price == null) return null;
    if (!product.weighed) return price;
    final amount = _amountValue;
    return amount == null ? null : (price * amount + 500) ~/ 1000;
  }

  void _confirm() {
    final error = widget.controller.confirmEntry(price: _priceValue, amount: _amountValue);
    if (error == null) {
      goBack<void>();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final total = _lineTotal;
    final limits = [
      if (product.minPrice != null) l.entryMin(formatMoney(product.minPrice!)),
      if (product.maxPrice != null) l.entryMax(formatMoney(product.maxPrice!)),
    ].join('  ·  ');
    return AlertDialog(
      title: Text(variant.name == null ? product.name : '${product.name}, ${variant.name}'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (product.weighed)
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                labelText: product.sellBy == SellBy.litre ? l.entryVolume : l.entryWeight,
                suffixText: _unit.symbol,
                suffixIcon: _scale == null
                    ? null
                    : IconButton(
                        tooltip: l.scaleRead,
                        onPressed: _weighing ? null : _readScale,
                        icon: _weighing
                            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.scale_outlined),
                      ),
                helperText: product.openPrice ? null : l.entryPricePer(formatMoney(variant.price), _unit.symbol),
              ),
            ),
          if (product.weighed && product.openPrice) const SizedBox(height: AbySpace.s3),
          if (product.openPrice)
            TextField(
              controller: _price,
              autofocus: !product.weighed,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                labelText: product.weighed ? l.entryPricePerLabel(_unit.symbol) : l.entryPrice,
                prefixText: 'GH₵ ',
                helperText: limits.isEmpty ? null : limits,
              ),
            ),
          const SizedBox(height: AbySpace.s4),
          Row(children: [
            Text(l.cartTotal, style: AbyText.body.copyWith(color: c.inkMuted)),
            const Spacer(),
            Text(total == null ? '—' : formatMoney(total), style: AbyText.heading.copyWith(color: c.ink)),
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
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _confirm, child: Text(l.entryAdd)),
        ]),
      ],
    );
  }
}
