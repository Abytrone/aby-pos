// Money is always integer pesewas (1 cedi = 100 pesewas). Doubles never
// touch an amount; these helpers convert to and from what people see.

/// Formats pesewas as "GH₵ 1,234.00", the same output as the brand kit's
/// `abyMoney()` but with integer arithmetic only.
String formatMoney(int pesewas) {
  final negative = pesewas < 0;
  final abs = pesewas.abs();
  final cedis = (abs ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}GH₵ $cedis.$fraction';
}

/// Whole cedis to pesewas.
int cedis(int value) => value * 100;

/// Parses what a cashier types ("50", "50.5", "1,000.25", "GH₵ 20") into
/// pesewas. Returns null for anything that is not a non-negative amount
/// with at most two decimal places.
int? parseMoney(String input) {
  final cleaned = input
      .replaceAll('GH₵', '')
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .trim();
  final match = RegExp(r'^(\d*)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (cleaned.isEmpty || match == null) return null;
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (whole.isEmpty && fraction.isEmpty) return null;
  return int.parse(whole.isEmpty ? '0' : whole) * 100 +
      int.parse(fraction.padRight(2, '0'));
}

/// Converts pesewas to a cedi value for brand widgets that take `num`
/// (`AbyPayButton`). Display only, never for arithmetic.
num toCedisForDisplay(int pesewas) => pesewas / 100;
