import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/receipt_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/domain/receipt/escpos.dart';
import 'package:aby_pos/app/domain/receipt/receipt_code.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/printing/print_service.dart';
import 'package:aby_pos/app/services/printing/printer_link.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// Records what was sent; fails while [down] is true.
class FakeLink implements PrinterLink {
  final sent = <Uint8List>[];
  bool down = false;

  @override
  Future<void> send(Uint8List bytes) async {
    if (down) throw const PrinterException('The printer is off.');
    sent.add(bytes);
  }
}

String _text(Uint8List bytes) => String.fromCharCodes(bytes.where((b) => b >= 32 && b < 127));

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;
  late SettingsService settings;
  late FakeLink link;
  late PrintService printing;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
    link = FakeLink();
    printing = PrintService(settings, ReceiptRepository(db), r.device, links: (_) => link, retryAfter: const Duration(hours: 1));
  });
  tearDown(() async {
    printing.onClose();
    await db.close();
  });

  Future<void> setUpPrinter({bool drawer = false, bool auto = true}) async {
    await settings.set(AppSettings.receiptPrinter, const PrinterTarget(kind: PrinterKind.network, address: '10.0.0.9').encode(), by: owner);
    await settings.set(AppSettings.cashDrawer, drawer, by: owner);
    await settings.set(AppSettings.autoPrint, auto, by: owner);
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('no printer: nothing queues and the sale is not held up', () async {
    final sale = await r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], payments: [const PaymentInput.cash(tendered: 2000)], cashier: cashier);
    await printing.afterSale(sale.saleId);
    expect(printing.queue, isEmpty);
    expect(await printing.printSale(sale.saleId), isFalse);
    expect(link.sent, isEmpty);
  });

  test('a cash sale prints its receipt with the drawer kick first', () async {
    await setUpPrinter(drawer: true);
    await settings.set(AppSettings.receiptFooter, 'Akwaaba!', by: owner);
    final sale = await r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], payments: [const PaymentInput.cash(tendered: 2000)], cashier: cashier);
    await printing.afterSale(sale.saleId);
    await settle();
    final bytes = link.sent.single;
    expect(bytes.sublist(2, 7), EscPos.drawerKick);
    expect(_text(bytes), contains('Receipt ${sale.displayNumber}'));
    expect(_text(bytes), contains('Akwaaba!'));
    expect(_text(bytes), contains('Cash given'));
  });

  test('printing off: a cash sale still opens the drawer, MoMo does not', () async {
    await setUpPrinter(drawer: true, auto: false);
    final cash = await r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], payments: [const PaymentInput.cash(tendered: 2000)], cashier: cashier);
    await printing.afterSale(cash.saleId);
    await settle();
    expect(link.sent.single, EscPos.kickOnly());
    final momo = (await r.payMethods.list()).firstWhere((m) => m.name == 'MTN MoMo');
    final sale = await r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], payments: [PaymentInput.from(momo, reference: 'MP-1')], cashier: cashier);
    await printing.afterSale(sale.saleId);
    await settle();
    expect(link.sent, hasLength(1));
    // The button still prints, marked as a reprint, and reprint last finds it.
    expect(await printing.reprintLast(), isTrue);
    await settle();
    expect(_text(link.sent.last), contains('REPRINT'));
    expect(_text(link.sent.last), contains(sale.displayNumber));
  });

  test('credit sales print a customer copy and a shop copy', () async {
    await setUpPrinter();
    final id = await r.customers.save(const CustomerDraft(name: 'Kofi Mensah'), by: owner);
    final kofi = (await r.customers.find(id))!;
    final sale = await r.sales.completeSale(
      lines: [CartLine(product: named('Waffle'))],
      payments: [const PaymentInput.credit(customer: 'Kofi Mensah')],
      customer: kofi,
      cashier: cashier,
    );
    await printing.afterSale(sale.saleId);
    await settle();
    expect(link.sent, hasLength(2));
    expect(_text(link.sent[0]), contains('CUSTOMER COPY'));
    expect(_text(link.sent[1]), contains('SHOP COPY'));
    expect(_text(link.sent[1]), contains('Customer: Kofi Mensah'));
  });

  test('the printer off: jobs wait, then go when it is back', () async {
    await setUpPrinter();
    link.down = true;
    final sale = await r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], payments: [const PaymentInput.cash(tendered: 2000)], cashier: cashier);
    await printing.afterSale(sale.saleId);
    await printing.printSale(sale.saleId);
    await settle();
    expect(printing.queue, hasLength(2));
    expect(printing.problem, 'The printer is off.');
    expect(printing.queue.first.attempts, greaterThanOrEqualTo(1), reason: 'each new job tries the stuck ones again');
    link.down = false;
    await printing.retryNow();
    expect(printing.queue, isEmpty);
    expect(link.sent, hasLength(2));
    expect(printing.problem, isNull);
  });

  test('refund slips, and the receipt QR code finds the sale', () async {
    await setUpPrinter(drawer: true);
    final sale = await r.sales.completeSale(lines: [CartLine(product: named('Waffle'))], payments: [const PaymentInput.cash(tendered: 2000)], cashier: cashier);
    final line = (await r.refunds.refundable(sale.saleId))!.lines.single;
    final refund = await r.refunds.refund(
      RefundDraft(saleId: sale.saleId, reason: 'Other', lines: [RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: 1)]),
      payments: [const RefundPaymentInput(method: PaymentMethod.cash, methodName: 'Cash', amount: 1200)],
      actor: owner,
    );
    await printing.afterRefund(refund.refundId);
    await settle();
    final slip = link.sent.single;
    expect(slip.sublist(2, 7), EscPos.drawerKick);
    expect(_text(slip), contains('REFUND ${refund.displayNumber}'));
    expect(_text(slip), contains('For sale ${sale.displayNumber}'));

    final receipt = (await ReceiptRepository(db).sale(sale.saleId))!;
    expect(receipt.refunded, 1200);
    expect(await r.refunds.saleIdByNumber(ReceiptCode.encode(sale.saleId)), sale.saleId);
    expect(await r.refunds.saleIdByNumber(ReceiptCode.encode('not-a-sale')), isNull);
  });

  test('a network printer gets the bytes on port 9100', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final got = Completer<List<int>>();
    server.listen((socket) async {
      final all = <int>[];
      await socket.forEach(all.addAll);
      got.complete(all);
    });
    await NetworkLink('127.0.0.1:${server.port}').send(Uint8List.fromList([1, 2, 3]));
    expect(await got.future.timeout(const Duration(seconds: 5)), [1, 2, 3]);
    await server.close();

    expect(NetworkLink('192.168.1.50').port, 9100);
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    await expectLater(
      NetworkLink('127.0.0.1:$port', timeout: const Duration(seconds: 2)).send(Uint8List(1)),
      throwsA(isA<PrinterException>()),
    );
  });
}
