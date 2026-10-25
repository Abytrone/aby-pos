import 'package:get/get.dart';

import '../controllers/momo_controller.dart';
import '../controllers/safe_controller.dart';

class SafeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(SafeController.new);
  }
}

class MomoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(MomoController.new);
  }
}
