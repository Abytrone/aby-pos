import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/catalogue_io.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/catalogue_controller.dart';
import '../../../ui/dialogs.dart';

/// Raise or lower many prices at once (the products in view), rounded,
/// with a preview before anything changes.
Future<void> showBulkPrices(CatalogueController controller) =>
    Get.dialog<void>(_BulkPrices(controller: controller));

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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.bulkScope(widget.controller.visibleProducts.length), style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s3),
          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            SegmentedButton<bool>(
              segments: [ButtonSegment(value: true, label: Text(l.bulkRaise)), ButtonSegment(value: false, label: Text(l.bulkLower))],
              selected: {_raise},
              onSelectionChanged: (s) => setState(() => _raise = s.first),
            ),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _value,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(isDense: true, prefixText: _percent ? null : 'GH₵ ', suffixText: _percent ? '%' : null),
              ),
            ),
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: true, label: Text('%')), ButtonSegment(value: false, label: Text('GH₵'))],
              selected: {_percent},
              onSelectionChanged: (s) => setState(() => _percent = s.first),
            ),
          ]),
          const SizedBox(height: AbySpace.s3),
          Wrap(spacing: AbySpace.s2, children: [
            for (final s in const [0, 10, 50, 100])
              ChoiceChip(label: Text(stepLabel(s)), selected: _step == s, onSelected: (_) => setState(() => _step = s)),
          ]),
          const SizedBox(height: AbySpace.s3),
          Text(l.bulkPreview(changes.length).toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView(shrinkWrap: true, children: [
              for (final (_, label, before, after) in changes)
                ListTile(
                  dense: true,
                  title: Text(label),
                  trailing: Text('${formatMoney(before)}  →  ${formatMoney(after)}',
                      style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: changes.isEmpty
                ? null
                : () async {
                    final description = '${_raise ? '+' : '−'}${_value.text.trim()}${_percent ? '%' : ' GH₵'}'
                        '${_step == 0 ? '' : ', rounded to ${formatMoney(_step)}'}';
                    if (await widget.controller.applyBulk(changes, description)) goBack<void>();
                  },
            child: Text(l.bulkApply(changes.length)),
          ),
        ]),
      ],
    );
  }
}

/// Explain the file (with a sample to start from), pick a CSV, show what
/// it would do, and import on confirm.
Future<void> runImport(CatalogueController controller) async {
  final pick = await Get.dialog<bool>(_ImportStart(controller: controller));
  if (pick != true) return;
  final preview = await controller.previewImport();
  if (preview == null) return;
  await Get.dialog<void>(Builder(builder: (context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.importTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.importSummary(preview.newProducts, preview.updatedProducts, preview.unchanged),
                style: AbyText.body.copyWith(color: c.ink)),
            if (preview.newCategories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s2),
                child: Text(l.importNewCategories(preview.newCategories.join(', ')),
                    style: AbyText.caption.copyWith(color: c.inkMuted)),
              ),
            if (preview.problems.isNotEmpty) ...[
              const SizedBox(height: AbySpace.s3),
              Text(l.importProblems(preview.problems.length).toUpperCase(), style: AbyText.label.copyWith(color: c.danger)),
              for (final ImportProblem p in preview.problems.take(30))
                Text(l.importRow(p.row, p.message), style: AbyText.caption.copyWith(color: c.danger)),
            ],
                  if (preview.problems.isNotEmpty) ...[
                    const SizedBox(height: AbySpace.s3),
            Text(l.importFixHint, style: AbyText.caption.copyWith(color: c.inkMuted)),
          ],
                ],
              ),
            ),
          ),
          actions: [
            DialogButtons(children: [
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: preview.canApply
                ? () async {
                    if (await controller.applyImport(preview)) goBack<void>();
                  }
                : null,
            child: Text(l.importApply),
          ),
            ]),
          ],
        );
  }));
}

/// Before the file picker: what the file looks like, column by column, and
/// a filled-in sample for this kind of shop. True: pick the file now.
class _ImportStart extends StatelessWidget {
  const _ImportStart({required this.controller});

  final CatalogueController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final columns = <String, String>{
      'category': l.importColCategory,
      'product': l.importColProduct,
      'variant': l.importColVariant,
      'price': l.importColPrice,
      'cost': l.importColCost,
      'barcodes': l.importColBarcodes,
      'tile_line': l.importColTileLine,
      'on_till': l.importColOnTill,
    };
    final hasProducts = controller.catalogue.value?.products.isNotEmpty ?? false;
    Widget step(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: AbySpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
            child: Text(
              '$n',
              style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: AbySpace.s3),
          Expanded(
            child: Text(text, style: AbyText.body.copyWith(color: c.ink)),
          ),
        ],
      ),
    );
    return AlertDialog(
      title: Text(l.importTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.importIntro, style: AbyText.body.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s4),
              step(1, l.importStep1),
              step(2, l.importStep2),
              step(3, l.importStep3),
              const SizedBox(height: AbySpace.s2),
              OutlinedButton.icon(
                onPressed: controller.downloadSample,
                icon: AbyIcon(AbyIcons.download, size: 20, color: c.ink),
                label: Text(l.importDownloadSample),
              ),
              if (hasProducts)
                TextButton.icon(
                  onPressed: controller.exportProducts,
                  icon: AbyIcon(AbyIcons.fileText, size: 20, color: c.ink),
                  label: Text(l.importStartFromMine),
                ),
              const SizedBox(height: AbySpace.s4),
              Text(l.importColumns.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Container(
                decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.md)),
                padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s2),
                child: Column(
                  children: [
                    for (final MapEntry(key: name, value: help) in columns.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 96,
                              child: Text(
                                name,
                                style: AbyText.receipt.copyWith(
                                  color: c.ink,
                                  fontWeight: CatalogueIo.requiredColumns.contains(name) ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(help, style: AbyText.caption.copyWith(color: c.inkMuted)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AbySpace.s2),
              Text(l.importNeverRemoves, style: AbyText.caption.copyWith(color: c.inkMuted)),
            ],
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<bool>(), child: Text(l.commonCancel)),
              FilledButton.icon(
                onPressed: () => goBack<bool>(result: true),
                icon: AbyIcon(AbyIcons.upload, size: 20, color: c.onPrimary),
                label: Text(l.importPick),
              ),
        ]),
      ],
    );
  }
}
