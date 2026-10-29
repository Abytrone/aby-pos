import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/settings.dart';
import '../../../domain/receipt/escpos.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/enums.dart';
import '../../../models/receipt.dart';
import '../../../models/sale.dart';
import '../../../services/auth_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/photo_picker.dart';
import '../../../ui/receipt_preview.dart';
import '../controllers/settings_controller.dart';

/// Settings → Receipt design: what goes on the receipt, with a live preview.
Future<void> showReceiptDesigner(SettingsController settings) =>
    Get.dialog<void>(_ReceiptDesigner(settings: settings));

class _ReceiptDesigner extends StatefulWidget {
  const _ReceiptDesigner({required this.settings});

  final SettingsController settings;

  @override
  State<_ReceiptDesigner> createState() => _ReceiptDesignerState();
}

class _ReceiptDesignerState extends State<_ReceiptDesigner> {
  late final SettingsController _s = widget.settings;
  late final _header = TextEditingController(text: _s.value(AppSettings.receiptHeader));
  late final _footer = TextEditingController(text: _s.value(AppSettings.receiptFooter));
  late final _momo = TextEditingController(text: _s.value(AppSettings.receiptMomo));
  late String _logo = _s.value(AppSettings.receiptLogo);
  late bool _cashier = _s.value(AppSettings.receiptShowCashier);
  late bool _customer = _s.value(AppSettings.receiptShowCustomer);
  late bool _tax = _s.value(AppSettings.receiptShowTax);
  late bool _qr = _s.value(AppSettings.receiptShowQr);
  late int _creditCopies = ReceiptDesign.decodeCopies(_s.value(AppSettings.receiptCopies))['credit'] ?? 1;

  @override
  void dispose() {
    _header.dispose();
    _footer.dispose();
    _momo.dispose();
    super.dispose();
  }

  ReceiptDesign get _design => ReceiptDesign(
        shopName: _s.value(AppSettings.shopName),
        address: _s.value(AppSettings.shopAddress),
        phone: _s.value(AppSettings.shopPhone),
        header: _header.text.trim(),
        footer: _footer.text.trim(),
        momoNumber: _momo.text.trim(),
        logo: _logo.isEmpty ? null : base64Decode(_logo),
        showCashier: _cashier,
        showCustomer: _customer,
        showTax: _tax,
        showQr: _qr,
      );

  /// A made-up sale to show the layout.
  ReceiptData get _sample => ReceiptData(
        saleId: '00000000-0000-7000-8000-000000000000',
        number: 142,
        at: DateTime.now(),
        cashierName: Get.find<AuthService>().currentUser.value?.name ?? 'Ama',
        customerName: 'Kofi Mensah',
        lines: const [
          ReceiptLine(name: 'Vanilla cone', variant: 'Large', quantity: 2, unitPrice: 1800, total: 3600, options: ['Sprinkles']),
          ReceiptLine(name: 'Waffle', quantity: 1, unitPrice: 1200, total: 1200, discount: 200),
        ],
        subtotal: 4800,
        total: 4600,
        taxTotal: 150,
        payments: const [
          Payment(id: 'p', method: PaymentMethod.cash, methodName: 'Cash', amount: 4600, tendered: 5000, changeGiven: 400),
        ],
      );

  Future<void> _pickLogo() async {
    final bytes = await pickPhotoBytes(ImageSource.gallery);
    if (bytes == null) return;
    final png = receiptLogo(bytes);
    if (png == null) return showMessage(appL10n().receiptLogoUnreadable);
    setState(() => _logo = base64Encode(png));
  }

  Future<void> _save() async {
    final copies = Map<String, int>.of(ReceiptDesign.decodeCopies(_s.value(AppSettings.receiptCopies)));
    if (_creditCopies == 1) {
      copies.remove('credit');
    } else {
      copies['credit'] = _creditCopies;
    }
    final ok = await _s.saveAll([
      (AppSettings.receiptHeader, _header.text.trim()),
      (AppSettings.receiptFooter, _footer.text.trim()),
      (AppSettings.receiptMomo, _momo.text.trim()),
      (AppSettings.receiptLogo, _logo),
      (AppSettings.receiptShowCashier, _cashier),
      (AppSettings.receiptShowCustomer, _customer),
      (AppSettings.receiptShowTax, _tax),
      (AppSettings.receiptShowQr, _qr),
      (AppSettings.receiptCopies, jsonEncode(copies)),
    ]);
    if (!ok) return;
    goBack<void>();
    _s.saved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    Widget toggle(String title, bool value, ValueChanged<bool> set) => SwitchListTile(
          title: Text(title),
          value: value,
          onChanged: (v) => setState(() => set(v)),
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
    final logoBytes = _logo.isEmpty ? null : base64Decode(_logo);
    final form = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.receiptShopFromSettings, style: AbyText.caption.copyWith(color: c.inkMuted)),
      const SizedBox(height: AbySpace.s3),
      Row(children: [
        if (logoBytes != null) ...[
          Image.memory(logoBytes, height: 48),
          const SizedBox(width: AbySpace.s2),
        ],
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _pickLogo,
            icon: const Icon(Icons.image_outlined),
            label: Text(logoBytes == null ? l.receiptLogoAdd : l.receiptLogoChange),
          ),
        ),
        if (logoBytes != null)
          IconButton(tooltip: l.receiptLogoRemove, onPressed: () => setState(() => _logo = ''), icon: const Icon(Icons.close)),
      ]),
      const SizedBox(height: AbySpace.s3),
      TextField(
        controller: _header,
        maxLines: 2,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: l.receiptHeader, helperText: l.receiptHeaderHelp),
      ),
      const SizedBox(height: AbySpace.s3),
      TextField(
        controller: _momo,
        keyboardType: TextInputType.phone,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: l.receiptMomo),
      ),
      const SizedBox(height: AbySpace.s3),
      TextField(
        controller: _footer,
        maxLines: 2,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: l.receiptFooter),
      ),
      const SizedBox(height: AbySpace.s2),
      toggle(l.receiptShowCashier, _cashier, (v) => _cashier = v),
      toggle(l.receiptShowCustomer, _customer, (v) => _customer = v),
      toggle(l.receiptShowTax, _tax, (v) => _tax = v),
      toggle(l.receiptShowQr, _qr, (v) => _qr = v),
      const SizedBox(height: AbySpace.s2),
      Text(l.receiptCreditCopies, style: AbyText.label.copyWith(color: c.inkMuted)),
      const SizedBox(height: AbySpace.s2),
      SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 1, label: Text(l.receiptOneCopy)),
          ButtonSegment(value: 2, label: Text(l.receiptTwoCopies)),
        ],
        selected: {_creditCopies},
        onSelectionChanged: (s) => setState(() => _creditCopies = s.first),
      ),
    ]);
    final preview = ReceiptPreview(
      doc: ReceiptBuilder.sale(_sample, _design),
      paper: Get.find<PrintService>().paper,
    );
    return AlertDialog(
      title: Text(l.receiptDesign),
      content: SizedBox(
        width: 820,
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth >= 640) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: SingleChildScrollView(child: form)),
              const SizedBox(width: AbySpace.s6),
              Expanded(child: SingleChildScrollView(child: preview)),
            ]);
          }
          return SingleChildScrollView(
            child: Column(children: [form, const SizedBox(height: AbySpace.s6), preview]),
          );
        }),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}
