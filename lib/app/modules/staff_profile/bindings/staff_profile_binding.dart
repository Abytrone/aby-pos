import 'package:get/get.dart';

import '../controllers/staff_profile_controller.dart';

class StaffProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(StaffProfileController.new);
  }
}
