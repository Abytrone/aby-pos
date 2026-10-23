import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../services/ids.dart';
import 'converters.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Meta keys.
abstract final class MetaKeys {
  static const deviceId = 'device_id';
  static const shopName = 'shop_name';
}

@DriftDatabase(tables: [
  Categories,
  Products,
  ProductVariants,
  Addons,
  ProductAddons,
  Sales,
  SaleLines,
  Payments,
  StockMovements,
  StaffMembers,
  DayCloses,
  Outbox,
  Meta,
])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database. Pass [executor] in tests
  /// (`NativeDatabase.memory()`). [seedDemoShop] fills a brand-new database
  /// with the Scoops Tamale menu.
  AppDatabase([QueryExecutor? executor, this.seedDemoShop = true])
      : super(executor ?? driftDatabase(name: 'aby_pos'));

  final bool seedDemoShop;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await m.createIndex(Index('outbox_entity',
              'CREATE INDEX outbox_entity ON outbox (entity, record_id)'));
          await m.createIndex(Index('sales_created',
              'CREATE INDEX sales_created ON sales (created_at)'));
        },
        onUpgrade: (m, from, to) async {
          // v2: staff sign-in and day close.
          if (from < 2) {
            await m.createTable(staffMembers);
            await m.createTable(dayCloses);
            await m.addColumn(sales, sales.cashierId);
            await m.addColumn(sales, sales.voidedById);
            await customStatement(
                "DELETE FROM meta WHERE key = 'cashier_name'");
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          final deviceId = await _ensureDeviceId();
          if (details.wasCreated && seedDemoShop) {
            await seedScoopsTamale(this, deviceId: deviceId);
          }
        },
      );

  Future<String> _ensureDeviceId() async {
    final existing = await readMeta(MetaKeys.deviceId);
    if (existing != null) return existing;
    final id = newId();
    await writeMeta(MetaKeys.deviceId, id);
    return id;
  }

  Future<String?> readMeta(String key) async {
    final row = await (select(meta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> writeMeta(String key, String value) =>
      into(meta).insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  /// Inserts a row into a syncable table and records it in the outbox.
  /// Call inside a transaction so both land or neither does.
  Future<D> insertTracked<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    Insertable<D> row,
  ) async {
    final inserted = await into(table).insertReturning(row);
    await _recordOutbox(table, inserted, OutboxOperation.insert);
    return inserted;
  }

  /// Replaces a row in a syncable table and records it in the outbox.
  /// Call inside a transaction so both land or neither does.
  Future<void> updateTracked<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    D row,
  ) async {
    final ok = await update(table).replace(row as Insertable<D>);
    if (!ok) throw StateError('No ${table.actualTableName} row to update');
    await _recordOutbox(table, row, OutboxOperation.update);
  }

  Future<void> _recordOutbox(
    TableInfo<Table, DataClass> table,
    DataClass row,
    OutboxOperation operation,
  ) async {
    final json = row.toJson();
    // TODO(sync): agree the wire format with the Laravel API (dates are
    // epoch milliseconds here, enums are names).
    await into(outbox).insert(OutboxCompanion.insert(
      entity: table.actualTableName,
      recordId: json['id'] as String,
      operation: operation,
      payload: jsonEncode(json),
      createdAt: DateTime.now(),
    ));
  }
}
