import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/units.dart';
import '../models/purchasing.dart';
import 'receipt/receipt_doc.dart';

/// A purchase order as an A4 PDF, to send to the supplier by WhatsApp or
/// email. Built-in fonts: prices read "GHS".
abstract final class PurchaseOrderPdf {
  static String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static Future<Uint8List> build(PurchaseOrder o, {required String shopName, String? shopPhone, String? shopAddress}) async {
    final doc = pw.Document(title: 'Purchase order ${o.displayNumber}', author: shopName);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text(shopName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        if (shopAddress != null && shopAddress.isNotEmpty) pw.Text(shopAddress),
        if (shopPhone != null && shopPhone.isNotEmpty) pw.Text(shopPhone),
        pw.SizedBox(height: 16),
        pw.Text('Purchase order ${o.displayNumber}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('To: ${o.supplierName}${o.supplierPhone == null ? '' : '  (${o.supplierPhone})'}'),
        pw.Text('Date: ${_date(o.at)}${o.expectedOn == null ? '' : '   Needed by: ${_date(o.expectedOn!)}'}'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Quantity', 'Expected price'],
          data: [
            for (final l in o.lines)
              [
                l.name,
                formatQuantity(l.quantity, l.unit),
                l.estimate == 0 ? '' : 'GHS ${paperMoney(l.estimate)}',
              ],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignments: {1: pw.Alignment.centerRight, 2: pw.Alignment.centerRight},
          border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
        if (o.estimate > 0) ...[
          pw.SizedBox(height: 8),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('About GHS ${paperMoney(o.estimate)}')),
        ],
        if (o.note != null) ...[pw.SizedBox(height: 12), pw.Text(o.note!)],
        pw.SizedBox(height: 24),
        pw.Text('Ordered by ${o.byName}. Thank you.', style: const pw.TextStyle(color: PdfColors.grey700)),
      ],
    ));
    return doc.save();
  }
}
