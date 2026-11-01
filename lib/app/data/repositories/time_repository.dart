import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/period.dart';
import '../../models/audit.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

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
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.clockIn,
    this.clockOut,
    this.breakMinutes = 0,
    this.breakStartedAt,
    this.lateMinutes = 0,
    this.earlyMinutes = 0,
    this.note,
  });

  final String id;
  final String staffId;
  final String staffName;
  final DateTime clockIn;

  /// Null while still clocked in.
  final DateTime? clockOut;

  /// Breaks that have ended, and the one going on now, if any.
  final int breakMinutes;
  final DateTime? breakStartedAt;

  /// Past the usual start (more than [TimeRepository.grace]) on the day's
  /// first stretch, or before the usual end on its last; 0 when on time or
  /// no usual hours are set.
  final int lateMinutes;
  final int earlyMinutes;

  /// Why a manager changed it, when one did.
  final String? note;

  bool get stillIn => clockOut == null;
  bool get edited => note != null;

  /// Minutes worked, breaks taken off (to now while still in, or on a
  /// break).
  int workedMinutes([DateTime? now]) {
    final at = now ?? clock.now();
    final end = clockOut ?? at;
    final onBreak = clockOut == null && breakStartedAt != null ? at.difference(breakStartedAt!).inMinutes : 0;
    final m = end.difference(clockIn).inMinutes - breakMinutes - onBreak;
    return m < 0 ? 0 : m;
  }

  /// Longer than anyone works in one go: most likely a forgotten clock out.
  bool tooLong([DateTime? now]) =>
      (clockOut ?? now ?? clock.now()).difference(clockIn) > TimeRepository.longestStretch;
}

DateTime _now() => clock.now();

/// Clocking in and out, with breaks (STF-04). Each stretch of work is one
/// entry; timesheets and hours are worked out from them. A manager can
/// correct an entry (a forgotten clock out), with a reason, in the audit log.
class TimeRepository {
  TimeRepository(this._db, this._device, {DateTime Function()? clock, this.audit}) : _clock = clock ?? _now;

  final AppDatabase _db;
  final DeviceInfo _device;
  final DateTime Function() _clock;
  final AuditRepository? audit;

  /// Minutes of leeway before arriving counts as late (or leaving as early).
  static const grace = 5;

  /// A stretch longer than this is flagged on the timesheet.
  static const longestStretch = Duration(hours: 16);

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

  /// Corrects a stretch: when it started and ended, and its breaks. Giving a
  /// [clockOut] to a stretch still open clocks the person out (a forgotten
  /// clock out). [reason] is kept on the entry and in the audit log.
  Future<void> correct(
    String entryId, {
    required DateTime clockIn,
    required DateTime? clockOut,
    required int breakMinutes,
    required String reason,
    required Staff by,
    Staff? approver,
  }) async {
    final r = await (_db.select(_db.timeEntries)..where((t) => t.id.equals(entryId))).getSingle();
    final now = _clock();
    if (reason.trim().isEmpty) throw const TimeClockException('Give a reason for the change.');
    if (clockIn.isAfter(now) || (clockOut?.isAfter(now) ?? false)) {
      throw const TimeClockException('Times cannot be in the future.');
    }
    if (r.clockOut != null && clockOut == null) {
      throw const TimeClockException('A finished stretch needs a clock out time.');
    }
    if (clockOut != null && !clockOut.isAfter(clockIn)) {
      throw const TimeClockException('Clock out must be after clock in.');
    }
    if (breakMinutes < 0 || breakMinutes > (clockOut ?? now).difference(clockIn).inMinutes) {
      throw const TimeClockException('The break is longer than the time worked.');
    }
    String hm(DateTime? d) => d == null ? 'still in' : d.toIso8601String().substring(0, 16).replaceFirst('T', ' ');
    await _db.transaction(() async {
      await _db.updateTracked(
        _db.timeEntries,
        r.copyWith(
          clockIn: clockIn,
          clockOut: Value(clockOut),
          breakMinutes: breakMinutes,
          // Clocked out by the correction: a break still going ends with it.
          breakStartedAt: clockOut == null ? Value(r.breakStartedAt) : const Value(null),
          note: Value(reason.trim()),
          updatedAt: now,
        ),
      );
      await audit?.record(
        action: AuditAction.timeEntryCorrected,
        actor: by,
        approver: approver,
        entity: 'time_entries',
        entityId: r.id,
        summary: 'Corrected the hours of ${r.staffName}: ${hm(clockIn)} to ${hm(clockOut)}, '
            '$breakMinutes min break (${reason.trim()})',
        details: {
          'before': {'in': hm(r.clockIn), 'out': hm(r.clockOut), 'break': r.breakMinutes},
          'after': {'in': hm(clockIn), 'out': hm(clockOut), 'break': breakMinutes},
        },
      );
    });
  }

  /// People still clocked in, oldest first; only those who clocked in on
  /// [deviceId] when given.
  Future<List<TimesheetEntry>> stillIn({String? deviceId}) async {
    final rows = await (_db.select(_db.timeEntries)
          ..where((t) =>
              t.clockOut.isNull() & t.deletedAt.isNull() & (deviceId == null ? const Constant(true) : t.deviceId.equals(deviceId)))
          ..orderBy([(t) => OrderingTerm(expression: t.clockIn)]))
        .get();
    return [for (final r in rows) _entry(r)];
  }

  TimesheetEntry _entry(TimeEntryRow r, {int late = 0, int early = 0}) => TimesheetEntry(
        id: r.id,
        staffId: r.staffId,
        staffName: r.staffName,
        clockIn: r.clockIn,
        clockOut: r.clockOut,
        breakMinutes: r.breakMinutes,
        breakStartedAt: r.breakStartedAt,
        lateMinutes: late,
        earlyMinutes: early,
        note: r.note,
      );

  /// Entries that started in [range], oldest first, with late and early
  /// worked out from each person's usual hours: late on the first stretch
  /// of a person's day, early on the last (lunch out and back in is
  /// neither).
  Future<List<TimesheetEntry>> timesheet(DateRange range) async {
    final rows = await (_db.select(_db.timeEntries)
          ..where((t) =>
              t.deletedAt.isNull() & t.clockIn.isBiggerOrEqualValue(range.from) & t.clockIn.isSmallerThanValue(range.to))
          ..orderBy([(t) => OrderingTerm(expression: t.clockIn), (t) => OrderingTerm(expression: t.id)]))
        .get();
    final hours = {
      for (final s in await _db.select(_db.staffMembers).get()) s.id: (s.workStart, s.workEnd),
    };
    String day(TimeEntryRow r) => '${r.staffId} ${r.clockIn.year}-${r.clockIn.month}-${r.clockIn.day}';
    final first = <String, String>{}, last = <String, String>{};
    for (final r in rows) {
      first.putIfAbsent(day(r), () => r.id);
      last[day(r)] = r.id;
    }
    return [
      for (final r in rows)
        () {
          final (start, end) = hours[r.staffId] ?? (null, null);
          final out = r.clockOut;
          final late = start == null || first[day(r)] != r.id ? 0 : minutesPast(start, r.clockIn);
          final early = end == null || out == null || last[day(r)] != r.id ? 0 : -minutesPast(end, out);
          return _entry(r, late: late > grace ? late : 0, early: early > grace ? early : 0);
        }(),
    ];
  }

  /// Minutes [at] is after [minuteOfDay] (negative when before), taking the
  /// nearer side of midnight, so 00:30 is 150 minutes past a 22:00 start.
  static int minutesPast(int minuteOfDay, DateTime at) {
    final d = (at.hour * 60 + at.minute - minuteOfDay) % (24 * 60);
    return d >= 12 * 60 ? d - 24 * 60 : d;
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
