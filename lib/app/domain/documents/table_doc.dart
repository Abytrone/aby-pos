import '../../core/csv.dart';

/// What a column holds. It decides the number format in Excel, the
/// alignment and font in PDFs, and the text in CSVs.
enum DocKind {
  text,

  /// Pesewas (int). Excel and CSV show cedis with two decimals.
  money,

  /// Whole numbers (int).
  count,

  /// A number with [DocColumn.decimals] places.
  decimal,

  /// Whole percent (num): 42 is 42%.
  percent,
  date,
  dateTime,

  /// Minutes (int). Excel shows hours and minutes ("7:30") so they add up.
  minutes;

  bool get numeric => this != text;

  /// Figures: right-aligned, in the figures font. Dates read as words.
  bool get figures => numeric && this != date && this != dateTime;
}

class DocColumn {
  const DocColumn(this.header, [this.kind = DocKind.text, this.decimals = 2]) : total = false, bar = false, heat = false;

  /// Adds up in a totals row (Excel keeps it live, filters included).
  const DocColumn.total(this.header, [this.kind = DocKind.money, this.decimals = 2]) : total = true, bar = false, heat = false;

  /// A totalled column drawn with a lime bar for each value: the eye finds
  /// the big ones first.
  const DocColumn.bars(this.header, [this.kind = DocKind.money, this.decimals = 2]) : total = true, bar = true, heat = false;

  /// Shaded from paper to lime by value, like the hours heat map.
  const DocColumn.heat(this.header, [this.kind = DocKind.money, this.decimals = 2]) : total = false, bar = false, heat = true;

  final String header;
  final DocKind kind;
  final int decimals;
  final bool total;
  final bool bar;
  final bool heat;
}

/// One table: a tab in Excel, a section in a PDF, a CSV file.
class DocSheet {
  const DocSheet({
    required this.name,
    required this.columns,
    required this.rows,
    this.note,
    this.chart,
    this.groupBy,
  });

  /// The tab name. Excel allows 31 characters.
  final String name;
  final List<DocColumn> columns;

  /// One value per column: String, int, num, DateTime or null (blank).
  final List<List<Object?>> rows;

  /// A line under the section heading in a PDF, and under the table in Excel.
  final String? note;

  /// A column to draw as a bar chart above the table in a PDF, labelled by
  /// the first column. For a series over time (sales by day).
  final int? chart;

  /// PDFs show rows under a heading each time this column's value changes,
  /// and leave the column out. [rows] must be sorted by it.
  final int? groupBy;

  bool get hasTotals => columns.any((c) => c.total);

  /// The sum of each totalled column; null for the others.
  List<num?> get totals => [
        for (var i = 0; i < columns.length; i++)
          columns[i].total ? rows.fold<num>(0, (s, r) => s + (r[i] is num ? r[i] as num : 0)) : null,
      ];

  /// The biggest value in column [i], for bars and shading.
  num maxOf(int i) => rows.fold<num>(0, (m, r) => r[i] is num && (r[i] as num) > m ? r[i] as num : m);

  num minOf(int i) => rows.fold<num>(0, (m, r) => r[i] is num && (r[i] as num) < m ? r[i] as num : m);

  /// The table as CSV: a header row and the data, no totals (so it imports
  /// cleanly elsewhere). Money is cedis with two decimals, dates are
  /// yyyy-mm-dd. [headers] replace the column headers, for files other
  /// software already reads.
  String toCsv({List<String>? headers}) => Csv.encode([
        headers ?? [for (final c in columns) c.header],
        for (final r in rows) [for (var i = 0; i < columns.length; i++) csvValue(r[i], columns[i])],
      ]);

  static String csvValue(Object? v, DocColumn c) {
    if (v == null) return '';
    return switch (c.kind) {
      DocKind.money when v is int => plainMoney(v),
      DocKind.decimal when v is num => v.toStringAsFixed(c.decimals),
      DocKind.date when v is DateTime => isoDay(v),
      DocKind.dateTime when v is DateTime => '${isoDay(v)} ${_two(v.hour)}:${_two(v.minute)}',
      DocKind.percent when v is num => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1),
      _ => '$v',
    };
  }
}

/// A headline number: big on the first page of a PDF, and on the Summary
/// tab in Excel.
class DocFact {
  const DocFact(this.label, this.value, {this.kind = DocKind.money, this.note});

  final String label;

  /// int pesewas for money, otherwise as in [DocKind].
  final Object value;
  final DocKind kind;

  /// "+12% on the period before".
  final String? note;
}

/// A report, list or export: the same thing becomes an Excel workbook, a
/// PDF or CSV.
class TableDoc {
  TableDoc({
    required this.title,
    required this.shopName,
    this.period,
    this.facts = const [],
    required this.sheets,
    this.landscape,
    DateTime? madeAt,
  }) : madeAt = madeAt ?? DateTime.now();

  /// "Products report".
  final String title;
  final String shopName;

  /// "1 Oct 2026 – 31 Oct 2026", when the figures cover a period.
  final String? period;
  final List<DocFact> facts;
  final List<DocSheet> sheets;

  /// PDF orientation; by default each table is landscape when it is too
  /// wide for portrait.
  final bool? landscape;
  final DateTime madeAt;

  bool isWide(DocSheet s) => landscape ?? s.columns.length - (s.groupBy == null ? 0 : 1) > 7;

  /// "Products report, Scoops Tamale, 1 Oct 2026 – 31 Oct 2026"
  String get subtitle => [shopName, ?period].join('  ·  ');
}

String _two(int v) => v.toString().padLeft(2, '0');

String isoDay(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "1234.50": cedis for spreadsheets, no thousands separator.
String plainMoney(int pesewas) {
  final neg = pesewas < 0;
  final v = pesewas.abs();
  return '${neg ? '-' : ''}${v ~/ 100}.${_two(v % 100)}';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "1 Oct 2026", for headings on paper.
String docDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String docTime(DateTime d) => '${docDay(d)}, ${_two(d.hour)}:${_two(d.minute)}';

/// "1 Oct 2026 – 31 Oct 2026", or one day.
String docPeriod(DateTime first, DateTime last) =>
    isoDay(first) == isoDay(last) ? docDay(first) : '${docDay(first)} – ${docDay(last)}';

/// "7:30" for 450 minutes.
String docMinutes(int minutes) => '${minutes ~/ 60}:${_two(minutes.abs() % 60)}';

/// A safe file name: "Purchase order PO-0012" → "Purchase-order-PO-0012".
String docFileStem(String title) => title.trim().replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
