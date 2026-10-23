import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/purchasing_controller.dart';

/// Deliveries received, newest first. Tap one to see its lines.
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
          final owed = r.total - r.paidNow;
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            shape: const Border(),
            title: Row(children: [
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
                if (owed > 0)
                  Text(l.deliveriesOwed(formatMoney(owed)), style: AbyText.caption.copyWith(color: c.warning, fontWeight: FontWeight.w700)),
              ]),
            ]),
            children: [
              FutureBuilder<List<(String, String, int)>>(
                future: controller.receiptLines(r),
                builder: (_, snap) => Column(children: [
                  for (final (name, qty, total) in snap.data ?? const <(String, String, int)>[])
                    InfoTile(title: name, subtitle: qty, value: formatMoney(total)),
                ]),
              ),
            ],
          );
        },
      );
    });
  }
}

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
