// The Aby mark as a widget. Needs flutter_svg and the SVGs in assets/brand/.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AbyMarkTone { brand, reversed, mono }

class AbyMark extends StatelessWidget {
  const AbyMark({super.key, this.size = 32, this.tone = AbyMarkTone.brand});
  final double size;
  final AbyMarkTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final file = switch (tone) {
      AbyMarkTone.mono => 'assets/brand/aby-mark-mono.svg',
      AbyMarkTone.reversed => 'assets/brand/aby-mark-reversed.svg',
      AbyMarkTone.brand => dark ? 'assets/brand/aby-mark-reversed.svg' : 'assets/brand/aby-mark.svg',
    };
    return SvgPicture.asset(file, width: size, height: size, semanticsLabel: 'Aby');
  }
}
