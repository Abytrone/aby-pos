import 'package:flutter/material.dart';

import '../../../models/day_close.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';

/// The figures of a shift so far (X report) or at its close (Z report):
/// sales, payments, refunds, discounts, voids, cash in and out, no-sales.
/// [showCash] false hides what the drawer should hold (blind count).
class PeriodSummary extends StatelessWidget {
  const PeriodSummary({super.key, required this.period, this.openingFloat, this.showCash = true});

  final OpenPeriod period;
  final int? openingFloat;
  final bool showCash;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    Widget line(String label, String value, {bool strong = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
          child: Row(children: [
            Expanded(child: Text(label, style: AbyText.body.copyWith(color: strong ? c.ink : c.inkMuted))),
            Text(
              value,
              style: (strong ? AbyText.heading : AbyText.body).copyWith(
                color: color ?? c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ]),
        );
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s4),
        child: Column(children: [
          line(l.closeSales(period.salesCount), formatMoney(period.salesTotal), strong: true),
          if (period.voidedCount > 0) line(l.closeVoided(period.voidedCount), ''),
          if (period.discountTotal > 0) line(l.closeDiscounts, '−${formatMoney(period.discountTotal)}'),
          if (period.refundsCount > 0) line(l.closeRefunds(period.refundsCount), '−${formatMoney(period.refundsTotal)}'),
          const Divider(height: AbySpace.s6),
          // Cash (unless counting blind), MoMo and credit always; the rest
          // when they were used.
          for (final m in PaymentMethod.values)
            if (m == PaymentMethod.cash
                ? showCash
                : m == PaymentMethod.momo || m == PaymentMethod.credit || (period.byMethod[m] ?? 0) > 0)
              line(m.label, formatMoney(period.byMethod[m] ?? 0)),
          if (period.rounding != 0 && showCash) line(l.closeRounding, formatMoney(period.rounding)),
          if (showCash) ...[
            const Divider(height: AbySpace.s6),
            if (openingFloat != null) line(l.closeFloat, formatMoney(openingFloat!)),
            if (period.customerCash > 0) line(l.closeCustomerCash, formatMoney(period.customerCash)),
            if (period.payIns > 0) line(l.closePayIns, formatMoney(period.payIns)),
            if (period.payOuts > 0) line(l.closePayOuts, '−${formatMoney(period.payOuts)}'),
            if (period.safeDrops > 0) line(l.closeSafeDrops, '−${formatMoney(period.safeDrops)}'),
            if (period.cashRefunds > 0) line(l.closeRefundsBy(PaymentMethod.cash.label), '−${formatMoney(period.cashRefunds)}'),
            if (openingFloat != null)
              line(l.closeExpected, formatMoney(period.expectedCash(openingFloat!)), strong: true),
          ],
          if (period.noSaleCount > 0) ...[
            const Divider(height: AbySpace.s6),
            for (final e in period.noSales.entries) line(l.closeNoSales(e.key), '${e.value}'),
          ],
        ]),
      ),
    );
  }
}
