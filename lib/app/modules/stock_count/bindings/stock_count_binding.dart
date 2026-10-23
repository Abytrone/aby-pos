import 'package:get/get.dart';

import '../controllers/stock_count_controller.dart';

class StockCountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(StockCountController.new);
  }
}
