import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import 'app_database.dart';

/// Fills a new database with the first customer's menu: an ice cream shop.
///
/// Seed rows are not written to the outbox and have no `syncedAt`.
/// TODO(sync): once back-office product editing exists, the server owns the
/// catalogue and this becomes a first-sync download instead.
Future<void> seedScoopsTamale(AppDatabase db, {required String deviceId}) async {
  final now = DateTime.now();
  var order = 0;

  await db.transaction(() async {
    await db.writeSettingRow(
        'shop.name', SettingScope.shop, jsonEncode('Scoops Tamale'), deviceId);

    Future<String> category(String name, CategoryTone tone) async {
      final id = newId();
      await db.into(db.categories).insert(CategoriesCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            name: name,
            tone: tone,
            sortOrder: Value(order++),
          ));
      return id;
    }

    Future<String> addon(String name, int price) async {
      final id = newId();
      await db.into(db.addons).insert(AddonsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            name: name,
            price: price,
            sortOrder: Value(order++),
          ));
      return id;
    }

    Future<void> product(
      String categoryId,
      String name, {
      required int price,
      String? detail,
      List<(String, int)> variants = const [],
      List<String> addonIds = const [],
    }) async {
      final id = newId();
      await db.into(db.products).insert(ProductsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            categoryId: categoryId,
            name: name,
            detail: Value(detail),
            basePrice: price,
            sortOrder: Value(order++),
          ));
      for (final (variantName, variantPrice) in variants) {
        await db.into(db.productVariants).insert(ProductVariantsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              productId: id,
              name: variantName,
              price: variantPrice,
              sortOrder: Value(order++),
            ));
      }
      for (final addonId in addonIds) {
        await db.into(db.productAddons).insert(ProductAddonsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              productId: id,
              addonId: addonId,
            ));
      }
    }

    final toppings = [
      await addon('Sprinkles', cedis(3)),
      await addon('Groundnut crunch', cedis(5)),
      await addon('Chocolate sauce', cedis(4)),
    ];

    final cones = await category('Cones', CategoryTone.coral);
    final cups = await category('Cups', CategoryTone.blue);
    final tubs = await category('Tubs', CategoryTone.midnight);
    final drinks = await category('Drinks', CategoryTone.lime);
    final snacks = await category('Snacks', CategoryTone.coral);

    final coneSizes = [('Single scoop', cedis(15)), ('Double scoop', cedis(22))];
    await product(cones, 'Vanilla cone',
        price: cedis(15), variants: coneSizes, addonIds: toppings);
    await product(cones, 'Chocolate cone',
        price: cedis(15), variants: coneSizes, addonIds: toppings);
    await product(cups, 'Ice cream cup',
        price: cedis(20),
        variants: [('Small', cedis(20)), ('Medium', cedis(25)), ('Large', cedis(32))],
        addonIds: toppings);
    await product(tubs, 'Ice cream tub', price: cedis(60), detail: '500 ml');
    await product(drinks, 'Milkshake', price: cedis(20), detail: '350 ml');
    await product(snacks, 'Waffle', price: cedis(12), addonIds: toppings);
  });
}
