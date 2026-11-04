import 'package:aby_pos/app/core/attendance.dart';
import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/day_close_repository.dart';
import 'package:aby_pos/app/data/repositories/time_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// What close day does with people still clocked in, for each shop setting.
void main() {
  late AppDatabase db;
  late Repos r;
  late Staff ama;
  late Staff kofi;
  late TimeRepository times;
  late DayCloseRepository closes;
  var now = DateTime(2026, 11, 2, 8, 0);

  final week = DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 11, 3));

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    ama = await r.staff.create(name: 'Ama', roleId: cashierRole.id, pin: '5678', by: owner);
    kofi = await r.staff.create(name: 'Kofi', roleId: cashierRole.id, pin: '4321', by: owner);
    now = DateTime(2026, 11, 2, 8, 0);
    times = TimeRepository(db, r.device, clock: () => now, audit: r.audit);
    closes = DayCloseRepository(db, r.device, r.audit, r.cashEvents, r.customers, r.shifts, times);
    await times.clockIn(ama);
    await times.clockIn(kofi);
    now = DateTime(2026, 11, 2, 12, 0);
    await times.clockOut(kofi); // Kofi clocks himself out; Ama does not.
    now = DateTime(2026, 11, 2, 18, 0);
  });
  tearDown(() => db.close());

  Future<void> close(String mode) =>
      closes.closeDay(openingFloat: 0, countedCash: 0, closedBy: owner, attendance: mode);

  Future<TimesheetEntry> amaEntry() async => (await times.timesheet(week)).firstWhere((e) => e.staffName == 'Ama');

  test('review (the default): left open, flagged, not paid, and tied to the close', () async {
    await close(CloseWithOthersIn.review);
    final e = await amaEntry();
    expect(e.clockOut, isNull, reason: 'the closer never writes a clock out for her');
    expect(e.closeSource, ClockOutSource.unconfirmed);
    expect(e.needsReview, isTrue);
    expect(e.payableMinutes(now), 0);
    expect(e.leftOpenByName, owner.name);
    final row = await (db.select(db.timeEntries)..where((t) => t.id.equals(e.id))).getSingle();
    expect(row.dayCloseId, isNotNull);
    expect(row.dayCloseId, (await closes.history()).single.id);
    // Kofi's own clock out is untouched.
    final k = (await times.timesheet(week)).firstWhere((x) => x.staffName == 'Kofi');
    expect(k.closeSource, ClockOutSource.self);
  });

  test('allow: left open without review', () async {
    await close(CloseWithOthersIn.allow);
    final e = await amaEntry();
    expect(e.closeSource, ClockOutSource.unconfirmed);
    expect(e.needsReview, isFalse);
    expect(await times.needingReview(), isEmpty);
  });

  test('auto: clocked out at the closing time and labelled automatic, not as her own', () async {
    await close(CloseWithOthersIn.auto);
    final e = await amaEntry();
    expect(e.clockOut, now);
    expect(e.closeSource, ClockOutSource.auto);
    expect(e.review, TimeReview.ok);
    expect(e.leftOpenByName, owner.name, reason: 'who closed the day is recorded');
    expect(await times.current(ama.id), isNull);
  });

  test('block: close day is refused while someone is still in, and nothing changes', () async {
    await expectLater(close(CloseWithOthersIn.block), throwsA(isA<TimeClockException>()));
    expect(await closes.history(), isEmpty, reason: 'the whole close rolled back');
    expect((await amaEntry()).stillIn, isTrue);

    // She clocks out herself, then the day can close.
    await times.clockOut(ama);
    await close(CloseWithOthersIn.block);
    expect(await closes.history(), hasLength(1));
    expect((await amaEntry()).closeSource, ClockOutSource.self);
  });

  test('block: a manager correcting her hours with a reason also clears the way', () async {
    final id = (await amaEntry()).id;
    await times.correct(
      id,
      clockIn: DateTime(2026, 11, 2, 8, 0),
      clockOut: DateTime(2026, 11, 2, 16, 0),
      breakMinutes: 0,
      reason: 'Left at 4, told the manager',
      by: owner,
    );
    await close(CloseWithOthersIn.block);
    final e = await amaEntry();
    expect(e.closeSource, ClockOutSource.corrected);
    expect(e.note, 'Left at 4, told the manager');
  });
}
