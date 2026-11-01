import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/units.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../models/drafts.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';

/// A stock item made in bulk, with what goes on the order or delivery.
class NewStockLine {
  const NewStockLine({required this.item, required this.quantity, required this.lineTotal});

  final StockItem item;

  /// Base units (pieces, grams, ml).
  final int quantity;

  /// Pesewas: quantity at the cost typed.
  final int lineTotal;
}

/// Several new stock items typed at once, one row each: name, unit,
/// quantity and cost per unit. Saved to the stock list with one approval,
/// then returned so the order or delivery takes them as lines. Null when
/// cancelled or refused.
Future<List<NewStockLine>?> showNewStockItems({
  required bool forDelivery,
  String? supplierId,
  required Set<String> takenNames,
}) =>
    Get.dialog<List<NewStockLine>>(
      _NewItems(forDelivery: forDelivery, supplierId: supplierId, takenNames: takenNames),
    );

/// The units a new item is counted in, as the shop thinks of them.
const _units = [DisplayUnit.piece, DisplayUnit.kg, DisplayUnit.l];

class _Row {
  final name = TextEditingController();
  final quantity = TextEditingController();
  final cost = TextEditingController();
  DisplayUnit unit = DisplayUnit.piece;

  bool get blank => name.text.trim().isEmpty && quantity.text.trim().isEmpty && cost.text.trim().isEmpty;

  void dispose() {
    name.dispose();
    quantity.dispose();
    cost.dispose();
  }
}

class _NewItems extends StatefulWidget {
  const _NewItems({required this.forDelivery, this.supplierId, required this.takenNames});

  final bool forDelivery;
  final String? supplierId;
  final Set<String> takenNames;

  @override
  State<_NewItems> createState() => _NewItemsState();
}

class _NewItemsState extends State<_NewItems> {
  final _rows = [_Row(), _Row(), _Row()];
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final taken = {for (final n in widget.takenNames) n.toLowerCase()};
    final seen = <String>{};
    final plans = <(StockItemDraft, int, int)>[];
    for (final r in _rows.where((r) => !r.blank)) {
      final name = r.name.text.trim();
      final qty = parseQuantity(r.quantity.text, r.unit);
      final costText = r.cost.text.trim();
      final cost = costText.isEmpty ? 0 : parseMoney(costText);
      if (name.isEmpty || qty == null || qty <= 0 || cost == null || cost < 0) {
        return setState(() => _error = l.newItemsRowInvalid(name.isEmpty ? '?' : name));
      }
      if (taken.contains(name.toLowerCase())) return setState(() => _error = l.newItemsTaken(name));
      if (!seen.add(name.toLowerCase())) return setState(() => _error = l.newItemsTwice(name));
      if (widget.forDelivery && costText.isEmpty) return setState(() => _error = l.newItemsNeedCost(name));
      final costMilli = costMilliFromPrice(cost, r.unit);
      plans.add((
        StockItemDraft(name: name, unit: r.unit.base, costMilli: costMilli, supplierId: widget.supplierId),
        qty,
        costOf(qty, costMilli),
      ));
    }
    if (plans.isEmpty) return setState(() => _error = l.newItemsNone);
    final auth = await Get.find<PermissionService>().authorize(Permission.editProducts, reason: l.stockEditReason);
    if (auth == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final stock = Get.find<StockRepository>();
    try {
      final made = <NewStockLine>[];
      for (final (draft, qty, total) in plans) {
        final id = await stock.saveItem(draft, by: auth.authority);
        made.add(NewStockLine(item: (await stock.item(id))!, quantity: qty, lineTotal: total));
      }
      goBack(result: made);
    } on StockException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final narrow = context.isNarrow;
    final count = _rows.where((r) => !r.blank).length;
    Widget row(_Row r) {
      final name = TextField(
        controller: r.name,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: l.newItemsName, isDense: true),
      );
      final unit = DropdownButtonFormField<DisplayUnit>(
        initialValue: r.unit,
        isExpanded: true,
        decoration: InputDecoration(labelText: l.newItemsUnit, isDense: true),
        items: [for (final u in _units) DropdownMenuItem(value: u, child: Text(u.symbol))],
        onChanged: (u) => setState(() => r.unit = u ?? r.unit),
      );
      final qty = TextField(
        controller: r.quantity,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: l.stockQuantity, suffixText: r.unit.symbol, isDense: true),
      );
      final cost = TextField(
        controller: r.cost,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: l.newItemsCostPer(r.unit.symbol),
          prefixText: 'GH₵ ',
          isDense: true,
        ),
      );
      final remove = IconButton(
        tooltip: l.recipeRemove,
        icon: const Icon(Icons.close),
        onPressed: _rows.length == 1
            ? null
            : () => setState(() {
                  _rows.remove(r);
                  r.dispose();
                }),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: AbySpace.s3),
        child: narrow
            ? Column(children: [
                Row(children: [Expanded(child: name), remove]),
                const SizedBox(height: AbySpace.s2),
                Row(children: [
                  SizedBox(width: 104, child: unit),
                  const SizedBox(width: AbySpace.s2),
                  Expanded(child: qty),
                  const SizedBox(width: AbySpace.s2),
                  Expanded(child: cost),
                ]),
              ])
            : Row(children: [
                Expanded(flex: 4, child: name),
                const SizedBox(width: AbySpace.s2),
                SizedBox(width: 104, child: unit),
                const SizedBox(width: AbySpace.s2),
                Expanded(flex: 2, child: qty),
                const SizedBox(width: AbySpace.s2),
                Expanded(flex: 2, child: cost),
                remove,
              ]),
      );
    }

    return AlertDialog(
      title: Text(l.newItemsTitle),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              widget.forDelivery ? l.newItemsIntroDelivery : l.newItemsIntroOrder,
              style: AbyText.body.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AbySpace.s4),
            for (final r in _rows) row(r),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _rows.add(_Row())),
                icon: const Icon(Icons.add),
                label: Text(l.newItemsAddRow),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s2),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
          OutlinedButton(onPressed: () => goBack<List<NewStockLine>>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: count == 0 || _saving ? null : _save,
            child: Text(l.newItemsSave(count)),
          ),
        ]),
      ],
    );
  }
}
