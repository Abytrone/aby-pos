import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// When closing the day would record something, and when it would only write
/// an empty Z report (the Close day button is off then).
void main() {
  late AppDatabase db;
  late Repos r;

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
  });
  tearDown(() => db.close());

  Future<bool> active() async => (await r.closes.openPeriod()).hasActivity;

  Future<void> sell() async {
    final waffle = (await r.catalog.products()).firstWhere((p) => p.name == 'Waffle');
    await r.sales.completeSale(
      lines: [CartLine(product: waffle, quantity: 1)],
      payment: PaymentInput.cash(tendered: 5000),
      cashier: cashier,
    );
  }

  test('a fresh till has nothing to close', () async {
    expect(await active(), isFalse);
  });

  test('a sale gives something to close; closing it leaves nothing again', () async {
    await sell();
    expect(await active(), isTrue);
    await r.closes.closeDay(openingFloat: 0, countedCash: 1200, closedBy: owner);
    expect(await active(), isFalse, reason: 'a second close right after would be empty');
  });

  test('a started day counts, even with no sales yet, and closing ends it', () async {
    await r.shifts.open(float: 5000, by: owner);
    expect(await active(), isTrue);
    await r.closes.closeDay(openingFloat: 5000, countedCash: 5000, closedBy: owner);
    expect(await active(), isFalse);
  });

  test('cash put in or out of the drawer counts', () async {
    await r.cashEvents.payInOrOut(payIn: true, amount: 1000, reason: 'Float top-up', actor: owner);
    expect(await active(), isTrue);
  });
}
