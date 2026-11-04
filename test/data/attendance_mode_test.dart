import 'package:aby_pos/app/core/attendance.dart';
import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/data/repositories/time_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late SettingsService settings;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
  });
  tearDown(() => db.close());

  Future<void> apply(AttendanceMode mode) async {
    for (final (setting, value) in mode.preset) {
      await settings.set(setting, value, by: owner);
    }
  }

  test('every mode is recognised after it is applied, and only that mode', () async {
    for (final mode in AttendanceMode.values) {
      await apply(mode);
      expect(AttendanceMode.current(settings.get), mode);
      for (final other in AttendanceMode.values.where((m) => m != mode)) {
        expect(other.preset.every((p) => settings.get(p.$1) == p.$2), isFalse, reason: '$mode looks like $other');
      }
    }
  });

  test('changing one setting on its own makes the mode custom', () async {
    await apply(AttendanceMode.standard);
    await settings.set(AppSettings.closeWithOthersIn, CloseWithOthersIn.block, by: owner);
    expect(AttendanceMode.current(settings.get), AttendanceMode.strict, reason: 'now matches strict');
    await settings.set(AppSettings.clockInToSell, false, by: owner);
    expect(AttendanceMode.current(settings.get), isNull);
  });

  test('a shop with no choices yet has the default close behaviour: review', () {
    expect(settings.get(AppSettings.closeWithOthersIn), CloseWithOthersIn.review);
    expect(CloseWithOthersIn.all, contains(settings.get(AppSettings.closeWithOthersIn)));
  });

  test('left open without review: paid up to the last activity, still labelled unconfirmed', () async {
    var now = DateTime(2026, 11, 2, 8, 0);
    final times = TimeRepository(db, r.device, clock: () => now, audit: r.audit);
    final ama = await r.staff.create(name: 'Ama', roleId: cashierRole.id, pin: '5678', by: owner);
    await times.clockIn(ama);
    now = DateTime(2026, 11, 2, 18, 0);
    await times.leaveOpenAtClose(by: owner, needsReview: false);

    final e = (await times.timesheet(DateRange.of(ReportPeriod.thisWeek, DateTime(2026, 11, 3)))).single;
    expect(e.closeSource, ClockOutSource.unconfirmed);
    expect(e.needsReview, isFalse);
    expect(await times.needingReview(), isEmpty);
    expect(e.payableMinutes(now), e.workedMinutes(now));
  });
}
