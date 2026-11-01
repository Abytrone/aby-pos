import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/units.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../models/stock.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/purchasing_controller.dart';
import '../controllers/stock_controller.dart';
import 'new_items_dialog.dart';
import 'purchasing_tabs.dart' show showDelivery;
import 'stock_item_editor.dart';

String poStatusLabel(AppLocalizations l, PurchaseOrderStatus s) => switch (s) {
      PurchaseOrderStatus.open => l.poOpen,
      PurchaseOrderStatus.partial => l.poPartial,
      PurchaseOrderStatus.received => l.poReceived,
      PurchaseOrderStatus.cancelled => l.poCancelled,
    };

/// Stock → Orders: purchase orders, waiting ones first.
class PurchaseOrdersTab extends GetView<PurchasingController> {
  const PurchaseOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final list = [...controller.orders.where((o) => o.isOpen), ...controller.orders.where((o) => !o.isOpen)];
      if (list.isEmpty) return EmptyState(icon: Icons.assignment_outlined, message: l.poNone);
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: list.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final o = list[i];
          return InfoTile(
            title: '${o.displayNumber}  ·  ${o.supplierName}',
            subtitle: [formatDate(o.at), poStatusLabel(l, o.status), l.deliveriesItems(o.lines.length)].join('  ·  '),
            value: o.estimate == 0 ? null : formatMoney(o.estimate),
            leading: Icon(Icons.assignment_outlined, color: o.isOpen ? c.blue : c.inkMuted),
            trailing: o.isOpen && controller.canReceive
                ? TextButton.icon(
                    onPressed: () => controller.receiveOrder(o),
                    icon: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: Text(l.poReceive),
                  )
                : null,
            onTap: () => showPurchaseOrder(controller, o),
          );
        },
      );
    });
  }
}

/// One order: what was ordered and received, and what to do next.
Future<void> showPurchaseOrder(PurchasingController ctl, PurchaseOrder o) => Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      final c = Theme.of(context).extension<AbyColors>()!;
      return AlertDialog(
        title: Text('${o.displayNumber}  ·  ${o.supplierName}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                [poStatusLabel(l, o.status), formatDate(o.at), o.byName, if (o.expectedOn != null) l.poNeededBy(formatDate(o.expectedOn!))]
                    .join('  ·  '),
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AbySpace.s2),
              for (final line in o.lines)
                InfoTile(
                  title: line.name,
                  subtitle: l.poLineReceived(formatQuantity(line.received, line.unit)),
                  value: formatQuantity(line.quantity, line.unit),
                ),
              if (o.note != null) Text('“${o.note}”', style: AbyText.caption.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s4),
              Text(l.poDeliveries.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              FutureBuilder<List<StockReceipt>>(
                future: ctl.deliveriesFor(o),
                builder: (_, snap) {
                  final list = snap.data ?? const <StockReceipt>[];
                  if (snap.hasData && list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AbySpace.s2),
                      child: Text(l.poNoDeliveries, style: AbyText.caption.copyWith(color: c.inkMuted)),
                    );
                  }
                  return Column(children: [
                    for (final r in list)
                      InfoTile(
                        leading: Icon(Icons.local_shipping_outlined, color: c.inkMuted),
                        title: r.displayNumber,
                        subtitle: [formatDateTime(r.at), l.deliveriesItems(r.lineCount), r.receivedByName].join('  ·  '),
                        value: formatMoney(r.total),
                        onTap: () {
                          goBack<void>();
                          showDelivery(ctl, r);
                        },
                      ),
                  ]);
                },
              ),
            ]),
          ),
        ),
        actions: [
          DialogButtons(children: [
                if (o.isOpen)
              TextButton(
                onPressed: () async {
                  goBack<void>();
                  await ctl.cancelOrder(o);
                },
                child: Text(l.poCancel, style: TextStyle(color: c.danger)),
              ),
            OutlinedButton.icon(onPressed: () => ctl.shareOrder(o), icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(l.deliveryPdf)),
            if (o.isOpen && ctl.canReceive)
              FilledButton.icon(
                onPressed: () async {
                  goBack<void>();
                  await ctl.receiveOrder(o);
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: Text(l.poReceive),
              ),
            if (!o.isOpen) FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
          ]),
        ],
      );
    }));

/// A new purchase order: pick the supplier (its low items come in), change
/// the amounts, add others.
Future<void> showNewPurchaseOrder(PurchasingController ctl) async {
  final items = Get.find<StockController>().items.toList();
  final order = await Get.dialog<PurchaseOrder>(_NewOrder(ctl: ctl, items: items));
  if (order != null) await showPurchaseOrder(ctl, order);
}

class _Line {
  _Line(this.itemId, String quantity) : quantity = TextEditingController(text: quantity);

  String? itemId;
  final TextEditingController quantity;

  /// Bumped after "New stock item…", so the dropdown redraws.
  int version = 0;
}

class _NewOrder extends StatefulWidget {
  const _NewOrder({required this.ctl, required this.items});

  final PurchasingController ctl;
  final List<StockItem> items;

  @override
  State<_NewOrder> createState() => _NewOrderState();
}

class _NewOrderState extends State<_NewOrder> {
  String? _supplier;
  final _lines = <_Line>[];
  final _note = TextEditingController();
  DateTime? _expected;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    for (final l in _lines) {
      l.quantity.dispose();
    }
    super.dispose();
  }

  StockItem? _item(String? id) => widget.items.where((i) => i.id == id).firstOrNull;

  /// "+ New stock items…" in a line's item list: one or several new items.
  /// The first goes on this line, the rest on lines of their own.
  Future<void> _newItemFor(_Line line) async {
    final made = await showNewStockItems(
      forDelivery: false,
      supplierId: _supplier,
      takenNames: {for (final i in widget.items) i.name},
    );
    setState(() {
      line.version++;
      if (made == null || made.isEmpty) return;
      for (final (k, m) in made.indexed) {
        widget.items.add(m.item);
        final qty = quantityIn(m.quantity, DisplayUnit.bulk(m.item.unit));
        if (k == 0) {
          line.itemId = m.item.id;
          line.quantity.text = qty;
        } else {
          _lines.add(_Line(m.item.id, qty));
        }
      }
    });
  }

  Future<void> _pickSupplier(String? id) async {
    setState(() => _supplier = id);
    if (id == null) return;
    final suggested = await widget.ctl.suggestionsFor(id);
    if (!mounted) return;
    setState(() {
      for (final (itemId, qty) in suggested) {
        if (_lines.any((l) => l.itemId == itemId)) continue;
        final item = _item(itemId);
        if (item == null) continue;
        _lines.add(_Line(itemId, quantityIn(qty, DisplayUnit.bulk(item.unit))));
      }
      if (_lines.isEmpty) _lines.add(_Line(null, ''));
    });
  }

  Future<void> _save() async {
    final l = context.l10n;
    final supplier = _supplier;
    if (supplier == null) return setState(() => _error = l.poPickSupplier);
    final lines = <(String, int)>[];
    for (final line in _lines.where((x) => x.itemId != null)) {
      final item = _item(line.itemId)!;
      final q = parseQuantity(line.quantity.text, DisplayUnit.bulk(item.unit));
      if (q == null || q <= 0) return setState(() => _error = l.receiveLineInvalid(item.name));
      lines.add((item.id, q));
    }
    if (lines.isEmpty) return setState(() => _error = l.poAddItems);
    final order = await widget.ctl.createOrder(PurchaseOrderDraft(supplierId: supplier, lines: lines, expectedOn: _expected, note: _note.text));
    if (order != null) {
      goBack(result: order);
    } else if (widget.ctl.message.value != null) {
      setState(() => _error = widget.ctl.message.value);
      widget.ctl.message.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    return AlertDialog(
      title: Text(l.poNew),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            DropdownButtonFormField<String>(
              initialValue: _supplier,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.receiveSupplier, helperText: l.poSuggestHelp),
              items: [
                for (final s in widget.ctl.suppliers.where((s) => s.active))
                  DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: _pickSupplier,
            ),
            const SizedBox(height: AbySpace.s3),
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AbySpace.s2),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey((line, line.version)),
                      initialValue: line.itemId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.recipeItem, isDense: true),
                      items: [
                        DropdownMenuItem(
                          value: newStockItemChoice,
                          child: Text(l.stockNewItemInline, style: TextStyle(color: c.blue, fontWeight: FontWeight.w600)),
                        ),
                        for (final i in widget.items) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => v == newStockItemChoice ? _newItemFor(line) : setState(() => line.itemId = v),
                    ),
                  ),

                  const SizedBox(width: AbySpace.s2),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: line.quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.stockQuantity,
                        suffixText: _item(line.itemId) == null ? null : DisplayUnit.bulk(_item(line.itemId)!.unit).symbol,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.recipeRemove,
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _lines.remove(line)),
                  ),
                ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _lines.add(_Line(null, ''))),
                icon: const Icon(Icons.add),
                label: Text(l.receiveAddLine),
              ),
            ),
            Wrap(spacing: AbySpace.s2, children: [
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(_expected == null ? l.poNeededByPick : l.poNeededBy(formatDate(_expected!))),
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(context: context, initialDate: _expected ?? now, firstDate: now, lastDate: DateTime(now.year + 1));
                  if (d != null) setState(() => _expected = d);
                },
              ),
            ]),
            const SizedBox(height: AbySpace.s2),
            TextField(controller: _note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _save, child: Text(l.poCreate)),
        ]),
      ],
    );
  }
}

/// Stock → Expiring: batches still in stock by expiry date.
Future<void> showExpiring(List<BatchLeft> batches) => Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      final c = Theme.of(context).extension<AbyColors>()!;
      final now = DateTime.now();
      return AlertDialog(
        title: Text(l.expiryTitle),
        content: SizedBox(
          width: 480,
          child: batches.isEmpty
              ? Text(l.expiryNone, style: AbyText.body.copyWith(color: c.inkMuted))
              : ListView(shrinkWrap: true, children: [
                  for (final b in batches)
                    InfoTile(
                      title: b.itemName,
                      subtitle: [
                        ?b.batchNo,
                        if (b.expiresOn != null)
                          (b.daysLeft(now)! < 0 ? l.expiryExpired(formatDate(b.expiresOn!)) : l.expiryOn(formatDate(b.expiresOn!))),
                      ].join('  ·  '),
                      value: formatQuantity(b.left, b.unit),
                      leading: Icon(
                        Icons.event_busy,
                        color: (b.daysLeft(now) ?? 99) < 0 ? c.danger : ((b.daysLeft(now) ?? 99) <= 7 ? c.warning : c.inkMuted),
                      ),
                    ),
                ]),
        ),
        actions: [
          DialogButtons(children: [FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
          ]),
        ],
      );
    }));

/// Shows a message left by the controller (an error from saving).
void flushPurchasing(PurchasingController ctl) {
  final m = ctl.message.value;
  if (m == null) return;
  ctl.message.value = null;
  showMessage(m);
}
