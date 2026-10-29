import 'package:get/get.dart';

import '../modules/shell/controllers/shell_controller.dart';
import '../services/insight_service.dart';
import '../services/money.dart';
import 'l10n.dart';

String _weekday(AppLocalizations l, int d) =>
    [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun][(d - 1).clamp(0, 6)];

/// One sentence for an insight (REP-08).
String insightText(AppLocalizations l, Insight i) => switch (i.kind) {
      InsightKind.runningOut => l.insightRunningOut(i.names.first, i.numbers.first),
      InsightKind.busyDay => l.insightBusyDay(_weekday(l, i.numbers[0]), i.numbers[1]),
      InsightKind.marginDrop => l.insightMarginDrop(i.names.first, i.numbers[0], i.numbers[1]),
      InsightKind.lateCredit => l.insightLateCredit(i.numbers[0], formatMoney(i.numbers[1])),
      InsightKind.cashShort => l.insightCashShort(i.numbers[0], formatMoney(i.numbers[1])),
    };

String insightActionLabel(AppLocalizations l, Insight i) => switch (i.kind) {
      InsightKind.runningOut => l.insightOrderMore,
      InsightKind.busyDay => l.insightSeeTimes,
      InsightKind.marginDrop => l.insightReviewPrice,
      InsightKind.lateCredit => l.insightSendReminders,
      InsightKind.cashShort => l.insightSeeStaff,
    };

/// The one action: the section where it is dealt with.
void insightAction(Insight i) {
  if (!Get.isRegistered<ShellController>()) return;
  Get.find<ShellController>().select(switch (i.kind) {
    InsightKind.runningOut => ShellSection.stock,
    InsightKind.busyDay || InsightKind.cashShort => ShellSection.reports,
    InsightKind.marginDrop => ShellSection.products,
    InsightKind.lateCredit => ShellSection.customers,
  });
}
