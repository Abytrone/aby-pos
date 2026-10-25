import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

import '../../../core/business_day.dart';
import '../../../core/period.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/day_close_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../models/day_close.dart';
import '../../../models/report.dart';
import '../../../services/alert_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_service.dart';

enum DashboardCard { sales, payments, hours, topProducts, shift, alerts }

/// The owner's first screen of Manage: today against the same day last
/// week, takings, the hours, top products, the drawer and alerts. Cards can
/// be reordered or hidden, per person.
class DashboardController extends GetxController {
  final ReportRepository _reports = Get.find();
  final DayCloseRepository _closes = Get.find();
  final AppDatabase _db = Get.find();
  final AuthService _auth = Get.find();
  final SettingsService _settings = Get.find();

  final loading = true.obs;
  final today = const SalesSummary().obs;
  final lastWeek = const SalesSummary().obs;
  final payments = <String, int>{}.obs;
  final top = <ProductFigures>[].obs;
  final hours = <int>[].obs;
  final period = Rxn<OpenPeriod>();
  final alerts = <Alert>[].obs;

  /// Shown cards, in order.
  final cards = <DashboardCard>[...DashboardCard.values].obs;

  StreamSubscription<void>? _changes;
  Timer? _debounce;

  String get _layoutKey => 'dashboard:${_auth.currentUser.value?.id ?? ''}';

  @override
  void onInit() {
    super.onInit();
    _loadLayout();
    load();
    _changes = _db
        .tableUpdates(TableUpdateQuery.onAllTables([_db.sales, _db.refunds, _db.cashEvents, _db.stockMovements]))
        .listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(seconds: 1), load);
    });
  }

  @override
  void onClose() {
    _changes?.cancel();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    final now = DateTime.now();
    final day = BusinessDay.containing(now, startMinutes: _settings.get(AppSettings.businessDayStart));
    final r = DateRange(day.start, day.end);
    final week = DateRange(day.start.subtract(const Duration(days: 7)), day.end.subtract(const Duration(days: 7)));
    today.value = await _reports.sales(r);
    lastWeek.value = await _reports.sales(week);
    payments.assignAll((await _reports.payments(r)).$1);
    top.assignAll((await _reports.products(r)).take(5));
    final grid = await _reports.byHour(r);
    hours.assignAll([for (var h = 0; h < 24; h++) grid.fold(0, (s, row) => s + row[h])]);
    period.value = await _closes.openPeriod();
    alerts.assignAll(await Get.find<AlertService>().current(now: now));
    loading.value = false;
  }

  Future<void> _loadLayout() async {
    final saved = await _db.readMeta(_layoutKey);
    if (saved == null) return;
    final names = (jsonDecode(saved) as List).cast<String>();
    final byName = DashboardCard.values.asNameMap();
    cards.assignAll([for (final n in names) ?byName[n]]);
  }

  /// Saves the order and which cards are shown, for this person.
  Future<void> setLayout(List<DashboardCard> shown) async {
    cards.assignAll(shown);
    await _db.writeMeta(_layoutKey, jsonEncode([for (final c in shown) c.name]));
  }
}
