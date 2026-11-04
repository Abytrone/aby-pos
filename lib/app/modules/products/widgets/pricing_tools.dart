import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/catalogue_io.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/catalogue_controller.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/import_dialogs.dart';

/// Raise or lower many prices at once (the products in view), rounded,
/// with a preview before anything changes.
Future<void> showBulkPrices(CatalogueController controller) => Get.dialog<void>(_BulkPrices(controller: controller));

class _BulkPrices extends StatefulWidget {
  const _BulkPrices({required this.controller});

  final CatalogueController controller;

  @override
  State<_BulkPrices> createState() => _BulkPricesState();
}

class _BulkPricesState extends State<_BulkPrices> {
  final _value = TextEditingController(text: '10');
  bool _percent = true;
  bool _raise = true;
  int _step = 50;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  List<(String, String, int, int)> get _changes {
    final text = _value.text.trim();
    if (_percent) {
      final pct = int.tryParse(text);
      if (pct == null) return const [];
      return widget.controller.bulkPreview(percent: _raise ? pct : -pct, step: _step);
    }
    final amount = parseMoney(text);
    if (amount == null) return const [];
    return widget.controller.bulkPreview(amount: _raise ? amount : -amount, step: _step);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final changes = _changes;
    String stepLabel(int s) => s == 0 ? l.bulkNoRounding : l.bulkRoundTo(formatMoney(s));
    return AlertDialog(
      title: Text(l.bulkTitle),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.bulkScope(widget.controller.visibleProducts.length),
              style: AbyText.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AbySpace.s3),
            Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, label: Text(l.bulkRaise)),
                    ButtonSegment(value: false, label: Text(l.bulkLower)),
                  ],
                  selected: {_raise},
                  onSelectionChanged: (s) => setState(() => _raise = s.first),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _value,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixText: _percent ? null : 'GH₵ ',
                      suffixText: _percent ? '%' : null,
                    ),
                  ),
                ),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('%')),
                    ButtonSegment(value: false, label: Text('GH₵')),
                  ],
                  selected: {_percent},
                  onSelectionChanged: (s) => setState(() => _percent = s.first),
                ),
              ],
            ),
            const SizedBox(height: AbySpace.s3),
            Wrap(
              spacing: AbySpace.s2,
              children: [
                for (final s in const [0, 10, 50, 100])
                  ChoiceChip(
                    label: Text(stepLabel(s)),
                    selected: _step == s,
                    onSelected: (_) => setState(() => _step = s),
                  ),
              ],
            ),
            const SizedBox(height: AbySpace.s3),
            Text(l.bulkPreview(changes.length).toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final (_, label, before, after) in changes)
                    ListTile(
                      dense: true,
                      title: Text(label),
                      trailing: Text(
                        '${formatMoney(before)}  →  ${formatMoney(after)}',
                        style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        DialogButtons(
          children: [
            OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
            FilledButton(
              onPressed: changes.isEmpty
                  ? null
                  : () async {
                      final description =
                          '${_raise ? '+' : '−'}${_value.text.trim()}${_percent ? '%' : ' GH₵'}'
                          '${_step == 0 ? '' : ', rounded to ${formatMoney(_step)}'}';
                      if (await widget.controller.applyBulk(changes, description)) goBack<void>();
                    },
              child: Text(l.bulkApply(changes.length)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Explain the file (with a sample to start from), pick a CSV, show what
/// it would do, and import on confirm.
Future<void> runImport(CatalogueController controller) async {
  final l = appL10n();
  final pick = await showImportStart(
    title: l.importTitle,
    intro: l.importIntro,
    steps: [l.importStep1, l.importStep2, l.importStep3],
    columns: {
      'category': l.importColCategory,
      'product': l.importColProduct,
      'variant': l.importColVariant,
      'price': l.importColPrice,
      'cost': l.importColCost,
      'barcodes': l.importColBarcodes,
      'tile_line': l.importColTileLine,
      'on_till': l.importColOnTill,
      'on_hand': l.importColOnHand,
      'low_below': l.importColLowBelow,
    },
    requiredColumns: CatalogueIo.requiredColumns,
    onSample: controller.downloadSample,
    startFromMineLabel: l.importStartFromMine,
    onStartFromMine: (controller.catalogue.value?.products.isNotEmpty ?? false) ? controller.exportProducts : null,
    footer: l.importNeverRemoves,
  );
  if (!pick) return;
  final preview = await controller.previewImport();
  if (preview == null) return;
  await showImportPreview(
    title: l.importTitle,
    summary: l.importSummary(preview.newProducts, preview.updatedProducts, preview.unchanged),
    notes: [
      if (preview.newCategories.isNotEmpty) l.importNewCategories(preview.newCategories.join(', ')),
      if (preview.newStockItems > 0 || preview.updatedStockItems > 0 || preview.recountedStockItems > 0)
        l.importStockSummary(preview.newStockItems, preview.updatedStockItems, preview.recountedStockItems),
    ],
    problems: preview.problems,
    canApply: preview.canApply,
    onApply: () => controller.applyImport(preview),
  );
}
