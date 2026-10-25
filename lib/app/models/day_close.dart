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
    this.lastRefundNumber = 0,
    this.refundsCount = 0,
    this.refundsTotal = 0,
    this.refundsByMethod = const {},
    this.rounding = 0,
    this.noSales = const {},
    this.customerMoney = const {},
  });

  /// Money from customers that was not a sale (repayments, wallet top-ups,
  /// change kept), per kind of payment.
  final Map<PaymentMethod, int> customerMoney;

  int get customerCash => customerMoney[PaymentMethod.cash] ?? 0;

  /// Highest refund number in the period.
  final int lastRefundNumber;
  final int refundsCount;
  final int refundsTotal;

  /// Refunds paid out, per kind of payment (exchanges are not money out).
  final Map<PaymentMethod, int> refundsByMethod;

  /// Pesewas added (or taken off) by cash rounding.
  final int rounding;

  /// Drawer opened without a sale, per person.
  final Map<String, int> noSales;

  int get noSaleCount => noSales.values.fold(0, (s, n) => s + n);
  int get cashRefunds => refundsByMethod[PaymentMethod.cash] ?? 0;

  /// Takings that are neither cash, MoMo nor credit (card, bank, cheque...).
  int get otherTakings => byMethod.entries
      .where((e) => !const {PaymentMethod.cash, PaymentMethod.momo, PaymentMethod.credit, PaymentMethod.exchange}
          .contains(e.key))
      .fold(0, (s, e) => s + e.value);

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

  /// Cash that should be in the drawer for a given opening float: the float,
  /// plus cash taken, minus cash given back.
  int expectedCash(int openingFloat) => openingFloat + cashTakings + customerCash - cashRefunds;
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
    this.refundsTotal = 0,
    this.cashRefunds = 0,
    this.otherTakings = 0,
    this.noSaleCount = 0,
    this.customerCash = 0,
  });

  final int customerCash;
  final int refundsTotal;
  final int cashRefunds;
  final int otherTakings;
  final int noSaleCount;

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
