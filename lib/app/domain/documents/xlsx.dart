import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'table_doc.dart';

/// A [TableDoc] as an Excel workbook in the Aby colours: a midnight title
/// band with a lime stripe, a frozen header with filters, totals that stay
/// right when you filter (SUBTOTAL), lime data bars, and A4 print setup
/// that repeats the header on every page. Opens in Excel, Google Sheets,
/// Numbers and LibreOffice.
abstract final class Xlsx {
  static const _midnight = 'FF101322';
  static const _lime = 'FFC8F560';
  static const _limeSoft = 'FFECFBC9';
  static const _chalk = 'FFF6F7F2';
  static const _line = 'FFDFE1D8';
  static const _ink = 'FF101322';
  static const _muted = 'FF5A5E6B';
  static const _blue = 'FF3446E0';
  static const _white = 'FFFFFFFF';

  /// The header row of each table sheet (1-based).
  static const headerRow = 5;

  static Uint8List build(TableDoc doc) {
    final styles = _Styles();
    final strings = _Strings();
    final names = _sheetNames(doc);
    final sheets = <String>[];
    final defined = <String>[];
    var index = 0;
    if (doc.facts.isNotEmpty) {
      sheets.add(_summary(doc, names, styles, strings));
      index++;
    }
    for (final s in doc.sheets) {
      sheets.add(_table(doc, s, styles, strings, selected: index == 0));
      final name = _quoted(names[index]);
      final last = _col(s.columns.length - 1);
      if (s.rows.isNotEmpty) {
        defined.add('<definedName name="_xlnm._FilterDatabase" localSheetId="$index" hidden="1">'
            '${_esc("$name!\$A\$$headerRow:\$$last\$${headerRow + s.rows.length}")}</definedName>');
      }
      defined.add('<definedName name="_xlnm.Print_Titles" localSheetId="$index">${_esc('$name!\$$headerRow:\$$headerRow')}</definedName>');
      index++;
    }

    final files = <String, String>{
      '[Content_Types].xml': _contentTypes(sheets.length),
      '_rels/.rels': _rootRels,
      'docProps/app.xml': '$_decl<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">'
          '<Application>Aby</Application></Properties>',
      'docProps/core.xml': _core(doc),
      'xl/workbook.xml': '$_decl<workbook xmlns="$_main" xmlns:r="$_rel"><workbookPr/>'
          '<bookViews><workbookView activeTab="0"/></bookViews><sheets>'
          '${[for (var i = 0; i < names.length; i++) '<sheet name="${_esc(names[i])}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
          '</sheets>${defined.isEmpty ? '' : '<definedNames>${defined.join()}</definedNames>'}</workbook>',
      'xl/_rels/workbook.xml.rels': _workbookRels(sheets.length),
      'xl/styles.xml': styles.xml(),
      'xl/sharedStrings.xml': strings.xml(),
      for (var i = 0; i < sheets.length; i++) 'xl/worksheets/sheet${i + 1}.xml': sheets[i],
    };
    final archive = Archive();
    for (final MapEntry(key: path, value: xml) in files.entries) {
      final bytes = utf8.encode(xml);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Tab names: at most 31 characters, none of []:*?/\ and all different.
  static List<String> _sheetNames(TableDoc doc) {
    final out = <String>[];
    for (final raw in [if (doc.facts.isNotEmpty) 'Summary', for (final s in doc.sheets) s.name]) {
      var base = raw.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
      if (base.isEmpty) base = 'Sheet';
      if (base.length > 31) base = base.substring(0, 31);
      var name = base;
      for (var n = 2; out.any((o) => o.toLowerCase() == name.toLowerCase()); n++) {
        final suffix = ' ($n)';
        name = '${base.length + suffix.length > 31 ? base.substring(0, 31 - suffix.length) : base}$suffix';
      }
      out.add(name);
    }
    return out;
  }

  /// The title band shared by every sheet: rows 1 to 3.
  static String _band(TableDoc doc, String heading, int width, _Styles st, _Strings str) {
    final title = st.xf(font: st.font(size: 18, bold: true, color: _chalk), fill: st.fill(_midnight), v: 'center', indent: 1);
    final sub = st.xf(font: st.font(size: 11, color: _lime), fill: st.fill(_midnight), v: 'top', indent: 1);
    final stripe = st.xf(fill: st.fill(_lime));
    String row(int r, double height, int style, [String? text]) => '<row r="$r" ht="$height" customHeight="1">'
        '${[for (var c = 0; c < width; c++) c == 0 && text != null ? _str(c, r, style, text, str) : '<c r="${_col(c)}$r" s="$style"/>'].join()}'
        '</row>';
    return row(1, 34, title, heading) + row(2, 22, sub, doc.subtitle) + row(3, 4.5, stripe);
  }

  static String _summary(TableDoc doc, List<String> names, _Styles st, _Strings str) {
    final label = st.xf(font: st.font(size: 10.5, color: _muted), v: 'center', indent: 1, border: st.border(bottom: _line));
    final note = st.xf(font: st.font(size: 10, italic: true, color: _muted), v: 'center', border: st.border(bottom: _line));
    final heading = st.xf(font: st.font(size: 12, bold: true), v: 'bottom', indent: 1);
    final link = st.xf(font: st.font(size: 10.5, color: _blue, underline: true), indent: 1);
    final rows = StringBuffer(_band(doc, doc.title, 4, st, str));
    var r = headerRow;
    rows.write('<row r="$r" ht="22" customHeight="1">${_str(0, r, heading, 'Summary', str)}</row>');
    for (final f in doc.facts) {
      r++;
      final value = st.xf(
        font: st.font(size: 13, bold: true),
        numFmt: st.numFmt(f.kind),
        h: 'right',
        v: 'center',
        border: st.border(bottom: _line),
      );
      rows.write('<row r="$r" ht="24" customHeight="1">${_str(0, r, label, f.label, str)}'
          '${_value(1, r, value, f.value, f.kind, str)}'
          '${f.note == null ? '<c r="C$r" s="$note"/>' : _str(2, r, note, '  ${f.note!}', str)}</row>');
    }
    final links = <String>[];
    if (doc.sheets.isNotEmpty) {
      r += 2;
      rows.write('<row r="$r" ht="22" customHeight="1">${_str(0, r, heading, 'In this workbook', str)}</row>');
      for (var i = 0; i < doc.sheets.length; i++) {
        r++;
        final name = names[i + 1];
        rows.write('<row r="$r">${_str(0, r, link, name, str)}</row>');
        links.add('<hyperlink ref="A$r" location="${_esc("${_quoted(name)}!A1")}" display="${_esc(name)}"/>');
      }
    }
    r += 2;
    rows.write(_madeRow(doc, r, st, str));
    return _sheetXml(
      tab: _lime,
      selected: true,
      cols: [32, 20, 34, 4],
      data: rows.toString(),
      freezeRow: null,
      extra: links.isEmpty ? '' : '<hyperlinks>${links.join()}</hyperlinks>',
      doc: doc,
      landscape: false,
      lastCell: 'D$r',
    );
  }

  static String _madeRow(TableDoc doc, int r, _Styles st, _Strings str) {
    final made = st.xf(font: st.font(size: 9, italic: true, color: _muted), indent: 1);
    return '<row r="$r">${_str(0, r, made, 'Made with Aby  ·  ${docTime(doc.madeAt)}', str)}</row>';
  }

  static String _table(TableDoc doc, DocSheet s, _Styles st, _Strings str, {required bool selected}) {
    final n = s.columns.length;
    final rows = StringBuffer(_band(doc, '${doc.title}${s.name == doc.title ? '' : '  ·  ${s.name}'}', n < 6 ? 6 : n, st, str));
    rows.write('<row r="4" ht="8" customHeight="1"/>');

    final headerFont = st.font(size: 10, bold: true, color: _chalk);
    final headerFill = st.fill(_midnight);
    rows.write('<row r="$headerRow" ht="26" customHeight="1">');
    for (var c = 0; c < n; c++) {
      final col = s.columns[c];
      final style = st.xf(font: headerFont, fill: headerFill, h: col.kind.figures ? 'right' : 'left', v: 'center', wrap: true, indent: 1);
      rows.write(_str(c, headerRow, style, col.header, str));
    }
    rows.write('</row>');

    final body = st.font(size: 10.5);
    final zebra = st.fill(_chalk);
    final rule = st.border(bottom: _line);
    for (var i = 0; i < s.rows.length; i++) {
      final r = headerRow + 1 + i;
      final fill = i.isOdd ? zebra : 0;
      rows.write('<row r="$r" ht="19" customHeight="1">');
      for (var c = 0; c < n; c++) {
        final col = s.columns[c];
        final style = st.xf(
          font: body,
          fill: fill,
          border: rule,
          numFmt: st.numFmt(col.kind, col.decimals),
          h: col.kind.figures ? 'right' : 'left',
          v: 'center',
          indent: 1,
        );
        rows.write(_value(c, r, style, s.rows[i][c], col.kind, str));
      }
      rows.write('</row>');
    }

    final first = headerRow + 1, last = headerRow + s.rows.length;
    var r = last;
    if (s.hasTotals && s.rows.isNotEmpty) {
      r++;
      final totals = s.totals;
      final font = st.font(size: 10.5, bold: true);
      final fill = st.fill(_limeSoft);
      final border = st.border(top: _midnight, topStyle: 'medium');
      rows.write('<row r="$r" ht="22" customHeight="1">');
      for (var c = 0; c < n; c++) {
        final col = s.columns[c];
        final style = st.xf(
          font: font,
          fill: fill,
          border: border,
          numFmt: st.numFmt(col.kind, col.decimals),
          h: col.kind.figures ? 'right' : 'left',
          v: 'center',
          indent: 1,
        );
        final t = totals[c];
        if (t != null) {
          final ref = '${_col(c)}$first:${_col(c)}$last';
          rows.write('<c r="${_col(c)}$r" s="$style"><f>SUBTOTAL(109,$ref)</f><v>${_number(t, col.kind)}</v></c>');
        } else if (c == 0) {
          rows.write(_str(c, r, style, 'Total', str));
        } else {
          rows.write('<c r="${_col(c)}$r" s="$style"/>');
        }
      }
      rows.write('</row>');
    }
    if (s.rows.isEmpty) {
      r++;
      final none = st.xf(font: st.font(size: 10.5, italic: true, color: _muted), indent: 1);
      rows.write('<row r="$r" ht="22" customHeight="1">${_str(0, r, none, 'Nothing in this period.', str)}</row>');
    }
    if (s.note != null) {
      r += 2;
      final note = st.xf(font: st.font(size: 10, color: _muted), indent: 1);
      rows.write('<row r="$r">${_str(0, r, note, s.note!, str)}</row>');
    }
    r += s.note == null ? 2 : 1;
    rows.write(_madeRow(doc, r, st, str));

    final extra = StringBuffer();
    if (s.rows.isNotEmpty) extra.write('<autoFilter ref="A$headerRow:${_col(n - 1)}$last"/>');
    var priority = 1;
    for (var c = 0; c < n; c++) {
      final col = s.columns[c];
      if (s.rows.isEmpty || !(col.bar || col.heat)) continue;
      final ref = '${_col(c)}$first:${_col(c)}$last';
      extra.write(col.bar
          ? '<conditionalFormatting sqref="$ref"><cfRule type="dataBar" priority="${priority++}"><dataBar>'
              '<cfvo type="min"/><cfvo type="max"/><color rgb="$_lime"/></dataBar></cfRule></conditionalFormatting>'
          : '<conditionalFormatting sqref="$ref"><cfRule type="colorScale" priority="${priority++}"><colorScale>'
              '<cfvo type="min"/><cfvo type="max"/><color rgb="$_white"/><color rgb="$_lime"/></colorScale></cfRule></conditionalFormatting>');
    }
    return _sheetXml(
      tab: _midnight,
      selected: selected,
      cols: [for (var c = 0; c < n; c++) _width(s, c)],
      data: rows.toString(),
      freezeRow: s.rows.isEmpty ? null : headerRow,
      extra: extra.toString(),
      doc: doc,
      landscape: n > 7,
      lastCell: '${_col(n < 6 ? 5 : n - 1)}$r',
    );
  }

  static String _sheetXml({
    required String tab,
    required bool selected,
    required List<double> cols,
    required String data,
    required int? freezeRow,
    required String extra,
    required TableDoc doc,
    required bool landscape,
    required String lastCell,
  }) {
    final pane = freezeRow == null
        ? ''
        : '<pane ySplit="$freezeRow" topLeftCell="A${freezeRow + 1}" activePane="bottomLeft" state="frozen"/>'
            '<selection pane="bottomLeft" activeCell="A${freezeRow + 1}" sqref="A${freezeRow + 1}"/>';
    final footer = _esc('&L&8${_footerText(doc.shopName)}&C&8${_footerText(doc.title)}&R&8Page &P of &N');
    return '$_decl<worksheet xmlns="$_main" xmlns:r="$_rel">'
        '<sheetPr><tabColor rgb="$tab"/><pageSetUpPr fitToPage="1"/></sheetPr>'
        '<dimension ref="A1:$lastCell"/>'
        '<sheetViews><sheetView showGridLines="0"${selected ? ' tabSelected="1"' : ''} workbookViewId="0">$pane</sheetView></sheetViews>'
        '<sheetFormatPr defaultRowHeight="16"/>'
        '<cols>${[for (var i = 0; i < cols.length; i++) '<col min="${i + 1}" max="${i + 1}" width="${cols[i]}" customWidth="1"/>'].join()}</cols>'
        '<sheetData>$data</sheetData>'
        '$extra'
        '<printOptions horizontalCentered="1"/>'
        '<pageMargins left="0.4" right="0.4" top="0.5" bottom="0.6" header="0.3" footer="0.3"/>'
        '<pageSetup paperSize="9" orientation="${landscape ? 'landscape' : 'portrait'}" fitToWidth="1" fitToHeight="0"/>'
        '<headerFooter><oddFooter>$footer</oddFooter></headerFooter>'
        '</worksheet>';
  }

  /// "&" starts a code in Excel's header and footer text.
  static String _footerText(String s) => s.replaceAll('&', '&&');

  /// Column width in characters, from the longest value.
  static double _width(DocSheet s, int c) {
    final col = s.columns[c];
    int len(Object? v) => switch (v) {
          null => 0,
          DateTime() => col.kind == DocKind.dateTime ? 17 : 11,
          int() when col.kind == DocKind.money => (v.abs() ~/ 100).toString().length * 4 ~/ 3 + 4,
          num() when col.kind == DocKind.percent => 5,
          int() when col.kind == DocKind.minutes => 7,
          num() => v.toStringAsFixed(col.kind == DocKind.decimal ? col.decimals : 0).length * 4 ~/ 3 + 1,
          _ => '$v'.length,
        };
    var w = 0;
    for (final r in s.rows) {
      final l = len(r[c]);
      if (l > w) w = l;
    }
    final totals = s.totals[c];
    if (totals != null) w = [w, len(col.kind == DocKind.money ? totals.round() : totals) + 1].reduce((a, b) => a > b ? a : b);
    // Headers wrap onto two lines, so half a long header is enough.
    final header = col.header.length > 16 ? (col.header.length / 2).ceil() + 2 : col.header.length + 2;
    final width = (w > header ? w : header) * 1.1 + 3;
    return width.clamp(8, 48).roundToDouble();
  }

  static String _value(int c, int r, int style, Object? v, DocKind kind, _Strings str) => switch (v) {
        null => '<c r="${_col(c)}$r" s="$style"/>',
        num() || DateTime() when kind != DocKind.text => '<c r="${_col(c)}$r" s="$style"><v>${_number(v, kind)}</v></c>',
        _ => _str(c, r, style, '$v', str),
      };

  static String _str(int c, int r, int style, String text, _Strings str) =>
      '<c r="${_col(c)}$r" s="$style" t="s"><v>${str.add(text)}</v></c>';

  /// The number Excel stores: cedis, a fraction for percent, a day count
  /// for dates and minutes.
  static String _number(Object v, DocKind kind) {
    if (v is DateTime) {
      final serial = DateTime.utc(v.year, v.month, v.day, v.hour, v.minute, v.second).difference(DateTime.utc(1899, 12, 30));
      return kind == DocKind.date ? '${serial.inDays}' : _trim(serial.inSeconds / 86400);
    }
    final n = v as num;
    return switch (kind) {
      DocKind.money => n is int ? plainMoney(n) : _trim(n / 100),
      DocKind.percent => _trim(n / 100),
      DocKind.minutes => _trim(n / 1440),
      _ => n is int ? '$n' : _trim(n.toDouble()),
    };
  }

  static String _trim(num n) {
    final s = n.toStringAsFixed(10);
    return s.contains('.') ? s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '') : s;
  }

  /// 0 → A, 26 → AA.
  static String _col(int i) {
    var n = i + 1;
    var s = '';
    while (n > 0) {
      final m = (n - 1) % 26;
      s = String.fromCharCode(65 + m) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  static String _quoted(String sheet) => "'${sheet.replaceAll("'", "''")}'";

  static final _invalid = RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F￾￿]');

  static String _esc(String s) => s
      .replaceAll(_invalid, '')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static const _decl = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
  static const _main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const _rel = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

  static String _contentTypes(int sheets) => '$_decl<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
      '${[for (var i = 1; i <= sheets; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
      '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
      '</Types>';

  static const _rootRels = '$_decl<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="$_rel/officeDocument" Target="xl/workbook.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '<Relationship Id="rId3" Type="$_rel/extended-properties" Target="docProps/app.xml"/>'
      '</Relationships>';

  static String _workbookRels(int sheets) => '$_decl<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '${[for (var i = 1; i <= sheets; i++) '<Relationship Id="rId$i" Type="$_rel/worksheet" Target="worksheets/sheet$i.xml"/>'].join()}'
      '<Relationship Id="rId${sheets + 1}" Type="$_rel/styles" Target="styles.xml"/>'
      '<Relationship Id="rId${sheets + 2}" Type="$_rel/sharedStrings" Target="sharedStrings.xml"/>'
      '</Relationships>';

  static String _core(TableDoc doc) {
    final at = '${doc.madeAt.toUtc().toIso8601String().split('.').first}Z';
    return '$_decl<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:title>${_esc(doc.title)}</dc:title><dc:subject>${_esc(doc.subtitle)}</dc:subject>'
        '<dc:creator>${_esc(doc.shopName)}</dc:creator>'
        '<dcterms:created xsi:type="dcterms:W3CDTF">$at</dcterms:created>'
        '<dcterms:modified xsi:type="dcterms:W3CDTF">$at</dcterms:modified>'
        '</cp:coreProperties>';
  }
}

/// The shared string table: each different text once.
class _Strings {
  final _index = <String, int>{};
  var _count = 0;

  int add(String s) {
    _count++;
    return _index.putIfAbsent(s, () => _index.length);
  }

  String xml() => '${Xlsx._decl}<sst xmlns="${Xlsx._main}" count="$_count" uniqueCount="${_index.length}">'
      '${[for (final s in _index.keys) '<si><t xml:space="preserve">${Xlsx._esc(s)}</t></si>'].join()}</sst>';
}

/// Fonts, fills, borders, number formats and cell formats, each written
/// once and referred to by index.
class _Styles {
  _Styles() {
    font();
    xf();
  }

  final _fonts = <String>[];
  final _fills = <String>['<fill><patternFill patternType="none"/></fill>', '<fill><patternFill patternType="gray125"/></fill>'];
  final _borders = <String>['<border><left/><right/><top/><bottom/><diagonal/></border>'];
  final _formats = <String, int>{};
  final _xfs = <String>[];

  static int _add(List<String> list, String xml) {
    final i = list.indexOf(xml);
    if (i >= 0) return i;
    list.add(xml);
    return list.length - 1;
  }

  int font({double size = 10.5, bool bold = false, bool italic = false, bool underline = false, String color = Xlsx._ink}) => _add(
      _fonts,
      '<font>${bold ? '<b/>' : ''}${italic ? '<i/>' : ''}${underline ? '<u/>' : ''}<sz val="$size"/>'
      '<color rgb="$color"/><name val="Figtree"/><family val="2"/></font>');

  int fill(String color) =>
      _add(_fills, '<fill><patternFill patternType="solid"><fgColor rgb="$color"/><bgColor indexed="64"/></patternFill></fill>');

  int border({String? top, String topStyle = 'thin', String? bottom}) => _add(
      _borders,
      '<border><left/><right/>${top == null ? '<top/>' : '<top style="$topStyle"><color rgb="$top"/></top>'}'
      '${bottom == null ? '<bottom/>' : '<bottom style="thin"><color rgb="$bottom"/></bottom>'}<diagonal/></border>');

  int numFmt(DocKind kind, [int decimals = 2]) {
    final code = switch (kind) {
      DocKind.text => null,
      DocKind.money => '#,##0.00;[Red]-#,##0.00;"–"',
      DocKind.count => '#,##0',
      DocKind.decimal => decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}',
      DocKind.percent => '0%',
      DocKind.date => 'd mmm yyyy',
      DocKind.dateTime => 'd mmm yyyy hh:mm',
      DocKind.minutes => '[h]:mm',
    };
    if (code == null) return 0;
    return _formats.putIfAbsent(code, () => 164 + _formats.length);
  }

  int xf({int font = 0, int fill = 0, int border = 0, int numFmt = 0, String? h, String? v, bool wrap = false, int indent = 0}) {
    final align = h == null && v == null && !wrap && indent == 0
        ? ''
        : '<alignment${h == null ? '' : ' horizontal="$h"'}${v == null ? '' : ' vertical="$v"'}'
            '${wrap ? ' wrapText="1"' : ''}${indent == 0 || h == 'center' ? '' : ' indent="$indent"'}/>';
    return _add(
        _xfs,
        '<xf numFmtId="$numFmt" fontId="$font" fillId="$fill" borderId="$border" xfId="0"'
        '${numFmt == 0 ? '' : ' applyNumberFormat="1"'} applyFont="1" applyFill="1" applyBorder="1"'
        '${align.isEmpty ? '/>' : ' applyAlignment="1">$align</xf>'}');
  }

  String xml() => '${Xlsx._decl}<styleSheet xmlns="${Xlsx._main}">'
      '${_formats.isEmpty ? '' : '<numFmts count="${_formats.length}">${[for (final e in _formats.entries) '<numFmt numFmtId="${e.value}" formatCode="${Xlsx._esc(e.key)}"/>'].join()}</numFmts>'}'
      '<fonts count="${_fonts.length}">${_fonts.join()}</fonts>'
      '<fills count="${_fills.length}">${_fills.join()}</fills>'
      '<borders count="${_borders.length}">${_borders.join()}</borders>'
      '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
      '<cellXfs count="${_xfs.length}">${_xfs.join()}</cellXfs>'
      '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
      '</styleSheet>';
}
