import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'documents/pdf_brand.dart';

import 'receipt/receipt_doc.dart';

/// One product's label: name, price and barcode, [count] times.
class LabelItem {
  const LabelItem({required this.name, required this.price, this.code, this.count = 1});

  final String name;

  /// Pesewas.
  final int price;
  final String? code;
  final int count;
}

/// A4 sheets of 24 (3 × 8, 70 × 37 mm, the common sticker sheet), one
/// 50 × 30 mm label per page for label printers, or stickers on the receipt
/// printer.
enum LabelFormat { sheet, roll, printer }

/// Shelf labels and price stickers (CAT-08), in the brand fonts with the
/// cedi sign (built-in fonts and "GHS" without a [PdfBrand]).
abstract final class Labels {
  static List<LabelItem> _expand(List<LabelItem> items) => [
        for (final i in items)
          for (var n = 0; n < i.count; n++) i,
      ];

  /// EAN-13, EAN-8 or UPC-A when [code] is a valid retail barcode (what a
  /// supplier printed), otherwise Code 128 (the shop's own "ABY00001").
  static pw.Barcode symbology(String code) {
    if (RegExp(r'^\d+$').hasMatch(code) && _checkDigitOk(code)) {
      switch (code.length) {
        case 13:
          return pw.Barcode.ean13();
        case 8:
          return pw.Barcode.ean8();
        case 12:
          return pw.Barcode.upcA();
      }
    }
    return pw.Barcode.code128();
  }

  /// The GS1 check: digits weighted 3, 1, 3... from the right.
  static bool _checkDigitOk(String digits) {
    var sum = 0;
    for (var i = 0; i < digits.length - 1; i++) {
      final d = digits.codeUnitAt(digits.length - 2 - i) - 48;
      sum += i.isEven ? d * 3 : d;
    }
    return (10 - sum % 10) % 10 == digits.codeUnitAt(digits.length - 1) - 48;
  }

  static pw.Widget _label(LabelItem i, PdfBrand brand, {required double width, required double height, String? shopName}) {
    final small = height < 32 * PdfPageFormat.mm;
    return pw.Container(
        width: width,
        height: height,
        padding: pw.EdgeInsets.fromLTRB(3 * PdfPageFormat.mm, 2.2 * PdfPageFormat.mm, 3 * PdfPageFormat.mm, 2 * PdfPageFormat.mm),
        child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (shopName != null && !small)
            pw.Text(shopName.toUpperCase(), maxLines: 1, style: brand.text(size: 5.5, weight: 700, color: PdfBrand.muted, spacing: 0.6)),
          pw.Text(i.name, maxLines: 2, style: brand.text(size: small ? 7.5 : 8.5, weight: 700, height: 0.5)),
          pw.Spacer(),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 3,
                height: small ? 11 : 13,
                margin: const pw.EdgeInsets.only(right: 4, bottom: 1.5),
                decoration: pw.BoxDecoration(color: PdfBrand.lime, borderRadius: pw.BorderRadius.circular(1.5))),
            pw.Text(brand.money(i.price), style: brand.text(size: small ? 13 : 15, weight: 900)),
            ],
          ),
            if (i.code != null) ...[
            pw.SizedBox(height: 2),
            pw.BarcodeWidget(
                barcode: symbology(i.code!),
                data: i.code!,
              height: height * (small ? 0.3 : 0.32),
              textStyle: brand.text(size: 6, figures: true),
            ),
          ],
        ],
      ),
    );
  }

  /// [shopName] goes small above each name on sheet labels.
  static Future<Uint8List> pdf(List<LabelItem> items, LabelFormat format, {PdfBrand? brand, String? shopName}) async {
    final b = brand ?? PdfBrand.plain();
    final doc = pw.Document(title: 'Labels', author: shopName ?? 'Aby', creator: 'Aby');
    final all = _expand(items);
    if (format == LabelFormat.roll) {
      const page = PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm);
      for (final i in all) {
        doc.addPage(pw.Page(pageFormat: page,
            theme: b.theme,
            build: (_) => _label(i, b, width: page.width, height: page.height)));
      }
    } else {
      const w = 70 * PdfPageFormat.mm, h = 37 * PdfPageFormat.mm;
      for (var start = 0; start < all.length; start += 24) {
        final sheet = all.sublist(start, start + 24 > all.length ? all.length : start + 24);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 0, marginRight: 0, marginTop: 0.5 * PdfPageFormat.mm, marginBottom: 0),
            theme: b.theme,
            build: (_) => pw.Wrap(children: [for (final i in sheet) _label(i, b, width: w, height: h, shopName: shopName)]),
        ));
      }
    }
    return doc.save();
  }

  /// One sticker per label for the receipt printer (thermal label paper).
  static List<ReceiptDoc> paper(List<LabelItem> items) => [
        for (final i in _expand(items))
          ReceiptDoc('Label ${i.name}', [
            RText(i.name, align: ReceiptAlign.center, bold: true),
            RText('GHS ${paperMoney(i.price)}', align: ReceiptAlign.center, bold: true, big: true),
            if (i.code != null) ...[RBarcode(i.code!), RText(i.code!, align: ReceiptAlign.center)],
          ]),
      ];
}
