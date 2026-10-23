/// Stock rules that are plain arithmetic, kept apart so they are easy to
/// test and the same everywhere.
abstract final class Inventory {
  /// Weighted average cost after receiving [qty] at [newCostMilli], when
  /// [onHand] was in stock at [oldCostMilli]. If the till thought stock had
  /// run out (or gone negative), the delivery's cost wins outright.
  static int averageCost({
    required int onHand,
    required int oldCostMilli,
    required int qty,
    required int newCostMilli,
  }) {
    if (qty <= 0) return oldCostMilli;
    if (onHand <= 0) return newCostMilli;
    final total = onHand * oldCostMilli + qty * newCostMilli;
    return (total + (onHand + qty) ~/ 2) ~/ (onHand + qty);
  }

  /// A low-stock level: enough for [leadDays] at the recent daily use, plus
  /// half again in case. [used] is base units used over [overDays].
  static int? suggestReorderPoint({required int used, int overDays = 28, int leadDays = 3}) {
    if (used <= 0) return null;
    final perDay = used / overDays;
    return (perDay * leadDays * 1.5).ceil();
  }

  /// Days the current stock lasts at the recent daily use, or null when
  /// nothing has been used.
  static double? daysLeft({required int onHand, required int used, int overDays = 28}) {
    if (used <= 0) return null;
    if (onHand <= 0) return 0;
    return onHand / (used / overDays);
  }
}
