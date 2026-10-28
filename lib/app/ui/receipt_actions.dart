import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/validators.dart';
import '../data/repositories/receipt_repository.dart';
import '../domain/customer_documents.dart';
import '../domain/receipt/receipt_doc.dart';
import '../domain/receipt/receipt_pdf.dart';
import '../services/printing/print_service.dart';
import '../theme/aby_theme.dart';
import 'dialogs.dart';
import 'files.dart';
import 'l10n.dart';

/// "Print receipt": queues it, or says there is no printer.
Future<void> printSaleReceipt(String saleId, {bool reprint = true}) async {
  final l = appL10n();
  final ok = await Get.find<PrintService>().printSale(saleId, reprint: reprint);
  showMessage(ok ? l.printSent : l.printNoPrinter);
}

Future<void> printRefundSlip(String refundId) async {
  final l = appL10n();
  final ok = await Get.find<PrintService>().printRefund(refundId);
  showMessage(ok ? l.printSent : l.printNoPrinter);
}

/// A report or statement on the receipt printer.
void printOnPaper(ReceiptDoc doc) {
  final l = appL10n();
  showMessage(Get.find<PrintService>().printDoc(doc) ? l.printSent : l.printNoPrinter);
}

/// "Send receipt": WhatsApp or SMS with the receipt as text, or a PDF
/// through the share sheet. Works offline: the message goes when the phone
/// has signal.
Future<void> sendSaleReceipt(String saleId) async {
  final data = await ReceiptRepository(Get.find()).sale(saleId);
  final doc = await Get.find<PrintService>().saleDoc(saleId);
  if (data == null || doc == null) return;
  await Get.dialog<void>(_SendReceipt(doc: doc, phone: data.customerPhone));
}

class _SendReceipt extends StatefulWidget {
  const _SendReceipt({required this.doc, this.phone});

  final ReceiptDoc doc;
  final String? phone;

  @override
  State<_SendReceipt> createState() => _SendReceiptState();
}

class _SendReceiptState extends State<_SendReceipt> {
  late final _phone = TextEditingController(text: widget.phone == null ? '' : Validators.formatPhone(widget.phone!));
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _message({required bool sms}) async {
    final l = context.l10n;
    final typed = _phone.text.trim();
    final phone = typed.isEmpty ? '' : Validators.normalisePhone(typed);
    if (phone == null) {
      setState(() => _error = l.receiptPhoneInvalid);
      return;
    }
    // Narrow enough for a phone screen; WhatsApp shows ``` as fixed width.
    final text = widget.doc.toText(Paper.mm58);
    final uri = sms
        ? CustomerDocuments.sms(phone, text)
        : CustomerDocuments.whatsApp(phone, '```\n$text\n```');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      setState(() => _error = l.customerCannotOpen);
      return;
    }
    Get.back<void>();
  }

  Future<void> _pdf() async {
    final bytes = await ReceiptPdf.build(widget.doc);
    final name = '${widget.doc.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.pdf';
    if (await shareOrSaveBytes(name, bytes)) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.receiptSend),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: l.receiptPhone, helperText: l.receiptPhoneHelp, errorText: _error),
          ),
          const SizedBox(height: AbySpace.s4),
          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
            FilledButton.icon(onPressed: () => _message(sms: false), icon: const Icon(Icons.chat_outlined), label: const Text('WhatsApp')),
            OutlinedButton.icon(onPressed: () => _message(sms: true), icon: const Icon(Icons.sms_outlined), label: Text(l.receiptSms)),
            OutlinedButton.icon(onPressed: _pdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: Text(l.receiptPdf)),
          ]),
        ]),
      ),
      actions: [OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel))],
    );
  }
}
