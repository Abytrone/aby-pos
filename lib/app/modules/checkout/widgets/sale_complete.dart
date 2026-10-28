import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/receipt_actions.dart';

/// Shown once the sale is saved.
class SaleComplete extends StatelessWidget {
  const SaleComplete({super.key, required this.sale, required this.onNewSale});

  final CompletedSale sale;
  final VoidCallback onNewSale;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final back = sale.exchangeRefund;
    // Printed already when this device prints every receipt.
    final printed = Get.find<PrintService>().hasPrinter && Get.find<SettingsService>().get(AppSettings.autoPrint);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, size: 56, color: c.success),
        const SizedBox(height: AbySpace.s3),
        Text(l.checkoutDone, textAlign: TextAlign.center, style: AbyText.title.copyWith(color: c.ink)),
        const SizedBox(height: AbySpace.s1),
        Text(
          '${sale.displayNumber}  ·  ${formatMoney(sale.total)}',
          textAlign: TextAlign.center,
          style: AbyText.body.copyWith(color: c.inkMuted),
        ),
        Text(
          sale.paymentLabels.join('  ·  '),
          textAlign: TextAlign.center,
          style: AbyText.caption.copyWith(color: c.inkMuted),
        ),
        if (sale.rounding != 0)
          Text(
            l.checkoutRoundingLine(formatMoney(sale.rounding.abs()), sale.rounding > 0 ? '+' : '−'),
            textAlign: TextAlign.center,
            style: AbyText.caption.copyWith(color: c.inkMuted),
          ),
        if (back != null)
          Text(
            l.checkoutExchangeLine(back.displayNumber, formatMoney(back.total)),
            textAlign: TextAlign.center,
            style: AbyText.caption.copyWith(color: c.inkMuted),
          ),
        if (sale.changeDue > 0 || (back?.paidBack ?? 0) > 0) ...[
          const SizedBox(height: AbySpace.s6),
          Text(
            (sale.changeDue > 0 ? l.checkoutChange : l.checkoutGiveBackNow).toUpperCase(),
            textAlign: TextAlign.center,
            style: AbyText.label.copyWith(color: c.inkMuted),
          ),
          Text(
            formatMoney(sale.changeDue > 0 ? sale.changeDue : back!.paidBack),
            textAlign: TextAlign.center,
            style: AbyText.total.copyWith(color: c.ink),
          ),
        ],
        const SizedBox(height: AbySpace.s6),
        Text(l.checkoutSavedHere, textAlign: TextAlign.center, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s4),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => printSaleReceipt(sale.saleId, reprint: printed),
              icon: const Icon(Icons.print_outlined),
              label: Text(printed ? l.receiptPrintAgain : l.receiptPrint, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: AbySpace.s2),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => sendSaleReceipt(sale.saleId),
              icon: const Icon(Icons.send_outlined),
              label: Text(l.receiptSend, overflow: TextOverflow.ellipsis),
            ),
          ),
        ]),
        const SizedBox(height: AbySpace.s2),
        FilledButton(autofocus: true, onPressed: onNewSale, child: Text(l.checkoutNewSale)),
      ],
    );
  }
}
