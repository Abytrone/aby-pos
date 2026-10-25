import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/expense.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'cash_event_repository.dart';

class ExpenseException implements Exception {
  const ExpenseException(this.message);
  final String message;

  @override
  String toString() => 'ExpenseException: $message';
}

/// Expenses, their categories, recurring reminders, and the owner's own
/// money (drawings and capital). Paid from the drawer, each is also a cash
/// event, so close day's expected cash follows.
class ExpenseRepository {
  ExpenseRepository(this._db, this._device, this._audit, this._cash);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final CashEventRepository _cash;

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  // ---------------------------------------------------------------------------
  // Categories

  Future<List<ExpenseCategory>> categories({bool includeInactive = false}) async {
    final q = _db.select(_db.expenseCategories)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm(expression: c.sortOrder), (c) => OrderingTerm(expression: c.name)]);
    if (!includeInactive) q.where((c) => c.active.equals(true));
    return [for (final r in await q.get()) ExpenseCategory(id: r.id, name: r.name, active: r.active)];
  }

  Future<String> saveCategory({String? id, required String name, required Staff by}) async {
    final clean = name.trim();
    if (clean.isEmpty) throw const ExpenseException('Enter a name.');
    return _db.transaction(() async {
      final taken = await (_db.select(_db.expenseCategories)
            ..where((c) => c.name.lower().equals(clean.toLowerCase()) & c.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();
      if (taken != null && taken.id != id) throw const ExpenseException('That category is already on the list.');
      final now = DateTime.now();
      final rowId = id ?? newId();
      if (id == null) {
        final max = _db.expenseCategories.sortOrder.max();
        final q = _db.selectOnly(_db.expenseCategories)..addColumns([max]);
        await _db.insertTracked(
          _db.expenseCategories,
          ExpenseCategoriesCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: clean,
            sortOrder: Value(((await q.map((r) => r.read(max)).getSingle()) ?? -1) + 1),
          ),
        );
      } else {
        final row = await (_db.select(_db.expenseCategories)..where((c) => c.id.equals(id))).getSingle();
        await _db.updateTracked(_db.expenseCategories, row.copyWith(name: clean, updatedAt: now));
      }
      await _audit.record(
        action: AuditAction.expenseCategorySaved,
        actor: by,
        entity: 'expense_categories',
        entityId: rowId,
        summary: '${id == null ? 'Added' : 'Renamed'} expense category $clean',
      );
      return rowId;
    });
  }

  Future<void> setCategoryActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.expenseCategories)..where((c) => c.id.equals(id))).getSingle();
      await _db.updateTracked(_db.expenseCategories, row.copyWith(active: active, updatedAt: DateTime.now()));
      await _audit.record(
        action: AuditAction.expenseCategorySaved,
        actor: by,
        entity: 'expense_categories',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} expense category ${row.name}',
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Expenses

  Future<String> add(ExpenseDraft d, {Uint8List? photo, required Staff actor, Staff? approver}) async {
    if (d.amount <= 0) throw const ExpenseException('Enter the amount.');
    return _db.transaction(() async {
      final category = await (_db.select(_db.expenseCategories)..where((c) => c.id.equals(d.categoryId))).getSingleOrNull();
      if (category == null) throw const ExpenseException('Pick a category.');
      final cashId = d.paidFrom == MoneySource.drawer
          ? await _cash.record(
              kind: CashEventKind.payOut,
              amount: -d.amount,
              reason: category.name,
              note: d.note,
              actor: actor,
              approver: approver,
            )
          : null;
      final now = DateTime.now();
      final id = newId();
      await _db.insertTracked(
        _db.expenses,
        ExpensesCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          day: _dayOf(d.day),
          amount: d.amount,
          categoryId: d.categoryId,
          paidFrom: d.paidFrom,
          supplierId: Value(d.supplierId),
          note: Value(d.note?.trim().isEmpty ?? true ? null : d.note!.trim()),
          byName: (approver ?? actor).name,
          cashEventId: Value(cashId),
          recurringId: Value(d.recurringId),
        ),
      );
      if (photo != null) await _cash.savePhoto(id, photo);
      await _audit.record(
        action: AuditAction.expenseAdded,
        actor: actor,
        approver: approver,
        entity: 'expenses',
        entityId: id,
        summary: '${category.name}: ${formatMoney(d.amount)} from ${d.paidFrom.name}'
            '${d.note == null || d.note!.trim().isEmpty ? '' : ' (${d.note!.trim()})'}',
      );
      return id;
    });
  }

  /// Days [from] to [to] (exclusive), newest first.
  Future<List<Expense>> list(DateTime from, DateTime to) async {
    final q = _db.select(_db.expenses).join([
      innerJoin(_db.expenseCategories, _db.expenseCategories.id.equalsExp(_db.expenses.categoryId)),
      leftOuterJoin(_db.suppliers, _db.suppliers.id.equalsExp(_db.expenses.supplierId)),
    ])
      ..where(_db.expenses.deletedAt.isNull() &
          _db.expenses.day.isBiggerOrEqualValue(_dayOf(from)) &
          _db.expenses.day.isSmallerThanValue(to))
      ..orderBy([
        OrderingTerm(expression: _db.expenses.day, mode: OrderingMode.desc),
        OrderingTerm(expression: _db.expenses.createdAt, mode: OrderingMode.desc),
      ]);
    final rows = await q.get();
    final photos = rows.isEmpty
        ? const <String>{}
        : {
            for (final p in await (_db.selectOnly(_db.receiptPhotos)
                  ..addColumns([_db.receiptPhotos.ownerId])
                  ..where(_db.receiptPhotos.ownerId.isIn(rows.map((r) => r.readTable(_db.expenses).id))))
                .get())
              p.read(_db.receiptPhotos.ownerId)!,
          };
    return [
      for (final r in rows)
        () {
          final e = r.readTable(_db.expenses);
          return Expense(
            id: e.id,
            day: e.day,
            amount: e.amount,
            categoryId: e.categoryId,
            categoryName: r.readTable(_db.expenseCategories).name,
            paidFrom: e.paidFrom,
            byName: e.byName,
            supplierName: r.readTableOrNull(_db.suppliers)?.name,
            note: e.note,
            hasPhoto: photos.contains(e.id),
          );
        }(),
    ];
  }

  /// Pesewas per category name, biggest first.
  Future<Map<String, int>> byCategory(DateTime from, DateTime to) async {
    final out = <String, int>{};
    for (final e in await list(from, to)) {
      out[e.categoryName] = (out[e.categoryName] ?? 0) + e.amount;
    }
    final sorted = out.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted) e.key: e.value};
  }

  // ---------------------------------------------------------------------------
  // Recurring

  Future<List<RecurringExpense>> recurring({bool includeInactive = false}) async {
    final q = _db.select(_db.recurringExpenses)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm(expression: r.dayOfMonth), (r) => OrderingTerm(expression: r.name)]);
    if (!includeInactive) q.where((r) => r.active.equals(true));
    return [
      for (final r in await q.get())
        RecurringExpense(
          id: r.id,
          name: r.name,
          categoryId: r.categoryId,
          amount: r.amount,
          dayOfMonth: r.dayOfMonth,
          paidFrom: r.paidFrom,
          active: r.active,
          doneUpTo: r.doneUpTo,
        ),
    ];
  }

  Future<String> saveRecurring({
    String? id,
    required String name,
    required String categoryId,
    required int amount,
    required int dayOfMonth,
    required MoneySource paidFrom,
    required Staff by,
  }) async {
    if (name.trim().isEmpty) throw const ExpenseException('Enter a name.');
    if (amount <= 0) throw const ExpenseException('Enter the amount.');
    if (dayOfMonth < 1 || dayOfMonth > 28) throw const ExpenseException('Pick a day from 1 to 28.');
    return _db.transaction(() async {
      final now = DateTime.now();
      final rowId = id ?? newId();
      if (id == null) {
        await _db.insertTracked(
          _db.recurringExpenses,
          RecurringExpensesCompanion.insert(
            id: rowId,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: name.trim(),
            categoryId: categoryId,
            amount: amount,
            dayOfMonth: dayOfMonth,
            paidFrom: paidFrom,
            // A reminder added after its day this month starts next month.
            doneUpTo: Value(now.day >= dayOfMonth ? RecurringExpense.monthKey(now) : null),
          ),
        );
      } else {
        final row = await (_db.select(_db.recurringExpenses)..where((r) => r.id.equals(id))).getSingle();
        await _db.updateTracked(
          _db.recurringExpenses,
          row.copyWith(
            name: name.trim(),
            categoryId: categoryId,
            amount: amount,
            dayOfMonth: dayOfMonth,
            paidFrom: paidFrom,
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.expenseCategorySaved,
        actor: by,
        entity: 'recurring_expenses',
        entityId: rowId,
        summary: '${id == null ? 'Added' : 'Changed'} the reminder "${name.trim()}": ${formatMoney(amount)} on day $dayOfMonth',
      );
      return rowId;
    });
  }

  Future<void> setRecurringActive(String id, {required bool active}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.recurringExpenses)..where((r) => r.id.equals(id))).getSingle();
      await _db.updateTracked(_db.recurringExpenses, row.copyWith(active: active, updatedAt: DateTime.now()));
    });
  }

  /// Reminders due this month and not yet confirmed or skipped.
  Future<List<RecurringExpense>> due({DateTime? now}) async {
    final at = now ?? DateTime.now();
    return (await recurring()).where((r) => r.dueOn(at)).toList();
  }

  /// Records this month's expense from the reminder ([amount] may differ).
  Future<void> confirm(RecurringExpense r, {int? amount, required Staff actor, Staff? approver, DateTime? now}) {
    final at = now ?? DateTime.now();
    return _db.transaction(() async {
      await add(
        ExpenseDraft(
          day: DateTime(at.year, at.month, r.dayOfMonth),
          amount: amount ?? r.amount,
          categoryId: r.categoryId,
          paidFrom: r.paidFrom,
          note: r.name,
          recurringId: r.id,
        ),
        actor: actor,
        approver: approver,
      );
      await _markDone(r.id, at);
    });
  }

  /// Not this month.
  Future<void> skip(RecurringExpense r, {DateTime? now}) => _db.transaction(() => _markDone(r.id, now ?? DateTime.now()));

  Future<void> _markDone(String id, DateTime at) async {
    final row = await (_db.select(_db.recurringExpenses)..where((x) => x.id.equals(id))).getSingle();
    await _db.updateTracked(
      _db.recurringExpenses,
      row.copyWith(doneUpTo: Value(RecurringExpense.monthKey(at)), updatedAt: DateTime.now()),
    );
  }

  // ---------------------------------------------------------------------------
  // The owner's own money

  Future<void> ownerMoney({
    required OwnerMoneyKind kind,
    required int amount,
    required MoneySource source,
    String? note,
    required Staff actor,
    Staff? approver,
  }) async {
    if (amount <= 0) throw const ExpenseException('Enter the amount.');
    if (source == MoneySource.ownerPocket) throw const ExpenseException('Choose where the money went or came from.');
    final drawing = kind == OwnerMoneyKind.drawing;
    await _db.transaction(() async {
      final cashId = source == MoneySource.drawer
          ? await _cash.record(
              kind: drawing ? CashEventKind.payOut : CashEventKind.payIn,
              amount: drawing ? -amount : amount,
              reason: drawing ? 'Owner drawing' : 'Owner put money in',
              note: note,
              actor: actor,
              approver: approver,
            )
          : null;
      final now = DateTime.now();
      final id = newId();
      await _db.insertTracked(
        _db.ownerMoney,
        OwnerMoneyCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          kind: kind,
          amount: amount,
          source: source,
          note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
          byName: (approver ?? actor).name,
          cashEventId: Value(cashId),
        ),
      );
      await _audit.record(
        action: drawing ? AuditAction.ownerDrawing : AuditAction.ownerCapital,
        actor: actor,
        approver: approver,
        entity: 'owner_money',
        entityId: id,
        summary: '${drawing ? 'Owner took' : 'Owner put in'} ${formatMoney(amount)} (${source.name})',
      );
    });
  }

  /// Newest first.
  Future<List<OwnerMoneyEntry>> ownerEntries(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.ownerMoney)
          ..where((o) => o.deletedAt.isNull() & o.createdAt.isBiggerOrEqualValue(from) & o.createdAt.isSmallerThanValue(to))
          ..orderBy([(o) => OrderingTerm(expression: o.createdAt, mode: OrderingMode.desc)]))
        .get();
    return [
      for (final r in rows)
        OwnerMoneyEntry(id: r.id, at: r.createdAt, kind: r.kind, amount: r.amount, source: r.source, byName: r.byName, note: r.note),
    ];
  }
}
