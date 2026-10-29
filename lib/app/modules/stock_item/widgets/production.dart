import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/stock.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/stock_item_controller.dart';

/// "Made here" (INV-09): the batch recipe and a button to record a run.
class ProductionCard extends GetView<StockItemController> {
  const ProductionCard({super.key, required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final recipe = controller.production.value;
    if (recipe == null) {
      if (!controller.canEdit) return const SizedBox.shrink();
      return OutlinedButton.icon(
        onPressed: () => _editRecipe(context),
        icon: const Icon(Icons.blender_outlined),
        label: Text(l.produceSetUp),
      );
    }
    return GroupCard(title: l.produceMadeHere, children: [
      InfoTile(
        title: l.produceBatchMakes(formatQuantity(recipe.batchYield, item.unit)),
        leading: const Icon(Icons.blender_outlined),
        onTap: controller.canEdit ? () => _editRecipe(context) : null,
      ),
      for (final (id, qty) in recipe.lines)
        InfoTile(title: controller.nameOf(id), value: formatQuantity(qty, controller.unitOf(id))),
      if (controller.canEdit)
        Padding(
          padding: const EdgeInsets.all(AbySpace.s3),
          child: FilledButton.icon(
            onPressed: () => _produce(context),
            icon: const Icon(Icons.add_task),
            label: Text(l.produceRecord),
          ),
        ),
    ]);
  }

  Future<void> _flush() async {
    final m = controller.message.value;
    if (m == null) return;
    controller.message.value = null;
    showMessage(m);
  }

  Future<void> _editRecipe(BuildContext context) async {
    await Get.dialog<void>(_RecipeDialog(item: item));
    await _flush();
  }

  Future<void> _produce(BuildContext context) async {
    await Get.dialog<void>(_ProduceDialog(item: item));
    await _flush();
  }
}

class _Ingredient {
  _Ingredient(this.itemId, String amount) : amount = TextEditingController(text: amount);

  String? itemId;
  final TextEditingController amount;
}

class _RecipeDialog extends StatefulWidget {
  const _RecipeDialog({required this.item});

  final StockItem item;

  @override
  State<_RecipeDialog> createState() => _RecipeDialogState();
}

class _RecipeDialogState extends State<_RecipeDialog> {
  StockItemController get _ctl => Get.find();
  late final DisplayUnit _bulk = DisplayUnit.bulk(widget.item.unit);
  late final _yield = TextEditingController(
    text: _ctl.production.value == null ? '' : quantityIn(_ctl.production.value!.batchYield, _bulk),
  );
  late final List<_Ingredient> _lines = [
    for (final (id, qty) in _ctl.production.value?.lines ?? const <(String, int)>[])
      _Ingredient(id, quantityIn(qty, DisplayUnit.bulk(_ctl.unitOf(id)))),
    if (_ctl.production.value == null) _Ingredient(null, ''),
  ];
  String? _error;

  @override
  void dispose() {
    _yield.dispose();
    for (final i in _lines) {
      i.amount.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool stop = false}) async {
    final l = context.l10n;
    if (stop) {
      if (await _ctl.saveProduction(null, const [])) Get.back<void>();
      return;
    }
    final batch = parseQuantity(_yield.text, _bulk);
    if (batch == null || batch <= 0) return setState(() => _error = l.produceYieldInvalid);
    final lines = <(String, int)>[];
    for (final i in _lines.where((x) => x.itemId != null)) {
      final q = parseQuantity(i.amount.text, DisplayUnit.bulk(_ctl.unitOf(i.itemId!)));
      if (q == null || q <= 0) return setState(() => _error = l.receiveLineInvalid(_ctl.nameOf(i.itemId!)));
      lines.add((i.itemId!, q));
    }
    if (lines.isEmpty) return setState(() => _error = l.produceNeedsIngredients);
    if (await _ctl.saveProduction(batch, lines)) {
      Get.back<void>();
    } else {
      setState(() => _error = _ctl.message.value);
      _ctl.message.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final others = [for (final i in _ctl.allItems) if (i.id != widget.item.id) i];
    return AlertDialog(
      title: Text(l.produceRecipeTitle(widget.item.name)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.produceRecipeHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s3),
            TextField(
              controller: _yield,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.produceOneBatchMakes, suffixText: _bulk.symbol),
            ),
            const SizedBox(height: AbySpace.s3),
            Text(l.produceIngredients.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            for (final i in _lines)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s2),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: i.itemId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.recipeItem, isDense: true),
                      items: [for (final o in others) DropdownMenuItem(value: o.id, child: Text(o.name, overflow: TextOverflow.ellipsis))],
                      onChanged: (v) => setState(() => i.itemId = v),
                    ),
                  ),
                  const SizedBox(width: AbySpace.s2),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: i.amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.stockHowMuch,
                        suffixText: i.itemId == null ? null : DisplayUnit.bulk(_ctl.unitOf(i.itemId!)).symbol,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.recipeRemove,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lines.remove(i)),
                  ),
                ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _lines.add(_Ingredient(null, ''))),
                icon: const Icon(Icons.add),
                label: Text(l.recipeAdd),
              ),
            ),
            if (_error != null) Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
          ]),
        ),
      ),
      actions: [
        if (_ctl.production.value != null)
          TextButton(onPressed: () => _save(stop: true), child: Text(l.produceStop, style: TextStyle(color: c.danger))),
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}

class _ProduceDialog extends StatefulWidget {
  const _ProduceDialog({required this.item});

  final StockItem item;

  @override
  State<_ProduceDialog> createState() => _ProduceDialogState();
}

class _ProduceDialogState extends State<_ProduceDialog> {
  StockItemController get _ctl => Get.find();
  late final DisplayUnit _bulk = DisplayUnit.bulk(widget.item.unit);
  late final _amount = TextEditingController(text: quantityIn(_ctl.production.value!.batchYield, _bulk));
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final recipe = _ctl.production.value!;
    final made = parseQuantity(_amount.text, _bulk) ?? 0;
    return AlertDialog(
      title: Text(l.produceRecordTitle(widget.item.name)),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: l.produceHowMuch, suffixText: _bulk.symbol),
          ),
          const SizedBox(height: AbySpace.s3),
          Text(l.produceUses.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          for (final (id, qty) in recipe.lines)
            InfoTile(
              title: _ctl.nameOf(id),
              value: formatQuantity((qty * made + recipe.batchYield ~/ 2) ~/ recipe.batchYield, _ctl.unitOf(id)),
            ),
          TextField(controller: _note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: made <= 0
              ? null
              : () async {
                  if (await _ctl.produce(_amount.text, _bulk, note: _note.text)) Get.back<void>();
                },
          child: Text(l.produceRecord),
        ),
      ],
    );
  }
}

/// Batches of an item that tracks expiry, with what is left of each.
class BatchesCard extends GetView<StockItemController> {
  const BatchesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final now = DateTime.now();
    final list = controller.batches.where((b) => b.left > 0).toList();
    return GroupCard(
      title: l.expiryBatches,
      children: list.isEmpty
          ? [InfoTile(title: l.expiryNoBatches)]
          : [
              for (final b in list)
                InfoTile(
                  title: b.expiresOn == null ? l.expiryNoDate : l.expiryOn(formatDate(b.expiresOn!)),
                  subtitle: [?b.batchNo, l.expiryReceived(formatDate(b.receivedAt))].join('  ·  '),
                  value: formatQuantity(b.left, b.unit),
                  leading: Icon(
                    Icons.event_busy,
                    color: (b.daysLeft(now) ?? 99) < 0 ? c.danger : ((b.daysLeft(now) ?? 99) <= 7 ? c.warning : c.inkMuted),
                  ),
                ),
            ],
    );
  }
}
