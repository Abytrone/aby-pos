import 'package:flutter/material.dart';

import '../../../models/enums.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../theme/category_palette.dart';

/// The dot colour for a category tone.
Color toneColor(CategoryTone tone, AbyColors c) => tonePaint(tone, c).dot;

class CategoryDot extends StatelessWidget {
  const CategoryDot({super.key, required this.tone, this.size = AbySize.dot});

  final CategoryTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: toneColor(tone, c), shape: BoxShape.circle),
    );
  }
}
