import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/denominations.dart';
import '../../../core/settings.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/day_close.dart';
import '../../../models/discount.dart';
import '../../../models/expense.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/cash_count_dialog.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/photo_picker.dart';
import '../../../ui/receipt_actions.dart';
import '../../close_day/widgets/period_summary.dart';
import '../../../ui/dialogs.dart';

/// Opening float: typed, or counted note by note. Null when cancelled.
Future<(int, CashCount?)?> showOpenShift({int suggested = 0}) => Get.dialog<(int, CashCount?)>(_OpenShift(suggested: suggested));

class _OpenShift extends StatefulWidget {
  const _OpenShift({required this.suggested});

  final int suggested;

  @override
  State<_OpenShift> createState() => _OpenShiftState();
}

class _OpenShiftState extends State<_OpenShift> {
  late final _float = TextEditingController(text: widget.suggested > 0 ? (widget.suggested / 100).toStringAsFixed(2) : '');
  CashCount? _count;
  String? _error;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.shiftOpen),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.shiftOpenHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s3),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _float,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _count = null,
                decoration: InputDecoration(labelText: l.closeFloatLabel, prefixText: 'GH₵ '),
              ),
            ),
            const SizedBox(width: AbySpace.s2),
            OutlinedButton.icon(
              onPressed: () async {
                final count = await showCashCount(initial: _count ?? const CashCount(), title: l.shiftCountFloat);
                if (count == null) return;
                setState(() {
                  _count = count;
                  _float.text = (count.total / 100).toStringAsFixed(2);
                });
              },
              icon: const Icon(Icons.calculate_outlined),
              label: Text(l.countCashButton),
            ),
          ]),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s3),
              child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
            ),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<(int, CashCount?)>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () {
            final v = _float.text.trim().isEmpty ? 0 : parseMoney(_float.text);
            if (v == null) return setState(() => _error = l.customerAmountInvalid);
            goBack(result: (v, _count));
          },
          child: Text(l.shiftOpen),
        ),
      ],
    );
  }
}

/// What the shift looks like so far, without closing it.
Future<void> showXReport(OpenPeriod period) => Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      final float = period.shiftFloat ?? period.suggestedFloat;
      return AlertDialog(
        title: Text(l.xReportTitle),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(child: PeriodSummary(period: period, openingFloat: float)),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => printOnPaper(ReceiptBuilder.period(
              period,
              title: 'X report',
              shopName: Get.find<SettingsService>().get(AppSettings.shopName),
              at: DateTime.now(),
              byName: Get.find<AuthService>().user.name,
              openingFloat: float,
            )),
            icon: const Icon(Icons.print_outlined),
            label: Text(l.receiptPrint),
          ),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ],
      );
    }));

/// The result of the pay in / out dialog.
class CashMove {
  const CashMove(this.amount, this.reason, this.note, this.photo, [this.expenseCategoryId]);
  final int amount;
  final String reason;
  final String? note;
  final Uint8List? photo;

  /// Also an expense in this category (pay-outs only).
  final String? expenseCategoryId;
}

/// Cash into ([payIn]) or out of the drawer: amount, reason, note, photo.
Future<CashMove?> showPayInOut({
  required bool payIn,
  required List<Reason> reasons,
  List<ExpenseCategory> expenseCategories = const [],
}) =>
    Get.dialog<CashMove>(_PayInOut(payIn: payIn, reasons: reasons, expenseCategories: expenseCategories));

class _PayInOut extends StatefulWidget {
  const _PayInOut({required this.payIn, required this.reasons, this.expenseCategories = const []});

  final bool payIn;
  final List<Reason> reasons;
  final List<ExpenseCategory> expenseCategories;

  @override
  State<_PayInOut> createState() => _PayInOutState();
}

class _PayInOutState extends State<_PayInOut> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _reason;
  String? _expense;
  Uint8List? _photo;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.payIn ? l.payInTitle : l.payOutTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.checkoutAmount, prefixText: 'GH₵ '),
            ),
            const SizedBox(height: AbySpace.s3),
            Text(l.refundReason.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final r in widget.reasons)
                OptionChip(label: r.name, selected: _reason == r.name, onTap: () => setState(() => _reason = r.name)),
            ]),
            if (!widget.payIn && widget.expenseCategories.isNotEmpty) ...[
              const SizedBox(height: AbySpace.s3),
              Text(l.payOutExpense.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                for (final cat in widget.expenseCategories)
                  OptionChip(
                    label: cat.name,
                    selected: _expense == cat.id,
                    onTap: () => setState(() => _expense = _expense == cat.id ? null : cat.id),
                  ),
              ]),
            ],
            const SizedBox(height: AbySpace.s3),
            TextField(controller: _note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
            const SizedBox(height: AbySpace.s3),
            Row(children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final bytes = await pickPhotoBytes(ImageSource.gallery);
                  if (bytes != null) setState(() => _photo = bytes);
                },
                icon: Icon(_photo == null ? Icons.receipt_long_outlined : Icons.check_circle, color: _photo == null ? null : c.success),
                label: Text(_photo == null ? l.cashAddReceipt : l.cashReceiptAdded),
              ),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<CashMove>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () {
            final amount = parseMoney(_amount.text);
            if (amount == null || amount <= 0) return setState(() => _error = l.customerAmountInvalid);
            if (_reason == null) return setState(() => _error = l.refundPickReason);
            goBack(result: CashMove(amount, _reason!, _note.text, _photo, _expense));
          },
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
