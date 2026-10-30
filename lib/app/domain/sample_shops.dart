import '../models/enums.dart';
import 'business_templates.dart';

/// The pretend shops training mode practises on (APP-05), one per kind of
/// business: what each sells and buys, and from whom. Everything here is
/// made up. TrainingSeeder turns it into a shop with a month of trading.
///
/// Prices are pesewas. Stock is named, and products use it by name.

class SampleSupplier {
  const SampleSupplier(this.name, {required this.phone, required this.address, this.termsDays});

  final String name;
  final String phone;
  final String address;

  /// Days they give to pay; null for pay on delivery.
  final int? termsDays;
}

class SampleStock {
  const SampleStock(
    this.name,
    this.unit, {
    required this.cost,
    this.per = 1,
    required this.opening,
    required this.supplier,
    this.expiry = false,
  });

  final String name;
  final StockUnit unit;

  /// Pesewas for [per] base units (GH₵ 45 for 1000 ml).
  final int cost;
  final int per;

  /// Base units delivered at the start, and again when it runs low.
  final int opening;

  /// Index into [SampleShop.suppliers].
  final int supplier;

  /// Batches and expiry dates (INV-07).
  final bool expiry;

  /// Thousandths of a pesewa per base unit.
  int get costMilli => cost * 1000 ~/ per;
}

/// A stock item made here from others (INV-08): [makes] base units of
/// [item] from one batch of [uses].
class SampleMade {
  const SampleMade(this.item, {required this.makes, required this.uses});

  final String item;
  final int makes;
  final List<(String, int)> uses;
}

class SampleOption {
  const SampleOption(this.name, {this.price = 0, this.uses = const [], this.isDefault = false});

  final String name;
  final int price;
  final List<(String, int)> uses;
  final bool isDefault;
}

class SampleGroup {
  const SampleGroup(this.name, this.options, {this.min = 0, this.max, this.repeat = false});

  final String name;
  final List<SampleOption> options;
  final int min;
  final int? max;
  final bool repeat;
}

class SampleVariant {
  const SampleVariant(this.name, this.price, {this.uses = const [], this.cost});

  /// Null for a product's only variant.
  final String? name;
  final int price;

  /// (stock item, base units) used per one sold (per kg when weighed).
  final List<(String, int)> uses;

  /// Pesewas, for what uses no stock (a service).
  final int? cost;
}

class SampleProduct {
  const SampleProduct(
    this.category,
    this.name,
    this.variants, {
    this.detail,
    this.groups = const [],
    this.sellBy = SellBy.each,
    this.quick = false,
    this.openPrice = false,
    this.minPrice,
    this.maxPrice,
    this.photo,
    this.popular = 1,
  });

  final String category;
  final String name;
  final List<SampleVariant> variants;
  final String? detail;
  final List<String> groups;
  final SellBy sellBy;
  final bool quick;
  final bool openPrice;
  final int? minPrice;
  final int? maxPrice;

  /// A picture in assets/samples/ (no extension).
  final String? photo;

  /// How often it sells compared with the rest (1 to 5).
  final int popular;
}

/// A deal on one product: [quantity] or more cost [price] each, or buy
/// [quantity] get one free when [price] is null.
class SampleDeal {
  const SampleDeal(this.name, this.product, {required this.quantity, this.price});

  final String name;
  final String product;
  final int quantity;
  final int? price;
}

class SampleShop {
  const SampleShop({
    required this.categories,
    required this.suppliers,
    required this.stock,
    this.made,
    this.groups = const [],
    required this.products,
    required this.deals,
    required this.spendThreshold,
    required this.branch,
  });

  final List<(String, CategoryTone)> categories;
  final List<SampleSupplier> suppliers;
  final List<SampleStock> stock;
  final SampleMade? made;
  final List<SampleGroup> groups;
  final List<SampleProduct> products;
  final List<SampleDeal> deals;

  /// Pesewas spent for the "spend and save" promotion.
  final int spendThreshold;

  /// The second branch stock is sent to.
  final String branch;

  static SampleShop of(BusinessType t) => switch (t) {
        BusinessType.iceCream => _iceCream,
        BusinessType.provision => _provision,
        BusinessType.chopBar => _chopBar,
        BusinessType.pharmacy => _pharmacy,
        BusinessType.salon => _salon,
        BusinessType.phones => _phones,
        BusinessType.boutique => _boutique,
        BusinessType.building => _building,
        BusinessType.other => _other,
      };
}

/// The pretend people who buy, shared by every sample shop.
class SampleCustomer {
  const SampleCustomer(this.name, this.phone, {this.location, this.tags = const [], this.creditLimit, this.dueDays, this.birthday});

  final String name;
  final String phone;
  final String? location;
  final List<String> tags;
  final int? creditLimit;
  final int? dueDays;

  /// (month, day).
  final (int, int)? birthday;
}

const sampleCustomers = [
  SampleCustomer('Abena Owusu', '0244100101', location: 'Near the Lamashegu mosque', tags: ['Regular'], creditLimit: 50000, dueDays: 14, birthday: (3, 14)),
  SampleCustomer('Yakubu Alhassan', '0244100102', location: 'Kalpohin, behind the school', tags: ['Wholesale'], creditLimit: 200000, dueDays: 30),
  SampleCustomer('Efua Asante', '0244100103', location: 'Vittin estates', birthday: (11, 2)),
  SampleCustomer('Mohammed Sumani', '0244100104', location: 'Aboabo market, stall 12', tags: ['Wholesale', 'Regular'], creditLimit: 150000, dueDays: 30),
  SampleCustomer('Akosua Boateng', '0244100105', location: 'Changli'),
  SampleCustomer('Ibrahim Fuseini', '0244100106', location: 'Sakasaka, opposite the clinic', tags: ['Regular'], creditLimit: 30000, dueDays: 7),
  SampleCustomer('Adjoa Mensah', '0244100107', location: 'Gumani', birthday: (7, 21)),
  SampleCustomer('Kojo Appiah', '0244100108', location: 'Choggu'),
  SampleCustomer('Salamatu Iddrisu', '0244100109', location: 'Nyohini', tags: ['Staff'], creditLimit: 20000, dueDays: 30),
  SampleCustomer('Yaw Darko', '0244100110', location: 'Kanvilli'),
  SampleCustomer('Rahinatu Abdulai', '0244100111', location: 'Tishigu', tags: ['Regular']),
  SampleCustomer('Kwesi Ofori', '0244100112', location: 'Ward K'),
];

/// Pretend staff: (name, role, phone, usual hours as minutes after midnight).
const sampleStaff = [
  ('Mariam Issah', 'manager', '0244200201', 7 * 60 + 30, 18 * 60),
  ('Kwame Asante', 'cashier', '0244200202', 8 * 60, 17 * 60),
  ('Fatima Yakubu', 'cashier', '0244200203', 10 * 60, 19 * 60),
  ('Issah Musah', 'stockKeeper', '0244200204', 7 * 60, 15 * 60),
];

const _iceCream = SampleShop(
  branch: 'Sakasaka kiosk',
  spendThreshold: 10000,
  categories: [
    ('Cones', CategoryTone.coral),
    ('Cups', CategoryTone.blue),
    ('Tubs', CategoryTone.midnight),
    ('Drinks', CategoryTone.lime),
    ('Snacks', CategoryTone.amber),
  ],
  suppliers: [
    SampleSupplier('Northern Dairy Supplies', phone: '0244300301', address: 'Industrial area, Tamale', termsDays: 14),
    SampleSupplier('Lamashegu Packaging', phone: '0244300302', address: 'Lamashegu market road'),
    SampleSupplier('Aboabo Market Traders', phone: '0244300303', address: 'Aboabo market, Tamale', termsDays: 7),
  ],
  stock: [
    SampleStock('Wafer cones', StockUnit.piece, cost: 80, opening: 300, supplier: 1),
    SampleStock('Cups, small', StockUnit.piece, cost: 50, opening: 200, supplier: 1),
    SampleStock('Cups, medium', StockUnit.piece, cost: 60, opening: 200, supplier: 1),
    SampleStock('Cups, large', StockUnit.piece, cost: 70, opening: 150, supplier: 1),
    SampleStock('Vanilla ice cream', StockUnit.ml, cost: 4500, per: 1000, opening: 30000, supplier: 0, expiry: true),
    SampleStock('Chocolate ice cream', StockUnit.ml, cost: 5000, per: 1000, opening: 20000, supplier: 0, expiry: true),
    SampleStock('Strawberry ice cream', StockUnit.ml, cost: 5000, per: 1000, opening: 15000, supplier: 0, expiry: true),
    SampleStock('Ice cream tubs, 500 ml', StockUnit.piece, cost: 3000, opening: 36, supplier: 0, expiry: true),
    SampleStock('Milk', StockUnit.ml, cost: 2500, per: 1000, opening: 15000, supplier: 0, expiry: true),
    SampleStock('Waffle mix', StockUnit.g, cost: 3500, per: 1000, opening: 8000, supplier: 2),
    SampleStock('Waffle batter', StockUnit.g, cost: 0, opening: 0, supplier: 2),
    SampleStock('Sprinkles', StockUnit.g, cost: 4000, per: 1000, opening: 3000, supplier: 2),
    SampleStock('Groundnut crunch', StockUnit.g, cost: 3000, per: 1000, opening: 3000, supplier: 2),
    SampleStock('Chocolate sauce', StockUnit.ml, cost: 6000, per: 1000, opening: 4000, supplier: 2),
  ],
  made: SampleMade('Waffle batter', makes: 2000, uses: [('Waffle mix', 1200), ('Milk', 800)]),
  groups: [
    SampleGroup('Toppings', max: 3, repeat: true, [
      SampleOption('Sprinkles', price: 300, uses: [('Sprinkles', 10)]),
      SampleOption('Groundnut crunch', price: 500, uses: [('Groundnut crunch', 15)]),
      SampleOption('Chocolate sauce', price: 400, uses: [('Chocolate sauce', 20)]),
    ]),
  ],
  products: [
    SampleProduct('Cones', 'Vanilla cone', groups: ['Toppings'], quick: true, photo: 'vanilla-cone', popular: 5, [
      SampleVariant('Single scoop', 1500, uses: [('Wafer cones', 1), ('Vanilla ice cream', 80)]),
      SampleVariant('Double scoop', 2200, uses: [('Wafer cones', 1), ('Vanilla ice cream', 160)]),
    ]),
    SampleProduct('Cones', 'Chocolate cone', groups: ['Toppings'], quick: true, photo: 'chocolate-cone', popular: 4, [
      SampleVariant('Single scoop', 1500, uses: [('Wafer cones', 1), ('Chocolate ice cream', 80)]),
      SampleVariant('Double scoop', 2200, uses: [('Wafer cones', 1), ('Chocolate ice cream', 160)]),
    ]),
    SampleProduct('Cups', 'Ice cream cup', groups: ['Toppings'], quick: true, photo: 'chocolate-cup', popular: 4, [
      SampleVariant('Small', 2000, uses: [('Cups, small', 1), ('Vanilla ice cream', 120)]),
      SampleVariant('Medium', 2500, uses: [('Cups, medium', 1), ('Vanilla ice cream', 180)]),
      SampleVariant('Large', 3200, uses: [('Cups, large', 1), ('Vanilla ice cream', 250)]),
    ]),
    SampleProduct('Cups', 'Strawberry cup', groups: ['Toppings'], popular: 2, [
      SampleVariant('Small', 2000, uses: [('Cups, small', 1), ('Strawberry ice cream', 120)]),
      SampleVariant('Large', 3200, uses: [('Cups, large', 1), ('Strawberry ice cream', 250)]),
    ]),
    SampleProduct('Tubs', 'Ice cream tub', detail: '500 ml', photo: 'strawberry-tub', [
      SampleVariant(null, 6000, uses: [('Ice cream tubs, 500 ml', 1)]),
    ]),
    SampleProduct('Drinks', 'Milkshake', detail: '350 ml', quick: true, photo: 'milkshake', popular: 3, [
      SampleVariant(null, 2000, uses: [('Milk', 200), ('Vanilla ice cream', 100)]),
    ]),
    SampleProduct('Snacks', 'Waffle', groups: ['Toppings'], photo: 'waffle', popular: 2, [
      SampleVariant(null, 1200, uses: [('Waffle batter', 120)]),
    ]),
  ],
  deals: [
    SampleDeal('Cone Friday: buy 3, get 1 free', 'Vanilla cone', quantity: 3),
    SampleDeal('Milkshakes: 4 for GH₵ 18 each', 'Milkshake', quantity: 4, price: 1800),
  ],
);

const _chopBar = SampleShop(
  branch: 'Station road canteen',
  spendThreshold: 15000,
  categories: [
    ('Food', CategoryTone.coral),
    ('Soups', CategoryTone.lime),
    ('Drinks', CategoryTone.blue),
    ('Extras', CategoryTone.midnight),
  ],
  suppliers: [
    SampleSupplier('Aboabo Grains and Oil', phone: '0244300311', address: 'Aboabo market, Tamale', termsDays: 14),
    SampleSupplier('Central Market Fresh Foods', phone: '0244300312', address: 'Central market, Tamale'),
    SampleSupplier('Savanna Drinks Distributors', phone: '0244300313', address: 'Bolgatanga road, Tamale', termsDays: 7),
  ],
  stock: [
    SampleStock('Rice', StockUnit.g, cost: 1200, per: 1000, opening: 60000, supplier: 0),
    SampleStock('Cooking oil', StockUnit.ml, cost: 3000, per: 1000, opening: 20000, supplier: 0),
    SampleStock('Fufu flour', StockUnit.g, cost: 1000, per: 1000, opening: 25000, supplier: 0),
    SampleStock('Tomatoes', StockUnit.g, cost: 1500, per: 1000, opening: 20000, supplier: 1, expiry: true),
    SampleStock('Chicken pieces', StockUnit.piece, cost: 1500, opening: 120, supplier: 1, expiry: true),
    SampleStock('Tilapia', StockUnit.piece, cost: 2500, opening: 60, supplier: 1, expiry: true),
    SampleStock('Eggs', StockUnit.piece, cost: 150, opening: 180, supplier: 1, expiry: true),
    SampleStock('Hibiscus leaves', StockUnit.g, cost: 2000, per: 1000, opening: 3000, supplier: 1),
    SampleStock('Ginger', StockUnit.g, cost: 1500, per: 1000, opening: 2000, supplier: 1),
    SampleStock('Empty bottles', StockUnit.piece, cost: 50, opening: 200, supplier: 2),
    SampleStock('Sobolo, bottled', StockUnit.piece, cost: 0, opening: 0, supplier: 2),
    SampleStock('Malt drink', StockUnit.piece, cost: 600, opening: 72, supplier: 2),
    SampleStock('Bottled water', StockUnit.piece, cost: 150, opening: 96, supplier: 2),
    SampleStock('Takeaway packs', StockUnit.piece, cost: 50, opening: 400, supplier: 1),
  ],
  made: SampleMade('Sobolo, bottled', makes: 20, uses: [('Hibiscus leaves', 500), ('Ginger', 200), ('Empty bottles', 20)]),
  groups: [
    SampleGroup('Protein', min: 1, max: 1, [
      SampleOption('Chicken', uses: [('Chicken pieces', 1)], isDefault: true),
      SampleOption('Fish', price: 500, uses: [('Tilapia', 1)]),
      SampleOption('Boiled eggs', uses: [('Eggs', 2)]),
    ]),
    SampleGroup('Extras', max: 3, [
      SampleOption('Extra shito', price: 200),
      SampleOption('Extra gravy', price: 300, uses: [('Cooking oil', 20), ('Tomatoes', 50)]),
      SampleOption('Pepper'),
    ]),
  ],
  products: [
    SampleProduct('Food', 'Jollof rice', groups: ['Protein', 'Extras'], quick: true, popular: 5, [
      SampleVariant('Small', 3000, uses: [('Rice', 250), ('Cooking oil', 30), ('Tomatoes', 80), ('Takeaway packs', 1)]),
      SampleVariant('Large', 4500, uses: [('Rice', 400), ('Cooking oil', 45), ('Tomatoes', 120), ('Takeaway packs', 1)]),
    ]),
    SampleProduct('Food', 'Fried rice', groups: ['Protein', 'Extras'], quick: true, popular: 4, [
      SampleVariant('Small', 3000, uses: [('Rice', 250), ('Cooking oil', 40), ('Takeaway packs', 1)]),
      SampleVariant('Large', 4500, uses: [('Rice', 400), ('Cooking oil', 60), ('Takeaway packs', 1)]),
    ]),
    SampleProduct('Soups', 'Light soup and fufu', groups: ['Protein'], popular: 3, [
      SampleVariant(null, 4000, uses: [('Fufu flour', 300), ('Tomatoes', 100)]),
    ]),
    SampleProduct('Soups', 'Groundnut soup and rice balls', groups: ['Protein'], popular: 2, [
      SampleVariant(null, 4000, uses: [('Rice', 300)], cost: 600),
    ]),
    SampleProduct('Drinks', 'Sobolo', detail: '500 ml', quick: true, popular: 3, [
      SampleVariant(null, 800, uses: [('Sobolo, bottled', 1)]),
    ]),
    SampleProduct('Drinks', 'Malt drink', quick: true, popular: 2, [
      SampleVariant(null, 1000, uses: [('Malt drink', 1)]),
    ]),
    SampleProduct('Drinks', 'Bottled water', detail: '500 ml', popular: 3, [
      SampleVariant(null, 300, uses: [('Bottled water', 1)]),
    ]),
    SampleProduct('Extras', 'Fried egg', popular: 2, [
      SampleVariant(null, 500, uses: [('Eggs', 1), ('Cooking oil', 10)]),
    ]),
    SampleProduct('Extras', 'Kelewele', popular: 2, [
      SampleVariant(null, 1000, uses: [('Cooking oil', 30)], cost: 300),
    ]),
    SampleProduct('Extras', 'Extra meat', [
      SampleVariant(null, 1500, uses: [('Chicken pieces', 1)]),
    ]),
  ],
  deals: [
    SampleDeal('Water: 6 or more at GH₵ 2.50 each', 'Bottled water', quantity: 6, price: 250),
    SampleDeal('Sobolo: buy 4, get 1 free', 'Sobolo', quantity: 4),
  ],
);

const _provision = SampleShop(
  branch: 'Kalpohin shop',
  spendThreshold: 20000,
  categories: [
    ('Drinks', CategoryTone.blue),
    ('Provisions', CategoryTone.lime),
    ('Toiletries', CategoryTone.coral),
    ('Snacks', CategoryTone.midnight),
  ],
  suppliers: [
    SampleSupplier('Tamale Wholesale Depot', phone: '0244300321', address: 'Central market, Tamale', termsDays: 14),
    SampleSupplier('Kumasi Road Distributors', phone: '0244300322', address: 'Kumasi road, Tamale', termsDays: 30),
    SampleSupplier('Northern Rice Mills', phone: '0244300323', address: 'Nyankpala road'),
  ],
  stock: [
    SampleStock('Rice', StockUnit.g, cost: 1100, per: 1000, opening: 100000, supplier: 2),
    SampleStock('Sugar, 1 kg', StockUnit.piece, cost: 1300, opening: 48, supplier: 0),
    SampleStock('Cooking oil, 1 litre', StockUnit.piece, cost: 2700, opening: 36, supplier: 0),
    SampleStock('Spaghetti, 500 g', StockUnit.piece, cost: 950, opening: 60, supplier: 0),
    SampleStock('Tomato paste, sachet', StockUnit.piece, cost: 200, opening: 150, supplier: 0, expiry: true),
    SampleStock('Sardines, tin', StockUnit.piece, cost: 950, opening: 72, supplier: 1, expiry: true),
    SampleStock('Evaporated milk, tin', StockUnit.piece, cost: 550, opening: 96, supplier: 1, expiry: true),
    SampleStock('Chocolate drink powder, 400 g', StockUnit.piece, cost: 3800, opening: 24, supplier: 1, expiry: true),
    SampleStock('Bottled water, 500 ml', StockUnit.piece, cost: 120, opening: 240, supplier: 1),
    SampleStock('Soft drink, 500 ml', StockUnit.piece, cost: 650, opening: 96, supplier: 1, expiry: true),
    SampleStock('Bar soap', StockUnit.piece, cost: 450, opening: 80, supplier: 0),
    SampleStock('Toothpaste', StockUnit.piece, cost: 1150, opening: 40, supplier: 0),
    SampleStock('Toilet roll', StockUnit.piece, cost: 300, opening: 200, supplier: 0),
    SampleStock('Biscuits', StockUnit.piece, cost: 200, opening: 150, supplier: 1, expiry: true),
    SampleStock('Plantain chips', StockUnit.piece, cost: 300, opening: 80, supplier: 1, expiry: true),
  ],
  products: [
    SampleProduct('Provisions', 'Rice', sellBy: SellBy.kg, detail: 'Per kg', popular: 4, [
      SampleVariant(null, 1400, uses: [('Rice', 1000)]),
    ]),
    SampleProduct('Provisions', 'Sugar', detail: '1 kg', popular: 3, [SampleVariant(null, 1700, uses: [('Sugar, 1 kg', 1)])]),
    SampleProduct('Provisions', 'Cooking oil', detail: '1 litre', popular: 3, [SampleVariant(null, 3200, uses: [('Cooking oil, 1 litre', 1)])]),
    SampleProduct('Provisions', 'Spaghetti', detail: '500 g', popular: 3, [SampleVariant(null, 1200, uses: [('Spaghetti, 500 g', 1)])]),
    SampleProduct('Provisions', 'Tomato paste', quick: true, popular: 4, [
      SampleVariant('Sachet', 300, uses: [('Tomato paste, sachet', 1)]),
      SampleVariant('Strip of 10', 2800, uses: [('Tomato paste, sachet', 10)]),
    ]),
    SampleProduct('Provisions', 'Sardines', detail: 'Tin', popular: 2, [SampleVariant(null, 1200, uses: [('Sardines, tin', 1)])]),
    SampleProduct('Provisions', 'Evaporated milk', detail: 'Tin', quick: true, popular: 4, [
      SampleVariant(null, 700, uses: [('Evaporated milk, tin', 1)]),
    ]),
    SampleProduct('Drinks', 'Chocolate drink powder', detail: '400 g', popular: 2, [
      SampleVariant(null, 4500, uses: [('Chocolate drink powder, 400 g', 1)]),
    ]),
    SampleProduct('Drinks', 'Bottled water', detail: '500 ml', quick: true, popular: 5, [
      SampleVariant('Single', 200, uses: [('Bottled water, 500 ml', 1)]),
      SampleVariant('Pack of 12', 2000, uses: [('Bottled water, 500 ml', 12)]),
    ]),
    SampleProduct('Drinks', 'Soft drink', detail: '500 ml', quick: true, popular: 4, [
      SampleVariant(null, 900, uses: [('Soft drink, 500 ml', 1)]),
    ]),
    SampleProduct('Toiletries', 'Bar soap', popular: 3, [SampleVariant(null, 600, uses: [('Bar soap', 1)])]),
    SampleProduct('Toiletries', 'Toothpaste', popular: 2, [SampleVariant(null, 1500, uses: [('Toothpaste', 1)])]),
    SampleProduct('Toiletries', 'Toilet roll', popular: 3, [
      SampleVariant('Single', 400, uses: [('Toilet roll', 1)]),
      SampleVariant('Pack of 10', 3500, uses: [('Toilet roll', 10)]),
    ]),
    SampleProduct('Snacks', 'Biscuits', popular: 3, [SampleVariant(null, 300, uses: [('Biscuits', 1)])]),
    SampleProduct('Snacks', 'Plantain chips', popular: 2, [SampleVariant(null, 500, uses: [('Plantain chips', 1)])]),
  ],
  deals: [
    SampleDeal('Soft drinks: 6 or more at GH₵ 8 each', 'Soft drink', quantity: 6, price: 800),
    SampleDeal('Biscuits: buy 5, get 1 free', 'Biscuits', quantity: 5),
  ],
);

const _pharmacy = SampleShop(
  branch: 'Hospital road branch',
  spendThreshold: 15000,
  categories: [
    ('Medicines', CategoryTone.blue),
    ('Personal care', CategoryTone.lime),
    ('Baby', CategoryTone.coral),
    ('First aid', CategoryTone.midnight),
  ],
  suppliers: [
    SampleSupplier('Northern Pharma Distributors', phone: '0244300331', address: 'Hospital road, Tamale', termsDays: 30),
    SampleSupplier('Tamale Medical Supplies', phone: '0244300332', address: 'Jisonayili, Tamale', termsDays: 14),
    SampleSupplier('Savanna Health Products', phone: '0244300333', address: 'Kumasi road, Tamale'),
  ],
  stock: [
    SampleStock('Paracetamol 500 mg tablets', StockUnit.piece, cost: 25, opening: 3000, supplier: 0, expiry: true),
    SampleStock('Amoxicillin 500 mg capsules', StockUnit.piece, cost: 120, opening: 600, supplier: 0, expiry: true),
    SampleStock('Oral rehydration salts', StockUnit.piece, cost: 150, opening: 200, supplier: 0, expiry: true),
    SampleStock('Vitamin C tablets, bottle', StockUnit.piece, cost: 1200, opening: 30, supplier: 1, expiry: true),
    SampleStock('Cough syrup, 100 ml', StockUnit.piece, cost: 1300, opening: 40, supplier: 1, expiry: true),
    SampleStock('Malaria test kit', StockUnit.piece, cost: 600, opening: 50, supplier: 1, expiry: true),
    SampleStock('Hand sanitiser, 250 ml', StockUnit.piece, cost: 1100, opening: 36, supplier: 2),
    SampleStock('Body lotion', StockUnit.piece, cost: 1800, opening: 24, supplier: 2),
    SampleStock('Diapers, size 3', StockUnit.piece, cost: 7200, opening: 20, supplier: 2),
    SampleStock('Baby wipes', StockUnit.piece, cost: 1400, opening: 30, supplier: 2),
    SampleStock('Plasters, 20 pack', StockUnit.piece, cost: 550, opening: 60, supplier: 1),
    SampleStock('Bandage roll', StockUnit.piece, cost: 700, opening: 50, supplier: 1),
    SampleStock('Digital thermometer', StockUnit.piece, cost: 2500, opening: 12, supplier: 1),
  ],
  products: [
    SampleProduct('Medicines', 'Paracetamol 500 mg', quick: true, popular: 5, [
      SampleVariant('Strip of 10', 500, uses: [('Paracetamol 500 mg tablets', 10)]),
      SampleVariant('Box of 100', 4500, uses: [('Paracetamol 500 mg tablets', 100)]),
    ]),
    SampleProduct('Medicines', 'Amoxicillin 500 mg', popular: 3, [
      SampleVariant('Strip of 10', 2000, uses: [('Amoxicillin 500 mg capsules', 10)]),
      SampleVariant('Course of 21', 4000, uses: [('Amoxicillin 500 mg capsules', 21)]),
    ]),
    SampleProduct('Medicines', 'Oral rehydration salts', detail: 'Sachet', popular: 3, [
      SampleVariant(null, 300, uses: [('Oral rehydration salts', 1)]),
    ]),
    SampleProduct('Medicines', 'Vitamin C', detail: '100 tablets', popular: 2, [
      SampleVariant(null, 1800, uses: [('Vitamin C tablets, bottle', 1)]),
    ]),
    SampleProduct('Medicines', 'Cough syrup', detail: '100 ml', quick: true, popular: 3, [
      SampleVariant(null, 1800, uses: [('Cough syrup, 100 ml', 1)]),
    ]),
    SampleProduct('Medicines', 'Malaria test', popular: 2, [
      SampleVariant(null, 1500, uses: [('Malaria test kit', 1)]),
    ]),
    SampleProduct('Medicines', 'Dispensing fee', openPrice: true, minPrice: 200, maxPrice: 2000, [
      SampleVariant(null, 500, cost: 0),
    ]),
    SampleProduct('Personal care', 'Hand sanitiser', detail: '250 ml', popular: 2, [
      SampleVariant(null, 1800, uses: [('Hand sanitiser, 250 ml', 1)]),
    ]),
    SampleProduct('Personal care', 'Body lotion', popular: 2, [SampleVariant(null, 2500, uses: [('Body lotion', 1)])]),
    SampleProduct('Baby', 'Diapers', detail: 'Size 3', popular: 2, [SampleVariant(null, 9500, uses: [('Diapers, size 3', 1)])]),
    SampleProduct('Baby', 'Baby wipes', popular: 2, [SampleVariant(null, 2000, uses: [('Baby wipes', 1)])]),
    SampleProduct('First aid', 'Plasters', detail: '20 pack', quick: true, popular: 3, [
      SampleVariant(null, 1000, uses: [('Plasters, 20 pack', 1)]),
    ]),
    SampleProduct('First aid', 'Bandage', popular: 2, [SampleVariant(null, 1200, uses: [('Bandage roll', 1)])]),
    SampleProduct('First aid', 'Digital thermometer', [SampleVariant(null, 4000, uses: [('Digital thermometer', 1)])]),
  ],
  deals: [
    SampleDeal('ORS: 5 or more at GH₵ 2.50 each', 'Oral rehydration salts', quantity: 5, price: 250),
    SampleDeal('Plasters: buy 2, get 1 free', 'Plasters', quantity: 2),
  ],
);

const _salon = SampleShop(
  branch: 'Vittin studio',
  spendThreshold: 30000,
  categories: [('Services', CategoryTone.coral), ('Products', CategoryTone.blue)],
  suppliers: [
    SampleSupplier('Beauty World Wholesale', phone: '0244300341', address: 'Central market, Tamale', termsDays: 14),
    SampleSupplier('Tamale Hair Market', phone: '0244300342', address: 'Aboabo market, Tamale'),
  ],
  stock: [
    SampleStock('Braiding hair', StockUnit.piece, cost: 1500, opening: 80, supplier: 1),
    SampleStock('Hair cream', StockUnit.piece, cost: 2800, opening: 24, supplier: 0),
    SampleStock('Shampoo', StockUnit.ml, cost: 4000, per: 1000, opening: 6000, supplier: 0),
    SampleStock('Relaxer kit', StockUnit.piece, cost: 3500, opening: 15, supplier: 0, expiry: true),
    SampleStock('Hair net', StockUnit.piece, cost: 300, opening: 60, supplier: 1),
    SampleStock('Nail polish', StockUnit.piece, cost: 900, opening: 30, supplier: 0),
  ],
  groups: [
    SampleGroup('Add-ons', max: 3, [
      SampleOption('Wash first', price: 2000, uses: [('Shampoo', 30)]),
      SampleOption('Beads', price: 1500),
      SampleOption('Deep treatment', price: 3000, uses: [('Hair cream', 1)]),
    ]),
  ],
  products: [
    SampleProduct('Services', 'Hair wash', quick: true, popular: 4, [SampleVariant(null, 3000, uses: [('Shampoo', 30)])]),
    SampleProduct('Services', 'Braids', groups: ['Add-ons'], quick: true, popular: 4, [
      SampleVariant('Medium', 25000, uses: [('Braiding hair', 3)]),
      SampleVariant('Long', 35000, uses: [('Braiding hair', 5)]),
    ]),
    SampleProduct('Services', 'Cornrows', groups: ['Add-ons'], popular: 3, [SampleVariant(null, 8000, cost: 0)]),
    SampleProduct('Services', 'Relaxer treatment', groups: ['Add-ons'], popular: 2, [
      SampleVariant(null, 12000, uses: [('Relaxer kit', 1)]),
    ]),
    SampleProduct('Services', 'Manicure', quick: true, popular: 3, [SampleVariant(null, 5000, uses: [('Nail polish', 1)])]),
    SampleProduct('Products', 'Hair cream', popular: 2, [SampleVariant(null, 4500, uses: [('Hair cream', 1)])]),
    SampleProduct('Products', 'Hair net', popular: 2, [SampleVariant(null, 1000, uses: [('Hair net', 1)])]),
    SampleProduct('Products', 'Braiding hair', detail: 'Per pack', popular: 2, [
      SampleVariant(null, 2500, uses: [('Braiding hair', 1)]),
    ]),
  ],
  deals: [
    SampleDeal('Braiding hair: 4 or more at GH₵ 22 each', 'Braiding hair', quantity: 4, price: 2200),
    SampleDeal('Hair nets: buy 2, get 1 free', 'Hair net', quantity: 2),
  ],
);

const _phones = SampleShop(
  branch: 'Market square stand',
  spendThreshold: 50000,
  categories: [
    ('Phones', CategoryTone.midnight),
    ('Accessories', CategoryTone.blue),
    ('Repairs', CategoryTone.coral),
    ('Airtime and data', CategoryTone.lime),
  ],
  suppliers: [
    SampleSupplier('Accra Mobile Distributors', phone: '0244300351', address: 'Circle, Accra', termsDays: 30),
    SampleSupplier('Kumasi Accessories Hub', phone: '0244300352', address: 'Adum, Kumasi', termsDays: 14),
    SampleSupplier('Tamale Phone Parts', phone: '0244300353', address: 'Central market, Tamale'),
  ],
  stock: [
    SampleStock('Nova A15, 64 GB', StockUnit.piece, cost: 125000, opening: 8, supplier: 0),
    SampleStock('Nova A15, 128 GB', StockUnit.piece, cost: 150000, opening: 6, supplier: 0),
    SampleStock('Basic phone', StockUnit.piece, cost: 18000, opening: 15, supplier: 0),
    SampleStock('Phone charger', StockUnit.piece, cost: 3500, opening: 40, supplier: 1),
    SampleStock('USB cable', StockUnit.piece, cost: 1200, opening: 60, supplier: 1),
    SampleStock('Earphones', StockUnit.piece, cost: 2000, opening: 30, supplier: 1),
    SampleStock('Screen protector', StockUnit.piece, cost: 500, opening: 100, supplier: 1),
    SampleStock('Phone case', StockUnit.piece, cost: 1500, opening: 50, supplier: 1),
    SampleStock('Replacement screen', StockUnit.piece, cost: 15000, opening: 10, supplier: 2),
    SampleStock('Replacement battery', StockUnit.piece, cost: 6000, opening: 12, supplier: 2),
  ],
  groups: [
    SampleGroup('Fitting', max: 1, [SampleOption('Fit it for them', price: 500)]),
  ],
  products: [
    SampleProduct('Phones', 'Nova A15', popular: 2, [
      SampleVariant('64 GB', 150000, uses: [('Nova A15, 64 GB', 1)]),
      SampleVariant('128 GB', 180000, uses: [('Nova A15, 128 GB', 1)]),
    ]),
    SampleProduct('Phones', 'Basic phone', popular: 2, [SampleVariant(null, 25000, uses: [('Basic phone', 1)])]),
    SampleProduct('Accessories', 'Phone charger', quick: true, popular: 4, [SampleVariant(null, 6000, uses: [('Phone charger', 1)])]),
    SampleProduct('Accessories', 'USB cable', quick: true, popular: 4, [SampleVariant(null, 2500, uses: [('USB cable', 1)])]),
    SampleProduct('Accessories', 'Earphones', popular: 3, [SampleVariant(null, 4000, uses: [('Earphones', 1)])]),
    SampleProduct('Accessories', 'Screen protector', groups: ['Fitting'], quick: true, popular: 4, [
      SampleVariant(null, 2000, uses: [('Screen protector', 1)]),
    ]),
    SampleProduct('Accessories', 'Phone case', groups: ['Fitting'], popular: 3, [SampleVariant(null, 3500, uses: [('Phone case', 1)])]),
    SampleProduct('Repairs', 'Screen repair', popular: 2, [SampleVariant(null, 25000, uses: [('Replacement screen', 1)])]),
    SampleProduct('Repairs', 'Battery replacement', popular: 2, [SampleVariant(null, 12000, uses: [('Replacement battery', 1)])]),
    SampleProduct('Repairs', 'Software fix', popular: 2, [SampleVariant(null, 5000, cost: 0)]),
    SampleProduct('Airtime and data', 'Airtime', openPrice: true, minPrice: 100, maxPrice: 50000, quick: true, popular: 5, [
      SampleVariant(null, 1000, cost: 970),
    ]),
    SampleProduct('Airtime and data', 'Data bundle', popular: 3, [
      SampleVariant('1 GB', 1000, cost: 950),
      SampleVariant('5 GB', 4500, cost: 4300),
    ]),
  ],
  deals: [
    SampleDeal('Screen protectors: 3 or more at GH₵ 15 each', 'Screen protector', quantity: 3, price: 1500),
    SampleDeal('USB cables: buy 2, get 1 free', 'USB cable', quantity: 2),
  ],
);

const _boutique = SampleShop(
  branch: 'Melcom road shop',
  spendThreshold: 40000,
  categories: [
    ('Women', CategoryTone.coral),
    ('Men', CategoryTone.blue),
    ('Children', CategoryTone.lime),
    ('Shoes and bags', CategoryTone.midnight),
  ],
  suppliers: [
    SampleSupplier('Kantamanto Wholesale', phone: '0244300361', address: 'Kantamanto, Accra', termsDays: 30),
    SampleSupplier('Tamale Fabrics and Tailoring', phone: '0244300362', address: 'Central market, Tamale', termsDays: 14),
    SampleSupplier('Accra Shoe Importers', phone: '0244300363', address: 'Makola, Accra'),
  ],
  stock: [
    SampleStock('Kaba and slit', StockUnit.piece, cost: 16000, opening: 12, supplier: 1),
    SampleStock('Ladies dress, S', StockUnit.piece, cost: 11000, opening: 8, supplier: 0),
    SampleStock('Ladies dress, M', StockUnit.piece, cost: 11000, opening: 10, supplier: 0),
    SampleStock('Ladies dress, L', StockUnit.piece, cost: 11000, opening: 8, supplier: 0),
    SampleStock('Men\'s shirt, M', StockUnit.piece, cost: 7000, opening: 12, supplier: 0),
    SampleStock('Men\'s shirt, L', StockUnit.piece, cost: 7000, opening: 12, supplier: 0),
    SampleStock('Men\'s shirt, XL', StockUnit.piece, cost: 7000, opening: 8, supplier: 0),
    SampleStock('Smock', StockUnit.piece, cost: 24000, opening: 6, supplier: 1),
    SampleStock('Children\'s T-shirt', StockUnit.piece, cost: 2500, opening: 30, supplier: 0),
    SampleStock('School uniform', StockUnit.piece, cost: 5000, opening: 20, supplier: 1),
    SampleStock('Sandals, 40', StockUnit.piece, cost: 5500, opening: 6, supplier: 2),
    SampleStock('Sandals, 42', StockUnit.piece, cost: 5500, opening: 8, supplier: 2),
    SampleStock('Sandals, 44', StockUnit.piece, cost: 5500, opening: 6, supplier: 2),
    SampleStock('Ladies handbag', StockUnit.piece, cost: 9000, opening: 10, supplier: 2),
  ],
  groups: [
    SampleGroup('Alterations', max: 2, [
      SampleOption('Hemming', price: 1000),
      SampleOption('Taking in', price: 1500),
    ]),
  ],
  products: [
    SampleProduct('Women', 'Kaba and slit', groups: ['Alterations'], popular: 2, [
      SampleVariant(null, 25000, uses: [('Kaba and slit', 1)]),
    ]),
    SampleProduct('Women', 'Ladies dress', groups: ['Alterations'], quick: true, popular: 3, [
      SampleVariant('S', 18000, uses: [('Ladies dress, S', 1)]),
      SampleVariant('M', 18000, uses: [('Ladies dress, M', 1)]),
      SampleVariant('L', 18000, uses: [('Ladies dress, L', 1)]),
    ]),
    SampleProduct('Men', 'Men\'s shirt', groups: ['Alterations'], quick: true, popular: 3, [
      SampleVariant('M', 12000, uses: [('Men\'s shirt, M', 1)]),
      SampleVariant('L', 12000, uses: [('Men\'s shirt, L', 1)]),
      SampleVariant('XL', 12000, uses: [('Men\'s shirt, XL', 1)]),
    ]),
    SampleProduct('Men', 'Smock', popular: 1, [SampleVariant(null, 35000, uses: [('Smock', 1)])]),
    SampleProduct('Children', 'Children\'s T-shirt', quick: true, popular: 3, [
      SampleVariant(null, 5000, uses: [('Children\'s T-shirt', 1)]),
    ]),
    SampleProduct('Children', 'School uniform', popular: 2, [SampleVariant(null, 8000, uses: [('School uniform', 1)])]),
    SampleProduct('Shoes and bags', 'Sandals', popular: 2, [
      SampleVariant('40', 9000, uses: [('Sandals, 40', 1)]),
      SampleVariant('42', 9000, uses: [('Sandals, 42', 1)]),
      SampleVariant('44', 9000, uses: [('Sandals, 44', 1)]),
    ]),
    SampleProduct('Shoes and bags', 'Ladies handbag', popular: 2, [SampleVariant(null, 15000, uses: [('Ladies handbag', 1)])]),
  ],
  deals: [
    SampleDeal('T-shirts: 3 or more at GH₵ 40 each', 'Children\'s T-shirt', quantity: 3, price: 4000),
    SampleDeal('Shirts: buy 2, get 1 free', 'Men\'s shirt', quantity: 2),
  ],
);

const _building = SampleShop(
  branch: 'Yendi road yard',
  spendThreshold: 100000,
  categories: [
    ('Cement and blocks', CategoryTone.midnight),
    ('Roofing', CategoryTone.coral),
    ('Plumbing', CategoryTone.blue),
    ('Electrical', CategoryTone.lime),
    ('Paint and tools', CategoryTone.amber),
  ],
  suppliers: [
    SampleSupplier('Northern Cement Depot', phone: '0244300371', address: 'Industrial area, Tamale', termsDays: 30),
    SampleSupplier('Tamale Roofing Sheets', phone: '0244300372', address: 'Bolgatanga road, Tamale', termsDays: 14),
    SampleSupplier('Savanna Hardware Importers', phone: '0244300373', address: 'Kumasi road, Tamale'),
  ],
  stock: [
    SampleStock('Cement, 50 kg bag', StockUnit.piece, cost: 7500, opening: 150, supplier: 0),
    SampleStock('Sandcrete block, 6 inch', StockUnit.piece, cost: 550, opening: 800, supplier: 0),
    SampleStock('Iron rod, 12 mm', StockUnit.piece, cost: 9500, opening: 100, supplier: 0),
    SampleStock('Roofing sheet', StockUnit.piece, cost: 6500, opening: 120, supplier: 1),
    SampleStock('Roofing nails', StockUnit.g, cost: 2500, per: 1000, opening: 30000, supplier: 1),
    SampleStock('PVC pipe, ½ inch', StockUnit.piece, cost: 2500, opening: 80, supplier: 2),
    SampleStock('Elbow, ½ inch', StockUnit.piece, cost: 300, opening: 200, supplier: 2),
    SampleStock('Electrical cable, 2.5 mm (metre)', StockUnit.piece, cost: 600, opening: 500, supplier: 2),
    SampleStock('Wall socket', StockUnit.piece, cost: 1500, opening: 60, supplier: 2),
    SampleStock('LED bulb', StockUnit.piece, cost: 1000, opening: 100, supplier: 2),
    SampleStock('Emulsion paint, 4 litres', StockUnit.piece, cost: 18000, opening: 24, supplier: 2, expiry: true),
    SampleStock('Paint brush', StockUnit.piece, cost: 1200, opening: 40, supplier: 2),
    SampleStock('Wheelbarrow', StockUnit.piece, cost: 45000, opening: 5, supplier: 2),
  ],
  products: [
    SampleProduct('Cement and blocks', 'Cement', detail: '50 kg bag', quick: true, popular: 5, [
      SampleVariant(null, 9000, uses: [('Cement, 50 kg bag', 1)]),
    ]),
    SampleProduct('Cement and blocks', 'Sandcrete block', detail: '6 inch', quick: true, popular: 4, [
      SampleVariant(null, 700, uses: [('Sandcrete block, 6 inch', 1)]),
    ]),
    SampleProduct('Cement and blocks', 'Iron rod', detail: '12 mm', popular: 3, [
      SampleVariant(null, 12000, uses: [('Iron rod, 12 mm', 1)]),
    ]),
    SampleProduct('Roofing', 'Roofing sheet', popular: 3, [SampleVariant(null, 8000, uses: [('Roofing sheet', 1)])]),
    SampleProduct('Roofing', 'Roofing nails', sellBy: SellBy.kg, detail: 'Per kg', popular: 2, [
      SampleVariant(null, 3500, uses: [('Roofing nails', 1000)]),
    ]),
    SampleProduct('Plumbing', 'PVC pipe', detail: '½ inch', popular: 2, [SampleVariant(null, 3200, uses: [('PVC pipe, ½ inch', 1)])]),
    SampleProduct('Plumbing', 'Elbow', detail: '½ inch', popular: 2, [SampleVariant(null, 500, uses: [('Elbow, ½ inch', 1)])]),
    SampleProduct('Electrical', 'Electrical cable', detail: '2.5 mm, per metre', popular: 3, [
      SampleVariant(null, 900, uses: [('Electrical cable, 2.5 mm (metre)', 1)]),
    ]),
    SampleProduct('Electrical', 'Wall socket', popular: 2, [SampleVariant(null, 2200, uses: [('Wall socket', 1)])]),
    SampleProduct('Electrical', 'LED bulb', quick: true, popular: 3, [SampleVariant(null, 1500, uses: [('LED bulb', 1)])]),
    SampleProduct('Paint and tools', 'Emulsion paint', detail: '4 litres', popular: 2, [
      SampleVariant(null, 24000, uses: [('Emulsion paint, 4 litres', 1)]),
    ]),
    SampleProduct('Paint and tools', 'Paint brush', popular: 2, [SampleVariant(null, 2000, uses: [('Paint brush', 1)])]),
    SampleProduct('Paint and tools', 'Wheelbarrow', [SampleVariant(null, 60000, uses: [('Wheelbarrow', 1)])]),
    SampleProduct('Paint and tools', 'Delivery', openPrice: true, minPrice: 2000, maxPrice: 20000, [
      SampleVariant(null, 5000, cost: 2000),
    ]),
  ],
  deals: [
    SampleDeal('Cement: 10 bags or more at GH₵ 87 each', 'Cement', quantity: 10, price: 8700),
    SampleDeal('Bulbs: buy 4, get 1 free', 'LED bulb', quantity: 4),
  ],
);

const _other = SampleShop(
  branch: 'Second shop',
  spendThreshold: 10000,
  categories: [('General', CategoryTone.blue), ('Services', CategoryTone.coral)],
  suppliers: [
    SampleSupplier('Tamale General Wholesale', phone: '0244300381', address: 'Central market, Tamale', termsDays: 14),
    SampleSupplier('Accra Stationery Supplies', phone: '0244300382', address: 'Kokomlemle, Accra'),
  ],
  stock: [
    SampleStock('Exercise book', StockUnit.piece, cost: 200, opening: 200, supplier: 1),
    SampleStock('Ballpoint pen', StockUnit.piece, cost: 120, opening: 300, supplier: 1),
    SampleStock('A4 paper', StockUnit.piece, cost: 10, opening: 2500, supplier: 1),
    SampleStock('Bottled water', StockUnit.piece, cost: 150, opening: 120, supplier: 0),
    SampleStock('AA batteries, pair', StockUnit.piece, cost: 500, opening: 60, supplier: 0),
    SampleStock('Torch', StockUnit.piece, cost: 2200, opening: 20, supplier: 0),
    SampleStock('Umbrella', StockUnit.piece, cost: 3000, opening: 15, supplier: 0),
  ],
  products: [
    SampleProduct('General', 'Exercise book', quick: true, popular: 4, [SampleVariant(null, 300, uses: [('Exercise book', 1)])]),
    SampleProduct('General', 'Ballpoint pen', quick: true, popular: 4, [
      SampleVariant('Single', 200, uses: [('Ballpoint pen', 1)]),
      SampleVariant('Box of 50', 8000, uses: [('Ballpoint pen', 50)]),
    ]),
    SampleProduct('General', 'Bottled water', detail: '500 ml', popular: 3, [SampleVariant(null, 300, uses: [('Bottled water', 1)])]),
    SampleProduct('General', 'AA batteries', detail: 'Pair', popular: 2, [SampleVariant(null, 800, uses: [('AA batteries, pair', 1)])]),
    SampleProduct('General', 'Torch', popular: 1, [SampleVariant(null, 3500, uses: [('Torch', 1)])]),
    SampleProduct('General', 'Umbrella', popular: 1, [SampleVariant(null, 4500, uses: [('Umbrella', 1)])]),
    SampleProduct('Services', 'Photocopy', detail: 'Per page', quick: true, popular: 5, [SampleVariant(null, 50, uses: [('A4 paper', 1)])]),
    SampleProduct('Services', 'Printing', detail: 'Per page', popular: 3, [SampleVariant(null, 100, uses: [('A4 paper', 1)], cost: 20)]),
  ],
  deals: [
    SampleDeal('Exercise books: 10 or more at GH₵ 2.50 each', 'Exercise book', quantity: 10, price: 250),
    SampleDeal('Pens: buy 4, get 1 free', 'Ballpoint pen', quantity: 4),
  ],
);
