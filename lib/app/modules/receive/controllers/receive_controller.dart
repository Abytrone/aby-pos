import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/units.dart';
import '../../../data/repositories/purchase_order_repository.dart';
import '../../../data/repositories/receiving_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// One line on the delivery form.
class ReceiveLineForm {
  ReceiveLineForm({this.stockItemId, String quantity = '', String total = '', this.unit})
      : quantity = TextEditingController(text: quantity),
        total = TextEditingController(text: total);

  String? stockItemId;
  DisplayUnit? unit;
  final TextEditingController quantity;

  /// For items that track expiry.
  final batchNo = TextEditingController();
  DateTime? expiresOn;

  /// What the line cost in all (GH₵), as on the supplier's invoice.
  final TextEditingController total;

  void dispose() {
    quantity.dispose();
    total.dispose();
    batchNo.dispose();
  }
}

/// Receive a delivery: what came, what it cost, and what was paid.
/// GetBuilder form, like the product editor.
class ReceiveController extends GetxController {
  final ReceivingRepository _receiving = Get.find();
  final StockRepository _stock = Get.find();
  final SupplierRepository _suppliers = Get.find();
  final PermissionService _permissions = Get.find();

  bool loading = true;
  bool saving = false;
  String? error;
  List<StockItem> items = const [];
  List<Supplier> suppliers = const [];

  String? supplierId;
  final invoiceRef = TextEditingController();
  final note = TextEditingController();
  final paidNow = TextEditingController();
  SupplierPaymentMethod paidWith = SupplierPaymentMethod.cash;

  /// Paid now follows the total until someone types in it.
  bool paidTouched = false;
  final lines = <ReceiveLineForm>[];

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    invoiceRef.dispose();
    note.dispose();
    paidNow.dispose();
    for (final l in lines) {
      l.dispose();
    }
    super.onClose();
  }

  /// Received against this purchase order (the route argument), if any.
  final String? purchaseOrderId = Get.arguments as String?;
  PurchaseOrder? order;

  Future<void> _load() async {
    items = (await _stock.items()).toList();
    suppliers = await _suppliers.list();
    final id = purchaseOrderId;
    order = id == null ? null : await Get.find<PurchaseOrderRepository>().find(id);
    final o = order;
    if (o != null) {
      // What is still to come, at the cost expected.
      supplierId = o.supplierId;
      for (final ol in o.lines.where((x) => x.outstanding > 0)) {
        final unit = DisplayUnit.bulk(ol.unit);
        lines.add(ReceiveLineForm(
          stockItemId: ol.stockItemId,
          unit: unit,
          quantity: quantityIn(ol.outstanding, unit),
          total: _plain((ol.outstanding * ol.unitCostMilli + 500) ~/ 1000),
        ));
      }
    }
    if (lines.isEmpty) lines.add(ReceiveLineForm());
    loading = false;
    if (o != null) paidNow.text = _plain(total);
    update();
  }

  void setExpiry(ReceiveLineForm line, DateTime? day) {
    line.expiresOn = day;
    update();
  }

  StockItem? itemOf(ReceiveLineForm l) => items.where((i) => i.id == l.stockItemId).firstOrNull;

  void changed() {
    if (!paidTouched) paidNow.text = _plain(total);
    update();
  }

  void setItem(ReceiveLineForm line, String? id) {
    line.stockItemId = id;
    final item = itemOf(line);
    line.unit = item == null ? null : DisplayUnit.bulk(item.unit);
    changed();
  }

  void setUnit(ReceiveLineForm line, DisplayUnit unit) {
    line.unit = unit;
    update();
  }

  void addLine() {
    lines.add(ReceiveLineForm());
    update();
  }

  void removeLine(ReceiveLineForm line) {
    lines.remove(line);
    line.dispose();
    if (lines.isEmpty) lines.add(ReceiveLineForm());
    changed();
  }

  /// Adds every low item not already on the delivery, at its usual order
  /// quantity and today's cost.
  void addLowItems() {
    final have = {for (final l in lines) l.stockItemId};
    lines.removeWhere((l) => l.stockItemId == null);
    for (final i in items.where((i) => i.isLow && !have.contains(i.id))) {
      final unit = DisplayUnit.bulk(i.unit);
      final qty = i.reorderQty ?? 0;
      lines.add(ReceiveLineForm(
        stockItemId: i.id,
        unit: unit,
        quantity: qty == 0 ? '' : quantityIn(qty, unit),
        total: qty == 0 ? '' : _plain(costOf(qty, i.costMilli)),
      ));
    }
    if (lines.isEmpty) lines.add(ReceiveLineForm());
    changed();
  }

  void setSupplier(String? id) {
    supplierId = id;
    update();
  }

  void setPaidWith(SupplierPaymentMethod m) {
    paidWith = m;
    update();
  }

  void touchPaid() => paidTouched = true;

  int? baseQuantity(ReceiveLineForm l) =>
      l.unit == null ? null : parseQuantity(l.quantity.text, l.unit!);

  /// Pesewas per bulk unit for a line, for checking against the invoice.
  int? unitPrice(ReceiveLineForm l) {
    final q = baseQuantity(l);
    final t = parseMoney(l.total.text);
    final item = itemOf(l);
    if (q == null || q == 0 || t == null || item == null) return null;
    final bulk = DisplayUnit.bulk(item.unit);
    return (t * bulk.factor + q ~/ 2) ~/ q;
  }

  int get total => lines.fold(0, (s, l) => s + (parseMoney(l.total.text) ?? 0));

  static String _plain(int p) => '${p ~/ 100}.${(p % 100).toString().padLeft(2, '0')}';

  Future<bool> save() async {
    final l = appL10n();
    error = null;
    final drafts = <ReceiptLineDraft>[];
    for (final line in lines.where((x) => x.stockItemId != null)) {
      final q = baseQuantity(line);
      final t = parseMoney(line.total.text);
      if (q == null || q <= 0 || t == null) {
        error = l.receiveLineInvalid(itemOf(line)?.name ?? '');
        update();
        return false;
      }
      drafts.add(ReceiptLineDraft(
        stockItemId: line.stockItemId!,
        quantity: q,
        lineTotal: t,
        batchNo: line.batchNo.text.trim().isEmpty ? null : line.batchNo.text.trim(),
        expiresOn: line.expiresOn,
      ));
    }
    final paid = paidNow.text.trim().isEmpty ? 0 : parseMoney(paidNow.text);
    if (paid == null) {
      error = l.receivePaidInvalid;
      update();
      return false;
    }
    final auth = await _permissions.authorize(Permission.receiveStock, reason: l.receiveReason);
    if (auth == null) return false;
    saving = true;
    update();
    try {
      final receipt = await _receiving.receive(
        ReceiptDraft(
          supplierId: supplierId,
          invoiceRef: invoiceRef.text,
          note: note.text,
          lines: drafts,
          paidNow: paid,
          paidWith: paidWith,
          purchaseOrderId: purchaseOrderId,
        ),
        by: auth.authority,
      );
      lastReceipt = receipt;
      received = {for (final d in drafts) d.stockItemId: (received[d.stockItemId] ?? 0) + d.quantity};
      return true;
    } on StockException catch (e) {
      error = e.message;
      return false;
    } finally {
      saving = false;
      update();
    }
  }

  StockReceipt? lastReceipt;

  /// Base units received per stock item, for labels.
  Map<String, int> received = const {};
}
