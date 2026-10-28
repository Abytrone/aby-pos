import 'enums.dart';
import 'sale.dart';

/// One line of an order, for the prep screen and the kitchen ticket.
class OrderLine {
  const OrderLine({required this.title, required this.quantity, this.options = const [], this.note, this.sellBy = SellBy.each});

  final String title;
  final int quantity;
  final SellBy sellBy;
  final List<String> options;
  final String? note;
}

/// A sale with a queue number that has not been collected yet.
class OpenOrder {
  const OpenOrder({
    required this.saleId,
    required this.number,
    required this.saleNumber,
    required this.status,
    required this.at,
    required this.statusAt,
    required this.lines,
    this.note,
    this.orderType,
    this.customerName,
  });

  final String saleId;

  /// The queue number (without the letter).
  final int number;
  final int saleNumber;
  final OrderStatus status;
  final DateTime at;
  final DateTime statusAt;
  final List<OrderLine> lines;
  final String? note;
  final OrderType? orderType;
  final String? customerName;

  String get displaySaleNumber => formatSaleNumber(saleNumber);
}
