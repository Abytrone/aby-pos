import 'package:flutter/material.dart';

import '../services/money.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';

/// Simple vertical bars with a label under each (sales by day, by hour).
/// Values are pesewas; the tallest bar shows its amount.
class BarStrip extends StatelessWidget {
  const BarStrip({super.key, required this.values, required this.labels, this.height = 140, this.highlight});

  final List<int> values;
  final List<String> labels;
  final double height;

  /// A bar to colour differently (the current hour).
  final int? highlight;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final top = values.fold(0, (m, v) => v > m ? v : m);
    final peak = values.indexOf(top);
    final step = (labels.length / 12).ceil().clamp(1, 1000);
    return SizedBox(
      height: height + 40,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          height: 16,
          child: top <= 0
              ? null
              : Text(formatMoney(top), style: AbyText.caption.copyWith(color: c.inkMuted), textAlign: TextAlign.end),
        ),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final (i, v) in values.indexed)
              Expanded(
                child: Tooltip(
                  message: '${labels[i]}: ${formatMoney(v)}',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    height: top <= 0 ? 2 : 2 + (height - 2) * v / top,
                    decoration: BoxDecoration(
                      color: i == highlight ? c.coral : (i == peak && top > 0 ? c.blue : c.blue.withValues(alpha: 0.55)),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: AbySpace.s1),
        Row(children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              child: Text(
                i % step == 0 ? label : '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: AbyText.caption.copyWith(color: c.inkMuted, fontSize: 11),
              ),
            ),
        ]),
      ]),
    );
  }
}

/// Day of week × hour of day, darker for busier. [grid] is [weekday-1][hour].
class Heatmap extends StatelessWidget {
  const Heatmap({super.key, required this.grid, required this.dayLabels});

  final List<List<int>> grid;
  final List<String> dayLabels;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final top = grid.expand((r) => r).fold(0, (m, v) => v > m ? v : m);
    // Only the hours the shop was open.
    final hours = [for (var h = 0; h < 24; h++) if (grid.any((r) => r[h] > 0)) h];
    final shown = hours.isEmpty ? [for (var h = 8; h < 22; h++) h] : [for (var h = hours.first; h <= hours.last; h++) h];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        const SizedBox(width: 44),
        for (final h in shown)
          Expanded(
            child: Text('$h', textAlign: TextAlign.center, style: AbyText.caption.copyWith(color: c.inkMuted, fontSize: 11)),
          ),
      ]),
      for (final (d, row) in grid.indexed)
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(children: [
            SizedBox(width: 44, child: Text(dayLabels[d], style: AbyText.caption.copyWith(color: c.inkMuted))),
            for (final h in shown)
              Expanded(
                child: Tooltip(
                  message: '${dayLabels[d]} $h:00 · ${formatMoney(row[h])}',
                  child: Container(
                    height: 26,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: row[h] == 0 || top == 0
                          ? c.surfaceSunken
                          : c.blue.withValues(alpha: 0.15 + 0.85 * row[h] / top),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ]),
        ),
    ]);
  }
}
