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

/// What the cashier chose to pay with, before it is saved.
class PaymentInput {
  const PaymentInput.cash({required int this.tendered})
      : method = PaymentMethod.cash,
        momoReference = null,
        customer = null;

  const PaymentInput.momo({required String this.momoReference})
      : method = PaymentMethod.momo,
        tendered = null,
        customer = null;

  const PaymentInput.credit({required String this.customer})
      : method = PaymentMethod.credit,
        tendered = null,
        momoReference = null;

  final PaymentMethod method;

  /// Pesewas handed over, for cash.
  final int? tendered;
  final String? momoReference;
  final String? customer;
}

class Payment {
  const Payment({
    required this.id,
    required this.method,
    required this.amount,
    this.tendered,
    this.changeGiven,
    this.momoReference,
    this.customer,
  });

  final String id;
  final PaymentMethod method;

  /// Pesewas.
  final int amount;
  final int? tendered;
  final int? changeGiven;
  final String? momoReference;
  final String? customer;
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
  });

  final String id;
  final int number;
  final SaleStatus status;

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
  });

  final String saleId;
  final int number;

  /// Pesewas.
  final int total;
  final PaymentMethod method;

  /// Pesewas.
  final int changeDue;

  String get displayNumber => formatSaleNumber(number);
}

class TodaySummary {
  const TodaySummary({
    this.total = 0,
    this.count = 0,
    this.byMethod = const {},
  });

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
    for (final sale in sales.where((s) => !s.isVoided)) {
      total += sale.total;
      count++;
      for (final p in sale.payments) {
        byMethod[p.method] = byMethod[p.method]! + p.amount;
      }
    }
    return TodaySummary(total: total, count: count, byMethod: byMethod);
  }
}
