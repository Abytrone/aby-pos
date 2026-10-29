import 'dart:io';

import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/insight_service.dart';
import 'package:aby_pos/app/services/training_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import '../helpers.dart';

void main() {
  group('Insights', () {
    late AppDatabase db;
    late Repos r;
    late InsightService insights;

    setUp(() async {
      db = memoryDb();
      r = await Repos.open(db);
      insights = InsightService(db, r.stock, r.customers);
    });
    tearDown(() => db.close());

    test('stock running out at this week\'s pace; dismissed and turned off', () async {
      final mix = (await r.stock.items()).firstWhere((i) => i.name == 'Waffle mix');
      // 5 kg in stock; 4 kg sold this week leaves 1 kg: under two days.
      await r.stock.record(stockItemId: mix.id, quantityChange: -4000, reason: StockReason.sale);
      expect((await r.stock.item(mix.id))!.onHand, 1000);
      var list = await insights.current();
      final out = list.firstWhere((i) => i.kind == InsightKind.runningOut);
      expect(out.names, ['Waffle mix']);
      expect(out.numbers.single, 2);

      await insights.dismiss(out);
      list = await insights.current();
      expect(list.where((i) => i.key == out.key), isEmpty, reason: 'dismissed for a week');

      await insights.turnOff(InsightKind.lateCredit);
      expect(await insights.off(), {InsightKind.lateCredit});
      await insights.turnAllOn();
      expect(await insights.off(), isEmpty);
    });

    test('customers more than 30 days late', () async {
      final id = await r.customers.save(const CustomerDraft(name: 'Ama', dueDays: 7), by: owner);
      final ama = (await r.customers.find(id))!;
      final menu = await r.catalog.load();
      await r.sales.completeSale(
        lines: [CartLine(product: menu.products.firstWhere((p) => p.name == 'Waffle'))],
        payments: [const PaymentInput.credit(customer: 'Ama')],
        customer: ama,
        cashier: cashier,
      );
      await db.customStatement('UPDATE customer_ledger SET due_on = due_on - 40 * 86400');
      final late = (await insights.current()).firstWhere((i) => i.kind == InsightKind.lateCredit);
      expect(late.numbers, [1, 1200]);
    });
  });

  group('Training mode', () {
    late Directory dir;

    setUp(() async => dir = await Directory.systemTemp.createTemp('aby_training_'));
    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('enter copies the shop and marks it; reset starts again; leave goes back', () async {
      final real = File('${dir.path}/real.sqlite');
      final copy = File('${dir.path}/training.sqlite');
      final marker = File('${dir.path}/marker');
      final db = AppDatabase(DatabaseConnection(NativeDatabase(real)));
      final r = await Repos.open(db);
      expect((await r.catalog.load()).products, isNotEmpty);
      var restarts = 0;
      final training = TrainingService(
        db,
        realFile: () async => real,
        trainingFile: () async => copy,
        markerFile: () async => marker,
        restart: () async => restarts++,
      );
      await training.load();
      expect(training.active.value, isFalse);

      await training.enter();
      expect(await marker.exists(), isTrue);
      expect(restarts, 1);
      final opened = sqlite3.open(copy.path);
      expect(opened.select("SELECT value FROM meta WHERE key = 'training_mode'").single['value'], '1');
      expect(opened.select('SELECT COUNT(*) AS n FROM outbox').single['n'], 0, reason: 'nothing to send from training');
      expect((opened.select('SELECT COUNT(*) AS n FROM products').single['n'] as int) > 0, isTrue);
      opened.execute('DELETE FROM products WHERE 1 = 0');
      opened.close();

      // Open the copy as the app would, practise, then reset.
      final practice = AppDatabase(DatabaseConnection(NativeDatabase(copy)));
      final t2 = TrainingService(
        practice,
        realFile: () async => real,
        trainingFile: () async => copy,
        markerFile: () async => marker,
        restart: () async => restarts++,
      );
      await t2.load();
      expect(t2.active.value, isTrue);
      await practice.customStatement("INSERT INTO meta (key, value) VALUES ('practice', 'yes')");
      await t2.reset();
      final fresh = sqlite3.open(copy.path);
      expect(fresh.select("SELECT * FROM meta WHERE key = 'practice'"), isEmpty);
      expect(fresh.select("SELECT value FROM meta WHERE key = 'training_mode'").single['value'], '1');
      fresh.close();

      final back = AppDatabase(DatabaseConnection(NativeDatabase(copy)));
      final t3 = TrainingService(
        back,
        realFile: () async => real,
        trainingFile: () async => copy,
        markerFile: () async => marker,
        restart: () async => restarts++,
      );
      await t3.leave();
      expect(await marker.exists(), isFalse);
      expect(restarts, 3);
    });
  });
}
