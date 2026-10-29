import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../core/units.dart';
import '../../../models/drafts.dart';
import '../../../models/enums.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/dialogs.dart';

/// "Pieces", "Weight (g, kg)", "Volume (ml, L)".
String unitLabel(AppLocalizations l, StockUnit u) => switch (u) {
      StockUnit.piece => l.unitPieces,
      StockUnit.g => l.unitWeight,
      StockUnit.ml => l.unitVolume,
    };

/// Name, unit, cost (per piece, kg or L) and when to reorder.
/// [onSave] returns true when saved.
Future<void> showStockItemEditor({
  StockItem? item,
  required Future<bool> Function(StockItemDraft draft) onSave,
}) =>
    Get.dialog<void>(_Editor(item: item, onSave: onSave));

class _Editor extends StatefulWidget {
  const _Editor({this.item, required this.onSave});

  final StockItem? item;
  final Future<bool> Function(StockItemDraft draft) onSave;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late StockUnit _unit = widget.item?.unit ?? StockUnit.piece;
  late final _cost = TextEditingController(
    text: widget.item == null ? '' : _plain(widget.item!.bulkPrice),
  );
  late final _reorderAt = TextEditingController(
    text: widget.item?.reorderPoint == null ? '' : quantityIn(widget.item!.reorderPoint!, DisplayUnit.bulk(_unit)),
  );
  late final _reorderQty = TextEditingController(
    text: widget.item?.reorderQty == null ? '' : quantityIn(widget.item!.reorderQty!, DisplayUnit.bulk(_unit)),
  );
  late bool _expiry = widget.item?.tracksExpiry ??
      (Get.isRegistered<SettingsService>() && Get.find<SettingsService>().get(AppSettings.expiryByDefault));
  String? _error;
  bool _saving = false;

  static String _plain(int pesewas) => '${pesewas ~/ 100}.${(pesewas % 100).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _reorderAt.dispose();
    _reorderQty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final bulk = DisplayUnit.bulk(_unit);
    final price = _cost.text.trim().isEmpty ? 0 : parseMoney(_cost.text);
    int? qty(TextEditingController c) => c.text.trim().isEmpty ? null : parseQuantity(c.text, bulk);
    if (price == null) return setState(() => _error = l.stockCostInvalid);
    final at = qty(_reorderAt);
    final reorder = qty(_reorderQty);
    if ((_reorderAt.text.trim().isNotEmpty && at == null) || (_reorderQty.text.trim().isNotEmpty && reorder == null)) {
      return setState(() => _error = l.stockQuantityInvalid);
    }
    setState(() => _saving = true);
    final ok = await widget.onSave(StockItemDraft(
      id: widget.item?.id,
      name: _name.text,
      unit: _unit,
      costMilli: costMilliFromPrice(price, bulk),
      reorderPoint: at,
      reorderQty: reorder,
      supplierId: widget.item?.supplierId,
      tracksExpiry: _expiry,
    ));
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) goBack<void>();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final bulk = DisplayUnit.bulk(_unit);
    return AlertDialog(
      title: Text(widget.item == null ? l.stockNew : l.stockEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _name,
              autofocus: widget.item == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.stockName, helperText: l.stockNameHelp),
            ),
            const SizedBox(height: AbySpace.s4),
            Text(l.stockUnit.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, children: [
              for (final u in StockUnit.values)
                ChoiceChip(
                  label: Text(unitLabel(l, u)),
                  selected: _unit == u,
                  onSelected: (_) => setState(() => _unit = u),
                ),
            ]),
            const SizedBox(height: AbySpace.s4),
            TextField(
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l.stockCostPer(bulk.symbol),
                prefixText: 'GH₵ ',
                helperText: l.stockCostHelp,
              ),
            ),
            const SizedBox(height: AbySpace.s3),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _reorderAt,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.stockReorderAt, suffixText: bulk.symbol),
                ),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: TextField(
                  controller: _reorderQty,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.stockReorderQty, suffixText: bulk.symbol),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s1),
              child: Text(l.stockReorderHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.stockTracksExpiry),
              subtitle: Text(l.stockTracksExpiryHelp),
              value: _expiry,
              onChanged: (v) => setState(() => _expiry = v),
            ),
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
        FilledButton(onPressed: _saving ? null : _save, child: Text(l.commonSave)),
      ],
    );
  }
}
