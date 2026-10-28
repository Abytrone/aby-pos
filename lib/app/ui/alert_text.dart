import '../services/alert_service.dart';
import '../services/money.dart';
import 'l10n.dart';

/// One line for an alert, on the dashboard and in notifications.
String alertText(AppLocalizations l, Alert a) => switch (a.kind) {
      AlertKind.lowStock => l.alertLowStock(a.count, a.names.join(', ')),
      AlertKind.creditOverdue => l.alertCredit(a.count, formatMoney(a.amount)),
      AlertKind.backup => l.alertBackup,
      AlertKind.dayNotClosed => l.alertDayOpen(a.count),
      AlertKind.parkedOld => l.closeParkedWarning(a.count),
      AlertKind.expenseDue => l.alertExpenses(a.names.join(', '), formatMoney(a.amount)),
    };
