import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/units.dart';
import '../../models/enums.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import 'app_database.dart';

/// Test fixture: fills a new database with the first customer's menu: an ice cream shop,
/// with stock items, recipes and some opening stock so the till shows what
/// is left from day one.
///
/// Seed rows are not written to the outbox and have no `syncedAt`.
/// TODO(sync): once the server owns the catalogue, this becomes a
/// first-sync download instead.
/// [photos] are pictures by product name (the brand kit's drawn samples):
/// demo data only, for the shop to replace with its own.
Future<void> seedScoopsTamale(AppDatabase db, {required String deviceId, Map<String, Uint8List> photos = const {}}) async {
  final now = DateTime.now();
  var order = 0;

  await db.transaction(() async {
    await db.writeSettingRow('shop.name', SettingScope.shop, jsonEncode('Scoops Tamale'), deviceId);

    // ---- Stock items: what the shop buys -----------------------------------
    Future<String> stock(String name, StockUnit unit, int pesewasPerBulk, int opening) async {
      final id = newId();
      final costMilli = costMilliFromPrice(pesewasPerBulk, DisplayUnit.bulk(unit));
      await db.into(db.stockItems).insert(StockItemsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            name: name,
            unit: unit,
            costMilli: Value(costMilli),
            reorderPoint: Value(opening ~/ 4),
            reorderQty: Value(opening),
          ));
      await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            stockItemId: Value(id),
            quantityChange: opening,
            reason: StockReason.adjustment,
            unitCostMilli: Value(costMilli),
            note: const Value('Opening stock'),
          ));
      return id;
    }

    final cone = await stock('Wafer cones', StockUnit.piece, 80, 200);
    final cupS = await stock('Cups, small', StockUnit.piece, 50, 150);
    final cupM = await stock('Cups, medium', StockUnit.piece, 60, 150);
    final cupL = await stock('Cups, large', StockUnit.piece, 70, 100);
    final vanilla = await stock('Vanilla ice cream', StockUnit.ml, cedis(45), 20000);
    final chocolate = await stock('Chocolate ice cream', StockUnit.ml, cedis(50), 15000);
    final tubs = await stock('Ice cream tubs, 500 ml', StockUnit.piece, cedis(30), 24);
    final milk = await stock('Milk', StockUnit.ml, cedis(25), 10000);
    final waffleMix = await stock('Waffle mix', StockUnit.g, cedis(35), 5000);
    final sprinkles = await stock('Sprinkles', StockUnit.g, cedis(40), 2000);
    final crunch = await stock('Groundnut crunch', StockUnit.g, cedis(30), 2000);
    final sauce = await stock('Chocolate sauce', StockUnit.ml, cedis(60), 3000);
    // Dairy keeps batches and expiry dates (INV-07).
    for (final id in [vanilla, chocolate, milk]) {
      await (db.update(db.stockItems)..where((s) => s.id.equals(id))).write(const StockItemsCompanion(tracksExpiry: Value(true)));
    }

    Future<void> recipe(List<(String, int)> items, {String? variantId, String? optionId}) async {
      for (final (item, qty) in items) {
        await db.into(db.recipeItems).insert(RecipeItemsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              variantId: Value(variantId),
              optionId: Value(optionId),
              stockItemId: item,
              quantity: qty,
            ));
      }
    }

    // ---- Toppings ------------------------------------------------------------
    final toppings = newId();
    await db.into(db.optionGroups).insert(OptionGroupsCompanion.insert(
          id: toppings,
          createdAt: now,
          updatedAt: now,
          deviceId: deviceId,
          name: 'Toppings',
          maxSelect: const Value(3),
          allowRepeat: const Value(true),
        ));
    for (final (name, price, item, qty) in [
      ('Sprinkles', cedis(3), sprinkles, 10),
      ('Groundnut crunch', cedis(5), crunch, 15),
      ('Chocolate sauce', cedis(4), sauce, 20),
    ]) {
      final id = newId();
      await db.into(db.optionItems).insert(OptionItemsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: deviceId,
            groupId: toppings,
            name: name,
            priceDelta: Value(price),
            sortOrder: Value(order++),
          ));
      await recipe([(item, qty)], optionId: id);
    }

    // ---- Menu ------------------------------------------------------------------
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

    Future<void> product(
      String categoryId,
      String name, {
      String? detail,
      required List<(String?, int, List<(String, int)>)> variants,
      bool withToppings = false,
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
            sortOrder: Value(order++),
          ));
      final photo = photos[name];
      if (photo != null) {
        await db.into(db.productPhotos).insert(ProductPhotosCompanion.insert(productId: id, image: photo, updatedAt: now));
      }
      for (final (i, (variantName, price, items)) in variants.indexed) {
        final variantId = newId();
        await db.into(db.productVariants).insert(ProductVariantsCompanion.insert(
              id: variantId,
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              productId: id,
              name: Value(variantName),
              price: price,
              sortOrder: Value(i),
            ));
        await recipe(items, variantId: variantId);
      }
      if (withToppings) {
        await db.into(db.productOptionGroups).insert(ProductOptionGroupsCompanion.insert(
              id: newId(),
              createdAt: now,
              updatedAt: now,
              deviceId: deviceId,
              productId: id,
              groupId: toppings,
            ));
      }
    }

    final cones = await category('Cones', CategoryTone.coral);
    final cups = await category('Cups', CategoryTone.blue);
    final tubsCat = await category('Tubs', CategoryTone.midnight);
    final drinks = await category('Drinks', CategoryTone.lime);
    final snacks = await category('Snacks', CategoryTone.coral);

    await product(cones, 'Vanilla cone', withToppings: true, variants: [
      ('Single scoop', cedis(15), [(cone, 1), (vanilla, 80)]),
      ('Double scoop', cedis(22), [(cone, 1), (vanilla, 160)]),
    ]);
    await product(cones, 'Chocolate cone', withToppings: true, variants: [
      ('Single scoop', cedis(15), [(cone, 1), (chocolate, 80)]),
      ('Double scoop', cedis(22), [(cone, 1), (chocolate, 160)]),
    ]);
    await product(cups, 'Ice cream cup', withToppings: true, variants: [
      ('Small', cedis(20), [(cupS, 1), (vanilla, 120)]),
      ('Medium', cedis(25), [(cupM, 1), (vanilla, 180)]),
      ('Large', cedis(32), [(cupL, 1), (vanilla, 250)]),
    ]);
    await product(tubsCat, 'Ice cream tub', detail: '500 ml', variants: [
      (null, cedis(60), [(tubs, 1)]),
    ]);
    await product(drinks, 'Milkshake', detail: '350 ml', variants: [
      (null, cedis(20), [(milk, 200), (vanilla, 100)]),
    ]);
    await product(snacks, 'Waffle', withToppings: true, variants: [
      (null, cedis(12), [(waffleMix, 120)]),
    ]);
  });
}
