import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/validators.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/section_page.dart';
import '../../receive/views/receive_view.dart' show payMethodLabel;
import '../../stock/widgets/purchasing_tabs.dart' show supplierBalanceText;
import '../../stock/widgets/supplier_editor.dart';
import '../controllers/supplier_controller.dart';

class SupplierView extends GetView<SupplierController> {
  const SupplierView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.supplier.value?.name ?? '')),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
      ),
      body: Obx(() {
        final s = controller.supplier.value;
        if (s == null) return const Center(child: CircularProgressIndicator());
        final entries = controller.ledger.toList();
        final receipts = controller.receipts.toList();
        final summary = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AbySpace.s4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.supplierBalance.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                Text(supplierBalanceText(l, s), style: AbyText.title.copyWith(color: s.balance > 0 ? c.warning : c.ink)),
                if (s.paymentTermsDays != null)
                  Text(l.supplierTermsShort(s.paymentTermsDays!), style: AbyText.caption.copyWith(color: c.inkMuted)),
              ]),
            ),
          ),
          const SizedBox(height: AbySpace.s3),
          FilledButton.icon(
            onPressed: () => _pay(context, s),
            icon: const Icon(Icons.payments_outlined),
            label: Text(l.supplierPay),
          ),
          const SizedBox(height: AbySpace.s2),
          OutlinedButton.icon(
            onPressed: () async {
              await showSupplierEditor(supplier: s, onSave: controller.save);
              _flush();
            },
            icon: const Icon(Icons.edit_outlined),
            label: Text(l.supplierEdit),
          ),
          TextButton(
            onPressed: () => controller.setActive(!s.active),
            child: Text(s.active ? l.stockRetire : l.stockRestore),
          ),
          const SizedBox(height: AbySpace.s3),
          GroupCard(title: l.profileContact, children: [
            InfoTile(title: l.profilePhone, value: s.phone == null ? l.settingsNotSet : Validators.formatPhone(s.phone!)),
            InfoTile(title: l.profileEmail, value: s.email ?? l.settingsNotSet),
            InfoTile(title: l.profileAddress, value: s.address ?? l.settingsNotSet),
            if (s.notes != null) InfoTile(title: l.profileNotes, value: s.notes),
          ]),
        ]);
        final history = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          GroupCard(
            title: l.supplierLedger,
            children: entries.isEmpty
                ? [InfoTile(title: l.stockNoMovements)]
                : [
                    for (final e in entries)
                      InfoTile(
                        title: switch (e.kind) {
                          SupplierEntryKind.purchase => l.supplierEntryPurchase,
                          SupplierEntryKind.payment =>
                            l.supplierEntryPayment(e.method == null ? '' : payMethodLabel(l, e.method!)),
                          SupplierEntryKind.adjustment => l.moveAdjustment,
                        },
                        subtitle: [formatDateTime(e.at), e.byName, ?e.reference, ?e.note].join('  ·  '),
                        value: '${e.amount > 0 ? '+' : '−'}${formatMoney(e.amount.abs())}',
                      ),
                  ],
          ),
          GroupCard(
            title: l.deliveriesTab,
            children: receipts.isEmpty
                ? [InfoTile(title: l.deliveriesNone)]
                : [
                    for (final r in receipts)
                      InfoTile(
                        title: r.displayNumber,
                        subtitle: '${formatDateTime(r.at)}  ·  ${l.deliveriesItems(r.lineCount)}',
                        value: formatMoney(r.total),
                      ),
                  ],
          ),
        ]);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: context.isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 340, child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: summary)),
                    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: history)),
                  ])
                : ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [summary, history]),
          ),
        );
      }),
    );
  }

  Future<void> _pay(BuildContext context, Supplier s) async {
    await Get.dialog<void>(_PayDialog(supplier: s));
    _flush();
  }

  void _flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}

/// Owns its text fields, so they outlive the closing animation.
class _PayDialog extends StatefulWidget {
  const _PayDialog({required this.supplier});

  final Supplier supplier;

  @override
  State<_PayDialog> createState() => _PayDialogState();
}

class _PayDialogState extends State<_PayDialog> {
  final SupplierController controller = Get.find();
  late final _amount = TextEditingController(
    text: widget.supplier.balance > 0 ? (widget.supplier.balance / 100).toStringAsFixed(2) : '',
  );
  final _reference = TextEditingController();
  var _method = SupplierPaymentMethod.cash;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.supplierPayTitle(widget.supplier.name)),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.supplierAmount, prefixText: 'GH₵ '),
          ),
          const SizedBox(height: AbySpace.s3),
          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
            for (final m in SupplierPaymentMethod.values)
              OptionChip(label: payMethodLabel(l, m), selected: _method == m, onTap: () => setState(() => _method = m)),
          ]),
          const SizedBox(height: AbySpace.s3),
          TextField(controller: _reference, decoration: InputDecoration(labelText: l.supplierReference)),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () async {
            if (await controller.pay(_amount.text, _method, reference: _reference.text)) {
              goBack<void>();
            } else if (controller.message.value case final text?) {
              controller.message.value = null;
              showMessage(text);
            }
          },
          child: Text(l.supplierPay),
        ),
      ],
    );
  }
}
