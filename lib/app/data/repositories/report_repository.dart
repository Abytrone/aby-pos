import 'package:drift/drift.dart';

import '../../core/period.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/report.dart';
import '../database/app_database.dart';
import 'customer_repository.dart';
import 'stock_repository.dart';

/// The reports, worked out offline from this device's database.
class ReportRepository {
  ReportRepository(this._db, this._stock, this._customers);

  final AppDatabase _db;
  final StockRepository _stock;
  final CustomerRepository _customers;

  List<Variable<Object>> _range(DateRange r) => [Variable.withDateTime(r.from), Variable.withDateTime(r.to)];

  static const _completed = "s.status = 'completed' AND s.deleted_at IS NULL AND s.created_at >= ? AND s.created_at < ?";

  Future<SalesSummary> sales(DateRange r) async {
    final totals = await _db.customSelect(
      'SELECT COALESCE(SUM(s.total + s.discount_total), 0) AS gross, COALESCE(SUM(s.discount_total), 0) AS discounts, '
      'COALESCE(SUM(s.tax_total), 0) AS tax, COUNT(*) AS n FROM sales s WHERE $_completed',
      variables: _range(r),
      readsFrom: {_db.sales},
    ).getSingle();
    final items = await _db.customSelect(
      "SELECT COALESCE(SUM(CASE WHEN l.sell_by = 'each' THEN l.quantity ELSE 1 END), 0) AS n, "
      'COALESCE(SUM(l.promotion), 0) AS promo '
      'FROM sale_lines l JOIN sales s ON s.id = l.sale_id WHERE l.deleted_at IS NULL AND $_completed',
      variables: _range(r),
      readsFrom: {_db.sales, _db.saleLines},
    ).getSingle();
    final voided = await _db.customSelect(
      "SELECT COUNT(*) AS n FROM sales WHERE status = 'voided' AND deleted_at IS NULL AND created_at >= ? AND created_at < ?",
      variables: _range(r),
      readsFrom: {_db.sales},
    ).getSingle();
    final refunds = await _db.customSelect(
      'SELECT COALESCE(SUM(total), 0) AS v FROM refunds WHERE deleted_at IS NULL AND created_at >= ? AND created_at < ?',
      variables: _range(r),
      readsFrom: {_db.refunds},
    ).getSingle();
    return SalesSummary(
      gross: totals.read<int>('gross'),
      discounts: totals.read<int>('discounts'),
      promotions: items.read<int>('promo'),
      tax: totals.read<int>('tax'),
      count: totals.read<int>('n'),
      items: items.read<int>('n'),
      voided: voided.read<int>('n'),
      refunds: refunds.read<int>('v'),
      series: await _series(r),
    );
  }

  /// Net sales per day, or per week (over 62 days) or month (over a year).
  Future<List<(DateTime, int)>> _series(DateRange r) async {
    final rows = await _db.customSelect(
      'SELECT s.created_at AS at, s.total AS total FROM sales s WHERE $_completed',
      variables: _range(r),
      readsFrom: {_db.sales},
    ).get();
    DateTime bucket(DateTime d) {
      if (r.days > 366) return DateTime(d.year, d.month);
      if (r.days > 62) {
        final day = DateTime(d.year, d.month, d.day);
        return day.subtract(Duration(days: day.weekday - 1));
      }
      return DateTime(d.year, d.month, d.day);
    }

    final out = <DateTime, int>{};
    for (var d = bucket(r.from); d.isBefore(r.to);) {
      out[d] = 0;
      d = r.days > 366
          ? DateTime(d.year, d.month + 1)
          : r.days > 62
              ? d.add(const Duration(days: 7))
              : DateTime(d.year, d.month, d.day + 1);
    }
    for (final row in rows) {
      final at = DateTime.fromMillisecondsSinceEpoch(row.read<int>('at') * 1000);
      final b = bucket(at);
      out[b] = (out[b] ?? 0) + row.read<int>('total');
    }
    return [for (final e in out.entries) (e.key, e.value)];
  }

  /// Net sales by day of week (1 = Monday) and hour: [weekday-1][hour].
  Future<List<List<int>>> byHour(DateRange r) async {
    final grid = List.generate(7, (_) => List.filled(24, 0));
    final rows = await _db.customSelect(
      'SELECT s.created_at AS at, s.total AS total FROM sales s WHERE $_completed',
      variables: _range(r),
      readsFrom: {_db.sales},
    ).get();
    for (final row in rows) {
      final at = DateTime.fromMillisecondsSinceEpoch(row.read<int>('at') * 1000);
      grid[at.weekday - 1][at.hour] += row.read<int>('total');
    }
    return grid;
  }

  /// Per product, biggest revenue first, graded A / B / C.
  Future<List<ProductFigures>> products(DateRange r) async {
    final rows = await _db.customSelect(
      "SELECT l.product_id AS id, MAX(l.product_name) AS name, COALESCE(MAX(c.name), '') AS category, "
      "SUM(CASE WHEN l.sell_by = 'each' THEN l.quantity ELSE 1 END) AS qty, "
      'SUM(l.line_total - l.discount - l.order_discount_share) AS revenue, SUM(l.cost_total) AS cost '
      'FROM sale_lines l JOIN sales s ON s.id = l.sale_id LEFT JOIN products p ON p.id = l.product_id '
      'LEFT JOIN categories c ON c.id = p.category_id '
      'WHERE l.deleted_at IS NULL AND $_completed GROUP BY l.product_id ORDER BY revenue DESC',
      variables: _range(r),
      readsFrom: {_db.sales, _db.saleLines, _db.products, _db.categories},
    ).get();
    final list = [
      for (final row in rows)
        ProductFigures(
          productId: row.read<String>('id'),
          name: row.read<String>('name'),
          category: row.read<String>('category'),
          quantity: row.read<int>('qty'),
          revenue: row.read<int>('revenue'),
          cost: row.read<int>('cost'),
        ),
    ];
    return grade(list);
  }

  /// ABC: A until 80% of revenue, B until 95%, C after. [list] is biggest first.
  static List<ProductFigures> grade(List<ProductFigures> list) {
    final total = list.fold(0, (s, p) => s + p.revenue);
    var running = 0;
    return [
      for (final p in list)
        () {
          final before = running;
          running += p.revenue;
          final share = total == 0 ? 1.0 : before / total;
          return p.withGrade(share < 0.8 ? 'A' : share < 0.95 ? 'B' : 'C');
        }(),
    ];
  }

  /// Options picked (name → count) over the period.
  Future<Map<String, int>> options(DateRange r) async {
    final rows = await (_db.select(_db.saleLines).join([innerJoin(_db.sales, _db.sales.id.equalsExp(_db.saleLines.saleId))])
          ..where(_db.sales.status.equalsValue(SaleStatus.completed) &
              _db.sales.createdAt.isBiggerOrEqualValue(r.from) &
              _db.sales.createdAt.isSmallerThanValue(r.to) &
              _db.saleLines.deletedAt.isNull()))
        .get();
    final out = <String, int>{};
    for (final row in rows) {
      final line = row.readTable(_db.saleLines);
      for (final a in line.addons) {
        out[a.name] = (out[a.name] ?? 0) + line.quantity;
      }
    }
    final sorted = out.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  /// Products on the till that have not sold for [days] days.
  Future<List<(String name, DateTime? last)>> slowMovers({int days = 14, DateTime? now}) async {
    final since = (now ?? DateTime.now()).subtract(Duration(days: days));
    final rows = await _db.customSelect(
      'SELECT p.name AS name, (SELECT MAX(s.created_at) FROM sale_lines l JOIN sales s ON s.id = l.sale_id '
      "WHERE l.product_id = p.id AND s.status = 'completed') AS last "
      'FROM products p WHERE p.deleted_at IS NULL AND p.active = 1 AND p.archived_at IS NULL ORDER BY last',
      readsFrom: {_db.products, _db.saleLines, _db.sales},
    ).get();
    return [
      for (final row in rows)
        if (row.read<int?>('last') == null ||
            DateTime.fromMillisecondsSinceEpoch(row.read<int>('last') * 1000).isBefore(since))
          (
            row.read<String>('name'),
            row.read<int?>('last') == null ? null : DateTime.fromMillisecondsSinceEpoch(row.read<int>('last') * 1000),
          ),
    ];
  }

  /// Takings per payment method name (pesewas), and the cash rounding.
  Future<(Map<String, int>, int)> payments(DateRange r) async {
    final rows = await _db.customSelect(
      'SELECT COALESCE(p.method_name, p.method) AS name, SUM(p.amount) AS v FROM payments p JOIN sales s ON s.id = p.sale_id '
      "WHERE p.deleted_at IS NULL AND p.method <> 'exchange' AND $_completed GROUP BY name ORDER BY v DESC",
      variables: _range(r),
      readsFrom: {_db.payments, _db.sales},
    ).get();
    final rounding = await _db.customSelect(
      'SELECT COALESCE(SUM(s.rounding), 0) AS v FROM sales s WHERE $_completed',
      variables: _range(r),
      readsFrom: {_db.sales},
    ).getSingle();
    return ({for (final row in rows) row.read<String>('name'): row.read<int>('v')}, rounding.read<int>('v'));
  }

  /// Per cashier: sales, voids, refunds, discounts, no-sales and shorts.
  Future<List<StaffFigures>> staff(DateRange r) async {
    final vars = _range(r);
    final sales = await _db.customSelect(
      // Discounts the cashier gave: promotions apply themselves.
      'SELECT s.cashier_name AS name, COUNT(*) AS n, SUM(s.total) AS total, '
      'SUM(s.discount_total - (SELECT COALESCE(SUM(l.promotion), 0) FROM sale_lines l WHERE l.sale_id = s.id)) AS discounts '
      'FROM sales s WHERE $_completed GROUP BY s.cashier_name',
      variables: vars,
      readsFrom: {_db.sales, _db.saleLines},
    ).get();
    final voids = await _db.customSelect(
      "SELECT voided_by AS name, COUNT(*) AS n FROM sales WHERE status = 'voided' AND created_at >= ? AND created_at < ? "
      'GROUP BY voided_by',
      variables: vars,
      readsFrom: {_db.sales},
    ).get();
    final refunds = await _db.customSelect(
      'SELECT staff_name AS name, COUNT(*) AS n FROM refunds WHERE deleted_at IS NULL AND created_at >= ? AND created_at < ? GROUP BY staff_name',
      variables: vars,
      readsFrom: {_db.refunds},
    ).get();
    final noSales = await _db.customSelect(
      "SELECT staff_name AS name, COUNT(*) AS n FROM cash_events WHERE kind = 'noSale' AND deleted_at IS NULL "
      'AND created_at >= ? AND created_at < ? GROUP BY staff_name',
      variables: vars,
      readsFrom: {_db.cashEvents},
    ).get();
    final closes = await _db.customSelect(
      'SELECT closed_by_name AS name, SUM(CASE WHEN counted_cash < expected_cash THEN 1 ELSE 0 END) AS n, '
      'SUM(CASE WHEN counted_cash < expected_cash THEN expected_cash - counted_cash ELSE 0 END) AS v FROM day_closes '
      'WHERE deleted_at IS NULL AND closed_at >= ? AND closed_at < ? GROUP BY closed_by_name',
      variables: vars,
      readsFrom: {_db.dayCloses},
    ).get();
    Map<String, int> count(List<QueryRow> rows) => {for (final x in rows) x.read<String?>('name') ?? '?': x.read<int>('n')};
    final v = count(voids), rf = count(refunds), ns = count(noSales);
    final sh = {for (final x in closes) x.read<String>('name'): (x.read<int>('n'), x.read<int>('v'))};
    final names = {for (final x in sales) x.read<String>('name'), ...v.keys, ...rf.keys, ...ns.keys, ...sh.keys};
    final byName = {for (final x in sales) x.read<String>('name'): x};
    return [
      for (final n in names)
        StaffFigures(
          name: n,
          sales: byName[n]?.read<int>('n') ?? 0,
          total: byName[n]?.read<int>('total') ?? 0,
          discounts: byName[n]?.read<int>('discounts') ?? 0,
          voids: v[n] ?? 0,
          refunds: rf[n] ?? 0,
          noSales: ns[n] ?? 0,
          shorts: sh[n]?.$1 ?? 0,
          shortTotal: sh[n]?.$2 ?? 0,
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
  }

  Future<CustomerFigures> customers(DateRange r) async {
    final top = await _db.customSelect(
      'SELECT c.name AS name, SUM(s.total) AS v FROM sales s JOIN customers c ON c.id = s.customer_id '
      'WHERE $_completed GROUP BY c.id ORDER BY v DESC LIMIT 10',
      variables: _range(r),
      readsFrom: {_db.sales, _db.customers},
    ).get();
    final firsts = await _db.customSelect(
      'SELECT s.customer_id AS id, MIN(s.created_at) AS first FROM sales s '
      "WHERE s.customer_id IS NOT NULL AND s.status = 'completed' AND s.deleted_at IS NULL GROUP BY s.customer_id "
      'HAVING MAX(s.created_at) >= ? AND MIN(s.created_at) < ?',
      variables: [Variable.withDateTime(r.from), Variable.withDateTime(r.to)],
      readsFrom: {_db.sales},
    ).get();
    var fresh = 0, returning = 0;
    for (final f in firsts) {
      final first = DateTime.fromMillisecondsSinceEpoch(f.read<int>('first') * 1000);
      first.isBefore(r.from) ? returning++ : fresh++;
    }
    final all = await _customers.list(includeInactive: true);
    var overdue = 0;
    final now = DateTime.now();
    for (final c in all.where((c) => c.owed > 0)) {
      overdue += CreditAging.of(await _customers.openDebts(c.id), now).overdue;
    }
    return CustomerFigures(
      top: [for (final t in top) (t.read<String>('name'), t.read<int>('v'))],
      newCustomers: fresh,
      returning: returning,
      owed: all.fold(0, (s, c) => s + (c.owed > 0 ? c.owed : 0)),
      overdue: overdue,
      wallets: all.fold(0, (s, c) => s + (c.wallet > 0 ? c.wallet : 0)),
    );
  }

  Future<StockTaxFigures> stockAndTax(DateRange r) async {
    final items = await _stock.items(includeInactive: true);
    final moves = await _db.customSelect(
      'SELECT m.reason AS reason, COALESCE(s.name, \'\') AS item, '
      'SUM(m.quantity_change * COALESCE(m.unit_cost_milli, 0)) AS v FROM stock_movements m '
      'LEFT JOIN stock_items s ON s.id = m.stock_item_id '
      'WHERE m.deleted_at IS NULL AND m.created_at >= ? AND m.created_at < ? GROUP BY m.reason, m.stock_item_id',
      variables: _range(r),
      readsFrom: {_db.stockMovements, _db.stockItems},
    ).get();
    int pesewas(int milli) => (milli + (milli >= 0 ? 500 : -500)) ~/ 1000;
    final byReason = <String, int>{};
    final waste = <(String, int)>[];
    final counts = <(String, int)>[];
    for (final m in moves) {
      final reason = m.read<String>('reason');
      final value = pesewas(m.read<int>('v'));
      byReason[reason] = (byReason[reason] ?? 0) + value;
      if (reason == StockReason.waste.name) waste.add((m.read<String>('item'), -value));
      if (reason == StockReason.count.name && value != 0) counts.add((m.read<String>('item'), value));
    }
    waste.sort((a, b) => b.$2.compareTo(a.$2));
    final taxes = await _db.customSelect(
      'SELECT t.name AS name, t.rate_bp AS bp, SUM(t.amount) AS v FROM sale_taxes t JOIN sales s ON s.id = t.sale_id '
      'WHERE t.deleted_at IS NULL AND $_completed GROUP BY t.name, t.rate_bp ORDER BY t.name',
      variables: _range(r),
      readsFrom: {_db.saleTaxes, _db.sales},
    ).get();
    return StockTaxFigures(
      stockValue: items.where((i) => i.active).fold(0, (s, i) => s + i.value),
      movements: byReason,
      waste: waste,
      countDifferences: counts,
      taxes: [for (final t in taxes) (t.read<String>('name'), t.read<int>('bp'), t.read<int>('v'))],
    );
  }
}
