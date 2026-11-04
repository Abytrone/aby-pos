import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/period.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
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

  bool missedClockOut([DateTime? now]) => _crossedCalendarDay(since, now ?? clock.now());
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
    this.closeSource,
    this.review = TimeReview.ok,
    this.lastActivityAt,
    this.leftOpenByName,
    this.approvedByName,
    this.approvedMinutes,
    this.approvalNote,
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

  /// Who ended it; null while it is open.
  final ClockOutSource? closeSource;
  final TimeReview review;

  /// For a stretch left open at close: the person's last sale or refund on
  /// that till. Evidence for the owner, never written as their clock out.
  final DateTime? lastActivityAt;
  final String? leftOpenByName;

  /// The owner's decision on a stretch that needed review.
  final String? approvedByName;
  final int? approvedMinutes;
  final String? approvalNote;

  /// Still clocked in: open, and not left open by a day close.
  bool get stillIn => clockOut == null && !unconfirmed;

  /// The day closed with this person still in and no clock out of their own.
  bool get unconfirmed => closeSource == ClockOutSource.unconfirmed;
  bool get needsReview => review == TimeReview.needsReview;
  bool get edited => note != null;

  /// The stretch is still open after its clock-in calendar day.
  bool missedClockOut([DateTime? now]) => stillIn && _crossedCalendarDay(clockIn, now ?? clock.now());

  /// Minutes worked, breaks taken off (to now while still in, or on a
  /// break). An unconfirmed stretch runs to the person's last activity, which
  /// is only a guide: see [payableMinutes] for what counts for pay.
  int workedMinutes([DateTime? now]) {
    final at = now ?? clock.now();
    final end = clockOut ?? (unconfirmed ? (lastActivityAt ?? clockIn) : at);
    final onBreak =
        clockOut == null && !unconfirmed && breakStartedAt != null ? at.difference(breakStartedAt!).inMinutes : 0;
    final m = end.difference(clockIn).inMinutes - breakMinutes - onBreak;
    return m < 0 ? 0 : m;
  }

  /// Minutes that count for pay. Waiting for review: none. Decided by an
  /// owner: the minutes they approved (0 when refused), else the worked time.
  int payableMinutes([DateTime? now]) {
    if (needsReview) return 0;
    if (review == TimeReview.approved && approvedMinutes != null) return approvedMinutes!;
    return workedMinutes(now);
  }

  /// How this stretch ended and was decided, in words, for exports. Empty
  /// for an ordinary stretch the person clocked out of themselves.
  String get statusNote => [
        if (stillIn) 'Still clocked in',
        if (unconfirmed) 'Left clocked in at close, not confirmed',
        if (closeSource == ClockOutSource.auto) 'Clocked out automatically at close',
        if (needsReview) 'Not paid until reviewed',
        if (review == TimeReview.approved && approvedByName != null)
          'Decided by $approvedByName${approvalNote == null ? '' : ': $approvalNote'}',
        if (note != null) 'Corrected: $note',
      ].join('; ');

  /// Longer than anyone works in one go: most likely a forgotten clock out.
  bool tooLong([DateTime? now]) =>
      !unconfirmed && (clockOut ?? now ?? clock.now()).difference(clockIn) > TimeRepository.longestStretch;
}

DateTime _now() => clock.now();

bool _crossedCalendarDay(DateTime start, DateTime end) {
  final localStart = start.toLocal();
  final localEnd = end.toLocal();
  return DateTime(localEnd.year, localEnd.month, localEnd.day)
      .isAfter(DateTime(localStart.year, localStart.month, localStart.day));
}

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
        ..where((t) => t.staffId.equals(staffId) & t.clockOut.isNull() & t.closeSource.isNull() & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.clockIn)])
        ..limit(1))
      .getSingleOrNull();

  Future<ClockedIn?> current(String staffId) async {
    final r = await _open(staffId);
    return r == null
        ? null
        : ClockedIn(entryId: r.id, since: r.clockIn, onBreakSince: r.breakStartedAt, breakMinutes: r.breakMinutes);
  }

  /// The signed-in person's open stretch, including the fields used to
  /// correct a forgotten clock out.
  Future<TimesheetEntry?> currentEntry(String staffId) async {
    final r = await _open(staffId);
    return r == null ? null : _entry(r);
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
      r.copyWith(clockOut: Value(now), closeSource: const Value(ClockOutSource.self), breakMinutes: r.breakMinutes + onBreak, breakStartedAt: const Value(null), updatedAt: now),
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
    // Setting the end of a stretch left open decides it: the corrected times
    // count, and who decided and why is on the entry.
    final decides = r.reviewStatus == TimeReview.needsReview && clockOut != null;
    await _db.transaction(() async {
      await _db.updateTracked(
        _db.timeEntries,
        r.copyWith(
          clockIn: clockIn,
          clockOut: Value(clockOut),
          closeSource: clockOut == null ? Value(r.closeSource) : const Value(ClockOutSource.corrected),
          reviewStatus: decides ? TimeReview.approved : r.reviewStatus,
          approvedById: decides ? Value((approver ?? by).id) : Value(r.approvedById),
          approvedByName: decides ? Value((approver ?? by).name) : Value(r.approvedByName),
          approvedAt: decides ? Value(now) : Value(r.approvedAt),
          approvedMinutes: decides ? const Value(null) : Value(r.approvedMinutes),
          approvalNote: decides ? Value(reason.trim()) : Value(r.approvalNote),
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
              t.clockOut.isNull() & t.closeSource.isNull() & t.deletedAt.isNull() & (deviceId == null ? const Constant(true) : t.deviceId.equals(deviceId)))
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
        closeSource: r.closeSource,
        review: r.reviewStatus,
        lastActivityAt: r.lastActivityAt,
        leftOpenByName: r.leftOpenByName,
        approvedByName: r.approvedByName,
        approvedMinutes: r.approvedMinutes,
        approvalNote: r.approvalNote,
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

  /// Minutes that count for pay per person in [range]: stretches waiting for
  /// an owner's review are left out until decided.
  Future<Map<String, int>> minutesWorked(DateRange range) async {
    final out = <String, int>{};
    final now = _clock();
    for (final e in await timesheet(range)) {
      out[e.staffId] = (out[e.staffId] ?? 0) + e.payableMinutes(now);
    }
    return out;
  }

  /// Stretches waiting for an owner's decision, oldest first.
  Future<List<TimesheetEntry>> needingReview() async {
    final rows = await (_db.select(_db.timeEntries)
          ..where((t) => t.reviewStatus.equalsValue(TimeReview.needsReview) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.clockIn)]))
        .get();
    return [for (final r in rows) _entry(r)];
  }

  /// Day close: the people still in on this till are left open, not clocked
  /// out. Each stretch is marked unconfirmed and waits for an owner, with the
  /// person's last sale or refund on this till kept as evidence. Their pay
  /// for it stays out until [review] decides. With [needsReview] false (shops
  /// that do not track hours closely) it is left open without review and is
  /// paid up to that last activity. Returns who was left open. Run it inside
  /// close day's transaction.
  Future<List<TimesheetEntry>> leaveOpenAtClose({
    required Staff by,
    String? closeId,
    Iterable<String>? onlyEntryIds,
    bool needsReview = true,
  }) async {
    final now = _clock();
    final left = <TimesheetEntry>[];
    await _db.transaction(() async {
      final rows = await (_db.select(_db.timeEntries)
            ..where((t) =>
                t.clockOut.isNull() &
                t.closeSource.isNull() &
                t.deletedAt.isNull() &
                t.deviceId.equals(_device.deviceId)))
          .get();
      for (final r in rows) {
        if (onlyEntryIds != null && !onlyEntryIds.contains(r.id)) continue;
        final evidence = await _lastActivity(r.staffId, since: r.clockIn);
        final updated = r.copyWith(
          closeSource: const Value(ClockOutSource.unconfirmed),
          reviewStatus: needsReview ? TimeReview.needsReview : TimeReview.ok,
          lastActivityAt: Value(evidence),
          leftOpenById: Value(by.id),
          leftOpenByName: Value(by.name),
          dayCloseId: Value(closeId),
          updatedAt: now,
        );
        await _db.updateTracked(_db.timeEntries, updated);
        await audit?.record(
          action: AuditAction.timeEntryLeftOpen,
          actor: by,
          entity: 'time_entries',
          entityId: r.id,
          summary: '${r.staffName} was still clocked in when the day closed '
              '(last activity ${evidence == null ? 'none' : _fmt(evidence)})',
          details: {'in': _fmt(r.clockIn), 'lastActivity': evidence == null ? null : _fmt(evidence)},
        );
        left.add(_entry(updated));
      }
    });
    return left;
  }

  /// Shops that choose it: everyone still in on this till is clocked out at
  /// the closing time, recorded as automatic (never as their own clock out)
  /// and audited. Run it inside close day's transaction.
  Future<List<TimesheetEntry>> clockOutAtClose({required Staff by, String? closeId}) async {
    final now = _clock();
    final out = <TimesheetEntry>[];
    await _db.transaction(() async {
      final rows = await (_db.select(_db.timeEntries)
            ..where((t) =>
                t.clockOut.isNull() &
                t.closeSource.isNull() &
                t.deletedAt.isNull() &
                t.deviceId.equals(_device.deviceId)))
          .get();
      for (final r in rows) {
        final onBreak = r.breakStartedAt == null ? 0 : now.difference(r.breakStartedAt!).inMinutes;
        final updated = r.copyWith(
          clockOut: Value(now),
          closeSource: const Value(ClockOutSource.auto),
          breakMinutes: r.breakMinutes + onBreak,
          breakStartedAt: const Value(null),
          leftOpenById: Value(by.id),
          leftOpenByName: Value(by.name),
          dayCloseId: Value(closeId),
          updatedAt: now,
        );
        await _db.updateTracked(_db.timeEntries, updated);
        await audit?.record(
          action: AuditAction.timeEntryAutoClockOut,
          actor: by,
          entity: 'time_entries',
          entityId: r.id,
          summary: '${r.staffName} was clocked out automatically when the day closed (${_fmt(now)})',
          details: {'in': _fmt(r.clockIn), 'out': _fmt(now)},
        );
        out.add(_entry(updated));
      }
    });
    return out;
  }

  /// The owner's decision on an unconfirmed stretch: how many minutes count
  /// for pay (0 refuses it), and why. The times themselves are not changed;
  /// to set when the person really left, use [correct].
  Future<void> review(
    String entryId, {
    required int minutes,
    required String reason,
    required Staff by,
    Staff? approver,
  }) async {
    final r = await (_db.select(_db.timeEntries)..where((t) => t.id.equals(entryId))).getSingle();
    if (r.reviewStatus != TimeReview.needsReview) {
      throw const TimeClockException('This stretch is not waiting for review.');
    }
    if (reason.trim().isEmpty) throw const TimeClockException('Give a reason for the decision.');
    if (minutes < 0) throw const TimeClockException('Minutes cannot be negative.');
    final now = _clock();
    final decider = approver ?? by;
    await _db.transaction(() async {
      await _db.updateTracked(
        _db.timeEntries,
        r.copyWith(
          reviewStatus: TimeReview.approved,
          approvedById: Value(decider.id),
          approvedByName: Value(decider.name),
          approvedAt: Value(now),
          approvedMinutes: Value(minutes),
          approvalNote: Value(reason.trim()),
          updatedAt: now,
        ),
      );
      await audit?.record(
        action: AuditAction.timeEntryReviewed,
        actor: by,
        approver: approver,
        entity: 'time_entries',
        entityId: r.id,
        summary: '${minutes == 0 ? 'Refused' : 'Approved $minutes min of'} the unconfirmed hours of ${r.staffName} '
            '(${reason.trim()})',
        details: {'in': _fmt(r.clockIn), 'minutes': minutes},
      );
    });
  }

  /// The person's last sale or refund on this till since [since].
  Future<DateTime?> _lastActivity(String staffId, {required DateTime since}) async {
    final row = await _db.customSelect(
      'SELECT MAX(at) AS at FROM ('
      'SELECT created_at AS at FROM sales WHERE cashier_id = ?1 AND device_id = ?2 AND created_at >= ?3 AND deleted_at IS NULL '
      'UNION ALL '
      'SELECT created_at AS at FROM refunds WHERE staff_id = ?1 AND device_id = ?2 AND created_at >= ?3 AND deleted_at IS NULL)',
      variables: [Variable.withString(staffId), Variable.withString(_device.deviceId), Variable.withDateTime(since)],
      readsFrom: {_db.sales, _db.refunds},
    ).getSingle();
    return row.readNullable<DateTime>('at');
  }

  static String _fmt(DateTime d) => d.toIso8601String().substring(0, 16).replaceFirst('T', ' ');
}
