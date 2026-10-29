import 'enums.dart';

/// A shop location (MDV-02).
class Branch {
  const Branch({required this.id, required this.name, this.address, this.phone, this.active = true});

  final String id;
  final String name;
  final String? address;
  final String? phone;
  final bool active;
}

class BranchDraft {
  const BranchDraft({this.id, required this.name, this.address, this.phone});

  final String? id;
  final String name;
  final String? address;
  final String? phone;
}

/// Stock sent between branches (INV-10).
class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.fromBranch,
    required this.toBranch,
    required this.fromName,
    required this.toName,
    required this.status,
    required this.sentAt,
    required this.sentBy,
    required this.lines,
    this.note,
    this.receivedAt,
    this.receivedBy,
  });

  final String id;
  final String fromBranch;
  final String toBranch;
  final String fromName;
  final String toName;
  final TransferStatus status;
  final DateTime sentAt;
  final String sentBy;
  final String? note;
  final DateTime? receivedAt;
  final String? receivedBy;
  final List<TransferLine> lines;

  /// Short and readable: the end of the ID (random), e.g. TR-4F2A9.
  String get code => 'TR-${id.replaceAll('-', '').substring(id.replaceAll('-', '').length - 5).toUpperCase()}';

  bool get hasDifferences => lines.any((l) => l.difference != 0);

  /// Cost of what was sent, in pesewas.
  int get value => lines.fold(0, (s, l) => s + (l.quantitySent * l.unitCostMilli + 500) ~/ 1000);
}

class TransferLine {
  const TransferLine({
    required this.id,
    required this.stockItemId,
    required this.itemName,
    required this.unit,
    required this.quantitySent,
    this.quantityReceived,
    this.unitCostMilli = 0,
  });

  final String id;
  final String stockItemId;
  final String itemName;
  final StockUnit unit;
  final int quantitySent;
  final int? quantityReceived;
  final int unitCostMilli;

  /// Received less sent (negative: short); 0 until received.
  int get difference => quantityReceived == null ? 0 : quantityReceived! - quantitySent;
}
