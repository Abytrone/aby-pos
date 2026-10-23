import 'package:get/get.dart';

import '../controllers/start_controller.dart';

class StartBinding extends Bindings {
  @override
  void dependencies() {
    // Not lazy: the view never reads the controller, and onReady must run.
    Get.put(StartController());
  }
}
