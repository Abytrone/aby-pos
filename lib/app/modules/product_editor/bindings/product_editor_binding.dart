import 'package:get/get.dart';

import '../controllers/product_editor_controller.dart';

class ProductEditorBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ProductEditorController.new);
  }
}
