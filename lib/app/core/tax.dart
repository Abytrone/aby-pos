/// How prices relate to tax: off (not registered), prices already include
/// tax (usual in Ghana retail), or tax is added at the till.
enum TaxMode {
  off,
  inclusive,
  exclusive;

  static TaxMode fromName(String name) =>
      TaxMode.values.where((m) => m.name == name).firstOrNull ?? TaxMode.off;
}

/// A rate as used in a calculation.
class TaxRateSpec {
  const TaxRateSpec({required this.id, required this.name, required this.rateBp, this.compound = false});

  final String id;
  final String name;

  /// Basis points: 1500 = 15%.
  final int rateBp;

  /// Charged on the amount plus the non-compound taxes.
  final bool compound;
}

class TaxAmount {
  const TaxAmount(this.rate, this.amount);

  final TaxRateSpec rate;

  /// Pesewas.
  final int amount;
}

/// [base] + taxes = [total], all in pesewas.
class TaxResult {
  const TaxResult({required this.base, required this.taxes, required this.total});

  final int base;
  final List<TaxAmount> taxes;
  final int total;

  int get taxTotal => total - base;

  static TaxResult none(int amount) => TaxResult(base: amount, taxes: const [], total: amount);
}

/// Works out the tax on [amount] (pesewas). Inclusive: [amount] already has
/// the tax in it. Exclusive: tax is added on top. Non-compound rates apply
/// to the base; compound rates to the base plus the non-compound taxes.
/// Integer arithmetic throughout; rounding is half-up per rate, and for
/// inclusive prices any leftover pesewa goes to the base so the parts
/// always add up to the price.
TaxResult computeTax(int amount, List<TaxRateSpec> rates, TaxMode mode) {
  if (mode == TaxMode.off || rates.isEmpty || amount == 0) return TaxResult.none(amount);
  final simpleBp = rates.where((r) => !r.compound).fold(0, (s, r) => s + r.rateBp);
  final compoundBp = rates.where((r) => r.compound).fold(0, (s, r) => s + r.rateBp);

  int roundDiv(int n, int d) => n >= 0 ? (n * 2 + d) ~/ (2 * d) : -((-n * 2 + d) ~/ (2 * d));

  final int base;
  if (mode == TaxMode.exclusive) {
    base = amount;
  } else {
    // amount = base × (1 + simple) × (1 + compound)
    base = roundDiv(amount * 10000 * 10000, (10000 + simpleBp) * (10000 + compoundBp));
  }

  final taxes = <TaxAmount>[];
  var simpleTotal = 0;
  for (final r in rates.where((r) => !r.compound)) {
    final t = roundDiv(base * r.rateBp, 10000);
    simpleTotal += t;
    taxes.add(TaxAmount(r, t));
  }
  for (final r in rates.where((r) => r.compound)) {
    taxes.add(TaxAmount(r, roundDiv((base + simpleTotal) * r.rateBp, 10000)));
  }
  final taxTotal = taxes.fold(0, (s, t) => s + t.amount);

  if (mode == TaxMode.exclusive) {
    return TaxResult(base: base, taxes: taxes, total: base + taxTotal);
  }
  // Inclusive: the price is fixed; the base absorbs rounding.
  return TaxResult(base: amount - taxTotal, taxes: taxes, total: amount);
}
