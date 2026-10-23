import 'dart:async';

import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/day_close_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../models/sale.dart';
import '../../../routes/app_routes.dart';
import '../../../services/device_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/l10n.dart';

/// The current business day's takings and sales, with voiding.
class TodayController extends GetxController {
  final SaleRepository _sales = Get.find();
  final DayCloseRepository _closes = Get.find();
  final PermissionService _permissions = Get.find();
  final SettingsService _settings = Get.find();
  final DeviceInfo _device = Get.find<DeviceService>();

  final sales = <Sale>[].obs;
  final summary = const TodaySummary().obs;
  final loading = true.obs;

  /// Sales on this device up to this number are in a closed day.
  final closedUpTo = 0.obs;

  StreamSubscription<List<Sale>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _loadLock();
    _sub = _sales
        .watchToday(dayStartMinutes: _settings.get(AppSettings.businessDayStart))
        .listen((list) {
      sales.assignAll(list);
      summary.value = TodaySummary.fromSales(list);
      loading.value = false;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _loadLock() async => closedUpTo.value = await _closes.closedUpTo();

  // TODO(sync): sales from other tills will show here; their own closes
  // lock them, which this device does not know about yet.
  bool isLocked(Sale sale) =>
      sale.deviceId == _device.deviceId && sale.number <= closedUpTo.value;

  /// Voids a sale after the view has asked for confirmation. Someone allowed
  /// to void must approve when the signed-in person cannot. Returns the
  /// message to show, or null if cancelled.
  Future<String?> voidSale(Sale sale) async {
    final l = appL10n();
    final auth = await _permissions.authorize(
      Permission.voidSale,
      reason: l.voidApprovalReason(sale.displayNumber),
    );
    if (auth == null) return null;
    try {
      await _sales.voidSale(sale.id, actor: auth.actor, approver: auth.approver);
      return l.voidDone(sale.displayNumber);
    } on SaleException catch (e) {
      return e.message;
    }
  }

  Future<void> openCloseDay() async {
    final auth = await _permissions.authorize(
      Permission.closeDay,
      reason: appL10n().closeDayApprovalReason,
    );
    if (auth == null) return;
    await Get.toNamed<void>(Routes.closeDay, arguments: auth);
    await _loadLock();
  }
}
