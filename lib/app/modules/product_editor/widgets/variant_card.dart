import 'package:flutter/material.dart';

import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../products/widgets/recipe_lines.dart';
import '../controllers/product_editor_controller.dart';

/// One price: name (for sizes), price, cost or recipe, margin, barcodes.
class VariantCard extends StatelessWidget {
  Future<void> _schedule(BuildContext context) async {
    final l = context.l10n;
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      helpText: l.editorScheduleWhen,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null) return;
    final price = await textInputDialog(
      title: l.editorSchedulePrice(formatDate(day)),
      label: l.editorPrice,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validate: (v) => parseMoney(v) == null ? l.editorPriceMissing : null,
    );
    if (price != null) await ctl.schedulePrice(form, price, day);
  }

  const VariantCard({
    super.key,
    required this.ctl,
    required this.form,
    required this.index,
    required this.single,
  });

  final ProductEditorController ctl;
  final VariantForm form;
  final int index;

  /// The only price: no name or reorder controls.
  final bool single;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final hasRecipe = form.recipe.any((r) => r.stockItemId != null);
    final cost = ctl.costOf(form);
    final margin = ctl.marginOf(form);
    return Card(
      margin: const EdgeInsets.only(bottom: AbySpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (!single) ...[
              Expanded(
                flex: 3,
                child: TextField(
                  controller: form.name,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => ctl.changed(),
                  decoration: InputDecoration(labelText: l.editorVariantName, helperText: l.editorVariantNameHelp),
                ),
              ),
              const SizedBox(width: AbySpace.s3),
            ],
            Expanded(
              flex: 2,
              child: TextField(
                controller: form.price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => ctl.changed(),
                decoration: InputDecoration(labelText: l.editorPrice, prefixText: 'GH₵ '),
              ),
            ),
            if (ctl.canSeeCost) ...[
              const SizedBox(width: AbySpace.s3),
              Expanded(
                flex: 2,
                child: hasRecipe
                    ? InputDecorator(
                        decoration: InputDecoration(labelText: l.editorCost, helperText: l.editorCostFromRecipe),
                        child: Text(formatMoney(cost ?? 0)),
                      )
                    : TextField(
                        controller: form.cost,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => ctl.changed(),
                        decoration: InputDecoration(labelText: l.editorCost, prefixText: 'GH₵ ', helperText: l.editorCostHelp),
                      ),
              ),
            ],
            if (!single)
              PopupMenuButton<int>(
                tooltip: l.commonMore,
                onSelected: (a) => switch (a) {
                  0 => ctl.moveVariant(form, -1),
                  1 => ctl.moveVariant(form, 1),
                  _ => ctl.removeVariant(form),
                },
                itemBuilder: (_) => [
                  if (index > 0) PopupMenuItem(value: 0, child: Text(l.editorMoveUp)),
                  if (index < ctl.variants.length - 1) PopupMenuItem(value: 1, child: Text(l.editorMoveDown)),
                  PopupMenuItem(value: 2, child: Text(l.editorRemoveVariant)),
                ],
              ),
          ]),
          if (ctl.canSeeCost && margin != null)
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s2),
              child: Text(
                l.editorMarginLine(margin, formatMoney((parseMoney(form.price.text) ?? 0) - (cost ?? 0))),
                style: AbyText.caption.copyWith(
                  color: margin < 0 ? c.danger : c.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          for (final s in ctl.scheduledFor(form))
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s2),
              child: Row(children: [
                Icon(Icons.schedule, size: 18, color: c.blue),
                const SizedBox(width: AbySpace.s2),
                Expanded(
                  child: Text(l.editorScheduled(formatMoney(s.newPrice), formatDate(s.effectiveOn)),
                      style: AbyText.caption.copyWith(color: c.blue, fontWeight: FontWeight.w700)),
                ),
                TextButton(onPressed: () => ctl.cancelScheduled(s), child: Text(l.commonCancel)),
              ]),
            ),
          if (form.id != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _schedule(context),
                icon: const Icon(Icons.schedule),
                label: Text(l.editorSchedule),
              ),
            ),
          const SizedBox(height: AbySpace.s3),
          Text(l.recipeUses.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          Text(l.recipeHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          RecipeLinesEditor(lines: form.recipe, stockItems: ctl.stockItems, onChanged: ctl.changed),
          const SizedBox(height: AbySpace.s2),
          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text(l.editorBarcodes, style: AbyText.label.copyWith(color: c.inkMuted)),
            for (final code in form.barcodes)
              InputChip(
                label: Text(code, style: AbyText.receipt),
                onDeleted: () => ctl.removeBarcode(form, code),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l.editorAddBarcode),
              onPressed: () async {
                final code = await textInputDialog(
                  title: l.editorAddBarcode,
                  label: l.editorBarcode,
                  helper: l.editorBarcodeHelp,
                  confirmLabel: l.editorAddBarcode,
                );
                if (code != null) ctl.addBarcode(form, code);
              },
            ),
          ]),
        ]),
      ),
    );
  }
}
