import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/pay_method_repository.dart';
import 'package:aby_pos/app/data/repositories/refund_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
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
  Future<int> onHand(String name) async => (await r.stock.items()).firstWhere((i) => i.name == name).onHand;

  Future<CompletedSale> sell(List<CartLine> lines, {List<PaymentInput>? payments, int roundTo = 0}) =>
      r.sales.completeSale(
        lines: lines,
        payments: payments ?? [const PaymentInput.cash(tendered: 100000)],
        cashier: cashier,
        roundTo: roundTo,
      );

  RefundPaymentInput cashBack(int amount) =>
      RefundPaymentInput(method: PaymentMethod.cash, methodId: method('Cash').id, methodName: 'Cash', amount: amount);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    methods = await r.payMethods.list(includeInactive: true);
  });
  tearDown(() => db.close());

  group('Payments', () {
    test('a new shop has the usual Ghana methods; cash cannot be switched off', () async {
      expect(methods.map((m) => m.name), containsAll(['Cash', 'MTN MoMo', 'Telecel Cash', 'AT Money', 'Credit (book)']));
      expect((await r.payMethods.list()).map((m) => m.name), isNot(contains('AT Money')));
      expect(method('MTN MoMo').needsReference, isTrue);
      await expectLater(
        r.payMethods.setActive(method('Cash').id, active: false, by: owner),
        throwsA(isA<PayMethodException>()),
      );
      final id = await r.payMethods.save(
        name: 'Vodafone Cash (old)',
        kind: PaymentMethod.momo,
        needsReference: true,
        shortReference: true,
        merchantNumber: '020 000 0000',
        by: owner,
      );
      final saved = (await r.payMethods.list()).firstWhere((m) => m.id == id);
      expect(saved.shortReference, isTrue);
      expect(saved.merchantNumber, '020 000 0000');
    });

    test('a split payment is saved as one row per payment, with names and rounding', () async {
      final done = await sell(
        [CartLine(product: named('Waffle')), CartLine(product: named('Milkshake'))], // 12 + 20
        payments: [
          PaymentInput.from(method('MTN MoMo'), amount: 1000, reference: 'mp 001'),
          const PaymentInput.cash(tendered: 2500),
        ],
      );
      expect(done.total, 3200);
      expect(done.changeDue, 300);
      expect(done.paymentLabels, ['MTN MoMo GH₵ 10.00', 'Cash GH₵ 22.00']);
      final rows = await db.select(db.payments).get();
      expect(rows.map((p) => p.amount), unorderedEquals([1000, 2200]));
      final momo = rows.firstWhere((p) => p.method == PaymentMethod.momo);
      expect(momo.methodName, 'MTN MoMo');
      expect(momo.momoReference, 'MP001');
      final cash = rows.firstWhere((p) => p.method == PaymentMethod.cash);
      expect(cash.changeGiven, 300);
    });

    test('cash rounding is recorded on the sale and in the drawer', () async {
      final cone = named('Vanilla cone');
      // A single scoop, 15.00, less 5.23: 9.77 rounds to 9.80.
      final line = CartLine(
        product: cone,
        variant: cone.variants.first,
        discount: const Discount(kind: DiscountKind.amount, value: 523, reason: 'Staff'),
      );
      final done = await sell([line], payments: [const PaymentInput.cash(tendered: 1000)], roundTo: 10);
      expect(done.total, 977);
      expect(done.rounding, 3);
      expect((await db.select(db.sales).getSingle()).rounding, 3);
      final period = await r.closes.openPeriod();
      expect(period.cashTakings, 980);
      expect(period.rounding, 3);
    });

    test('a MoMo reference can only be used once', () async {
      final waffle = named('Waffle');
      final momo = method('MTN MoMo');
      final first = await sell([CartLine(product: waffle)], payments: [PaymentInput.from(momo, reference: 'MP-77')]);
      await expectLater(
        sell([CartLine(product: waffle)], payments: [PaymentInput.from(momo, reference: 'mp-77')]),
        throwsA(isA<SaleException>().having((e) => e.message, 'message', contains(first.displayNumber))),
      );
      // Voided sales free their reference.
      await r.sales.voidSale(first.saleId, actor: owner);
      await sell([CartLine(product: waffle)], payments: [PaymentInput.from(momo, reference: 'MP-77')]);
    });
  });

  group('Refunds', () {
    test('part of a line comes back at what was paid, and goes back into stock', () async {
      final cone = named('Vanilla cone');
      final done = await sell([
        CartLine(
          product: cone,
          variant: cone.variants.first,
          quantity: 2,
          discount: const Discount(kind: DiscountKind.percent, value: 10, reason: 'Regular customer'),
        ),
      ]);
      expect(done.total, 2700);
      expect(await onHand('Wafer cones'), 198);

      final sale = (await r.refunds.refundable(done.saleId))!;
      final line = sale.lines.single;
      expect(line.paid, 2700);
      expect(line.amountFor(1), 1350);

      final first = await r.refunds.refund(
        RefundDraft(saleId: done.saleId, reason: 'Wrong item', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
        payments: [cashBack(1350)],
        actor: cashier,
        approver: owner,
      );
      expect(first.displayNumber, 'R-0001');
      expect(first.paidBack, 1350);
      expect(await onHand('Wafer cones'), 199);
      expect(await onHand('Vanilla ice cream'), 20000 - 160 + 80);

      // Only one is left to give back.
      await expectLater(
        r.refunds.refund(
          RefundDraft(saleId: done.saleId, reason: 'Wrong item', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 2)]),
          payments: [cashBack(2700)],
          actor: cashier,
        ),
        throwsA(isA<RefundException>()),
      );
      expect((await r.refunds.refundable(done.saleId))!.lines.single.left, 1);
      expect((await r.audit.list(actions: {AuditAction.refundGiven})).single.approverName, 'Kofi');
    });

    test('the payments must match the refund; damaged items stay out of stock', () async {
      final done = await sell([CartLine(product: named('Ice cream tub'))]);
      final line = (await r.refunds.refundable(done.saleId))!.lines.single;
      final draft = RefundDraft(
        saleId: done.saleId,
        reason: 'Damaged or melted',
        lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1, restock: false)],
      );
      await expectLater(r.refunds.refund(draft, payments: [cashBack(100)], actor: owner), throwsA(isA<RefundException>()));
      await r.refunds.refund(draft, payments: [cashBack(6000)], actor: owner);
      expect(await onHand('Ice cream tubs, 500 ml'), 23);
      expect((await db.select(db.refundLines).getSingle()).restocked, isFalse);
    });

    test('a refunded sale cannot be voided, and the refund shows on the sale', () async {
      final done = await sell([CartLine(product: named('Waffle'), quantity: 2)]);
      final line = (await r.refunds.refundable(done.saleId))!.lines.single;
      await r.refunds.refund(
        RefundDraft(saleId: done.saleId, reason: 'Other', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
        payments: [cashBack(1200)],
        actor: owner,
      );
      await expectLater(r.sales.voidSale(done.saleId, actor: owner), throwsA(isA<SaleException>()));
      final today = await r.sales.watchToday(dayStartMinutes: 0).first;
      expect(today.single.refunded, 1200);
      expect(today.single.fullyRefunded, isFalse);
      expect(await r.refunds.saleIdByNumber('#00001'), done.saleId);
    });

    test('without a receipt: the amount is typed and stock comes back by the recipe', () async {
      final waffle = named('Waffle');
      final before = await onHand('Waffle mix');
      final refund = await r.refunds.refund(
        RefundDraft(
          reason: 'Customer not happy',
          lines: [RefundLineDraft(productId: waffle.id, variantId: waffle.variants.single.id, name: 'Waffle', quantity: 2, amount: 2000)],
        ),
        payments: [cashBack(2000)],
        actor: cashier,
        approver: owner,
      );
      expect(refund.total, 2000);
      expect(await onHand('Waffle mix'), before + 240);
      expect((await db.select(db.refunds).getSingle()).withoutReceipt, isTrue);
    });
  });

  group('Exchanges', () {
    test('returned items pay first; the customer pays only the difference', () async {
      final first = await sell([CartLine(product: named('Waffle'))]);
      final line = (await r.refunds.refundable(first.saleId))!.lines.single;
      final done = await r.sales.completeSale(
        lines: [CartLine(product: named('Milkshake'))],
        payments: [const PaymentInput.cash(tendered: 1000)],
        cashier: cashier,
        exchange: ExchangeInput(
          returned: RefundDraft(
            saleId: first.saleId,
            reason: 'Wrong item',
            lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)],
          ),
        ),
      );
      expect(done.total, 2000);
      expect(done.changeDue, 200, reason: '20.00 - 12.00 returned = 8.00 to pay from 10.00');
      expect(done.exchangeRefund!.total, 1200);
      expect(done.exchangeRefund!.paidBack, 0);
      final payments = await (db.select(db.payments)..where((p) => p.saleId.equals(done.saleId))).get();
      expect(payments.map((p) => (p.method, p.amount)), unorderedEquals([(PaymentMethod.exchange, 1200), (PaymentMethod.cash, 800)]));
      final refund = await db.select(db.refunds).getSingle();
      expect(refund.exchangeSaleId, done.saleId);
      // The drawer only sees the 8.00.
      final period = await r.closes.openPeriod();
      expect(period.cashRefunds, 0);
    });

    test('when the returned items are worth more, the difference goes back', () async {
      final cone = named('Vanilla cone');
      final first = await sell([CartLine(product: cone, variant: cone.variants[1])]); // 22.00
      final line = (await r.refunds.refundable(first.saleId))!.lines.single;
      final returned = RefundDraft(
        saleId: first.saleId,
        reason: 'Wrong item',
        lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)],
      );
      await expectLater(
        r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], cashier: cashier, exchange: ExchangeInput(returned: returned)),
        throwsA(isA<SaleException>()),
        reason: 'how to give back the difference is needed',
      );
      final done = await r.sales.completeSale(
        lines: [CartLine(product: named('Waffle'))],
        cashier: cashier,
        exchange: ExchangeInput(returned: returned, payBack: method('Cash')),
      );
      expect(done.exchangeRefund!.paidBack, 1000);
      final period = await r.closes.openPeriod();
      expect(period.cashRefunds, 1000);
      expect(period.expectedCash(0), period.cashTakings - 1000);
    });
  });

  group('Close day', () {
    test('cash refunds come off the drawer, and no-sales are counted per person', () async {
      final done = await sell([CartLine(product: named('Waffle'))], payments: [const PaymentInput.cash(tendered: 1200)]);
      final line = (await r.refunds.refundable(done.saleId))!.lines.single;
      await r.refunds.refund(
        RefundDraft(saleId: done.saleId, reason: 'Other', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
        payments: [cashBack(1200)],
        actor: owner,
      );
      await r.cashEvents.noSale(reason: 'Give change', actor: cashier);
      await r.cashEvents.noSale(reason: 'Check the float', actor: cashier);

      final period = await r.closes.openPeriod();
      expect(period.refundsCount, 1);
      expect(period.expectedCash(5000), 5000);
      expect(period.noSales, {'Ama': 2});

      final close = await r.closes.closeDay(openingFloat: 5000, countedCash: 5000, closedBy: owner);
      expect(close.difference, 0);
      expect(close.cashRefunds, 1200);
      expect(close.noSaleCount, 2);
      final next = await r.closes.openPeriod();
      expect(next.refundsCount, 0, reason: 'the refund belongs to the closed day');
      expect((await r.audit.list(actions: {AuditAction.noSale})), hasLength(2));
    });
  });
}
