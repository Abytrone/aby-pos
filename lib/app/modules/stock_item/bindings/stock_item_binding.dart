import 'package:get/get.dart';

import '../controllers/stock_item_controller.dart';

class StockItemBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(StockItemController.new);
  }
}
