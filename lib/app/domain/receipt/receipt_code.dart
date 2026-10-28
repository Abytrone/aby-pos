import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The QR code on a receipt: the sale's ID and a short check code, so a
/// mistyped or made-up code is refused. Scanning it at the till or in
/// Refund opens the sale.
abstract final class ReceiptCode {
  static const _prefix = 'ABY-R:';

  static String _check(String saleId) =>
      sha256.convert(utf8.encode('aby-receipt:$saleId')).toString().substring(0, 6);

  static String encode(String saleId) => '$_prefix$saleId:${_check(saleId)}';

  /// The sale ID, or null when [text] is not a receipt code or its check
  /// code is wrong. Scanners in caps lock send upper case, so case is
  /// ignored.
  static String? parse(String text) {
    final t = text.trim();
    if (t.length < _prefix.length || t.substring(0, _prefix.length).toUpperCase() != _prefix) return null;
    final rest = t.substring(_prefix.length).toLowerCase();
    final colon = rest.lastIndexOf(':');
    if (colon <= 0) return null;
    final id = rest.substring(0, colon);
    return rest.substring(colon + 1) == _check(id) ? id : null;
  }
}
