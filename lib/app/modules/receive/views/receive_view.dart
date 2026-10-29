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
import '../../../ui/option_chip.dart';
import '../../products/widgets/labels_dialog.dart';
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
              child: FilledButton(
                onPressed: ctl.loading || ctl.saving
                    ? null
                    : () async {
                        if (await ctl.save()) {
                          goBack<void>();
                          showMessage(l.receiveDone(ctl.lastReceipt!.displayNumber));
                          // Price stickers for what came in.
                          final counts = await labelCountsFor(ctl.received);
                          if (counts.isNotEmpty &&
                              await confirmDialog(
                                title: l.labelsForDelivery,
                                message: l.labelsForDeliveryBody(counts.length),
                                confirmLabel: l.labelsTitle,
                              )) {
                            await showLabels(preset: counts);
                          }
                        }
                      },
                child: Text(l.receiveSave),
              ),
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
                        child: Text(
                          l.receiveAgainst(ctl.order!.displayNumber, ctl.order!.supplierName),
                          style: AbyText.heading.copyWith(color: c.ink),
                        ),
                      ),
                    Wrap(spacing: AbySpace.s3, runSpacing: AbySpace.s3, children: [
                      SizedBox(
                        width: 320,
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
                        width: 240,
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
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: line.stockItemId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.recipeItem, isDense: true),
              items: [for (final i in ctl.items) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => ctl.setItem(line, v),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: line.quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => ctl.changed(),
              decoration: InputDecoration(labelText: l.stockHowMuch, isDense: true),
            ),
          ),
          if (units.length > 1)
            DropdownButton<DisplayUnit>(
              value: line.unit,
              items: [for (final u in units) DropdownMenuItem(value: u, child: Text(u.symbol))],
              onChanged: (u) => u == null ? null : ctl.setUnit(line, u),
            )
          else if (line.unit != null)
            Text(line.unit!.symbol, style: AbyText.body.copyWith(color: c.inkMuted)),
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
