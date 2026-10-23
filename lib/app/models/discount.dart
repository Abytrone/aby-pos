import '../services/money.dart';
import 'enums.dart';

/// A discount as given on a line or a whole order: a percentage or an
/// amount, with the reason picked and, for saved discounts, their name.
class Discount {
  const Discount({
    required this.kind,
    required this.value,
    required this.reason,
    this.name,
    this.savedId,
    this.approvedBy,
  });

  factory Discount.fromJson(Map<String, dynamic> json) => Discount(
        kind: DiscountKind.values.byName(json['kind'] as String),
        value: json['value'] as int,
        reason: json['reason'] as String,
        name: json['name'] as String?,
        savedId: json['savedId'] as String?,
        approvedBy: json['approvedBy'] as String?,
      );

  final DiscountKind kind;

  /// Whole percent, or pesewas.
  final int value;
  final String reason;

  /// A saved discount's name ("Student 10%").
  final String? name;
  final String? savedId;

  /// Who approved it, when it was above the cashier's limit.
  final String? approvedBy;

  /// Pesewas off [base], never more than [base]. Percentages round half up.
  int amountOn(int base) {
    if (base <= 0) return 0;
    final off = kind == DiscountKind.percent ? (base * value + 50) ~/ 100 : value;
    return off > base ? base : off;
  }

  /// "10%" or "GH₵ 5.00".
  String get label => kind == DiscountKind.percent ? '$value%' : formatMoney(value);

  /// The percentage of [base] that [amount] is, rounded up, for role limits.
  static int percentOf(int amount, int base) => base <= 0 ? 0 : (amount * 100 + base - 1) ~/ base;

  Discount copyWith({String? approvedBy}) => Discount(
        kind: kind,
        value: value,
        reason: reason,
        name: name,
        savedId: savedId,
        approvedBy: approvedBy ?? this.approvedBy,
      );

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'value': value,
        'reason': reason,
        'name': ?name,
        'savedId': ?savedId,
        'approvedBy': ?approvedBy,
      };
}

/// A discount the owner saved for reuse.
class SavedDiscount {
  const SavedDiscount({
    required this.id,
    required this.name,
    required this.kind,
    required this.value,
    required this.scope,
    this.active = true,
  });

  final String id;
  final String name;
  final DiscountKind kind;
  final int value;
  final DiscountScope scope;
  final bool active;

  bool get forLines => scope != DiscountScope.order;
  bool get forOrders => scope != DiscountScope.line;

  String get label => kind == DiscountKind.percent ? '$value%' : formatMoney(value);

  Discount apply({required String reason}) =>
      Discount(kind: kind, value: value, reason: reason, name: name, savedId: id);
}

/// One entry in a reasons list (discount, void, refund, no-sale).
class Reason {
  const Reason({required this.id, required this.kind, required this.name, this.active = true});

  final String id;
  final ReasonKind kind;
  final String name;
  final bool active;
}
