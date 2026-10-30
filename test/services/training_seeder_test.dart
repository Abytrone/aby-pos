import 'dart:typed_data';

import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/domain/business_templates.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/training_seeder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late Staff boss;

  setUp(() async {
    db = memoryDb(seed: false);
    r = await Repos.open(db);
    boss = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
  });
  tearDown(() => db.close());

  Future<void> shopOf(BusinessType type, {String tax = 'off'}) async {
    final settings = SettingsRepository(db, r.device, r.audit);
    await settings.write(AppSettings.shopName, 'Mama Ese Enterprise', by: boss);
    await settings.write(AppSettings.shopType, type.name, by: boss);
    await settings.write(AppSettings.taxMode, tax, by: boss);
    if (type == BusinessType.chopBar) {
      await settings.write(AppSettings.ordersOn, true, by: boss);
      await settings.write(AppSettings.orderTypes, true, by: boss);
    }
    if (type == BusinessType.iceCream) await settings.write(AppSettings.loyaltyStyle, 'stamps', by: boss);
  }

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle()).read<int>('n');

  final png = Uint8List.fromList(img.encodePng(img.Image(width: 4, height: 4)));

  test('the sample shop fills every table, connected, under the real shop name and staff', () async {
    await shopOf(BusinessType.iceCream, tax: 'inclusive');
    await r.catalog.saveCategory(const CategoryDraft(name: 'Real category', tone: CategoryTone.blue), by: boss);

    await TrainingSeeder(db, photo: (_) async => png).run();

    final tables = [
      for (final row in await db.customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'").get())
        row.read<String>('name'),
    ];
    final empty = [for (final t in tables) if (await count(t) == 0) t];
    // The local hub's tables belong to a hub, which a training copy never is.
    expect(empty, unorderedEquals(['hub_changes', 'hub_devices']));

    final menu = await r.catalog.load(includeInactive: true);
    expect(menu.categories.map((c) => c.name), isNot(contains('Real category')), reason: 'the real catalogue is replaced');
    expect(menu.products.map((p) => p.name), contains('Vanilla cone'));
    expect((await r.staff.list()).map((s) => s.name), containsAll(['Kofi', 'Mariam Issah']));
    final shopName = await db.customSelect("SELECT value FROM settings WHERE key = 'shop.name'").getSingle();
    expect(shopName.read<String>('value'), '"Mama Ese Enterprise"');

    // A month of closes, each picking up where the last left off.
    final closes = await r.closes.history(limit: 100);
    expect(closes, hasLength(28));
    expect(await r.audit.verifyChain().then((s) => s.isIntact), isTrue);
    // Sales use stock, and every delivery is on the supplier's account.
    final sales = await count('sales');
    expect(sales, greaterThan(150));
    expect(await count("stock_movements WHERE reason = 'sale'"), greaterThan(sales));
    Future<int> sum(String sql) async => (await db.customSelect(sql).getSingle()).read<int>('n');
    expect(
      await sum("SELECT SUM(amount) AS n FROM supplier_ledger WHERE kind = 'purchase'"),
      await sum('SELECT SUM(total) AS n FROM stock_receipts'),
    );
  });

  test('something sold by weight comes back whole', () async {
    await shopOf(BusinessType.provision);
    await TrainingSeeder(db).run();
    final rice = await db.customSelect(
      "SELECT r.quantity AS back, l.quantity AS sold FROM refund_lines r JOIN sale_lines l ON l.id = r.sale_line_id WHERE r.sell_by = 'kg'",
    ).get();
    expect(rice, isNotEmpty);
    for (final row in rice) {
      expect(row.read<int>('back'), row.read<int>('sold'));
    }
  });

  for (final type in BusinessType.values) {
    test('a ${type.name} sample shop trades', () async {
      await shopOf(type);
      await TrainingSeeder(db, days: 14).run();
      expect(await count('sales'), greaterThan(50));
      expect(await count('day_closes'), 14);
      expect(await count('stock_receipts'), greaterThan(0));
      expect(await r.audit.verifyChain().then((s) => s.isIntact), isTrue);
    });
  }
}
