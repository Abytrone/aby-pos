import 'package:flutter/widgets.dart';

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
