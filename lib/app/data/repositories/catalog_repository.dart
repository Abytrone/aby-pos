import 'package:drift/drift.dart';

import '../../models/catalog.dart';
import '../database/app_database.dart';

/// Reads the menu: categories, products, sizes and toppings.
class CatalogRepository {
  CatalogRepository(this._db);

  final AppDatabase _db;

  Future<List<Category>> categories() async {
    final rows = await (_db.select(_db.categories)
          ..where((c) => c.deletedAt.isNull())
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .get();
    return [
      for (final r in rows) Category(id: r.id, name: r.name, tone: r.tone),
    ];
  }

  /// Active products with their variants and add-ons, in menu order.
  Future<List<Product>> products() async {
    final productRows = await (_db.select(_db.products)
          ..where((p) => p.deletedAt.isNull() & p.active.equals(true))
          ..orderBy([(p) => OrderingTerm(expression: p.sortOrder)]))
        .get();

    final variantRows = await (_db.select(_db.productVariants)
          ..where((v) => v.deletedAt.isNull())
          ..orderBy([(v) => OrderingTerm(expression: v.sortOrder)]))
        .get();

    final addonQuery = _db.select(_db.productAddons).join([
      innerJoin(_db.addons, _db.addons.id.equalsExp(_db.productAddons.addonId)),
    ])
      ..where(_db.productAddons.deletedAt.isNull() &
          _db.addons.deletedAt.isNull() &
          _db.addons.active.equals(true))
      ..orderBy([OrderingTerm(expression: _db.addons.sortOrder)]);
    final addonRows = await addonQuery.get();

    final variantsByProduct = <String, List<Variant>>{};
    for (final v in variantRows) {
      variantsByProduct
          .putIfAbsent(v.productId, () => [])
          .add(Variant(id: v.id, name: v.name, price: v.price));
    }

    final addonsByProduct = <String, List<Addon>>{};
    for (final row in addonRows) {
      final link = row.readTable(_db.productAddons);
      final a = row.readTable(_db.addons);
      addonsByProduct
          .putIfAbsent(link.productId, () => [])
          .add(Addon(id: a.id, name: a.name, price: a.price));
    }

    return [
      for (final p in productRows)
        Product(
          id: p.id,
          categoryId: p.categoryId,
          name: p.name,
          detail: p.detail,
          basePrice: p.basePrice,
          variants: variantsByProduct[p.id] ?? const [],
          addons: addonsByProduct[p.id] ?? const [],
        ),
    ];
  }
}
