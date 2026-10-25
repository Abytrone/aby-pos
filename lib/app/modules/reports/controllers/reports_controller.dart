import 'package:get/get.dart';

import '../../../core/csv.dart';
import '../../../core/period.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/profit_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../domain/accountant_pack.dart';
import '../../../models/expense.dart';
import '../../../models/report.dart';
import '../../../services/auth_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/files.dart';

/// Manage → Reports: every report for a chosen period, with the previous
/// period beside it, CSV exports and the accountant's month-end pack.
class ReportsController extends GetxController {
  final ReportRepository _reports = Get.find();
  final ProfitRepository _profit = Get.find();
  final AuthService _auth = Get.find();

  final period = ReportPeriod.thisMonth.obs;
  final range = DateRange.of(ReportPeriod.thisMonth, DateTime.now()).obs;
  final loading = true.obs;

  final sales = const SalesSummary().obs;
  final before = const SalesSummary().obs;
  final hours = <List<int>>[].obs;
  final products = <ProductFigures>[].obs;
  final options = <String, int>{}.obs;
  final slow = <(String, DateTime?)>[].obs;
  final payments = <String, int>{}.obs;
  final rounding = 0.obs;
  final staff = <StaffFigures>[].obs;
  final customers = const CustomerFigures().obs;
  final stockTax = const StockTaxFigures().obs;

  bool get canSeeCost => _auth.can(Permission.viewCostAndProfit);
  bool get canExport => _auth.can(Permission.exportData);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> setPeriod(ReportPeriod p, {DateTime? start, DateTime? end}) async {
    period.value = p;
    range.value = DateRange.of(p, DateTime.now(), start: start, end: end);
    await load();
  }

  Future<void> load() async {
    final r = range.value;
    sales.value = await _reports.sales(r);
    before.value = await _reports.sales(r.previous);
    hours.assignAll(await _reports.byHour(r));
    products.assignAll(await _reports.products(r));
    options.assignAll(await _reports.options(r));
    slow.assignAll(await _reports.slowMovers());
    final (byMethod, round) = await _reports.payments(r);
    payments.assignAll(byMethod);
    rounding.value = round;
    staff.assignAll(await _reports.staff(r));
    customers.value = await _reports.customers(r);
    stockTax.value = await _reports.stockAndTax(r);
    loading.value = false;
  }

  String get _stamp => '${AccountantPack.day(range.value.from)}_${AccountantPack.day(range.value.lastDay)}';
  String _m(int v) => AccountantPack.money(v);

  /// The products report as a spreadsheet.
  Future<void> exportProducts() => shareOrSaveText('products_$_stamp.csv', Csv.encode([
        ['product', 'category', 'sold', 'revenue', if (canSeeCost) ...['cost', 'profit', 'margin %'], 'grade'],
        for (final p in products)
          [
            p.name,
            p.category,
            '${p.quantity}',
            _m(p.revenue),
            if (canSeeCost) ...[_m(p.cost), _m(p.profit), p.marginPercent?.toString() ?? ''],
            p.grade,
          ],
      ]));

  Future<void> exportSales() => shareOrSaveText('sales_by_day_$_stamp.csv', Csv.encode([
        ['day', 'net sales'],
        for (final (d, v) in sales.value.series) [AccountantPack.day(d), _m(v)],
      ]));

  Future<void> exportStaff() => shareOrSaveText('staff_$_stamp.csv', Csv.encode([
        ['name', 'sales', 'total', 'average', 'discounts', 'voids', 'refunds', 'no-sales', 'times short', 'short by'],
        for (final s in staff)
          [s.name, '${s.sales}', _m(s.total), _m(s.average), _m(s.discounts), '${s.voids}', '${s.refunds}', '${s.noSales}', '${s.shorts}', _m(s.shortTotal)],
      ]));

  /// The month-end pack: CSVs and a PDF summary in one zip.
  Future<void> accountantPack() async {
    final r = range.value;
    ProfitAndLoss? pnl;
    if (canSeeCost) pnl = await _profit.forPeriod(r.from, r.to);
    final zip = await AccountantPack(Get.find<AppDatabase>()).build(
      shopName: Get.find<SettingsService>().get(AppSettings.shopName),
      range: r,
      summary: sales.value,
      pnl: pnl,
      stockTax: stockTax.value,
    );
    await shareOrSaveBytes('aby_accounts_$_stamp.zip', zip);
  }
}
