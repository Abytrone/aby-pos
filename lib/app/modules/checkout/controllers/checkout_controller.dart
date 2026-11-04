import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart' show builtInPayMethods, payMethodRowId;
import '../../../data/repositories/voucher_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/pay_method_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../domain/settlement.dart';
import '../../../models/cart_line.dart';
import '../../../models/customer.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../models/staff.dart';
import '../../../models/order.dart';
import '../../../services/auth_service.dart';
import '../../../services/display/display_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/l10n.dart';
import '../../till/controllers/cart_controller.dart';
import '../../till/controllers/till_controller.dart';
import '../../../ui/dialogs.dart';

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

  /// Put cash change in the customer's wallet instead of handing it over.
  final keepChange = false.obs;

  final saving = false.obs;
  final error = RxnString();
  final completed = Rxn<CompletedSale>();

  final tenderedField = TextEditingController();
  final amountField = TextEditingController();
  final referenceField = TextEditingController();

  // Mirrors of the fields, so Obx can react to typing.
  final _tenderedText = ''.obs;
  final _amountText = ''.obs;
  final _referenceText = ''.obs;

  /// Old names, kept for the MoMo field.
  TextEditingController get momoField => referenceField;

  @override
  void onInit() {
    super.onInit();
    tenderedField.addListener(() => _tenderedText.value = tenderedField.text);
    amountField.addListener(() => _amountText.value = amountField.text);
    referenceField.addListener(() => _referenceText.value = referenceField.text);
    // A gift voucher's code: look it up as it is typed or scanned.
    debounce(_referenceText, (_) => _findVoucher(), time: const Duration(milliseconds: 250));
    ever(selected, (_) => _findVoucher());
    _loadMethods();
    _refreshCustomer();
    ever(selected, (_) => _toDisplay());
    _toDisplay();
  }

  /// The customer display shows what to pay, with the MoMo number and QR
  /// code for MoMo methods.
  void _toDisplay() {
    final m = selected.value;
    display?.paying(due: remaining > 0 ? remaining : total, payToName: m?.name, payToNumber: m?.merchantNumber);
  }

  DisplayService? get display => Get.isRegistered<DisplayService>() ? Get.find<DisplayService>() : null;

  /// The attached customer with today's balances.
  Future<void> _refreshCustomer() async {
    final c = cart.customer.value;
    if (c == null || !Get.isRegistered<CustomerRepository>()) return;
    final fresh = await Get.find<CustomerRepository>().find(c.id);
    if (fresh != null) cart.customer.value = fresh;
  }

  Customer? get customer => cart.customer.value;

  /// The gift voucher whose code is in the reference box, when paying by
  /// voucher; null while not found.
  final voucher = Rxn<GiftVoucher>();
  final voucherProblem = RxnString();

  Future<void> _findVoucher() async {
    voucher.value = null;
    voucherProblem.value = null;
    final code = _referenceText.value.trim();
    if (kind != PaymentMethod.voucher || code.isEmpty || !Get.isRegistered<VoucherRepository>()) return;
    final found = await Get.find<VoucherRepository>().find(code);
    if (_referenceText.value.trim() != code) return;
    final l = appL10n();
    if (found == null) {
      voucherProblem.value = l.voucherNotFound;
    } else if (found.expiredAt(DateTime.now())) {
      voucherProblem.value = l.voucherExpired;
    } else if (found.balance <= 0) {
      voucherProblem.value = l.voucherUsedUp;
    } else {
      voucher.value = found;
    }
  }

  /// Credit and wallet go on the customer's account.
  bool get needsCustomer => kind == PaymentMethod.credit || kind == PaymentMethod.wallet;

  @override
  void onClose() {
    if (completed.value == null) display?.cancelPaying();
    tenderedField.dispose();
    amountField.dispose();
    referenceField.dispose();
    super.onClose();
  }

  Future<void> _loadMethods() async {
    final list = Get.isRegistered<PayMethodRepository>()
        ? await Get.find<PayMethodRepository>().list()
        : [
            for (final (key, name, kind, on, reference) in builtInPayMethods)
              if (on)
                PayMethod(id: payMethodRowId(key), name: name, kind: kind, builtIn: key, needsReference: reference),
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

  /// The amount for a non-cash payment: what is typed, or the rest (no
  /// more than the wallet holds).
  int? get amount {
    if (_amountText.value.trim().isNotEmpty) return parseMoney(_amountText.value);
    if (kind == PaymentMethod.wallet) {
      final held = customer?.wallet ?? 0;
      return held < remaining ? held : remaining;
    }
    if (kind == PaymentMethod.voucher) {
      final held = voucher.value?.balance ?? 0;
      return held < remaining ? held : remaining;
    }
    return remaining;
  }

  bool get _detailsDone {
    final m = selected.value;
    if (m == null) return false;
    if (needsCustomer && customer == null) return false;
    if (m.kind == PaymentMethod.wallet && (amount ?? 0) > (customer?.wallet ?? 0)) return false;
    if (m.kind == PaymentMethod.voucher && (voucher.value == null || (amount ?? 0) > voucher.value!.balance))
      return false;
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
      customer: m.kind == PaymentMethod.credit ? customer?.name : null,
    );
  }

  /// Takes this payment towards the total; the rest is paid another way.
  void takePart() {
    if (!canTakePart) return;
    taken.add(_current(part: true));
    for (final f in [tenderedField, amountField, referenceField]) {
      f.clear();
    }
    error.value = null;
  }

  void removeTaken(int index) {
    if (index >= 0 && index < taken.length) taken.removeAt(index);
  }

  /// Pesewas this sale puts on the customer's credit account (the payment
  /// without an amount pays what remains).
  int _creditIn(List<PaymentInput> payments) =>
      payments.where((p) => p.method == PaymentMethod.credit).fold(0, (s, p) => s + (p.amount ?? remaining));

  Future<void> complete() async {
    if (!canComplete) return;
    final payments = [...taken, if (remaining > 0) _current(part: false)];
    final pending = cart.exchange.value;
    final l = appL10n();

    // Over the credit limit: blocked, or someone allowed to give credit
    // approves, by the shop's setting.
    Staff? creditApprover;
    final c = customer;
    final credit = _creditIn(payments);
    if (c != null && credit > 0 && c.creditLimit != null && c.owed + credit > c.creditLimit!) {
      final rule = Get.isRegistered<SettingsService>()
          ? Get.find<SettingsService>().get(AppSettings.creditOverLimit)
          : 'approve';
      if (rule == 'block') {
        error.value = l.checkoutOverLimit(c.name, formatMoney(c.creditLimit!));
        return;
      }
      final auth = await Get.find<PermissionService>().authorize(
        Permission.giveCredit,
        reason: l.checkoutOverLimitReason(c.name, formatMoney(c.owed + credit), formatMoney(c.creditLimit!)),
      );
      if (auth == null) return;
      creditApprover = auth.authority;
    }

    saving.value = true;
    error.value = null;
    // What the kitchen makes, kept before the cart clears.
    final orders = cart.orders;
    final prep = [
      for (final l in orders?.prepLines(cart.lines) ?? const <CartLine>[])
        OrderLine(
          title: l.title,
          quantity: l.quantity,
          sellBy: l.product.sellBy,
          options: [for (final o in l.options) o.name],
          note: l.note,
        ),
    ];
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
        customer: c,
        changeToWallet: keepChange.value && c != null,
        creditApprover: creditApprover,
        promotions: cart.promotions.toList(),
        loyalty: cart.loyalty,
        orders: orders,
        allowNegativeStock:
            Get.isRegistered<SettingsService>() && Get.find<SettingsService>().get(AppSettings.allowNegativeStock),
      );
      unawaited(printService?.afterSale(completed.value!.saleId, prep: prep));
      final done = completed.value!;
      display?.done(
        total: done.total + done.rounding,
        change: done.changeDue,
        order: done.orderNumber == null ? null : orders?.label(done.orderNumber!),
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
    goBack<void>();
  }
}
