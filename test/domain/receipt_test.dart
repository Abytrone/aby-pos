import 'dart:typed_data';

import 'package:aby_pos/app/domain/receipt/escpos.dart';
import 'package:aby_pos/app/domain/receipt/receipt_builder.dart';
import 'package:aby_pos/app/domain/receipt/receipt_code.dart';
import 'package:aby_pos/app/domain/receipt/receipt_doc.dart';
import 'package:aby_pos/app/domain/receipt/receipt_pdf.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

bool _contains(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var hit = true;
    for (var j = 0; j < needle.length && hit; j++) {
      hit = haystack[i + j] == needle[j];
    }
    if (hit) return true;
  }
  return false;
}

void main() {
  test('plain ASCII for the printer: accents, Ghanaian letters, the cedi sign', () {
    expect(receiptAscii('Café Ɛkɔ'), 'Cafe Eko');
    expect(receiptAscii('GH₵ 5 · 2×'), 'GHGHS 5 - 2x');
    expect(receiptAscii('漢'), '?');
    expect(paperMoney(123450), '1,234.50');
    expect(paperMoney(-200), '-2.00');
  });

  test('wrapping and rows fit the paper', () {
    expect(wrap('one two three', 7), ['one two', 'three']);
    expect(wrap('abcdefghij', 4), ['abcd', 'efgh', 'ij']);
    final row = layout(const RRow('2 x A very long product name indeed', '36.00'), 32);
    expect(row.every((l) => l.length <= 32), isTrue);
    expect(row.last, endsWith(' 36.00'));
    expect(row.last.length, 32);
    expect(layout(const RText('Hi', align: ReceiptAlign.center), 10).single, '    Hi');
    expect(layout(const RText('Big', big: true, align: ReceiptAlign.right), 32).single.length, 16);
  });

  test('receipt codes: round trip, case, and a wrong check code', () {
    const id = '0192f5a0-1b2c-7d3e-8f40-123456789abc';
    final code = ReceiptCode.encode(id);
    expect(ReceiptCode.parse(code), id);
    expect(ReceiptCode.parse(code.toUpperCase()), id);
    expect(ReceiptCode.parse('${code.substring(0, code.length - 1)}0'), code.endsWith('0') ? id : isNull);
    expect(ReceiptCode.parse('ABY-R:${id.replaceFirst('0192', '0193')}:${code.split(':').last}'), isNull);
    expect(ReceiptCode.parse('6001234567890'), isNull);
  });

  test('ESC/POS: reset, drawer kick, raster images and the cut', () {
    final doc = ReceiptBuilder.testPage('Scoops Tamale', Paper.mm58, 'Counter');
    final bytes = EscPos.encode(doc, Paper.mm58, kickDrawer: true);
    expect(bytes.sublist(0, 2), EscPos.init);
    expect(bytes.sublist(2, 7), EscPos.drawerKick);
    expect(_contains(bytes, EscPos.feedAndCut), isTrue);
    expect(_contains(bytes, 'Aby printer test'.codeUnits), isTrue);
    // The QR code as GS v 0.
    expect(_contains(bytes, [0x1D, 0x76, 0x30, 0x00]), isTrue);
    expect(EscPos.encode(doc, Paper.mm58).sublist(2, 4), isNot(EscPos.drawerKick.sublist(0, 2)));
    expect(EscPos.kickOnly(), [...EscPos.init, ...EscPos.drawerKick]);
  });

  test('pictures become one-bit bitmaps no wider than the paper', () {
    final qr = MonoBitmap.qr('ABY-TEST', scale: 4);
    expect(qr.width, qr.height);
    expect(qr.dark(0, 0), isFalse, reason: 'quiet zone');
    expect(qr.dark(16, 16), isTrue, reason: 'corner finder pattern');

    final picture = img.Image(width: 800, height: 40);
    img.fill(picture, color: img.ColorRgb8(0, 0, 0));
    img.fillRect(picture, x1: 0, y1: 0, x2: 799, y2: 19, color: img.ColorRgb8(255, 255, 255));
    final bmp = MonoBitmap.picture(Uint8List.fromList(img.encodePng(picture)), maxWidth: 384)!;
    expect(bmp.width, 384);
    expect(bmp.dark(10, 2), isFalse);
    expect(bmp.dark(10, bmp.height - 2), isTrue);
    final raster = EscPos.raster(bmp);
    expect(raster.sublist(3, 11), [0x1D, 0x76, 0x30, 0x00, 48, 0, bmp.height, 0]);

    final logo = receiptLogo(Uint8List.fromList(img.encodePng(picture)))!;
    expect(img.decodePng(logo)!.width, lessThanOrEqualTo(384));
    expect(receiptLogo(Uint8List.fromList([1, 2, 3])), isNull);
  });

  ReceiptData sample({List<Payment>? payments}) => ReceiptData(
        saleId: '0192f5a0-1b2c-7d3e-8f40-123456789abc',
        number: 142,
        at: DateTime(2026, 10, 28, 14, 5),
        cashierName: 'Ama',
        customerName: 'Kofi',
        lines: const [
          ReceiptLine(name: 'Vanilla cone', variant: 'Large', quantity: 2, unitPrice: 1800, total: 3600, options: ['Sprinkles']),
          ReceiptLine(name: 'Groundnuts', quantity: 534, unitPrice: 2500, total: 1335, sellBy: SellBy.kg, discount: 135),
        ],
        subtotal: 4935,
        total: 4800,
        payments: payments ??
            const [Payment(id: 'p', method: PaymentMethod.cash, methodName: 'Cash', amount: 4800, tendered: 5000, changeGiven: 200)],
      );

  test('a sale receipt: lines, weights, discounts, payments, change and the QR code', () {
    const design = ReceiptDesign(shopName: 'Scoops Tamale', phone: '024 123 4567', footer: 'Thank you. Come again!', momoNumber: '055 000 1111');
    final doc = ReceiptBuilder.sale(sample(), design);
    final text = doc.toText(Paper.mm80);
    expect(text, contains('Receipt #00142'));
    expect(text, contains('28/10/2026 14:05'));
    expect(text, contains('2 x Vanilla cone (Large)'));
    expect(text, contains('  + Sprinkles'));
    expect(text, contains('0.534 kg @ 25.00'));
    expect(text, contains('Item discounts'));
    expect(text, contains('Cash given'));
    expect(text, contains('Change'));
    expect(text, contains('MoMo 055 000 1111'));
    expect(text, contains('Customer: Kofi'));
    expect(RegExp(r'TOTAL GHS\s+48\.00').hasMatch(text), isTrue);
    expect(doc.blocks.whereType<RQr>().single.data, ReceiptCode.encode(sample().saleId));

    final plain = ReceiptBuilder.sale(sample(), const ReceiptDesign(shopName: 'S', showCustomer: false, showQr: false));
    expect(plain.toText(Paper.mm58), isNot(contains('Kofi')));
    expect(plain.blocks.whereType<RQr>(), isEmpty);
    expect(ReceiptBuilder.sale(sample(), design, reprint: true).toText(Paper.mm58), contains('REPRINT'));
  });

  test('credit: two copies, and the shop copy has a line to sign', () {
    const design = ReceiptDesign(shopName: 'S', copies: {'credit': 2});
    final credit = sample(payments: const [Payment(id: 'p', method: PaymentMethod.credit, methodName: 'Credit', amount: 4800)]);
    expect(design.copiesFor(credit.payments.map((p) => p.method)), 2);
    expect(design.copiesFor([PaymentMethod.cash]), 1);
    final shop = ReceiptBuilder.sale(credit, design, copy: ReceiptCopy.shop).toText(Paper.mm58);
    expect(shop, contains('SHOP COPY'));
    expect(shop, contains('on credit. Signed:'));
    final customer = ReceiptBuilder.sale(credit, design, copy: ReceiptCopy.customer).toText(Paper.mm58);
    expect(customer, contains('CUSTOMER COPY'));
    expect(customer, isNot(contains('Signed')));
    expect(ReceiptDesign.decodeCopies('{"credit":2}'), {'credit': 2});
    expect(ReceiptDesign.decodeCopies('nonsense'), isEmpty);
  });

  test('X report on paper', () {
    const period = OpenPeriod(
      from: null,
      salesCount: 3,
      voidedCount: 1,
      salesTotal: 9000,
      byMethod: {PaymentMethod.cash: 6000, PaymentMethod.momo: 3000},
      suggestedFloat: 5000,
      payOuts: 1000,
      noSales: {'Ama': 2},
    );
    final text = ReceiptBuilder.period(period, title: 'X report', shopName: 'S', at: DateTime(2026, 10, 28), byName: 'Kofi', openingFloat: 5000)
        .toText(Paper.mm58);
    expect(text, contains('X REPORT'));
    expect(RegExp(r'Expected\s+100\.00').hasMatch(text), isTrue);
    expect(RegExp(r'Ama\s+2').hasMatch(text), isTrue);
  });

  test('the PDF builds', () async {
    final pdf = await ReceiptPdf.build(ReceiptBuilder.sale(sample(), const ReceiptDesign(shopName: 'S')));
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
  });

  test('printer targets round trip', () {
    const t = PrinterTarget(kind: PrinterKind.network, address: '192.168.1.50:9100');
    expect(PrinterTarget.decode(t.encode()), t);
    expect(PrinterTarget.decode(''), isNull);
    expect(PrinterTarget.decode('{bad'), isNull);
    expect(Paper.fromMillimetres(58), Paper.mm58);
  });
}
