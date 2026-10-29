import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

import '../core/units.dart';
import '../models/purchasing.dart';
import 'documents/pdf_brand.dart';
import 'documents/table_doc.dart';

/// A purchase order as an A4 PDF, to send to the supplier by WhatsApp or
/// email.
abstract final class PurchaseOrderPdf {
  static Future<Uint8List> build(PurchaseOrder o, {required String shopName, String? shopPhone, String? shopAddress,
    PdfBrand? brand,
    Uint8List? logo,
  }) async {
    final b = brand ?? PdfBrand.plain();
    final made = DateTime.now();
    final doc = pw.Document(title: 'Purchase order ${o.displayNumber}', author: shopName, creator: 'Aby');
    final items = DocSheet(
      name: 'Items',
      columns: [const DocColumn('Item'), const DocColumn('Quantity', DocKind.count), DocColumn.total('Expected price (${b.currency})')],
      rows: [
            for (final l in o.lines)
              [
                l.name,
                formatQuantity(l.quantity, l.unit),
                l.estimate == 0 ? null : l.estimate],
      ],
    );
    pw.Widget box(String label, List<String> lines) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(color: PdfBrand.chalk, borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(), style: b.text(size: 6.5, weight: 700, color: PdfBrand.muted, spacing: 0.6)),
            pw.SizedBox(height: 3),
            pw.Text(lines.first, style: b.text(size: 11, weight: 700)),
            // Every box two lines high, so they line up.
            pw.Text(lines.length > 1 ? lines[1] : ' ', style: b.text(size: 8.5, color: PdfBrand.muted)),
          ],
        ),
      ),
    );
    doc.addPage(
      pw.MultiPage(
        pageTheme: b.page(),
        header: (context) => b.runningHeader(context, 'Purchase order ${o.displayNumber}', shopName),
        footer: (context) => b.footer(context, made),
        build: (_) => [
          b.band(
            eyebrow: 'Purchase order',
            title: o.displayNumber,
            shopName: shopName,
            lines: [
              if (shopAddress != null && shopAddress.isNotEmpty) shopAddress,
              if (shopPhone != null && shopPhone.isNotEmpty) shopPhone,
            ],
            logo: logo,
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              box('To', [o.supplierName, ?o.supplierPhone]),
              pw.SizedBox(width: 8),
              box('Ordered', [docDay(o.at), 'By ${o.byName}']),
        if (o.expectedOn != null) ...[
          pw.SizedBox(width: 8),
                box('Needed by', [docDay(o.expectedOn!)]),
              ],
            ],
          ),
          pw.SizedBox(height: 14),
          ...b.table(o.estimate > 0 ? items : DocSheet(name: items.name, columns: items.columns.sublist(0, 2), rows: items.rows)),
        if (o.note != null) ...[pw.SizedBox(height: 12), pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfBrand.lime, width: 3)),
              ),
              child: pw.Text(o.note!, style: b.text()),
            )],
        pw.SizedBox(height: 20),
        pw.Text('Thank you.', style: b.text(color: PdfBrand.muted)),
      ],
    ));
    return doc.save();
  }
}
