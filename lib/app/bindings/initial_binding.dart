import 'package:get/get.dart';

import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/cash_event_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/day_close_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/profit_repository.dart';
import '../data/repositories/report_repository.dart';
import '../data/repositories/momo_repository.dart';
import '../data/repositories/safe_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/repositories/discount_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/outbox_repository.dart';
import '../data/repositories/parked_order_repository.dart';
import '../data/repositories/pay_method_repository.dart';
import '../data/repositories/promotion_repository.dart';
import '../data/repositories/receipt_repository.dart';
import '../data/repositories/role_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/staff_stats_repository.dart';
import '../data/repositories/receiving_repository.dart';
import '../data/repositories/refund_repository.dart';
import '../data/repositories/stock_count_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/supplier_repository.dart';
import '../data/repositories/voucher_repository.dart';
import '../domain/catalogue_io.dart';
import '../domain/catalogue_rules.dart';
import '../modules/till/controllers/cart_controller.dart';
import '../services/alert_service.dart';
import '../services/auth_service.dart';
import '../services/backup/backup_service.dart';
import '../services/device_service.dart';
import '../services/display/display_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../services/price_scheduler.dart';
import '../services/printing/print_service.dart';
import '../services/scale/scale_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/status_service.dart';
import '../services/staff_photo_service.dart';
import '../services/sync_service.dart';
import '../ui/approval_prompt.dart';

/// App-wide services: the composition root. Runs once per app start (and
/// again after a restore restarts the app).
class InitialBinding extends Bindings {
  InitialBinding({this.database});

  /// Tests pass an in-memory database; the app opens the on-device one.
  final AppDatabase? database;

  @override
  void dependencies() {
    final db = Get.put(database ?? AppDatabase(), permanent: true);
    final device = Get.put(DeviceService(db), permanent: true);

    final audit = Get.put(AuditRepository(db, device), permanent: true);
    Get.lazyPut(() => CatalogRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => CatalogueRules(Get.find()), fenix: true);
    Get.lazyPut(() => StockRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => SupplierRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => ReceivingRepository(db, device, audit, Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => StockCountRepository(db, device, audit, Get.find()), fenix: true);
    Get.lazyPut(() => CatalogueIo(Get.find(), Get.find(), audit), fenix: true);
    Get.lazyPut(() => CashEventRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => CustomerRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => ShiftRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => SafeRepository(db, device, audit, Get.find<CashEventRepository>()), fenix: true);
    Get.lazyPut(() => MomoRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => ExpenseRepository(db, device, audit, Get.find<CashEventRepository>()), fenix: true);
    Get.lazyPut(() => ProfitRepository(db, Get.find<ExpenseRepository>()), fenix: true);
    Get.lazyPut(() => ReportRepository(db, Get.find<StockRepository>(), Get.find<CustomerRepository>()), fenix: true);
    Get.lazyPut(() => DayCloseRepository(
          db,
          device,
          audit,
          Get.find<CashEventRepository>(),
          Get.find<CustomerRepository>(),
          Get.find<ShiftRepository>(),
        ), fenix: true);
    Get.lazyPut(() => RefundRepository(db, device, audit, Get.find(), Get.find<CustomerRepository>()), fenix: true);
    Get.lazyPut(() => PayMethodRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => VoucherRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => OrderRepository(db), fenix: true);
    Get.lazyPut(
      () => SaleRepository(
        db,
        Get.find(),
        Get.find(),
        audit,
        device,
        Get.find<RefundRepository>(),
        Get.find<CustomerRepository>(),
        Get.find<VoucherRepository>(),
      ),
      fenix: true,
    );
    Get.lazyPut(() => DiscountRepository(db, device, audit), fenix: true);
    Get.lazyPut(() => PromotionRepository(db, device, audit), fenix: true);
    // The cart saves itself through this, so it is ready before the cart.
    Get.put(ParkedOrderRepository(db, device, audit), permanent: true);
    Get.lazyPut(() => RoleRepository(db, device, audit), fenix: true);
    final staff = Get.put(StaffRepository(db, device, audit), permanent: true);
    Get.lazyPut(() => StaffStatsRepository(db), fenix: true);
    Get.put(StaffPhotoService(staff), permanent: true);
    Get.lazyPut(() => OutboxRepository(db), fenix: true);

    final settings = Get.put(SettingsService(SettingsRepository(db, device, audit)), permanent: true);
    final auth = Get.put(AuthService(Get.find(), audit), permanent: true);
    Get.put(PermissionService(auth), permanent: true).prompter = showApprovalPrompt;
    Get.put(SessionService(auth, settings), permanent: true);
    final sync = Get.put(SyncService(Get.find()), permanent: true);
    final backups = Get.put(BackupService(db, audit, settings), permanent: true);
    Get.put(PriceScheduler(Get.find()), permanent: true);
    Get.put(PrintService(settings, ReceiptRepository(db), device), permanent: true);
    Get.put(StatusService(backups, audit, settings, sync), permanent: true);
    final alerts = Get.put(AlertService(db), permanent: true);
    Get.put(NotificationService(db, settings, alerts), permanent: true);
    Get.put(ScaleService(settings), permanent: true);

    // Shared by the till and checkout.
    final cart = Get.put(CartController(), permanent: true);
    Get.put(DisplayService(db, settings), permanent: true).promotions = () {
      final now = DateTime.now();
      return [for (final p in cart.promotions) if (p.runsAt(now)) p.name];
    };
  }
}
