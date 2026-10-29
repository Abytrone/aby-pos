import 'dart:convert';
import 'dart:io';

import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/domain/documents/pdf_brand.dart';
import 'package:aby_pos/app/domain/documents/report_docs.dart';
import 'package:aby_pos/app/domain/documents/table_doc.dart';
import 'package:aby_pos/app/domain/documents/xlsx.dart';
import 'package:aby_pos/app/domain/labels.dart';
import 'package:aby_pos/app/models/report.dart';
import 'package:aby_pos/app/services/pdf_brand_loader.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;

TableDoc sample() => TableDoc(
      title: 'Sales report',
      shopName: 'Scoops & Co, Tamale',
      period: docPeriod(DateTime(2026, 10, 1), DateTime(2026, 10, 31)),
      madeAt: DateTime(2026, 10, 29, 14, 5),
      facts: const [
        DocFact('Net sales', 1234550, note: '+12% on the period before'),
        DocFact('Sales', 412, kind: DocKind.count),
        DocFact('Refunds', -2500, note: '-3%'),
      ],
      sheets: [
        DocSheet(
          name: 'Sales by day',
          columns: const [DocColumn('Day', DocKind.date), DocColumn.bars('Net sales (GH₵)')],
          rows: [for (var d = 1; d <= 31; d++) [DateTime(2026, 10, d), d * 1375 % 9000 + 500]],
          chart: 1,
        ),
        DocSheet(
          name: 'Products',
          columns: const [
            DocColumn('Category'),
            DocColumn('Product'),
            DocColumn.total('Sold', DocKind.count),
            DocColumn.bars('Revenue (GH₵)'),
            DocColumn('Margin', DocKind.percent),
            DocColumn('Hours', DocKind.minutes),
            DocColumn.heat('Heat', DocKind.count),
          ],
          rows: const [
            ['Drinks', 'Sobolo <large> & "cold"', 12, 4500, 42, 450, 3],
            ['Drinks', 'Ɔdɔ ɛnyɛ', 3, 900, null, 0, 9],
            ['Ice cream', 'Waffle', 7, 8400, 51.5, 75, 0],
          ],
          groupBy: 0,
          note: 'A: the products bringing the first 80% of revenue.',
        ),
        const DocSheet(name: 'Empty', columns: [DocColumn('Name')], rows: []),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CSV is the plain table: cedis, ISO dates, no totals', () {
    final csv = sample().sheets[1].toCsv();
    expect(csv.split('\r\n').first, 'Category,Product,Sold,Revenue (GH₵),Margin,Hours,Heat');
    expect(csv, contains('Drinks,"Sobolo <large> & ""cold""",12,45.00,42,450,3'));
    expect(csv, contains('Ice cream,Waffle,7,84.00,51.5,75,0'));
    expect(sample().sheets.first.toCsv(), contains('2026-10-01,'));
  });

  test('totals add up the totalled columns only', () {
    final t = sample().sheets[1].totals;
    expect(t, [null, null, 22, 13800, null, null, null]);
  });

  test('the workbook has a summary, a tab per table and live totals', () {
    final zip = ZipDecoder().decodeBytes(Xlsx.build(sample()));
    String part(String name) => utf8.decode(zip.files.firstWhere((f) => f.name == name).content);
    expect(zip.files.map((f) => f.name), containsAll(['[Content_Types].xml', 'xl/workbook.xml', 'xl/styles.xml', 'xl/sharedStrings.xml']));
    final book = part('xl/workbook.xml');
    expect(book, contains('<sheet name="Summary"'));
    expect(book, contains('<sheet name="Sales by day"'));
    expect(book, contains('_xlnm.Print_Titles'));
    final products = part('xl/worksheets/sheet3.xml');
    expect(products, contains('<f>SUBTOTAL(109,D6:D8)</f><v>138.00</v>'));
    expect(products, contains('<autoFilter ref="A5:G8"/>'));
    expect(products, contains('type="dataBar"'));
    expect(products, contains('type="colorScale"'));
    expect(products, contains('state="frozen"'));
    expect(part('xl/sharedStrings.xml'), contains('Sobolo &lt;large&gt; &amp; &quot;cold&quot;'));
    // 1 Oct 2026 is day 46296 counting from Excel's 1900 epoch.
    expect(part('xl/worksheets/sheet2.xml'), contains('<v>46296</v>'));
  });

  test('a PDF is made with the plain fonts and with the brand fonts', () async {
    final plain = await DocPdf.build(sample(), PdfBrand.plain());
    expect(String.fromCharCodes(plain.sublist(0, 5)), '%PDF-');
    final brand = await loadPdfBrand();
    expect(brand.hasCedi, isTrue, reason: 'the fonts are in the asset bundle');
    expect(brand.money(-123456), '-GH₵ 1,234.56');
    final pdf = await DocPdf.build(sample(), brand);
    expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');

    // ABY_DOC_OUT=/some/folder flutter test ... to look at the files.
    final out = Platform.environment['ABY_DOC_OUT'];
    if (out != null) {
      File('$out/sample.pdf').writeAsBytesSync(pdf);
      File('$out/sample.xlsx').writeAsBytesSync(Xlsx.build(sample()));
    }
  });

  test('labels use EAN-13, EAN-8 or UPC-A only for valid retail codes', () {
    expect(Labels.symbology('6034000123456').name, pw.Barcode.ean13().name);
    expect(Labels.symbology('6034000123457').name, pw.Barcode.code128().name, reason: 'wrong check digit');
    expect(Labels.symbology('96385074').name, pw.Barcode.ean8().name);
    expect(Labels.symbology('036000291452').name, pw.Barcode.upcA().name);
    expect(Labels.symbology('ABY00001').name, pw.Barcode.code128().name);
  });

  test('the whole report: figures, a tab per table, cost only for those allowed', () {
    final range = DateRange(DateTime(2026, 10), DateTime(2026, 11));
    final hours = List.generate(7, (_) => List.filled(24, 0));
    hours[3][9] = 1500;
    hours[3][11] = 500;
    ReportFigures figures({required bool cost}) => ReportFigures(
          shopName: 'S',
          range: range,
          sales: SalesSummary(gross: 12000, count: 3, series: [(DateTime(2026, 10, 1), 12000)]),
          before: const SalesSummary(gross: 10000, count: 2),
          hours: hours,
          products: const [ProductFigures(productId: 'p', name: 'Waffle', category: 'Snacks', quantity: 3, revenue: 12000, cost: 4000, grade: 'A')],
          payments: const {'Cash': 9000, 'MoMo': 3000},
          stockTax: const StockTaxFigures(stockValue: 50000, movements: {'sale': -4000}),
          canSeeCost: cost,
        );
    final doc = ReportDocs.full(figures(cost: true));
    expect(doc.period, '1 Oct 2026 – 31 Oct 2026');
    expect(doc.facts.first.note, '+20% on the period before');
    expect(doc.sheets.map((s) => s.name), containsAll(['Sales by day', 'Busy times', 'Products', 'Payments', 'Stock movements']));
    final busy = doc.sheets.firstWhere((s) => s.name == 'Busy times');
    expect(busy.rows.map((r) => r.first), ['09:00', '10:00', '11:00'], reason: 'only the hours the shop sold in');
    expect(busy.rows.first.last, 1500);
    expect(doc.sheets.firstWhere((s) => s.name == 'Payments').rows.first.last, 75);

    final plain = ReportDocs.full(figures(cost: false));
    expect(plain.sheets.map((s) => s.name), isNot(contains('Stock movements')));
    expect(plain.sheets.firstWhere((s) => s.name == 'Products').columns.map((c) => c.header), isNot(contains('Cost (GH₵)')));
    expect(plain.facts.map((f) => f.label), isNot(contains('Stock value at cost (now)')));
  });
}
