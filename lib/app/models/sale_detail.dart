import 'discount.dart';
import 'receipt.dart';

/// One line of a sale with what the receipt leaves out: who changed its
/// price, the discount as given, and what it cost.
class SaleDetailLine {
  const SaleDetailLine({
    required this.line,
    this.listPrice,
    this.priceOverriddenBy,
    this.discount,
    this.orderShare = 0,
    this.cost = 0,
  });

  final ReceiptLine line;

  /// The menu price for one, when the price was typed or changed.
  final int? listPrice;
  final String? priceOverriddenBy;

  /// The line discount as given (null for promotions alone).
  final Discount? discount;

  /// Pesewas of the order discount carried by this line.
  final int orderShare;

  /// Pesewas at cost.
  final int cost;

  bool get priceChanged => listPrice != null && listPrice != line.unitPrice;
}

/// A refund taken against a sale.
class SaleRefundNote {
  const SaleRefundNote({
    required this.refundId,
    required this.number,
    required this.at,
    required this.byName,
    required this.reason,
    required this.total,
    this.approverName,
  });

  final String refundId;
  final int number;
  final DateTime at;
  final String byName;
  final String reason;
  final int total;
  final String? approverName;
}

/// Everything about one sale, for the sale's own page.
class SaleDetail {
  const SaleDetail({
    required this.receipt,
    required this.lines,
    required this.refunds,
    this.orderDiscount,
    this.voidedAt,
    this.voidedBy,
  });

  /// As printed: totals, payments, customer, note.
  final ReceiptData receipt;
  final List<SaleDetailLine> lines;
  final List<SaleRefundNote> refunds;

  /// The order discount as given.
  final Discount? orderDiscount;
  final DateTime? voidedAt;
  final String? voidedBy;

  /// Pesewas at cost, and what the sale made over it (after discounts,
  /// before tax added on top).
  int get cost => lines.fold(0, (t, l) => t + l.cost);
  int get takings => receipt.total - receipt.rounding - (receipt.taxIncluded ? 0 : receipt.taxTotal);
  int get profit => takings - cost;

  /// Profit as a share of takings, whole percent; null with no takings.
  int? get margin => takings <= 0 ? null : (profit * 100 / takings).round();

  int get lineDiscounts => receipt.lines.fold(0, (t, l) => t + l.discount);
  int get promotions => receipt.lines.fold(0, (t, l) => t + l.promotion);
}
