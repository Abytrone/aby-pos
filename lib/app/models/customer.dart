import 'enums.dart';

/// Someone who buys, found by phone. Balances are sums of their ledger.
class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.phone2,
    this.location,
    this.notes,
    this.birthday,
    this.tags = const [],
    this.creditLimit,
    this.dueDays,
    this.active = true,
    this.owed = 0,
    this.wallet = 0,
  });

  final String id;
  final String name;

  /// +233XXXXXXXXX.
  final String? phone;
  final String? phone2;
  final String? location;
  final String? notes;
  final DateTime? birthday;
  final List<String> tags;

  /// Pesewas they may owe at most; null for no limit.
  final int? creditLimit;

  /// Days to pay a credit sale; null for no due date.
  final int? dueDays;
  final bool active;

  /// Pesewas they owe now, and the shop holds for them.
  final int owed;
  final int wallet;

  /// Pesewas they can still take on credit; null for no limit.
  int? get creditLeft => creditLimit == null ? null : creditLimit! - owed;
}

class CustomerDraft {
  const CustomerDraft({
    this.id,
    required this.name,
    this.phone,
    this.phone2,
    this.location,
    this.notes,
    this.birthday,
    this.tags = const [],
    this.creditLimit,
    this.dueDays,
  });

  final String? id;
  final String name;

  /// As typed; checked and stored as +233.
  final String? phone;
  final String? phone2;
  final String? location;
  final String? notes;
  final DateTime? birthday;
  final List<String> tags;
  final int? creditLimit;
  final int? dueDays;
}

/// One entry in a customer account.
class CustomerEntry {
  const CustomerEntry({
    required this.id,
    required this.at,
    required this.account,
    required this.kind,
    required this.amount,
    required this.byName,
    this.saleId,
    this.saleNumber,
    this.dueOn,
    this.methodName,
    this.reference,
    this.note,
    this.approverName,
  });

  final String id;
  final DateTime at;
  final CustomerAccount account;
  final CustomerEntryKind kind;

  /// Pesewas: on credit, + owed / − paid; on the wallet, + held / − used.
  final int amount;
  final String byName;
  final String? saleId;
  final int? saleNumber;
  final DateTime? dueOn;
  final String? methodName;
  final String? reference;
  final String? note;
  final String? approverName;
}

/// What is still owed on one credit sale, after repayments are applied
/// (chosen sales first, then the oldest).
class OpenDebt {
  const OpenDebt({
    required this.saleId,
    required this.saleNumber,
    required this.at,
    required this.amount,
    required this.outstanding,
    this.dueOn,
  });

  final String? saleId;
  final int? saleNumber;
  final DateTime at;

  /// Pesewas first owed, and still owed.
  final int amount;
  final int outstanding;
  final DateTime? dueOn;

  /// Days past the due date (0 when not due, or no due date).
  int daysOverdue(DateTime now) {
    final due = dueOn;
    if (due == null || !now.isAfter(due)) return 0;
    return now.difference(due).inDays;
  }
}

/// What is owed, by how late it is.
class CreditAging {
  const CreditAging({this.current = 0, this.days1to30 = 0, this.days31to60 = 0, this.over60 = 0});

  factory CreditAging.of(List<OpenDebt> debts, DateTime now) {
    var current = 0, a = 0, b = 0, c = 0;
    for (final d in debts) {
      final late = d.daysOverdue(now);
      if (late == 0) {
        current += d.outstanding;
      } else if (late <= 30) {
        a += d.outstanding;
      } else if (late <= 60) {
        b += d.outstanding;
      } else {
        c += d.outstanding;
      }
    }
    return CreditAging(current: current, days1to30: a, days31to60: b, over60: c);
  }

  final int current;
  final int days1to30;
  final int days31to60;
  final int over60;

  int get total => current + days1to30 + days31to60 + over60;
  int get overdue => days1to30 + days31to60 + over60;
}

/// Lifetime figures for the customer page.
class CustomerStats {
  const CustomerStats({
    this.spend = 0,
    this.visits = 0,
    this.lastVisit,
    this.favourites = const [],
  });

  /// Pesewas, completed sales less refunds.
  final int spend;
  final int visits;
  final DateTime? lastVisit;

  /// Product names, most bought first.
  final List<String> favourites;
}
