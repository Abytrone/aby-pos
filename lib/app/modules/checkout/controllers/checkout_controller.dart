import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../data/database/app_database.dart' show builtInPayMethods, payMethodRowId;
import '../../../data/repositories/pay_method_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../domain/settlement.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../ui/l10n.dart';
import '../../till/controllers/cart_controller.dart';
import '../../till/controllers/till_controller.dart';

/// Takes payment for the cart and saves the sale: one payment, or several
/// (split), with cash rounding and exchanges. Amounts are pesewas.
class CheckoutController extends GetxController {
  final SaleRepository _sales = Get.find();
  final CartController cart = Get.find();
  final AuthService _auth = Get.find();

  final methods = <PayMethod>[].obs;
  final selected = Rxn<PayMethod>();

  /// Payments already taken towards this sale (a split payment).
  final taken = <PaymentInput>[].obs;

  /// How the difference goes back when returned items are worth more.
  final payBack = Rxn<PayMethod>();

  final saving = false.obs;
  final error = RxnString();
  final completed = Rxn<CompletedSale>();

  final tenderedField = TextEditingController();
  final amountField = TextEditingController();
  final referenceField = TextEditingController();
  final customerField = TextEditingController();

  // Mirrors of the fields, so Obx can react to typing.
  final _tenderedText = ''.obs;
  final _amountText = ''.obs;
  final _referenceText = ''.obs;
  final _customerText = ''.obs;

  /// Old names, kept for the MoMo field.
  TextEditingController get momoField => referenceField;

  @override
  void onInit() {
    super.onInit();
    tenderedField.addListener(() => _tenderedText.value = tenderedField.text);
    amountField.addListener(() => _amountText.value = amountField.text);
    referenceField.addListener(() => _referenceText.value = referenceField.text);
    customerField.addListener(() => _customerText.value = customerField.text);
    _loadMethods();
  }

  @override
  void onClose() {
    tenderedField.dispose();
    amountField.dispose();
    referenceField.dispose();
    customerField.dispose();
    super.onClose();
  }

  Future<void> _loadMethods() async {
    final list = Get.isRegistered<PayMethodRepository>()
        ? await Get.find<PayMethodRepository>().list()
        : [
            for (final (key, name, kind, on, reference) in builtInPayMethods)
              if (on) PayMethod(id: payMethodRowId(key), name: name, kind: kind, builtIn: key, needsReference: reference),
          ];
    methods.assignAll(list);
    selected.value ??= list.firstWhereOrNull((m) => m.isCash) ?? list.firstOrNull;
    payBack.value ??= list.firstWhereOrNull((m) => m.isCash);
  }

  int get roundTo => Get.isRegistered<SettingsService>() ? Get.find<SettingsService>().get(AppSettings.cashRoundTo) : 0;

  int get total => cart.total;

  /// Value of the items coming back (an exchange), and the part of it this
  /// sale uses.
  int get credit => cart.exchange.value?.credit ?? 0;
  int get fromExchange => credit < total ? credit : total;

  /// Positive when the returned items are worth more than the new ones.
  int get owedBack => credit > total ? credit - total : 0;

  int get paidSoFar => taken.fold(0, (s, p) => s + (p.amount ?? 0));

  /// Still to pay before this payment.
  int get remaining => total - fromExchange - paidSoFar;

  PaymentMethod get kind => selected.value?.kind ?? PaymentMethod.cash;
  bool get isCash => kind == PaymentMethod.cash;

  /// Cash due for the rest, rounded when the shop rounds cash.
  int get cashDue {
    if (roundTo <= 0) return remaining;
    final rounded = Settlement.roundCash(remaining, roundTo);
    return rounded > 0 ? rounded : remaining;
  }

  int get rounding => cashDue - remaining;

  /// Null when the cash field does not hold a valid amount.
  int? get tendered => parseMoney(_tenderedText.value);

  int get changeDue => (tendered ?? 0) > cashDue ? tendered! - cashDue : 0;

  bool get cashShort => (tendered ?? 0) < cashDue;

  /// The amount for a non-cash payment: what is typed, or the rest.
  int? get amount => _amountText.value.trim().isEmpty ? remaining : parseMoney(_amountText.value);

  bool get _detailsDone {
    final m = selected.value;
    if (m == null) return false;
    if (m.kind == PaymentMethod.credit && _customerText.value.trim().isEmpty) return false;
    if (m.needsReference && _referenceText.value.trim().isEmpty) return false;
    return true;
  }

  /// This payment pays the rest, so the sale can be completed.
  bool get coversRest {
    if (remaining <= 0) return true;
    if (!_detailsDone) return false;
    return isCash ? tendered != null && !cashShort : amount == remaining;
  }

  /// This payment is part of the total: take it and pay the rest another way.
  bool get canTakePart {
    if (remaining <= 0 || !_detailsDone) return false;
    if (isCash) return (tendered ?? 0) > 0 && tendered! < cashDue;
    final a = amount;
    return a != null && a > 0 && a < remaining;
  }

  bool get canComplete => !cart.isEmpty && !saving.value && coversRest && (owedBack == 0 || payBack.value != null);

  /// The exact amount due, then that amount rounded up to the next 5, 10,
  /// 20, 50...
  List<int> get quickCash {
    final due = cashDue;
    final options = <int>[due];
    for (final note in const [5, 10, 20, 50, 100, 200]) {
      final value = cedis(note);
      options.add(((due + value - 1) ~/ value) * value);
    }
    return options.toSet().take(4).toList();
  }

  void select(PayMethod m) {
    selected.value = m;
    error.value = null;
  }

  /// The first of the shop's methods of [kind].
  void selectMethod(PaymentMethod kind) {
    final m = methods.firstWhereOrNull((x) => x.kind == kind);
    if (m != null) select(m);
  }

  void setTendered(int pesewas) => tenderedField.text = _plain(pesewas);

  static String _plain(int pesewas) => '${pesewas ~/ 100}.${(pesewas % 100).toString().padLeft(2, '0')}';

  PaymentInput _current({required bool part}) {
    final m = selected.value!;
    return PaymentInput.from(
      m,
      amount: part ? (isCash ? tendered : amount) : null,
      tendered: isCash ? tendered : null,
      reference: m.needsReference ? referenceField.text : null,
      customer: m.kind == PaymentMethod.credit ? customerField.text : null,
    );
  }

  /// Takes this payment towards the total; the rest is paid another way.
  void takePart() {
    if (!canTakePart) return;
    taken.add(_current(part: true));
    for (final f in [tenderedField, amountField, referenceField, customerField]) {
      f.clear();
    }
    error.value = null;
  }

  void removeTaken(int index) {
    if (index >= 0 && index < taken.length) taken.removeAt(index);
  }

  Future<void> complete() async {
    if (!canComplete) return;
    final payments = [...taken, if (remaining > 0) _current(part: false)];
    final pending = cart.exchange.value;
    saving.value = true;
    error.value = null;
    try {
      completed.value = await _sales.completeSale(
        lines: cart.lines.toList(),
        payments: payments,
        cashier: _auth.user,
        taxMode: cart.taxMode,
        orderDiscount: cart.orderDiscount.value,
        note: cart.note.value,
        orderType: cart.orderType.value,
        roundTo: roundTo,
        exchange: pending == null
            ? null
            : ExchangeInput(returned: pending.returned, payBack: payBack.value, approver: pending.approver),
      );
      cart.reset();
      taken.clear();
      if (Get.isRegistered<TillController>()) unawaited(Get.find<TillController>().refreshRecent());
    } on SaleException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = appL10n().checkoutSaveFailed;
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
