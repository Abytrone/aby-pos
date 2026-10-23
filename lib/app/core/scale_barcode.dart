/// Barcodes printed by a shop scale: an EAN-13 that starts with the
/// shop's prefix (often "2" or "21"), then the item code, then five digits
/// of weight (grams) or price (pesewas), then the check digit.
///
/// With prefix "2": 2 CCCCCC VVVVV K (six-digit item code).
/// With prefix "21": 21 CCCCC VVVVV K (five-digit item code).
class ScaleBarcode {
  const ScaleBarcode({required this.itemCode, required this.value});

  /// As printed, leading zeros kept ("000123").
  final String itemCode;

  /// Grams, or pesewas when the scale prints prices.
  final int value;

  /// The item code without leading zeros ("123"), for short PLU codes.
  String get shortCode => itemCode.replaceFirst(RegExp(r'^0+(?=.)'), '');

  /// Null when [code] is not a valid scale barcode for [prefix]. An empty
  /// prefix turns scale barcodes off.
  static ScaleBarcode? parse(String code, {required String prefix}) {
    if (prefix.isEmpty || prefix.length > 6 || !RegExp(r'^\d+$').hasMatch(prefix)) return null;
    if (!isValidEan13(code) || !code.startsWith(prefix)) return null;
    final item = code.substring(prefix.length, 7);
    final value = int.parse(code.substring(7, 12));
    if (item.isEmpty) return null;
    return ScaleBarcode(itemCode: item, value: value);
  }

  /// Thirteen digits with a correct check digit.
  static bool isValidEan13(String code) {
    if (!RegExp(r'^\d{13}$').hasMatch(code)) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(code[i]) * (i.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10 == int.parse(code[12]);
  }
}
