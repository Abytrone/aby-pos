import 'package:get/get.dart';

import '../data/database/app_database.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/day_close_repository.dart';
import '../data/repositories/outbox_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../modules/till/controllers/cart_controller.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/sync_service.dart';

/// App-wide services. Runs once, before the first route.
class InitialBinding extends Bindings {
  InitialBinding({this.database});

  /// Tests pass an in-memory database; the app opens the on-device one.
  final AppDatabase? database;

  @override
  void dependencies() {
    final db = Get.put(database ?? AppDatabase(), permanent: true);
    final device = Get.put(DeviceService(db), permanent: true);

    Get.lazyPut(() => CatalogRepository(db), fenix: true);
    Get.lazyPut(() => StockRepository(db, device), fenix: true);
    Get.lazyPut(() => DayCloseRepository(db, device), fenix: true);
    Get.lazyPut(() => SaleRepository(db, Get.find(), Get.find(), device), fenix: true);
    Get.lazyPut(() => StaffRepository(db, device), fenix: true);
    Get.lazyPut(() => OutboxRepository(db), fenix: true);

    Get.put(AuthService(Get.find()), permanent: true);
    Get.put(SyncService(Get.find()), permanent: true);

    // Shared by the till and checkout.
    Get.put(CartController(), permanent: true);
  }
}
