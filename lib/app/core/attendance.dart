import 'settings.dart';

/// What happens at close day to people who are still clocked in.
/// Stored as the setting's text value.
abstract final class CloseWithOthersIn {
  /// Left open and flagged: their hours wait for an owner (the default).
  static const review = 'review';

  /// Close day is blocked until each person clocks out themselves, or a
  /// manager corrects them with a reason.
  static const block = 'block';

  /// Left open without review: paid up to their last sale. For a shop where
  /// hours are not tracked closely.
  static const allow = 'allow';

  /// Clocked out at closing time and labelled automatic. Never replaces a
  /// clock-out the person made themselves.
  static const auto = 'auto';

  static const all = [review, block, allow, auto];
}

/// A ready-made set of attendance settings for a kind of workplace. Picking
/// one writes its settings; each can still be changed on its own afterwards.
enum AttendanceMode {
  /// An owner working alone or with family: nothing is required.
  solo,

  /// Start the day and clock in to sell; leftovers at close wait for review.
  standard,

  /// As standard, but close day waits until everyone has clocked out.
  strict;

  /// The settings this mode sets.
  List<(Setting<Object>, Object)> get preset => switch (this) {
        AttendanceMode.solo => const [
            (AppSettings.startDayToSell, false),
            (AppSettings.clockInToSell, false),
            (AppSettings.closeWithOthersIn, CloseWithOthersIn.allow),
            (AppSettings.allowMissedClockOutEdit, true),
          ],
        AttendanceMode.standard => const [
            (AppSettings.startDayToSell, true),
            (AppSettings.clockInToSell, true),
            (AppSettings.closeWithOthersIn, CloseWithOthersIn.review),
            (AppSettings.allowMissedClockOutEdit, false),
          ],
        AttendanceMode.strict => const [
            (AppSettings.startDayToSell, true),
            (AppSettings.clockInToSell, true),
            (AppSettings.closeWithOthersIn, CloseWithOthersIn.block),
            (AppSettings.allowMissedClockOutEdit, false),
          ],
      };

  /// The mode whose settings match what the shop has now, or null when they
  /// were changed one by one (shown as "Custom").
  static AttendanceMode? current(T Function<T extends Object>(Setting<T>) get) {
    for (final mode in values) {
      if (mode.preset.every((p) => get(p.$1) == p.$2)) return mode;
    }
    return null;
  }
}
