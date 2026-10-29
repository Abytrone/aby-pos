import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../receipt/receipt_doc.dart' show paperMoney;
import 'table_doc.dart';

/// The Aby look on paper: Figtree for words, JetBrains Mono for figures,
/// midnight and lime, the cedi sign, and the pieces every A4 document is
/// made of (title band, figures, tables, charts, footer).
///
/// [PdfBrand.plain] uses the PDF's built-in fonts, for tests and in case the
/// app's fonts cannot be read; money then reads "GHS".
class PdfBrand {
  PdfBrand({
    required this.sans,
    required this.sansSemi,
    required this.sansBold,
    required this.sansBlack,
    required this.mono,
    required this.monoBold,
    this.extra = const [],
    this.extraBold = const [],
    this.mark,
    this.markReversed,
  });

  PdfBrand.plain()
      : sans = pw.Font.helvetica(),
        sansSemi = pw.Font.helveticaBold(),
        sansBold = pw.Font.helveticaBold(),
        sansBlack = pw.Font.helveticaBold(),
        mono = pw.Font.courier(),
        monoBold = pw.Font.courierBold(),
        extra = const [],
        extraBold = const [],
        mark = null,
        markReversed = null;

  final pw.Font sans, sansSemi, sansBold, sansBlack, mono, monoBold;

  /// Fallbacks with the cedi sign and Ghanaian letters (ɛ, ɔ, ŋ...), which
  /// Figtree and JetBrains Mono don't have.
  final List<pw.Font> extra, extraBold;

  /// The Aby mark as SVG, for the footer, and in chalk for dark grounds.
  final String? mark, markReversed;

  static final midnight = PdfColor.fromInt(0xFF101322);
  static final lime = PdfColor.fromInt(0xFFC8F560);
  static final limeSoft = PdfColor.fromInt(0xFFECFBC9);
  static final limeInk = PdfColor.fromInt(0xFF3F5A00);
  static final chalk = PdfColor.fromInt(0xFFF6F7F2);
  static final sunken = PdfColor.fromInt(0xFFECEDE6);
  static final line = PdfColor.fromInt(0xFFDFE1D8);
  static final ink = PdfColor.fromInt(0xFF101322);
  static final muted = PdfColor.fromInt(0xFF5A5E6B);
  static final danger = PdfColor.fromInt(0xFFC2361B);
  static final dangerSoft = PdfColor.fromInt(0xFFFFE6DF);
  static final white = PdfColor.fromInt(0xFFFFFFFF);

  bool get hasCedi => extra.isNotEmpty;
  String get currency => hasCedi ? 'GH₵' : 'GHS';

  /// "GH₵ 1,234.50".
  String money(int pesewas) => pesewas < 0 ? '-$currency ${paperMoney(-pesewas)}' : '$currency ${paperMoney(pesewas)}';

  pw.ThemeData get theme => pw.ThemeData.withFont(base: sans, bold: sansBold, fontFallback: extra);

  /// [weight]: 400, 600, 700 or 900.
  pw.TextStyle text({double size = 9.5, int weight = 400, PdfColor? color, bool figures = false, double? spacing, double? height}) {
    final bold = weight >= 700;
    return pw.TextStyle(
      font: figures ? (bold ? monoBold : mono) : (switch (weight) { >= 900 => sansBlack, >= 700 => sansBold, >= 600 => sansSemi, _ => sans }),
      fontBold: figures ? monoBold : sansBold,
      fontFallback: weight >= 600 ? extraBold : extra,
      fontSize: size,
      color: color ?? ink,
      letterSpacing: spacing,
      lineSpacing: height,
    );
  }

  pw.PageTheme page({bool landscape = false, PdfPageFormat format = PdfPageFormat.a4}) => pw.PageTheme(
        pageFormat: landscape ? format.landscape : format.portrait,
        margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 26),
        theme: theme,
      );

  /// The midnight title band at the top of the first page. [eyebrow] is a
  /// small lime word above the title ("PURCHASE ORDER"). The shop's own
  /// logo sits on the right when there is one.
  pw.Widget band({required String title, String? eyebrow, String? subtitle, String? shopName, Uint8List? logo, List<String> lines = const []}) =>
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(20, 16, 16, 16),
        decoration: pw.BoxDecoration(color: midnight, borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              if (shopName != null) pw.Text(shopName, style: text(size: 10, weight: 600, color: chalk)),
              for (final l in lines) pw.Text(l, style: text(size: 8.5, color: PdfColor.fromInt(0xFFB9BCC8))),
              if (shopName != null || lines.isNotEmpty) pw.SizedBox(height: 10),
              if (eyebrow != null) pw.Text(eyebrow.toUpperCase(), style: text(size: 8, weight: 700, color: lime, spacing: 1.2)),
              pw.Text(title, style: text(size: 22, weight: 900, color: chalk, spacing: -0.4)),
              if (subtitle != null) ...[
                pw.SizedBox(height: 3),
                pw.Text(subtitle, style: text(size: 10, color: lime)),
              ],
            ]),
          ),
          if (logo != null)
            pw.Container(
              width: 64,
              height: 64,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(color: white, borderRadius: pw.BorderRadius.circular(8)),
              child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
            )
          else if (markReversed != null)
            pw.SvgImage(svg: markReversed!, width: 36, height: 36),
        ]),
      );

  /// A slim heading on the pages after the first.
  pw.Widget runningHeader(pw.Context context, String title, String? subtitle) => context.pageNumber == 1
      ? pw.SizedBox()
      : pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.only(bottom: 5),
          decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: lime, width: 2))),
          child: pw.Row(children: [
            pw.Expanded(child: pw.Text(title, style: text(size: 9, weight: 700))),
            if (subtitle != null) pw.Text(subtitle, style: text(size: 8, color: muted)),
          ]),
        );

  /// "Made with Aby", when it was made, and the page number.
  pw.Widget footer(pw.Context context, DateTime madeAt) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: line, width: 0.6))),
        child: pw.Row(children: [
          if (mark != null) ...[pw.SvgImage(svg: mark!, width: 9, height: 9), pw.SizedBox(width: 4)],
          pw.Text('Made with Aby', style: text(size: 7.5, weight: 600, color: muted)),
          pw.Text('  ·  ${docTime(madeAt)}', style: text(size: 7.5, color: muted)),
          pw.Spacer(),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: text(size: 7.5, color: muted, figures: true)),
        ]),
      );

  /// A section heading with a lime tick.
  pw.Widget heading(String title, {String? note}) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(children: [
            pw.Container(width: 4, height: 14, decoration: pw.BoxDecoration(color: lime, borderRadius: pw.BorderRadius.circular(2))),
            pw.SizedBox(width: 7),
            pw.Text(title, style: text(size: 13, weight: 700)),
          ]),
          if (note != null) pw.Padding(padding: const pw.EdgeInsets.only(left: 11, top: 2), child: pw.Text(note, style: text(size: 8.5, color: muted))),
        ]),
      );

  /// Headline figures as tiles; the first one in lime.
  pw.Widget facts(List<DocFact> facts) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14),
        child: pw.Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < facts.length; i++)
            pw.Container(
              width: 124,
              padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 9),
              decoration: pw.BoxDecoration(
                color: i == 0 ? lime : chalk,
                borderRadius: pw.BorderRadius.circular(8),
                border: i == 0 ? null : pw.Border.all(color: line, width: 0.8),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(facts[i].label.toUpperCase(), maxLines: 1, style: text(size: 6.5, weight: 700, color: i == 0 ? ink : muted, spacing: 0.6)),
                pw.SizedBox(height: 3),
                pw.Text(value(facts[i].value, facts[i].kind, symbol: true), maxLines: 1, style: text(size: 13, weight: 900)),
                if (facts[i].note != null)
                  pw.Text(facts[i].note!, maxLines: 1, style: text(size: 7, weight: 600, color: facts[i].note!.startsWith('-') ? danger : limeInk)),
              ]),
            ),
        ]),
      );

  /// A value as text. [symbol] adds the currency to money.
  String value(Object? v, DocKind kind, {int decimals = 2, bool symbol = false}) {
    if (v == null) return '';
    String grouped(String digits) => digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return switch (kind) {
      DocKind.money when v is num => symbol ? money(v.round()) : paperMoney(v.round()),
      DocKind.count when v is num => (v < 0 ? '-' : '') + grouped('${v.abs().round()}'),
      DocKind.decimal when v is num => () {
          final s = v.abs().toStringAsFixed(decimals).split('.');
          return '${v < 0 ? '-' : ''}${grouped(s.first)}${s.length > 1 ? '.${s.last}' : ''}';
        }(),
      DocKind.percent when v is num => '${v == v.roundToDouble() ? v.round() : v.toStringAsFixed(1)}%',
      DocKind.date when v is DateTime => docDay(v),
      DocKind.dateTime when v is DateTime => docTime(v),
      DocKind.minutes when v is int => docMinutes(v),
      _ => '$v',
    };
  }

  /// [sheet] as a table: midnight header repeated on each page, zebra rows,
  /// lime bars or shading where the columns ask for them, and a lime totals
  /// row. With [DocSheet.groupBy], one table per group under a subheading.
  List<pw.Widget> table(DocSheet sheet) {
    if (sheet.rows.isEmpty) {
      return [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(color: chalk, borderRadius: pw.BorderRadius.circular(6)),
          child: pw.Text('Nothing in this period.', style: text(color: muted)),
        ),
      ];
    }
    final group = sheet.groupBy;
    final shown = [for (var i = 0; i < sheet.columns.length; i++) if (i != group) i];
    final widths = {for (var k = 0; k < shown.length; k++) k: pw.FlexColumnWidth(_flex(sheet, shown[k]))};
    final maxima = {for (final i in shown) if (sheet.columns[i].bar || sheet.columns[i].heat) i: sheet.maxOf(i)};

    pw.Widget cell(Object? v, int i, {bool bold = false, PdfColor? background}) {
      final col = sheet.columns[i];
      final numeric = col.kind.figures && v != 'Total';
      final negative = v is num && v < 0;
      // A dash for no money, as accountants write it (and as Excel shows it).
      final none = col.kind == DocKind.money && v == 0 && !bold;
      final label = pw.Text(
        none ? '–' : value(v, col.kind, decimals: col.decimals),
        textAlign: numeric ? pw.TextAlign.right : pw.TextAlign.left,
        style: text(size: 8.5, weight: bold ? 700 : 400, figures: numeric, color: negative ? danger : null),
      );
      final max = maxima[i];
      final share = col.bar && v is num && max != null && max > 0 && !bold ? (v.clamp(0, max) * 1000 / max).round() : null;
      final content = share == null
          ? label
          : pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              label,
              pw.SizedBox(height: 2),
              pw.Row(children: [
                if (share < 1000) pw.Spacer(flex: 1000 - share),
                pw.Expanded(
                  flex: share < 1 ? 1 : share,
                  child: pw.Container(
                    height: 2.5,
                    decoration: pw.BoxDecoration(color: share < 1 ? null : lime, borderRadius: pw.BorderRadius.circular(1)),
                  ),
                ),
              ]),
            ]);
      final shade = col.heat && v is num && max != null && max > 0 && v > 0 ? _mix(white, lime, v / max) : null;
      return pw.Container(
        color: shade ?? background,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4.5),
        alignment: numeric ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: content,
      );
    }

    pw.Widget build(List<List<Object?>> rows, {required bool totals}) => pw.Table(
          columnWidths: widths,
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
          children: [
            pw.TableRow(
              repeat: true,
              decoration: pw.BoxDecoration(color: midnight),
              children: [
                for (final i in shown)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    alignment: sheet.columns[i].kind.figures ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                    child: pw.Text(
                      sheet.columns[i].header,
                      textAlign: sheet.columns[i].kind.figures ? pw.TextAlign.right : pw.TextAlign.left,
                      style: text(size: 7.5, weight: 700, color: chalk, spacing: 0.2),
                    ),
                  ),
              ],
            ),
            for (var r = 0; r < rows.length; r++)
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: r.isOdd ? chalk : white,
                  border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.5)),
                ),
                children: [for (final i in shown) cell(rows[r][i], i)],
              ),
            if (totals && sheet.hasTotals)
              pw.TableRow(
                decoration: pw.BoxDecoration(color: limeSoft, border: pw.Border(top: pw.BorderSide(color: midnight, width: 1.2))),
                children: [
                  for (final (k, i) in shown.indexed)
                    k == 0 && sheet.columns[i].total == false
                        ? cell('Total', i, bold: true)
                        : cell(sheet.columns[i].total ? _sum(rows, i) : null, i, bold: true),
                ],
              ),
          ],
        );

    if (group == null) return [build(sheet.rows, totals: true)];
    final out = <pw.Widget>[];
    var start = 0;
    for (var r = 1; r <= sheet.rows.length; r++) {
      if (r < sheet.rows.length && sheet.rows[r][group] == sheet.rows[start][group]) continue;
      final rows = sheet.rows.sublist(start, r);
      final name = '${rows.first[group] ?? ''}';
      out
        ..add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
          child: pw.Text(name.isEmpty ? 'Other' : name, style: text(size: 10, weight: 700, color: limeInk)),
        ))
        ..add(build(rows, totals: sheet.hasTotals));
      start = r;
    }
    return out;
  }

  static num _sum(List<List<Object?>> rows, int i) => rows.fold<num>(0, (s, r) => s + (r[i] is num ? r[i] as num : 0));

  static double _flex(DocSheet s, int i) {
    final col = s.columns[i];
    if (col.kind == DocKind.text) {
      final longest = s.rows.fold(col.header.length ~/ 2, (m, r) => '${r[i] ?? ''}'.length > m ? '${r[i] ?? ''}'.length : m);
      return longest.clamp(6, 34).toDouble();
    }
    return switch (col.kind) {
      DocKind.dateTime => 9,
      DocKind.date => 7,
      DocKind.money => 8,
      DocKind.percent => 5,
      _ => 6,
    };
  }

  static PdfColor _mix(PdfColor a, PdfColor b, num t) {
    final f = t.clamp(0, 1).toDouble();
    return PdfColor(a.red + (b.red - a.red) * f, a.green + (b.green - a.green) * f, a.blue + (b.blue - a.blue) * f);
  }

  /// Column [sheet.chart] as bars, labelled by the first column. For a
  /// series over time.
  pw.Widget chart(DocSheet sheet) {
    final i = sheet.chart!;
    final values = [for (final r in sheet.rows) r[i] is num ? (r[i] as num).toDouble() : 0.0];
    final top = values.fold(0.0, (m, v) => v > m ? v : m);
    if (values.isEmpty || top <= 0) return pw.SizedBox();
    final step = (values.length / 8).ceil();
    String label(Object? v) => v is DateTime ? '${v.day}/${v.month}' : '${v ?? ''}';
    const height = 96.0;
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.fromLTRB(10, 10, 10, 6),
      decoration: pw.BoxDecoration(color: chalk, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        pw.Text('Highest: ${value(top, sheet.columns[i].kind, symbol: true)}', style: text(size: 7, color: muted)),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          height: height,
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            for (final v in values)
              pw.Expanded(
                child: pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: values.length > 40 ? 0.5 : 1.5),
                  child: pw.Container(
                    height: v <= 0 ? 0.6 : (v / top * height).clamp(1.5, height),
                    decoration: pw.BoxDecoration(
                      color: v == top ? midnight : lime,
                      borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(1.5)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        pw.Container(height: 0.8, color: midnight),
        pw.SizedBox(height: 3),
        // Each label gets the room of the [step] bars it stands for.
        pw.Row(children: [
          for (var r = 0; r < values.length; r += step)
            pw.Expanded(
              flex: values.length - r < step ? values.length - r : step,
              child: pw.Text(label(sheet.rows[r][0]), maxLines: 1, style: text(size: 6, color: muted, figures: true)),
            ),
        ]),
      ]),
    );
  }
}

/// A [TableDoc] as a branded A4 PDF: title band and headline figures on
/// the first page, then each table as a section. A table too wide for
/// portrait gets landscape pages of its own.
abstract final class DocPdf {
  static Future<Uint8List> build(TableDoc doc, PdfBrand brand, {Uint8List? logo, String? eyebrow}) async {
    final pdf = pw.Document(title: doc.title, author: doc.shopName, creator: 'Aby');
    // Runs of tables that share an orientation share pages.
    final runs = <(bool, List<DocSheet>)>[];
    for (final s in doc.sheets) {
      final wide = doc.isWide(s);
      if (runs.isNotEmpty && runs.last.$1 == wide) {
        runs.last.$2.add(s);
      } else {
        runs.add((wide, [s]));
      }
    }
    if (runs.isEmpty) runs.add((doc.landscape ?? false, []));
    final headings = doc.sheets.length > 1 || doc.facts.isNotEmpty;
    for (final (i, (wide, sheets)) in runs.indexed) {
      pdf.addPage(pw.MultiPage(
        pageTheme: brand.page(landscape: wide),
        header: (context) => brand.runningHeader(context, doc.title, doc.subtitle),
        footer: (context) => brand.footer(context, doc.madeAt),
        build: (_) => [
          if (i == 0) brand.band(title: doc.title, eyebrow: eyebrow, subtitle: doc.period, shopName: doc.shopName, logo: logo),
          if (i == 0 && doc.facts.isNotEmpty) brand.facts(doc.facts),
          for (final s in sheets) ...[
            if (headings || s.note != null) brand.heading(s.name, note: s.note) else pw.SizedBox(height: 14),
            if (s.chart != null && s.rows.length > 1) brand.chart(s),
            ...brand.table(s),
          ],
        ],
      ));
    }
    return pdf.save();
  }
}
