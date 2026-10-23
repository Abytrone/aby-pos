import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../data/repositories/sale_repository.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../till/controllers/cart_controller.dart';

/// Takes payment for the cart and saves the sale. Amounts are pesewas.
class CheckoutController extends GetxController {
  final SaleRepository _sales = Get.find();
  final CartController cart = Get.find();
  final AuthService _auth = Get.find();

  final method = PaymentMethod.cash.obs;
  final saving = false.obs;
  final error = RxnString();
  final completed = Rxn<CompletedSale>();

  final tenderedField = TextEditingController();
  final momoField = TextEditingController();
  final customerField = TextEditingController();

  // Mirrors of the fields, so Obx can react to typing.
  final _tenderedText = ''.obs;
  final _momoText = ''.obs;
  final _customerText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    tenderedField.addListener(() => _tenderedText.value = tenderedField.text);
    momoField.addListener(() => _momoText.value = momoField.text);
    customerField.addListener(() => _customerText.value = customerField.text);
  }

  @override
  void onClose() {
    tenderedField.dispose();
    momoField.dispose();
    customerField.dispose();
    super.onClose();
  }

  int get total => cart.total;

  /// Null when the cash field does not hold a valid amount.
  int? get tendered => parseMoney(_tenderedText.value);

  int get changeDue => cart.changeDue(tendered ?? 0);

  bool get cashShort => (tendered ?? 0) < total;

  bool get canComplete {
    if (cart.isEmpty || saving.value) return false;
    return switch (method.value) {
      PaymentMethod.cash => tendered != null && !cashShort,
      PaymentMethod.momo => _momoText.value.trim().isNotEmpty,
      PaymentMethod.credit => _customerText.value.trim().isNotEmpty,
    };
  }

  /// The exact total, then the total rounded up to the next 5, 10, 20, 50...
  List<int> get quickCash {
    final options = <int>[total];
    for (final note in const [5, 10, 20, 50, 100, 200]) {
      final value = cedis(note);
      options.add(((total + value - 1) ~/ value) * value);
    }
    return options.toSet().take(4).toList();
  }

  void selectMethod(PaymentMethod value) {
    method.value = value;
    error.value = null;
  }

  void setTendered(int pesewas) {
    tenderedField.text =
        '${pesewas ~/ 100}.${(pesewas % 100).toString().padLeft(2, '0')}';
  }

  Future<void> complete() async {
    if (!canComplete) return;
    final payment = switch (method.value) {
      PaymentMethod.cash => PaymentInput.cash(tendered: tendered!),
      PaymentMethod.momo => PaymentInput.momo(momoReference: momoField.text),
      PaymentMethod.credit => PaymentInput.credit(customer: customerField.text),
    };
    saving.value = true;
    error.value = null;
    try {
      completed.value =
          await _sales.completeSale(
        lines: cart.lines.toList(),
        payment: payment,
        cashier: _auth.user,
      );
      cart.clear();
    } on SaleException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'Could not save the sale. Try again.';
    } finally {
      saving.value = false;
    }
  }

  /// Back to the till. Blocked while a sale is being saved.
  void close() {
    if (saving.value) return;
    Get.back<void>();
  }
}
