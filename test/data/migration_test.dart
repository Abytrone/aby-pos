import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/models/enums.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../generated_migrations/schema.dart';
import '../helpers.dart';

// Schema snapshots live in drift_schemas/. After changing a table, bump
// schemaVersion, then run:
//   dart run drift_dev schema dump lib/app/data/database/app_database.dart drift_schemas/drift_schema_vN.json
//   dart run drift_dev schema generate --data-classes --companions drift_schemas test/generated_migrations
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 to v2 gives exactly the v2 schema', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase(schema.newConnection(), false);
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('v1 to v2 keeps existing sales and the device ID', () async {
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
    expect(sale.total, 1200);
    expect(sale.cashierName, 'Cashier');
    expect(sale.cashierId, isNull);

    expect(await db.readMeta(MetaKeys.deviceId), 'dev-1');
    expect(await db.readMeta('cashier_name'), isNull);

    // No staff yet, so the app will ask for the owner on next start.
    final staff = StaffRepository(db, FakeDevice('dev-1'));
    expect(await staff.hasStaff(), isFalse);
    await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
    expect(await staff.hasStaff(), isTrue);
    await db.close();
  });
}
