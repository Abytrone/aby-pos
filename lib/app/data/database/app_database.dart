import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/permissions.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../services/ids.dart';
import 'converters.dart';
import 'schema_versions.dart';
import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Device-local values that never sync.
abstract final class MetaKeys {
  static const deviceId = 'device_id';
  static const lastLocalBackupAt = 'last_local_backup_at';
  static const lastOffsiteBackupAt = 'last_offsite_backup_at';
  static const backupPasswordHash = 'backup_password_hash';
}

/// Where the on-device database lives. The backup and restore code uses the
/// same path, so keep this the single source.
// TODO(storage): on Windows this is the user's Documents folder. Consider
// moving to the app support folder with a one-time file move.
Future<File> databaseFile() async =>
    File(p.join((await getApplicationDocumentsDirectory()).path, 'aby_pos.sqlite'));

/// Stable row ID for a setting, so every device of a shop writes the same
/// row for a shop setting, and one row per device for device settings.
String settingRowId(String key, SettingScope scope, String deviceId) =>
    const Uuid().v5(
      Namespace.url.value,
      scope == SettingScope.shop ? 'aby:setting:shop:$key' : 'aby:setting:$deviceId:$key',
    );

@DriftDatabase(tables: [
  Categories,
  Products,
  ProductVariants,
  OptionGroups,
  OptionItems,
  ProductOptionGroups,
  StockItems,
  RecipeItems,
  TaxRates,
  ProductTaxes,
  Barcodes,
  ProductPhotos,
  PriceChanges,
  Suppliers,
  SupplierLedger,
  StockReceipts,
  StockReceiptLines,
  StockCounts,
  StockCountLines,
  Sales,
  SaleLines,
  SaleTaxes,
  Payments,
  StockMovements,
  Roles,
  StaffMembers,
  StaffPhotos,
  DayCloses,
  AuditLog,
  Settings,
  Outbox,
  Meta,
])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database. Pass [executor] in tests
  /// (`NativeDatabase.memory()`). [seedDemoShop] fills a brand-new database
  /// with the Scoops Tamale menu.
  AppDatabase([QueryExecutor? executor, this.seedDemoShop = true])
      : super(executor ??
            driftDatabase(
              name: 'aby_pos',
              native: DriftNativeOptions(
                databasePath: () async => (await databaseFile()).path,
              ),
            ));

  final bool seedDemoShop;

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await m.createIndex(Index('outbox_entity',
              'CREATE INDEX outbox_entity ON outbox (entity, record_id)'));
          await m.createIndex(Index('sales_created',
              'CREATE INDEX sales_created ON sales (created_at)'));
        },
        onUpgrade: stepByStep(
          // v2: staff sign-in and day close.
          from1To2: (m, schema) async {
            await m.createTable(schema.staff);
            await m.createTable(schema.dayCloses);
            await m.addColumn(schema.sales, schema.sales.cashierId);
            await m.addColumn(schema.sales, schema.sales.voidedById);
            await customStatement("DELETE FROM meta WHERE key = 'cashier_name'");
          },
          // v3: roles and permissions, audit log, settings.
          from2To3: (m, schema) async {
            final deviceId = await _ensureDeviceId();
            await m.createTable(schema.roles);
            await _insertBuiltInRoles(deviceId);
            await m.alterTable(TableMigration(
              schema.staff,
              columnTransformer: {
                schema.staff.roleId: CustomExpression<String>(
                  "CASE role WHEN 'owner' THEN '${BuiltInRole.owner.id}' "
                  "ELSE '${BuiltInRole.cashier.id}' END",
                ),
              },
              newColumns: [schema.staff.roleId],
            ));
            await m.createTable(schema.auditLog);
            await m.createTable(schema.settings);
            final shopName = await readMeta('shop_name');
            if (shopName != null) {
              await writeSettingRow(
                  'shop.name', SettingScope.shop, jsonEncode(shopName), deviceId);
              await customStatement("DELETE FROM meta WHERE key = 'shop_name'");
            }
          },
          // v4: staff profiles and photos.
          from3To4: (m, schema) async {
            final staff = schema.staff;
            for (final column in [
              staff.phone,
              staff.email,
              staff.address,
              staff.emergencyName,
              staff.emergencyPhone,
              staff.idNumber,
              staff.dateOfBirth,
              staff.startedOn,
              staff.notes,
            ]) {
              await m.addColumn(staff, column);
            }
            await m.createTable(schema.staffPhotos);
          },
          // v5: catalogue and stock (variants for everything, option groups,
          // stock items and recipes, taxes, suppliers, deliveries, counts).
          from4To5: (m, schema) async {
            final deviceId = await _ensureDeviceId();
            final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            for (final table in [
              schema.optionGroups,
              schema.optionItems,
              schema.productOptionGroups,
              schema.stockItems,
              schema.recipeItems,
              schema.taxRates,
              schema.productTaxes,
              schema.barcodes,
              schema.productPhotos,
              schema.priceChanges,
              schema.suppliers,
              schema.supplierLedger,
              schema.stockReceipts,
              schema.stockReceiptLines,
              schema.stockCounts,
              schema.stockCountLines,
              schema.saleTaxes,
            ]) {
              await m.createTable(table);
            }
            await m.addColumn(schema.categories, schema.categories.parentId);
            await m.addColumn(schema.categories, schema.categories.active);

            // Variant names become optional; cost and active are new.
            await m.alterTable(TableMigration(
              schema.productVariants,
              newColumns: [schema.productVariants.manualCost, schema.productVariants.active],
            ));
            // Every product needs a variant: simple products get one at their
            // old base price (read before that column goes).
            final simple = await customSelect(
              'SELECT id, base_price FROM products p WHERE NOT EXISTS '
              '(SELECT 1 FROM product_variants v WHERE v.product_id = p.id)',
            ).get();
            for (final row in simple) {
              await customStatement(
                'INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, '
                'name, price, sort_order, active) VALUES (?, ?, ?, ?, ?, NULL, ?, 0, 1)',
                [newId(), now, now, deviceId, row.read<String>('id'), row.read<int>('base_price')],
              );
            }
            await m.alterTable(TableMigration(
              schema.products,
              newColumns: [schema.products.description, schema.products.archivedAt],
            ));

            // Add-ons become options in one "Toppings" group. Same IDs, so
            // the add-ons on old sale lines still match.
            final addons = await customSelect(
              'SELECT id, name, price, active, sort_order FROM addons WHERE deleted_at IS NULL',
            ).get();
            if (addons.isNotEmpty) {
              final groupId = newId();
              await customStatement(
                'INSERT INTO option_groups (id, created_at, updated_at, device_id, name, '
                'min_select, max_select, allow_repeat, active, sort_order) '
                "VALUES (?, ?, ?, ?, 'Toppings', 0, NULL, 0, 1, 0)",
                [groupId, now, now, deviceId],
              );
              for (final a in addons) {
                await customStatement(
                  'INSERT INTO option_items (id, created_at, updated_at, device_id, group_id, name, '
                  'price_delta, is_default, active, sort_order) VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)',
                  [
                    a.read<String>('id'),
                    now,
                    now,
                    deviceId,
                    groupId,
                    a.read<String>('name'),
                    a.read<int>('price'),
                    a.read<int>('active'),
                    a.read<int>('sort_order'),
                  ],
                );
              }
              final linked = await customSelect(
                'SELECT DISTINCT product_id FROM product_addons WHERE deleted_at IS NULL',
              ).get();
              for (final l in linked) {
                await customStatement(
                  'INSERT INTO product_option_groups (id, created_at, updated_at, device_id, '
                  'product_id, group_id, sort_order) VALUES (?, ?, ?, ?, ?, ?, 0)',
                  [newId(), now, now, deviceId, l.read<String>('product_id'), groupId],
                );
              }
            }
            await customStatement('DROP TABLE product_addons');
            await customStatement('DROP TABLE addons');

            await m.addColumn(schema.sales, schema.sales.taxTotal);
            await m.addColumn(schema.saleLines, schema.saleLines.costTotal);
            await m.addColumn(schema.saleLines, schema.saleLines.taxTotal);

            // Movements are per stock item from now on; product is optional.
            final moves = schema.stockMovements;
            await m.alterTable(TableMigration(moves, newColumns: [
              moves.stockItemId,
              moves.subReason,
              moves.unitCostMilli,
              moves.refId,
              moves.byName,
            ]));
          },
        ),
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          final deviceId = await _ensureDeviceId();
          if (details.wasCreated) {
            await _insertBuiltInRoles(deviceId);
            if (seedDemoShop) await seedScoopsTamale(this, deviceId: deviceId);
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

  /// Raw SQL so it works inside any migration step, whatever the current
  /// table classes look like. Not written to the outbox: every device
  /// creates the same rows with the same IDs.
  Future<void> _insertBuiltInRoles(String deviceId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const names = {
      BuiltInRole.owner: 'Owner',
      BuiltInRole.manager: 'Manager',
      BuiltInRole.cashier: 'Cashier',
      BuiltInRole.stockKeeper: 'Stock keeper',
    };
    for (final role in BuiltInRole.values) {
      await customStatement(
        'INSERT OR IGNORE INTO roles (id, created_at, updated_at, device_id, name, '
        'built_in, permissions, max_discount_percent, sort_order) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          role.id,
          now,
          now,
          deviceId,
          names[role],
          role.name,
          const PermissionSetConverter().toSql(role.defaultPermissions),
          role.defaultMaxDiscount,
          role.index,
        ],
      );
    }
  }

  Future<String?> readMeta(String key) async {
    final row = await (select(meta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> writeMeta(String key, String value) =>
      into(meta).insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));

  Future<void> deleteMeta(String key) =>
      (delete(meta)..where((t) => t.key.equals(key))).go();

  /// Writes a settings row without the outbox (seed and migrations).
  /// SettingsRepository is the tracked path for everything else.
  Future<void> writeSettingRow(
    String key,
    SettingScope scope,
    String valueJson,
    String deviceId,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await customStatement(
      'INSERT INTO settings (id, created_at, updated_at, device_id, key, scope, value) '
      'VALUES (?, ?, ?, ?, ?, ?, ?) '
      'ON CONFLICT(id) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at',
      [settingRowId(key, scope, deviceId), now, now, deviceId, key, scope.name, valueJson],
    );
  }

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

  /// Sets deletedAt on a syncable row and records the update in the outbox.
  /// Rows are never removed: sync and history still need them.
  Future<void> softDeleteTracked<T extends Table, D extends DataClass>(
    TableInfo<T, D> table,
    String id,
  ) async {
    final now = DateTime.now();
    await customUpdate(
      'UPDATE ${table.actualTableName} SET deleted_at = ?, updated_at = ? WHERE id = ?',
      variables: [Variable.withDateTime(now), Variable.withDateTime(now), Variable.withString(id)],
      updates: {table},
      updateKind: UpdateKind.update,
    );
    final row = await customSelect(
      'SELECT * FROM ${table.actualTableName} WHERE id = ?',
      variables: [Variable.withString(id)],
      readsFrom: {table},
    ).asyncMap((r) async => await table.map(r.data)).getSingle();
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
