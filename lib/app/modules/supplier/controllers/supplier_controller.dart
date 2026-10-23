import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/receiving_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// One supplier: what is owed, the ledger, deliveries, and payments.
class SupplierController extends GetxController {
  final SupplierRepository _suppliers = Get.find();
  final ReceivingRepository _receiving = Get.find();
  final PermissionService _permissions = Get.find();

  final String supplierId = Get.arguments as String;

  final supplier = Rxn<Supplier>();
  final ledger = <SupplierEntry>[].obs;
  final receipts = <StockReceipt>[].obs;
  final message = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    supplier.value = await _suppliers.find(supplierId);
    ledger.assignAll(await _suppliers.ledger(supplierId));
    receipts.assignAll(await _receiving.list(supplierId: supplierId, limit: 20));
  }

  /// Returns true when recorded.
  Future<bool> pay(String amount, SupplierPaymentMethod method, {String? reference}) async {
    final l = appL10n();
    final pesewas = parseMoney(amount);
    if (pesewas == null || pesewas <= 0) {
      message.value = l.receivePaidInvalid;
      return false;
    }
    final auth = await _permissions.authorize(Permission.payOut, reason: l.supplierPayReason(supplier.value!.name));
    if (auth == null) return false;
    try {
      await _suppliers.recordPayment(supplierId, amount: pesewas, method: method, reference: reference, by: auth.authority);
      message.value = l.supplierPaid(formatMoney(pesewas));
      await load();
      return true;
    } on StockException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  Future<bool> save(SupplierDraft d) async {
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

  Future<void> setActive(bool active) async {
    final auth = await _permissions.authorize(Permission.receiveStock, reason: appL10n().supplierEditReason);
    if (auth == null) return;
    await _suppliers.setActive(supplierId, active: active, by: auth.authority);
    await load();
  }
}
