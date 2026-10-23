import 'package:flutter/material.dart';

import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';

/// "Drawer balances", "Over by" or "Short by". Pesewas.
class DifferenceBox extends StatelessWidget {
  const DifferenceBox({super.key, required this.difference});

  /// Null until the count is entered.
  final int? difference;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final d = difference;
    final (label, fg, bg) = switch (d) {
      null => ('Enter the cash you counted', c.inkMuted, c.surfaceSunken),
      0 => ('Drawer balances', c.success, c.successSoft),
      > 0 => ('Over by', c.warning, c.warningSoft),
      _ => ('Short by', c.danger, c.dangerSoft),
    };
    return Container(
      padding: const EdgeInsets.all(AbySpace.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AbyRadius.md),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AbyText.body.copyWith(color: fg, fontWeight: FontWeight.w700))),
          if (d != null && d != 0)
            Text(formatMoney(d.abs()),
                style: AbyText.title.copyWith(
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
        ],
      ),
    );
  }
}
