import 'package:get/get.dart';
import '../../../core/period.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/profit_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../domain/accountant_pack.dart';
import '../../../domain/documents/report_docs.dart';
import '../../../models/expense.dart';
import '../../../models/report.dart';
import '../../../services/auth_service.dart';
import '../../../services/pdf_brand_loader.dart';
import '../../../services/settings_service.dart';
import '../../../ui/export_dialog.dart';
import '../../../ui/files.dart';

/// Manage → Reports: every report for a chosen period, with the previous
/// period beside it, exports (Excel, PDF, CSV) and the accountant's
/// month-end pack.
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
    staff.assignAll(await _reports.staff(r, commission: commission));
    customers.value = await _reports.customers(r);
    stockTax.value = await _reports.stockAndTax(r);
    loading.value = false;
  }

  String get _stamp => '${AccountantPack.day(range.value.from)}_${AccountantPack.day(range.value.lastDay)}';

  /// Everything on the screen, for exports.
  ReportFigures get figures => ReportFigures(
    shopName: Get.find<SettingsService>().get(AppSettings.shopName),
    range: range.value,
    sales: sales.value,
    before: before.value,
    hours: hours.toList(),
    products: products.toList(),
    payments: Map.of(payments),
    rounding: rounding.value,
    staff: staff.toList(),
    customers: customers.value,
    stockTax: stockTax.value,
    canSeeCost: canSeeCost,
    commission: commission.mode != CommissionMode.off,
  );

  /// The whole report: a workbook with a tab per table, or a PDF.
  Future<void> exportReport() => exportDocument(ReportDocs.full(figures), fileStem: 'report_$_stamp');

  Future<void> exportProducts() {
    final f = figures;
    return exportDocument(ReportDocs.productsDoc(f), fileStem: 'products_$_stamp', csv: ReportDocs.products(f).toCsv());
  }

  Future<void> exportSales() => exportDocument(ReportDocs.salesDoc(figures), fileStem: 'sales_by_day_$_stamp');

  /// The shop's commission rules (STF-07).
  CommissionConfig get commission {
    final s = Get.find<SettingsService>();
    return CommissionConfig(
      mode: CommissionMode.values.asNameMap()[s.get(AppSettings.commissionMode)] ?? CommissionMode.off,
      percent: s.get(AppSettings.commissionPercent),
    );
  }

  Future<void> exportStaff() => exportDocument(ReportDocs.staffDoc(figures), fileStem: 'staff_$_stamp');

  /// The month-end pack: CSVs, a workbook and a PDF summary in one zip.
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
      brand: await loadPdfBrand(),
    );
    await shareOrSaveBytes('aby_accounts_$_stamp.zip', zip);
  }
}
