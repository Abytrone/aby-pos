import 'dart:async';

import 'package:get/get.dart';

import '../../../data/repositories/day_close_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../models/sale.dart';
import '../../../models/staff.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';

/// Today's takings and sales, with voiding.
class TodayController extends GetxController {
  final SaleRepository _sales = Get.find();
  final DayCloseRepository _closes = Get.find();
  final AuthService _auth = Get.find();
  final DeviceInfo _device = Get.find<DeviceService>();

  final sales = <Sale>[].obs;
  final summary = const TodaySummary().obs;
  final loading = true.obs;
  final message = RxnString();

  /// Sales on this device up to this number are in a closed day.
  final closedUpTo = 0.obs;

  StreamSubscription<List<Sale>>? _sub;

  bool get isOwner => _auth.isOwner;

  @override
  void onInit() {
    super.onInit();
    _loadLock();
    _sub = _sales.watchToday().listen((list) {
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

  bool canVoid(Sale sale) => !sale.isVoided && !isLocked(sale);

  /// A cashier needs an owner to approve a void.
  bool get needsApproval => !_auth.isOwner;

  Future<Staff?> approveAsOwner(String pin) => _auth.approveAsOwner(pin);

  /// Voids a sale (after the view has asked for confirmation and, for a
  /// cashier, an owner's PIN). Records the owner who approved it.
  Future<void> voidSale(Sale sale, {Staff? approvedBy}) async {
    final by = approvedBy ?? _auth.user;
    if (!by.isOwner) {
      message.value = 'Only an owner can void a sale.';
      return;
    }
    try {
      await _sales.voidSale(sale.id, by: by);
      message.value = 'Sale ${sale.displayNumber} voided.';
    } on SaleException catch (e) {
      message.value = e.message;
    }
  }

  Future<void> openCloseDay() async {
    await Get.toNamed<void>(Routes.closeDay);
    await _loadLock();
  }

  void openStaff() => Get.toNamed<void>(Routes.staff);
}
