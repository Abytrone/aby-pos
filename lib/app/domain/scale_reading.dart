/// What a scale sent, read as a weight. Scales talk in short ASCII lines;
/// the formats differ by brand but nearly all carry a number and a unit:
///
///   "ST,GS,+  0.534kg"     (stable, gross)
///   "US,GS,+  0.530kg"     (still moving)
///   "\x02 0.534\r"          (Toledo 8217, kilograms)
///   "   534 g"
class ScaleReading {
  const ScaleReading(this.grams, {this.stable = true});

  final int grams;

  /// False while the weight is still moving.
  final bool stable;

  static final _number = RegExp(r'([-+])?\s*(\d+(?:[.,]\d+)?)\s*(kg|g|lb|oz)?', caseSensitive: false);

  /// The last complete weight in [raw], or null when there is none or it is
  /// below zero.
  static ScaleReading? parse(String raw) {
    final lines = raw
        .replaceAll(RegExp(r'[\x00-\x09\x0B\x0C\x0E-\x1F]'), ' ')
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    for (final line in lines.reversed) {
      final upper = line.toUpperCase();
      // "ST,GS,+0.534kg": the first number after the status words.
      final matches = _number.allMatches(line).toList();
      if (matches.isEmpty) continue;
      final m = matches.firstWhere((m) => m.group(3) != null, orElse: () => matches.last);
      final sign = m.group(1);
      final value = double.tryParse(m.group(2)!.replaceAll(',', '.'));
      if (value == null) continue;
      if (sign == '-') return null;
      final unit = m.group(3)?.toLowerCase();
      final grams = switch (unit) {
        'kg' => value * 1000,
        'g' => value,
        'lb' => value * 453.59237,
        'oz' => value * 28.349523125,
        // No unit: a decimal is kilograms (most scales), a whole number grams.
        _ => m.group(2)!.contains(RegExp('[.,]')) ? value * 1000 : value,
      };
      final unstable = upper.startsWith('US') || upper.contains('?') || upper.contains('MOTION');
      return ScaleReading(grams.round(), stable: !unstable);
    }
    return null;
  }
}
