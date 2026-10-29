import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;

import '../core/validators.dart';
import '../models/customer.dart';
import '../models/enums.dart';
import '../models/sale.dart';
import 'documents/pdf_brand.dart';
import 'documents/table_doc.dart';

/// Statements and reminders for a customer's credit account.
abstract final class CustomerDocuments {
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
    PdfBrand? brand,
    Uint8List? logo,
  }) async {
    final b = brand ?? PdfBrand.plain();
    final made = DateTime.now();
    final doc = pw.Document(title: 'Statement for ${customer.name}', author: shopName, creator: 'Aby');
    var running = opening;
    final sheet = DocSheet(
      name: 'Statement',
      columns: [
        const DocColumn('Date', DocKind.date),
        const DocColumn('Details'),
        DocColumn('Owed (${b.currency})', DocKind.money),
        DocColumn('Paid (${b.currency})', DocKind.money),
        DocColumn('Balance (${b.currency})', DocKind.money),
      ],
      rows: [
        [from, 'Balance brought forward', null, null, opening],
      for (final e in entries)
        () {
          running += e.amount;
          return [e.at,
            entryLabel(e),
            e.amount > 0 ? e.amount : null,
            e.amount < 0 ? -e.amount : null, running];
        }(),
    ],
    );
    final period = docPeriod(from, to);
    doc.addPage(pw.MultiPage(
        pageTheme: b.page(),
        header: (context) => b.runningHeader(context, 'Statement for ${customer.name}', period),
        footer: (context) => b.footer(context, made),
      build: (_) => [
          b.band(
            eyebrow: 'Statement of account',
            title: customer.name,
            subtitle: [period, if (customer.phone != null) Validators.formatPhone(customer.phone!)].join('  ·  '),
            shopName: shopName,
            lines: [if (shopPhone != null && shopPhone.isNotEmpty) shopPhone],
            logo: logo,
          ),
          b.facts([
            DocFact('Balance owed', running),
            DocFact('Brought forward', opening),
            if (aging.overdue > 0) DocFact('Overdue', aging.overdue),
          ]),
        pw.SizedBox(height: 14),
          ...b.table(sheet),
        if (aging.overdue > 0) ...[
          pw.SizedBox(height: 10),
          pw.Text(
              'Overdue: 1-30 days ${b.money(aging.days1to30)}, 31-60 days ${b.money(aging.days31to60)}, over 60 days ${b.money(aging.over60)}',
              style: b.text(size: 8.5, color: PdfBrand.danger),
            ),
        ],
        pw.SizedBox(height: 20),
        pw.Text('Thank you for your business.', style: b.text(color: PdfBrand.muted)),
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
