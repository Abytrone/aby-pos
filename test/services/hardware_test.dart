import 'dart:typed_data';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/parked_order_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/domain/scale_reading.dart';
import 'package:aby_pos/app/models/scale.dart';
import 'package:aby_pos/app/services/alert_service.dart';
import 'package:aby_pos/app/services/notification_service.dart';
import 'package:aby_pos/app/services/scale/scale_service.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

class FakeScale implements ScaleLink {
  FakeScale(this.reply);

  String reply;
  List<int>? asked;

  @override
  Future<Uint8List> read(List<int> request, Duration listen) async {
    asked = request;
    return Uint8List.fromList(reply.codeUnits);
  }
}

class FakeNotifier implements Notifier {
  final shown = <(int, String, String)>[];

  @override
  Future<bool> init() async => true;

  @override
  Future<void> show(int id, String title, String body) async => shown.add((id, title, body));
}

void main() {
  group('Scale readings', () {
    test('the common formats', () {
      expect(ScaleReading.parse('ST,GS,+  0.534kg\r\n')!.grams, 534);
      expect(ScaleReading.parse('US,GS,+  0.530kg\r\n')!.stable, isFalse);
      expect(ScaleReading.parse('\x02 1.250\r')!.grams, 1250, reason: 'Toledo: kilograms without a unit');
      expect(ScaleReading.parse('   534 g\r\n')!.grams, 534);
      expect(ScaleReading.parse('0,750 kg')!.grams, 750, reason: 'a decimal comma');
      expect(ScaleReading.parse('1.000 lb')!.grams, 454);
      expect(ScaleReading.parse('ST,GS,+0.100kg\r\nST,GS,+0.250kg\r\nST,GS,+0.2')!.grams, 200,
          reason: 'the last line, even when cut short');
      expect(ScaleReading.parse('ST,GS,-0.010kg'), isNull);
      expect(ScaleReading.parse('ERROR'), isNull);
      expect(ScaleReading.parse(''), isNull);
    });

    test('scale targets round trip', () {
      const t = ScaleTarget(kind: ScaleKind.serial, address: 'COM3', baud: 4800, request: ScaleRequest.w);
      final back = ScaleTarget.decode(t.encode())!;
      expect((back.kind, back.address, back.baud, back.request), (ScaleKind.serial, 'COM3', 4800, ScaleRequest.w));
      expect(ScaleTarget.decode(''), isNull);
      expect(ScaleRequest.enq.bytes, [5]);
    });
  });

  group('With a database', () {
    late AppDatabase db;
    late Repos r;
    late SettingsService settings;

    setUp(() async {
      db = memoryDb();
      r = await Repos.open(db);
      settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
    });
    tearDown(() async {
      Get.reset();
      await db.close();
    });

    test('the scale service: asks, reads, refuses a moving weight', () async {
      final fake = FakeScale('ST,GS,+  0.534kg\r\n');
      final scale = ScaleService(settings, links: (_) => fake);
      expect(scale.hasScale, isFalse);
      await expectLater(scale.readGrams(), throwsA(isA<ScaleException>()));
      await settings.set(
        AppSettings.scale,
        const ScaleTarget(kind: ScaleKind.serial, address: 'COM3', request: ScaleRequest.p).encode(),
        by: owner,
      );
      expect(await scale.readGrams(), 534);
      expect(fake.asked, ScaleRequest.p.bytes);
      fake.reply = 'US,GS,+  0.530kg\r\n';
      await expectLater(scale.readGrams(), throwsA(isA<ScaleException>().having((e) => e.message, 'message', contains('moving'))));
      fake.reply = '';
      await expectLater(scale.readGrams(), throwsA(isA<ScaleException>().having((e) => e.message, 'message', contains('nothing'))));
    });

    test('notifications: once a day per kind, again when it grows, and each person can turn kinds off', () async {
      Get.testMode = true;
      Get.put(r.stock);
      Get.put(r.customers);
      Get.put(r.expenses);
      Get.put(ParkedOrderRepository(db, r.device, r.audit));
      Get.put(settings);
      final notifier = FakeNotifier();
      final service = NotificationService(db, settings, AlertService(db), notifier: notifier);

      final tubs = (await r.stock.items()).firstWhere((i) => i.name == 'Ice cream tubs, 500 ml');
      await r.stock.adjust(tubs.id, -20, note: 'sold off the books', by: owner);
      final today = DateTime(2026, 10, 28, 10);

      final first = await service.check(now: today, force: true);
      expect(first.map((a) => a.kind), contains(AlertKind.lowStock));
      expect(notifier.shown.first.$2, 'Scoops Tamale');
      expect(notifier.shown.first.$3, contains('Ice cream tubs'));
      expect(await service.check(now: today.add(const Duration(hours: 2)), force: true), isEmpty, reason: 'already told today');

      // One more item runs low: told again.
      final cones = (await r.stock.items()).firstWhere((i) => !i.isLow);
      await r.stock.adjust(cones.id, -(cones.onHand + 1000), note: 'test', by: owner);
      expect((await service.check(now: today.add(const Duration(hours: 3)), force: true)).single.kind, AlertKind.lowStock);

      // The next day, told again; unless this person turned it off.
      await service.setOff(owner.id, {AlertKind.lowStock});
      expect(await service.offFor(owner.id), {AlertKind.lowStock});
      expect((await service.check(now: today.add(const Duration(days: 1)), force: true)).map((a) => a.kind), contains(AlertKind.lowStock),
          reason: 'nobody signed in: everything shows');

      await settings.set(AppSettings.notifications, false, by: owner);
      expect(await service.check(now: today.add(const Duration(days: 2)), force: true), isEmpty);
      expect(await service.check(now: today.add(const Duration(days: 3))), isEmpty, reason: 'not started');
    });
  });
}
