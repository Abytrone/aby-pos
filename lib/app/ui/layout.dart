import 'package:flutter/material.dart';

import '../theme/aby_theme.dart';

/// Breakpoints shared by every screen.
abstract final class AbyBreakpoints {
  /// Rail navigation and side-by-side layouts (10-inch tablet landscape).
  static const wide = 840.0;

  /// Phones in portrait.
  static const narrow = 600.0;
}

extension LayoutContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isWide => screenWidth >= AbyBreakpoints.wide;
  bool get isNarrow => screenWidth < AbyBreakpoints.narrow;
}

/// Cards that flow across the row at their own widths. Where the space is
/// narrower than [AbyBreakpoints.narrow], two share each row instead, so a
/// phone shows no ragged gap beside a single card.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final half = (box.maxWidth - AbySpace.s3) / 2;
      final narrow = box.maxWidth < AbyBreakpoints.narrow;
      return Wrap(
        spacing: AbySpace.s3,
        runSpacing: AbySpace.s3,
        children: [for (final child in children) narrow ? SizedBox(width: half, child: child) : child],
      );
    });
  }
}

/// On phones, buttons in [child] shrink to fit a row of actions or an app
/// bar: 48 high, no 120-pixel minimum width, slightly smaller text. Tap
/// targets stay at [AbySize.tapMin]. Larger screens are left as they are.
class CompactButtons extends StatelessWidget {
  const CompactButtons({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!context.isNarrow) return child;
    final theme = Theme.of(context);
    ButtonStyle? compact(ButtonStyle? style) => style?.copyWith(
      minimumSize: const WidgetStatePropertyAll(Size(AbySize.tapMin, AbySize.tapMin)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AbySpace.s4)),
      textStyle: WidgetStatePropertyAll(
        style.textStyle?.resolve({})?.copyWith(fontSize: 15) ?? const TextStyle(fontSize: 15),
      ),
    );
    return Theme(
      data: theme.copyWith(
        filledButtonTheme: FilledButtonThemeData(style: compact(theme.filledButtonTheme.style)),
        outlinedButtonTheme: OutlinedButtonThemeData(style: compact(theme.outlinedButtonTheme.style)),
      ),
      child: child,
    );
  }
}
