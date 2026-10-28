import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/validators.dart';
import '../models/customer.dart';
import '../models/enums.dart';
import '../models/sale.dart';

/// Statements and reminders for a customer's credit account.
abstract final class CustomerDocuments {
  /// "GHS 12.50": the PDF's built-in font has no cedi sign.
  static String _money(int pesewas) {
    final neg = pesewas < 0;
    final v = pesewas.abs();
    final whole = (v ~/ 100).toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '${neg ? '-' : ''}GHS $whole.${(v % 100).toString().padLeft(2, '0')}';
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String entryLabel(CustomerEntry e) => switch (e.kind) {
        CustomerEntryKind.creditSale => 'Sale ${e.saleNumber == null ? '' : formatSaleNumber(e.saleNumber!)}'.trim(),
        CustomerEntryKind.repayment => 'Payment${e.methodName == null ? '' : ' (${e.methodName})'}',
        CustomerEntryKind.writeOff => 'Written off',
        CustomerEntryKind.creditRefund => 'Refund',
        CustomerEntryKind.topUp => 'Paid in${e.methodName == null ? '' : ' (${e.methodName})'}',
        CustomerEntryKind.changeKept => 'Change kept',
        CustomerEntryKind.walletSpend => 'Spent on a sale',
        CustomerEntryKind.walletRefund => 'Refund to wallet',
        CustomerEntryKind.adjustment => 'Adjustment',
        CustomerEntryKind.loyaltyEarn => 'Earned',
        CustomerEntryKind.loyaltyRedeem => 'Reward',
        CustomerEntryKind.loyaltyExpire => 'Expired',
        CustomerEntryKind.voidReversal => 'Sale voided',
      };

  /// A credit statement for [from] to [to]: the balance brought forward,
  /// every entry with a running balance, and what is owed at the end.
  /// [entries] are the credit-account entries in the period, oldest first.
  static Future<Uint8List> statementPdf({
    required String shopName,
    String? shopPhone,
    required Customer customer,
    required DateTime from,
    required DateTime to,
    required int opening,
    required List<CustomerEntry> entries,
    required CreditAging aging,
  }) async {
    final doc = pw.Document(title: 'Statement for ${customer.name}', author: shopName);
    var running = opening;
    final rows = <List<String>>[
      [_date(from), 'Balance brought forward', '', '', _money(opening)],
      for (final e in entries)
        () {
          running += e.amount;
          return [
            _date(e.at),
            entryLabel(e),
            e.amount > 0 ? _money(e.amount) : '',
            e.amount < 0 ? _money(-e.amount) : '',
            _money(running),
          ];
        }(),
    ];
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (_) => [
        pw.Text(shopName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        if (shopPhone != null && shopPhone.isNotEmpty) pw.Text(shopPhone),
        pw.SizedBox(height: 16),
        pw.Text('Statement of account', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text('${customer.name}${customer.phone == null ? '' : '  ·  ${Validators.formatPhone(customer.phone!)}'}'),
        pw.Text('${_date(from)} to ${_date(to)}'),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: ['Date', 'Details', 'Owed', 'Paid', 'Balance'],
          data: rows,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignments: {2: pw.Alignment.centerRight, 3: pw.Alignment.centerRight, 4: pw.Alignment.centerRight},
          border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Balance owed: ${_money(running)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ),
        if (aging.overdue > 0) ...[
          pw.SizedBox(height: 8),
          pw.Text('Overdue: 1-30 days ${_money(aging.days1to30)}, 31-60 days ${_money(aging.days31to60)}, '
              'over 60 days ${_money(aging.over60)}'),
        ],
        pw.SizedBox(height: 24),
        pw.Text('Thank you for your business.', style: const pw.TextStyle(color: PdfColors.grey700)),
      ],
    ));
    return doc.save();
  }

  /// The reminder message from the shop's template. {name}, {amount} and
  /// {shop} are filled in.
  static String reminder(String template, {required Customer customer, required String shopName, required String amount}) =>
      template.replaceAll('{name}', customer.name).replaceAll('{amount}', amount).replaceAll('{shop}', shopName);

  /// Opens WhatsApp with the message ready (no internet API needed).
  static Uri whatsApp(String phone, String text) =>
      Uri.parse('https://wa.me/${phone.replaceAll('+', '')}?text=${Uri.encodeComponent(text)}');

  static Uri sms(String phone, String text) => Uri.parse('sms:$phone?body=${Uri.encodeComponent(text)}');
}
