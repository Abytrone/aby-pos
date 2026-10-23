import '../core/units.dart';
import 'enums.dart';

/// Something the shop buys and keeps, with what is on hand now.
class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.unit,
    this.costMilli = 0,
    this.onHand = 0,
    this.reorderPoint,
    this.reorderQty,
    this.supplierId,
    this.active = true,
  });

  final String id;
  final String name;
  final StockUnit unit;

  /// Thousandths of a pesewa per base unit.
  final int costMilli;

  /// Base units (sum of movements).
  final int onHand;
  final int? reorderPoint;
  final int? reorderQty;
  final String? supplierId;
  final bool active;

  bool get isLow => reorderPoint != null && onHand <= reorderPoint!;

  /// Pesewas.
  int get value => onHand <= 0 ? 0 : costOf(onHand, costMilli);

  /// Pesewas per kg, L or piece.
  int get bulkPrice => priceForUnit(costMilli, DisplayUnit.bulk(unit));

  String get onHandText => formatQuantity(onHand, unit);
}

class StockMovement {
  const StockMovement({
    required this.id,
    required this.at,
    required this.quantityChange,
    required this.reason,
    this.subReason,
    this.note,
    this.byName,
    this.saleId,
    this.refId,
  });

  final String id;
  final DateTime at;

  /// Base units.
  final int quantityChange;
  final StockReason reason;
  final String? subReason;
  final String? note;
  final String? byName;
  final String? saleId;
  final String? refId;
}
