import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/pay_method_repository.dart';
import '../../../data/repositories/voucher_repository.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/receipt_actions.dart';
import '../../../ui/dialogs.dart';

/// Customers → Gift vouchers: what is out there, and selling a new one.
Future<void> showVouchers() => Get.dialog<void>(const _Vouchers());

class _Vouchers extends StatefulWidget {
  const _Vouchers();

  @override
  State<_Vouchers> createState() => _VouchersState();
}

class _VouchersState extends State<_Vouchers> {
  final VoucherRepository _repo = Get.find();
  List<GiftVoucher> _list = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.list();
    if (mounted) setState(() => _list = list);
  }

  Future<void> _sell() async {
    final sold = await Get.dialog<GiftVoucher>(const _SellVoucher());
    if (sold == null) return;
    await _load();
    await Get.dialog<void>(_VoucherCard(voucher: sold));
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final now = DateTime.now();
    return AlertDialog(
      title: Text(l.voucherTitle),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.voucherHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Flexible(
            child: _list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AbySpace.s4),
                    child: Text(l.voucherNone, style: AbyText.body.copyWith(color: c.inkMuted)),
                  )
                : ListView(shrinkWrap: true, children: [
                    for (final v in _list)
                      ListTile(
                        title: Text(v.code, style: AbyText.receiptStrong.copyWith(color: c.ink)),
                        subtitle: Text([
                          l.voucherSoldFor(formatMoney(v.amount), formatDate(v.issuedAt)),
                          if (v.expiresOn != null)
                            v.expiredAt(now) ? l.voucherExpired : l.voucherUseBy(formatDate(v.expiresOn!)),
                        ].join('  ·  ')),
                        trailing: Text(
                          formatMoney(v.balance),
                          style: AbyText.price.copyWith(color: v.balance > 0 && !v.expiredAt(now) ? c.ink : c.inkMuted),
                        ),
                        onTap: () => Get.dialog<void>(_VoucherCard(voucher: v)),
                      ),
                  ]),
          ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton.icon(onPressed: _sell, icon: const Icon(Icons.card_giftcard), label: Text(l.voucherSell)),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}

/// Value, how it was paid, and how long it lasts.
class _SellVoucher extends StatefulWidget {
  const _SellVoucher();

  @override
  State<_SellVoucher> createState() => _SellVoucherState();
}

class _SellVoucherState extends State<_SellVoucher> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  final _settings = Get.find<SettingsService>();
  List<PayMethod> _methods = const [];
  PayMethod? _method;
  late int _months = _settings.get(AppSettings.voucherMonths);
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final all = await Get.find<PayMethodRepository>().list();
    const notForVouchers = {PaymentMethod.credit, PaymentMethod.wallet, PaymentMethod.voucher, PaymentMethod.exchange};
    if (!mounted) return;
    setState(() {
      _methods = [for (final m in all) if (!notForVouchers.contains(m.kind)) m];
      _method = _methods.where((m) => m.isCash).firstOrNull ?? _methods.firstOrNull;
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final amount = parseMoney(_amount.text);
    final method = _method;
    if (amount == null || amount <= 0) return setState(() => _error = l.customerAmountInvalid);
    if (method == null) return;
    if (method.needsReference && _reference.text.trim().isEmpty) return setState(() => _error = l.voucherReferenceNeeded);
    final auth = await Get.find<PermissionService>().authorize(Permission.sell, reason: l.voucherSell);
    if (auth == null) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final voucher = await Get.find<VoucherRepository>().issue(
        amount: amount,
        method: method,
        reference: _reference.text,
        shopName: _settings.get(AppSettings.shopName),
        expiresOn: _months <= 0 ? null : DateTime(now.year, now.month + _months, now.day),
        note: _note.text,
        by: auth.authority,
      );
      if (method.isCash) printService?.openDrawer();
      goBack(result: voucher);
    } on VoucherException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    return AlertDialog(
      title: Text(l.voucherSell),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.voucherValue, prefixText: 'GH₵ '),
            ),
            const SizedBox(height: AbySpace.s3),
            DropdownButtonFormField<PayMethod>(
              key: ValueKey(_methods.length),
              initialValue: _method,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.voucherPaidBy),
              items: [for (final m in _methods) DropdownMenuItem(value: m, child: Text(m.name))],
              onChanged: (m) => setState(() => _method = m),
            ),
            if (_method?.needsReference ?? false) ...[
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: _reference,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: l.checkoutReference(_method!.name)),
              ),
            ],
            const SizedBox(height: AbySpace.s3),
            DropdownButtonFormField<int>(
              initialValue: const [0, 3, 6, 12, 24].contains(_months) ? _months : 12,
              decoration: InputDecoration(labelText: l.voucherLasts),
              items: [
                for (final m in const [3, 6, 12, 24]) DropdownMenuItem(value: m, child: Text(l.voucherMonths(m))),
                DropdownMenuItem(value: 0, child: Text(l.voucherNoExpiry)),
              ],
              onChanged: (m) => setState(() => _months = m ?? 12),
            ),
            const SizedBox(height: AbySpace.s3),
            TextField(controller: _note, decoration: InputDecoration(labelText: l.voucherNote)),
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
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.voucherSellButton)),
        ]),
      ],
    );
  }
}

/// The voucher with its QR code: print it or send it.
class _VoucherCard extends StatelessWidget {
  const _VoucherCard({required this.voucher});

  final GiftVoucher voucher;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final shop = Get.find<SettingsService>().get(AppSettings.shopName);
    final doc = ReceiptBuilder.voucher(shopName: shop, code: voucher.code, amount: voucher.amount, expiresOn: voucher.expiresOn);
    return AlertDialog(
      title: Text(l.voucherTitleOne),
      content: SizedBox(
        width: 340,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(voucher.code, style: AbyText.title.copyWith(color: c.ink, fontFamily: AbyText.mono)),
          const SizedBox(height: AbySpace.s2),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AbySpace.s2),
            child: QrImageView(data: voucher.code, size: 160, padding: EdgeInsets.zero),
          ),
          const SizedBox(height: AbySpace.s2),
          Text(l.voucherLeft(formatMoney(voucher.balance), formatMoney(voucher.amount)), style: AbyText.body.copyWith(color: c.ink)),
          if (voucher.expiresOn != null)
            Text(l.voucherUseBy(formatDate(voucher.expiresOn!)), style: AbyText.caption.copyWith(color: c.inkMuted)),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton.icon(
            onPressed: () => shareReceiptPdf(doc),
            icon: const Icon(Icons.send_outlined),
            label: Text(l.voucherSend),
          ),
          OutlinedButton.icon(
            onPressed: () => printOnPaper(doc, askPdf: false),
            icon: const Icon(Icons.print_outlined),
            label: Text(l.receiptPrint),
          ),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}
