import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/customer.dart';
import '../../../models/sale.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../services/money.dart';

/// Money in from a customer (a repayment or a wallet top-up): amount, how
/// it was paid, the reference and, for repayments, which sale it is for.
/// [onSave] returns an error to show, or null when done.
Future<void> showMoneyDialog({
  required String title,
  required List<PayMethod> methods,
  required Future<String?> Function(String amount, PayMethod method, String? reference, String? saleId) onSave,
  String initialAmount = '',
  List<OpenDebt> debts = const [],
}) =>
    Get.dialog<void>(_MoneyDialog(title: title, methods: methods, onSave: onSave, initialAmount: initialAmount, debts: debts));

class _MoneyDialog extends StatefulWidget {
  const _MoneyDialog({
    required this.title,
    required this.methods,
    required this.onSave,
    required this.initialAmount,
    required this.debts,
  });

  final String title;
  final List<PayMethod> methods;
  final Future<String?> Function(String, PayMethod, String?, String?) onSave;
  final String initialAmount;
  final List<OpenDebt> debts;

  @override
  State<_MoneyDialog> createState() => _MoneyDialogState();
}

class _MoneyDialogState extends State<_MoneyDialog> {
  late final _amount = TextEditingController(text: widget.initialAmount);
  final _reference = TextEditingController();
  late PayMethod? _method = widget.methods.firstWhereOrNull((m) => m.isCash) ?? widget.methods.firstOrNull;
  String? _saleId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final m = _method;
    if (m == null) return;
    setState(() => _saving = true);
    final error = await widget.onSave(_amount.text, m, m.needsReference ? _reference.text : null, _saleId);
    if (!mounted) return;
    if (error == null) {
      Get.back<void>();
    } else {
      setState(() {
        _error = error;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.supplierAmount, prefixText: 'GH₵ '),
            ),
            const SizedBox(height: AbySpace.s3),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final m in widget.methods)
                OptionChip(label: m.name, selected: _method?.id == m.id, onTap: () => setState(() => _method = m)),
            ]),
            if (_method?.needsReference ?? false) ...[
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _reference,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l.checkoutReference(_method!.name)),
              ),
            ],
            if (widget.debts.length > 1) ...[
              const SizedBox(height: AbySpace.s4),
              Text(l.customerPayFor.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                OptionChip(label: l.customerOldestFirst, selected: _saleId == null, onTap: () => setState(() => _saleId = null)),
                for (final d in widget.debts.where((d) => d.saleId != null))
                  OptionChip(
                    label: d.saleNumber == null ? '?' : formatSaleNumber(d.saleNumber!),
                    trailing: formatMoney(d.outstanding),
                    selected: _saleId == d.saleId,
                    onTap: () => setState(() => _saleId = d.saleId),
                  ),
              ]),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l.commonSave)),
      ],
    );
  }
}
