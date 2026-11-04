import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/domain/documents/report_docs.dart';
import 'package:aby_pos/app/data/repositories/time_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Attendance accountability: only the person clocks out; a day close can only
/// leave them open, for an owner to decide.
void main() {
  late AppDatabase db;
  late Repos r;
  late Staff ama;
  late Staff kofi;
  late TimeRepository times;
  var now = DateTime(2026, 11, 2, 8, 0);

  final week = DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 11, 3));

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    ama = await r.staff.create(name: 'Ama', roleId: cashierRole.id, pin: '5678', by: owner);
    kofi = await r.staff.create(name: 'Kofi', roleId: cashierRole.id, pin: '4321', by: owner);
    now = DateTime(2026, 11, 2, 8, 0);
    times = TimeRepository(db, r.device, clock: () => now, audit: r.audit);
  });
  tearDown(() => db.close());

  test('clocking out is recorded as the person\'s own', () async {
    await times.clockIn(ama);
    now = DateTime(2026, 11, 2, 16, 0);
    await times.clockOut(ama);
    final e = (await times.timesheet(week)).single;
    expect(e.closeSource, ClockOutSource.self);
    expect(e.review, TimeReview.ok);
    expect(e.payableMinutes(now), 480);
  });

  test('closing the day leaves people open: not clocked out, flagged, and out of pay', () async {
    await times.clockIn(ama);
    await times.clockIn(kofi);
    now = DateTime(2026, 11, 2, 12, 0);
    await times.clockOut(kofi);
    now = DateTime(2026, 11, 2, 18, 0);

    final left = await times.leaveOpenAtClose(by: owner, closeId: 'close-1');
    expect(left.map((e) => e.staffName), ['Ama'], reason: 'Kofi clocked himself out');

    final amaEntry = (await times.timesheet(week)).firstWhere((e) => e.staffName == 'Ama');
    expect(amaEntry.clockOut, isNull, reason: 'nobody writes a clock out for her');
    expect(amaEntry.closeSource, ClockOutSource.unconfirmed);
    expect(amaEntry.needsReview, isTrue);
    expect(amaEntry.stillIn, isFalse);
    expect(amaEntry.leftOpenByName, owner.name);
    expect(amaEntry.payableMinutes(now), 0);

    final minutes = await times.minutesWorked(week);
    expect(minutes[ama.id] ?? 0, 0, reason: 'unconfirmed hours are not paid');
    expect(minutes[kofi.id], 240);

    expect(await times.current(ama.id), isNull, reason: 'she can clock in again tomorrow');
    expect((await times.needingReview()).single.staffName, 'Ama');
    expect(await times.stillIn(), isEmpty);

    final log = await r.audit.list();
    expect(log.where((a) => a.action == AuditAction.timeEntryLeftOpen), hasLength(1));
  });

  test('the last sale on this till is kept as evidence, not as the clock out', () async {
    final waffle = (await r.catalog.products()).firstWhere((p) => p.name == 'Waffle');
    await times.clockIn(ama);
    await withClock(Clock.fixed(DateTime(2026, 11, 2, 16, 52)), () async {
      await r.sales.completeSale(
        lines: [CartLine(product: waffle, quantity: 1)],
        payment: PaymentInput.cash(tendered: 5000),
        cashier: ama,
      );
    });
    now = DateTime(2026, 11, 2, 19, 0);
    await times.leaveOpenAtClose(by: owner);

    final e = (await times.needingReview()).single;
    expect(e.lastActivityAt, DateTime(2026, 11, 2, 16, 52));
    expect(e.clockOut, isNull);
    expect(e.workedMinutes(now), 8 * 60 + 52, reason: 'a guide for the owner, up to the last sale');
    expect(e.payableMinutes(now), 0);
  });

  test('an owner decides: approve some minutes, refuse, or correct the real time', () async {
    await times.clockIn(ama);
    await times.clockIn(kofi);
    now = DateTime(2026, 11, 2, 18, 0);
    await times.leaveOpenAtClose(by: owner);
    final waiting = await times.needingReview();
    final amaId = waiting.firstWhere((e) => e.staffName == 'Ama').id;
    final kofiId = waiting.firstWhere((e) => e.staffName == 'Kofi').id;

    await expectLater(
      times.review(amaId, minutes: 300, reason: '  ', by: owner),
      throwsA(isA<TimeClockException>()),
      reason: 'a reason is required',
    );
    await times.review(amaId, minutes: 300, reason: 'Manager confirmed she left at 1pm', by: owner);
    await times.correct(
      kofiId,
      clockIn: DateTime(2026, 11, 2, 8, 0),
      clockOut: DateTime(2026, 11, 2, 14, 0),
      breakMinutes: 0,
      reason: 'Left early, told the owner',
      by: owner,
    );

    expect(await times.needingReview(), isEmpty);
    final sheet = await times.timesheet(week);
    final a = sheet.firstWhere((e) => e.staffName == 'Ama');
    expect(a.review, TimeReview.approved);
    expect(a.approvedByName, owner.name);
    expect(a.payableMinutes(now), 300);
    final k = sheet.firstWhere((e) => e.staffName == 'Kofi');
    expect(k.closeSource, ClockOutSource.corrected);
    expect(k.review, TimeReview.approved);
    expect(k.approvedByName, owner.name);
    expect(k.payableMinutes(now), 360);

    await expectLater(
      times.review(amaId, minutes: 0, reason: 'again', by: owner),
      throwsA(isA<TimeClockException>()),
      reason: 'decided already',
    );
    final log = await r.audit.list();
    expect(log.where((a) => a.action == AuditAction.timeEntryReviewed), hasLength(1));
    expect(log.where((a) => a.action == AuditAction.timeEntryCorrected), hasLength(1));
  });

  test('refusing unconfirmed hours pays nothing and keeps the record', () async {
    await times.clockIn(ama);
    now = DateTime(2026, 11, 2, 18, 0);
    await times.leaveOpenAtClose(by: owner);
    final id = (await times.needingReview()).single.id;
    await times.review(id, minutes: 0, reason: 'Left without telling anyone', by: owner);
    final e = (await times.timesheet(week)).single;
    expect(e.payableMinutes(now), 0);
    expect(e.approvalNote, 'Left without telling anyone');
    expect(e.review, TimeReview.approved);
  });

  test('the exported timesheet pays only what counts, and says how each stretch ended', () async {
    await times.clockIn(ama);
    await times.clockIn(kofi);
    now = DateTime(2026, 11, 2, 16, 0);
    await times.clockOut(kofi);
    now = DateTime(2026, 11, 2, 18, 0);
    await times.leaveOpenAtClose(by: owner);

    final range = week;
    final doc = ReportDocs.timesheet(await times.timesheet(range), shopName: 'Shop', range: range, now: now);
    final rows = {for (final row in doc.sheets.single.rows) row[0] as String: row};
    expect(rows['Kofi']![4], 480);
    expect(rows['Kofi']![7], '');
    expect(rows['Ama']![4], 0, reason: 'unconfirmed hours are not in the pay column');
    expect(rows['Ama']![7], contains('not confirmed'));
    expect(rows['Ama']![7], contains('Not paid until reviewed'));
  });
}
