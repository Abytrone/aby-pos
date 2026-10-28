import 'dart:convert';
import 'dart:typed_data';

import 'enums.dart';
import 'sale.dart';

/// A sale line as it goes on a receipt.
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.variant,
    this.options = const [],
    this.discount = 0,
    this.sellBy = SellBy.each,
    this.note,
  });

  final String name;
  final String? variant;
  final List<String> options;

  /// Count, or grams / millilitres when sold by weight or volume.
  final int quantity;
  final SellBy sellBy;

  /// Pesewas for one (per kg or litre when weighed).
  final int unitPrice;

  /// Pesewas before this line's discount.
  final int total;

  /// Pesewas off this line.
  final int discount;
  final String? note;

  String get title => variant == null || variant!.isEmpty ? name : '$name ($variant)';
}

/// Everything a sale receipt shows, read back from the database so a reprint
/// matches the first print.
class ReceiptData {
  const ReceiptData({
    required this.saleId,
    required this.number,
    required this.at,
    required this.cashierName,
    required this.lines,
    required this.subtotal,
    required this.total,
    required this.payments,
    this.orderDiscount = 0,
    this.taxTotal = 0,
    this.taxIncluded = true,
    this.rounding = 0,
    this.customerName,
    this.customerPhone,
    this.orderType,
    this.note,
    this.voided = false,
    this.refunded = 0,
  });

  final String saleId;
  final int number;
  final DateTime at;
  final String cashierName;
  final List<ReceiptLine> lines;

  /// Pesewas: lines before any discount, total as paid.
  final int subtotal;
  final int total;

  /// Pesewas off the whole order.
  final int orderDiscount;
  final int taxTotal;

  /// Prices already include the tax (otherwise it was added on top).
  final bool taxIncluded;
  final int rounding;
  final List<Payment> payments;
  final String? customerName;
  final String? customerPhone;
  final OrderType? orderType;
  final String? note;
  final bool voided;

  /// Pesewas given back by refunds since.
  final int refunded;

  String get displayNumber => formatSaleNumber(number);

  int get lineDiscounts => lines.fold(0, (s, l) => s + l.discount);

  bool get paidCash => payments.any((p) => p.method == PaymentMethod.cash);
}

/// A refund slip.
class RefundReceiptData {
  const RefundReceiptData({
    required this.refundId,
    required this.number,
    required this.at,
    required this.byName,
    required this.reason,
    required this.lines,
    required this.total,
    required this.payments,
    this.saleNumber,
    this.paidCash = false,
  });

  final String refundId;
  final int number;
  final DateTime at;
  final String byName;
  final String reason;
  final int? saleNumber;

  /// Name and quantity (count, or grams / ml) with the pesewas given back.
  final List<(String, int, SellBy, int)> lines;
  final int total;

  /// Method name and pesewas.
  final List<(String, int)> payments;

  /// Some of it was handed back in cash.
  final bool paidCash;

  String get displayNumber => formatRefundNumber(number);
}

/// What the owner chose for receipts (Settings → Receipt design).
class ReceiptDesign {
  const ReceiptDesign({
    required this.shopName,
    this.address = '',
    this.phone = '',
    this.header = '',
    this.footer = '',
    this.momoNumber = '',
    this.logo,
    this.showCashier = true,
    this.showCustomer = true,
    this.showTax = true,
    this.showQr = true,
    this.copies = const {},
  });

  final String shopName;
  final String address;
  final String phone;
  final String header;
  final String footer;
  final String momoNumber;

  /// PNG, already sized for the paper.
  final Uint8List? logo;
  final bool showCashier;
  final bool showCustomer;
  final bool showTax;
  final bool showQr;

  /// Copies to print per kind of payment ('credit': 2); 1 when not listed.
  final Map<String, int> copies;

  /// The most copies any of the payments asks for.
  int copiesFor(Iterable<PaymentMethod> methods) =>
      methods.fold(1, (most, m) => (copies[m.name] ?? 1) > most ? copies[m.name]! : most);

  static Map<String, int> decodeCopies(String json) {
    try {
      return (jsonDecode(json) as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt()));
    } on Object {
      return const {};
    }
  }
}

enum PrinterKind { network, windows, bluetooth }

/// Where this device's receipt printer is: an IP address and port, a
/// Windows printer's name, or a paired Bluetooth printer's address.
class PrinterTarget {
  const PrinterTarget({required this.kind, required this.address, String? name}) : name = name ?? address;

  final PrinterKind kind;
  final String address;

  /// What people see.
  final String name;

  String encode() => jsonEncode({'kind': kind.name, 'address': address, 'name': name});

  /// Null for '' (no printer) or anything unreadable.
  static PrinterTarget? decode(String json) {
    if (json.isEmpty) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return PrinterTarget(
        kind: PrinterKind.values.byName(m['kind'] as String),
        address: m['address'] as String,
        name: m['name'] as String?,
      );
    } on Object {
      return null;
    }
  }

  @override
  bool operator ==(Object other) => other is PrinterTarget && other.kind == kind && other.address == address;

  @override
  int get hashCode => Object.hash(kind, address);
}
