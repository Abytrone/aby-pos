import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/catalogue_io.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/catalogue_controller.dart';

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
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: changes.isEmpty
              ? null
              : () async {
                  final description = '${_raise ? '+' : '−'}${_value.text.trim()}${_percent ? '%' : ' GH₵'}'
                      '${_step == 0 ? '' : ', rounded to ${formatMoney(_step)}'}';
                  if (await widget.controller.applyBulk(changes, description)) Get.back<void>();
                },
          child: Text(l.bulkApply(changes.length)),
        ),
      ],
    );
  }
}

/// Pick a CSV, show what it would do, and import on confirm.
Future<void> runImport(CatalogueController controller) async {
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
            const SizedBox(height: AbySpace.s3),
            Text(l.importHelp(CatalogueIo.productColumns.join(', ')), style: AbyText.caption.copyWith(color: c.inkMuted)),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: preview.canApply
              ? () async {
                  if (await controller.applyImport(preview)) Get.back<void>();
                }
              : null,
          child: Text(l.importApply),
        ),
      ],
    );
  }));
}
