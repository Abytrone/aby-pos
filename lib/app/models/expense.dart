import 'enums.dart';

class ExpenseCategory {
  const ExpenseCategory({required this.id, required this.name, this.active = true});

  final String id;
  final String name;
  final bool active;
}

class Expense {
  const Expense({
    required this.id,
    required this.day,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.paidFrom,
    required this.byName,
    this.supplierName,
    this.note,
    this.hasPhoto = false,
  });

  final String id;
  final DateTime day;

  /// Pesewas.
  final int amount;
  final String categoryId;
  final String categoryName;
  final MoneySource paidFrom;
  final String byName;
  final String? supplierName;
  final String? note;
  final bool hasPhoto;
}

class ExpenseDraft {
  const ExpenseDraft({
    required this.day,
    required this.amount,
    required this.categoryId,
    required this.paidFrom,
    this.supplierId,
    this.note,
    this.recurringId,
  });

  final DateTime day;
  final int amount;
  final String categoryId;
  final MoneySource paidFrom;
  final String? supplierId;
  final String? note;
  final String? recurringId;
}

/// "Rent GH₵ 800 on the 1st".
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.amount,
    required this.dayOfMonth,
    required this.paidFrom,
    this.active = true,
    this.doneUpTo,
  });

  final String id;
  final String name;
  final String categoryId;
  final int amount;
  final int dayOfMonth;
  final MoneySource paidFrom;
  final bool active;

  /// "2026-10": the last month confirmed or skipped.
  final String? doneUpTo;

  static String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  /// Due this month and not yet confirmed or skipped.
  bool dueOn(DateTime now) =>
      active && now.day >= dayOfMonth && (doneUpTo == null || doneUpTo!.compareTo(monthKey(now)) < 0);
}

class OwnerMoneyEntry {
  const OwnerMoneyEntry({
    required this.id,
    required this.at,
    required this.kind,
    required this.amount,
    required this.source,
    required this.byName,
    this.note,
  });

  final String id;
  final DateTime at;
  final OwnerMoneyKind kind;

  /// Pesewas, positive.
  final int amount;
  final MoneySource source;
  final String byName;
  final String? note;
}

/// A simple profit and loss for a period, in plain words. Pesewas.
class ProfitAndLoss {
  const ProfitAndLoss({
    required this.from,
    required this.to,
    this.sales = 0,
    this.discounts = 0,
    this.refunds = 0,
    this.tax = 0,
    this.costOfGoods = 0,
    this.expenses = const {},
    this.waste = 0,
    this.countDifference = 0,
    this.drawings = 0,
    this.capital = 0,
  });

  final DateTime from;
  final DateTime to;

  /// At menu prices, before discounts.
  final int sales;
  final int discounts;
  final int refunds;

  /// Tax collected for GRA (not the shop's money).
  final int tax;

  /// What the stock sold cost (recipes and costs), less what came back.
  final int costOfGoods;

  /// By category name.
  final Map<String, int> expenses;

  /// Stock thrown away, and found (+) or missing (−) at counts, at cost.
  final int waste;
  final int countDifference;

  /// The owner's own money, kept out of profit.
  final int drawings;
  final int capital;

  int get netSales => sales - discounts - refunds - tax;
  int get grossProfit => netSales - costOfGoods;
  int get expenseTotal => expenses.values.fold(0, (s, v) => s + v);
  int get netProfit => grossProfit - expenseTotal - waste + countDifference;

  /// Of net sales, rounded; null when nothing was sold.
  int? get grossMarginPercent => netSales <= 0 ? null : (grossProfit * 100 / netSales).round();
}
