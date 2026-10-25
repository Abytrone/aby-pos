import '../core/units.dart';
import 'enums.dart';
import 'sale.dart';
import 'staff.dart';

/// A sold line and how much of it can still be given back.
class RefundableLine {
  const RefundableLine({
    required this.saleLineId,
    required this.productId,
    required this.variantId,
    required this.title,
    required this.optionsLine,
    required this.sellBy,
    required this.sold,
    required this.paid,
    this.refunded = 0,
    this.refundedAmount = 0,
  });

  final String saleLineId;
  final String productId;
  final String? variantId;
  final String title;
  final String optionsLine;
  final SellBy sellBy;

  /// How many were sold (grams or ml when weighed), and already given back.
  final int sold;
  final int refunded;

  /// Pesewas the customer paid for the whole line, after discounts (and
  /// with tax when it was added on top); and already given back.
  final int paid;
  final int refundedAmount;

  bool get weighed => sellBy != SellBy.each;
  int get left => sold - refunded;

  /// Pesewas for giving back [quantity]: in proportion, and exactly what is
  /// left for the last of the line.
  int amountFor(int quantity) {
    if (quantity <= 0 || sold <= 0) return 0;
    if (quantity >= left) return paid - refundedAmount;
    final share = (paid * quantity + sold ~/ 2) ~/ sold;
    return share > paid - refundedAmount ? paid - refundedAmount : share;
  }

  String quantityText(int quantity) =>
      weighed ? formatQuantity(quantity, sellBy == SellBy.kg ? StockUnit.g : StockUnit.ml) : '$quantity';
}

/// A sale, as the refund screen needs it.
class RefundableSale {
  const RefundableSale({
    required this.saleId,
    required this.number,
    required this.at,
    required this.cashierName,
    required this.total,
    required this.payments,
    required this.lines,
    this.refundedTotal = 0,
    this.voided = false,
    this.customerId,
  });

  final String saleId;

  /// The sale's customer: then refunds can go to their wallet or account.
  final String? customerId;
  final int number;
  final DateTime at;
  final String cashierName;

  /// Pesewas.
  final int total;
  final List<Payment> payments;
  final List<RefundableLine> lines;
  final int refundedTotal;
  final bool voided;

  int get left => total - refundedTotal;
  bool get canRefund => !voided && left > 0 && lines.any((l) => l.left > 0);
  String get displayNumber => formatSaleNumber(number);
}

/// One line to give back. From a receipt, [saleLineId] is set and the
/// amount is worked out; without one, [amount] is what the cashier typed.
class RefundLineDraft {
  const RefundLineDraft({
    this.saleLineId,
    this.productId,
    this.variantId,
    required this.name,
    this.variantName,
    required this.quantity,
    this.amount,
    this.sellBy = SellBy.each,
    this.restock = true,
  });

  final String? saleLineId;
  final String? productId;
  final String? variantId;
  final String name;
  final String? variantName;
  final int quantity;
  final int? amount;
  final SellBy sellBy;

  /// Back into stock; false for damaged items.
  final bool restock;
}

class RefundDraft {
  const RefundDraft({
    this.saleId,
    required this.lines,
    required this.reason,
    this.note,
  });

  /// Null for a refund without a receipt.
  final String? saleId;
  final List<RefundLineDraft> lines;
  final String reason;
  final String? note;

  bool get withoutReceipt => saleId == null;
}

/// How the money goes back.
class RefundPaymentInput {
  const RefundPaymentInput({
    required this.method,
    this.methodId,
    required this.methodName,
    required this.amount,
    this.reference,
  });

  final PaymentMethod method;
  final String? methodId;
  final String methodName;

  /// Pesewas.
  final int amount;
  final String? reference;
}

/// A refund in a list (a sale's refunds, the day's refunds).
class RefundSummary {
  const RefundSummary({
    required this.id,
    required this.number,
    required this.at,
    required this.total,
    required this.staffName,
    required this.reason,
    this.saleNumber,
    this.approverName,
    this.withoutReceipt = false,
    this.methods = const [],
  });

  final String id;
  final int number;
  final DateTime at;
  final int total;
  final String staffName;
  final String reason;
  final int? saleNumber;
  final String? approverName;
  final bool withoutReceipt;
  final List<String> methods;

  String get displayNumber => formatRefundNumber(number);
}

/// Items coming back in an exchange, waiting for the new sale. Nothing is
/// saved until that sale is: then both are written together.
class PendingExchange {
  const PendingExchange({required this.returned, required this.credit, this.saleNumber, this.approver});

  final RefundDraft returned;

  /// Pesewas the returned items are worth.
  final int credit;
  final int? saleNumber;

  /// Who approved the refund, when the cashier could not.
  final Staff? approver;
}
