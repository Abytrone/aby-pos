import 'dart:async';

import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../models/enums.dart';
import '../../../models/order.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';

/// Sell → Orders: open orders with queue numbers, moved New → Preparing →
/// Ready → Collected (SEL-11).
class OrdersController extends GetxController {
  final OrderRepository _orders = Get.find();
  final SettingsService _settings = Get.find();

  final orders = <OpenOrder>[].obs;
  StreamSubscription<List<OpenOrder>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _orders.watchOpen().listen(orders.assignAll);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  String label(OpenOrder o) => '${_settings.get(AppSettings.orderPrefix)}${o.number}';

  List<OpenOrder> withStatus(OrderStatus s) => [for (final o in orders) if (o.status == s) o];

  /// The next step: New → Preparing → Ready → Collected.
  static OrderStatus next(OrderStatus s) => switch (s) {
        OrderStatus.fresh => OrderStatus.preparing,
        OrderStatus.preparing => OrderStatus.ready,
        OrderStatus.ready || OrderStatus.collected => OrderStatus.collected,
      };

  static OrderStatus back(OrderStatus s) => switch (s) {
        OrderStatus.fresh || OrderStatus.preparing => OrderStatus.fresh,
        OrderStatus.ready => OrderStatus.preparing,
        OrderStatus.collected => OrderStatus.ready,
      };

  Future<void> move(OpenOrder o, OrderStatus to) => _orders.setStatus(o.saleId, to);

  void printTicket(OpenOrder o) {
    final ok = printService?.printKitchenTicket(o.number, o.at, o.lines,
            note: o.note, orderType: o.orderType, customerName: o.customerName) ??
        false;
    final l = appL10n();
    showMessage(ok ? l.printSent : l.printNoPrinter);
  }
}
