import 'dart:convert';

import 'package:drift/drift.dart';

import '../../models/discount.dart';
import '../../models/enums.dart';
import '../../models/receipt.dart';
import '../../models/sale.dart';
import '../../models/sale_detail.dart';
import '../database/app_database.dart';

/// Reads a saved sale or refund back as it goes on paper, so a reprint is
/// the same as the first print.
class ReceiptRepository {
  ReceiptRepository(this._db);

  final AppDatabase _db;

  Future<ReceiptData?> sale(String saleId) async {
    final s = await (_db.select(_db.sales)..where((t) => t.id.equals(saleId))).getSingleOrNull();
    if (s == null) return null;
    final lines = await (_db.select(_db.saleLines)
          ..where((l) => l.saleId.equals(saleId) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final payments = await (_db.select(_db.payments)
          ..where((p) => p.saleId.equals(saleId) & p.deletedAt.isNull())
          ..orderBy([(p) => OrderingTerm(expression: p.createdAt), (p) => OrderingTerm(expression: p.id)]))
        .get();
    final customer = s.customerId == null
        ? null
        : await (_db.select(_db.customers)..where((c) => c.id.equals(s.customerId!))).getSingleOrNull();
    final refundSum = _db.refunds.total.sum();
    final refunded = await (_db.selectOnly(_db.refunds)
          ..addColumns([refundSum])
          ..where(_db.refunds.saleId.equals(saleId) & _db.refunds.deletedAt.isNull()))
        .map((r) => r.read(refundSum) ?? 0)
        .getSingle();
    // The discount column includes promotions.
    final loyalty = s.customerId == null
        ? null
        : await _db.customSelect(
            "SELECT SUM(amount) AS v FROM customer_ledger WHERE customer_id = ? AND account = 'loyalty' AND deleted_at IS NULL",
            variables: [Variable.withString(s.customerId!)],
            readsFrom: {_db.customerLedger},
          ).map((r) => r.read<int?>('v')).getSingle();
    final lineDiscounts = lines.fold(0, (t, l) => t + l.discount);
    final exclusive = s.taxTotal > 0 && s.total == s.subtotal - s.discountTotal + s.taxTotal;
    return ReceiptData(
      saleId: s.id,
      number: s.number,
      at: s.createdAt,
      cashierName: s.cashierName,
      lines: [
        for (final l in lines)
          ReceiptLine(
            name: l.productName,
            variant: l.variantName,
            options: [for (final a in l.addons) a.name],
            quantity: l.quantity,
            unitPrice: l.unitPrice,
            total: l.lineTotal,
            discount: l.discount - l.promotion,
            promotion: l.promotion,
            promotionName: l.promotionName,
            sellBy: l.sellBy,
            note: l.note,
          ),
      ],
      subtotal: s.subtotal,
      total: s.total + s.rounding,
      orderDiscount: s.discountTotal - lineDiscounts,
      taxTotal: s.taxTotal,
      taxIncluded: !exclusive,
      rounding: s.rounding,
      payments: [
        for (final p in payments)
          Payment(
            id: p.id,
            method: p.method,
            methodName: p.methodName,
            amount: p.amount,
            tendered: p.tendered,
            changeGiven: p.changeGiven,
            momoReference: p.momoReference,
            customer: p.customer,
          ),
      ],
      customerName: customer?.name,
      customerPhone: customer?.phone,
      orderType: s.orderType,
      note: s.note,
      voided: s.status == SaleStatus.voided,
      refunded: refunded,
      loyaltyBalance: loyalty,
      orderNumber: s.orderNumber,
    );
  }

  /// A sale with everything the receipt leaves out, for its own page.
  Future<SaleDetail?> detail(String saleId) async {
    final receipt = await sale(saleId);
    if (receipt == null) return null;
    final s = await (_db.select(_db.sales)..where((t) => t.id.equals(saleId))).getSingle();
    final lines = await (_db.select(_db.saleLines)
          ..where((l) => l.saleId.equals(saleId) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final refunds = await (_db.select(_db.refunds)
          ..where((r) => r.saleId.equals(saleId) & r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm(expression: r.createdAt)]))
        .get();
    return SaleDetail(
      receipt: receipt,
      lines: [
        for (final (i, l) in lines.indexed)
          SaleDetailLine(
            line: receipt.lines[i],
            listPrice: l.listPrice,
            priceOverriddenBy: l.priceOverriddenBy,
            discount: _discount(l.discountDetail),
            orderShare: l.orderDiscountShare,
            cost: l.costTotal,
          ),
      ],
      refunds: [
        for (final r in refunds)
          SaleRefundNote(
            refundId: r.id,
            number: r.number,
            at: r.createdAt,
            byName: r.staffName,
            reason: r.reason,
            total: r.total,
            approverName: r.approverName,
          ),
      ],
      orderDiscount: _discount(s.orderDiscount),
      voidedAt: s.voidedAt,
      voidedBy: s.voidedBy,
    );
  }

  static Discount? _discount(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      return Discount.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<RefundReceiptData?> refund(String refundId) async {
    final r = await (_db.select(_db.refunds)..where((t) => t.id.equals(refundId))).getSingleOrNull();
    if (r == null) return null;
    final lines = await (_db.select(_db.refundLines)
          ..where((l) => l.refundId.equals(refundId) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final payments = await (_db.select(_db.refundPayments)
          ..where((p) => p.refundId.equals(refundId) & p.deletedAt.isNull()))
        .get();
    return RefundReceiptData(
      refundId: r.id,
      number: r.number,
      at: r.createdAt,
      byName: r.staffName,
      reason: r.reason,
      saleNumber: r.saleNumber,
      lines: [
        for (final l in lines)
          (
            l.variantName == null || l.variantName!.isEmpty ? l.productName : '${l.productName} (${l.variantName})',
            l.quantity,
            l.sellBy,
            l.amount,
          ),
      ],
      total: r.total,
      payments: [for (final p in payments) (p.methodName, p.amount)],
      paidCash: payments.any((p) => p.method == PaymentMethod.cash),
    );
  }

  /// The sale before this one on this device, for "Reprint last".
  Future<String?> lastSaleId(String deviceId) async {
    final row = await (_db.select(_db.sales)
          ..where((s) => s.deviceId.equals(deviceId) & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.number)])
          ..limit(1))
        .getSingleOrNull();
    return row?.id;
  }
}
