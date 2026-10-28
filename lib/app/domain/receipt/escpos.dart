import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

import 'receipt_doc.dart';

/// A one-bit picture for the printer: rows of packed bits, 1 = black.
class MonoBitmap {
  MonoBitmap(this.width, this.height, this.bits) : assert(bits.length == ((width + 7) ~/ 8) * height);

  final int width;
  final int height;
  final Uint8List bits;

  int get bytesPerRow => (width + 7) ~/ 8;

  bool dark(int x, int y) => bits[y * bytesPerRow + (x >> 3)] & (0x80 >> (x & 7)) != 0;

  /// A QR code, [scale] dots per module, with a 4-module quiet zone.
  factory MonoBitmap.qr(String data, {int scale = 6}) {
    final code = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
    final n = code.moduleCount + 8;
    final size = n * scale;
    final bmp = MonoBitmap(size, size, Uint8List(((size + 7) ~/ 8) * size));
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final r = y ~/ scale - 4;
        final c = x ~/ scale - 4;
        if (r >= 0 && c >= 0 && r < code.moduleCount && c < code.moduleCount && code.isDark(r, c)) {
          bmp.bits[y * bmp.bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
        }
      }
    }
    return bmp;
  }

  /// A picture (PNG or JPEG), no wider than [maxWidth] dots, dithered to
  /// black and white. Null when it cannot be read.
  static MonoBitmap? picture(Uint8List bytes, {required int maxWidth}) {
    var image = img.decodeImage(bytes);
    if (image == null) return null;
    if (image.width > maxWidth) image = img.copyResize(image, width: maxWidth);
    final w = image.width, h = image.height;
    // Grey levels (transparent counts as white), then Floyd-Steinberg.
    final grey = Float32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final a = p.aNormalized;
        final l = 0.299 * p.rNormalized + 0.587 * p.gNormalized + 0.114 * p.bNormalized;
        grey[y * w + x] = (l * a + (1 - a)) * 255;
      }
    }
    final bmp = MonoBitmap(w, h, Uint8List(((w + 7) ~/ 8) * h));
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        final old = grey[i];
        final black = old < 128;
        if (black) bmp.bits[y * bmp.bytesPerRow + (x >> 3)] |= 0x80 >> (x & 7);
        final err = old - (black ? 0 : 255);
        if (x + 1 < w) grey[i + 1] += err * 7 / 16;
        if (y + 1 < h) {
          if (x > 0) grey[i + w - 1] += err * 3 / 16;
          grey[i + w] += err * 5 / 16;
          if (x + 1 < w) grey[i + w + 1] += err * 1 / 16;
        }
      }
    }
    return bmp;
  }
}

/// A logo picked by the owner, made ready for receipts: grey, at most 384
/// dots wide (two thirds of 80 mm paper, all of 58 mm), as PNG. Null when
/// the picture cannot be read.
Uint8List? receiptLogo(Uint8List bytes) {
  var image = img.decodeImage(bytes);
  if (image == null) return null;
  if (image.width > 384) image = img.copyResize(image, width: 384);
  if (image.height > 240) image = img.copyResize(image, height: 240);
  return img.encodePng(img.grayscale(image));
}

/// Turns receipts into ESC/POS bytes, the language of 58 mm and 80 mm
/// thermal printers (Epson and the many printers that copy it).
abstract final class EscPos {
  static const _esc = 0x1B, _gs = 0x1D, _lf = 0x0A;

  static const init = [_esc, 0x40];

  /// Pulse pin 2 of the drawer port (25 ms on, 250 ms off): opens the cash
  /// drawer plugged into the printer.
  static const drawerKick = [_esc, 0x70, 0x00, 0x19, 0xFA];

  /// Feed past the cutter and cut (partial cut). Printers without a cutter
  /// ignore it.
  static const feedAndCut = [_gs, 0x56, 0x42, 0x03];

  static List<int> _align(ReceiptAlign a) => [_esc, 0x61, a.index];
  static List<int> _bold(bool on) => [_esc, 0x45, on ? 1 : 0];
  static List<int> _size(bool big) => [_gs, 0x21, big ? 0x11 : 0x00];

  /// The whole document, ready to send. [kickDrawer] opens the drawer first.
  static Uint8List encode(ReceiptDoc doc, Paper paper, {bool kickDrawer = false, bool cut = true}) {
    final out = BytesBuilder(copy: false)..add(init);
    if (kickDrawer) out.add(drawerKick);
    for (final b in doc.blocks) {
      switch (b) {
        case RText(:final align, :final bold, :final big):
          // Wrapped here; the printer's own alignment places the lines.
          final w = big ? paper.chars ~/ 2 : paper.chars;
          out
            ..add(_align(align))
            ..add(_bold(bold))
            ..add(_size(big));
          for (final line in wrap(receiptAscii(b.text), w)) {
            out
              ..add(line.codeUnits)
              ..addByte(_lf);
          }
          out
            ..add(_size(false))
            ..add(_bold(false))
            ..add(_align(ReceiptAlign.left));
        case RRow(:final bold):
          out.add(_bold(bold));
          for (final line in layout(b, paper.chars)) {
            out
              ..add(line.codeUnits)
              ..addByte(_lf);
          }
          out.add(_bold(false));
        case RRule() || RFeed():
          for (final line in layout(b, paper.chars)) {
            out
              ..add(line.codeUnits)
              ..addByte(_lf);
          }
        case RQr(:final data):
          out.add(raster(MonoBitmap.qr(data, scale: paper == Paper.mm58 ? 5 : 6)));
        case RImage(:final png):
          final bmp = MonoBitmap.picture(png, maxWidth: paper.dots);
          if (bmp != null) out.add(raster(bmp));
      }
    }
    if (cut) {
      out
        ..add([_lf, _lf, _lf])
        ..add(feedAndCut);
    }
    return out.takeBytes();
  }

  /// Just the drawer.
  static Uint8List kickOnly() => Uint8List.fromList([...init, ...drawerKick]);

  /// GS v 0, centred, in bands of 128 rows: some printers' buffers are small.
  static Uint8List raster(MonoBitmap bmp) {
    final out = BytesBuilder(copy: false)..add(_align(ReceiptAlign.center));
    final bpr = bmp.bytesPerRow;
    for (var top = 0; top < bmp.height; top += 128) {
      final rows = bmp.height - top < 128 ? bmp.height - top : 128;
      out
        ..add([_gs, 0x76, 0x30, 0x00, bpr & 0xFF, bpr >> 8, rows & 0xFF, rows >> 8])
        ..add(Uint8List.sublistView(bmp.bits, top * bpr, (top + rows) * bpr));
    }
    out.add(_align(ReceiptAlign.left));
    return out.takeBytes();
  }
}
