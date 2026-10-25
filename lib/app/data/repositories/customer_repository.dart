import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/validators.dart';
import '../../models/audit.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class CustomerException implements Exception {
  const CustomerException(this.message);
  final String message;

  @override
  String toString() => 'CustomerException: $message';
}

/// Customers, their credit book and their wallet. Balances are sums of the
/// ledger; nothing is overwritten.
class CustomerRepository {
  CustomerRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  // ---------------------------------------------------------------------------
  // Customers

  Future<Map<String, (int, int)>> _balances([String? customerId]) async {
    final rows = await _db.customSelect(
      "SELECT customer_id AS id, COALESCE(SUM(CASE WHEN account = 'credit' THEN amount END), 0) AS owed, "
      "COALESCE(SUM(CASE WHEN account = 'wallet' THEN amount END), 0) AS wallet FROM customer_ledger "
      'WHERE deleted_at IS NULL ${customerId == null ? '' : 'AND customer_id = ?'} GROUP BY customer_id',
      variables: [if (customerId != null) Variable.withString(customerId)],
      readsFrom: {_db.customerLedger},
    ).get();
    return {for (final r in rows) r.read<String>('id'): (r.read<int>('owed'), r.read<int>('wallet'))};
  }

  Customer _toModel(CustomerRow r, (int, int)? balance) => Customer(
        id: r.id,
        name: r.name,
        phone: r.phone,
        phone2: r.phone2,
        location: r.location,
        notes: r.notes,
        birthday: r.birthday,
        tags: (jsonDecode(r.tags) as List).cast<String>(),
        creditLimit: r.creditLimit,
        dueDays: r.dueDays,
        active: r.active,
        owed: balance?.$1 ?? 0,
        wallet: balance?.$2 ?? 0,
      );

  /// By name. [query]: 4 or more digits match phone numbers, anything else
  /// the name. [owing] keeps only customers who owe money.
  Future<List<Customer>> list({String query = '', bool owing = false, bool includeInactive = false, int limit = 500}) async {
    final q = _db.select(_db.customers)
      ..where((c) => c.deletedAt.isNull())
      ..orderBy([(c) => OrderingTerm(expression: c.name.collate(Collate.noCase))]);
    if (!includeInactive) q.where((c) => c.active.equals(true));
    final text = query.trim();
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4 && digits.length == text.replaceAll(RegExp(r'[\s+\-()]'), '').length) {
      // "0241" and "241 234" both find +233241234567.
      final tail = digits.startsWith('0') ? digits.substring(1) : digits.startsWith('233') ? digits.substring(3) : digits;
      q.where((c) => c.phone.like('%$tail%') | c.phone2.like('%$tail%'));
    } else if (text.isNotEmpty) {
      q.where((c) => c.name.lower().like('%${text.toLowerCase()}%'));
    }
    final balances = await _balances();
    final rows = await q.get();
    final list = [for (final r in rows) _toModel(r, balances[r.id])];
    return (owing ? list.where((c) => c.owed > 0).toList() : list).take(limit).toList();
  }

  Future<Customer?> find(String id) async {
    final row = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row, (await _balances(id))[id]);
  }

  Future<Customer?> byPhone(String phone) async {
    final normal = Validators.normalisePhone(phone);
    if (normal == null) return null;
    final row = await (_db.select(_db.customers)
          ..where((c) => c.phone.equals(normal) & c.active.equals(true) & c.deletedAt.isNull())
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toModel(row, (await _balances(row.id))[row.id]);
  }

  Future<String> save(CustomerDraft d, {required Staff by}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw const CustomerException('Enter the name.');
    String? phone(String? typed, String what) {
      if (typed == null || typed.trim().isEmpty) return null;
      final p = Validators.normalisePhone(typed);
      if (p == null) throw CustomerException('Check the $what: a Ghana number like 024 123 4567.');
      return p;
    }

    final main = phone(d.phone, 'phone number');
    final second = phone(d.phone2, 'second phone number');
    if ((d.creditLimit ?? 0) < 0) throw const CustomerException('The credit limit cannot be negative.');
    if ((d.dueDays ?? 0) < 0) throw const CustomerException('Days to pay cannot be negative.');
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final tags = {for (final t in d.tags) if (t.trim().isNotEmpty) t.trim()}.toList();

    return _db.transaction(() async {
      if (main != null) {
        final taken = await (_db.select(_db.customers)
              ..where((c) => c.phone.equals(main) & c.active.equals(true) & c.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
        if (taken != null && taken.id != d.id) {
          throw CustomerException('${Validators.formatPhone(main)} is already ${taken.name}.');
        }
      }
      final now = DateTime.now();
      final id = d.id ?? newId();
      if (d.id == null) {
        await _db.insertTracked(
          _db.customers,
          CustomersCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: name,
            phone: Value(main),
            phone2: Value(second),
            location: Value(clean(d.location)),
            notes: Value(clean(d.notes)),
            birthday: Value(d.birthday),
            tags: Value(jsonEncode(tags)),
            creditLimit: Value(d.creditLimit),
            dueDays: Value(d.dueDays),
          ),
        );
      } else {
        final row = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingle();
        await _db.updateTracked(
          _db.customers,
          row.copyWith(
            name: name,
            phone: Value(main),
            phone2: Value(second),
            location: Value(clean(d.location)),
            notes: Value(clean(d.notes)),
            birthday: Value(d.birthday),
            tags: jsonEncode(tags),
            creditLimit: Value(d.creditLimit),
            dueDays: Value(d.dueDays),
            updatedAt: now,
          ),
        );
        if (row.creditLimit != d.creditLimit) {
          await _audit.record(
            action: AuditAction.customerCreditLimit,
            actor: by,
            entity: 'customers',
            entityId: id,
            summary: '$name: credit limit '
                '${row.creditLimit == null ? 'none' : formatMoney(row.creditLimit!)} to '
                '${d.creditLimit == null ? 'none' : formatMoney(d.creditLimit!)}',
          );
        }
      }
      if (d.id == null) {
        await _audit.record(
          action: AuditAction.customerSaved,
          actor: by,
          entity: 'customers',
          entityId: id,
          summary: 'Added customer $name',
        );
      }
      return id;
    });
  }

  Future<void> setActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.customers)..where((c) => c.id.equals(id))).getSingle();
      await _db.updateTracked(_db.customers, row.copyWith(active: active, updatedAt: DateTime.now()));
      await _audit.record(
        action: AuditAction.customerSaved,
        actor: by,
        entity: 'customers',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} customer ${row.name}',
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Ledger

  /// Newest first; both accounts unless [account] is given.
  Future<List<CustomerEntry>> ledger(String customerId, {CustomerAccount? account, DateTime? from, DateTime? to}) async {
    final q = _db.select(_db.customerLedger).join([
      leftOuterJoin(_db.sales, _db.sales.id.equalsExp(_db.customerLedger.saleId)),
    ])
      ..where(_db.customerLedger.customerId.equals(customerId) & _db.customerLedger.deletedAt.isNull())
      ..orderBy([
        OrderingTerm(expression: _db.customerLedger.createdAt, mode: OrderingMode.desc),
        OrderingTerm(expression: _db.customerLedger.id, mode: OrderingMode.desc),
      ]);
    if (account != null) q.where(_db.customerLedger.account.equalsValue(account));
    if (from != null) q.where(_db.customerLedger.createdAt.isBiggerOrEqualValue(from));
    if (to != null) q.where(_db.customerLedger.createdAt.isSmallerThanValue(to));
    return [
      for (final r in await q.get())
        () {
          final e = r.readTable(_db.customerLedger);
          return CustomerEntry(
            id: e.id,
            at: e.createdAt,
            account: e.account,
            kind: e.kind,
            amount: e.amount,
            byName: e.byName,
            saleId: e.saleId,
            saleNumber: r.readTableOrNull(_db.sales)?.number,
            dueOn: e.dueOn,
            methodName: e.methodName,
            reference: e.reference,
            note: e.note,
            approverName: e.approverName,
          );
        }(),
    ];
  }

  /// The account balance just before [at] (for statements).
  Future<int> balanceBefore(String customerId, CustomerAccount account, DateTime at) async {
    final row = await _db.customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS b FROM customer_ledger WHERE customer_id = ? AND account = ? '
      'AND deleted_at IS NULL AND created_at < ?',
      variables: [Variable.withString(customerId), Variable.withString(account.name), Variable.withDateTime(at)],
      readsFrom: {_db.customerLedger},
    ).getSingle();
    return row.read<int>('b');
  }

  /// Credit sales still (partly) unpaid. Repayments for a chosen sale go
  /// to it first; the rest pays the oldest debts first.
  Future<List<OpenDebt>> openDebts(String customerId) async {
    final entries = (await ledger(customerId, account: CustomerAccount.credit)).reversed.toList();
    final debts = <OpenDebt>[];
    final outstanding = <int>[];
    var free = 0;
    final aimed = <String, int>{};
    for (final e in entries) {
      if (e.amount > 0) {
        debts.add(OpenDebt(saleId: e.saleId, saleNumber: e.saleNumber, at: e.at, amount: e.amount, outstanding: e.amount, dueOn: e.dueOn));
        outstanding.add(e.amount);
      }
    }
    final rows = await (_db.select(_db.customerLedger)
          ..where((x) =>
              x.customerId.equals(customerId) &
              x.account.equalsValue(CustomerAccount.credit) &
              x.deletedAt.isNull() &
              x.amount.isSmallerThanValue(0)))
        .get();
    for (final r in rows) {
      if (r.appliesToSaleId != null) {
        aimed[r.appliesToSaleId!] = (aimed[r.appliesToSaleId!] ?? 0) - r.amount;
      } else if (r.saleId != null && r.kind == CustomerEntryKind.creditRefund) {
        aimed[r.saleId!] = (aimed[r.saleId!] ?? 0) - r.amount;
      } else {
        free -= r.amount;
      }
    }
    for (var i = 0; i < debts.length; i++) {
      final take = aimed[debts[i].saleId] ?? 0;
      final used = take > outstanding[i] ? outstanding[i] : take;
      outstanding[i] -= used;
      if (debts[i].saleId != null) aimed[debts[i].saleId!] = take - used;
    }
    // Aimed money left over (overpaid one sale) pays the oldest like the rest.
    free += aimed.values.fold(0, (s, v) => s + (v > 0 ? v : 0));
    for (var i = 0; i < debts.length && free > 0; i++) {
      final used = free > outstanding[i] ? outstanding[i] : free;
      outstanding[i] -= used;
      free -= used;
    }
    return [
      for (final (i, d) in debts.indexed)
        if (outstanding[i] > 0)
          OpenDebt(saleId: d.saleId, saleNumber: d.saleNumber, at: d.at, amount: d.amount, outstanding: outstanding[i], dueOn: d.dueOn),
    ];
  }

  Future<CreditAging> aging(String customerId, {DateTime? now}) async =>
      CreditAging.of(await openDebts(customerId), now ?? DateTime.now());

  Future<CustomerStats> stats(String customerId) async {
    final totals = await _db.customSelect(
      'SELECT COUNT(*) AS visits, COALESCE(SUM(s.total), 0) AS spend, MAX(s.created_at) AS last, '
      '(SELECT COALESCE(SUM(r.total), 0) FROM refunds r JOIN sales x ON x.id = r.sale_id '
      ' WHERE x.customer_id = ? AND r.deleted_at IS NULL) AS refunded FROM sales s '
      "WHERE s.customer_id = ? AND s.status = 'completed' AND s.deleted_at IS NULL",
      variables: [Variable.withString(customerId), Variable.withString(customerId)],
      readsFrom: {_db.sales, _db.refunds},
    ).getSingle();
    final top = await _db.customSelect(
      'SELECT l.product_name AS name, SUM(l.quantity) AS qty FROM sale_lines l JOIN sales s ON s.id = l.sale_id '
      "WHERE s.customer_id = ? AND s.status = 'completed' AND l.deleted_at IS NULL "
      'GROUP BY l.product_name ORDER BY qty DESC LIMIT 3',
      variables: [Variable.withString(customerId)],
      readsFrom: {_db.sales, _db.saleLines},
    ).get();
    final last = totals.read<int?>('last');
    return CustomerStats(
      spend: totals.read<int>('spend') - totals.read<int>('refunded'),
      visits: totals.read<int>('visits'),
      lastVisit: last == null ? null : DateTime.fromMillisecondsSinceEpoch(last * 1000),
      favourites: [for (final r in top) r.read<String>('name')],
    );
  }

  /// This customer's sales, newest first.
  Future<List<(String id, int number, DateTime at, int total, SaleStatus status)>> sales(String customerId,
      {int limit = 50}) async {
    final rows = await (_db.select(_db.sales)
          ..where((s) => s.customerId.equals(customerId) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();
    return [for (final s in rows) (s.id, s.number, s.createdAt, s.total, s.status)];
  }

  /// Writes an entry inside the caller's transaction (sales and refunds).
  Future<void> addEntry({
    required String customerId,
    required CustomerAccount account,
    required CustomerEntryKind kind,
    required int amount,
    required String byName,
    String? saleId,
    String? refundId,
    String? appliesToSaleId,
    DateTime? dueOn,
    PaymentMethod? method,
    String? methodName,
    String? reference,
    String? note,
    String? approverName,
  }) async {
    final now = DateTime.now();
    await _db.insertTracked(
      _db.customerLedger,
      CustomerLedgerCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        customerId: customerId,
        account: account,
        kind: kind,
        amount: amount,
        saleId: Value(saleId),
        refundId: Value(refundId),
        appliesToSaleId: Value(appliesToSaleId),
        dueOn: Value(dueOn),
        method: Value(method),
        methodName: Value(methodName),
        reference: Value(reference?.trim().isEmpty ?? true ? null : reference!.trim()),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
        byName: byName,
        approverName: Value(approverName),
      ),
    );
  }

  /// Money paid towards what is owed. [forSaleId] pays that sale first.
  Future<void> repay(
    String customerId, {
    required int amount,
    required PayMethod method,
    String? reference,
    String? forSaleId,
    String? note,
    required Staff by,
  }) async {
    if (amount <= 0) throw const CustomerException('Enter the amount paid.');
    if (method.kind == PaymentMethod.credit || method.kind == PaymentMethod.wallet) {
      throw const CustomerException('Choose how the money was paid.');
    }
    if (method.needsReference && (reference ?? '').trim().isEmpty) {
      throw CustomerException('Enter the transaction reference for ${method.name}.');
    }
    await _db.transaction(() async {
      final c = await find(customerId);
      if (c == null) throw const CustomerException('Customer not found.');
      if (amount > c.owed) {
        throw CustomerException('${c.name} owes ${formatMoney(c.owed)}. Put anything more in their wallet.');
      }
      await addEntry(
        customerId: customerId,
        account: CustomerAccount.credit,
        kind: CustomerEntryKind.repayment,
        amount: -amount,
        byName: by.name,
        appliesToSaleId: forSaleId,
        method: method.kind,
        methodName: method.name,
        reference: reference,
        note: note,
      );
      await _audit.record(
        action: AuditAction.customerRepaid,
        actor: by,
        entity: 'customers',
        entityId: customerId,
        summary: '${c.name} paid ${formatMoney(amount)} by ${method.name}; owes ${formatMoney(c.owed - amount)}',
      );
    });
  }

  /// Money paid in to be spent later (an advance), into the wallet.
  Future<void> topUp(String customerId, {required int amount, required PayMethod method, String? reference, String? note, required Staff by}) async {
    if (amount <= 0) throw const CustomerException('Enter the amount.');
    if (method.kind == PaymentMethod.credit || method.kind == PaymentMethod.wallet) {
      throw const CustomerException('Choose how the money was paid.');
    }
    await _db.transaction(() async {
      final c = await find(customerId);
      if (c == null) throw const CustomerException('Customer not found.');
      await addEntry(
        customerId: customerId,
        account: CustomerAccount.wallet,
        kind: CustomerEntryKind.topUp,
        amount: amount,
        byName: by.name,
        method: method.kind,
        methodName: method.name,
        reference: reference,
        note: note,
      );
      await _audit.record(
        action: AuditAction.walletTopUp,
        actor: by,
        entity: 'customers',
        entityId: customerId,
        summary: '${c.name}: ${formatMoney(amount)} into the wallet by ${method.name}',
      );
    });
  }

  /// Forgives what is owed (all or part). Owner permission; always audited.
  Future<void> writeOff(String customerId, {required int amount, required String reason, required Staff actor, Staff? approver}) async {
    if (amount <= 0) throw const CustomerException('Enter the amount to write off.');
    if (reason.trim().isEmpty) throw const CustomerException('Give a reason.');
    await _db.transaction(() async {
      final c = await find(customerId);
      if (c == null) throw const CustomerException('Customer not found.');
      if (amount > c.owed) throw CustomerException('${c.name} only owes ${formatMoney(c.owed)}.');
      await addEntry(
        customerId: customerId,
        account: CustomerAccount.credit,
        kind: CustomerEntryKind.writeOff,
        amount: -amount,
        byName: actor.name,
        approverName: approver?.name,
        note: reason,
      );
      await _audit.record(
        action: AuditAction.creditWrittenOff,
        actor: actor,
        approver: approver,
        entity: 'customers',
        entityId: customerId,
        summary: 'Wrote off ${formatMoney(amount)} owed by ${c.name}: ${reason.trim()}',
      );
    });
  }

  /// Cash from customers on this device since [from], for the drawer:
  /// repayments, top-ups and change kept, by kind of payment.
  Future<Map<PaymentMethod, int>> moneyInSince(DateTime? from) async {
    final rows = await _db.customSelect(
      'SELECT method, COALESCE(SUM(ABS(amount)), 0) AS total FROM customer_ledger '
      "WHERE device_id = ? AND deleted_at IS NULL AND method IS NOT NULL AND kind IN ('repayment', 'topUp', 'changeKept') "
      '${from == null ? '' : 'AND created_at > ?'} GROUP BY method',
      variables: [Variable.withString(_device.deviceId), if (from != null) Variable.withDateTime(from)],
      readsFrom: {_db.customerLedger},
    ).get();
    return {for (final r in rows) PaymentMethod.values.byName(r.read<String>('method')): r.read<int>('total')};
  }
}
