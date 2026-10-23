import '../models/enums.dart';

/// A unit people type and read. Stock is stored in base units (piece, g,
/// ml); kg and L are 1000 of those.
enum DisplayUnit {
  piece(StockUnit.piece, 1, 'pcs'),
  g(StockUnit.g, 1, 'g'),
  kg(StockUnit.g, 1000, 'kg'),
  ml(StockUnit.ml, 1, 'ml'),
  l(StockUnit.ml, 1000, 'L');

  const DisplayUnit(this.base, this.factor, this.symbol);

  final StockUnit base;

  /// Base units in one of these.
  final int factor;
  final String symbol;

  static List<DisplayUnit> forBase(StockUnit unit) =>
      DisplayUnit.values.where((d) => d.base == unit).toList();

  /// The unit used to talk about bulk amounts and prices (per kg, per L).
  static DisplayUnit bulk(StockUnit unit) => switch (unit) {
        StockUnit.piece => DisplayUnit.piece,
        StockUnit.g => DisplayUnit.kg,
        StockUnit.ml => DisplayUnit.l,
      };

  /// The unit recipes use (80 ml, 10 g, 1 pcs).
  static DisplayUnit small(StockUnit unit) => switch (unit) {
        StockUnit.piece => DisplayUnit.piece,
        StockUnit.g => DisplayUnit.g,
        StockUnit.ml => DisplayUnit.ml,
      };
}

/// "12 pcs", "750 g", "2.5 kg", "1.25 L". Large weights and volumes show in
/// kg and L.
String formatQuantity(int baseQty, StockUnit unit) {
  if (unit == StockUnit.piece) return '$baseQty pcs';
  final small = DisplayUnit.small(unit);
  if (baseQty.abs() < 1000) return '$baseQty ${small.symbol}';
  final big = DisplayUnit.bulk(unit);
  return '${_decimal(baseQty, 1000)} ${big.symbol}';
}

/// [value] / [divisor] with up to three decimals, trailing zeros trimmed.
String _decimal(int value, int divisor) {
  final negative = value < 0;
  final abs = value.abs();
  final whole = abs ~/ divisor;
  var frac = (abs % divisor).toString().padLeft(3, '0');
  frac = frac.replaceFirst(RegExp(r'0+$'), '');
  return '${negative ? '-' : ''}$whole${frac.isEmpty ? '' : '.$frac'}';
}

/// "2.5" in [unit] → base units (2500 for kg). Null if not a non-negative
/// number with at most three decimals.
int? parseQuantity(String input, DisplayUnit unit) {
  final text = input.trim().replaceAll(',', '');
  final match = RegExp(r'^(\d*)(?:\.(\d{0,3}))?$').firstMatch(text);
  if (text.isEmpty || match == null) return null;
  final whole = match.group(1)!;
  final frac = match.group(2) ?? '';
  if (whole.isEmpty && frac.isEmpty) return null;
  final thousandths = int.parse(whole.isEmpty ? '0' : whole) * 1000 + int.parse(frac.padRight(3, '0'));
  // thousandths of the display unit → base units
  final base = thousandths * unit.factor;
  if (base % 1000 != 0 && unit.factor == 1) return null; // no fractions of a gram / piece
  return base ~/ 1000;
}

/// Base units shown in [unit], e.g. 2500 g in kg → "2.5".
String quantityIn(int baseQty, DisplayUnit unit) =>
    unit.factor == 1 ? '$baseQty' : _decimal(baseQty, unit.factor);

/// Cost in thousandths of a pesewa per base unit, from a price for one
/// [unit] (pesewas per kg, per L, per piece).
int costMilliFromPrice(int pesewasPerUnit, DisplayUnit unit) =>
    (pesewasPerUnit * 1000 + unit.factor ~/ 2) ~/ unit.factor;

/// Pesewas for one [unit] at [costMilli] per base unit.
int priceForUnit(int costMilli, DisplayUnit unit) => (costMilli * unit.factor + 500) ~/ 1000;

/// Pesewas for [baseQty] at [costMilli] per base unit, rounded half-up.
int costOf(int baseQty, int costMilli) {
  final milli = baseQty * costMilli;
  return milli >= 0 ? (milli + 500) ~/ 1000 : -((-milli + 500) ~/ 1000);
}
