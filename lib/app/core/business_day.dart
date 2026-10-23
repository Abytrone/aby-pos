/// A trading day that can run past midnight. With a start of 05:00, a sale
/// at 01:30 on Saturday belongs to Friday's business day.
class BusinessDay {
  BusinessDay._(this.start, this.end);

  /// The business day containing [moment] (local time).
  factory BusinessDay.containing(DateTime moment, {required int startMinutes}) {
    final local = moment.toLocal();
    final offset = Duration(minutes: startMinutes);
    final shifted = local.subtract(offset);
    final start = DateTime(shifted.year, shifted.month, shifted.day).add(offset);
    // DateTime arithmetic on calendar days keeps 24h days in Ghana (no DST),
    // but use calendar math anyway so other time zones stay correct.
    final next = DateTime(shifted.year, shifted.month, shifted.day + 1).add(offset);
    return BusinessDay._(start, next);
  }

  /// Inclusive.
  final DateTime start;

  /// Exclusive.
  final DateTime end;

  /// The calendar date the day is named after.
  DateTime get date => DateTime(start.year, start.month, start.day);

  bool contains(DateTime moment) {
    final local = moment.toLocal();
    return !local.isBefore(start) && local.isBefore(end);
  }
}
