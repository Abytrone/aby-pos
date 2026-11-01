import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/data/repositories/time_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Staff ama;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    ama = await r.staff.create(name: 'Ama', roleId: cashierRole.id, pin: '5678', by: owner);
  });
  tearDown(() => db.close());

  test('badges: made, scanned to find the person, removed', () async {
    final code = await r.staff.newBadge(ama.id, by: owner);
    expect(code, startsWith(StaffRepository.badgePrefix));
    expect(code.substring(StaffRepository.badgePrefix.length), matches(RegExp(r'^[a-z]{14}$')), reason: 'no digits for the PIN pad');
    expect((await r.staff.byBadge(code))?.id, ama.id);
    expect((await r.staff.byBadge(code.toUpperCase()))?.id, ama.id, reason: 'scanners in caps lock');
    expect(await r.staff.byBadge('ABY-STAFF:nothere'), isNull);
    expect((await r.staff.profile(ama.id))!.badgeCode, isNotNull);

    final again = await r.staff.newBadge(ama.id, by: owner);
    expect(await r.staff.byBadge(code), isNull, reason: 'a new badge replaces the old');
    await r.staff.removeBadge(ama.id, by: owner);
    expect(await r.staff.byBadge(again), isNull);
  });

  test('the time clock: breaks, late arrivals and early leaves', () async {
    var now = DateTime(2026, 10, 26, 8, 12);
    final times = TimeRepository(db, r.device, clock: () => now);
    await r.staff.setWorkHours(ama.id, start: 8 * 60, end: 17 * 60, by: owner);

    await times.clockIn(ama);
    await expectLater(times.clockIn(ama), throwsA(isA<TimeClockException>()));
    expect((await times.current(ama.id))!.since, now);
    now = DateTime(2026, 10, 26, 12, 0);
    await times.startBreak(ama);
    expect((await times.current(ama.id))!.onBreak, isTrue);
    now = DateTime(2026, 10, 26, 12, 40);
    await times.endBreak(ama);
    now = DateTime(2026, 10, 26, 16, 30);
    await times.clockOut(ama);
    expect(await times.current(ama.id), isNull);
    await expectLater(times.clockOut(ama), throwsA(isA<TimeClockException>()));

    final week = DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 10, 28));
    final sheet = await times.timesheet(week);
    final e = sheet.single;
    expect(e.breakMinutes, 40);
    expect(e.workedMinutes(), 8 * 60 + 18 - 40);
    expect(e.lateMinutes, 12);
    expect(e.earlyMinutes, 30);
    expect((await times.minutesWorked(week))[ama.id], 458);

    // Within the grace minutes: on time.
    now = DateTime(2026, 10, 27, 8, 4);
    await times.clockIn(ama);
    now = DateTime(2026, 10, 27, 17, 2);
    await times.clockOut(ama);
    final second = (await times.timesheet(week)).last;
    expect((second.lateMinutes, second.earlyMinutes), (0, 0));
  });

  test('out for lunch and back is neither late nor early; only the day\'s first and last stretch count', () async {
    var now = DateTime(2026, 10, 26, 8, 20);
    final times = TimeRepository(db, r.device, clock: () => now);
    await r.staff.setWorkHours(ama.id, start: 8 * 60, end: 17 * 60, by: owner);
    await times.clockIn(ama);
    now = DateTime(2026, 10, 26, 12, 0);
    await times.clockOut(ama);
    now = DateTime(2026, 10, 26, 13, 0);
    await times.clockIn(ama);
    now = DateTime(2026, 10, 26, 16, 0);
    await times.clockOut(ama);

    final sheet = await times.timesheet(DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 10, 28)));
    expect([for (final e in sheet) (e.lateMinutes, e.earlyMinutes)], [(20, 0), (0, 60)]);
  });

  test('night shifts: late and early either side of midnight', () async {
    var now = DateTime(2026, 10, 27, 0, 30);
    final times = TimeRepository(db, r.device, clock: () => now);
    await r.staff.setWorkHours(ama.id, start: 22 * 60, end: 6 * 60, by: owner);
    await times.clockIn(ama);
    now = DateTime(2026, 10, 27, 5, 0);
    await times.clockOut(ama);

    final e = (await times.timesheet(DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 10, 28)))).single;
    expect(e.lateMinutes, 150, reason: '00:30 is two and a half hours after 22:00');
    expect(e.earlyMinutes, 60);
    expect(TimeRepository.minutesPast(22 * 60, DateTime(2026, 1, 1, 21, 50)), -10);
    expect(TimeRepository.minutesPast(6 * 60, DateTime(2026, 1, 1, 23, 0)), -7 * 60);
  });

  test('a forgotten clock out is flagged, and a manager corrects it with a reason in the log', () async {
    var now = DateTime(2026, 10, 26, 8, 0);
    final times = TimeRepository(db, r.device, clock: () => now, audit: r.audit);
    await times.clockIn(ama);
    await times.startBreak(ama);
    now = DateTime(2026, 10, 27, 9, 0);

    final stale = (await times.stillIn()).single;
    expect(stale.tooLong(now), isTrue);
    expect(await times.stillIn(deviceId: 'another till'), isEmpty);

    Future<void> correct({DateTime? out, int breakMinutes = 30, String reason = 'Forgot to clock out'}) => times.correct(
          stale.id,
          clockIn: stale.clockIn,
          clockOut: out,
          breakMinutes: breakMinutes,
          reason: reason,
          by: owner,
        );
    await expectLater(correct(out: DateTime(2026, 10, 26, 17), reason: ' '), throwsA(isA<TimeClockException>()));
    await expectLater(correct(out: DateTime(2026, 10, 26, 7)), throwsA(isA<TimeClockException>()), reason: 'before clock in');
    await expectLater(correct(out: DateTime(2026, 10, 28)), throwsA(isA<TimeClockException>()), reason: 'in the future');
    await expectLater(correct(out: DateTime(2026, 10, 26, 9), breakMinutes: 90), throwsA(isA<TimeClockException>()));

    await correct(out: DateTime(2026, 10, 26, 17));
    expect(await times.current(ama.id), isNull, reason: 'clocked out, and the break that was going ended');
    final fixed = (await times.timesheet(DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 10, 28)))).single;
    expect(fixed.workedMinutes(now), 9 * 60 - 30);
    expect(fixed.tooLong(now), isFalse);
    expect(fixed.note, 'Forgot to clock out');
    final logged = (await r.audit.list()).firstWhere((a) => a.action == AuditAction.timeEntryCorrected);
    expect(logged.summary, contains('Forgot to clock out'));
    expect(AuditAction.timeEntryCorrected.isSensitive, isTrue);
    await expectLater(correct(), throwsA(isA<TimeClockException>()), reason: 'a finished stretch keeps a clock out');
  });

  test('a break still going is not worked time', () async {
    var now = DateTime(2026, 10, 26, 8, 0);
    final times = TimeRepository(db, r.device, clock: () => now);
    await times.clockIn(ama);
    now = DateTime(2026, 10, 26, 12, 0);
    await times.startBreak(ama);
    now = DateTime(2026, 10, 26, 12, 45);
    final e = (await times.stillIn()).single;
    expect(e.workedMinutes(now), 4 * 60);
  });

  test('the staff report: items, hours and commission', () async {
    final menu = await r.catalog.load();
    Product named(String n) => menu.products.firstWhere((p) => p.name == n);
    final waffle = named('Waffle');
    // Commission of GH₵ 1 per waffle.
    await db.customStatement('UPDATE products SET commission = 100 WHERE id = ?', [waffle.id]);
    await r.sales.completeSale(
      lines: [CartLine(product: waffle, quantity: 3), CartLine(product: named('Milkshake'))],
      payments: [const PaymentInput.cash(tendered: 10000)],
      cashier: ama,
    );
    final today = DateTime.now();
    final times = TimeRepository(db, r.device, clock: () => today.subtract(const Duration(hours: 2)));
    await times.clockIn(ama);
    final out = TimeRepository(db, r.device, clock: () => today.subtract(const Duration(minutes: 30)));
    await out.clockOut(ama);

    final month = DateRange.of(ReportPeriod.thisMonth, today);
    final perProduct = (await r.reports.staff(month, commission: const CommissionConfig(mode: CommissionMode.perProduct)))
        .firstWhere((s) => s.name == 'Ama');
    expect(perProduct.items, 4);
    expect(perProduct.commission, 300);
    expect(perProduct.minutesWorked, 90);
    expect(perProduct.average, 3600 + 2000);

    final percent = (await r.reports.staff(month, commission: const CommissionConfig(mode: CommissionMode.percent, percent: 5)))
        .firstWhere((s) => s.name == 'Ama');
    expect(percent.commission, 280, reason: '5% of GH₵ 56');
    final off = (await r.reports.staff(month)).firstWhere((s) => s.name == 'Ama');
    expect(off.commission, 0);
  });
}
