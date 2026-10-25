import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/parked_order_repository.dart';
import 'package:aby_pos/app/data/repositories/report_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/domain/accountant_pack.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/alert_service.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);
  final month = DateRange.of(ReportPeriod.thisMonth, DateTime.now());

  Future<CompletedSale> sell(List<CartLine> lines, {Customer? customer, List<PaymentInput>? payments}) => r.sales.completeSale(
        lines: lines,
        payments: payments ?? [const PaymentInput.cash(tendered: 100000)],
        cashier: cashier,
        customer: customer,
      );

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
  });
  tearDown(() => db.close());

  test('date ranges: weeks start on Monday; the previous range is as long', () {
    final wed = DateTime(2026, 10, 21, 15);
    final week = DateRange.of(ReportPeriod.thisWeek, wed);
    expect(week.from, DateTime(2026, 10, 19));
    expect(week.to, DateTime(2026, 10, 22));
    expect(week.previous.from, DateTime(2026, 10, 16));
    final last = DateRange.of(ReportPeriod.lastMonth, wed);
    expect(last.from, DateTime(2026, 9));
    expect(last.lastDay, DateTime(2026, 9, 30));
    final custom = DateRange.of(ReportPeriod.custom, wed, start: DateTime(2026, 10, 1, 9), end: DateTime(2026, 10, 3, 9));
    expect(custom.days, 3);
  });

  test('sales summary, products with grades, options, payments and staff', () async {
    final cone = named('Vanilla cone');
    final sprinkles = menu.groups.expand((g) => g.options).firstWhere((o) => o.name == 'Sprinkles');
    await sell([
      CartLine(product: cone, variant: cone.variants.first, options: [sprinkles], quantity: 2), // 36.00
      CartLine(product: named('Waffle'), discount: const Discount(kind: DiscountKind.amount, value: 200, reason: 'Staff')), // 10.00
    ]);
    final momo = (await r.payMethods.list()).firstWhere((m) => m.name == 'MTN MoMo');
    final second = await sell([CartLine(product: named('Milkshake'))], payments: [PaymentInput.from(momo, reference: 'MP-9')]);
    final line = (await r.refunds.refundable(second.saleId))!.lines.single;
    await r.refunds.refund(
      RefundDraft(saleId: second.saleId, reason: 'Other', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
      payments: [const RefundPaymentInput(method: PaymentMethod.cash, methodName: 'Cash', amount: 2000)],
      actor: owner,
    );
    await r.cashEvents.noSale(reason: 'Give change', actor: cashier);

    final s = await r.reports.sales(month);
    expect(s.count, 2);
    expect(s.gross, 3600 + 1200 + 2000);
    expect(s.discounts, 200);
    expect(s.refunds, 2000);
    expect(s.net, 4600);
    expect(s.items, 4);
    expect(s.averageSale, (6800 - 200) ~/ 2);
    expect(s.series.length, month.days);
    expect(s.series.fold(0, (a, b) => a + b.$2), 6600);

    final products = await r.reports.products(month);
    expect(products.first.name, 'Vanilla cone');
    expect(products.first.revenue, 3600);
    expect(products.firstWhere((p) => p.name == 'Waffle').revenue, 1000, reason: 'after the discount');
    expect(products.first.grade, 'A');
    expect((await r.reports.options(month))['Sprinkles'], 2);

    final (byMethod, rounding) = await r.reports.payments(month);
    expect(byMethod, {'Cash': 4600, 'MTN MoMo': 2000});
    expect(rounding, 0);

    final staff = await r.reports.staff(month);
    final ama = staff.firstWhere((x) => x.name == 'Ama');
    expect(ama.sales, 2);
    expect(ama.discounts, 200);
    expect(ama.noSales, 1);
    expect(staff.firstWhere((x) => x.name == 'Kofi').refunds, 1);

    final grid = await r.reports.byHour(month);
    final now = DateTime.now();
    expect(grid[now.weekday - 1][now.hour], greaterThan(0));
  });

  test('ABC grades: 80% A, the next 15% B, the rest C', () {
    final graded = ReportRepository.grade([
      for (final (i, v) in [700, 100, 100, 50, 50].indexed) ProductFigures(productId: '$i', name: '$i', category: '', revenue: v),
    ]);
    // Starting shares 0, 70, 80, 90, 95%: B covers 80 to 95%.
    expect(graded.map((p) => p.grade), ['A', 'A', 'B', 'B', 'C']);
  });

  test('slow movers are on the till but unsold lately', () async {
    await sell([CartLine(product: named('Waffle'))]);
    final slow = await r.reports.slowMovers();
    expect(slow.map((x) => x.$1), isNot(contains('Waffle')));
    expect(slow.map((x) => x.$1), contains('Ice cream tub'));
  });

  test('customers: new and returning, owed and wallets; stock and tax', () async {
    final id = await r.customers.save(const CustomerDraft(name: 'Ama'), by: owner);
    final ama = (await r.customers.find(id))!;
    await sell([CartLine(product: named('Waffle'))], customer: ama);
    await r.customers.topUp(id, amount: 500, method: (await r.payMethods.list()).first, by: owner);
    final c = await r.reports.customers(month);
    expect(c.newCustomers, 1);
    expect(c.returning, 0);
    expect(c.top.single, ('Ama', 1200));
    expect(c.wallets, 500);

    final mix = (await r.stock.items()).firstWhere((i) => i.name == 'Waffle mix');
    await r.stock.logWaste(mix.id, 500, reason: WasteReason.expired, by: owner);
    final st = await r.reports.stockAndTax(month);
    expect(st.stockValue, greaterThan(0));
    expect(st.waste.single.$1, 'Waffle mix');
    expect(st.movements.keys, containsAll(['sale', 'waste']));
    expect(st.taxes, isEmpty);
  });

  test("the accountant's pack is a zip of CSVs and a PDF", () async {
    await sell([CartLine(product: named('Waffle'))]);
    final zip = await AccountantPack(db).build(
      shopName: 'Scoops Tamale',
      range: month,
      summary: await r.reports.sales(month),
      pnl: await r.profit.forPeriod(month.from, month.to),
      stockTax: await r.reports.stockAndTax(month),
    );
    final archive = ZipDecoder().decodeBytes(zip);
    expect(archive.files.map((f) => f.name),
        containsAll(['sales.csv', 'payments.csv', 'refunds.csv', 'expenses.csv', 'purchases.csv', 'tax.csv', 'stock_valuation.csv', 'summary.pdf']));
    final sales = String.fromCharCodes(archive.files.firstWhere((f) => f.name == 'sales.csv').content);
    expect(sales, contains('12.00'));
  });

  group('Alerts', () {
    setUp(() async {
      Get.testMode = true;
      Get.put(r.stock);
      Get.put(r.customers);
      Get.put(r.expenses);
      Get.put(ParkedOrderRepository(db, r.device, r.audit));
      final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
      await settings.load();
      Get.put(settings);
    });
    tearDown(Get.reset);

    test('low stock, a day not closed, and expenses due', () async {
      final tubs = (await r.stock.items()).firstWhere((i) => i.name == 'Ice cream tubs, 500 ml');
      await r.stock.adjust(tubs.id, -20, note: 'sold off the books', by: owner);
      await sell([CartLine(product: named('Waffle'))]);
      await db.customStatement('UPDATE sales SET created_at = created_at - 3 * 86400');
      await r.expenses.saveRecurring(
        name: 'Shop rent',
        categoryId: (await r.expenses.categories()).first.id,
        amount: 80000,
        dayOfMonth: 1,
        paidFrom: MoneySource.momo,
        by: owner,
      );
      final next = DateTime(DateTime.now().year, DateTime.now().month + 1, 2, 12);
      final alerts = await AlertService(db).current(now: next);
      final kinds = alerts.map((a) => a.kind).toSet();
      expect(kinds, containsAll({AlertKind.lowStock, AlertKind.dayNotClosed, AlertKind.expenseDue}));
      expect(alerts.firstWhere((a) => a.kind == AlertKind.lowStock).names, contains('Ice cream tubs, 500 ml'));
      expect(AppSettings.parkedWarnHours.defaultValue, 12);
    });
  });
}
