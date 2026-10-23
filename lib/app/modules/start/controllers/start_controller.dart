import 'package:get/get.dart';

import '../../../data/repositories/staff_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/device_service.dart';

/// Opens the database, then goes to setup (no staff yet) or sign-in.
class StartController extends GetxController {
  final DeviceService _device = Get.find();
  final StaffRepository _staff = Get.find();

  @override
  void onReady() {
    super.onReady();
    _route();
  }

  Future<void> _route() async {
    await _device.ready;
    final hasStaff = await _staff.hasStaff();
    await Get.offAllNamed<void>(hasStaff ? Routes.signIn : Routes.setup);
  }
}
