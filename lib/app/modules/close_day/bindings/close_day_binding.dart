import 'package:get/get.dart';

import '../controllers/close_day_controller.dart';

class CloseDayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(CloseDayController.new);
  }
}
