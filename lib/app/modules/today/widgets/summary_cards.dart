import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';

/// Total, number of sales, and takings per payment method.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.summary});

  final TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AbySpace.s3,
      runSpacing: AbySpace.s3,
      children: [
        _Card(label: 'TOTAL SALES', value: formatMoney(summary.total), large: true),
        _Card(label: 'NUMBER OF SALES', value: '${summary.count}', large: true),
        for (final m in PaymentMethod.values)
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
          Text(
            value,
            style: (large ? AbyText.title : AbyText.heading).copyWith(
              color: c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
