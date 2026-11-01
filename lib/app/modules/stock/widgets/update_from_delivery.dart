import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/units.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../domain/delivery_updates.dart';
import '../../../models/purchasing.dart';
import '../../../routes/app_routes.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

/// Update the stock items on a delivery from it: tick, per item, whether
/// its cost, supplier and usual order follow the delivery. The stock the
/// delivery brought in is already counted; this is the rest of the item.
Future<void> showUpdateFromDelivery(DeliveryDetail d) async {
  // Already used, or nothing differs: say so instead.
  final when = await DeliveryUpdates.updatedAt(Get.find<AuditRepository>(), d.receipt);
  if (when != null) {
    showMessage(appL10n().updateAlready(formatDateTime(when)));
    return;
  }
  final items = {for (final i in await Get.find<StockRepository>().items(includeInactive: true)) i.id: i};
  final suppliers = {for (final s in await Get.find<SupplierRepository>().list(includeInactive: true)) s.id: s.name};
  await Get.dialog<void>(_Update(detail: d, updates: DeliveryUpdates.plan(d, items), suppliers: suppliers));
}

class _Update extends StatefulWidget {
  const _Update({required this.detail, required this.updates, required this.suppliers});

  final DeliveryDetail detail;
  final List<DeliveryUpdate> updates;
  final Map<String, String> suppliers;

  @override
  State<_Update> createState() => _UpdateState();
}

class _UpdateState extends State<_Update> {
  /// Everything that differs starts ticked: the delivery is the newest word.
  late final _picked = {for (final u in widget.updates) u.item.id: {...u.changes}};
  bool _saving = false;

  int get _count => _picked.values.where((p) => p.isNotEmpty).length;

  Future<void> _apply() async {
    final l = context.l10n;
    final auth = await Get.find<PermissionService>().authorize(Permission.editProducts, reason: l.stockEditReason);
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      final n = await DeliveryUpdates.apply(
        Get.find<StockRepository>(),
        Get.find<AuditRepository>(),
        widget.detail.receipt,
        [for (final u in widget.updates) (u, _picked[u.item.id]!)],
        by: auth.authority,
      );
      goBack<void>();
      showMessage(appL10n().updateDone(n), tone: MessageTone.success);
    } on StockException catch (e) {
      setState(() => _saving = false);
      showMessage(e.message, tone: MessageTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final muted = AbyText.caption.copyWith(color: c.inkMuted);
    String supplier(String? id) => id == null ? l.updateNoSupplier : (widget.suppliers[id] ?? l.updateNoSupplier);
    return AlertDialog(
      title: Text(l.updateTitle(widget.detail.receipt.displayNumber)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.updateIntro, style: AbyText.body.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s3),
            if (widget.updates.isEmpty)
              Container(
                padding: const EdgeInsets.all(AbySpace.s3),
                decoration: BoxDecoration(color: c.successSoft, borderRadius: BorderRadius.circular(AbyRadius.md)),
                child: Text(l.updateNothing, style: AbyText.body.copyWith(color: c.success)),
              ),
            for (final u in widget.updates) ...[
              Row(children: [
                Expanded(
                  child: Text(u.item.name, style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () {
                    goBack<void>();
                    Get.toNamed<void>(Routes.stockItem, arguments: u.item.id);
                  },
                  child: Text(l.updateOpenItem),
                ),
              ]),
              for (final change in DeliveryChange.values)
                if (u.changes.contains(change))
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _picked[u.item.id]!.contains(change),
                    onChanged: (v) => setState(() => v == true ? _picked[u.item.id]!.add(change) : _picked[u.item.id]!.remove(change)),
                    title: Text(switch (change) {
                      DeliveryChange.cost => l.updateCost(
                          formatMoney(u.item.bulkPrice),
                          formatMoney(priceForUnit(u.line.unitCostMilli, DisplayUnit.bulk(u.item.unit))),
                          DisplayUnit.bulk(u.item.unit).symbol,
                        ),
                      DeliveryChange.supplier => l.updateSupplier(supplier(u.item.supplierId), supplier(u.supplierId)),
                      DeliveryChange.orderQty => l.updateOrderQty(
                          u.item.reorderQty == null ? '–' : formatQuantity(u.item.reorderQty!, u.item.unit),
                          formatQuantity(u.line.quantity, u.item.unit),
                        ),
                    }),
                    subtitle: change == DeliveryChange.cost ? Text(l.updateCostHelp, style: muted) : null,
                  ),
              const Divider(),
            ],
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          if (widget.updates.isNotEmpty)
            FilledButton(
              onPressed: _count == 0 || _saving ? null : _apply,
              child: Text(l.updateApply(_count)),
            ),
        ]),
      ],
    );
  }
}
