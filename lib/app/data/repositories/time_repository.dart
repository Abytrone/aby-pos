import 'package:drift/drift.dart';

import '../../core/period.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';

class TimeClockException implements Exception {
  const TimeClockException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Someone clocked in now.
class ClockedIn {
  const ClockedIn({required this.entryId, required this.since, this.onBreakSince, this.breakMinutes = 0});

  final String entryId;
  final DateTime since;
  final DateTime? onBreakSince;
  final int breakMinutes;

  bool get onBreak => onBreakSince != null;
}

/// One stretch of work on a timesheet.
class TimesheetEntry {
  const TimesheetEntry({
    required this.staffId,
    required this.staffName,
    required this.clockIn,
    this.clockOut,
    this.breakMinutes = 0,
    this.lateMinutes = 0,
    this.earlyMinutes = 0,
  });

  final String staffId;
  final String staffName;
  final DateTime clockIn;

  /// Null while still clocked in.
  final DateTime? clockOut;
  final int breakMinutes;

  /// Past the usual start (more than [TimeRepository.grace]), or before the
  /// usual end; 0 when on time or no usual hours are set.
  final int lateMinutes;
  final int earlyMinutes;

  /// Minutes worked, breaks taken off (to now while still in).
  int workedMinutes([DateTime? now]) {
    final end = clockOut ?? now ?? DateTime.now();
    final m = end.difference(clockIn).inMinutes - breakMinutes;
    return m < 0 ? 0 : m;
  }
}

/// Clocking in and out, with breaks (STF-04). Each stretch of work is one
/// entry; timesheets and hours are worked out from them.
class TimeRepository {
  TimeRepository(this._db, this._device, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final DeviceInfo _device;
  final DateTime Function() _clock;

  /// Minutes of leeway before arriving counts as late (or leaving as early).
  static const grace = 5;

  Future<TimeEntryRow?> _open(String staffId) => (_db.select(_db.timeEntries)
        ..where((t) => t.staffId.equals(staffId) & t.clockOut.isNull() & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.clockIn)])
        ..limit(1))
      .getSingleOrNull();

  Future<ClockedIn?> current(String staffId) async {
    final r = await _open(staffId);
    return r == null
        ? null
        : ClockedIn(entryId: r.id, since: r.clockIn, onBreakSince: r.breakStartedAt, breakMinutes: r.breakMinutes);
  }

  Future<void> clockIn(Staff staff) async {
    if (await _open(staff.id) != null) throw TimeClockException('${staff.name} is already clocked in.');
    final now = _clock();
    await _db.insertTracked(
      _db.timeEntries,
      TimeEntriesCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        staffId: staff.id,
        staffName: staff.name,
        clockIn: now,
      ),
    );
  }

  /// Ends a break that is still going, then clocks out.
  Future<void> clockOut(Staff staff) async {
    final r = await _open(staff.id);
    if (r == null) throw TimeClockException('${staff.name} is not clocked in.');
    final now = _clock();
    final onBreak = r.breakStartedAt == null ? 0 : now.difference(r.breakStartedAt!).inMinutes;
    await _db.updateTracked(
      _db.timeEntries,
      r.copyWith(clockOut: Value(now), breakMinutes: r.breakMinutes + onBreak, breakStartedAt: const Value(null), updatedAt: now),
    );
  }

  Future<void> startBreak(Staff staff) async {
    final r = await _open(staff.id);
    if (r == null) throw TimeClockException('${staff.name} is not clocked in.');
    if (r.breakStartedAt != null) return;
    final now = _clock();
    await _db.updateTracked(_db.timeEntries, r.copyWith(breakStartedAt: Value(now), updatedAt: now));
  }

  Future<void> endBreak(Staff staff) async {
    final r = await _open(staff.id);
    if (r == null || r.breakStartedAt == null) return;
    final now = _clock();
    await _db.updateTracked(
      _db.timeEntries,
      r.copyWith(breakMinutes: r.breakMinutes + now.difference(r.breakStartedAt!).inMinutes, breakStartedAt: const Value(null), updatedAt: now),
    );
  }

  /// Entries that started in [range], oldest first, with late and early
  /// worked out from each person's usual hours.
  Future<List<TimesheetEntry>> timesheet(DateRange range) async {
    final rows = await (_db.select(_db.timeEntries)
          ..where((t) =>
              t.deletedAt.isNull() & t.clockIn.isBiggerOrEqualValue(range.from) & t.clockIn.isSmallerThanValue(range.to))
          ..orderBy([(t) => OrderingTerm(expression: t.clockIn), (t) => OrderingTerm(expression: t.id)]))
        .get();
    final hours = {
      for (final s in await _db.select(_db.staffMembers).get()) s.id: (s.workStart, s.workEnd),
    };
    int minutesOfDay(DateTime d) => d.hour * 60 + d.minute;
    return [
      for (final r in rows)
        () {
          final (start, end) = hours[r.staffId] ?? (null, null);
          final late = start == null ? 0 : minutesOfDay(r.clockIn) - start;
          final out = r.clockOut;
          final early = end == null || out == null ? 0 : end - minutesOfDay(out);
          return TimesheetEntry(
            staffId: r.staffId,
            staffName: r.staffName,
            clockIn: r.clockIn,
            clockOut: out,
            breakMinutes: r.breakMinutes,
            lateMinutes: late > grace ? late : 0,
            earlyMinutes: early > grace ? early : 0,
          );
        }(),
    ];
  }

  /// Minutes worked per person in [range].
  Future<Map<String, int>> minutesWorked(DateRange range) async {
    final out = <String, int>{};
    final now = _clock();
    for (final e in await timesheet(range)) {
      out[e.staffId] = (out[e.staffId] ?? 0) + e.workedMinutes(now);
    }
    return out;
  }
}
