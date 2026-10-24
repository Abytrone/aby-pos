import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/discount_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/enums.dart';
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

  for (final from in [1, 2, 3, 4, 5, 6]) {
    test('v$from to v7 gives exactly the v7 schema', () async {
      final schema = await verifier.schemaAt(from);
      final db = AppDatabase(schema.newConnection(), false);
      await verifier.migrateAndValidate(db, 7);
      await db.close();
    });
  }

  test('v1 to v6 keeps existing sales, the device ID and the shop name', () async {
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

  test('v2 to v6 gives existing owners and cashiers the built-in roles', () async {
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

  test('v3 to v6 keeps staff and leaves their new profile empty', () async {
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

  test('v4 to v6 gives every product a price, turns add-ons into options, keeps history', () async {
    final schema = await verifier.schemaAt(4);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute('INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
        "VALUES ('c1', $t, $t, 'dev-1', 'Cones', 'coral', 0)");
    raw.execute('INSERT INTO products (id, created_at, updated_at, device_id, category_id, name, base_price, active, sort_order) VALUES '
        "('p-cone', $t, $t, 'dev-1', 'c1', 'Vanilla cone', 1500, 1, 0), "
        "('p-waffle', $t, $t, 'dev-1', 'c1', 'Waffle', 1200, 1, 1)");
    raw.execute('INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, name, price, sort_order) VALUES '
        "('v-single', $t, $t, 'dev-1', 'p-cone', 'Single scoop', 1500, 0), "
        "('v-double', $t, $t, 'dev-1', 'p-cone', 'Double scoop', 2200, 1)");
    raw.execute('INSERT INTO addons (id, created_at, updated_at, device_id, name, price, active, sort_order) VALUES '
        "('a-sprinkles', $t, $t, 'dev-1', 'Sprinkles', 300, 1, 0)");
    raw.execute('INSERT INTO product_addons (id, created_at, updated_at, device_id, product_id, addon_id) VALUES '
        "('pa1', $t, $t, 'dev-1', 'p-waffle', 'a-sprinkles')");
    raw.execute('INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
        "VALUES ('s1', $t, $t, 'dev-1', 1, 'completed', 1500, 1500, 'Ama')");
    raw.execute('INSERT INTO stock_movements (id, created_at, updated_at, device_id, product_id, quantity_change, reason, sale_id) '
        "VALUES ('m1', $t, $t, 'dev-1', 'p-waffle', -1, 'sale', 's1')");

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final menu = await r.catalog.load();
    final waffle = menu.products.firstWhere((p) => p.name == 'Waffle');
    expect(waffle.isSimple, isTrue);
    expect(waffle.variants.single.price, 1200, reason: 'old base price');
    expect(waffle.groups.single.name, 'Toppings');
    expect(waffle.groups.single.options.single.id, 'a-sprinkles', reason: 'same ID as the old add-on');
    final cone = menu.products.firstWhere((p) => p.name == 'Vanilla cone');
    expect(cone.variants.map((v) => v.name), ['Single scoop', 'Double scoop']);
    expect(cone.groups, isEmpty);

    final moves = await db.select(db.stockMovements).get();
    expect(moves.single.productId, 'p-waffle');
    expect(moves.single.stockItemId, isNull);
    final sale = await db.select(db.sales).getSingle();
    expect(sale.taxTotal, 0);
    await db.close();
  });

  test('v5 to v6 keeps sales and products as they were and adds the reasons lists', () async {
    final schema = await verifier.schemaAt(5);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute('INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
        "VALUES ('c1', $t, $t, 'dev-1', 'Snacks', 'coral', 0)");
    raw.execute('INSERT INTO products (id, created_at, updated_at, device_id, category_id, name, active, sort_order) '
        "VALUES ('p-waffle', $t, $t, 'dev-1', 'c1', 'Waffle', 1, 0)");
    raw.execute('INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, price, sort_order) '
        "VALUES ('v-waffle', $t, $t, 'dev-1', 'p-waffle', 1200, 0)");
    raw.execute('INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
        "VALUES ('s1', $t, $t, 'dev-1', 1, 'completed', 1200, 1200, 'Ama')");
    raw.execute('INSERT INTO sale_lines (id, created_at, updated_at, device_id, sale_id, product_id, variant_id, '
        'product_name, quantity, unit_price, line_total) '
        "VALUES ('l1', $t, $t, 'dev-1', 's1', 'p-waffle', 'v-waffle', 'Waffle', 1, 1200, 1200)");

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final waffle = (await r.catalog.load()).products.single;
    expect(waffle.sellBy, SellBy.each);
    expect(waffle.openPrice, isFalse);
    expect(waffle.quickOrder, isNull);
    final sale = await db.select(db.sales).getSingle();
    expect(sale.discountTotal, 0);
    expect(sale.orderType, isNull);
    final line = await db.select(db.saleLines).getSingle();
    expect(line.discount, 0);
    expect(line.listPrice, isNull);
    final discounts = DiscountRepository(db, r.device, r.audit);
    expect((await discounts.reasons(ReasonKind.voidSale)).map((x) => x.name), contains('Wrong item rung up'));
    expect(await discounts.discounts(), isEmpty);
    await db.close();
  });

  test('v6 to v7 gives old payments their method and adds the payment methods', () async {
    final schema = await verifier.schemaAt(6);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute('INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
        "VALUES ('s1', $t, $t, 'dev-1', 1, 'completed', 1200, 1200, 'Ama')");
    raw.execute('INSERT INTO payments (id, created_at, updated_at, device_id, sale_id, method, amount, momo_reference) '
        "VALUES ('p1', $t, $t, 'dev-1', 's1', 'momo', 1200, 'TX1')");

    final db = AppDatabase(schema.newConnection(), false);
    final payment = await db.select(db.payments).getSingle();
    expect(payment.methodName, 'MTN MoMo');
    expect(payment.methodId, payMethodRowId('mtn'));
    expect((await db.select(db.sales).getSingle()).rounding, 0);
    final r = await Repos.open(db);
    expect((await r.payMethods.list()).map((m) => m.name), contains('Telecel Cash'));
    expect((await r.closes.openPeriod()).byMethod[PaymentMethod.momo], 1200);
    await db.close();
  });
}
