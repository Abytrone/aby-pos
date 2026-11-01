import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/option_chip.dart';
import '../../products/controllers/catalogue_controller.dart';
import '../../products/widgets/labels_dialog.dart';
import '../../stock/widgets/stock_item_editor.dart';
import '../../shell/controllers/shell_controller.dart';
import '../controllers/receive_controller.dart';

String payMethodLabel(AppLocalizations l, SupplierPaymentMethod m) => switch (m) {
      SupplierPaymentMethod.cash => l.payCash,
      SupplierPaymentMethod.momo => l.payMomo,
      SupplierPaymentMethod.bank => l.payBank,
      SupplierPaymentMethod.other => l.payOther,
    };

class ReceiveView extends StatelessWidget {
  const ReceiveView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return GetBuilder<ReceiveController>(builder: (ctl) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l.receiveNew),
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AbySpace.s4),
              child: CompactButtons(child: FilledButton(
                onPressed: ctl.loading || ctl.saving
                    ? null
                    : () async {
                        if (await ctl.save()) {
                          goBack<void>();
                          final counts = await labelCountsFor(ctl.received);
                          await showDeliverySummary(ctl.summary!, labels: counts);
                        }
                      },
                child: Text(l.receiveSave),
              )),
            ),
          ],
        ),
        body: ctl.loading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
                    if (ctl.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AbySpace.s4),
                        padding: const EdgeInsets.all(AbySpace.s3),
                        decoration: BoxDecoration(color: c.dangerSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
                        child: Text(ctl.error!, style: AbyText.body.copyWith(color: c.danger)),
                      ),
                    if (ctl.order != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AbySpace.s3),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            l.receiveAgainst(ctl.order!.displayNumber, ctl.order!.supplierName),
                            style: AbyText.heading.copyWith(color: c.ink),
                          ),
                          Text(l.receiveZeroHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
                        ]),
                      ),
                    Wrap(spacing: AbySpace.s3, runSpacing: AbySpace.s3, children: [
                      SizedBox(
                        width: context.isNarrow ? double.infinity : 320,
                        child: DropdownButtonFormField<String?>(
                          initialValue: ctl.supplierId,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.receiveSupplier),
                          items: [
                            DropdownMenuItem<String?>(value: null, child: Text(l.receiveNoSupplier, overflow: TextOverflow.ellipsis)),
                            for (final s in ctl.suppliers) DropdownMenuItem<String?>(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: ctl.setSupplier,
                        ),
                      ),
                      SizedBox(
                        width: context.isNarrow ? double.infinity : 240,
                        child: TextField(
                          controller: ctl.invoiceRef,
                          decoration: InputDecoration(labelText: l.receiveInvoice),
                        ),
                      ),
                    ]),
                    const SizedBox(height: AbySpace.s6),
                    Row(children: [
                      Expanded(child: Text(l.receiveWhatCame.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted))),
                      TextButton.icon(
                        onPressed: ctl.addLowItems,
                        icon: const Icon(Icons.playlist_add),
                        label: Text(l.receiveAddLow),
                      ),
                    ]),
                    for (final line in ctl.lines) _LineRow(ctl: ctl, line: line),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(onPressed: ctl.addLine, icon: const Icon(Icons.add), label: Text(l.receiveAddLine)),
                    ),
                    const SizedBox(height: AbySpace.s6),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(AbySpace.s4),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(children: [
                            Text(l.receiveTotal, style: AbyText.body.copyWith(color: c.inkMuted)),
                            const Spacer(),
                            Text(formatMoney(ctl.total), style: AbyText.title.copyWith(color: c.ink)),
                          ]),
                          const SizedBox(height: AbySpace.s3),
                          TextField(
                            controller: ctl.paidNow,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) {
                              ctl.touchPaid();
                              ctl.update();
                            },
                            decoration: InputDecoration(
                              labelText: l.receivePaidNow,
                              prefixText: 'GH₵ ',
                              helperText: ctl.supplierId == null ? l.receivePaidNowNoSupplier : l.receivePaidNowHelp,
                            ),
                          ),
                          const SizedBox(height: AbySpace.s3),
                          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                            for (final m in SupplierPaymentMethod.values)
                              OptionChip(label: payMethodLabel(l, m), selected: ctl.paidWith == m, onTap: () => ctl.setPaidWith(m)),
                          ]),
                          const SizedBox(height: AbySpace.s3),
                          TextField(controller: ctl.note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: AbySpace.s8),
                  ]),
                ),
              ),
      );
    });
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.ctl, required this.line});

  final ReceiveController ctl;
  final ReceiveLineForm line;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final item = ctl.itemOf(line);
    final units = item == null ? const <DisplayUnit>[] : DisplayUnit.forBase(item.unit);
    final unitPrice = ctl.unitPrice(line);
    return Card(
      margin: const EdgeInsets.only(bottom: AbySpace.s2),
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s3),
        child: Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: context.isNarrow ? double.infinity : 260,
            child: DropdownButtonFormField<String>(
              key: ValueKey((line, line.version)),
              initialValue: line.stockItemId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.recipeItem, isDense: true),
              items: [
                for (final i in ctl.items) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis)),
                DropdownMenuItem(
                  value: newStockItemChoice,
                  child: Text(l.stockNewItemInline, style: TextStyle(color: c.blue, fontWeight: FontWeight.w600)),
                ),
              ],
              onChanged: (v) => ctl.setItem(line, v),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: line.quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => ctl.changed(),
              decoration: InputDecoration(
                labelText: l.stockQuantity,
                suffixText: units.length > 1 ? null : line.unit?.symbol,
                isDense: true,
              ),
            ),
          ),
          if (units.length > 1)
            DropdownButton<DisplayUnit>(
              value: line.unit,
              items: [for (final u in units) DropdownMenuItem(value: u, child: Text(u.symbol))],
              onChanged: (u) => u == null ? null : ctl.setUnit(line, u),
            ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: line.total,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => ctl.changed(),
              decoration: InputDecoration(labelText: l.receiveLineCost, prefixText: 'GH₵ ', isDense: true),
            ),
          ),
          if (unitPrice != null && item != null)
            Text(l.stockCostEach(formatMoney(unitPrice), DisplayUnit.bulk(item.unit).symbol),
                style: AbyText.caption.copyWith(color: c.inkMuted)),
          IconButton(tooltip: l.recipeRemove, icon: const Icon(Icons.close), onPressed: () => ctl.removeLine(line)),
          if (line.ordered != null && item != null)
            SizedBox(
              width: double.infinity,
              child: Text(
                line.receivedBefore > 0
                    ? l.receiveOrdered(formatQuantity(line.ordered!, item.unit), formatQuantity(line.receivedBefore, item.unit))
                    : l.receiveOrderedOnly(formatQuantity(line.ordered!, item.unit)),
                style: AbyText.caption.copyWith(color: c.blue),
              ),
            ),
          if (item?.tracksExpiry ?? false) ...[
            SizedBox(
              width: 160,
              child: TextField(
                controller: line.batchNo,
                decoration: InputDecoration(labelText: l.receiveBatchNo, isDense: true),
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.event, size: 18),
              label: Text(line.expiresOn == null ? l.receiveExpiry : l.receiveExpiresOn(formatDate(line.expiresOn!))),
              onPressed: () async {
                final now = DateTime.now();
                final day = await showDatePicker(
                  context: context,
                  initialDate: line.expiresOn ?? now.add(const Duration(days: 30)),
                  firstDate: now.subtract(const Duration(days: 30)),
                  lastDate: DateTime(now.year + 5),
                );
                if (day != null) ctl.setExpiry(line, day);
              },
            ),
          ],
        ]),
      ),
    );
  }
}

/// After a delivery: each item's stock and cost before and after, how the
/// order stands, products whose margin fell below the target (with a way to
/// their prices), and price labels for what came in.
Future<void> showDeliverySummary(DeliverySummary s, {Map<String, int> labels = const {}}) => Get.dialog<void>(Builder(builder: (context) {
      final c = Theme.of(context).extension<AbyColors>()!;
      final l = context.l10n;
      final muted = AbyText.caption.copyWith(color: c.inkMuted);
      final o = s.order;
      return AlertDialog(
        title: Text(l.receiveSummaryTitle(s.number)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (o != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AbySpace.s3),
                  child: Text(
                    s.stillWaiting == 0
                        ? l.receiveSummaryOrderDone(o.displayNumber)
                        : l.receiveSummaryOrderWaiting(s.stillWaiting, o.displayNumber),
                    style: AbyText.body.copyWith(color: s.stillWaiting == 0 ? c.success : c.warning, fontWeight: FontWeight.w600),
                  ),
                ),
              Text(l.receiveSummaryStock.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              for (final (before, after) in s.changes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(after.name, style: AbyText.body.copyWith(color: c.ink)),
                        if (before.bulkPrice != after.bulkPrice)
                          Text(
                            l.receiveSummaryCost(
                              formatMoney(before.bulkPrice),
                              formatMoney(after.bulkPrice),
                              DisplayUnit.bulk(after.unit).symbol,
                            ),
                            style: muted,
                          ),
                      ]),
                    ),
                    Text(
                      l.receiveSummaryOnHand(before.onHandText, after.onHandText),
                      style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                    ),
                  ]),
                ),
              if (s.belowMargin.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AbySpace.s3),
                  padding: const EdgeInsets.all(AbySpace.s3),
                  decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AbyRadius.md)),
                  child: Text(
                    l.receiveSummaryLowMargin(s.belowMargin.length, '${s.targetMargin}', s.belowMargin.take(5).join(', ')),
                    style: AbyText.body.copyWith(color: c.warning),
                  ),
                ),
            ]),
          ),
        ),
        actions: [
          DialogButtons(children: [
            if (labels.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () async {
                  goBack<void>();
                  await showLabels(preset: labels);
                },
                icon: const Icon(Icons.label_outline),
                label: Text(l.receiveSummaryLabels),
              ),
            if (s.belowMargin.isNotEmpty)
              OutlinedButton(
                onPressed: () {
                  goBack<void>();
                  reviewLowMargins();
                },
                child: Text(l.receiveSummaryReview),
              ),
            FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
          ]),
        ],
      );
    }));

/// Manage → Products, showing those below the target margin.
void reviewLowMargins() {
  if (Get.isRegistered<CatalogueController>()) Get.find<CatalogueController>().filter.value = ProductFilter.belowMargin;
  if (Get.isRegistered<ShellController>()) Get.find<ShellController>().select(ShellSection.products);
}
