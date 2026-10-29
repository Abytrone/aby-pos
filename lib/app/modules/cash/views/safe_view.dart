import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/repositories/safe_repository.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/photo_picker.dart';
import '../../../ui/section_page.dart';
import '../controllers/safe_controller.dart';
import '../../../ui/dialogs.dart';

class SafeView extends GetView<SafeController> {
  const SafeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.safeTitle), backgroundColor: c.surface, surfaceTintColor: Colors.transparent, toolbarHeight: 64),
      body: Obx(() {
        if (controller.loading.value) return const Center(child: CircularProgressIndicator());
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AbySpace.s4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.safeBalance.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                    Text(formatMoney(controller.balance.value), style: AbyText.title.copyWith(color: c.ink)),
                  ]),
                ),
              ),
              const SizedBox(height: AbySpace.s3),
              FilledButton.icon(
                onPressed: controller.balance.value <= 0 ? null : () => Get.dialog<void>(_DepositDialog(controller: controller)),
                icon: const Icon(Icons.account_balance_outlined),
                label: Text(l.bankDepositTitle),
              ),
              const SizedBox(height: AbySpace.s4),
              GroupCard(
                title: l.safeEntries,
                children: controller.entries.isEmpty
                    ? [InfoTile(title: l.safeNone)]
                    : [for (final e in controller.entries) _EntryTile(entry: e)],
              ),
            ]),
          ),
        );
      }),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final SafeEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final title = switch (entry.kind) {
      SafeEntryKind.drop => l.safeDropTitle,
      SafeEntryKind.deposit => l.bankDepositAt(entry.bank ?? ''),
      SafeEntryKind.adjustment => l.safeAdjustment,
    };
    return InfoTile(
      title: title,
      subtitle: [formatDateTime(entry.at), entry.byName, ?entry.reference, ?entry.note].join('  ·  '),
      value: '${entry.amount > 0 ? '+' : '−'}${formatMoney(entry.amount.abs())}',
    );
  }
}

class _DepositDialog extends StatefulWidget {
  const _DepositDialog({required this.controller});

  final SafeController controller;

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  late final _amount = TextEditingController(text: (widget.controller.balance.value / 100).toStringAsFixed(2));
  final _bank = TextEditingController();
  final _reference = TextEditingController();
  Uint8List? _slip;
  String? _error;

  @override
  void dispose() {
    for (final f in [_amount, _bank, _reference]) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.bankDepositTitle),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.checkoutAmount, prefixText: 'GH₵ '),
          ),
          const SizedBox(height: AbySpace.s3),
          TextField(controller: _bank, decoration: InputDecoration(labelText: l.bankName)),
          const SizedBox(height: AbySpace.s3),
          TextField(controller: _reference, decoration: InputDecoration(labelText: l.bankSlip)),
          const SizedBox(height: AbySpace.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final bytes = await pickPhotoBytes(ImageSource.gallery);
                if (bytes != null) setState(() => _slip = bytes);
              },
              icon: Icon(_slip == null ? Icons.receipt_long_outlined : Icons.check_circle, color: _slip == null ? null : c.success),
              label: Text(_slip == null ? l.bankSlipPhoto : l.cashReceiptAdded),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s3),
              child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
            ),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () async {
            final error = await widget.controller.deposit(_amount.text, bank: _bank.text, reference: _reference.text, slip: _slip);
            if (error == null) {
              goBack<void>();
            } else {
              setState(() => _error = error);
            }
          },
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
