import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

import '../core/units.dart';
import '../models/purchasing.dart';
import 'documents/pdf_brand.dart';
import 'documents/table_doc.dart';

/// A delivery as an A4 goods received note: what came, at what cost, what
/// was paid and what is owed. For the shop's files, the accountant, or to
/// send the supplier.
abstract final class DeliveryPdf {
  static Future<Uint8List> build(
    DeliveryDetail d, {
    required String shopName,
    String? shopPhone,
    String? shopAddress,
    PdfBrand? brand,
    Uint8List? logo,
  }) async {
    final b = brand ?? PdfBrand.plain();
    final r = d.receipt;
    final made = DateTime.now();
    final doc = pw.Document(title: 'Goods received ${r.displayNumber}', author: shopName, creator: 'Aby');
    final items = DocSheet(
      name: 'Items',
      columns: [
        const DocColumn('Item'),
        const DocColumn('Quantity', DocKind.count),
        const DocColumn('Unit'),
        DocColumn('Unit cost (${b.currency})', DocKind.money),
        DocColumn.total('Total (${b.currency})'),
      ],
      rows: [
        for (final l in d.lines)
          [
            l.name,
            quantityIn(l.quantity, DisplayUnit.bulk(l.unit)),
            DisplayUnit.bulk(l.unit).symbol,
            priceForUnit(l.unitCostMilli, DisplayUnit.bulk(l.unit)),
            l.lineTotal,
          ],
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
    pw.Widget money(String label, int pesewas, {bool strong = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(label, style: b.text(weight: strong ? 700 : 400))),
            pw.Text(b.money(pesewas), style: b.text(weight: strong ? 700 : 400)),
          ]),
        );
    doc.addPage(
      pw.MultiPage(
        pageTheme: b.page(),
        header: (context) => b.runningHeader(context, 'Goods received ${r.displayNumber}', shopName),
        footer: (context) => b.footer(context, made),
        build: (_) => [
          b.band(
            eyebrow: 'Goods received note',
            title: r.displayNumber,
            shopName: shopName,
            lines: [
              if (shopAddress != null && shopAddress.isNotEmpty) shopAddress,
              if (shopPhone != null && shopPhone.isNotEmpty) shopPhone,
            ],
            logo: logo,
          ),
          pw.SizedBox(height: 14),
          pw.Row(children: [
            box('From', [r.supplierName ?? 'No supplier', ?d.supplierPhone]),
            pw.SizedBox(width: 8),
            box('Received', [docDay(r.at), 'By ${r.receivedByName}']),
            if (r.invoiceRef != null || d.orderNumber != null) ...[
              pw.SizedBox(width: 8),
              box(r.invoiceRef != null ? 'Invoice' : 'Order', [
                r.invoiceRef ?? d.orderNumber!,
                if (r.invoiceRef != null && d.orderNumber != null) 'Order ${d.orderNumber}',
              ]),
            ],
          ]),
          pw.SizedBox(height: 14),
          ...b.table(items),
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(children: [
                money('Delivery total', r.total, strong: true),
                money('Paid', r.paidNow),
                if (r.owed > 0) money('Owed to the supplier', r.owed, strong: true),
              ]),
            ),
          ),
          if (d.note != null) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(color: PdfBrand.lime, width: 3))),
              child: pw.Text(d.note!, style: b.text()),
            ),
          ],
          pw.SizedBox(height: 28),
          pw.Row(children: [
            pw.Expanded(child: pw.Text('Received by: ______________________', style: b.text(color: PdfBrand.muted))),
            pw.Expanded(child: pw.Text('Delivered by: ______________________', style: b.text(color: PdfBrand.muted))),
          ]),
        ],
      ),
    );
    return doc.save();
  }
}
