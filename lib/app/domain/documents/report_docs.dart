import '../../core/period.dart';
import '../../data/repositories/time_repository.dart';
import '../../models/report.dart';
import 'table_doc.dart';

/// The figures on Manage → Reports for one period, for exports.
class ReportFigures {
  const ReportFigures({
    required this.shopName,
    required this.range,
    required this.sales,
    required this.before,
    this.hours = const [],
    this.products = const [],
    this.payments = const {},
    this.rounding = 0,
    this.staff = const [],
    this.customers = const CustomerFigures(),
    this.stockTax = const StockTaxFigures(),
    this.canSeeCost = false,
    this.commission = false,
  });

  final String shopName;
  final DateRange range;
  final SalesSummary sales;

  /// The period before, for the changes.
  final SalesSummary before;

  /// [weekday 0-6][hour 0-23] → pesewas.
  final List<List<int>> hours;
  final List<ProductFigures> products;
  final Map<String, int> payments;
  final int rounding;
  final List<StaffFigures> staff;
  final CustomerFigures customers;
  final StockTaxFigures stockTax;
  final bool canSeeCost;

  /// The shop pays commission, so staff exports show it.
  final bool commission;

  String get period => docPeriod(range.from, range.lastDay);
}

/// Reports as [TableDoc]s: the whole report as one workbook or PDF, or one
/// tab at a time.
abstract final class ReportDocs {
  static const _money = DocKind.money;

  /// "+12% on the period before", or null when there was nothing before.
  static String? change(int now, int before) {
    if (before == 0) return null;
    final pct = ((now - before) * 100 / before).round();
    return '${pct >= 0 ? '+' : ''}$pct% on the period before';
  }

  static List<DocFact> facts(ReportFigures f) {
    final s = f.sales, b = f.before;
    return [
      DocFact('Net sales', s.net, note: change(s.net, b.net)),
      DocFact('Sales', s.count, kind: DocKind.count, note: change(s.count, b.count)),
      DocFact('Average sale', s.averageSale, note: change(s.averageSale, b.averageSale)),
      DocFact('Items per sale', double.parse(s.itemsPerSale.toStringAsFixed(2)), kind: DocKind.decimal),
      DocFact('Discounts', s.discounts),
      DocFact('Refunds', s.refunds),
      DocFact('Tax in sales', s.tax),
      if (f.canSeeCost) DocFact('Stock value at cost (now)', f.stockTax.stockValue),
    ];
  }

  static DocSheet salesByDay(ReportFigures f) => DocSheet(
        name: 'Sales by day',
        columns: const [DocColumn('Date', DocKind.date), DocColumn.bars('Net sales (GH₵)')],
        rows: [for (final (d, v) in f.sales.series) [d, v]],
        chart: 1,
        note: f.sales.series.length > 62 ? 'Each row is a week or a month.' : null,
      );

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// Sales by hour and weekday, shaded like the heat map on screen. Only
  /// the hours the shop sold in.
  static DocSheet busyTimes(ReportFigures f) {
    final grid = f.hours.length == 7 ? f.hours : List.generate(7, (_) => List.filled(24, 0));
    final open = [for (var h = 0; h < 24; h++) if (grid.any((d) => d[h] > 0)) h];
    return DocSheet(
      name: 'Busy times',
      columns: [
        const DocColumn('Hour'),
        for (final d in _days) DocColumn.heat('$d (GH₵)'),
        const DocColumn.bars('All week (GH₵)'),
      ],
      rows: [
        if (open.isNotEmpty)
          for (var h = open.first; h <= open.last; h++)
            ['${h.toString().padLeft(2, '0')}:00', for (final d in grid) d[h], grid.fold<int>(0, (s, d) => s + d[h])],
      ],
      note: 'Net sales started in each hour. The darker the cell, the busier.',
    );
  }

  static DocSheet products(ReportFigures f) => DocSheet(
        name: 'Products',
        columns: [
          const DocColumn('Product'),
          const DocColumn('Category'),
          const DocColumn.total('Sold', DocKind.count),
          const DocColumn.bars('Revenue (GH₵)'),
          if (f.canSeeCost) ...const [DocColumn.total('Cost (GH₵)'), DocColumn.total('Profit (GH₵)'), DocColumn('Margin', DocKind.percent)],
          const DocColumn('Grade'),
        ],
        rows: [
          for (final p in f.products)
            [p.name, p.category, p.quantity, p.revenue, if (f.canSeeCost) ...[p.cost, p.profit, p.marginPercent], p.grade],
        ],
        note: 'Grade A: the products bringing the first 80% of revenue; B the next 15%; C the rest.',
      );

  static DocSheet categories(ReportFigures f) {
    final by = <String, int>{};
    for (final p in f.products) {
      by[p.category] = (by[p.category] ?? 0) + p.revenue;
    }
    final rows = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return DocSheet(
      name: 'By category',
      columns: const [DocColumn('Category'), DocColumn.bars('Revenue (GH₵)')],
      rows: [for (final e in rows) [e.key.isEmpty ? 'No category' : e.key, e.value]],
    );
  }

  static DocSheet payments(ReportFigures f) {
    final total = f.payments.values.fold(0, (s, v) => s + v);
    return DocSheet(
      name: 'Payments',
      columns: const [DocColumn('Method'), DocColumn.bars('Amount (GH₵)'), DocColumn('Share', DocKind.percent)],
      rows: [for (final e in f.payments.entries) [e.key, e.value, total == 0 ? null : (e.value * 1000 / total).round() / 10]],
      note: f.rounding == 0 ? null : 'Cash rounding: GH₵ ${plainMoney(f.rounding)}',
    );
  }

  static DocSheet staff(ReportFigures f) => DocSheet(
        name: 'Staff',
        columns: [
          const DocColumn('Name'),
          const DocColumn.total('Sales', DocKind.count),
          const DocColumn.bars('Total (GH₵)'),
          const DocColumn('Average (GH₵)', _money),
          const DocColumn.total('Items', DocKind.count),
          const DocColumn.total('Discounts (GH₵)'),
          const DocColumn.total('Voids', DocKind.count),
          const DocColumn.total('Refunds', DocKind.count),
          const DocColumn.total('No-sales', DocKind.count),
          const DocColumn.total('Times short', DocKind.count),
          const DocColumn.total('Short by (GH₵)'),
          const DocColumn.total('Hours', DocKind.minutes),
          if (f.commission) const DocColumn.total('Commission (GH₵)'),
        ],
        rows: [
          for (final s in f.staff)
            [
              s.name, s.sales, s.total, s.average, s.items, s.discounts, s.voids, s.refunds, s.noSales, s.shorts, s.shortTotal,
              s.minutesWorked, if (f.commission) s.commission,
            ],
        ],
      );

  static DocSheet customers(ReportFigures f) {
    final c = f.customers;
    return DocSheet(
      name: 'Customers',
      columns: const [DocColumn('Customer'), DocColumn.bars('Spent (GH₵)')],
      rows: [for (final (name, v) in c.top) [name, v]],
      note: 'New customers: ${c.newCustomers}. Returning: ${c.returning}. Owed now: GH₵ ${plainMoney(c.owed)} '
          '(GH₵ ${plainMoney(c.overdue)} late). In wallets: GH₵ ${plainMoney(c.wallets)}.',
    );
  }

  static DocSheet tax(ReportFigures f) => DocSheet(
        name: 'Tax',
        columns: const [DocColumn('Tax'), DocColumn('Rate %', DocKind.decimal), DocColumn.total('Amount (GH₵)')],
        rows: [for (final (name, bp, v) in f.stockTax.taxes) [name, bp / 100, v]],
      );

  static const _reasons = {
    'sale': 'Sold',
    'restock': 'Received',
    'waste': 'Thrown away',
    'adjustment': 'Adjusted',
    'count': 'Counted',
    'returned': 'Returned',
    'production': 'Made',
    'transferOut': 'Sent to a branch',
    'transferIn': 'From a branch',
  };

  /// Stock movements, waste and count differences, at cost.
  static List<DocSheet> stock(ReportFigures f) {
    final s = f.stockTax;
    return [
      DocSheet(
        name: 'Stock movements',
        columns: const [DocColumn('Movement'), DocColumn.total('Value at cost (GH₵)')],
        rows: [for (final e in s.movements.entries) [_reasons[e.key] ?? e.key, e.value]],
      ),
      if (s.waste.isNotEmpty)
        DocSheet(
          name: 'Waste',
          columns: const [DocColumn('Item'), DocColumn.bars('Value lost (GH₵)')],
          rows: [for (final (n, v) in s.waste) [n, v]],
        ),
      if (s.countDifferences.isNotEmpty)
        DocSheet(
          name: 'Count differences',
          columns: const [DocColumn('Item'), DocColumn.total('Found (+) or missing (-) (GH₵)')],
          rows: [for (final (n, v) in s.countDifferences) [n, v]],
        ),
    ];
  }

  /// Every tab of the report in one document.
  static TableDoc full(ReportFigures f) => TableDoc(
        title: 'Shop report',
        shopName: f.shopName,
        period: f.period,
        facts: facts(f),
        sheets: [
          salesByDay(f),
          busyTimes(f),
          products(f),
          categories(f),
          payments(f),
          staff(f),
          customers(f),
          tax(f),
          if (f.canSeeCost) ...stock(f),
        ],
      );

  static TableDoc salesDoc(ReportFigures f) =>
      TableDoc(title: 'Sales report', shopName: f.shopName, period: f.period, facts: facts(f), sheets: [salesByDay(f)]);

  static TableDoc productsDoc(ReportFigures f) =>
      TableDoc(title: 'Products report', shopName: f.shopName, period: f.period, sheets: [products(f), categories(f)]);

  static TableDoc staffDoc(ReportFigures f) => TableDoc(title: 'Staff report', shopName: f.shopName, period: f.period, sheets: [staff(f)]);

  /// Timesheets, one section per person with their total. Hours read
  /// "7:30" and add up in Excel.
  static TableDoc timesheet(List<TimesheetEntry> entries, {required String shopName, required DateRange range, DateTime? now}) {
    final sorted = [...entries]..sort((a, b) {
        final byName = a.staffName.toLowerCase().compareTo(b.staffName.toLowerCase());
        return byName != 0 ? byName : a.clockIn.compareTo(b.clockIn);
      });
    return TableDoc(
      title: 'Timesheet',
      shopName: shopName,
      period: docPeriod(range.from, range.lastDay),
      sheets: [
        DocSheet(
          name: 'Timesheet',
          columns: const [
            DocColumn('Name'),
            DocColumn('In', DocKind.dateTime),
            DocColumn('Out', DocKind.dateTime),
            DocColumn.total('Break', DocKind.minutes),
            DocColumn.bars('Worked', DocKind.minutes),
            DocColumn.total('Late', DocKind.minutes),
            DocColumn.total('Left early', DocKind.minutes),
          ],
          rows: [
            for (final e in sorted)
              [e.staffName, e.clockIn, e.clockOut, e.breakMinutes, e.workedMinutes(now), e.lateMinutes, e.earlyMinutes],
          ],
          groupBy: 0,
          note: 'Hours and minutes. Still clocked in: worked until now.',
        ),
      ],
    );
  }
}
