import 'package:intl/intl.dart';

import 'l10n.dart';

/// "just now", "5 minutes ago", "3 hours ago", "2 days ago".
String relativeTime(AppLocalizations l, DateTime at, {DateTime? now}) {
  final gone = (now ?? DateTime.now()).difference(at);
  if (gone.inMinutes < 1) return l.timeJustNow;
  if (gone.inHours < 1) return l.timeMinutesAgo(gone.inMinutes);
  if (gone.inDays < 1) return l.timeHoursAgo(gone.inHours);
  return l.timeDaysAgo(gone.inDays);
}

/// "23 Oct 2026, 14:05" in the app's locale.
String formatDateTime(DateTime at, {String? locale}) =>
    DateFormat('d MMM y, HH:mm', locale).format(at.toLocal());

String formatDate(DateTime at, {String? locale}) => DateFormat('d MMM y', locale).format(at.toLocal());

String formatTime(DateTime at, {String? locale}) => DateFormat('HH:mm', locale).format(at.toLocal());

/// "05:00" from minutes after midnight.
String formatMinutesOfDay(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
