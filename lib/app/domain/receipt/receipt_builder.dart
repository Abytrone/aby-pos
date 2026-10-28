import '../../models/customer.dart';
import '../../models/day_close.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/receipt.dart';
import '../../models/sale.dart';
import '../customer_documents.dart';
import 'receipt_code.dart';
import 'receipt_doc.dart';

/// Which copy of a receipt this is, when more than one prints.
enum ReceiptCopy { only, customer, shop }

/// Builds receipts and reports on paper. Printed text is English, like the
/// PDF statements: it is read by customers and accountants.
abstract final class ReceiptBuilder {
  static String _two(int n) => n.toString().padLeft(2, '0');

  static String dateTime(DateTime at) {
    final d = at.toLocal();
    return '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  /// "2", "0.534 kg", "0.250 l".
  static String quantity(int q, SellBy by) => switch (by) {
        SellBy.each => '$q',
        SellBy.kg => '${(q / 1000).toStringAsFixed(3)} kg',
        SellBy.litre => '${(q / 1000).toStringAsFixed(3)} l',
      };

  static String _orderType(OrderType t) => switch (t) {
        OrderType.takeaway => 'Takeaway',
        OrderType.eatIn => 'Eat in',
        OrderType.delivery => 'Delivery',
      };

  /// The shop's name, logo, address and header lines.
  static List<ReceiptBlock> _top(ReceiptDesign d) => [
        if (d.logo != null) RImage(d.logo!),
        RText(d.shopName, align: ReceiptAlign.center, bold: true, big: true),
        if (d.address.isNotEmpty) RText(d.address, align: ReceiptAlign.center),
        if (d.phone.isNotEmpty) RText('Tel ${d.phone}', align: ReceiptAlign.center),
        if (d.header.isNotEmpty) RText(d.header, align: ReceiptAlign.center),
      ];

  static ReceiptDoc sale(
    ReceiptData s,
    ReceiptDesign d, {
    ReceiptCopy copy = ReceiptCopy.only,
    bool reprint = false,
  }) {
    final credit = s.payments.where((p) => p.method == PaymentMethod.credit).fold(0, (t, p) => t + p.amount);
    return ReceiptDoc('Receipt ${s.displayNumber}', [
      ..._top(d),
      if (d.momoNumber.isNotEmpty) RText('MoMo ${d.momoNumber}', align: ReceiptAlign.center),
      const RRule(),
      if (s.orderNumber != null) ...[
        const RText('YOUR ORDER', align: ReceiptAlign.center),
        RText('${d.orderPrefix}${s.orderNumber}', align: ReceiptAlign.center, bold: true, big: true),
        const RRule(),
      ],
      RRow('Receipt ${s.displayNumber}', dateTime(s.at)),
      if (d.showCashier) RText('Served by ${s.cashierName}'),
      if (d.showCustomer && s.customerName != null) RText('Customer: ${s.customerName}'),
      if (s.orderType != null) RText(_orderType(s.orderType!)),
      if (copy == ReceiptCopy.customer) const RText('CUSTOMER COPY', align: ReceiptAlign.center, bold: true),
      if (copy == ReceiptCopy.shop) const RText('SHOP COPY', align: ReceiptAlign.center, bold: true),
      if (reprint) const RText('REPRINT', align: ReceiptAlign.center, bold: true),
      if (s.voided) const RText('VOIDED - NOT A SALE', align: ReceiptAlign.center, bold: true, big: true),
      const RRule(),
      for (final l in s.lines) ...[
        if (l.sellBy == SellBy.each)
          RRow('${l.quantity} x ${l.title}', paperMoney(l.total))
        else ...[
          RRow(l.title, paperMoney(l.total)),
          RText('  ${quantity(l.quantity, l.sellBy)} @ ${paperMoney(l.unitPrice)}'),
        ],
        for (final o in l.options) RText('  + $o'),
        if (l.note != null) RText('  "${l.note}"'),
        if (l.promotion > 0) RRow('  ${l.promotionName ?? 'Promotion'}', paperMoney(-l.promotion)),
        if (l.discount > 0) RRow('  Discount', paperMoney(-l.discount)),
      ],
      const RRule(),
      if (s.orderDiscount > 0 || s.lineDiscounts > 0 || s.rounding != 0 || (!s.taxIncluded && s.taxTotal > 0))
        RRow('Subtotal', paperMoney(s.subtotal)),
      if (s.lineDiscounts > 0) RRow('Item discounts', paperMoney(-s.lineDiscounts)),
      if (s.orderDiscount > 0) RRow('Discount', paperMoney(-s.orderDiscount)),
      if (!s.taxIncluded && s.taxTotal > 0) RRow('Tax', paperMoney(s.taxTotal)),
      if (s.rounding != 0) RRow('Rounding', paperMoney(s.rounding)),
      RRow('TOTAL GHS', paperMoney(s.total), bold: true),
      if (d.showTax && s.taxIncluded && s.taxTotal > 0) RRow('Includes tax', paperMoney(s.taxTotal)),
      const RFeed(),
      for (final p in s.payments) ...[
        RRow(p.method == PaymentMethod.cash && (p.tendered ?? 0) > p.amount ? 'Cash given' : p.label,
            paperMoney(p.method == PaymentMethod.cash ? (p.tendered ?? p.amount) : p.amount)),
        if ((p.changeGiven ?? 0) > 0) RRow('Change', paperMoney(p.changeGiven!)),
        if (p.method == PaymentMethod.cash && (p.tendered ?? 0) - p.amount - (p.changeGiven ?? 0) > 0)
          RRow('Change to wallet', paperMoney(p.tendered! - p.amount - (p.changeGiven ?? 0))),
        if (p.momoReference != null && p.method != PaymentMethod.exchange) RText('  Ref ${p.momoReference}'),
        if (p.method == PaymentMethod.exchange && p.momoReference != null) RText('  Returned items ${p.momoReference}'),
      ],
      if (s.refunded > 0) RRow('Refunded since', paperMoney(-s.refunded)),
      if (s.loyaltyBalance != null && d.loyaltyStyle == 'stamps')
        RText('Stamps: ${s.loyaltyBalance} of ${d.stampsForReward}. Then one free!'),
      if (s.loyaltyBalance != null && d.loyaltyStyle == 'points') RText('Points: ${s.loyaltyBalance}'),
      if (s.note != null) RText('Note: ${s.note}'),
      if (credit > 0 && copy != ReceiptCopy.customer) ...[
        const RFeed(2),
        RText('${paperMoney(credit)} on credit. Signed:'),
        const RFeed(2),
        const RText('______________________________'),
      ],
      const RRule(),
      if (d.footer.isNotEmpty) RText(d.footer, align: ReceiptAlign.center),
      if (d.showQr && !s.voided) ...[
        const RFeed(),
        RQr(ReceiptCode.encode(s.saleId)),
        const RText('Keep this receipt for refunds', align: ReceiptAlign.center),
      ],
    ]);
  }

  static ReceiptDoc refund(RefundReceiptData r, ReceiptDesign d) => ReceiptDoc('Refund ${r.displayNumber}', [
        ..._top(d),
        const RRule(),
        RText('REFUND ${r.displayNumber}', align: ReceiptAlign.center, bold: true, big: true),
        RRow(r.saleNumber == null ? 'No receipt' : 'For sale ${formatSaleNumber(r.saleNumber!)}', dateTime(r.at)),
        RText('By ${r.byName}'),
        RText('Reason: ${r.reason}'),
        const RRule(),
        for (final (name, q, by, amount) in r.lines)
          RRow(by == SellBy.each ? '$q x $name' : '$name ${quantity(q, by)}', paperMoney(amount)),
        const RRule(),
        RRow('REFUNDED GHS', paperMoney(r.total), bold: true),
        for (final (method, amount) in r.payments) RRow(method, paperMoney(amount)),
        const RFeed(2),
        const RText('Customer signature:'),
        const RFeed(2),
        const RText('______________________________'),
      ]);

  /// A kitchen / prep ticket: the queue number big, then what to make.
  static ReceiptDoc kitchenTicket({
    required String number,
    required DateTime at,
    required List<OrderLine> lines,
    String? note,
    OrderType? orderType,
    String? customerName,
  }) =>
      ReceiptDoc('Order $number', [
        RText(number, align: ReceiptAlign.center, bold: true, big: true),
        RRow(orderType == null ? 'Order' : _orderType(orderType), dateTime(at)),
        if (customerName != null) RText(customerName),
        const RRule(),
        for (final l in lines) ...[
          RText(l.sellBy == SellBy.each ? '${l.quantity} x ${l.title}' : '${l.title} ${quantity(l.quantity, l.sellBy)}',
              bold: true, big: true),
          for (final o in l.options) RText('  + $o', bold: true),
          if (l.note != null) RText('  "${l.note}"', bold: true),
        ],
        if (note != null) ...[const RRule(), RText('NOTE: $note', bold: true)],
      ]);

  /// An X report (the shift so far) or Z report (the day's close).
  static ReceiptDoc period(
    OpenPeriod p, {
    required String title,
    required String shopName,
    required DateTime at,
    required String byName,
    int? openingFloat,
    int? counted,
    bool showCash = true,
  }) {
    final expected = openingFloat == null ? null : p.expectedCash(openingFloat);
    return ReceiptDoc(title, [
      RText(shopName, align: ReceiptAlign.center, bold: true),
      RText(title.toUpperCase(), align: ReceiptAlign.center, bold: true, big: true),
      RText('${p.from == null ? 'Start' : dateTime(p.from!)} to ${dateTime(at)}', align: ReceiptAlign.center),
      RText('Printed by $byName', align: ReceiptAlign.center),
      if (p.shiftOpenedBy != null) RText('Shift opened by ${p.shiftOpenedBy}', align: ReceiptAlign.center),
      const RRule(),
      RRow('Sales (${p.salesCount})', paperMoney(p.salesTotal), bold: true),
      if (p.voidedCount > 0) RRow('Voided', '${p.voidedCount}'),
      if (p.discountTotal > 0) RRow('Discounts', paperMoney(-p.discountTotal)),
      if (p.refundsCount > 0) RRow('Refunds (${p.refundsCount})', paperMoney(-p.refundsTotal)),
      const RRule(),
      for (final m in PaymentMethod.values)
        if (m == PaymentMethod.cash ? showCash : (p.byMethod[m] ?? 0) > 0) RRow(m.label, paperMoney(p.byMethod[m] ?? 0)),
      if (showCash) ...[
        if (p.rounding != 0) RRow('Rounding', paperMoney(p.rounding)),
        const RRule(),
        const RText('CASH DRAWER', bold: true),
        if (openingFloat != null) RRow('Opening float', paperMoney(openingFloat)),
        RRow('Cash sales', paperMoney(p.cashTakings)),
        if (p.customerCash > 0) RRow('From customers', paperMoney(p.customerCash)),
        if (p.payIns > 0) RRow('Paid in', paperMoney(p.payIns)),
        if (p.payOuts > 0) RRow('Paid out', paperMoney(-p.payOuts)),
        if (p.safeDrops > 0) RRow('To the safe', paperMoney(-p.safeDrops)),
        if (p.cashRefunds > 0) RRow('Cash refunds', paperMoney(-p.cashRefunds)),
        if (expected != null) RRow('Expected', paperMoney(expected), bold: true),
        if (counted != null) RRow('Counted', paperMoney(counted), bold: true),
        if (counted != null && expected != null)
          RRow(counted >= expected ? 'Over' : 'Short', paperMoney((counted - expected).abs()), bold: true),
      ],
      if (p.noSaleCount > 0) ...[
        const RRule(),
        const RText('DRAWER OPENED WITHOUT A SALE'),
        for (final e in p.noSales.entries) RRow(e.key, '${e.value}'),
      ],
      const RRule(),
      if (p.lastSaleNumber > 0) RText('Last sale ${formatSaleNumber(p.lastSaleNumber)}'),
    ]);
  }

  /// The Z report: a day as it was closed (also reprinted from the list of
  /// past closes).
  static ReceiptDoc dayClose(DayClose z, {required String shopName}) {
    final cashSales =
        z.expectedCash - z.openingFloat - z.customerCash - z.payIns + z.cashRefunds + z.payOuts + z.safeDrops;
    final d = z.difference;
    return ReceiptDoc('Z report ${dateTime(z.closedAt)}', [
      RText(shopName, align: ReceiptAlign.center, bold: true),
      const RText('Z REPORT', align: ReceiptAlign.center, bold: true, big: true),
      RText('${z.periodStart == null ? 'Start' : dateTime(z.periodStart!)} to ${dateTime(z.closedAt)}',
          align: ReceiptAlign.center),
      RText('Closed by ${z.closedByName}', align: ReceiptAlign.center),
      const RRule(),
      RRow('Sales (${z.salesCount})', paperMoney(z.salesTotal), bold: true),
      if (z.voidedCount > 0) RRow('Voided', '${z.voidedCount}'),
      if (z.discountTotal > 0) RRow('Discounts', paperMoney(-z.discountTotal)),
      if (z.refundsTotal > 0) RRow('Refunds', paperMoney(-z.refundsTotal)),
      const RRule(),
      RRow('Cash', paperMoney(cashSales)),
      RRow('MoMo', paperMoney(z.momoTakings)),
      RRow('Credit', paperMoney(z.creditTakings)),
      if (z.otherTakings > 0) RRow('Other', paperMoney(z.otherTakings)),
      const RRule(),
      const RText('CASH DRAWER', bold: true),
      RRow('Opening float', paperMoney(z.openingFloat)),
      RRow('Cash sales', paperMoney(cashSales)),
      if (z.customerCash > 0) RRow('From customers', paperMoney(z.customerCash)),
      if (z.payIns > 0) RRow('Paid in', paperMoney(z.payIns)),
      if (z.payOuts > 0) RRow('Paid out', paperMoney(-z.payOuts)),
      if (z.safeDrops > 0) RRow('To the safe', paperMoney(-z.safeDrops)),
      if (z.cashRefunds > 0) RRow('Cash refunds', paperMoney(-z.cashRefunds)),
      RRow('Expected', paperMoney(z.expectedCash), bold: true),
      RRow('Counted', paperMoney(z.countedCash), bold: true),
      RRow(d == 0 ? 'Balanced' : (d > 0 ? 'Over' : 'Short'), paperMoney(d.abs()), bold: true),
      if (z.varianceReason != null) RText('Reason: ${z.varianceReason}'),
      if (z.noSaleCount > 0) RRow('Drawer opened without a sale', '${z.noSaleCount}'),
      if (z.note != null) RText('Note: ${z.note}'),
      const RFeed(2),
      const RText('Signed: ______________________'),
    ]);
  }

  /// A customer's balance and recent entries, for the counter.
  static ReceiptDoc statement({
    required String shopName,
    required Customer customer,
    required List<CustomerEntry> entries,
    required DateTime at,
  }) =>
      ReceiptDoc('Statement ${customer.name}', [
        RText(shopName, align: ReceiptAlign.center, bold: true),
        const RText('STATEMENT', align: ReceiptAlign.center, bold: true, big: true),
        RText(customer.name, align: ReceiptAlign.center),
        RText(dateTime(at), align: ReceiptAlign.center),
        const RRule(),
        for (final e in entries) ...[
          RRow(CustomerDocuments.entryLabel(e), paperMoney(e.amount)),
          RText('  ${dateTime(e.at)}'),
        ],
        const RRule(),
        RRow('OWED GHS', paperMoney(customer.owed), bold: true),
        if (customer.wallet > 0) RRow('In wallet', paperMoney(customer.wallet)),
      ]);

  /// A gift voucher to hand over or send: the code big, its QR code, the
  /// value and the last day.
  static ReceiptDoc voucher({
    required String shopName,
    required String code,
    required int amount,
    DateTime? expiresOn,
  }) =>
      ReceiptDoc('Gift voucher $code', [
        RText(shopName, align: ReceiptAlign.center, bold: true),
        const RText('GIFT VOUCHER', align: ReceiptAlign.center, bold: true, big: true),
        const RRule(),
        RText('GHS ${paperMoney(amount)}', align: ReceiptAlign.center, bold: true, big: true),
        RText(code, align: ReceiptAlign.center, bold: true, big: true),
        RQr(code),
        if (expiresOn != null)
          RText('Use by ${_two(expiresOn.day)}/${_two(expiresOn.month)}/${expiresOn.year}', align: ReceiptAlign.center),
        RText('Pay with it at $shopName. What is left stays on the code.', align: ReceiptAlign.center),
      ]);

  /// Shows the paper width, the characters and a QR code.
  static ReceiptDoc testPage(String shopName, Paper paper, String printerName) => ReceiptDoc('Test page', [
        const RText('Aby printer test', align: ReceiptAlign.center, bold: true, big: true),
        RText(shopName, align: ReceiptAlign.center),
        RText(printerName, align: ReceiptAlign.center),
        RText('${paper.millimetres} mm paper, ${paper.chars} characters', align: ReceiptAlign.center),
        const RRule(),
        RText('1234567890' * (paper.chars ~/ 10) + '1234567890'.substring(0, paper.chars % 10)),
        const RText('ABCDEFGHIJKLMNOPQRSTUVWXYZ abcdefghijklmnopqrstuvwxyz'),
        const RRow('2 x Vanilla cone', '36.00'),
        const RRow('TOTAL GHS', '36.00', bold: true),
        const RRule(),
        const RQr('ABY-TEST'),
        const RText('If you can read this, the printer works.', align: ReceiptAlign.center),
      ]);
}
