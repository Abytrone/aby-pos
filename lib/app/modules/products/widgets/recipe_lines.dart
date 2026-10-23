import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/units.dart';
import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';

/// One editable recipe line: a stock item and how much of it.
class RecipeLineForm {
  RecipeLineForm({this.stockItemId, String quantity = ''}) : quantity = TextEditingController(text: quantity);

  factory RecipeLineForm.from(RecipeLine line) => RecipeLineForm(
        stockItemId: line.stockItemId,
        quantity: quantityIn(line.quantity, DisplayUnit.small(line.unit)),
      );

  String? stockItemId;
  final TextEditingController quantity;

  /// Base units, or null if not filled in properly.
  int? baseQuantity(List<StockItem> items) {
    final item = items.where((s) => s.id == stockItemId).firstOrNull;
    if (item == null) return null;
    return parseQuantity(quantity.text, DisplayUnit.small(item.unit));
  }

  RecipeDraftLine? draft(List<StockItem> items) {
    final q = baseQuantity(items);
    return stockItemId == null || q == null || q <= 0 ? null : RecipeDraftLine(stockItemId: stockItemId!, quantity: q);
  }

  /// Pesewas at today's cost.
  int cost(List<StockItem> items) {
    final item = items.where((s) => s.id == stockItemId).firstOrNull;
    final q = baseQuantity(items);
    return item == null || q == null ? 0 : costOf(q, item.costMilli);
  }

  void dispose() => quantity.dispose();
}

/// "What it uses": a list of recipe lines with add and remove.
class RecipeLinesEditor extends StatelessWidget {
  const RecipeLinesEditor({
    super.key,
    required this.lines,
    required this.stockItems,
    required this.onChanged,
  });

  final List<RecipeLineForm> lines;
  final List<StockItem> stockItems;

  /// Call setState in the parent.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final active = stockItems.where((s) => s.active).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(bottom: AbySpace.s2),
          child: Row(children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                initialValue: line.stockItemId,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.recipeItem, isDense: true),
                items: [
                  for (final s in active) DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) {
                  line.stockItemId = v;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: AbySpace.s2),
            Expanded(
              flex: 2,
              child: TextField(
                controller: line.quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                onChanged: (_) => onChanged(),
                decoration: InputDecoration(
                  labelText: l.recipeAmount,
                  isDense: true,
                  suffixText: () {
                    final item = stockItems.where((s) => s.id == line.stockItemId).firstOrNull;
                    return item == null ? null : DisplayUnit.small(item.unit).symbol;
                  }(),
                ),
              ),
            ),
            SizedBox(
              width: 76,
              child: Text(
                formatMoney(line.cost(stockItems)),
                textAlign: TextAlign.end,
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
            ),
            IconButton(
              tooltip: l.recipeRemove,
              icon: const Icon(Icons.close),
              onPressed: () {
                lines.remove(line);
                line.dispose();
                onChanged();
              },
            ),
          ]),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: active.isEmpty
              ? null
              : () {
                  lines.add(RecipeLineForm());
                  onChanged();
                },
          icon: const Icon(Icons.add),
          label: Text(active.isEmpty ? l.recipeNoStockItems : l.recipeAdd),
        ),
      ),
    ]);
  }
}
