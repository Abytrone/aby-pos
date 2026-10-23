import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';
import '../helpers.dart';

// Schema snapshots live in drift_schemas/. After changing a table, bump
// schemaVersion, then run:
//   dart run drift_dev schema dump lib/app/data/database/app_database.dart drift_schemas/drift_schema_vN.json
//   dart run drift_dev schema steps drift_schemas lib/app/data/database/schema_versions.dart
//   dart run drift_dev schema generate --data-classes --companions drift_schemas test/generated_migrations
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  for (final from in [1, 2, 3]) {
    test('v$from to v4 gives exactly the v4 schema', () async {
      final schema = await verifier.schemaAt(from);
      final db = AppDatabase(schema.newConnection(), false);
      await verifier.migrateAndValidate(db, 4);
      await db.close();
    });
  }

  test('v1 to v4 keeps existing sales, the device ID and the shop name', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1'), "
        "('shop_name', 'Scoops Tamale'), ('cashier_name', 'Cashier')");
    raw.execute(
      'INSERT INTO sales (id, created_at, updated_at, device_id, number, status, '
      'subtotal, total, cashier_name) '
      "VALUES ('sale-1', 1761000000, 1761000000, 'dev-1', 1, 'completed', 1200, 1200, 'Cashier')",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final sale = await db.select(db.sales).getSingle();
    expect(sale.id, 'sale-1');
    expect(sale.cashierId, isNull);
    expect(await db.readMeta(MetaKeys.deviceId), 'dev-1');
    expect(await db.readMeta('cashier_name'), isNull);
    expect(await db.readMeta('shop_name'), isNull, reason: 'moved to settings');

    final r = await Repos.open(db);
    final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
    expect(settings.get(AppSettings.shopName), 'Scoops Tamale');

    // No staff yet, so the app will ask for the owner on next start.
    expect(await r.staff.hasStaff(), isFalse);
    await db.close();
  });

  test('v2 to v4 gives existing owners and cashiers the built-in roles', () async {
    final schema = await verifier.schemaAt(2);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1'), ('shop_name', 'Scoops Tamale')");
    raw.execute(
      'INSERT INTO staff (id, created_at, updated_at, device_id, name, role, pin_hash, active) VALUES '
      "('st-1', 1761000000, 1761000000, 'dev-1', 'Kofi', 'owner', 'v1\$1\$AA==\$AA==', 1), "
      "('st-2', 1761000000, 1761000000, 'dev-1', 'Ama', 'cashier', 'v1\$1\$AA==\$AA==', 1)",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final people = await r.staff.list();
    expect(people.map((s) => (s.name, s.role.builtIn)), [
      ('Kofi', BuiltInRole.owner),
      ('Ama', BuiltInRole.cashier),
    ]);
    expect(people.first.can(Permission.restoreBackup), isTrue);
    expect(people.last.can(Permission.voidSale), isFalse);
    await db.close();
  });

  test('v3 to v4 keeps staff and leaves their new profile empty', () async {
    final schema = await verifier.schemaAt(3);
    final raw = schema.rawDatabase;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO roles (id, created_at, updated_at, device_id, name, built_in, permissions) VALUES '
      "('${BuiltInRole.owner.id}', 1761000000, 1761000000, 'dev-1', 'Owner', 'owner', '[]')",
    );
    raw.execute(
      'INSERT INTO staff (id, created_at, updated_at, device_id, name, role_id, pin_hash, active) VALUES '
      "('st-1', 1761000000, 1761000000, 'dev-1', 'Kofi', '${BuiltInRole.owner.id}', 'v1\$1\$AA==\$AA==', 1)",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final profile = await r.staff.profile('st-1');
    expect(profile!.staff.name, 'Kofi');
    expect(profile.phone, isNull);
    expect(await r.staff.photo('st-1'), isNull);
    await db.close();
  });
}
