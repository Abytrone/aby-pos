import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/csv.dart';
import '../core/period.dart';
import '../data/database/app_database.dart';
import '../models/expense.dart';
import '../models/report.dart';

/// The month-end pack for the accountant: one zip with CSVs of sales,
/// payments, expenses, purchases, tax and the stock valuation, plus a PDF
/// summary. Money in the files is GH₵ with two decimals.
class AccountantPack {
  AccountantPack(this._db);

  final AppDatabase _db;

  static String money(int pesewas) {
    final neg = pesewas < 0;
    final v = pesewas.abs();
    return '${neg ? '-' : ''}${v ~/ 100}.${(v % 100).toString().padLeft(2, '0')}';
  }

  static String day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String time(DateTime d) => '${day(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<List<List<String>>> _rows(String sql, List<String> header, DateRange r, List<String> Function(QueryRow) row,
      Set<ResultSetImplementation<dynamic, dynamic>> tables) async {
    final rows = await _db.customSelect(sql, variables: [Variable.withDateTime(r.from), Variable.withDateTime(r.to)], readsFrom: tables).get();
    return [header, for (final x in rows) row(x)];
  }

  DateTime _at(QueryRow x, String col) => DateTime.fromMillisecondsSinceEpoch(x.read<int>(col) * 1000);

  /// Builds the zip. [summary] and [pnl] are for the PDF.
  Future<Uint8List> build({
    required String shopName,
    required DateRange range,
    required SalesSummary summary,
    required ProfitAndLoss? pnl,
    required StockTaxFigures stockTax,
  }) async {
    final files = <String, List<List<String>>>{
      'sales.csv': await _rows(
        'SELECT s.number AS number, s.created_at AS at, s.status AS status, s.cashier_name AS cashier, '
        "COALESCE(c.name, '') AS customer, s.subtotal AS subtotal, s.discount_total AS discount, s.tax_total AS tax, "
        's.total AS total, s.rounding AS rounding FROM sales s LEFT JOIN customers c ON c.id = s.customer_id '
        'WHERE s.deleted_at IS NULL AND s.created_at >= ? AND s.created_at < ? ORDER BY s.created_at',
        ['sale', 'date', 'status', 'cashier', 'customer', 'subtotal', 'discount', 'tax', 'total', 'rounding'],
        range,
        (x) => [
          '${x.read<int>('number')}',
          time(_at(x, 'at')),
          x.read<String>('status'),
          x.read<String>('cashier'),
          x.read<String>('customer'),
          money(x.read<int>('subtotal')),
          money(x.read<int>('discount')),
          money(x.read<int>('tax')),
          money(x.read<int>('total')),
          money(x.read<int>('rounding')),
        ],
        {_db.sales, _db.customers},
      ),
      'payments.csv': await _rows(
        'SELECT s.number AS number, p.created_at AS at, COALESCE(p.method_name, p.method) AS method, p.amount AS amount, '
        "COALESCE(p.momo_reference, '') AS ref FROM payments p JOIN sales s ON s.id = p.sale_id "
        "WHERE s.status = 'completed' AND p.deleted_at IS NULL AND p.created_at >= ? AND p.created_at < ? ORDER BY p.created_at",
        ['sale', 'date', 'method', 'amount', 'reference'],
        range,
        (x) => ['${x.read<int>('number')}', time(_at(x, 'at')), x.read<String>('method'), money(x.read<int>('amount')), x.read<String>('ref')],
        {_db.payments, _db.sales},
      ),
      'refunds.csv': await _rows(
        'SELECT r.number AS number, r.created_at AS at, COALESCE(r.sale_number, 0) AS sale, r.total AS total, r.reason AS reason, '
        'r.staff_name AS staff FROM refunds r WHERE r.deleted_at IS NULL AND r.created_at >= ? AND r.created_at < ? ORDER BY r.created_at',
        ['refund', 'date', 'sale', 'total', 'reason', 'by'],
        range,
        (x) => [
          '${x.read<int>('number')}',
          time(_at(x, 'at')),
          x.read<int>('sale') == 0 ? '' : '${x.read<int>('sale')}',
          money(x.read<int>('total')),
          x.read<String>('reason'),
          x.read<String>('staff'),
        ],
        {_db.refunds},
      ),
      'expenses.csv': await _rows(
        "SELECT e.day AS day, c.name AS category, e.amount AS amount, e.paid_from AS source, COALESCE(e.note, '') AS note, "
        "COALESCE(s.name, '') AS supplier FROM expenses e JOIN expense_categories c ON c.id = e.category_id "
        'LEFT JOIN suppliers s ON s.id = e.supplier_id WHERE e.deleted_at IS NULL AND e.day >= ? AND e.day < ? ORDER BY e.day',
        ['date', 'category', 'amount', 'paid from', 'supplier', 'note'],
        range,
        (x) => [
          day(_at(x, 'day')),
          x.read<String>('category'),
          money(x.read<int>('amount')),
          x.read<String>('source'),
          x.read<String>('supplier'),
          x.read<String>('note'),
        ],
        {_db.expenses, _db.expenseCategories, _db.suppliers},
      ),
      'purchases.csv': await _rows(
        "SELECT r.number AS number, r.created_at AS at, COALESCE(s.name, '') AS supplier, COALESCE(r.invoice_ref, '') AS invoice, "
        'r.total AS total, r.paid_now AS paid FROM stock_receipts r LEFT JOIN suppliers s ON s.id = r.supplier_id '
        'WHERE r.deleted_at IS NULL AND r.created_at >= ? AND r.created_at < ? ORDER BY r.created_at',
        ['delivery', 'date', 'supplier', 'invoice', 'total', 'paid on delivery'],
        range,
        (x) => [
          'GRN-${x.read<int>('number').toString().padLeft(4, '0')}',
          time(_at(x, 'at')),
          x.read<String>('supplier'),
          x.read<String>('invoice'),
          money(x.read<int>('total')),
          money(x.read<int>('paid')),
        ],
        {_db.stockReceipts, _db.suppliers},
      ),
      'tax.csv': [
        ['tax', 'rate %', 'amount'],
        for (final (name, bp, amount) in stockTax.taxes) [name, (bp / 100).toStringAsFixed(2), money(amount)],
      ],
    };
    final stock = await _db.customSelect(
      'SELECT s.name AS name, s.unit AS unit, s.cost_milli AS cost, COALESCE((SELECT SUM(m.quantity_change) FROM stock_movements m '
      'WHERE m.stock_item_id = s.id AND m.deleted_at IS NULL), 0) AS qty FROM stock_items s WHERE s.deleted_at IS NULL ORDER BY s.name',
      readsFrom: {_db.stockItems, _db.stockMovements},
    ).get();
    files['stock_valuation.csv'] = [
      ['item', 'unit', 'on hand', 'cost per unit', 'value'],
      for (final x in stock)
        [
          x.read<String>('name'),
          x.read<String>('unit'),
          '${x.read<int>('qty')}',
          (x.read<int>('cost') / 100000).toStringAsFixed(5),
          money(x.read<int>('qty') <= 0 ? 0 : (x.read<int>('qty') * x.read<int>('cost') + 500) ~/ 1000),
        ],
    ];

    final archive = Archive();
    for (final MapEntry(key: name, value: rows) in files.entries) {
      final bytes = utf8.encode('﻿${Csv.encode(rows)}');
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    final pdf = await _summaryPdf(shopName, range, summary, pnl, stockTax);
    archive.addFile(ArchiveFile('summary.pdf', pdf.length, pdf));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<Uint8List> _summaryPdf(String shop, DateRange r, SalesSummary s, ProfitAndLoss? p, StockTaxFigures st) async {
    final doc = pw.Document(title: 'Summary', author: shop);
    String m(int v) => 'GHS ${money(v)}';
    pw.Widget row(String a, String b, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(a, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null)),
            pw.Text(b, style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null),
          ]),
        );
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text(shop, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Summary ${day(r.from)} to ${day(r.lastDay)}'),
        pw.SizedBox(height: 16),
        pw.Text('Sales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        row('Sales at menu prices', m(s.gross)),
        row('Discounts', m(-s.discounts)),
        row('Refunds', m(-s.refunds)),
        row('Net sales', m(s.net), bold: true),
        row('Tax in sales', m(s.tax)),
        row('Number of sales', '${s.count}'),
        if (p != null) ...[
          pw.SizedBox(height: 16),
          pw.Text('Profit and loss', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          row('Net sales (after tax)', m(p.netSales)),
          row('Cost of stock sold', m(-p.costOfGoods)),
          row('Gross profit', m(p.grossProfit), bold: true),
          for (final e in p.expenses.entries) row(e.key, m(-e.value)),
          row('Stock thrown away', m(-p.waste)),
          row('Stock count differences', m(p.countDifference)),
          row('Net profit', m(p.netProfit), bold: true),
          row('Owner drawings', m(p.drawings)),
          row('Owner capital put in', m(p.capital)),
        ],
        pw.SizedBox(height: 16),
        pw.Text('Tax', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        for (final (name, bp, amount) in st.taxes) row('$name ${(bp / 100).toStringAsFixed(2)}%', m(amount)),
        if (st.taxes.isEmpty) row('No tax charged', ''),
        pw.SizedBox(height: 16),
        row('Stock value at cost (now)', m(st.stockValue), bold: true),
        pw.SizedBox(height: 24),
        pw.Text('Made by Aby from the shop\'s own records. The CSV files have every line.',
            style: const pw.TextStyle(color: PdfColors.grey700)),
      ],
    ));
    return doc.save();
  }
}
