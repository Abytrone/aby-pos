import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';

/// The stock ledger. Stock is never stored as a level: every change is a
/// movement, and stock on hand is their sum.
class StockRepository {
  StockRepository(this._db, this._device);

  final AppDatabase _db;
  final DeviceInfo _device;

  /// Appends a movement (and its outbox row). Runs inside the caller's
  /// transaction when there is one.
  Future<void> record({
    required String productId,
    String? variantId,
    required int quantityChange,
    required StockReason reason,
    String? saleId,
    String? note,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();
    await _db.insertTracked(
      _db.stockMovements,
      StockMovementsCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        productId: productId,
        variantId: Value(variantId),
        quantityChange: quantityChange,
        reason: reason,
        saleId: Value(saleId),
        note: Value(note),
      ),
    );
  }

  /// Sum of all movements for a product (and variant, if given).
  Future<int> onHand(String productId, {String? variantId}) async {
    final sum = _db.stockMovements.quantityChange.sum();
    final query = _db.selectOnly(_db.stockMovements)
      ..addColumns([sum])
      ..where(_db.stockMovements.productId.equals(productId) &
          _db.stockMovements.deletedAt.isNull() &
          (variantId == null
              ? _db.stockMovements.variantId.isNull()
              : _db.stockMovements.variantId.equals(variantId)));
    return (await query.map((r) => r.read(sum)).getSingle()) ?? 0;
  }
}
