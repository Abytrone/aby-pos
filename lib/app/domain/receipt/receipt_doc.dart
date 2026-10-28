import 'dart:typed_data';

/// Paper widths: characters per line in the printer's normal font and dots
/// across for images.
enum Paper {
  mm58(32, 384),
  mm80(48, 576);

  const Paper(this.chars, this.dots);

  final int chars;
  final int dots;

  static Paper fromMillimetres(int mm) => mm == 58 ? mm58 : mm80;

  int get millimetres => this == mm58 ? 58 : 80;
}

enum ReceiptAlign { left, center, right }

/// One piece of a receipt or a report on paper. The same blocks become
/// printer bytes, the on-screen preview, a PDF and a plain-text message.
sealed class ReceiptBlock {
  const ReceiptBlock();
}

/// Text that wraps. [big] is double width and height (half as many
/// characters fit).
class RText extends ReceiptBlock {
  const RText(this.text, {this.align = ReceiptAlign.left, this.bold = false, this.big = false});

  final String text;
  final ReceiptAlign align;
  final bool bold;
  final bool big;
}

/// Text on the left, an amount on the right. The left side wraps.
class RRow extends ReceiptBlock {
  const RRow(this.left, this.right, {this.bold = false});

  final String left;
  final String right;
  final bool bold;
}

/// A dashed line across.
class RRule extends ReceiptBlock {
  const RRule();
}

class RQr extends ReceiptBlock {
  const RQr(this.data);

  final String data;
}

/// A Code 128 barcode (labels).
class RBarcode extends ReceiptBlock {
  const RBarcode(this.data);

  final String data;
}

/// The shop's logo (PNG), printed as an image.
class RImage extends ReceiptBlock {
  const RImage(this.png);

  final Uint8List png;
}

class RFeed extends ReceiptBlock {
  const RFeed([this.lines = 1]);

  final int lines;
}

class ReceiptDoc {
  const ReceiptDoc(this.title, this.blocks);

  /// For the print queue and file names: "Receipt #00142".
  final String title;
  final List<ReceiptBlock> blocks;

  /// Plain text, for WhatsApp, SMS and tests. Images are left out and a QR
  /// code becomes nothing (the message is the receipt).
  String toText(Paper paper) {
    final out = <String>[];
    for (final b in blocks) {
      out.addAll(layout(b, paper.chars));
    }
    return out.join('\n');
  }
}

/// The lines a text block takes on paper [width] characters wide; empty for
/// images and QR codes.
List<String> layout(ReceiptBlock b, int width) {
  switch (b) {
    case RText(:final text, :final align, :final big):
      final w = big ? width ~/ 2 : width;
      return [for (final line in wrap(receiptAscii(text), w)) _aligned(line, w, align)];
    case RRow(:final left, :final right):
      final r = receiptAscii(right);
      final room = width - r.length - 1;
      if (room < 8) return [...wrap(receiptAscii(left), width), _aligned(r, width, ReceiptAlign.right)];
      final lines = wrap(receiptAscii(left), room);
      return [
        for (var i = 0; i < lines.length; i++)
          i == lines.length - 1 ? '${lines[i].padRight(room)} $r' : lines[i],
      ];
    case RRule():
      return ['-' * width];
    case RFeed(:final lines):
      return List.filled(lines, '');
    case RQr() || RImage() || RBarcode():
      return const [];
  }
}

String _aligned(String line, int width, ReceiptAlign align) => switch (align) {
      ReceiptAlign.left => line,
      ReceiptAlign.right => line.padLeft(width),
      ReceiptAlign.center => ' ' * ((width - line.length) ~/ 2) + line,
    };

/// Word wraps to [width]; words longer than a line are cut. A paragraph's
/// leading spaces indent each of its lines.
List<String> wrap(String text, int width) {
  final out = <String>[];
  for (final para in text.split('\n')) {
    final indent = para.length - para.trimLeft().length;
    if (indent > 0 && indent < width ~/ 2) {
      out.addAll([for (final l in wrap(para.trimLeft(), width - indent)) ' ' * indent + l]);
      continue;
    }
    var line = '';
    for (var word in para.split(' ').where((w) => w.isNotEmpty)) {
      while (word.length > width) {
        if (line.isNotEmpty) {
          out.add(line);
          line = '';
        }
        out.add(word.substring(0, width));
        word = word.substring(width);
      }
      if (line.isEmpty) {
        line = word;
      } else if (line.length + 1 + word.length <= width) {
        line = '$line $word';
      } else {
        out.add(line);
        line = word;
      }
    }
    out.add(line);
  }
  return out;
}

const _fold = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'æ': 'ae', 'ç': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
  'ñ': 'n', 'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ù': 'u',
  'ú': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y', 'ɛ': 'e', 'ɔ': 'o', 'ŋ': 'ng',
  'ƒ': 'f', 'ɣ': 'g', 'ʋ': 'v', 'ɖ': 'd', 'ß': 'ss',
  '₵': 'GHS', '−': '-', '–': '-', '—': '-', '·': '-', '×': 'x', '‘': "'", '’': "'",
  '“': '"', '”': '"', '…': '...', '•': '*', ' ': ' ', '\t': ' ',
};

/// Cheap thermal printers only know plain ASCII: accents are dropped
/// (Ghanaian letters too: ɛ → e, ɔ → o), the cedi sign becomes GHS, and
/// anything else becomes "?".
String receiptAscii(String s) {
  final b = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    if (r == 10 || (r >= 32 && r < 127)) {
      b.write(ch);
      continue;
    }
    final lower = ch.toLowerCase();
    final folded = _fold[ch] ?? _fold[lower];
    if (folded == null) {
      b.write('?');
    } else {
      b.write(ch != lower && folded.length == 1 ? folded.toUpperCase() : folded);
    }
  }
  return b.toString();
}

/// "1,234.50" for receipt columns ("-2.00" when negative).
String paperMoney(int pesewas) {
  final neg = pesewas < 0;
  final v = pesewas.abs();
  final whole = (v ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${neg ? '-' : ''}$whole.${(v % 100).toString().padLeft(2, '0')}';
}
