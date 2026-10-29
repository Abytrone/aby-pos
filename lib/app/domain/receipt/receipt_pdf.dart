import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../documents/pdf_brand.dart';
import 'receipt_doc.dart';

/// A receipt as a PDF on an 80 mm roll, for sending by WhatsApp or the share
/// sheet. A fixed-width font matches the printed layout: JetBrains Mono from
/// [brand], or the built-in Courier (both are 0.6 em wide).
abstract final class ReceiptPdf {
  static Future<Uint8List> build(ReceiptDoc doc, {String author = 'Aby', PdfBrand? brand}) async {
    const paper = Paper.mm80;
    final pdf = pw.Document(title: doc.title, author: author, creator: 'Aby');
    final regular = brand?.mono ?? pw.Font.courier();
    final bold = brand?.monoBold ?? pw.Font.courierBold();
    // 48 characters across the 72 mm printable width.
    const size = 72 * PdfPageFormat.mm / 48 / 0.6;
    pw.Widget text(String line, {bool strong = false, bool big = false}) => pw.Text(
          line.isEmpty ? ' ' : line,
          style: pw.TextStyle(font: strong ? bold : regular, fontSize: big ? size * 2 : size, lineSpacing: 0),
        );
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80.copyWith(marginLeft: 4 * PdfPageFormat.mm, marginRight: 4 * PdfPageFormat.mm),
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        for (final b in doc.blocks)
          switch (b) {
            RQr(:final data) => pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6),
                  child: pw.BarcodeWidget(barcode: pw.Barcode.qrCode(), data: data, width: 90, height: 90),
                ),
              ),
            RImage(:final png) => pw.Center(child: pw.Image(pw.MemoryImage(png), width: 120)),
            RBarcode(:final data) => pw.Center(
                child: pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: data, width: 140, height: 40, drawText: false),
              ),
            RText(:final bold, :final big) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [for (final l in layout(b, paper.chars)) text(l, strong: bold, big: big)],
              ),
            RRow(:final bold) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [for (final l in layout(b, paper.chars)) text(l, strong: bold)],
              ),
            RRule() || RFeed() => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [for (final l in layout(b, paper.chars)) text(l)],
              ),
          },
      ]),
    ));
    return pdf.save();
  }
}
