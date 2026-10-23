import 'package:flutter/material.dart';

import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';

class SaleRow extends StatelessWidget {
  const SaleRow({
    super.key,
    required this.sale,
    required this.onVoid,
    this.locked = false,
  });

  final Sale sale;

  /// Null when the sale cannot be voided.
  final VoidCallback? onVoid;

  /// In a closed day.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final local = sale.createdAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final methods = sale.payments.map((p) => p.method.label).toSet().join(', ');
    final items = sale.itemCount == 1 ? '1 item' : '${sale.itemCount} items';
    final muted = AbyText.caption.copyWith(color: c.inkMuted);
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
                  Text(sale.displayNumber,
                      style: AbyText.receiptStrong.copyWith(color: c.ink)),
                  Text(time, style: muted),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$items  ·  $methods', style: AbyText.body.copyWith(color: c.ink)),
                  if (sale.isVoided)
                    Text('Voided by ${sale.voidedBy ?? 'unknown'}',
                        style: muted.copyWith(color: c.danger))
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
            const SizedBox(width: AbySpace.s3),
            SizedBox(
              width: 96,
              child: sale.isVoided || locked || onVoid == null
                  ? Text(sale.isVoided ? 'Voided' : 'Closed',
                      textAlign: TextAlign.center, style: muted)
                  : TextButton(
                      onPressed: onVoid,
                      style: TextButton.styleFrom(foregroundColor: c.danger),
                      child: const Text('Void'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
