import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../core/units.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/purchase_order_repository.dart';
import '../../../data/repositories/receiving_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../products/controllers/catalogue_controller.dart';
import '../../stock/widgets/new_items_dialog.dart';
import '../../stock/widgets/stock_item_editor.dart';
import '../../../ui/l10n.dart';

/// One line on the delivery form.
class ReceiveLineForm {
  ReceiveLineForm({this.stockItemId, String quantity = '', String total = '', this.unit, this.ordered, this.receivedBefore = 0})
      : quantity = TextEditingController(text: quantity),
        total = TextEditingController(text: total);

  String? stockItemId;

  /// Bumped when the item is set from outside the dropdown (a new item, or
  /// "New stock item…" cancelled), so the dropdown redraws.
  int version = 0;

  /// Base units on the order, and already received against it, when the
  /// line comes from a purchase order. Such a line may be 0: not delivered.
  final int? ordered;
  final int receivedBefore;
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
          ordered: ol.quantity,
          receivedBefore: ol.received,
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

  /// "+ New stock items…" in a line's item list: one or several new items,
  /// with what came and its cost. The first goes on this line, the rest on
  /// lines of their own.
  Future<void> newItemFor(ReceiveLineForm line) async {
    final made = await showNewStockItems(
      forDelivery: true,
      supplierId: supplierId,
      takenNames: {for (final i in items) i.name},
    );
    line.version++;
    if (made == null || made.isEmpty) return update();
    items = [...items, for (final m in made) m.item]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final (k, m) in made.indexed) {
      final unit = DisplayUnit.bulk(m.item.unit);
      if (k == 0) {
        line.stockItemId = m.item.id;
        line.unit = unit;
        line.quantity.text = quantityIn(m.quantity, unit);
        line.total.text = _plain(m.lineTotal);
      } else {
        lines.add(ReceiveLineForm(stockItemId: m.item.id, unit: unit, quantity: quantityIn(m.quantity, unit), total: _plain(m.lineTotal)));
      }
    }
    changed();
  }

  void setItem(ReceiveLineForm line, String? id) {
    if (id == newStockItemChoice) {
      newItemFor(line);
      return;
    }
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
      final q = line.ordered != null && line.quantity.text.trim().isEmpty ? 0 : baseQuantity(line);
      final t = parseMoney(line.total.text);
      // An ordered item that did not come: left for a later delivery.
      if (line.ordered != null && q == 0) continue;
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
    if (drafts.isEmpty) {
      error = l.receiveNothing;
      update();
      return false;
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
    final before = {for (final i in await _stock.items()) i.id: i};
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
      summary = await _summarise(before, receipt);
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

  /// What the saved delivery changed, for the screen after it.
  DeliverySummary? summary;

  Future<DeliverySummary> _summarise(Map<String, StockItem> before, StockReceipt receipt) async {
    final after = {for (final i in await _stock.items()) i.id: i};
    final changes = [
      for (final id in received.keys)
        if (before[id] != null && after[id] != null) (before[id]!, after[id]!),
    ];
    final id = purchaseOrderId;
    final o = id == null ? null : await Get.find<PurchaseOrderRepository>().find(id);
    final target = Get.find<SettingsService>().get(AppSettings.targetMarginPercent);
    final catalogue = await Get.find<CatalogRepository>().load();
    final low = [
      for (final p in catalogue.products.where((p) => !p.archived))
        if (p.variants.any((v) =>
            v.recipe.any((r) => received.containsKey(r.stockItemId)) &&
            (CatalogueController.marginOf(v.price, v.cost) ?? 100) < target))
          p.name,
    ];
    return DeliverySummary(
      detail: await _receiving.detail(receipt.id),
      number: receipt.displayNumber,
      changes: changes,
      order: o,
      targetMargin: target,
      belowMargin: low,
    );
  }
}

/// A saved delivery: each item's stock and cost before and after, how the
/// order stands, and products whose margin the new costs pushed below the
/// shop's target.
class DeliverySummary {
  const DeliverySummary({
    required this.number,
    required this.changes,
    required this.targetMargin,
    required this.belowMargin,
    this.order,
    this.detail,
  });

  /// The delivery as saved.
  final DeliveryDetail? detail;
  final String number;
  final List<(StockItem before, StockItem after)> changes;
  final PurchaseOrder? order;
  final int targetMargin;
  final List<String> belowMargin;

  int get stillWaiting => order?.lines.where((l) => l.outstanding > 0).length ?? 0;
}
