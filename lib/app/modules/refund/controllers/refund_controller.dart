import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/discount_repository.dart';
import '../../../data/repositories/pay_method_repository.dart';
import '../../../data/repositories/refund_repository.dart';
import '../../../models/catalog.dart';
import '../../../models/discount.dart';
import '../../../models/enums.dart';
import '../../../models/refund.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';
import '../../shell/controllers/shell_controller.dart';
import '../../till/controllers/cart_controller.dart';

/// An item typed in for a refund without a receipt.
class ManualRefundLine {
  ManualRefundLine({required this.product, required this.variant})
      : amount = TextEditingController(text: (variant.price / 100).toStringAsFixed(2));

  final Product product;
  final Variant variant;
  int quantity = 1;
  bool restock = true;

  /// What goes back for all of them (GH₵).
  final TextEditingController amount;

  String get title => variant.name == null ? product.name : '${product.name}, ${variant.name}';
}

/// Give back some or all of a sale (or, with a PIN, items without a
/// receipt), as a refund or towards an exchange. Argument: the sale ID, or
/// nothing for a refund without a receipt.
class RefundController extends GetxController {
  final RefundRepository _refunds = Get.find();
  final PayMethodRepository _methods = Get.find();
  final DiscountRepository _reasons = Get.find();
  final CatalogRepository _catalog = Get.find();
  final PermissionService _permissions = Get.find();

  final String? saleId = Get.arguments as String?;

  bool get withoutReceipt => saleId == null;

  final loading = true.obs;
  final saving = false.obs;
  final error = RxnString();
  final done = Rxn<CompletedRefund>();

  final sale = Rxn<RefundableSale>();
  final quantities = <String, int>{}.obs;
  final restock = <String, bool>{}.obs;
  final manual = <ManualRefundLine>[].obs;
  final products = <Product>[].obs;

  final reasons = <Reason>[].obs;
  final reason = RxnString();
  final note = TextEditingController();

  final methods = <PayMethod>[].obs;
  final method = Rxn<PayMethod>();
  final reference = TextEditingController();

  /// Bumps when a manual amount is typed, so totals recompute.
  final _typed = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    note.dispose();
    reference.dispose();
    for (final m in manual) {
      m.amount.dispose();
    }
    super.onClose();
  }

  Future<void> _load() async {
    reasons.assignAll(await _reasons.reasons(ReasonKind.refund));
    methods.assignAll((await _methods.list()).where((m) => m.kind != PaymentMethod.credit));
    if (saleId != null) {
      final s = await _refunds.refundable(saleId!);
      sale.value = s;
      // Back the way it was paid, when that method is still on.
      final main = s?.payments.where((p) => p.method != PaymentMethod.exchange).firstOrNull;
      method.value = methods.firstWhereOrNull((m) => m.name == main?.methodName) ??
          methods.firstWhereOrNull((m) => m.kind == main?.method) ??
          methods.firstWhereOrNull((m) => m.isCash);
    } else {
      products.assignAll((await _catalog.load()).products);
      method.value = methods.firstWhereOrNull((m) => m.isCash);
    }
    loading.value = false;
  }

  void setQuantity(RefundableLine line, int quantity) {
    final q = quantity.clamp(0, line.left);
    quantities[line.saleLineId] = line.weighed && q > 0 ? line.left : q;
  }

  int quantityOf(RefundableLine line) => quantities[line.saleLineId] ?? 0;
  bool restockOf(String key) => restock[key] ?? true;
  void setRestock(String key, bool value) => restock[key] = value;

  /// Everything still on the sale.
  void all() {
    for (final l in sale.value?.lines ?? const <RefundableLine>[]) {
      quantities[l.saleLineId] = l.left;
    }
  }

  void addManual(Product p) {
    manual.add(ManualRefundLine(product: p, variant: p.variants.first)..amount.addListener(() => _typed.value++));
  }

  void removeManual(ManualRefundLine line) {
    manual.remove(line);
    line.amount.dispose();
  }

  void changeManualQuantity(ManualRefundLine line, int by) {
    line.quantity = (line.quantity + by).clamp(1, 999);
    final each = line.variant.price;
    line.amount.text = (each * line.quantity / 100).toStringAsFixed(2);
    manual.refresh();
  }

  int get total {
    _typed.value;
    final s = sale.value;
    if (s != null) {
      return s.lines.fold(0, (sum, l) => sum + l.amountFor(quantities[l.saleLineId] ?? 0));
    }
    return manual.fold(0, (sum, m) => sum + (parseMoney(m.amount.text) ?? 0));
  }

  RefundDraft get _draft => RefundDraft(
        saleId: saleId,
        reason: reason.value ?? '',
        note: note.text,
        lines: sale.value != null
            ? [
                for (final l in sale.value!.lines)
                  if ((quantities[l.saleLineId] ?? 0) > 0)
                    RefundLineDraft(
                      saleLineId: l.saleLineId,
                      name: l.title,
                      quantity: quantities[l.saleLineId]!,
                      restock: restockOf(l.saleLineId),
                    ),
              ]
            : [
                for (final (i, m) in manual.indexed)
                  RefundLineDraft(
                    productId: m.product.id,
                    variantId: m.variant.id,
                    name: m.product.name,
                    variantName: m.variant.name,
                    quantity: m.quantity,
                    amount: parseMoney(m.amount.text),
                    sellBy: m.product.sellBy,
                    restock: restockOf('m$i'),
                  ),
              ],
      );

  /// The outgoing reference is for the record only, so it is optional.
  bool get canRefund => !saving.value && total > 0 && reason.value != null && method.value != null;

  Future<Authorization?> _authorize(String what) => _permissions.authorize(
        withoutReceipt ? Permission.refundWithoutReceipt : Permission.refund,
        reason: what,
      );

  Future<void> refund() async {
    final l = appL10n();
    if (reason.value == null) {
      error.value = l.refundPickReason;
      return;
    }
    final m = method.value;
    if (m == null) return;
    final auth = await _authorize(l.refundApprovalReason(formatMoney(total)));
    if (auth == null) return;
    saving.value = true;
    error.value = null;
    try {
      done.value = await _refunds.refund(
        _draft,
        payments: [
          RefundPaymentInput(
            method: m.kind,
            methodId: m.id,
            methodName: m.name,
            amount: total,
            reference: m.needsReference ? reference.text : null,
          ),
        ],
        actor: auth.actor,
        approver: auth.approver,
      );
    } on RefundException catch (e) {
      error.value = e.message;
    } finally {
      saving.value = false;
    }
  }

  /// The returned items pay for new ones: checked now, saved with the sale.
  Future<void> exchange() async {
    final l = appL10n();
    if (reason.value == null) {
      error.value = l.refundPickReason;
      return;
    }
    final cart = Get.find<CartController>();
    if (cart.exchange.value != null) {
      error.value = l.exchangeAlready;
      return;
    }
    try {
      await _refunds.price(_draft);
    } on RefundException catch (e) {
      error.value = e.message;
      return;
    }
    final auth = await _authorize(l.exchangeApprovalReason(formatMoney(total)));
    if (auth == null) return;
    cart.exchange.value = PendingExchange(
      returned: _draft,
      credit: total,
      saleNumber: sale.value?.number,
      approver: auth.approver,
    );
    Get.back<void>();
    if (Get.isRegistered<ShellController>()) Get.find<ShellController>().select(ShellSection.sell);
  }
}
