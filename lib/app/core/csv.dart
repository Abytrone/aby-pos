/// Minimal RFC 4180 CSV: commas, double-quoted fields with "" escapes, and
/// CRLF or LF line ends. Enough for spreadsheets saved as CSV.
abstract final class Csv {
  static String encode(List<List<String>> rows) {
    String field(String v) =>
        v.contains(RegExp(r'[",\r\n]')) || v.startsWith(' ') || v.endsWith(' ')
            ? '"${v.replaceAll('"', '""')}"'
            : v;
    return '${rows.map((r) => r.map(field).join(',')).join('\r\n')}\r\n';
  }

  static List<List<String>> decode(String text) {
    // Excel adds a byte-order mark.
    final input = text.startsWith('﻿') ? text.substring(1) : text;
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var quoted = false;
    var i = 0;
    void endField() {
      row.add(field.toString());
      field.clear();
    }

    void endRow() {
      endField();
      if (!(row.length == 1 && row.single.isEmpty)) rows.add(row);
      row = <String>[];
    }

    while (i < input.length) {
      final ch = input[i];
      if (quoted) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"' && field.isEmpty) {
        quoted = true;
      } else if (ch == ',') {
        endField();
      } else if (ch == '\r' || ch == '\n') {
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        endRow();
      } else {
        field.write(ch);
      }
      i++;
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }
}
