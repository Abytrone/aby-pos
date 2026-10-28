import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

/// Shelf labels and price stickers (CAT-08). PDFs use the built-in fonts,
/// which have no cedi sign, so prices read "GHS 12.00".
abstract final class Labels {
  static List<LabelItem> _expand(List<LabelItem> items) => [
        for (final i in items)
          for (var n = 0; n < i.count; n++) i,
      ];

  static pw.Widget _label(LabelItem i, {required double width, required double height}) => pw.Container(
        width: width,
        height: height,
        padding: const pw.EdgeInsets.all(2 * PdfPageFormat.mm),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(i.name, maxLines: 2, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text('GHS ${paperMoney(i.price)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (i.code != null)
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: i.code!,
                width: width * 0.8,
                height: height * 0.32,
                textStyle: const pw.TextStyle(fontSize: 7),
              ),
          ],
        ),
      );

  static Future<Uint8List> pdf(List<LabelItem> items, LabelFormat format) async {
    final doc = pw.Document(title: 'Labels', author: 'Aby');
    final all = _expand(items);
    if (format == LabelFormat.roll) {
      const page = PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm);
      for (final i in all) {
        doc.addPage(pw.Page(pageFormat: page, build: (_) => _label(i, width: page.width, height: page.height)));
      }
    } else {
      const w = 70 * PdfPageFormat.mm, h = 37 * PdfPageFormat.mm;
      for (var start = 0; start < all.length; start += 24) {
        final sheet = all.sublist(start, start + 24 > all.length ? all.length : start + 24);
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 0, marginRight: 0, marginTop: 0.5 * PdfPageFormat.mm, marginBottom: 0),
          build: (_) => pw.Wrap(children: [for (final i in sheet) _label(i, width: w, height: h)]),
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
