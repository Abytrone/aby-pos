import '../core/csv.dart';
import '../core/units.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../models/audit.dart';
import '../models/catalog.dart';
import '../models/drafts.dart';
import '../models/enums.dart';
import '../models/staff.dart';
import '../models/stock.dart';
import '../data/repositories/audit_repository.dart';
import '../services/money.dart';
import '../services/ids.dart';
import 'business_templates.dart';
import 'catalogue_rules.dart';
import 'documents/table_doc.dart';

/// One problem in an import file. [row] counts from 1 for the header.
class ImportProblem {
  const ImportProblem(this.row, this.message);
  final int row;
  final String message;
}

/// What an import would do, worked out before anything is saved.
class ImportPreview {
  const ImportPreview({
    required this.drafts,
    required this.stockItems,
    required this.newProducts,
    required this.updatedProducts,
    required this.unchanged,
    required this.newCategories,
    required this.problems,
  });

  /// Product name → draft (new or updated).
  final List<ProductDraft> drafts;
  final List<ProductStockImport> stockItems;
  final int newProducts;
  final int updatedProducts;
  final int unchanged;
  final List<String> newCategories;
  final List<ImportProblem> problems;

  int get newStockItems => stockItems.where((i) => i.isNew).length;
  int get updatedStockItems => stockItems.where((i) => !i.isNew).length;
  int get recountedStockItems => stockItems.where((i) => i.change != 0).length;

  bool get canApply =>
      problems.isEmpty && (drafts.isNotEmpty || stockItems.isNotEmpty);
}

/// A direct-stock item created or updated from a product import row.
class ProductStockImport {
  const ProductStockImport({
    required this.draft,
    required this.onHandNow,
    required this.isNew,
    this.setOnHand,
    this.reactivate = false,
  });

  final StockItemDraft draft;
  final int onHandNow;
  final bool isNew;
  final int? setOnHand;
  final bool reactivate;

  int get change => setOnHand == null ? 0 : setOnHand! - onHandNow;
}

/// Products to and from CSV, so a shop with hundreds of items can start
/// from a spreadsheet. Import only adds products and updates prices, costs,
/// barcodes and optional direct stock counts: it never removes variants,
/// recipes, options or taxes.
class CatalogueIo {
  CatalogueIo(this._catalog, this._rules, this._stock, this._audit);

  final CatalogRepository _catalog;
  final CatalogueRules _rules;
  final StockRepository _stock;
  final AuditRepository _audit;

  static const productColumns = [
    'category',
    'product',
    'variant',
    'price',
    'cost',
    'barcodes',
    'tile_line',
    'on_till',
    'on_hand',
    'low_below',
    'stock_item',
    'stock_quantity',
    'sell_by',
  ];

  /// The columns an import must have.
  static const requiredColumns = {'product', 'price'};

  /// Other names spreadsheets use for the same columns, so a shop's own
  /// price list imports without renaming its headings.
  static const _aliases = {
    'name': 'product',
    'item': 'product',
    'product_name': 'product',
    'item_name': 'product',
    'selling_price': 'price',
    'sell_price': 'price',
    'sale_price': 'price',
    'unit_price': 'price',
    'retail_price': 'price',
    'cost_price': 'cost',
    'buying_price': 'cost',
    'purchase_price': 'cost',
    'unit_cost': 'cost',
    'barcode': 'barcodes',
    'ean': 'barcodes',
    'upc': 'barcodes',
    'size': 'variant',
    'variant_name': 'variant',
    'group': 'category',
    'department': 'category',
    'category_name': 'category',
    'detail': 'tile_line',
    'tile': 'tile_line',
    'on_sale': 'on_till',
    'active': 'on_till',
    'quantity': 'on_hand',
    'qty': 'on_hand',
    'stock': 'on_hand',
    'stock_on_hand': 'on_hand',
    'count': 'on_hand',
    'reorder_point': 'low_below',
    'reorder_level': 'low_below',
    'reorder_at': 'low_below',
    'low_stock': 'low_below',
    'minimum': 'low_below',
    'min': 'low_below',
    'linked_stock_item': 'stock_item',
    'stock_item_name': 'stock_item',
    'quantity_per_sale': 'stock_quantity',
    'stock_per_sale': 'stock_quantity',
    'sale_unit': 'sell_by',
    'sold_by': 'sell_by',
  };

  /// A heading as the importer reads it: "Selling price" is "price".
  static String columnFor(String heading) {
    final h = heading
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z_]'), '');
    return _aliases[h] ?? h;
  }

  /// A filled-in example for [type] of shop, to download, edit in a
  /// spreadsheet and import: every column, a product with sizes, barcodes
  /// (several split by "|") and one product kept off the till.
  String sampleProducts(BusinessType type) =>
      Csv.encode([productColumns, ..._samples(type)]);

  static List<List<String>> _samples(BusinessType type) => switch (type) {
    BusinessType.iceCream => const [
      ['Cones', 'Vanilla cone', 'Single scoop', '15.00', '6.50', '', '', 'yes'],
      [
        'Cones',
        'Vanilla cone',
        'Double scoop',
        '22.00',
        '11.00',
        '',
        '',
        'yes',
      ],
      ['Cups', 'Strawberry cup', 'Small', '20.00', '8.00', '', '', 'yes'],
      ['Cups', 'Strawberry cup', 'Large', '32.00', '13.00', '', '', 'yes'],
      ['Drinks', 'Milkshake', '', '20.00', '9.00', '', '350 ml', 'yes'],
      ['Snacks', 'Waffle', '', '12.00', '', '', '', 'no'],
    ],
    BusinessType.chopBar => const [
      ['Food', 'Jollof rice', 'Small', '30.00', '14.00', '', '', 'yes'],
      ['Food', 'Jollof rice', 'Large', '45.00', '20.00', '', '', 'yes'],
      ['Soups', 'Light soup and fufu', '', '40.00', '18.00', '', '', 'yes'],
      ['Drinks', 'Sobolo', '', '8.00', '3.00', '', '500 ml', 'yes'],
      ['Extras', 'Fried egg', '', '5.00', '2.50', '', '', 'yes'],
      ['Extras', 'Extra meat', '', '15.00', '', '', '', 'no'],
    ],
    BusinessType.pharmacy => const [
      [
        'Medicines',
        'Paracetamol 500 mg',
        'Strip',
        '5.00',
        '2.80',
        '6001234500011',
        '10 tablets',
        'yes',
      ],
      [
        'Medicines',
        'Paracetamol 500 mg',
        'Box',
        '45.00',
        '26.00',
        '6001234500028',
        '100 tablets',
        'yes',
      ],
      [
        'Personal care',
        'Hand sanitiser',
        '',
        '18.00',
        '11.00',
        '6001234500035',
        '250 ml',
        'yes',
      ],
      ['Baby', 'Diapers', 'Size 3', '95.00', '72.00', '', '', 'yes'],
      ['First aid', 'Plasters', '', '10.00', '5.50', '', '20 pack', 'yes'],
      ['First aid', 'Bandage', '', '12.00', '', '', '', 'no'],
    ],
    BusinessType.salon => const [
      ['Services', 'Hair wash', '', '30.00', '', '', '', 'yes'],
      ['Services', 'Braids', 'Medium', '250.00', '', '', '', 'yes'],
      ['Services', 'Braids', 'Long', '350.00', '', '', '', 'yes'],
      [
        'Products',
        'Hair cream',
        '',
        '45.00',
        '28.00',
        '6001234500042',
        '',
        'yes',
      ],
      ['Products', 'Hair net', '', '10.00', '', '', '', 'no'],
    ],
    BusinessType.phones => const [
      [
        'Phones',
        'Smartphone A15',
        '64 GB',
        '1500.00',
        '1250.00',
        '',
        '',
        'yes',
      ],
      [
        'Phones',
        'Smartphone A15',
        '128 GB',
        '1800.00',
        '1500.00',
        '',
        '',
        'yes',
      ],
      [
        'Accessories',
        'Phone charger',
        '',
        '60.00',
        '35.00',
        '6001234500059|6001234500066',
        '',
        'yes',
      ],
      ['Repairs', 'Screen repair', '', '250.00', '', '', '', 'yes'],
      ['Airtime and data', 'Airtime', '', '10.00', '9.70', '', '', 'yes'],
      ['Accessories', 'Earphones', '', '40.00', '', '', '', 'no'],
    ],
    BusinessType.boutique => const [
      ['Women', 'Kente dress', 'S', '350.00', '210.00', '', '', 'yes'],
      ['Women', 'Kente dress', 'M', '350.00', '210.00', '', '', 'yes'],
      ['Men', 'Polo shirt', 'M', '120.00', '70.00', '', '', 'yes'],
      ['Men', 'Polo shirt', 'L', '120.00', '70.00', '', '', 'yes'],
      [
        'Shoes and bags',
        'Sandals',
        '',
        '90.00',
        '55.00',
        '6001234500073',
        '',
        'yes',
      ],
      ['Children', 'School socks', '', '15.00', '', '', '', 'no'],
    ],
    BusinessType.building => const [
      [
        'Cement and blocks',
        'Cement',
        '',
        '95.00',
        '82.00',
        '',
        '50 kg bag',
        'yes',
      ],
      ['Roofing', 'Roofing sheet', '', '85.00', '68.00', '', '', 'yes'],
      ['Plumbing', 'PVC pipe', '1/2 inch', '25.00', '15.00', '', '', 'yes'],
      ['Plumbing', 'PVC pipe', '1 inch', '40.00', '26.00', '', '', 'yes'],
      [
        'Electrical',
        'Light bulb',
        '',
        '15.00',
        '8.00',
        '6001234500080',
        'LED 9 W',
        'yes',
      ],
      ['Paint and tools', 'Paint brush', '', '20.00', '', '', '', 'no'],
    ],
    BusinessType.provision || BusinessType.other => const [
      [
        'Drinks',
        'Malt drink',
        '',
        '8.00',
        '5.50',
        '6001234500097',
        '330 ml',
        'yes',
      ],
      [
        'Drinks',
        'Bottled water',
        '',
        '3.00',
        '1.80',
        '6001234500103|6001234500110',
        '500 ml',
        'yes',
      ],
      [
        'Provisions',
        'Rice',
        '1 kg',
        '25.00',
        '19.00',
        '6001234500127',
        '',
        'yes',
      ],
      [
        'Provisions',
        'Rice',
        '5 kg',
        '115.00',
        '92.00',
        '6001234500134',
        '',
        'yes',
      ],
      [
        'Toiletries',
        'Bathing soap',
        '',
        '6.50',
        '4.20',
        '6001234500141',
        '',
        'yes',
      ],
      ['Snacks', 'Biscuits', '', '4.00', '', '', '', 'no'],
    ],
  };

  static String _money(int? p) =>
      p == null ? '' : '${p ~/ 100}.${(p % 100).toString().padLeft(2, '0')}';

  /// One row per variant.
  Future<String> exportProducts(Catalogue c) async {
    final rows = <List<String>>[productColumns];
    final stockById = {
      for (final item in await _stock.items(includeInactive: true))
        item.id: item,
    };
    for (final p in c.products.where((p) => !p.archived)) {
      final category = c.category(p.categoryId)?.name ?? '';
      for (final v in p.variants) {
        final expectedStockName = v.name == null
            ? p.name
            : '${p.name} - ${v.name}';
        final linkedStock = v.stockLink == null
            ? null
            : stockById[v.stockLink!.stockItemId];
        final legacyStock =
            v.recipe.length == 1 &&
                v.recipe.single.quantity == 1 &&
                v.recipe.single.unit == StockUnit.piece &&
                stockById[v.recipe.single.stockItemId]?.name.toLowerCase() ==
                    expectedStockName.toLowerCase()
            ? stockById[v.recipe.single.stockItemId]
            : null;
        final directStock = linkedStock ?? legacyStock;
        rows.add([
          category,
          p.name,
          v.name ?? '',
          _money(v.price),
          _money(v.recipe.isEmpty ? v.cost : null),
          v.barcodes.join('|'),
          p.detail ?? '',
          p.active ? 'yes' : 'no',
          directStock?.unit == StockUnit.piece
              ? directStock!.onHand.toString()
              : '',
          directStock?.unit == StockUnit.piece
              ? directStock!.reorderPoint?.toString() ?? ''
              : '',
          directStock?.name ?? '',
          directStock == null
              ? ''
              : (v.stockLink?.quantity ??
                        (legacyStock == null ? 1 : v.recipe.single.quantity))
                    .toString(),
          p.sellBy.name,
        ]);
      }
    }
    return Csv.encode(rows);
  }

  /// The file stock import reads back. [suppliers]: supplier ID to name.
  String exportStock(
    List<StockItem> items, {
    Map<String, String> suppliers = const {},
  }) {
    final rows = <List<String>>[
      [
        'stock_item',
        'unit',
        'cost_per',
        'cost',
        'on_hand',
        'low_below',
        'order_qty',
        'supplier',
      ],
    ];
    for (final i in items.where((i) => i.active)) {
      final bulk = DisplayUnit.bulk(i.unit);
      rows.add([
        i.name,
        i.unit.name,
        bulk.symbol,
        _money(i.bulkPrice),
        quantityIn(i.onHand, bulk),
        i.reorderPoint == null ? '' : quantityIn(i.reorderPoint!, bulk),
        i.reorderQty == null ? '' : quantityIn(i.reorderQty!, bulk),
        suppliers[i.supplierId] ?? '',
      ]);
    }
    return Csv.encode(rows);
  }

  /// The menu as a price list, grouped by category: a PDF to print or send
  /// to customers, or a workbook. Hidden and archived products are left out.
  TableDoc priceList(Catalogue c, {required String shopName}) {
    final order = {for (final (i, cat) in c.categories.indexed) cat.id: i};
    final products = c.products.where((p) => !p.archived && p.active).toList()
      ..sort(
        (a, b) => (order[a.categoryId] ?? 1 << 30).compareTo(
          order[b.categoryId] ?? 1 << 30,
        ),
      );
    return TableDoc(
      title: 'Price list',
      shopName: shopName,
      period: docDay(DateTime.now()),
      sheets: [
        DocSheet(
          name: 'Price list',
          columns: const [
            DocColumn('Category'),
            DocColumn('Product'),
            DocColumn('Price (GH₵)', DocKind.money),
            DocColumn('Barcode'),
          ],
          rows: [
            for (final p in products)
              for (final v in p.variants)
                [
                  c.category(p.categoryId)?.name ?? '',
                  v.name == null ? p.name : '${p.name}, ${v.name}',
                  v.price,
                  v.barcodes.firstOrNull,
                ],
          ],
          groupBy: 0,
        ),
      ],
    );
  }

  /// Stock on hand and what it is worth at cost.
  TableDoc stockDoc(List<StockItem> items, {required String shopName}) =>
      TableDoc(
        title: 'Stock',
        shopName: shopName,
        period: docTime(DateTime.now()),
        sheets: [
          DocSheet(
            name: 'Stock',
            columns: const [
              DocColumn('Item'),
              DocColumn('On hand', DocKind.count),
              DocColumn('Low below', DocKind.count),
              DocColumn('Cost (GH₵)', DocKind.money),
              DocColumn('Per'),
              DocColumn.bars('Value at cost (GH₵)'),
              DocColumn('Status'),
            ],
            rows: [
              for (final i in items.where((i) => i.active))
                [
                  i.name,
                  i.onHandText,
                  i.reorderPoint == null
                      ? null
                      : formatQuantity(i.reorderPoint!, i.unit),
                  i.bulkPrice,
                  DisplayUnit.bulk(i.unit).symbol,
                  i.value,
                  i.isLow ? 'Low' : (i.onHand <= 0 ? 'Out' : ''),
                ],
            ],
          ),
        ],
      );

  /// Reads a CSV and works out what would change. Nothing is saved.
  Future<ImportPreview> previewProducts(String csv) async {
    final rows = Csv.decode(csv);
    final problems = <ImportProblem>[];
    if (rows.isEmpty) {
      return const ImportPreview(
        drafts: [],
        stockItems: [],
        newProducts: 0,
        updatedProducts: 0,
        unchanged: 0,
        newCategories: [],
        problems: [ImportProblem(1, 'The file is empty.')],
      );
    }
    final header = [for (final h in rows.first) columnFor(h)];
    int col(String name) => header.indexOf(name);
    if (col('product') < 0 || col('price') < 0) {
      return ImportPreview(
        drafts: const [],
        stockItems: const [],
        newProducts: 0,
        updatedProducts: 0,
        unchanged: 0,
        newCategories: const [],
        problems: const [
          ImportProblem(
            1,
            'The first row needs at least "product" and "price" columns.',
          ),
        ],
      );
    }
    String cell(List<String> r, String name) {
      final i = col(name);
      return i < 0 || i >= r.length ? '' : r[i].trim();
    }

    final catalogue = await _catalog.load(
      includeInactive: true,
      includeArchived: true,
    );
    final stockItems = await _stock.items(includeInactive: true);
    final stockById = {for (final item in stockItems) item.id: item};
    final stockByName = {
      for (final item in stockItems) item.name.toLowerCase(): item,
    };
    final linkedStockIds = {
      for (final product in catalogue.products)
        for (final variant in product.variants)
          if (variant.stockLink != null) variant.stockLink!.stockItemId,
      for (final product in catalogue.products)
        for (final variant in product.variants)
          for (final line in variant.recipe) line.stockItemId,
      for (final group in catalogue.groups)
        for (final option in group.options)
          for (final line in option.recipe) line.stockItemId,
    };
    final categoriesByName = {
      for (final c in catalogue.categories) c.name.toLowerCase(): c,
    };
    final productsByName = {
      for (final p in catalogue.products.where((p) => !p.archived))
        p.name.toLowerCase(): p,
    };

    // Group rows by product.
    final grouped = <String, List<(int, List<String>)>>{};
    for (final (i, r) in rows.skip(1).indexed) {
      final name = cell(r, 'product');
      if (name.isEmpty) {
        problems.add(ImportProblem(i + 2, 'No product name.'));
        continue;
      }
      grouped.putIfAbsent(name.toLowerCase(), () => []).add((i + 2, r));
    }

    final drafts = <ProductDraft>[];
    final importedStock = <String, ProductStockImport>{};
    final newCategories = <String>{};
    var created = 0;
    var updated = 0;
    var unchanged = 0;
    for (final entry in grouped.values) {
      final first = entry.first.$2;
      final name = cell(first, 'product');
      final existing = productsByName[name.toLowerCase()];
      final categoryName = cell(first, 'category');
      String? categoryId = existing?.categoryId;
      if (categoryName.isNotEmpty) {
        final match = categoriesByName[categoryName.toLowerCase()];
        if (match != null) {
          categoryId = match.id;
        } else {
          newCategories.add(categoryName);
          categoryId = 'new:$categoryName';
        }
      }
      if (categoryId == null) {
        problems.add(ImportProblem(entry.first.$1, 'No category for $name.'));
        continue;
      }

      final variants = <VariantDraft>[
        for (final v in existing?.variants ?? const <Variant>[])
          VariantDraft(
            id: v.id,
            name: v.name,
            price: v.price,
            manualCost: v.manualCost,
            stockItemId: v.stockLink?.stockItemId,
            stockQuantity: v.stockLink?.quantity ?? 1,
            barcodes: v.barcodes,
            recipe: [
              for (final r in v.recipe)
                RecipeDraftLine(
                  stockItemId: r.stockItemId,
                  quantity: r.quantity,
                ),
            ],
          ),
      ];
      var changed = existing == null;
      SellBy? productSellBy;
      for (final (rowNo, r) in entry) {
        final price = parseMoney(cell(r, 'price'));
        if (price == null) {
          problems.add(ImportProblem(rowNo, 'Check the price for $name.'));
          continue;
        }
        final costText = cell(r, 'cost');
        final cost = costText.isEmpty ? null : parseMoney(costText);
        if (costText.isNotEmpty && cost == null) {
          problems.add(ImportProblem(rowNo, 'Check the cost for $name.'));
          continue;
        }
        final sellByText = cell(r, 'sell_by').toLowerCase();
        final importedSellBy = switch (sellByText) {
          '' => existing?.sellBy ?? SellBy.each,
          'each' || 'piece' || 'pieces' => SellBy.each,
          'kg' || 'kilogram' || 'kilograms' => SellBy.kg,
          'l' || 'litre' || 'liter' || 'litres' || 'liters' => SellBy.litre,
          _ => null,
        };
        if (importedSellBy == null) {
          problems.add(
            ImportProblem(
              rowNo,
              'Check sell_by for $name: use each, kg or litre.',
            ),
          );
          continue;
        }
        if (sellByText.isNotEmpty) {
          if (productSellBy != null && productSellBy != importedSellBy) {
            problems.add(
              ImportProblem(
                rowNo,
                '$name must use the same sell_by value for every variant.',
              ),
            );
            continue;
          }
          productSellBy = importedSellBy;
        } else {
          productSellBy ??= existing?.sellBy ?? SellBy.each;
        }
        final onHandText = cell(r, 'on_hand');
        final onHand = onHandText.isEmpty
            ? null
            : parseQuantity(onHandText, DisplayUnit.piece);
        if (onHandText.isNotEmpty && (onHand == null || onHand < 0)) {
          problems.add(
            ImportProblem(
              rowNo,
              'Check on_hand for $name: enter a whole number of pieces.',
            ),
          );
          continue;
        }
        final lowText = cell(r, 'low_below');
        final low = lowText.isEmpty
            ? null
            : parseQuantity(lowText, DisplayUnit.piece);
        if (lowText.isNotEmpty && (low == null || low < 0)) {
          problems.add(
            ImportProblem(
              rowNo,
              'Check low_below for $name: enter a whole number of pieces.',
            ),
          );
          continue;
        }
        final variantName = cell(r, 'variant');
        final barcodesText = cell(r, 'barcodes');
        final barcodes = barcodesText.isEmpty
            ? null
            : barcodesText
                  .split(RegExp(r'[|;]'))
                  .map((b) => b.trim())
                  .where((b) => b.isNotEmpty)
                  .toList();
        var index = variants.indexWhere(
          (v) =>
              (v.name ?? '').toLowerCase() == variantName.toLowerCase() ||
              (variants.length == 1 && v.name == null && variantName.isEmpty),
        );
        if (index == -1) {
          variants.add(
            VariantDraft(
              id: onHandText.isNotEmpty || lowText.isNotEmpty ? newId() : null,
              name: variantName.isEmpty ? null : variantName,
              price: price,
              manualCost: cost,
              barcodes: barcodes ?? const [],
            ),
          );
          index = variants.length - 1;
          changed = true;
        } else {
          final old = variants[index];
          final next = VariantDraft(
            id: old.id,
            name: old.name,
            price: price,
            manualCost: costText.isEmpty || old.stockItemId != null
                ? old.manualCost
                : cost,
            stockItemId: old.stockItemId,
            stockQuantity: old.stockQuantity,
            barcodes: barcodes ?? old.barcodes,
            recipe: old.recipe,
          );
          if (next.price != old.price ||
              next.manualCost != old.manualCost ||
              next.barcodes.join('|') != old.barcodes.join('|')) {
            changed = true;
          }
          variants[index] = next;
        }

        final stockNameText = cell(r, 'stock_item');
        final existingDirectLink = variants[index].stockItemId;
        final stockQuantityText = cell(r, 'stock_quantity');
        if (stockNameText.isEmpty &&
            stockQuantityText.isNotEmpty &&
            existingDirectLink == null) {
          problems.add(
            ImportProblem(
              rowNo,
              'stock_quantity needs an existing or specified stock_item for $name.',
            ),
          );
          continue;
        }
        if (stockNameText.isNotEmpty ||
            (existingDirectLink != null &&
                (cost != null || stockQuantityText.isNotEmpty))) {
          final linked = stockNameText.isEmpty
              ? stockById[existingDirectLink]
              : stockByName[stockNameText.toLowerCase()];
          if (linked == null) {
            if (stockNameText.isNotEmpty) {
              problems.add(
                ImportProblem(
                  rowNo,
                  'Stock item "$stockNameText" was not found. Import stock items first.',
                ),
              );
            }
            continue;
          }
          final expectedUnit = switch (importedSellBy) {
            SellBy.each => StockUnit.piece,
            SellBy.kg => StockUnit.g,
            SellBy.litre => StockUnit.ml,
          };
          if (linked.unit != expectedUnit) {
            problems.add(
              ImportProblem(
                rowNo,
                '"${stockNameText.isEmpty ? linked.name : stockNameText}" is measured in ${linked.unit.name}, which is incompatible with '
                '${importedSellBy.name}.',
              ),
            );
            continue;
          }
          final quantity = stockQuantityText.isEmpty
              ? variants[index].stockQuantity
              : int.tryParse(stockQuantityText);
          if (quantity == null || quantity <= 0) {
            problems.add(
              ImportProblem(
                rowNo,
                'Enter a positive whole-number stock_quantity for $name.',
              ),
            );
            continue;
          }
          final old = variants[index];
          if ((stockNameText.isNotEmpty || stockQuantityText.isNotEmpty) &&
              (old.stockItemId != linked.id || old.stockQuantity != quantity)) {
            variants[index] = VariantDraft(
              id: old.id ?? newId(),
              name: old.name,
              price: old.price,
              manualCost: old.manualCost,
              stockItemId: linked.id,
              stockQuantity: quantity,
              barcodes: old.barcodes,
            );
            changed = true;
          }
          if (cost != null) {
            final linkedCostMilli = (cost * 1000 + quantity ~/ 2) ~/ quantity;
            if (linkedCostMilli != linked.costMilli) {
              changed = true;
              importedStock[linked.id] = ProductStockImport(
                draft: StockItemDraft(
                  id: linked.id,
                  name: linked.name,
                  unit: linked.unit,
                  costMilli: linkedCostMilli,
                  reorderPoint: linked.reorderPoint,
                  reorderQty: linked.reorderQty,
                  supplierId: linked.supplierId,
                  tracksExpiry: linked.tracksExpiry,
                ),
                onHandNow: linked.onHand,
                isNew: false,
                setOnHand: null,
                reactivate: false,
              );
            }
          }
        }

        if (onHandText.isNotEmpty || lowText.isNotEmpty) {
          var variant = variants[index];
          final expectedStockName = variantName.isEmpty
              ? name
              : '$name - $variantName';
          StockItem? directStock;
          final legacyRecipe =
              variant.stockItemId == null && variant.recipe.isNotEmpty;
          if (variant.stockItemId != null) {
            directStock = stockById[variant.stockItemId];
            if (directStock == null || directStock.unit != StockUnit.piece) {
              problems.add(
                ImportProblem(
                  rowNo,
                  '$expectedStockName is not linked to a piece-based stock item.',
                ),
              );
              continue;
            }
          } else if (variant.recipe.isNotEmpty) {
            if (variant.recipe.length == 1 &&
                variant.recipe.single.quantity == 1 &&
                stockById[variant.recipe.single.stockItemId]?.unit ==
                    StockUnit.piece &&
                stockById[variant.recipe.single.stockItemId]?.name
                        .toLowerCase() ==
                    expectedStockName.toLowerCase()) {
              directStock = stockById[variant.recipe.single.stockItemId];
            } else {
              problems.add(
                ImportProblem(
                  rowNo,
                  '$name${variantName.isEmpty ? '' : ' ($variantName)'} already has a recipe. '
                  'Use on_hand only for a product that is stocked as individual pieces.',
                ),
              );
              continue;
            }
          } else {
            final namedStock = stockByName[expectedStockName.toLowerCase()];
            if (namedStock != null && namedStock.unit != StockUnit.piece) {
              problems.add(
                ImportProblem(
                  rowNo,
                  '$expectedStockName is already stocked in ${namedStock.unit.name}, not pieces.',
                ),
              );
              continue;
            }
            if (namedStock != null && linkedStockIds.contains(namedStock.id)) {
              problems.add(
                ImportProblem(
                  rowNo,
                  '$expectedStockName is already used by another product recipe.',
                ),
              );
              continue;
            }
            directStock = namedStock;
          }

          final itemId = directStock?.id ?? newId();
          if (legacyRecipe || variant.stockItemId == null) {
            variant = VariantDraft(
              id: variant.id ?? newId(),
              name: variant.name,
              price: variant.price,
              stockItemId: itemId,
              stockQuantity: 1,
              barcodes: variant.barcodes,
            );
            variants[index] = variant;
            changed = true;
          }
          final previous = directStock;
          final stockName = previous?.name ?? expectedStockName;
          final stockDraft = StockItemDraft(
            id: itemId,
            name: stockName,
            unit: StockUnit.piece,
            costMilli: cost == null
                ? (previous?.costMilli ?? (variant.manualCost ?? 0) * 1000)
                : (cost * 1000 + (variant.stockQuantity ~/ 2)) ~/
                      variant.stockQuantity,
            reorderPoint: lowText.isEmpty ? previous?.reorderPoint : low,
            reorderQty: previous?.reorderQty,
            supplierId: previous?.supplierId,
            tracksExpiry: previous?.tracksExpiry ?? false,
          );
          final isNew = previous == null;
          final stockPlan = ProductStockImport(
            draft: stockDraft,
            onHandNow: previous?.onHand ?? 0,
            isNew: isNew,
            setOnHand: onHand,
            reactivate: previous != null && !previous.active,
          );
          if (isNew ||
              stockDraft.costMilli != previous.costMilli ||
              stockDraft.reorderPoint != previous.reorderPoint ||
              stockPlan.change != 0 ||
              stockPlan.reactivate) {
            importedStock[itemId] = stockPlan;
          }
        }
      }
      // Two unnamed variants: the second needs a name.
      if (variants.length > 1 && variants.any((v) => (v.name ?? '').isEmpty)) {
        problems.add(
          ImportProblem(
            entry.first.$1,
            '$name has several prices: give each a variant name.',
          ),
        );
        continue;
      }
      final onTill = cell(first, 'on_till').toLowerCase();
      final tile = cell(first, 'tile_line');
      final draft = ProductDraft(
        id: existing?.id,
        categoryId: categoryId,
        name: existing?.name ?? name,
        detail: tile.isEmpty ? existing?.detail : tile,
        description: existing?.description,
        active: onTill.isEmpty
            ? (existing?.active ?? true)
            : !['no', 'false', '0', 'off'].contains(onTill),
        variants: variants,
        groupIds: [
          for (final g in existing?.groups ?? const <OptionGroup>[]) g.id,
        ],
        taxIds: [for (final t in existing?.taxes ?? const <TaxRate>[]) t.id],
        sellBy: productSellBy ?? existing?.sellBy ?? SellBy.each,
        openPrice: existing?.openPrice ?? false,
        minPrice: existing?.minPrice,
        maxPrice: existing?.maxPrice,
        onQuickTab: existing?.quickOrder != null,
      );
      if (existing != null &&
          (draft.active != existing.active ||
              draft.detail != existing.detail ||
              draft.sellBy != existing.sellBy)) {
        changed = true;
      }
      if (!changed) {
        unchanged++;
        continue;
      }
      existing == null ? created++ : updated++;
      drafts.add(draft);
    }
    return ImportPreview(
      drafts: drafts,
      stockItems: importedStock.values.toList(),
      newProducts: created,
      updatedProducts: updated,
      unchanged: unchanged,
      newCategories: newCategories.toList(),
      problems: problems,
    );
  }

  /// Saves a preview: all of it, or none of it.
  Future<void> applyProducts(ImportPreview preview, {required Staff by}) async {
    if (!preview.canApply)
      throw const CatalogueException('Fix the problems in the file first.');
    await _catalog.transaction(() async {
      final created = <String, String>{};
      for (final name in preview.newCategories) {
        created[name] = await _rules.saveCategory(
          CategoryDraft(name: name, tone: CategoryTone.blue),
          by: by,
        );
      }
      for (final item in preview.stockItems) {
        final id = await _stock.saveItem(
          item.draft,
          by: by,
          createNew: item.isNew,
        );
        if (item.reactivate)
          await _stock.setItemActive(id, active: true, by: by);
        if (item.setOnHand case final target?) {
          final change = target - await _stock.onHand(id);
          if (change != 0)
            await _stock.adjust(id, change, note: 'Product import', by: by);
        }
      }
      for (final d in preview.drafts) {
        final categoryId = d.categoryId.startsWith('new:')
            ? created[d.categoryId.substring(4)]!
            : d.categoryId;
        await _rules.saveProduct(d.copyWith(categoryId: categoryId), by: by);
      }
      await _audit.record(
        action: AuditAction.catalogueImported,
        actor: by,
        summary:
            'Imported ${preview.newProducts} new and ${preview.updatedProducts} changed products',
      );
    });
  }
}
