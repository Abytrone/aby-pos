import 'package:get/get.dart';

import '../../activity/controllers/activity_controller.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../products/controllers/catalogue_controller.dart';
import '../../settings/controllers/backup_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../staff/controllers/roles_controller.dart';
import '../../staff/controllers/staff_controller.dart';
import '../../stock/controllers/purchasing_controller.dart';
import '../../stock/controllers/stock_controller.dart';
import '../../till/controllers/till_controller.dart';
import '../../today/controllers/today_controller.dart';
import '../controllers/shell_controller.dart';

/// The shell and every section's controller. Section controllers are lazy:
/// each is created when its section is first opened.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShellController());
    Get.lazyPut(TillController.new, fenix: true);
    Get.lazyPut(TodayController.new, fenix: true);
    Get.lazyPut(CatalogueController.new, fenix: true);
    Get.lazyPut(StockController.new, fenix: true);
    Get.lazyPut(PurchasingController.new, fenix: true);
    Get.lazyPut(CustomersController.new, fenix: true);
    Get.lazyPut(StaffController.new, fenix: true);
    Get.lazyPut(RolesController.new, fenix: true);
    Get.lazyPut(ActivityController.new, fenix: true);
    Get.lazyPut(SettingsController.new, fenix: true);
    Get.lazyPut(BackupController.new, fenix: true);
  }
}
