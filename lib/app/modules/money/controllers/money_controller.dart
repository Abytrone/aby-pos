import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../core/period.dart';
import '../../../core/permissions.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../data/repositories/profit_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../models/enums.dart';
import '../../../models/expense.dart';
import '../../../models/purchasing.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// Manage → Money: expenses, the profit and loss, and the owner's money,
/// for a chosen period.
class MoneyController extends GetxController {
  final ExpenseRepository _expenses = Get.find();
  final ProfitRepository _profit = Get.find();
  final SupplierRepository _suppliers = Get.find();
  final PermissionService _permissions = Get.find();
  final AuthService _auth = Get.find();

  final period = ReportPeriod.thisMonth.obs;
  final from = DateTime.now().obs;
  final to = DateTime.now().obs;

  final expenses = <Expense>[].obs;
  final byCategory = <String, int>{}.obs;
  final due = <RecurringExpense>[].obs;
  final categories = <ExpenseCategory>[].obs;
  final suppliers = <Supplier>[].obs;
  final pnl = Rxn<ProfitAndLoss>();
  final previous = Rxn<ProfitAndLoss>();
  final owner = <OwnerMoneyEntry>[].obs;
  final loading = true.obs;
  final message = RxnString();

  bool get canSeeProfit => _auth.can(Permission.viewCostAndProfit);

  @override
  void onInit() {
    super.onInit();
    setPeriod(ReportPeriod.thisMonth);
  }

  Future<void> setPeriod(ReportPeriod p, {DateTime? start, DateTime? end}) async {
    final r = DateRange.of(p, DateTime.now(), start: start, end: end);
    period.value = p;
    from.value = r.from;
    to.value = r.to;
    await load();
  }

  DateRange get range => DateRange(from.value, to.value);

  Future<void> load() async {
    expenses.assignAll(await _expenses.list(from.value, to.value));
    byCategory.assignAll(await _expenses.byCategory(from.value, to.value));
    due.assignAll(await _expenses.due());
    categories.assignAll(await _expenses.categories());
    suppliers.assignAll(await _suppliers.list());
    owner.assignAll(await _expenses.ownerEntries(from.value, to.value));
    if (canSeeProfit) {
      pnl.value = await _profit.forPeriod(from.value, to.value);
      previous.value = await _profit.previous(from.value, to.value);
    }
    loading.value = false;
  }

  int get expenseTotal => byCategory.values.fold(0, (s, v) => s + v);
  int get drawings => owner.where((o) => o.kind == OwnerMoneyKind.drawing).fold(0, (s, o) => s + o.amount);
  int get capital => owner.where((o) => o.kind == OwnerMoneyKind.capital).fold(0, (s, o) => s + o.amount);

  Future<Authorization?> _authorize(String reason) => _permissions.authorize(Permission.manageExpenses, reason: reason);

  /// Returns an error to show, or null when saved (or cancelled).
  Future<String?> addExpense(ExpenseDraft d, {Uint8List? photo}) async {
    final auth = await _authorize(appL10n().expenseReason(formatMoney(d.amount)));
    if (auth == null) return null;
    try {
      await _expenses.add(d, photo: photo, actor: auth.actor, approver: auth.approver);
      message.value = appL10n().expenseSaved(formatMoney(d.amount));
      await load();
      return null;
    } on ExpenseException catch (e) {
      return e.message;
    }
  }

  Future<void> confirm(RecurringExpense r, {int? amount}) async {
    final auth = await _authorize(appL10n().expenseReason(formatMoney(amount ?? r.amount)));
    if (auth == null) return;
    await _expenses.confirm(r, amount: amount, actor: auth.actor, approver: auth.approver);
    await load();
  }

  Future<void> skip(RecurringExpense r) async {
    await _expenses.skip(r);
    await load();
  }

  Future<String?> saveRecurring({
    String? id,
    required String name,
    required String categoryId,
    required int amount,
    required int dayOfMonth,
    required MoneySource paidFrom,
  }) async {
    final auth = await _authorize(appL10n().recurringReason);
    if (auth == null) return null;
    try {
      await _expenses.saveRecurring(
        id: id,
        name: name,
        categoryId: categoryId,
        amount: amount,
        dayOfMonth: dayOfMonth,
        paidFrom: paidFrom,
        by: auth.authority,
      );
      await load();
      return null;
    } on ExpenseException catch (e) {
      return e.message;
    }
  }

  Future<List<RecurringExpense>> allRecurring() => _expenses.recurring(includeInactive: true);

  Future<void> setRecurringActive(RecurringExpense r, bool active) async {
    await _expenses.setRecurringActive(r.id, active: active, by: _auth.user);
    await load();
  }

  Future<List<ExpenseCategory>> allCategories() => _expenses.categories(includeInactive: true);

  Future<String?> saveCategory({String? id, required String name}) async {
    final auth = await _authorize(appL10n().expenseCategoryReason);
    if (auth == null) return null;
    try {
      await _expenses.saveCategory(id: id, name: name, by: auth.authority);
      await load();
      return null;
    } on ExpenseException catch (e) {
      return e.message;
    }
  }

  Future<void> setCategoryActive(ExpenseCategory c, bool active) async {
    final auth = await _authorize(appL10n().expenseCategoryReason);
    if (auth == null) return;
    await _expenses.setCategoryActive(c.id, active: active, by: auth.authority);
    await load();
  }

  Future<String?> ownerMoney(OwnerMoneyKind kind, int amount, MoneySource source, {String? note}) async {
    final l = appL10n();
    final auth = await _authorize(kind == OwnerMoneyKind.drawing ? l.ownerTookReason(formatMoney(amount)) : l.ownerPutReason(formatMoney(amount)));
    if (auth == null) return null;
    try {
      await _expenses.ownerMoney(kind: kind, amount: amount, source: source, note: note, actor: auth.actor, approver: auth.approver);
      await load();
      return null;
    } on ExpenseException catch (e) {
      return e.message;
    }
  }
}
