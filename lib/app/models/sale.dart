import 'enums.dart';

/// An add-on as it was sold, stored in sale_lines.addons as JSON so old
/// sales stay correct when prices change.
class SoldAddon {
  const SoldAddon({required this.id, required this.name, required this.price});

  factory SoldAddon.fromJson(Map<String, dynamic> json) => SoldAddon(
        id: json['id'] as String,
        name: json['name'] as String,
        price: json['price'] as int,
      );

  final String id;
  final String name;

  /// Pesewas.
  final int price;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'price': price};
}

/// One payment the cashier took, before it is saved. A sale can have
/// several (split payment). [amount] null means "the rest".
class PaymentInput {
  const PaymentInput({
    required this.method,
    this.methodId,
    this.methodName,
    this.amount,
    this.tendered,
    this.reference,
    this.customer,
    this.needsReference = false,
    this.shortReference = false,
  });

  const PaymentInput.cash({required int this.tendered, this.amount})
      : method = PaymentMethod.cash,
        methodId = null,
        methodName = null,
        reference = null,
        customer = null,
        needsReference = false,
        shortReference = false;

  const PaymentInput.momo({required String momoReference, this.amount})
      : method = PaymentMethod.momo,
        methodId = null,
        methodName = null,
        tendered = null,
        reference = momoReference,
        customer = null,
        needsReference = true,
        shortReference = false;

  const PaymentInput.credit({required String this.customer, this.amount})
      : method = PaymentMethod.credit,
        methodId = null,
        methodName = null,
        tendered = null,
        reference = null,
        needsReference = false,
        shortReference = false;

  /// From one of the shop's payment methods.
  factory PaymentInput.from(
    PayMethod m, {
    int? amount,
    int? tendered,
    String? reference,
    String? customer,
  }) =>
      PaymentInput(
        method: m.kind,
        methodId: m.id,
        methodName: m.name,
        amount: amount,
        tendered: tendered,
        reference: reference,
        customer: customer,
        needsReference: m.needsReference,
        shortReference: m.shortReference,
      );

  final PaymentMethod method;
  final String? methodId;
  final String? methodName;

  /// Pesewas this payment covers; null for the rest of the total.
  final int? amount;

  /// Pesewas handed over, for cash.
  final int? tendered;

  /// Transaction reference (MoMo, bank, cheque).
  final String? reference;
  final String? customer;
  final bool needsReference;

  /// The last 4 characters of the reference are enough.
  final bool shortReference;

  String? get momoReference => reference;

  String get label => methodName ?? method.label;
}

/// One of the shop's payment methods.
class PayMethod {
  const PayMethod({
    required this.id,
    required this.name,
    required this.kind,
    this.builtIn,
    this.active = true,
    this.needsReference = false,
    this.shortReference = false,
    this.merchantNumber,
  });

  final String id;
  final String name;
  final PaymentMethod kind;
  final String? builtIn;
  final bool active;
  final bool needsReference;
  final bool shortReference;

  /// The shop's MoMo number or merchant ID, shown to the customer.
  final String? merchantNumber;

  bool get isCash => kind == PaymentMethod.cash;
}

class Payment {
  const Payment({
    required this.id,
    required this.method,
    required this.amount,
    this.methodName,
    this.tendered,
    this.changeGiven,
    this.momoReference,
    this.customer,
  });

  final String id;
  final PaymentMethod method;
  final String? methodName;

  /// Pesewas.
  final int amount;
  final int? tendered;
  final int? changeGiven;
  final String? momoReference;
  final String? customer;

  String get label => methodName ?? method.label;
}

class Sale {
  const Sale({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    required this.cashierName,
    required this.deviceId,
    this.payments = const [],
    this.voidedAt,
    this.voidedBy,
    this.refunded = 0,
  });

  final String id;
  final int number;
  final SaleStatus status;

  /// Pesewas given back by refunds.
  final int refunded;

  /// Pesewas.
  final int total;
  final int itemCount;
  final DateTime createdAt;
  final String cashierName;
  final String deviceId;
  final List<Payment> payments;
  final DateTime? voidedAt;
  final String? voidedBy;

  bool get isVoided => status == SaleStatus.voided;
  bool get hasRefunds => refunded > 0;
  bool get fullyRefunded => refunded > 0 && refunded >= total;

  /// "#00142".
  String get displayNumber => formatSaleNumber(number);
}

String formatSaleNumber(int number) => '#${number.toString().padLeft(5, '0')}';

/// What the checkout shows once a sale is saved.
class CompletedSale {
  const CompletedSale({
    required this.saleId,
    required this.number,
    required this.total,
    required this.method,
    this.changeDue = 0,
    this.paymentLabels = const [],
    this.rounding = 0,
    this.exchangeRefund,
    this.changeKept = 0,
    this.orderNumber,
  });

  /// The day's queue number, when the sale has prep items and the shop uses
  /// order numbers.
  final int? orderNumber;

  /// Pesewas of change put in the customer's wallet instead.
  final int changeKept;

  /// "MTN MoMo GH₵ 20.00", one per payment.
  final List<String> paymentLabels;

  /// Pesewas added (or taken off) by cash rounding.
  final int rounding;

  /// For an exchange: the refund that went towards this sale.
  final CompletedRefund? exchangeRefund;

  final String saleId;
  final int number;

  /// Pesewas.
  final int total;
  final PaymentMethod method;

  /// Pesewas.
  final int changeDue;

  String get displayNumber => formatSaleNumber(number);
}

String formatRefundNumber(int number) => 'R-${number.toString().padLeft(4, '0')}';

/// What the refund screen shows once a refund is saved.
class CompletedRefund {
  const CompletedRefund({required this.refundId, required this.number, required this.total, this.paidBack = 0});

  final String refundId;
  final int number;

  /// Pesewas.
  final int total;

  /// Pesewas handed back (for an exchange, only what the new sale did not use).
  final int paidBack;

  String get displayNumber => formatRefundNumber(number);
}

class TodaySummary {
  const TodaySummary({
    this.total = 0,
    this.count = 0,
    this.byMethod = const {},
    this.refunded = 0,
  });

  /// Pesewas given back by refunds of these sales.
  final int refunded;

  /// Pesewas, completed sales only.
  final int total;
  final int count;

  /// Pesewas per payment method, completed sales only.
  final Map<PaymentMethod, int> byMethod;

  /// Voided sales are listed but not counted.
  factory TodaySummary.fromSales(List<Sale> sales) {
    var total = 0;
    var count = 0;
    final byMethod = {for (final m in PaymentMethod.values) m: 0};
    var refunded = 0;
    for (final sale in sales.where((s) => !s.isVoided)) {
      total += sale.total;
      refunded += sale.refunded;
      count++;
      for (final p in sale.payments) {
        byMethod[p.method] = byMethod[p.method]! + p.amount;
      }
    }
    return TodaySummary(total: total, count: count, byMethod: byMethod, refunded: refunded);
  }
}
