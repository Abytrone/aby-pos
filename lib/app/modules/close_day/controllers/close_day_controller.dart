import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/denominations.dart';
import '../../../core/permissions.dart';
import '../../../core/period.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/day_close_repository.dart';
import '../../../data/repositories/parked_order_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../models/day_close.dart';
import '../../../models/report.dart';
import '../../../services/alert_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/alert_text.dart';
import '../../../ui/l10n.dart';
import '../widgets/daily_summary.dart';

/// Cash-up (the Z report): compare the counted drawer with what the till
/// expects, then close the shift so its sales are locked. With a blind
/// count the expected amount shows only after the count is in.
class CloseDayController extends GetxController {
  final DayCloseRepository _closes = Get.find();
  final AuthService _auth = Get.find();
  final SettingsService _settings = Get.find();

  /// Who opened this screen (and who approved it), from TodayController.
  final Authorization? _authorization = Get.arguments as Authorization?;

  final period = Rxn<OpenPeriod>();
  final history = <DayClose>[].obs;
  final variance = <String, (int, int, int)>{}.obs;
  final saving = false.obs;
  final error = RxnString();
  final closed = Rxn<DayClose>();

  /// The owner's summary of the day just closed (NTF-02).
  final summary = Rxn<DailySummary>();

  final floatField = TextEditingController();
  final countedField = TextEditingController();
  final noteField = TextEditingController();
  final reasonField = TextEditingController();

  /// The notes and coins, when counted that way.
  final cashCount = Rxn<CashCount>();

  /// Blind count: the expected amount is shown once the count is checked.
  final revealed = false.obs;

  final _floatText = ''.obs;
  final _countedText = ''.obs;
  final _reasonText = ''.obs;

  /// Parked orders older than the warning time (they may be unpaid sales).
  final oldParked = 0.obs;

  bool get blind => _settings.get(AppSettings.blindCount);
  int get varianceLimit => _settings.get(AppSettings.varianceLimit);
  bool get canSeeVariance => _auth.can(Permission.viewReports);

  @override
  void onInit() {
    super.onInit();
    floatField.addListener(() => _floatText.value = floatField.text);
    countedField.addListener(() => _countedText.value = countedField.text);
    reasonField.addListener(() => _reasonText.value = reasonField.text);
    load();
  }

  @override
  void onClose() {
    for (final f in [floatField, countedField, noteField, reasonField]) {
      f.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    final open = await _closes.openPeriod();
    period.value = open;
    history.assignAll(await _closes.history());
    if (canSeeVariance) variance.assignAll(await _closes.varianceByPerson());
    if (open.shiftFloat == null && floatField.text.isEmpty && open.suggestedFloat > 0) {
      floatField.text = _plain(open.suggestedFloat);
    }
    final hours = _settings.get(AppSettings.parkedWarnHours);
    oldParked.value = await Get.find<ParkedOrderRepository>().olderThan(Duration(hours: hours));
  }

  /// From the open shift; otherwise typed (blank counts as zero).
  int? get openingFloat {
    final shift = period.value?.shiftFloat;
    if (shift != null) return shift;
    return _floatText.value.trim().isEmpty ? 0 : parseMoney(_floatText.value);
  }

  int? get counted => parseMoney(_countedText.value);

  void useCount(CashCount count) {
    cashCount.value = count;
    countedField.text = _plain(count.total);
  }

  bool get showExpected => !blind || revealed.value;

  int? get expected {
    final p = period.value;
    final float = openingFloat;
    return p == null || float == null ? null : p.expectedCash(float);
  }

  /// Positive when over, negative when short; null until both are entered.
  int? get difference {
    final e = expected;
    final c = counted;
    return e == null || c == null ? null : c - e;
  }

  /// Over or short by more than the shop allows: a reason is needed.
  bool get needsReason => (difference?.abs() ?? 0) > varianceLimit;

  /// Blind count: shows the expected amount; the count is then fixed.
  void reveal() {
    if (counted != null) revealed.value = true;
  }

  bool get canClose =>
      !saving.value &&
      period.value != null &&
      openingFloat != null &&
      counted != null &&
      showExpected &&
      (!needsReason || _reasonText.value.trim().isNotEmpty);

  Future<void> closeDay() async {
    if (!canClose) return;
    saving.value = true;
    error.value = null;
    try {
      closed.value = await _closes.closeDay(
        openingFloat: openingFloat!,
        countedCash: counted!,
        closedBy: _authorization?.authority ?? _auth.user,
        note: noteField.text,
        cashCount: cashCount.value,
        varianceReason: needsReason ? reasonField.text : null,
      );
      history.assignAll(await _closes.history());
      summary.value = await _summary(closed.value!);
    } catch (_) {
      error.value = appL10n().closeFailed;
    } finally {
      saving.value = false;
    }
  }

  void done() => Get.back<void>();

  /// Sales, gross profit when costs are known, the cash difference, the top
  /// product and what needs attention.
  Future<DailySummary> _summary(DayClose z) async {
    final range = DateRange(z.periodStart ?? DateTime(2000), z.closedAt.add(const Duration(seconds: 1)));
    var top = <ProductFigures>[];
    if (Get.isRegistered<ReportRepository>()) top = await Get.find<ReportRepository>().products(range);
    final costed = top.where((p) => p.cost > 0).toList();
    final alerts = Get.isRegistered<AlertService>() ? await Get.find<AlertService>().current() : const <Alert>[];
    final l = appL10n();
    return DailySummary(
      shopName: _settings.get(AppSettings.shopName),
      closedAt: z.closedAt,
      closedBy: z.closedByName,
      sales: z.salesTotal,
      count: z.salesCount,
      cashDifference: z.difference,
      profit: costed.isEmpty ? null : costed.fold<int>(0, (s, p) => s + p.revenue - p.cost),
      topProduct: top.firstOrNull?.name,
      alerts: [for (final a in alerts.where((a) => a.kind != AlertKind.dayNotClosed).take(3)) alertText(l, a)],
    );
  }

  static String _plain(int pesewas) => '${pesewas ~/ 100}.${(pesewas % 100).toString().padLeft(2, '0')}';
}
