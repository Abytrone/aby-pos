import 'enums.dart';

/// Takings since the last close, before the drawer is counted. Pesewas.
class OpenPeriod {
  const OpenPeriod({
    required this.from,
    required this.salesCount,
    required this.voidedCount,
    required this.salesTotal,
    required this.byMethod,
    required this.suggestedFloat,
    this.lastSaleNumber = 0,
  });

  /// Highest sale number in the period (0 when there are no sales).
  final int lastSaleNumber;

  /// End of the previous close, or null if the till has never been closed.
  final DateTime? from;
  final int salesCount;
  final int voidedCount;
  final int salesTotal;

  /// Completed sales only.
  final Map<PaymentMethod, int> byMethod;

  /// The last close's opening float, to prefill the form.
  final int suggestedFloat;

  int get cashTakings => byMethod[PaymentMethod.cash] ?? 0;

  /// Cash that should be in the drawer for a given opening float.
  int expectedCash(int openingFloat) => openingFloat + cashTakings;
}

/// A closed day (cash-up). Pesewas.
class DayClose {
  const DayClose({
    required this.id,
    required this.periodStart,
    required this.closedAt,
    required this.closedByName,
    required this.salesCount,
    required this.salesTotal,
    required this.openingFloat,
    required this.expectedCash,
    required this.countedCash,
    required this.momoTakings,
    required this.creditTakings,
    this.note,
  });

  final String id;

  /// Null for the first close on this device.
  final DateTime? periodStart;
  final DateTime closedAt;
  final String closedByName;
  final int salesCount;
  final int salesTotal;
  final int openingFloat;
  final int expectedCash;
  final int countedCash;
  final int momoTakings;
  final int creditTakings;
  final String? note;

  /// Positive when the drawer is over, negative when short.
  int get difference => countedCash - expectedCash;
}
