import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/discount_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/enums.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:drift/drift.dart' show OrderingTerm, driftRuntimeOptions;
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

  for (final from in [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    23,
  ]) {
    test('v$from to v24 gives exactly the v24 schema', () async {
      final schema = await verifier.schemaAt(from);
      final db = AppDatabase(schema.newConnection(), false);
      await verifier.migrateAndValidate(db, 24);
      await db.close();
    });
  }

  test('v21 to v22 renames duplicate product and stock names before enforcing uniqueness', () async {
    final schema = await verifier.schemaAt(21);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute(
      'INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
      "VALUES ('c1', $t, $t, 'dev-1', 'Drinks', 'blue', 0)",
    );
    raw.execute(
      'INSERT INTO products (id, created_at, updated_at, device_id, category_id, name) VALUES '
      "('p1', $t, $t, 'dev-1', 'c1', 'Water'), "
      "('p2', $t, $t, 'dev-1', 'c1', ' water ')",
    );
    raw.execute(
      'INSERT INTO stock_items (id, created_at, updated_at, device_id, name, unit) VALUES '
      "('s1', $t, $t, 'dev-1', 'Bottle', 'piece'), "
      "('s2', $t, $t, 'dev-1', 'bottle', 'piece')",
    );

    final db = AppDatabase(schema.newConnection(), false);
    await verifier.migrateAndValidate(db, 22);
    expect(
      (await db.select(db.products).get()).map((p) => p.name),
      containsAll(['Water', 'water (2)']),
    );
    expect(
      (await db.select(db.stockItems).get()).map((s) => s.name),
      containsAll(['Bottle', 'bottle (2)']),
    );
    await db.close();
  });

  test(
    'v22 migrates exact-name retail stock matches into explicit variant links',
    () async {
      final schema = await verifier.schemaAt(22);
      final raw = schema.rawDatabase;
      const t = 1761000000;
      raw.execute(
        'INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
        "VALUES ('c1', $t, $t, 'dev-1', 'Shop', 'blue', 0)",
      );
      raw.execute(
        'INSERT INTO products (id, created_at, updated_at, device_id, category_id, name) VALUES '
        "('p1', $t, $t, 'dev-1', 'c1', 'Tracked product'), "
        "('p2', $t, $t, 'dev-1', 'c1', 'Made drink'), "
        "('p3', $t, $t, 'dev-1', 'c1', 'Milk')",
      );
      raw.execute(
        'INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, price) VALUES '
        "('v1', $t, $t, 'dev-1', 'p1', 500), "
        "('v2', $t, $t, 'dev-1', 'p2', 700), "
        "('v3', $t, $t, 'dev-1', 'p3', 900)",
      );
      raw.execute(
        'INSERT INTO stock_items (id, created_at, updated_at, device_id, name, unit) VALUES '
        "('s1', $t, $t, 'dev-1', 'Tracked product', 'piece'), "
        "('s2', $t, $t, 'dev-1', 'Made drink', 'piece'), "
        "('s3', $t, $t, 'dev-1', 'Milk', 'ml')",
      );
      raw.execute(
        'INSERT INTO recipe_items (id, created_at, updated_at, device_id, variant_id, stock_item_id, quantity) '
        "VALUES ('r1', $t, $t, 'dev-1', 'v2', 's3', 100)",
      );

      final db = AppDatabase(schema.newConnection(), false);
      await verifier.migrateAndValidate(db, 24);
      final variants = {
        for (final v in await db.select(db.productVariants).get()) v.id: v,
      };
      expect(variants['v1']!.stockItemId, 's1');
      expect(variants['v1']!.stockQuantity, 1);
      expect(
        variants['v2']!.stockItemId,
        isNull,
        reason: 'existing recipes remain recipes',
      );
      expect(
        variants['v3']!.stockItemId,
        isNull,
        reason: 'the old fallback only tracked piece items',
      );
      expect((await db.select(db.recipeItems).get()).single.id, 'r1');
      await db.close();
    },
  );

  test(
    'v23 converts only exact single-item self recipes at the sell-unit amount',
    () async {
      final schema = await verifier.schemaAt(23);
      final raw = schema.rawDatabase;
      const t = 1761000000;
      raw.execute(
        'INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
        "VALUES ('c1', $t, $t, 'dev-1', 'Shop', 'blue', 0)",
      );
      raw.execute(
        'INSERT INTO products (id, created_at, updated_at, device_id, category_id, name, sell_by) VALUES '
        "('p1', $t, $t, 'dev-1', 'c1', 'Water', 'each'), "
        "('p2', $t, $t, 'dev-1', 'c1', 'Rice', 'kg'), "
        "('p3', $t, $t, 'dev-1', 'c1', 'Oil', 'litre'), "
        "('p4', $t, $t, 'dev-1', 'c1', 'Drink', 'each')",
      );
      raw.execute(
        'INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, price) VALUES '
        "('v1', $t, $t, 'dev-1', 'p1', 500), "
        "('v2', $t, $t, 'dev-1', 'p2', 700), "
        "('v3', $t, $t, 'dev-1', 'p3', 900), "
        "('v4', $t, $t, 'dev-1', 'p4', 900)",
      );
      raw.execute(
        'INSERT INTO stock_items (id, created_at, updated_at, device_id, name, unit) VALUES '
        "('s1', $t, $t, 'dev-1', 'Water', 'piece'), "
        "('s2', $t, $t, 'dev-1', 'Rice', 'g'), "
        "('s3', $t, $t, 'dev-1', 'Oil', 'ml'), "
        "('s4', $t, $t, 'dev-1', 'Sugar', 'piece'), "
        "('s5', $t, $t, 'dev-1', 'Drink extra', 'piece')",
      );
      raw.execute(
        'INSERT INTO recipe_items (id, created_at, updated_at, device_id, variant_id, stock_item_id, quantity) VALUES '
        "('r1', $t, $t, 'dev-1', 'v1', 's1', 1), "
        "('r2', $t, $t, 'dev-1', 'v2', 's2', 1000), "
        "('r3', $t, $t, 'dev-1', 'v3', 's3', 1000), "
        "('r4', $t, $t, 'dev-1', 'v4', 's4', 1), "
        "('r5', $t, $t, 'dev-1', 'v4', 's5', 1)",
      );

      final db = AppDatabase(schema.newConnection(), false);
      await verifier.migrateAndValidate(db, 24);
      final variants = {
        for (final v in await db.select(db.productVariants).get()) v.id: v,
      };
      expect(variants['v1']!.stockItemId, 's1');
      expect(variants['v2']!.stockItemId, 's2');
      expect(variants['v3']!.stockItemId, 's3');
      expect(
        variants['v4']!.stockItemId,
        isNull,
        reason: 'multi-item recipes remain recipes',
      );
      final activeRecipes = await (db.select(
        db.recipeItems,
      )..where((r) => r.deletedAt.isNull())).get();
      expect(activeRecipes.map((r) => r.id), ['r4', 'r5']);
      await db.close();
    },
  );

  test(
    'v1 to v6 keeps existing sales, the device ID and the shop name',
    () async {
      final schema = await verifier.schemaAt(1);
      final raw = schema.rawDatabase;
      raw.execute(
        "INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1'), "
        "('shop_name', 'Scoops Tamale'), ('cashier_name', 'Cashier')",
      );
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
      expect(
        await db.readMeta('shop_name'),
        isNull,
        reason: 'moved to settings',
      );

      final r = await Repos.open(db);
      final settings = SettingsService(
        SettingsRepository(db, r.device, r.audit),
      );
      await settings.load();
      expect(settings.get(AppSettings.shopName), 'Scoops Tamale');

      // No staff yet, so the app will ask for the owner on next start.
      expect(await r.staff.hasStaff(), isFalse);
      await db.close();
    },
  );

  test(
    'v2 to v6 gives existing owners and cashiers the built-in roles',
    () async {
      final schema = await verifier.schemaAt(2);
      final raw = schema.rawDatabase;
      raw.execute(
        "INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1'), ('shop_name', 'Scoops Tamale')",
      );
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
    },
  );

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
    raw.execute(
      'INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
      "VALUES ('c1', $t, $t, 'dev-1', 'Cones', 'coral', 0)",
    );
    raw.execute(
      'INSERT INTO products (id, created_at, updated_at, device_id, category_id, name, base_price, active, sort_order) VALUES '
      "('p-cone', $t, $t, 'dev-1', 'c1', 'Vanilla cone', 1500, 1, 0), "
      "('p-waffle', $t, $t, 'dev-1', 'c1', 'Waffle', 1200, 1, 1)",
    );
    raw.execute(
      'INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, name, price, sort_order) VALUES '
      "('v-single', $t, $t, 'dev-1', 'p-cone', 'Single scoop', 1500, 0), "
      "('v-double', $t, $t, 'dev-1', 'p-cone', 'Double scoop', 2200, 1)",
    );
    raw.execute(
      'INSERT INTO addons (id, created_at, updated_at, device_id, name, price, active, sort_order) VALUES '
      "('a-sprinkles', $t, $t, 'dev-1', 'Sprinkles', 300, 1, 0)",
    );
    raw.execute(
      'INSERT INTO product_addons (id, created_at, updated_at, device_id, product_id, addon_id) VALUES '
      "('pa1', $t, $t, 'dev-1', 'p-waffle', 'a-sprinkles')",
    );
    raw.execute(
      'INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
      "VALUES ('s1', $t, $t, 'dev-1', 1, 'completed', 1500, 1500, 'Ama')",
    );
    raw.execute(
      'INSERT INTO stock_movements (id, created_at, updated_at, device_id, product_id, quantity_change, reason, sale_id) '
      "VALUES ('m1', $t, $t, 'dev-1', 'p-waffle', -1, 'sale', 's1')",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final menu = await r.catalog.load();
    final waffle = menu.products.firstWhere((p) => p.name == 'Waffle');
    expect(waffle.isSimple, isTrue);
    expect(waffle.variants.single.price, 1200, reason: 'old base price');
    expect(waffle.groups.single.name, 'Options');
    expect(
      waffle.groups.single.options.single.id,
      'a-sprinkles',
      reason: 'same ID as the old add-on',
    );
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
    raw.execute(
      'INSERT INTO categories (id, created_at, updated_at, device_id, name, tone, sort_order) '
      "VALUES ('c1', $t, $t, 'dev-1', 'Snacks', 'coral', 0)",
    );
    raw.execute(
      'INSERT INTO products (id, created_at, updated_at, device_id, category_id, name, active, sort_order) '
      "VALUES ('p-waffle', $t, $t, 'dev-1', 'c1', 'Waffle', 1, 0)",
    );
    raw.execute(
      'INSERT INTO product_variants (id, created_at, updated_at, device_id, product_id, price, sort_order) '
      "VALUES ('v-waffle', $t, $t, 'dev-1', 'p-waffle', 1200, 0)",
    );
    raw.execute(
      'INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
      "VALUES ('s1', $t, $t, 'dev-1', 1, 'completed', 1200, 1200, 'Ama')",
    );
    raw.execute(
      'INSERT INTO sale_lines (id, created_at, updated_at, device_id, sale_id, product_id, variant_id, '
      'product_name, quantity, unit_price, line_total) '
      "VALUES ('l1', $t, $t, 'dev-1', 's1', 'p-waffle', 'v-waffle', 'Waffle', 1, 1200, 1200)",
    );

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
    expect(
      (await discounts.reasons(ReasonKind.voidSale)).map((x) => x.name),
      contains('Wrong item rung up'),
    );
    expect(await discounts.discounts(), isEmpty);
    await db.close();
  });

  test(
    'v6 to v7 gives old payments their method and adds the payment methods',
    () async {
      final schema = await verifier.schemaAt(6);
      final raw = schema.rawDatabase;
      const t = 1761000000;
      raw.execute(
        "INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')",
      );
      raw.execute(
        'INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
        "VALUES ('s1', $t, $t, 'dev-1', 1, 'completed', 1200, 1200, 'Ama')",
      );
      raw.execute(
        'INSERT INTO payments (id, created_at, updated_at, device_id, sale_id, method, amount, momo_reference) '
        "VALUES ('p1', $t, $t, 'dev-1', 's1', 'momo', 1200, 'TX1')",
      );

      final db = AppDatabase(schema.newConnection(), false);
      final payment = await db.select(db.payments).getSingle();
      expect(payment.methodName, 'MTN MoMo');
      expect(payment.methodId, payMethodRowId('mtn'));
      expect((await db.select(db.sales).getSingle()).rounding, 0);
      final r = await Repos.open(db);
      expect(
        (await r.payMethods.list()).map((m) => m.name),
        contains('Telecel Cash'),
      );
      expect((await r.closes.openPeriod()).byMethod[PaymentMethod.momo], 1200);
      await db.close();
    },
  );

  test('v7 to v8 turns the old credit book into customers with what they owe', () async {
    final schema = await verifier.schemaAt(7);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO roles (id, created_at, updated_at, device_id, name, built_in, permissions, max_discount_percent, sort_order) '
      "VALUES ('${BuiltInRole.manager.id}', $t, $t, 'dev-1', 'Manager', 'manager', '[\"sell\"]', 50, 1)",
    );
    for (final (id, n, who, amount) in [
      ('s1', 1, 'Auntie Akos', 1200),
      ('s2', 2, '024 123 4567', 2000),
      ('s3', 3, 'auntie akos', 500),
    ]) {
      raw.execute(
        'INSERT INTO sales (id, created_at, updated_at, device_id, number, status, subtotal, total, cashier_name) '
        "VALUES ('$id', ${t + n}, ${t + n}, 'dev-1', $n, 'completed', $amount, $amount, 'Ama')",
      );
      raw.execute(
        'INSERT INTO payments (id, created_at, updated_at, device_id, sale_id, method, amount, customer) '
        "VALUES ('p$n', ${t + n}, ${t + n}, 'dev-1', '$id', 'credit', $amount, '$who')",
      );
    }

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final customers = await r.customers.list();
    expect(
      customers.map((c) => (c.name, c.owed)),
      unorderedEquals([('Auntie Akos', 1700), ('024 123 4567', 2000)]),
    );
    expect(customers.firstWhere((c) => c.owed == 2000).phone, '+233241234567');
    expect(
      (await (db.select(
        db.sales,
      )..where((s) => s.id.equals('s3'))).getSingle()).customerId,
      customers.firstWhere((c) => c.name == 'Auntie Akos').id,
    );
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(BuiltInRole.manager.id))).getSingle();
    expect(role.permissions, contains(Permission.manageCustomers));
    expect((await r.payMethods.list()).map((m) => m.name), contains('Wallet'));
    await db.close();
  });

  test('v8 to v9 keeps closes, gives managers the cash permission and adds pay-out reasons', () async {
    final schema = await verifier.schemaAt(8);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO roles (id, created_at, updated_at, device_id, name, built_in, permissions, max_discount_percent, sort_order) '
      "VALUES ('${BuiltInRole.manager.id}', $t, $t, 'dev-1', 'Manager', 'manager', '[\"sell\"]', 50, 1)",
    );
    raw.execute(
      'INSERT INTO day_closes (id, created_at, updated_at, device_id, closed_at, last_sale_number, closed_by_id, '
      'closed_by_name, sales_count, voided_count, sales_total, cash_takings, momo_takings, credit_takings, opening_float, '
      "expected_cash, counted_cash) VALUES ('d1', $t, $t, 'dev-1', $t, 3, 'st', 'Kofi', 3, 0, 4500, 4500, 0, 0, 1000, 5500, 5500)",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    final close = (await r.closes.history()).single;
    expect(close.difference, 0);
    expect(close.payOuts, 0);
    expect(close.cashCount.isEmpty, isTrue);
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(BuiltInRole.manager.id))).getSingle();
    expect(role.permissions, contains(Permission.manageCash));
    expect(
      (await DiscountRepository(
        db,
        r.device,
        r.audit,
      ).reasons(ReasonKind.payOut)).map((x) => x.name),
      contains('Ice'),
    );
    expect(await r.shifts.current(), isNull);
    await db.close();
  });

  test('v9 to v10 adds the expense categories and gives managers expenses', () async {
    final schema = await verifier.schemaAt(9);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO roles (id, created_at, updated_at, device_id, name, built_in, permissions, max_discount_percent, sort_order) '
      "VALUES ('${BuiltInRole.manager.id}', $t, $t, 'dev-1', 'Manager', 'manager', '[\"sell\"]', 50, 1)",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final r = await Repos.open(db);
    expect(
      (await r.expenses.categories()).map((c) => c.name),
      contains('Electricity (ECG)'),
    );
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(BuiltInRole.manager.id))).getSingle();
    expect(role.permissions, contains(Permission.manageExpenses));
    await db.close();
  });

  test('v10 to v11 keeps sale lines (no promotion) and options (no linked product)', () async {
    final schema = await verifier.schemaAt(10);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO option_groups (id, created_at, updated_at, device_id, name) '
      "VALUES ('g1', $t, $t, 'dev-1', 'Toppings')",
    );
    raw.execute(
      'INSERT INTO option_items (id, created_at, updated_at, device_id, group_id, name, price_delta) '
      "VALUES ('o1', $t, $t, 'dev-1', 'g1', 'Sprinkles', 300)",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final option = await (db.select(
      db.optionItems,
    )..where((o) => o.id.equals('o1'))).getSingle();
    expect(option.variantId, isNull);
    expect(await db.select(db.promotions).get(), isEmpty);
    await db.close();
  });

  test(
    'v11 to v12 adds gift vouchers and the gift voucher payment method',
    () async {
      final schema = await verifier.schemaAt(11);
      schema.rawDatabase.execute(
        "INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')",
      );
      final db = AppDatabase(schema.newConnection(), false);
      final r = await Repos.open(db);
      expect(
        (await r.payMethods.list(includeInactive: true))
            .where((m) => m.kind == PaymentMethod.voucher),
        hasLength(1),
      );
      expect(await r.vouchers.list(), isEmpty);
      await db.close();
    },
  );

  test('v17 to v18 keeps categories, with no icon picked yet', () async {
    final schema = await verifier.schemaAt(17);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO categories (id, created_at, updated_at, device_id, name, tone) '
      "VALUES ('c1', $t, $t, 'dev-1', 'Drinks', 'blue')",
    );
    final db = AppDatabase(schema.newConnection(), false);
    final row = await (db.select(
      db.categories,
    )..where((c) => c.id.equals('c1'))).getSingle();
    expect((row.name, row.icon), ('Drinks', null));
    await db.close();
  });

  test('v18 to v19 lets managers manage devices', () async {
    final schema = await verifier.schemaAt(18);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO roles (id, created_at, updated_at, device_id, name, built_in, permissions, max_discount_percent, sort_order) '
      "VALUES ('${BuiltInRole.manager.id}', $t, $t, 'dev-1', 'Manager', 'manager', '[\"sell\"]', 50, 1)",
    );

    final db = AppDatabase(schema.newConnection(), false);
    final role = await (db.select(
      db.roles,
    )..where((x) => x.id.equals(BuiltInRole.manager.id))).getSingle();
    expect(
      role.permissions,
      containsAll({Permission.sell, Permission.manageDevices}),
    );
    await db.close();
  });

  test('v19 to v20 numbers staff from 101 in the order they were added', () async {
    final schema = await verifier.schemaAt(19);
    final raw = schema.rawDatabase;
    const t = 1761000000;
    raw.execute("INSERT INTO meta (key, value) VALUES ('device_id', 'dev-1')");
    raw.execute(
      'INSERT INTO roles (id, created_at, updated_at, device_id, name, built_in, permissions, max_discount_percent, sort_order) '
      "VALUES ('${BuiltInRole.owner.id}', $t, $t, 'dev-1', 'Owner', 'owner', '[]', 100, 0)",
    );
    for (final (id, name, at) in [('s2', 'Ama', t + 60), ('s1', 'Kofi', t)]) {
      raw.execute(
        'INSERT INTO staff (id, created_at, updated_at, device_id, name, role_id, pin_hash) '
        "VALUES ('$id', $at, $at, 'dev-1', '$name', '${BuiltInRole.owner.id}', 'x')",
      );
    }

    final db = AppDatabase(schema.newConnection(), false);
    final rows = await (db.select(
      db.staffMembers,
    )..orderBy([(s) => OrderingTerm(expression: s.name)])).get();
    expect(
      [for (final r in rows) (r.name, r.staffNumber)],
      [('Ama', '102'), ('Kofi', '101')],
    );
    await db.close();
  });
}
