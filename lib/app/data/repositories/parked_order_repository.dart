import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// A cart put aside to finish later.
class ParkedOrder {
  const ParkedOrder({
    required this.id,
    required this.name,
    required this.at,
    required this.total,
    required this.itemCount,
    required this.parkedByName,
    required this.cart,
  });

  final String id;
  final String name;
  final DateTime at;

  /// Pesewas when parked.
  final int total;
  final int itemCount;
  final String parkedByName;

  /// The cart as JSON (CartController.snapshot).
  final Map<String, dynamic> cart;
}

/// Parked orders (synced, so other tills on the hub see them) and the cart
/// being built on this till (device-only, so a crash or power cut loses
/// nothing).
class ParkedOrderRepository {
  ParkedOrderRepository(this._db, this._device, this._audit);

  static const _currentKey = 'cart.current';

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<void> saveCurrent(Map<String, dynamic>? cart) =>
      cart == null ? _db.deleteMeta(_currentKey) : _db.writeMeta(_currentKey, jsonEncode(cart));

  Future<Map<String, dynamic>?> loadCurrent() async {
    final text = await _db.readMeta(_currentKey);
    if (text == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } on FormatException {
      return null;
    }
  }

  SimpleSelectStatement<$ParkedOrdersTable, ParkedOrderRow> _parked() => _db.select(_db.parkedOrders)
    ..where((o) => o.status.equalsValue(ParkedOrderStatus.parked) & o.deletedAt.isNull())
    ..orderBy([(o) => OrderingTerm(expression: o.createdAt), (o) => OrderingTerm(expression: o.id)]);

  /// Oldest first, the order the tabs show.
  Stream<List<ParkedOrder>> watchParked() => _parked().watch().map((rows) => rows.map(_toOrder).toList());

  Future<List<ParkedOrder>> parked() async => (await _parked().get()).map(_toOrder).toList();

  ParkedOrder _toOrder(ParkedOrderRow r) => ParkedOrder(
        id: r.id,
        name: r.name,
        at: r.createdAt,
        total: r.total,
        itemCount: r.itemCount,
        parkedByName: r.parkedByName,
        cart: Map<String, dynamic>.from(jsonDecode(r.cart) as Map),
      );

  Future<String> park({
    required String name,
    required Map<String, dynamic> cart,
    required int total,
    required int itemCount,
    required Staff by,
  }) {
    final clean = name.trim();
    return _db.transaction(() async {
      final now = clock.now();
      final id = newId();
      await _db.insertTracked(
        _db.parkedOrders,
        ParkedOrdersCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          name: clean,
          status: ParkedOrderStatus.parked,
          cart: jsonEncode(cart),
          total: total,
          itemCount: itemCount,
          parkedById: by.id,
          parkedByName: by.name,
        ),
      );
      await _audit.record(
        action: AuditAction.orderParked,
        actor: by,
        entity: 'parked_orders',
        entityId: id,
        summary: 'Parked "$clean": $itemCount items, ${formatMoney(total)}',
      );
      return id;
    });
  }

  /// Takes the order off the parked list (it goes back into a cart).
  /// Returns false when another till took it first.
  Future<bool> take(String id) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.parkedOrders)..where((o) => o.id.equals(id))).getSingleOrNull();
      if (row == null || row.status != ParkedOrderStatus.parked) return false;
      final now = clock.now();
      await _db.updateTracked(
        _db.parkedOrders,
        row.copyWith(status: ParkedOrderStatus.resumed, closedAt: Value(now), updatedAt: now),
      );
      return true;
    });
  }

  Future<void> rename(String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    await _db.transaction(() async {
      final row = await (_db.select(_db.parkedOrders)..where((o) => o.id.equals(id))).getSingle();
      await _db.updateTracked(_db.parkedOrders, row.copyWith(name: clean, updatedAt: clock.now()));
    });
  }

  /// Throws the order away. Audited: it could hide a sale that was paid.
  Future<void> discard(String id, {required Staff actor, Staff? approver}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.parkedOrders)..where((o) => o.id.equals(id))).getSingle();
      if (row.status != ParkedOrderStatus.parked) return;
      final now = clock.now();
      await _db.updateTracked(
        _db.parkedOrders,
        row.copyWith(status: ParkedOrderStatus.discarded, closedAt: Value(now), updatedAt: now),
      );
      await _audit.record(
        action: AuditAction.parkedOrderDiscarded,
        actor: actor,
        approver: approver,
        entity: 'parked_orders',
        entityId: id,
        summary: 'Discarded parked order "${row.name}": ${row.itemCount} items, ${formatMoney(row.total)}',
      );
    });
  }

  /// Parked orders waiting longer than [age] (close day warns about them).
  Future<int> olderThan(Duration age) async {
    final cutoff = clock.now().subtract(age);
    return (await _parked().get()).where((r) => r.createdAt.isBefore(cutoff)).length;
  }
}
