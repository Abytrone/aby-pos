import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/expense_repository.dart';
import 'package:aby_pos/app/domain/catalogue_rules.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;
  late List<ExpenseCategory> categories;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);
  String category(String name) => categories.firstWhere((c) => c.name == name).id;
  final today = DateTime.now();
  final monthStart = DateTime(today.year, today.month);
  final monthEnd = DateTime(today.year, today.month + 1);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    categories = await r.expenses.categories();
  });
  tearDown(() => db.close());

  group('Expenses', () {
    test('a new shop has the usual categories; names are unique', () async {
      expect(categories.map((c) => c.name), containsAll(['Rent', 'Electricity (ECG)', 'Generator fuel', 'Ice']));
      await expectLater(r.expenses.saveCategory(name: 'rent', by: owner), throwsA(isA<ExpenseException>()));
      await r.expenses.saveCategory(name: 'Security', by: owner);
      expect((await r.expenses.categories()).last.name, 'Security');
    });

    test('paid from the drawer, it is also a pay-out; from MoMo it is not', () async {
      await r.expenses.add(
        ExpenseDraft(day: today, amount: 2000, categoryId: category('Ice'), paidFrom: MoneySource.drawer, note: 'Mr Issah'),
        actor: cashier,
      );
      await r.expenses.add(
        ExpenseDraft(day: today, amount: 80000, categoryId: category('Rent'), paidFrom: MoneySource.momo),
        actor: owner,
      );
      final period = await r.closes.openPeriod();
      expect(period.payOuts, 2000);
      final list = await r.expenses.list(monthStart, monthEnd);
      expect(list.map((e) => e.categoryName), unorderedEquals(['Ice', 'Rent']));
      expect(await r.expenses.byCategory(monthStart, monthEnd), {'Rent': 80000, 'Ice': 2000});
      expect(await r.audit.list(actions: {AuditAction.expenseAdded}), hasLength(2));
      await expectLater(
        r.expenses.add(ExpenseDraft(day: today, amount: 0, categoryId: category('Ice'), paidFrom: MoneySource.bank), actor: owner),
        throwsA(isA<ExpenseException>()),
      );
    });

    test('a monthly reminder is due on its day, once a month', () async {
      final id = await r.expenses.saveRecurring(
        name: 'Shop rent',
        categoryId: category('Rent'),
        amount: 80000,
        dayOfMonth: 1,
        paidFrom: MoneySource.momo,
        by: owner,
      );
      // Added after the 1st: it starts next month.
      expect(await r.expenses.due(), isEmpty);
      final nextMonth = DateTime(today.year, today.month + 1, 2);
      var due = await r.expenses.due(now: nextMonth);
      expect(due.single.id, id);
      await r.expenses.confirm(due.single, amount: 85000, actor: owner, now: nextMonth);
      expect(await r.expenses.due(now: nextMonth), isEmpty);
      final list = await r.expenses.list(DateTime(nextMonth.year, nextMonth.month), DateTime(nextMonth.year, nextMonth.month + 1));
      expect(list.single.amount, 85000);
      final monthAfter = DateTime(today.year, today.month + 2, 5);
      due = await r.expenses.due(now: monthAfter);
      await r.expenses.skip(due.single, now: monthAfter);
      expect(await r.expenses.due(now: monthAfter), isEmpty);

      await r.expenses.setRecurringActive(id, active: false, by: owner);
      await r.expenses.setRecurringActive(id, active: false, by: owner);
      final paused = await r.audit.list(actions: {AuditAction.expenseCategorySaved});
      expect(paused.where((e) => e.summary == 'Turned off the reminder "Shop rent"'), hasLength(1));
      expect(paused.first.actorName, owner.name);
    });
  });

  group("Owner's money", () {
    test('drawings and capital are kept apart and move the drawer when they use it', () async {
      await r.expenses.ownerMoney(kind: OwnerMoneyKind.drawing, amount: 20000, source: MoneySource.drawer, actor: owner);
      await r.expenses.ownerMoney(kind: OwnerMoneyKind.capital, amount: 50000, source: MoneySource.bank, actor: owner);
      await expectLater(
        r.expenses.ownerMoney(kind: OwnerMoneyKind.drawing, amount: 100, source: MoneySource.ownerPocket, actor: owner),
        throwsA(isA<ExpenseException>()),
      );
      final period = await r.closes.openPeriod();
      expect(period.payOuts, 20000);
      expect(period.payIns, 0, reason: 'capital by bank does not touch the drawer');
      final pnl = await r.profit.forPeriod(monthStart, monthEnd);
      expect(pnl.drawings, 20000);
      expect(pnl.capital, 50000);
      expect(pnl.expenseTotal, 0, reason: 'drawings are not expenses');
    });
  });

  group('Profit and loss', () {
    test('sales less discounts, refunds and tax, less cost, expenses and waste', () async {
      final waffle = named('Waffle');
      final first = await r.sales.completeSale(
        lines: [
          CartLine(
            product: waffle,
            quantity: 2,
            discount: const Discount(kind: DiscountKind.amount, value: 400, reason: 'Staff'),
          ),
        ],
        payments: [const PaymentInput.cash(tendered: 10000)],
        cashier: cashier,
      );
      final line = (await db.select(db.saleLines).get()).single;
      final costOfOne = line.costTotal ~/ 2;
      expect(costOfOne, greaterThan(0));

      final refundable = (await r.refunds.refundable(first.saleId))!.lines.single;
      await r.refunds.refund(
        RefundDraft(
          saleId: first.saleId,
          reason: 'Other',
          lines: [RefundLineDraft(saleLineId: refundable.saleLineId, name: refundable.title, quantity: 1)],
        ),
        payments: [const RefundPaymentInput(method: PaymentMethod.cash, methodName: 'Cash', amount: 1000)],
        actor: owner,
      );
      await r.expenses.add(ExpenseDraft(day: today, amount: 300, categoryId: category('Ice'), paidFrom: MoneySource.drawer), actor: owner);
      final mix = (await r.stock.items()).firstWhere((i) => i.name == 'Waffle mix');
      await r.stock.logWaste(mix.id, 1000, reason: WasteReason.expired, by: owner);

      final pnl = await r.profit.forPeriod(monthStart, monthEnd);
      expect(pnl.sales, 2400);
      expect(pnl.discounts, 400);
      expect(pnl.refunds, 1000);
      expect(pnl.netSales, 1000);
      expect(pnl.costOfGoods, line.costTotal - costOfOne);
      expect(pnl.expenses, {'Ice': 300});
      expect(pnl.waste, (1000 * mix.costMilli + 500) ~/ 1000);
      expect(pnl.netProfit, pnl.netSales - pnl.costOfGoods - 300 - pnl.waste);

      final before = await r.profit.previous(monthStart, monthEnd);
      expect(before.sales, 0);
    });

    test('a product without a recipe costs what its typed cost says', () async {
      final snacks = menu.categories.firstWhere((c) => c.name == 'Snacks');
      final id = await CatalogueRules(r.catalog).saveProduct(
        ProductDraft(categoryId: snacks.id, name: 'Bottled water', variants: const [VariantDraft(price: 300, manualCost: 180)]),
        by: owner,
      );
      final water = (await r.catalog.load()).products.firstWhere((p) => p.id == id);
      await r.sales.completeSale(
        lines: [CartLine(product: water, quantity: 3)],
        payments: [const PaymentInput.cash(tendered: 900)],
        cashier: cashier,
      );
      final pnl = await r.profit.forPeriod(monthStart, monthEnd);
      expect(pnl.costOfGoods, 540);
      expect(pnl.grossProfit, 360);
      final before = await r.profit.previous(monthStart, monthEnd);
      expect(before.sales, 0);
      expect(before.to, monthStart);
    });
  });
}
