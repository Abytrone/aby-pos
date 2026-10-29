import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import '../core/period.dart';
import '../data/database/app_database.dart';
import '../models/expense.dart';
import '../models/report.dart';
import 'documents/pdf_brand.dart';
import 'documents/table_doc.dart';
import 'documents/xlsx.dart';

/// The month-end pack for the accountant: one zip with CSVs of sales,
/// payments, expenses, purchases, tax and the stock valuation, the same
/// tables as one Excel workbook (accounts.xlsx), and a PDF summary. Money in
/// the files is GH₵ with two decimals.
class AccountantPack {
  AccountantPack(this._db);

  final AppDatabase _db;

  static String money(int pesewas) => plainMoney(pesewas);

  static String day(DateTime d) => isoDay(d);

  static String time(DateTime d) => '${day(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// The CSV files keep these headers: accountants' imports read them.
  static const csvHeaders = {
    'sales.csv': ['sale', 'date', 'status', 'cashier', 'customer', 'subtotal', 'discount', 'tax', 'total', 'rounding'],
    'payments.csv': ['sale', 'date', 'method', 'amount', 'reference'],
    'refunds.csv': ['refund', 'date', 'sale', 'total', 'reason', 'by'],
    'expenses.csv': ['date', 'category', 'amount', 'paid from', 'supplier', 'note'],
    'purchases.csv': ['delivery', 'date', 'supplier', 'invoice', 'total', 'paid on delivery'],
    'tax.csv': ['tax', 'rate %', 'amount'],
    'stock_valuation.csv': ['item', 'unit', 'on hand', 'cost per unit', 'value'],
  };

  Future<List<List<Object?>>> _rows(String sql,
    DateRange r,
    List<Object?> Function(QueryRow) row,
      Set<ResultSetImplementation<dynamic, dynamic>> tables) async {
    final rows = await _db.customSelect(sql, variables: [Variable.withDateTime(r.from), Variable.withDateTime(r.to)], readsFrom: tables).get();
    return [for (final x in rows) row(x)];
  }

  DateTime _at(QueryRow x, String col) => DateTime.fromMillisecondsSinceEpoch(x.read<int>(col) * 1000);

  /// Every table in the pack, keyed by its CSV file name.
  Future<Map<String, DocSheet>> tables(DateRange range, StockTaxFigures stockTax) async {
    const m = DocKind.money;
    final stock = await _db
        .customSelect(
          'SELECT s.name AS name, s.unit AS unit, s.cost_milli AS cost, COALESCE((SELECT SUM(m.quantity_change) FROM stock_movements m '
          'WHERE m.stock_item_id = s.id AND m.deleted_at IS NULL), 0) AS qty FROM stock_items s WHERE s.deleted_at IS NULL ORDER BY s.name',
          readsFrom: {_db.stockItems, _db.stockMovements},
        )
        .get();
    return {
      'sales.csv': DocSheet(
        name: 'Sales',
        columns: const [
          DocColumn('Sale', DocKind.count),
          DocColumn('Date', DocKind.dateTime),
          DocColumn('Status'),
          DocColumn('Cashier'),
          DocColumn('Customer'),
          DocColumn.total('Subtotal (GH₵)'),
          DocColumn.total('Discount (GH₵)'),
          DocColumn.total('Tax (GH₵)'),
          DocColumn.bars('Total (GH₵)'),
          DocColumn.total('Rounding (GH₵)'),
        ],
        rows: await _rows(
        'SELECT s.number AS number, s.created_at AS at, s.status AS status, s.cashier_name AS cashier, '
        "COALESCE(c.name, '') AS customer, s.subtotal AS subtotal, s.discount_total AS discount, s.tax_total AS tax, "
        's.total AS total, s.rounding AS rounding FROM sales s LEFT JOIN customers c ON c.id = s.customer_id '
        'WHERE s.deleted_at IS NULL AND s.created_at >= ? AND s.created_at < ? ORDER BY s.created_at',
          range,
        (x) => [
            x.read<int>('number'),
            _at(x, 'at'),
          x.read<String>('status'),
          x.read<String>('cashier'),
          x.read<String>('customer'),
            x.read<int>('subtotal'),
            x.read<int>('discount'),
            x.read<int>('tax'),
            x.read<int>('total'),
            x.read<int>('rounding'),
        ],
        {_db.sales, _db.customers},
      ),
        note: 'Every sale, voided ones included (see Status). Totals add up what the filter shows.',
      ),
      'payments.csv': DocSheet(
        name: 'Payments',
        columns: const [
          DocColumn('Sale', DocKind.count),
          DocColumn('Date', DocKind.dateTime),
          DocColumn('Method'),
          DocColumn.bars('Amount (GH₵)'),
          DocColumn('Reference'),
        ],
        rows: await _rows(
        'SELECT s.number AS number, p.created_at AS at, COALESCE(p.method_name, p.method) AS method, p.amount AS amount, '
        "COALESCE(p.momo_reference, '') AS ref FROM payments p JOIN sales s ON s.id = p.sale_id "
        "WHERE s.status = 'completed' AND p.deleted_at IS NULL AND p.created_at >= ? AND p.created_at < ? ORDER BY p.created_at",
        range,
        (x) => [x.read<int>('number'), _at(x, 'at'), x.read<String>('method'), x.read<int>('amount'), x.read<String>('ref')],
        {_db.payments, _db.sales},
      ),
      ),
      'refunds.csv': DocSheet(
        name: 'Refunds',
        columns: const [
          DocColumn('Refund', DocKind.count),
          DocColumn('Date', DocKind.dateTime),
          DocColumn('Sale', DocKind.count),
          DocColumn.total('Total (GH₵)'),
          DocColumn('Reason'),
          DocColumn('By'),
        ],
        rows: await _rows(
        'SELECT r.number AS number, r.created_at AS at, COALESCE(r.sale_number, 0) AS sale, r.total AS total, r.reason AS reason, '
        'r.staff_name AS staff FROM refunds r WHERE r.deleted_at IS NULL AND r.created_at >= ? AND r.created_at < ? ORDER BY r.created_at',
        range,
        (x) => [
            x.read<int>('number'),
            _at(x, 'at'),
          x.read<int>('sale') == 0 ? null : x.read<int>('sale'),
            x.read<int>('total'),
          x.read<String>('reason'),
          x.read<String>('staff'),
        ],
        {_db.refunds},
      ),
      ),
      'expenses.csv': DocSheet(
        name: 'Expenses',
        columns: const [
          DocColumn('Date', DocKind.date),
          DocColumn('Category'),
          DocColumn.bars('Amount (GH₵)'),
          DocColumn('Paid from'),
          DocColumn('Supplier'),
          DocColumn('Note'),
        ],
        rows: await _rows(
        "SELECT e.day AS day, c.name AS category, e.amount AS amount, e.paid_from AS source, COALESCE(e.note, '') AS note, "
        "COALESCE(s.name, '') AS supplier FROM expenses e JOIN expense_categories c ON c.id = e.category_id "
        'LEFT JOIN suppliers s ON s.id = e.supplier_id WHERE e.deleted_at IS NULL AND e.day >= ? AND e.day < ? ORDER BY e.day',
        range,
        (x) => [
            _at(x, 'day'),
          x.read<String>('category'),
            x.read<int>('amount'),
          x.read<String>('source'),
          x.read<String>('supplier'),
          x.read<String>('note'),
        ],
        {_db.expenses, _db.expenseCategories, _db.suppliers},
      ),
      ),
      'purchases.csv': DocSheet(
        name: 'Purchases',
        columns: const [
          DocColumn('Delivery'),
          DocColumn('Date', DocKind.dateTime),
          DocColumn('Supplier'),
          DocColumn('Invoice'),
          DocColumn.bars('Total (GH₵)'),
          DocColumn.total('Paid on delivery (GH₵)'),
        ],
        rows: await _rows(
        "SELECT r.number AS number, r.created_at AS at, COALESCE(s.name, '') AS supplier, COALESCE(r.invoice_ref, '') AS invoice, "
        'r.total AS total, r.paid_now AS paid FROM stock_receipts r LEFT JOIN suppliers s ON s.id = r.supplier_id '
        'WHERE r.deleted_at IS NULL AND r.created_at >= ? AND r.created_at < ? ORDER BY r.created_at',
        range,
        (x) => [
          'GRN-${x.read<int>('number').toString().padLeft(4, '0')}',
            _at(x, 'at'),
          x.read<String>('supplier'),
          x.read<String>('invoice'),
            x.read<int>('total'),
            x.read<int>('paid'),
        ],
        {_db.stockReceipts, _db.suppliers},
      ),
      ),
      'tax.csv': DocSheet(
        name: 'Tax',
        columns: const [DocColumn('Tax'), DocColumn('Rate %', DocKind.decimal), DocColumn.total('Amount (GH₵)', m)],
        rows: [
          for (final (name, bp, amount) in stockTax.taxes) [name, bp / 100, amount],
        ],
      ),
      'stock_valuation.csv': DocSheet(
        name: 'Stock valuation',
        columns: const [
          DocColumn('Item'),
          DocColumn('Unit'),
          DocColumn('On hand', DocKind.count),
          DocColumn('Cost per unit (GH₵)', DocKind.decimal, 5),
          DocColumn.bars('Value (GH₵)'),
        ],
        rows: [
          for (final x in stock)
        [
          x.read<String>('name'),
          x.read<String>('unit'),
              x.read<int>('qty'),
              x.read<int>('cost') / 100000,
              x.read<int>('qty') <= 0 ? 0 : (x.read<int>('qty') * x.read<int>('cost') + 500) ~/ 1000,
            ],
        ],
        note: 'Stock on hand now, at cost.',
      ),
    };
  }

  /// The summary: headline figures, then sales, profit and loss, and tax.
  static TableDoc summary({
    required String shopName,
    required DateRange range,
    required SalesSummary summary,
    required ProfitAndLoss? pnl,
    required StockTaxFigures stockTax,
    List<DocSheet> tables = const [],
  }) {
    const item = DocColumn('Item');
    const amount = DocColumn('Amount (GH₵)', DocKind.money);
    return TableDoc(
      title: 'Accounts',
      shopName: shopName,
      period: docPeriod(range.from, range.lastDay),
      facts: [
        DocFact('Net sales', summary.net),
        DocFact('Number of sales', summary.count, kind: DocKind.count),
        if (pnl != null) DocFact('Gross profit', pnl.grossProfit),
        if (pnl != null) DocFact('Net profit', pnl.netProfit),
        DocFact('Tax in sales', summary.tax),
        DocFact('Stock value at cost (now)', stockTax.stockValue),
      ],
      sheets: [
        DocSheet(
          name: 'Sales summary',
          columns: const [item, amount],
          rows: [
            ['Sales at menu prices', summary.gross],
            ['Discounts', -summary.discounts],
            ['Refunds', -summary.refunds],
            ['Net sales', summary.net],
            ['Tax in sales', summary.tax],
          ],
        ),
        if (pnl != null)
          DocSheet(
            name: 'Profit and loss',
            columns: const [item, amount],
            rows: [
              ['Net sales (after tax)', pnl.netSales],
              ['Cost of stock sold', -pnl.costOfGoods],
              ['Gross profit', pnl.grossProfit],
              for (final e in pnl.expenses.entries) [e.key, -e.value],
              ['Stock thrown away', -pnl.waste],
              ['Stock count differences', pnl.countDifference],
              ['Net profit', pnl.netProfit],
              ['Owner drawings', pnl.drawings],
              ['Owner capital put in', pnl.capital],
            ],
          ),
        DocSheet(
          name: 'Tax summary',
          columns: const [item, DocColumn('Rate %', DocKind.decimal), DocColumn.total('Amount (GH₵)')],
          rows: [
            for (final (name, bp, v) in stockTax.taxes) [name, bp / 100, v],
          ],
          note: stockTax.taxes.isEmpty ? 'No tax was charged.' : null,
        ),
        ...tables,
      ],
    );
  }

  /// Builds the zip. [summary] and [pnl] are for the summary.
  Future<Uint8List> build({
    required String shopName,
    required DateRange range,
    required SalesSummary summary,
    required ProfitAndLoss? pnl,
    required StockTaxFigures stockTax,
    PdfBrand? brand,
  }) async {
    final files = await tables(range, stockTax);

    final archive = Archive();
    void add(String name, List<int> bytes) => archive.addFile(ArchiveFile(name, bytes.length, bytes));
    for (final MapEntry(key: name, value: sheet) in files.entries) {
      add(name, utf8.encode('﻿${sheet.toCsv(headers: csvHeaders[name])}'));
    }
    final short = AccountantPack.summary(shopName: shopName, range: range, summary: summary, pnl: pnl, stockTax: stockTax);
    add('summary.pdf', await DocPdf.build(short, brand ?? PdfBrand.plain(), eyebrow: 'For the accountant'));
    final full = AccountantPack.summary(
      shopName: shopName,
      range: range,
      summary: summary,
      pnl: pnl,
      stockTax: stockTax,
      tables: [
        for (final e in files.entries)
          if (e.key != 'tax.csv') e.value,
      ],
    );
    add('accounts.xlsx', Xlsx.build(full));
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }
}
