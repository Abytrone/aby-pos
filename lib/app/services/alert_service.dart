import 'package:drift/drift.dart';
import 'package:get/get.dart';

import '../core/business_day.dart';
import '../core/settings.dart';
import '../data/database/app_database.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/parked_order_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../models/customer.dart';
import 'settings_service.dart';
import 'status_service.dart';

enum AlertKind { lowStock, creditOverdue, backup, dayNotClosed, parkedOld, expenseDue }

/// Something the owner should do something about.
class Alert {
  const Alert(this.kind, {this.count = 0, this.amount = 0, this.names = const []});

  final AlertKind kind;
  final int count;

  /// Pesewas, where it applies.
  final int amount;

  /// A few of the things it is about (stock items, customers).
  final List<String> names;
}

/// Works out the alerts on this device, with no internet: low stock, credit
/// overdue, backups, a day left open, old parked orders, expenses due.
// TODO(notify): show these as phone / Windows notifications too (NTF-01).
class AlertService extends GetxService {
  AlertService(this._db);

  final AppDatabase _db;

  Future<List<Alert>> current({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final settings = Get.find<SettingsService>();
    final alerts = <Alert>[];

    final low = (await Get.find<StockRepository>().items()).where((i) => i.isLow).toList();
    if (low.isNotEmpty) alerts.add(Alert(AlertKind.lowStock, count: low.length, names: [for (final i in low.take(3)) i.name]));

    final customers = Get.find<CustomerRepository>();
    var late = 0;
    final lateNames = <String>[];
    for (final c in (await customers.list()).where((c) => c.owed > 0)) {
      final overdue = CreditAging.of(await customers.openDebts(c.id), at).overdue;
      if (overdue > 0) {
        late += overdue;
        lateNames.add(c.name);
      }
    }
    if (late > 0) alerts.add(Alert(AlertKind.creditOverdue, count: lateNames.length, amount: late, names: lateNames.take(3).toList()));

    if (Get.isRegistered<StatusService>()) {
      final backup = Get.find<StatusService>()
          .checks
          .where((c) => (c.item == StatusItem.localBackup || c.item == StatusItem.offsiteBackup) && c.level.index >= StatusLevel.warning.index);
      if (backup.isNotEmpty) alerts.add(const Alert(AlertKind.backup));
    }

    // Sales from before today's business day that no close covers.
    final today = BusinessDay.containing(at, startMinutes: settings.get(AppSettings.businessDayStart));
    final open = await _db.customSelect(
      'SELECT COUNT(*) AS n FROM sales s WHERE s.deleted_at IS NULL AND s.created_at < ? AND s.number > '
      '(SELECT COALESCE(MAX(last_sale_number), 0) FROM day_closes d WHERE d.device_id = s.device_id AND d.deleted_at IS NULL)',
      variables: [Variable.withDateTime(today.start)],
      readsFrom: {_db.sales, _db.dayCloses},
    ).getSingle();
    if (open.read<int>('n') > 0) alerts.add(Alert(AlertKind.dayNotClosed, count: open.read<int>('n')));

    final parked = await Get.find<ParkedOrderRepository>().olderThan(Duration(hours: settings.get(AppSettings.parkedWarnHours)));
    if (parked > 0) alerts.add(Alert(AlertKind.parkedOld, count: parked));

    final due = await Get.find<ExpenseRepository>().due(now: at);
    if (due.isNotEmpty) {
      alerts.add(Alert(AlertKind.expenseDue, count: due.length, amount: due.fold(0, (s, r) => s + r.amount), names: [for (final r in due) r.name]));
    }
    return alerts;
  }
}
