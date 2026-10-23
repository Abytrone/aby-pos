import 'package:get/get.dart';

import '../controllers/till_controller.dart';

class TillBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(TillController.new);
  }
}
