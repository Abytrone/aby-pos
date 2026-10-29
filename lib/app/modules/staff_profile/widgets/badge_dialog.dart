import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/receipt/receipt_doc.dart';
import '../../../services/printing/print_service.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/receipt_actions.dart';
import '../../../ui/receipt_preview.dart';
import '../../../ui/dialogs.dart';

/// A staff badge: preview, print on the receipt printer, or send as a PDF
/// to print on card.
Future<void> showBadgeDialog(ReceiptDoc doc, String name) => Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      final paper = printService?.paper ?? Paper.mm80;
      return AlertDialog(
        title: Text(l.badgeFor(name)),
        content: SizedBox(width: 360, child: SingleChildScrollView(child: ReceiptPreview(doc: doc, paper: paper))),
        actions: [
          DialogButtons(children: [
                OutlinedButton.icon(
              onPressed: () => shareReceiptPdf(doc),
              icon: const Icon(Icons.send_outlined),
              label: Text(l.voucherSend),
            ),
            OutlinedButton.icon(onPressed: () => printOnPaper(doc, askPdf: false), icon: const Icon(Icons.print_outlined), label: Text(l.receiptPrint)),
            FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
          ]),
        ],
        actionsPadding: const EdgeInsets.all(AbySpace.s4),
      );
    }));
