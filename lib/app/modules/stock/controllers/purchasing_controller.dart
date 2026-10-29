import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/purchase_order_repository.dart';
import '../../../data/repositories/receiving_repository.dart';
import '../../../data/repositories/stock_count_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../domain/purchase_order_pdf.dart';
import '../../../models/purchasing.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/files.dart';
import '../../../ui/l10n.dart';

/// The Stock section's other tabs: deliveries, counts and suppliers.
class PurchasingController extends GetxController {
  final ReceivingRepository _receiving = Get.find();
  final StockCountRepository _counts = Get.find();
  final SupplierRepository _suppliers = Get.find();
  final PurchaseOrderRepository _orders = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();

  final receipts = <StockReceipt>[].obs;
  final counts = <StockCount>[].obs;
  final openCount = Rxn<StockCount>();
  final suppliers = <Supplier>[].obs;
  final orders = <PurchaseOrder>[].obs;
  final message = RxnString();

  bool get canReceive => _auth.can(Permission.receiveStock);
  bool get canCount => _auth.can(Permission.adjustStock) || _auth.can(Permission.approveStockCount);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    receipts.assignAll(await _receiving.list());
    counts.assignAll(await _counts.list());
    openCount.value = await _counts.open();
    suppliers.assignAll(await _suppliers.list(includeInactive: true));
    orders.assignAll(await _orders.list());
  }

  // Purchase orders (INV-03)

  Future<List<(String, int)>> suggestionsFor(String supplierId) => _orders.suggestions(supplierId);

  /// Returns the new order, or null when refused or invalid ([message]).
  Future<PurchaseOrder?> createOrder(PurchaseOrderDraft d) async {
    final auth = await _permissions.authorize(Permission.receiveStock, reason: appL10n().poReason);
    if (auth == null) return null;
    try {
      final o = await _orders.create(d, by: auth.authority);
      await load();
      return o;
    } on StockException catch (e) {
      message.value = e.message;
      return null;
    }
  }

  Future<void> cancelOrder(PurchaseOrder o) async {
    final auth = await _permissions.authorize(Permission.receiveStock, reason: appL10n().poReason);
    if (auth == null) return;
    try {
      await _orders.cancel(o.id, by: auth.authority);
    } on StockException catch (e) {
      message.value = e.message;
    }
    await load();
  }

  Future<void> receiveOrder(PurchaseOrder o) async {
    await Get.toNamed<void>(Routes.receive, arguments: o.id);
    await load();
  }

  Future<void> shareOrder(PurchaseOrder o) async {
    final s = Get.find<SettingsService>();
    final bytes = await PurchaseOrderPdf.build(
      o,
      shopName: s.get(AppSettings.shopName),
      shopPhone: s.get(AppSettings.shopPhone),
      shopAddress: s.get(AppSettings.shopAddress),
    );
    await shareOrSaveBytes('${o.displayNumber}.pdf', bytes, text: appL10n().poShareText(o.displayNumber));
  }

  /// Pesewas owed to all suppliers.
  int get totalOwed => suppliers.fold(0, (s, x) => s + (x.balance > 0 ? x.balance : 0));

  Future<void> receive() async {
    await Get.toNamed<void>(Routes.receive);
    await load();
  }

  Future<List<(String, String, int)>> receiptLines(StockReceipt r) => _receiving.lines(r.id);

  Future<void> startOrContinueCount({required bool blind}) async {
    var count = openCount.value;
    if (count == null) {
      final auth = await _permissions.authorize(Permission.adjustStock, reason: appL10n().countStartReason);
      if (auth == null) return;
      try {
        final id = await _counts.start(blind: blind, by: auth.authority);
        count = await _counts.find(id);
      } on StockException catch (e) {
        message.value = e.message;
        return;
      }
    }
    await Get.toNamed<void>(Routes.stockCount, arguments: count!.id);
    await load();
  }

  Future<void> openCountPage(StockCount c) async {
    await Get.toNamed<void>(Routes.stockCount, arguments: c.id);
    await load();
  }

  Future<bool> saveSupplier(SupplierDraft d) async {
    final auth = await _permissions.authorize(Permission.receiveStock, reason: appL10n().supplierEditReason);
    if (auth == null) return false;
    try {
      await _suppliers.save(d, by: auth.authority);
      await load();
      return true;
    } on StockException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  Future<void> openSupplier(Supplier s) async {
    await Get.toNamed<void>(Routes.supplier, arguments: s.id);
    await load();
  }
}
