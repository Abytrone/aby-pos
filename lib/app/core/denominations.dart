import 'dart:convert';

/// Ghana cedi notes and coins, largest first, in pesewas.
const ghanaDenominations = [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10, 5, 1];

/// "GH₵ 200", "GH₵ 2", "50p".
String denominationLabel(int pesewas) => pesewas >= 100 ? 'GH₵ ${pesewas ~/ 100}' : '${pesewas}p';

/// How many of each note and coin were counted. Stored with the shift or
/// close, so "where did the GH₵ 50 go?" has an answer.
class CashCount {
  const CashCount([this.pieces = const {}]);

  factory CashCount.fromJson(String? json) {
    if (json == null) return const CashCount();
    final map = Map<String, dynamic>.from(jsonDecode(json) as Map);
    return CashCount({for (final e in map.entries) int.parse(e.key): e.value as int});
  }

  /// Denomination (pesewas) → how many.
  final Map<int, int> pieces;

  int get total => pieces.entries.fold(0, (s, e) => s + e.key * e.value);
  bool get isEmpty => pieces.values.every((n) => n == 0);

  CashCount withCount(int denomination, int count) =>
      CashCount({...pieces, denomination: count < 0 ? 0 : count});

  String toJson() => jsonEncode({for (final e in pieces.entries) if (e.value > 0) '${e.key}': e.value});
}
