import 'package:flutter/material.dart';

import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';

class SaleRow extends StatelessWidget {
  const SaleRow({
    super.key,
    required this.sale,
    required this.onVoid,
    required this.onRefund,
    this.onPrint,
    this.onSend,
    this.locked = false,
  });

  /// Print or send the receipt again.
  final VoidCallback? onPrint;
  final VoidCallback? onSend;

  final Sale sale;

  /// Null when the sale cannot be voided.
  final VoidCallback? onVoid;

  /// Null when nothing on the sale can be refunded.
  final VoidCallback? onRefund;

  /// In a closed day.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final local = sale.createdAt.toLocal();
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final methods = sale.payments.map((p) => p.label).toSet().join(', ');
    final muted = AbyText.caption.copyWith(color: c.inkMuted);
    final narrow = context.isNarrow;
    final actions = [
      if (onRefund != null)
        TextButton(onPressed: onRefund, child: Text(l.todayRefund)),
      if (onVoid != null)
        TextButton(
          onPressed: onVoid,
          style: TextButton.styleFrom(foregroundColor: c.danger),
          child: Text(l.todayVoid),
        ),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AbySize.tapPos + AbySpace.s4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s2),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.displayNumber, style: AbyText.receiptStrong.copyWith(color: c.ink)),
                  Text(time, style: muted),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${l.todayItems(sale.itemCount)}  ·  $methods', style: AbyText.body.copyWith(color: c.ink)),
                  if (sale.isVoided)
                    Text(l.todayVoidedBy(sale.voidedBy ?? '?'), style: muted.copyWith(color: c.danger))
                  else if (sale.hasRefunds)
                    Text(l.todayRefunded(formatMoney(sale.refunded)), style: muted.copyWith(color: c.warning))
                  else
                    Text(sale.cashierName, style: muted),
                ],
              ),
            ),
            Text(
              formatMoney(sale.total),
              style: AbyText.price.copyWith(
                color: sale.isVoided ? c.inkMuted : c.ink,
                decoration: sale.isVoided ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(width: AbySpace.s2),
            if (actions.isEmpty)
              SizedBox(
                width: 96,
                child: Text(
                  sale.isVoided ? l.todayVoided : (locked ? l.todayClosed : l.todayRefundedAll),
                  textAlign: TextAlign.center,
                  style: muted,
                ),
              )
            else if (!narrow)
              Row(mainAxisSize: MainAxisSize.min, children: actions),
            if (narrow || onPrint != null || onSend != null)
              PopupMenuButton<VoidCallback>(
                tooltip: l.commonMore,
                onSelected: (f) => f(),
                itemBuilder: (_) => [
                  if (narrow && onRefund != null) PopupMenuItem(value: onRefund, child: Text(l.todayRefund)),
                  if (narrow && onVoid != null) PopupMenuItem(value: onVoid, child: Text(l.todayVoid)),
                  if (onPrint != null) PopupMenuItem(value: onPrint, child: Text(l.receiptPrint)),
                  if (onSend != null) PopupMenuItem(value: onSend, child: Text(l.receiptSend)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
