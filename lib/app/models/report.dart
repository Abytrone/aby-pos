/// Sales totals for a period. Pesewas.
class SalesSummary {
  const SalesSummary({
    this.gross = 0,
    this.discounts = 0,
    this.refunds = 0,
    this.tax = 0,
    this.count = 0,
    this.items = 0,
    this.voided = 0,
    this.series = const [],
  });

  /// At menu prices, before discounts.
  final int gross;
  final int discounts;
  final int refunds;
  final int tax;
  final int count;

  /// Pieces sold (a weighed line is one).
  final int items;
  final int voided;

  /// Net sales per day (or week / month for long periods), oldest first.
  final List<(DateTime, int)> series;

  int get net => gross - discounts - refunds;
  int get averageSale => count == 0 ? 0 : (gross - discounts) ~/ count;
  double get itemsPerSale => count == 0 ? 0 : items / count;
}

/// One product's figures for a period. Pesewas.
class ProductFigures {
  const ProductFigures({
    required this.productId,
    required this.name,
    required this.category,
    this.quantity = 0,
    this.revenue = 0,
    this.cost = 0,
    this.grade = 'C',
  });

  final String productId;
  final String name;
  final String category;
  final int quantity;
  final int revenue;
  final int cost;

  /// A: the products bringing the first 80% of revenue; B: the next 15%; C: the rest.
  final String grade;

  int get profit => revenue - cost;
  int? get marginPercent => revenue <= 0 ? null : (profit * 100 / revenue).round();

  ProductFigures withGrade(String g) =>
      ProductFigures(productId: productId, name: name, category: category, quantity: quantity, revenue: revenue, cost: cost, grade: g);
}

/// One person's figures for a period.
class StaffFigures {
  const StaffFigures({
    required this.name,
    this.sales = 0,
    this.total = 0,
    this.voids = 0,
    this.refunds = 0,
    this.discounts = 0,
    this.noSales = 0,
    this.shorts = 0,
    this.shortTotal = 0,
  });

  final String name;
  final int sales;
  final int total;
  final int voids;
  final int refunds;
  final int discounts;
  final int noSales;
  final int shorts;
  final int shortTotal;

  int get average => sales == 0 ? 0 : total ~/ sales;
}

/// Customers over a period, and the credit book now.
class CustomerFigures {
  const CustomerFigures({
    this.top = const [],
    this.newCustomers = 0,
    this.returning = 0,
    this.owed = 0,
    this.overdue = 0,
    this.wallets = 0,
  });

  /// (name, spend), biggest first.
  final List<(String, int)> top;
  final int newCustomers;
  final int returning;

  /// Pesewas owed by all customers now, and how much of it is late.
  final int owed;
  final int overdue;

  /// Pesewas held in wallets now.
  final int wallets;
}

/// Stock and tax for a period.
class StockTaxFigures {
  const StockTaxFigures({
    this.stockValue = 0,
    this.movements = const {},
    this.waste = const [],
    this.countDifferences = const [],
    this.taxes = const [],
  });

  /// Pesewas, at cost, now.
  final int stockValue;

  /// Movement reason name → value at cost (pesewas, signed).
  final Map<String, int> movements;

  /// (item, value lost).
  final List<(String, int)> waste;

  /// (item, value: + found, − missing).
  final List<(String, int)> countDifferences;

  /// (tax name, rate in basis points, amount).
  final List<(String, int, int)> taxes;
}
