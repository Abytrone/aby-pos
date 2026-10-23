import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';

/// Colour for a category tone. Lime is kept for Pay, the waiting dot and
/// cart counts, so the lime tone is drawn in lime ink.
Color toneColor(CategoryTone tone, AbyColors c) => switch (tone) {
      CategoryTone.midnight => c.primary,
      CategoryTone.lime => c.limeInk,
      CategoryTone.blue => c.blue,
      CategoryTone.coral => c.coral,
    };

class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.tone});

  final CategoryTone tone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      width: AbySize.dot,
      height: AbySize.dot,
      decoration: BoxDecoration(color: toneColor(tone, c), shape: BoxShape.circle),
    );
  }
}
