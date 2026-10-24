import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/refund.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../controllers/refund_controller.dart';

class RefundView extends GetView<RefundController> {
  const RefundView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.withoutReceipt
            ? l.refundNoReceiptTitle
            : l.refundTitle(controller.sale.value?.displayNumber ?? ''))),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
      ),
      body: Obx(() {
        if (controller.loading.value) return const Center(child: CircularProgressIndicator());
        final done = controller.done.value;
        if (done != null) return _Done(refund: done);
        final sale = controller.sale.value;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
              if (sale != null) ...[
                Text(
                  [formatDateTime(sale.at), sale.cashierName, formatMoney(sale.total), sale.payments.map((p) => p.label).join(', ')]
                      .join('  ·  '),
                  style: AbyText.body.copyWith(color: c.inkMuted),
                ),
                if (sale.refundedTotal > 0)
                  Text(l.refundAlready(formatMoney(sale.refundedTotal)), style: AbyText.body.copyWith(color: c.warning)),
                if (!sale.canRefund)
                  Padding(
                    padding: const EdgeInsets.only(top: AbySpace.s4),
                    child: Text(sale.voided ? l.refundVoided : l.refundNothingLeft, style: AbyText.body.copyWith(color: c.danger)),
                  ),
                const SizedBox(height: AbySpace.s3),
                Row(children: [
                  Expanded(child: Text(l.refundWhatComesBack.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted))),
                  TextButton(onPressed: controller.all, child: Text(l.refundEverything)),
                ]),
                for (final line in sale.lines) _SaleLineRow(line: line),
              ] else
                const _ManualLines(),
              const SizedBox(height: AbySpace.s4),
              Text(l.refundReason.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                for (final r in controller.reasons)
                  OptionChip(label: r.name, selected: controller.reason.value == r.name, onTap: () => controller.reason.value = r.name),
              ]),
              const SizedBox(height: AbySpace.s3),
              TextField(controller: controller.note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
              const SizedBox(height: AbySpace.s4),
              Text(l.refundHow.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                for (final m in controller.methods)
                  OptionChip(label: m.name, selected: controller.method.value?.id == m.id, onTap: () => controller.method.value = m),
              ]),
              if (controller.method.value?.needsReference ?? false) ...[
                const SizedBox(height: AbySpace.s3),
                TextField(
                  controller: controller.reference,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(labelText: l.refundReference, helperText: l.refundReferenceHelp),
                ),
              ],
              const SizedBox(height: AbySpace.s4),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AbySpace.s4),
                  child: Row(children: [
                    Text(l.refundTotal, style: AbyText.body.copyWith(color: c.inkMuted)),
                    const Spacer(),
                    Text(formatMoney(controller.total), style: AbyText.title.copyWith(color: c.ink)),
                  ]),
                ),
              ),
              if (controller.error.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: AbySpace.s3),
                  child: Text(controller.error.value!, style: AbyText.body.copyWith(color: c.danger)),
                ),
              const SizedBox(height: AbySpace.s4),
              FilledButton(
                onPressed: controller.canRefund ? controller.refund : null,
                child: Text(l.refundButton(formatMoney(controller.total))),
              ),
              const SizedBox(height: AbySpace.s2),
              OutlinedButton(
                onPressed: controller.total > 0 && !controller.saving.value ? controller.exchange : null,
                child: Text(l.refundExchange),
              ),
              const SizedBox(height: AbySpace.s1),
              Text(l.refundExchangeHelp, style: AbyText.caption.copyWith(color: c.inkMuted), textAlign: TextAlign.center),
              const SizedBox(height: AbySpace.s8),
            ]),
          ),
        );
      }),
    );
  }
}

class _SaleLineRow extends GetView<RefundController> {
  const _SaleLineRow({required this.line});

  final RefundableLine line;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final q = controller.quantityOf(line);
    final gone = line.left <= 0;
    return Card(
      margin: const EdgeInsets.only(bottom: AbySpace.s2),
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(line.title, style: AbyText.tile.copyWith(color: gone ? c.inkMuted : c.ink)),
                if (line.optionsLine.isNotEmpty) Text('+ ${line.optionsLine}', style: AbyText.caption.copyWith(color: c.inkMuted)),
                Text(
                  [
                    l.refundSold(line.quantityText(line.sold), formatMoney(line.paid)),
                    if (line.refunded > 0) l.refundBackAlready(line.quantityText(line.refunded)),
                  ].join('  ·  '),
                  style: AbyText.caption.copyWith(color: c.inkMuted),
                ),
              ]),
            ),
            if (!gone && !line.weighed) ...[
              IconButton.outlined(tooltip: l.cartOneLess, onPressed: () => controller.setQuantity(line, q - 1), icon: const Icon(Icons.remove)),
              SizedBox(width: 40, child: Text('$q', textAlign: TextAlign.center, style: AbyText.price.copyWith(color: c.ink))),
              IconButton.outlined(tooltip: l.cartOneMore, onPressed: () => controller.setQuantity(line, q + 1), icon: const Icon(Icons.add)),
            ] else if (!gone)
              Checkbox(value: q > 0, onChanged: (v) => controller.setQuantity(line, (v ?? false) ? line.left : 0)),
          ]),
          if (q > 0)
            Row(children: [
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(l.refundRestock),
                  subtitle: Text(controller.restockOf(line.saleLineId) ? l.refundRestockHelp : l.refundDamagedHelp),
                  value: controller.restockOf(line.saleLineId),
                  onChanged: (v) => controller.setRestock(line.saleLineId, v ?? true),
                ),
              ),
              Text(formatMoney(line.amountFor(q)), style: AbyText.price.copyWith(color: c.ink)),
            ]),
        ]),
      ),
    );
  }
}

class _ManualLines extends GetView<RefundController> {
  const _ManualLines();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(AbySpace.s3),
        decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
        child: Text(l.refundNoReceiptHelp, style: AbyText.body.copyWith(color: c.ink)),
      ),
      const SizedBox(height: AbySpace.s3),
      for (final (i, m) in controller.manual.indexed)
        Card(
          margin: const EdgeInsets.only(bottom: AbySpace.s2),
          child: Padding(
            padding: const EdgeInsets.all(AbySpace.s3),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text(m.title, style: AbyText.tile.copyWith(color: c.ink))),
                IconButton.outlined(tooltip: l.cartOneLess, onPressed: () => controller.changeManualQuantity(m, -1), icon: const Icon(Icons.remove)),
                SizedBox(width: 40, child: Text('${m.quantity}', textAlign: TextAlign.center, style: AbyText.price.copyWith(color: c.ink))),
                IconButton.outlined(tooltip: l.cartOneMore, onPressed: () => controller.changeManualQuantity(m, 1), icon: const Icon(Icons.add)),
                IconButton(tooltip: l.lineRemove, onPressed: () => controller.removeManual(m), icon: const Icon(Icons.close)),
              ]),
              Row(children: [
                Expanded(
                  child: CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l.refundRestock),
                    value: controller.restockOf('m$i'),
                    onChanged: (v) => controller.setRestock('m$i', v ?? true),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: m.amount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l.refundAmount, prefixText: 'GH₵ ', isDense: true),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      Autocomplete<String>(
        optionsBuilder: (v) {
          final q = v.text.trim().toLowerCase();
          if (q.isEmpty) return const Iterable<String>.empty();
          return controller.products.where((p) => p.name.toLowerCase().contains(q)).map((p) => p.id).take(8);
        },
        displayStringForOption: (id) => controller.products.firstWhere((p) => p.id == id).name,
        onSelected: (id) => controller.addManual(controller.products.firstWhere((p) => p.id == id)),
        fieldViewBuilder: (context, text, focus, _) => TextField(
          controller: text,
          focusNode: focus,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search), labelText: l.refundAddItem),
        ),
      ),
    ]);
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.refund});

  final CompletedRefund refund;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AbySpace.s6),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(Icons.check_circle, size: 56, color: c.success),
            const SizedBox(height: AbySpace.s3),
            Text(l.refundDone(refund.displayNumber), textAlign: TextAlign.center, style: AbyText.title.copyWith(color: c.ink)),
            const SizedBox(height: AbySpace.s4),
            Text(l.refundGiveBack.toUpperCase(), textAlign: TextAlign.center, style: AbyText.label.copyWith(color: c.inkMuted)),
            Text(formatMoney(refund.paidBack), textAlign: TextAlign.center, style: AbyText.total.copyWith(color: c.ink)),
            const SizedBox(height: AbySpace.s6),
            // TODO(print): print a refund slip here.
            FilledButton(autofocus: true, onPressed: () => Get.back<void>(), child: Text(l.commonDone)),
          ]),
        ),
      ),
    );
  }
}
