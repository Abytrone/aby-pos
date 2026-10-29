import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/purchasing.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../controllers/stock_count_controller.dart';

class StockCountView extends GetView<StockCountController> {
  const StockCountView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.countTitle),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        actions: [
          Obx(() => controller.isOpen
              ? Row(children: [
                  TextButton(
                    onPressed: () async {
                      final ok = await confirmDialog(
                        title: l.countCancelTitle,
                        message: l.countCancelBody,
                        confirmLabel: l.countCancel,
                        danger: true,
                      );
                      if (ok) {
                        await controller.cancel();
                        goBack<void>();
                      }
                    },
                    child: Text(l.countCancel),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AbySpace.s4, left: AbySpace.s2),
                    child: FilledButton(
                      onPressed: controller.countedCount == 0
                          ? null
                          : () async {
                              final ok = await confirmDialog(
                                title: l.countPostTitle,
                                message: l.countPostBody(controller.countedCount),
                                confirmLabel: l.countPost,
                              );
                              if (!ok) return;
                              final posted = await controller.post();
                              _flush();
                              if (posted) goBack<void>();
                            },
                      child: Text(l.countPost),
                    ),
                  ),
                ])
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        final count = controller.count.value;
        if (count == null) return const Center(child: CircularProgressIndicator());
        _flush();
        final rows = controller.visible;
        final showExpected = controller.showExpected;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(AbySpace.s4),
            child: Wrap(spacing: AbySpace.s3, runSpacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
              SizedBox(
                width: context.isNarrow ? double.infinity : 260,
                child: TextField(
                  onChanged: (v) => controller.query.value = v,
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.stockSearch, isDense: true),
                ),
              ),
              Text(
                l.countProgress(controller.countedCount, controller.lines.length),
                style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700),
              ),
              if (showExpected && controller.countedCount > 0)
                Text(
                  controller.differenceValue == 0
                      ? l.countNoDifference
                      : controller.differenceValue > 0
                          ? l.countFoundValue(formatMoney(controller.differenceValue))
                          : l.countShortValue(formatMoney(-controller.differenceValue)),
                  style: AbyText.body.copyWith(
                    color: controller.differenceValue < 0 ? c.danger : c.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Text(
                '${formatDateTime(count.startedAt)}  ·  ${count.startedByName}${count.blind ? '  ·  ${l.countBlindShort}' : ''}',
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s8),
              itemCount: rows.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _CountRow(line: rows[i], showExpected: showExpected, open: controller.isOpen),
            ),
          ),
        ]);
      }),
    );
  }

  void _flush() {
    final text = controller.message.value;
    if (text == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.message.value == null) return;
      controller.message.value = null;
      showMessage(text);
    });
  }
}

class _CountRow extends GetView<StockCountController> {
  const _CountRow({required this.line, required this.showExpected, required this.open});

  final StockCountLine line;
  final bool showExpected;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final unit = DisplayUnit.bulk(line.unit);
    final diff = line.difference;
    final difference = showExpected && diff != null && diff != 0
        ? Text(
            '${diff > 0 ? '+' : ''}${formatQuantity(diff, line.unit)}  (${formatMoney(costOf(diff, line.costMilli))})',
            style: AbyText.caption.copyWith(color: diff < 0 ? c.danger : c.success, fontWeight: FontWeight.w700),
          )
        : null;
    // Beside the count field there is no room for it on a phone.
    final narrow = context.isNarrow;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(line.name, style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            if (line.counted != null)
              Text(
                [
                  l.countCounted(formatQuantity(line.counted!, line.unit)),
                  if (showExpected && line.expected != null) l.countExpected(formatQuantity(line.expected!, line.unit)),
                  ?line.countedByName,
                ].join('  ·  '),
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
            if (difference != null && narrow) difference,
          ]),
        ),
        if (difference != null && !narrow)
          Padding(padding: const EdgeInsets.only(right: AbySpace.s3), child: difference),
        if (open) ...[
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller.fields[line.stockItemId],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => controller.saveLine(line),
              decoration: InputDecoration(isDense: true, suffixText: unit.symbol, hintText: l.countFound),
            ),
          ),
          IconButton(
            tooltip: l.commonSave,
            icon: Icon(line.counted == null ? Icons.check_circle_outline : Icons.check_circle, color: line.counted == null ? c.inkMuted : c.success),
            onPressed: () => controller.saveLine(line),
          ),
        ],
      ]),
    );
  }
}
