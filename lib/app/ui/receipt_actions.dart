import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/validators.dart';
import '../data/repositories/receipt_repository.dart';
import '../domain/customer_documents.dart';
import '../domain/documents/table_doc.dart';
import '../domain/receipt/receipt_doc.dart';
import '../domain/receipt/receipt_pdf.dart';
import '../services/pdf_brand_loader.dart';
import '../services/printing/print_service.dart';
import '../theme/aby_theme.dart';
import 'dialogs.dart';
import 'files.dart';
import 'l10n.dart';

/// "Print receipt": queues it. Without a printer, offers to send it
/// instead (WhatsApp, SMS or PDF).
Future<void> printSaleReceipt(String saleId, {bool reprint = true}) async {
  final print = Get.find<PrintService>();
  if (!print.hasPrinter) {
    showMessage(appL10n().printNoPrinter, tone: MessageTone.error);
    return sendSaleReceipt(saleId);
  }
  final ok = await print.printSale(saleId, reprint: reprint);
  showMessage(ok ? appL10n().printSent : appL10n().printNoPrinter, tone: ok ? MessageTone.success : MessageTone.error);
}

/// The refund slip on the printer, or as a PDF when there is none.
Future<void> printRefundSlip(String refundId) async {
  final print = Get.find<PrintService>();
  if (!print.hasPrinter) {
    final doc = await print.refundDoc(refundId);
    if (doc != null) await shareReceiptPdf(doc, title: appL10n().printNoPrinterPdf);
    return;
  }
  final ok = await print.printRefund(refundId);
  showMessage(ok ? appL10n().printSent : appL10n().printNoPrinter, tone: ok ? MessageTone.success : MessageTone.error);
}

enum _PaperWay { printer, pdf }

/// A report, statement, voucher or badge on the receipt printer, or as a
/// PDF to share or save. With a printer it asks which (it just prints when
/// [askPdf] is false, for screens with their own PDF button); without one
/// it goes straight to the PDF.
Future<void> printOnPaper(ReceiptDoc doc, {bool askPdf = true}) async {
  final l = appL10n();
  final print = Get.find<PrintService>();
  if (!print.hasPrinter) {
    await shareReceiptPdf(doc, title: l.printNoPrinterPdf);
    return;
  }
  final way = askPdf
      ? await choiceDialog<_PaperWay>(
          title: l.printHow,
          options: _PaperWay.values,
          label: (w) => w == _PaperWay.printer ? l.printOnPrinter : l.printAsPdf,
        )
      : _PaperWay.printer;
  if (way == _PaperWay.printer) {
    final ok = print.printDoc(doc);
    showMessage(ok ? l.printSent : l.printNoPrinter, tone: ok ? MessageTone.success : MessageTone.error);
  }
  if (way == _PaperWay.pdf) await shareReceiptPdf(doc);
}

/// [doc] as a PDF on a receipt roll, shared or saved. True when it went
/// somewhere.
Future<bool> shareReceiptPdf(ReceiptDoc doc, {String? title, String? text}) async => shareOrSaveBytes(
  '${docFileStem(doc.title)}.pdf',
  await ReceiptPdf.build(doc, brand: await loadPdfBrand()),
  title: title,
  text: text,
);

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
    goBack<void>();
  }

  Future<void> _pdf() async {
    if (await shareReceiptPdf(widget.doc)) goBack<void>();
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
      actions: [
        DialogButtons(children: [OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        ]),
      ],
    );
  }
}
