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
    this.tracksExpiry = false,
    this.batchYield,
  });

  final String id;
  final String name;
  final StockUnit unit;

  /// Batch numbers and expiry dates are asked for when receiving.
  final bool tracksExpiry;

  /// Made here: base units one batch of its recipe makes.
  final int? batchYield;

  bool get madeHere => batchYield != null;

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

/// What is left of a batch, counting sales and waste from the batch that
/// expires first (FEFO).
class BatchLeft {
  const BatchLeft({
    required this.id,
    required this.stockItemId,
    required this.itemName,
    required this.unit,
    required this.quantity,
    required this.left,
    required this.receivedAt,
    this.batchNo,
    this.expiresOn,
  });

  final String id;
  final String stockItemId;
  final String itemName;
  final StockUnit unit;

  /// Base units received, and still in stock.
  final int quantity;
  final int left;
  final DateTime receivedAt;
  final String? batchNo;
  final DateTime? expiresOn;

  /// Days until it expires (negative once it has); null without a date.
  int? daysLeft(DateTime now) {
    final e = expiresOn;
    if (e == null) return null;
    return DateTime(e.year, e.month, e.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}

/// A stock item made here from other stock items: its batch recipe.
class ProductionRecipe {
  const ProductionRecipe({required this.batchYield, required this.lines});

  /// Base units one batch makes.
  final int batchYield;

  /// (stock item ID, base units per batch).
  final List<(String, int)> lines;
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
