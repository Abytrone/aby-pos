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
