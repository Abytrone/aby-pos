import 'package:flutter/material.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';

/// A figure with a label and an optional second line.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.label, required this.value, this.detail, this.color});

  final String label;
  final String value;
  final String? detail;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(AbySpace.s4),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AbyRadius.md),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(label.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s1),
        Text(value,
            style: AbyText.heading.copyWith(
              color: color ?? c.ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            )),
        if (detail != null) Text(detail!, style: AbyText.caption.copyWith(color: c.inkMuted)),
      ]),
    );
  }
}
