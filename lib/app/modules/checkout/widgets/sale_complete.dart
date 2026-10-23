import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';

/// Shown once the sale is saved.
class SaleComplete extends StatelessWidget {
  const SaleComplete({super.key, required this.sale, required this.onNewSale});

  final CompletedSale sale;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final showChange = sale.method == PaymentMethod.cash;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, size: 56, color: c.success),
        const SizedBox(height: AbySpace.s3),
        Text(
          'Sale complete',
          textAlign: TextAlign.center,
          style: AbyText.title.copyWith(color: c.ink),
        ),
        const SizedBox(height: AbySpace.s1),
        Text(
          '${sale.displayNumber}  ·  ${sale.method.label}  ·  ${formatMoney(sale.total)}',
          textAlign: TextAlign.center,
          style: AbyText.body.copyWith(color: c.inkMuted),
        ),
        if (showChange) ...[
          const SizedBox(height: AbySpace.s6),
          Text('CHANGE DUE', textAlign: TextAlign.center, style: AbyText.label.copyWith(color: c.inkMuted)),
          Text(
            formatMoney(sale.changeDue),
            textAlign: TextAlign.center,
            style: AbyText.total.copyWith(color: c.ink),
          ),
        ],
        const SizedBox(height: AbySpace.s6),
        Text(
          "Saved on this device. Will sync when you're online.",
          textAlign: TextAlign.center,
          style: AbyText.caption.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AbySpace.s4),
        // TODO(print): add a "Print receipt" button next to this.
        FilledButton(
          autofocus: true,
          onPressed: onNewSale,
          child: const Text('New sale'),
        ),
      ],
    );
  }
}
