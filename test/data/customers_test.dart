import 'dart:convert';

import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/customer_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/domain/customer_documents.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;
  late List<PayMethod> methods;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);
  PayMethod method(String name) => methods.firstWhere((m) => m.name == name);

  Future<Customer> add(String name, {String? phone, int? limit, int? dueDays}) async {
    final id = await r.customers.save(CustomerDraft(name: name, phone: phone, creditLimit: limit, dueDays: dueDays), by: owner);
    return (await r.customers.find(id))!;
  }

  Future<CompletedSale> onCredit(Customer c, String product, {Staff? approver}) => r.sales.completeSale(
        lines: [CartLine(product: named(product))],
        payments: [PaymentInput.from(method('Credit (book)'))],
        cashier: cashier,
        customer: c,
        creditApprover: approver,
      );

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    methods = await r.payMethods.list(includeInactive: true);
  });
  tearDown(() => db.close());

  group('Customers', () {
    test('phones are stored as +233, unique, and found by 4 digits', () async {
      final ama = await add('Ama Serwaa', phone: '024 123 4567');
      expect(ama.phone, '+233241234567');
      await expectLater(add('Someone', phone: '0241234567'), throwsA(isA<CustomerException>()));
      await expectLater(add('Bad', phone: '12345'), throwsA(isA<CustomerException>()));
      await add('Kwame', phone: '055 999 0000');
      expect((await r.customers.list(query: '1234')).single.name, 'Ama Serwaa');
      expect((await r.customers.list(query: '0241')).single.name, 'Ama Serwaa');
      expect((await r.customers.list(query: 'kwa')).single.name, 'Kwame');
      expect((await r.customers.byPhone('+233 24 123 4567'))!.id, ama.id);
    });
  });

  group('Credit book', () {
    test('a credit sale needs the customer and goes on their account with a due date', () async {
      await expectLater(
        r.sales.completeSale(
          lines: [CartLine(product: named('Waffle'))],
          payments: [PaymentInput.from(method('Credit (book)'))],
          cashier: cashier,
        ),
        throwsA(isA<SaleException>()),
      );
      final ama = await add('Ama', dueDays: 14);
      final sale = await onCredit(ama, 'Waffle');
      final after = (await r.customers.find(ama.id))!;
      expect(after.owed, 1200);
      final debt = (await r.customers.openDebts(ama.id)).single;
      expect(debt.saleNumber, sale.number);
      expect(debt.dueOn!.difference(debt.at).inDays, 14);
      expect((await db.select(db.sales).getSingle()).customerId, ama.id);
    });

    test('the credit limit blocks, unless someone approves', () async {
      final ama = await add('Ama', limit: 2000);
      await onCredit(ama, 'Waffle'); // 12.00
      await expectLater(onCredit(ama, 'Waffle'), throwsA(isA<SaleException>()));
      await onCredit(ama, 'Waffle', approver: owner);
      expect((await r.customers.find(ama.id))!.owed, 2400);
      expect(await r.audit.list(actions: {AuditAction.customerCreditLimit}), hasLength(1));
    });

    test('repayments pay the oldest first, or the sale chosen; aging shows what is late', () async {
      final ama = await add('Ama', dueDays: 7);
      final first = await onCredit(ama, 'Waffle'); // 12.00
      final second = await onCredit(ama, 'Milkshake'); // 20.00
      await r.customers.repay(ama.id, amount: 500, method: method('Cash'), by: cashier);
      var debts = await r.customers.openDebts(ama.id);
      expect(debts.map((d) => d.outstanding), [700, 2000]);
      await r.customers.repay(ama.id, amount: 1500, method: method('Cash'), forSaleId: second.saleId, by: cashier);
      debts = await r.customers.openDebts(ama.id);
      expect(debts.map((d) => (d.saleNumber, d.outstanding)), [(first.number, 700), (second.number, 500)]);

      final aging = await r.customers.aging(ama.id, now: DateTime.now().add(const Duration(days: 20)));
      expect(aging.days1to30, 1200);
      expect(aging.current, 0);
      expect(aging.total, 1200);

      await expectLater(
        r.customers.repay(ama.id, amount: 5000, method: method('Cash'), by: cashier),
        throwsA(isA<CustomerException>()),
        reason: 'more than owed',
      );
      await expectLater(
        r.customers.repay(ama.id, amount: 100, method: method('MTN MoMo'), by: cashier),
        throwsA(isA<CustomerException>()),
        reason: 'MoMo needs its reference',
      );
    });

    test('writing off is audited and reduces what is owed', () async {
      final ama = await add('Ama');
      await onCredit(ama, 'Waffle');
      await r.customers.writeOff(ama.id, amount: 200, reason: 'Moved away', actor: cashier, approver: owner);
      expect((await r.customers.find(ama.id))!.owed, 1000);
      expect((await r.audit.list(actions: {AuditAction.creditWrittenOff})).single.approverName, 'Kofi');
    });

    test('a refund of a credit sale comes off what is owed', () async {
      final ama = await add('Ama');
      final sale = await onCredit(ama, 'Waffle');
      final line = (await r.refunds.refundable(sale.saleId))!.lines.single;
      await r.refunds.refund(
        RefundDraft(saleId: sale.saleId, reason: 'Wrong item', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
        payments: [RefundPaymentInput(method: PaymentMethod.credit, methodId: method('Credit (book)').id, methodName: 'Credit (book)', amount: 1200)],
        actor: owner,
      );
      expect((await r.customers.find(ama.id))!.owed, 0);
      expect(await r.customers.openDebts(ama.id), isEmpty);
    });
  });

  group('Wallet', () {
    test('top up, spend at the till, keep change; the drawer counts the cash', () async {
      final ama = await add('Ama');
      await r.customers.topUp(ama.id, amount: 1000, method: method('Cash'), by: cashier);
      // Waffle 12.00: 10.00 from the wallet, 2.00 cash from 5.00, change kept.
      final done = await r.sales.completeSale(
        lines: [CartLine(product: named('Waffle'))],
        payments: [PaymentInput.from(method('Wallet'), amount: 1000), const PaymentInput.cash(tendered: 500)],
        cashier: cashier,
        customer: ama,
        changeToWallet: true,
      );
      expect(done.changeDue, 0);
      expect(done.changeKept, 300);
      expect((await r.customers.find(ama.id))!.wallet, 300);
      final cash = (await db.select(db.payments).get()).firstWhere((p) => p.method == PaymentMethod.cash);
      expect(cash.changeGiven, 0);

      final period = await r.closes.openPeriod();
      // 2.00 sale cash + 10.00 top-up + 3.00 kept change: 15.00 in the drawer.
      expect(period.expectedCash(0), 1500);

      await expectLater(
        r.sales.completeSale(
          lines: [CartLine(product: named('Waffle'))],
          payments: [PaymentInput.from(method('Wallet'))],
          cashier: cashier,
          customer: ama,
        ),
        throwsA(isA<SaleException>()),
        reason: 'the wallet only holds 3.00',
      );
    });

    test('a refund can go to the wallet', () async {
      final ama = await add('Ama');
      final sale = await r.sales.completeSale(
        lines: [CartLine(product: named('Waffle'))],
        payments: [const PaymentInput.cash(tendered: 1200)],
        cashier: cashier,
        customer: ama,
      );
      final line = (await r.refunds.refundable(sale.saleId))!.lines.single;
      await r.refunds.refund(
        RefundDraft(saleId: sale.saleId, reason: 'Other', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
        payments: [RefundPaymentInput(method: PaymentMethod.wallet, methodName: 'Wallet', amount: 1200)],
        actor: owner,
      );
      expect((await r.customers.find(ama.id))!.wallet, 1200);
      final stats = await r.customers.stats(ama.id);
      expect(stats.visits, 1);
      expect(stats.spend, 0, reason: 'refunded');
      expect(stats.favourites, ['Waffle']);
    });
  });

  group('Statements and reminders', () {
    test('a PDF statement and a WhatsApp reminder', () async {
      final ama = await add('Ama', phone: '0241234567');
      await onCredit(ama, 'Waffle');
      final now = DateTime.now();
      final entries = (await r.customers.ledger(ama.id, account: CustomerAccount.credit)).reversed.toList();
      final pdf = await CustomerDocuments.statementPdf(
        shopName: 'Scoops Tamale',
        customer: (await r.customers.find(ama.id))!,
        from: now.subtract(const Duration(days: 30)),
        to: now,
        opening: 0,
        entries: entries,
        aging: await r.customers.aging(ama.id),
      );
      expect(ascii.decode(pdf.sublist(0, 4)), '%PDF');

      final text = CustomerDocuments.reminder('Hello {name}, you owe {amount} at {shop}.',
          customer: ama, shopName: 'Scoops', amount: 'GH₵ 12.00');
      expect(text, 'Hello Ama, you owe GH₵ 12.00 at Scoops.');
      final uri = CustomerDocuments.whatsApp(ama.phone!, text);
      expect(uri.host, 'wa.me');
      expect(uri.path, '/233241234567');
      expect(uri.queryParameters['text'], text);
    });
  });
}
