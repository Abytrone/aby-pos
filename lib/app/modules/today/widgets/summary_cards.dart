import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';

/// Total, number of sales, and takings per payment method.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TileGrid(
      children: [
        _Card(label: l.todayTotalSales.toUpperCase(), value: formatMoney(summary.total), large: true),
        _Card(label: l.todaySalesCount.toUpperCase(), value: '${summary.count}', large: true),
        if (summary.refunded > 0)
          _Card(label: l.todayRefunds.toUpperCase(), value: '−${formatMoney(summary.refunded)}'),
        // Cash, MoMo and credit always; the others when they were used.
        for (final m in PaymentMethod.values)
          if (const {PaymentMethod.cash, PaymentMethod.momo, PaymentMethod.credit}.contains(m) ||
              (summary.byMethod[m] ?? 0) > 0)
            _Card(label: m.label.toUpperCase(), value: formatMoney(summary.byMethod[m] ?? 0)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.value, this.large = false});

  final String label;
  final String value;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      width: large ? 260 : 200,
      padding: const EdgeInsets.all(AbySpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AbyRadius.md),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AbyText.label.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s1),
          // Shrinks a big total to fit a phone's half-width card.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: (large ? AbyText.title : AbyText.heading).copyWith(
                color: c.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
