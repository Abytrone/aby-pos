import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../../../routes/app_routes.dart';
import '../controllers/purchasing_controller.dart';
import 'update_from_delivery.dart';

/// Deliveries received, newest first. Tap one to see it in full.
class DeliveriesTab extends GetView<PurchasingController> {
  const DeliveriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final list = controller.receipts.toList();
      if (list.isEmpty) return EmptyState(icon: Icons.local_shipping_outlined, message: l.deliveriesNone);
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final r = list[i];
          return InkWell(
            onTap: () => showDelivery(controller, r),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AbySpace.s3),
              child: Row(children: [
                Icon(Icons.local_shipping_outlined, color: r.owed > 0 ? c.warning : c.inkMuted),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.displayNumber}  ·  ${r.supplierName ?? l.receiveNoSupplier}',
                        style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                    Text(
                      [formatDateTime(r.at), l.deliveriesItems(r.lineCount), r.receivedByName, ?r.invoiceRef].join('  ·  '),
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(formatMoney(r.total), style: AbyText.price.copyWith(color: c.ink)),
                  if (r.owed > 0)
                    Text(l.deliveriesOwed(formatMoney(r.owed)),
                        style: AbyText.caption.copyWith(color: c.warning, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(width: AbySpace.s2),
                Icon(Icons.chevron_right, color: c.inkMuted),
              ]),
            ),
          );
        },
      );
    });
  }
}

/// One delivery: what came, at what cost, paid and owed, and its goods
/// received note as a PDF to share, save or print.
Future<void> showDelivery(PurchasingController ctl, StockReceipt r) => Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      final c = Theme.of(context).extension<AbyColors>()!;
      final muted = AbyText.caption.copyWith(color: c.inkMuted);
      return FutureBuilder<DeliveryDetail?>(
        future: ctl.delivery(r),
        builder: (context, snap) {
          final d = snap.data;
          Widget money(String label, int amount, {Color? color, bool strong = false}) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Expanded(child: Text(label, style: AbyText.body.copyWith(color: color ?? c.ink))),
                  Text(
                    formatMoney(amount),
                    style: (strong ? AbyText.price : AbyText.body).copyWith(color: color ?? c.ink),
                  ),
                ]),
              );
          return AlertDialog(
            title: Text('${r.displayNumber}  ·  ${r.supplierName ?? l.receiveNoSupplier}'),
            content: SizedBox(
              width: 520,
              child: d == null
                  ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
                  : SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(
                          [
                            formatDateTime(r.at),
                            r.receivedByName,
                            if (r.invoiceRef != null) '${l.receiveInvoice}: ${r.invoiceRef}',
                            if (d.orderNumber != null) l.deliveryAgainstOrder(d.orderNumber!),
                          ].join('  ·  '),
                          style: muted,
                        ),
                        const SizedBox(height: AbySpace.s3),
                        // A table: item, quantity, unit, cost each, line total.
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(3),
                            1: IntrinsicColumnWidth(),
                            2: IntrinsicColumnWidth(),
                            3: IntrinsicColumnWidth(),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            for (final line in d.lines)
                              TableRow(
                                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      InkWell(
                                        onTap: () {
                                          goBack<void>();
                                          Get.toNamed<void>(Routes.stockItem, arguments: line.stockItemId);
                                        },
                                        child: Text(
                                          line.name,
                                          style: AbyText.body.copyWith(color: c.ink, decoration: TextDecoration.underline),
                                        ),
                                      ),
                                      Text(
                                        l.deliveryEach(
                                          formatMoney(priceForUnit(line.unitCostMilli, DisplayUnit.bulk(line.unit))),
                                          DisplayUnit.bulk(line.unit).symbol,
                                        ),
                                        style: muted,
                                      ),
                                    ]),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: AbySpace.s3),
                                    child: Text(
                                      quantityIn(line.quantity, DisplayUnit.bulk(line.unit)),
                                      textAlign: TextAlign.right,
                                      style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: AbySpace.s1),
                                    child: Text(DisplayUnit.bulk(line.unit).symbol, style: muted),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: AbySpace.s4),
                                    child: Text(formatMoney(line.lineTotal),
                                        textAlign: TextAlign.right, style: AbyText.body.copyWith(color: c.ink)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: AbySpace.s3),
                        money(l.receiveTotal, r.total, strong: true),
                        money(l.deliveryPaid, r.paidNow),
                        if (r.owed > 0) money(l.deliveryOwed, r.owed, color: c.warning, strong: true),
                        if (d.note != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AbySpace.s3),
                            child: Text('“${d.note}”', style: muted),
                          ),
                      ]),
                    ),
            ),
            actions: [
              DialogButtons(children: [
                OutlinedButton.icon(
                  onPressed: d == null ? null : () => ctl.shareDelivery(d),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(l.deliveryPdf),
                ),
                if (ctl.canReceive)
                  OutlinedButton.icon(
                    onPressed: d == null
                        ? null
                        : () async {
                            goBack<void>();
                            await showUpdateFromDelivery(d);
                          },
                    icon: const Icon(Icons.sync_alt),
                    label: Text(l.deliveryUpdateStock),
                  ),
                FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
              ]),
            ],
          );
        },
      );
    }));

/// Stock counts: the open one first, then past counts.
class CountsTab extends GetView<PurchasingController> {
  const CountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final list = controller.counts.toList();
      if (list.isEmpty) return EmptyState(icon: Icons.fact_check_outlined, message: l.countsNone);
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final count = list[i];
          final status = switch (count.status) {
            StockCountStatus.open => l.countOpenStatus,
            StockCountStatus.posted => l.countPostedStatus(count.postedByName ?? ''),
            StockCountStatus.cancelled => l.countCancelledStatus,
          };
          return InfoTile(
            title: formatDateTime(count.startedAt),
            subtitle: '${count.startedByName}  ·  ${l.countLines(count.lineCount)}${count.blind ? '  ·  ${l.countBlindShort}' : ''}',
            value: status,
            leading: Icon(
              count.status == StockCountStatus.open ? Icons.pending_actions : Icons.fact_check_outlined,
              color: count.status == StockCountStatus.open ? c.warning : c.inkMuted,
            ),
            onTap: () => controller.openCountPage(count),
          );
        },
      );
    });
  }
}

/// Suppliers and what is owed to each.
class SuppliersTab extends GetView<PurchasingController> {
  const SuppliersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final list = controller.suppliers.toList();
      if (list.isEmpty) return EmptyState(icon: Icons.storefront_outlined, message: l.suppliersNone);
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        if (controller.totalOwed > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: AbySpace.s3),
            child: Text(l.suppliersOwedTotal(formatMoney(controller.totalOwed)),
                style: AbyText.body.copyWith(color: c.warning, fontWeight: FontWeight.w700)),
          ),
        for (final s in list) ...[
          InfoTile(
            title: s.name,
            subtitle: [
              ?s.phone,
              if (s.paymentTermsDays != null) l.supplierTermsShort(s.paymentTermsDays!),
              if (!s.active) l.stockFilterRetired,
            ].join('  ·  '),
            value: supplierBalanceText(l, s),
            onTap: () => controller.openSupplier(s),
          ),
          const Divider(height: 1),
        ],
      ]);
    });
  }
}

/// "Owe GH₵ 120.00" style balance for a supplier.
String supplierBalanceText(AppLocalizations l, Supplier s) => s.balance == 0
    ? l.supplierSettled
    : s.balance > 0
        ? l.supplierOwe(formatMoney(s.balance))
        : l.supplierCredit(formatMoney(-s.balance));
