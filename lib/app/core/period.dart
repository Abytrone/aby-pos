/// The periods reports and Money offer.
enum ReportPeriod { today, thisWeek, thisMonth, lastMonth, custom }

/// [from] (inclusive) to [to] (exclusive), whole days.
class DateRange {
  const DateRange(this.from, this.to);

  /// The range for [p] around [now]. Weeks start on Monday. A custom range
  /// runs from the start of [start] to the end of [end].
  factory DateRange.of(ReportPeriod p, DateTime now, {DateTime? start, DateTime? end}) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (p) {
      ReportPeriod.today => DateRange(today, today.add(const Duration(days: 1))),
      ReportPeriod.thisWeek => DateRange(today.subtract(Duration(days: today.weekday - 1)), today.add(const Duration(days: 1))),
      ReportPeriod.thisMonth => DateRange(DateTime(now.year, now.month), DateTime(now.year, now.month + 1)),
      ReportPeriod.lastMonth => DateRange(DateTime(now.year, now.month - 1), DateTime(now.year, now.month)),
      ReportPeriod.custom => () {
          final s = start ?? today;
          final e = end ?? today;
          return DateRange(DateTime(s.year, s.month, s.day), DateTime(e.year, e.month, e.day).add(const Duration(days: 1)));
        }(),
    };
  }

  final DateTime from;
  final DateTime to;

  /// The same length of time just before.
  DateRange get previous => DateRange(from.subtract(to.difference(from)), from);

  int get days => to.difference(from).inDays;

  /// The last day included.
  DateTime get lastDay => to.subtract(const Duration(days: 1));
}
