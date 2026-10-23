import 'enums.dart';

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.paymentTermsDays,
    this.active = true,
    this.balance = 0,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;

  /// Days they give to pay; null = pay on delivery.
  final int? paymentTermsDays;
  final bool active;

  /// Pesewas the shop owes them now.
  final int balance;
}

class SupplierEntry {
  const SupplierEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.amount,
    required this.byName,
    this.method,
    this.receiptId,
    this.reference,
    this.note,
  });

  final String id;
  final DateTime at;
  final SupplierEntryKind kind;

  /// Pesewas: positive adds to what is owed, negative is a payment.
  final int amount;
  final String byName;
  final SupplierPaymentMethod? method;
  final String? receiptId;
  final String? reference;
  final String? note;
}

class SupplierDraft {
  const SupplierDraft({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.paymentTermsDays,
  });

  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final int? paymentTermsDays;
}

/// One line of a delivery being entered.
class ReceiptLineDraft {
  const ReceiptLineDraft({required this.stockItemId, required this.quantity, required this.lineTotal});

  final String stockItemId;

  /// Base units.
  final int quantity;

  /// Pesewas paid for the whole line.
  final int lineTotal;
}

class ReceiptDraft {
  const ReceiptDraft({
    this.supplierId,
    this.invoiceRef,
    this.note,
    required this.lines,
    this.paidNow = 0,
    this.paidWith,
  });

  final String? supplierId;
  final String? invoiceRef;
  final String? note;
  final List<ReceiptLineDraft> lines;

  /// Pesewas paid on delivery.
  final int paidNow;
  final SupplierPaymentMethod? paidWith;

  int get total => lines.fold(0, (s, l) => s + l.lineTotal);
}

class StockReceipt {
  const StockReceipt({
    required this.id,
    required this.number,
    required this.at,
    required this.total,
    required this.paidNow,
    required this.receivedByName,
    required this.lineCount,
    this.supplierName,
    this.invoiceRef,
  });

  final String id;
  final int number;
  final DateTime at;

  /// Pesewas.
  final int total;
  final int paidNow;
  final String receivedByName;
  final int lineCount;
  final String? supplierName;
  final String? invoiceRef;

  String get displayNumber => 'GRN-${number.toString().padLeft(4, '0')}';
}

class StockCount {
  const StockCount({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.startedByName,
    required this.blind,
    required this.lineCount,
    this.postedAt,
    this.postedByName,
    this.note,
  });

  final String id;
  final StockCountStatus status;
  final DateTime startedAt;
  final String startedByName;
  final bool blind;
  final int lineCount;
  final DateTime? postedAt;
  final String? postedByName;
  final String? note;
}

class StockCountLine {
  const StockCountLine({
    required this.stockItemId,
    required this.name,
    required this.unit,
    required this.costMilli,
    this.expected,
    this.counted,
    this.countedByName,
  });

  final String stockItemId;
  final String name;
  final StockUnit unit;
  final int costMilli;

  /// On hand when counted (null until counted).
  final int? expected;
  final int? counted;
  final String? countedByName;

  int? get difference => counted == null || expected == null ? null : counted! - expected!;
}
