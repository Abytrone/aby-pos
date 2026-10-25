import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/expense.dart';
import '../database/app_database.dart';
import 'expense_repository.dart';

/// The simple profit and loss: sales less refunds, discounts and tax, less
/// what the stock cost, less expenses and lost stock. Not full accounting.
class ProfitRepository {
  ProfitRepository(this._db, this._expenses);

  final AppDatabase _db;
  final ExpenseRepository _expenses;

  Future<ProfitAndLoss> forPeriod(DateTime from, DateTime to) async {
    final vars = [Variable.withDateTime(from), Variable.withDateTime(to)];
    final sales = await _db.customSelect(
      'SELECT COALESCE(SUM(total + discount_total), 0) AS sales, COALESCE(SUM(discount_total), 0) AS discounts, '
      'COALESCE(SUM(tax_total), 0) AS tax FROM sales '
      "WHERE status = 'completed' AND deleted_at IS NULL AND created_at >= ? AND created_at < ?",
      variables: vars,
      readsFrom: {_db.sales},
    ).getSingle();
    final refunds = await _db.customSelect(
      'SELECT COALESCE(SUM(total), 0) AS v FROM refunds WHERE deleted_at IS NULL AND created_at >= ? AND created_at < ?',
      variables: vars,
      readsFrom: {_db.refunds},
    ).getSingle();
    final cost = await _db.customSelect(
      'SELECT COALESCE(SUM(l.cost_total), 0) AS v FROM sale_lines l JOIN sales s ON s.id = l.sale_id '
      "WHERE s.status = 'completed' AND s.deleted_at IS NULL AND l.deleted_at IS NULL AND s.created_at >= ? AND s.created_at < ?",
      variables: vars,
      readsFrom: {_db.sales, _db.saleLines},
    ).getSingle();
    // What came back into stock no longer counts as sold.
    final returned = await _db.customSelect(
      'SELECT COALESCE(SUM(sl.cost_total * rl.quantity / sl.quantity), 0) AS v FROM refund_lines rl '
      'JOIN refunds r ON r.id = rl.refund_id JOIN sale_lines sl ON sl.id = rl.sale_line_id '
      'WHERE rl.restocked = 1 AND rl.deleted_at IS NULL AND r.deleted_at IS NULL AND sl.quantity > 0 '
      'AND r.created_at >= ? AND r.created_at < ?',
      variables: vars,
      readsFrom: {_db.refundLines, _db.refunds, _db.saleLines},
    ).getSingle();
    final stock = await _db.customSelect(
      "SELECT COALESCE(SUM(CASE WHEN reason = 'waste' THEN -quantity_change * COALESCE(unit_cost_milli, 0) END), 0) AS waste, "
      "COALESCE(SUM(CASE WHEN reason = 'count' THEN quantity_change * COALESCE(unit_cost_milli, 0) END), 0) AS counts "
      'FROM stock_movements WHERE deleted_at IS NULL AND created_at >= ? AND created_at < ?',
      variables: vars,
      readsFrom: {_db.stockMovements},
    ).getSingle();
    final owner = await _expenses.ownerEntries(from, to);
    int milli(int v) => (v + (v >= 0 ? 500 : -500)) ~/ 1000;
    return ProfitAndLoss(
      from: from,
      to: to,
      sales: sales.read<int>('sales'),
      discounts: sales.read<int>('discounts'),
      tax: sales.read<int>('tax'),
      refunds: refunds.read<int>('v'),
      costOfGoods: cost.read<int>('v') - returned.read<int>('v'),
      expenses: await _expenses.byCategory(from, to),
      waste: milli(stock.read<int>('waste')),
      countDifference: milli(stock.read<int>('counts')),
      drawings: owner.where((o) => o.kind == OwnerMoneyKind.drawing).fold(0, (s, o) => s + o.amount),
      capital: owner.where((o) => o.kind == OwnerMoneyKind.capital).fold(0, (s, o) => s + o.amount),
    );
  }

  /// The same length of time just before [from].
  Future<ProfitAndLoss> previous(DateTime from, DateTime to) => forPeriod(from.subtract(to.difference(from)), from);
}
