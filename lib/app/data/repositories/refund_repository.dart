import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/units.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/refund.dart';
import '../../models/sale.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'customer_repository.dart';
import 'stock_repository.dart';

class RefundException implements Exception {
  const RefundException(this.message);
  final String message;

  @override
  String toString() => 'RefundException: $message';
}

/// Refunds and returns. Each refund is its own record linked to the sale,
/// which is never changed. Items go back into stock unless marked damaged.
class RefundRepository {
  RefundRepository(this._db, this._device, this._audit, this._stock, [this._customers]);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final StockRepository _stock;
  final CustomerRepository? _customers;

  /// A sale on this device by its number ("#00142" or "142").
  Future<String?> saleIdByNumber(String text) async {
    final n = int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null) return null;
    final row = await (_db.select(_db.sales)
          ..where((s) => s.deviceId.equals(_device.deviceId) & s.number.equals(n) & s.deletedAt.isNull()))
        .getSingleOrNull();
    return row?.id;
  }

  /// The sale with what each line paid and what has already come back.
  Future<RefundableSale?> refundable(String saleId) async {
    final sale = await (_db.select(_db.sales)..where((s) => s.id.equals(saleId))).getSingleOrNull();
    if (sale == null) return null;
    final lines = await (_db.select(_db.saleLines)
          ..where((l) => l.saleId.equals(saleId) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final payments = await (_db.select(_db.payments)..where((p) => p.saleId.equals(saleId) & p.deletedAt.isNull()))
        .get();
    final back = await _db.customSelect(
      'SELECT rl.sale_line_id AS line, SUM(rl.quantity) AS qty, SUM(rl.amount) AS amount '
      'FROM refund_lines rl JOIN refunds r ON r.id = rl.refund_id '
      'WHERE r.sale_id = ? AND r.deleted_at IS NULL AND rl.deleted_at IS NULL GROUP BY rl.sale_line_id',
      variables: [Variable.withString(saleId)],
      readsFrom: {_db.refunds, _db.refundLines},
    ).get();
    final refunded = {for (final r in back) r.read<String?>('line'): (r.read<int>('qty'), r.read<int>('amount'))};
    // Tax was added on top when the total is more than the lines after
    // discounts; then each line's tax is part of what it paid.
    final exclusive = sale.taxTotal > 0 && sale.total == sale.subtotal - sale.discountTotal + sale.taxTotal;
    return RefundableSale(
      saleId: sale.id,
      number: sale.number,
      at: sale.createdAt,
      cashierName: sale.cashierName,
      total: sale.total,
      voided: sale.status == SaleStatus.voided,
      customerId: sale.customerId,
      refundedTotal: refunded.values.fold(0, (s, r) => s + r.$2),
      payments: [
        for (final p in payments)
          Payment(id: p.id, method: p.method, methodName: p.methodName, amount: p.amount, momoReference: p.momoReference),
      ],
      lines: [
        for (final l in lines)
          RefundableLine(
            saleLineId: l.id,
            productId: l.productId,
            variantId: l.variantId,
            title: l.variantName == null ? l.productName : '${l.productName}, ${l.variantName}',
            optionsLine: _addonsLine(l.addons.map((a) => a.name)),
            sellBy: l.sellBy,
            sold: l.quantity,
            paid: l.lineTotal - l.discount - l.orderDiscountShare + (exclusive ? l.taxTotal : 0),
            refunded: refunded[l.id]?.$1 ?? 0,
            refundedAmount: refunded[l.id]?.$2 ?? 0,
          ),
      ],
    );
  }

  static String _addonsLine(Iterable<String> names) {
    final counts = <String, int>{};
    for (final n in names) {
      counts[n] = (counts[n] ?? 0) + 1;
    }
    return counts.entries.map((e) => e.value > 1 ? '${e.key} ×${e.value}' : e.key).join(', ');
  }

  /// Checks [d] and works out each line's amount. Returns the lines with
  /// amounts and the total. Nothing is saved.
  Future<(List<RefundLineDraft>, int)> price(RefundDraft d) async {
    if (d.reason.trim().isEmpty) throw const RefundException('Pick a reason.');
    final lines = d.lines.where((l) => l.quantity > 0).toList();
    if (lines.isEmpty) throw const RefundException('Choose what is coming back.');
    final priced = <RefundLineDraft>[];
    if (d.saleId != null) {
      final sale = await refundable(d.saleId!);
      if (sale == null) throw const RefundException('Sale not found.');
      if (sale.voided) throw const RefundException('This sale was voided: there is nothing to refund.');
      for (final draft in lines) {
        final line = sale.lines.where((l) => l.saleLineId == draft.saleLineId).firstOrNull;
        if (line == null) throw const RefundException('That item is not on this sale.');
        if (draft.quantity > line.left) {
          throw RefundException('Only ${line.quantityText(line.left)} of ${line.title} can still come back.');
        }
        if (line.weighed && draft.quantity != line.left) {
          throw RefundException('${line.title} was weighed: it comes back whole.');
        }
        priced.add(RefundLineDraft(
          saleLineId: line.saleLineId,
          productId: line.productId,
          variantId: line.variantId,
          name: line.title,
          quantity: draft.quantity,
          amount: line.amountFor(draft.quantity),
          sellBy: line.sellBy,
          restock: draft.restock,
        ));
      }
    } else {
      for (final draft in lines) {
        if (draft.name.trim().isEmpty) throw const RefundException('Name each item.');
        if ((draft.amount ?? 0) <= 0) throw RefundException('Enter the amount for ${draft.name}.');
        priced.add(draft);
      }
    }
    final total = priced.fold(0, (s, l) => s + l.amount!);
    if (total <= 0) throw const RefundException('There is nothing to give back.');
    return (priced, total);
  }

  /// Saves a refund. [payments] must add up to its total. Runs inside the
  /// caller's transaction when there is one (exchanges).
  Future<CompletedRefund> refund(
    RefundDraft d, {
    required List<RefundPaymentInput> payments,
    required Staff actor,
    Staff? approver,
    String? exchangeSaleId,
  }) {
    return _db.transaction(() async {
      final (lines, total) = await price(d);
      final paid = payments.fold(0, (s, p) => s + p.amount);
      if (paid != total) throw RefundException('The refund is ${formatMoney(total)}; ${formatMoney(paid)} is set to go back.');
      if (payments.any((p) => p.amount <= 0)) throw const RefundException('Each refund payment must be more than nothing.');

      final now = DateTime.now();
      final id = newId();
      final max = _db.refunds.number.max();
      final q = _db.selectOnly(_db.refunds)
        ..addColumns([max])
        ..where(_db.refunds.deviceId.equals(_device.deviceId));
      final number = ((await q.map((r) => r.read(max)).getSingle()) ?? 0) + 1;
      final sale = d.saleId == null ? null : await (_db.select(_db.sales)..where((s) => s.id.equals(d.saleId!))).getSingle();
      final by = approver ?? actor;
      final onAccount = payments.where((p) => p.method == PaymentMethod.credit || p.method == PaymentMethod.wallet);
      if (onAccount.isNotEmpty && (sale?.customerId == null || _customers == null)) {
        throw const RefundException('Only a sale with a customer can be refunded to their account or wallet.');
      }
      if (payments.any((p) => p.method == PaymentMethod.credit)) {
        final owedOnSale = await _db.customSelect(
          "SELECT COALESCE(SUM(amount), 0) AS v FROM customer_ledger WHERE sale_id = ? AND account = 'credit' AND deleted_at IS NULL",
          variables: [Variable.withString(sale!.id)],
          readsFrom: {_db.customerLedger},
        ).getSingle();
        final back = payments.where((p) => p.method == PaymentMethod.credit).fold(0, (s, p) => s + p.amount);
        if (back > owedOnSale.read<int>('v')) {
          throw const RefundException('More than was sold on credit cannot go back to the account. Give the rest another way.');
        }
      }

      await _db.insertTracked(
        _db.refunds,
        RefundsCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          number: number,
          saleId: Value(d.saleId),
          saleNumber: Value(sale?.number),
          total: total,
          reason: d.reason.trim(),
          note: Value(d.note?.trim().isEmpty ?? true ? null : d.note!.trim()),
          withoutReceipt: Value(d.withoutReceipt),
          exchangeSaleId: Value(exchangeSaleId),
          staffId: actor.id,
          staffName: actor.name,
          approverName: Value(approver?.name),
        ),
      );

      for (final l in lines) {
        await _db.insertTracked(
          _db.refundLines,
          RefundLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            refundId: id,
            saleLineId: Value(l.saleLineId),
            productId: Value(l.productId),
            variantId: Value(l.variantId),
            productName: l.name,
            variantName: Value(l.variantName),
            quantity: l.quantity,
            sellBy: Value(l.sellBy),
            amount: l.amount!,
            restocked: l.restock,
          ),
        );
        if (l.restock) await _restock(l, refundId: id, number: number, saleId: d.saleId, byName: by.name, at: now);
      }

      for (final p in payments) {
        await _db.insertTracked(
          _db.refundPayments,
          RefundPaymentsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            refundId: id,
            method: p.method,
            methodId: Value(p.methodId),
            methodName: p.methodName,
            amount: p.amount,
            reference: Value(p.reference?.trim().isEmpty ?? true ? null : p.reference!.trim()),
          ),
        );
      }

      for (final p in onAccount) {
        await _customers!.addEntry(
          customerId: sale!.customerId!,
          account: p.method == PaymentMethod.credit ? CustomerAccount.credit : CustomerAccount.wallet,
          kind: p.method == PaymentMethod.credit ? CustomerEntryKind.creditRefund : CustomerEntryKind.walletRefund,
          amount: p.method == PaymentMethod.credit ? -p.amount : p.amount,
          byName: by.name,
          saleId: sale.id,
          refundId: id,
          methodName: p.methodName,
        );
      }

      final display = formatRefundNumber(number);
      await _audit.record(
        action: AuditAction.refundGiven,
        actor: actor,
        approver: approver,
        entity: 'refunds',
        entityId: id,
        summary: '$display${sale == null ? ' without a receipt' : ' for ${formatSaleNumber(sale.number)}'}: '
            '${formatMoney(total)}, ${lines.length} ${lines.length == 1 ? 'item' : 'items'} '
            '(${payments.map((p) => '${p.methodName} ${formatMoney(p.amount)}').join(', ')}). ${d.reason.trim()}',
        details: {'total': total, 'withoutReceipt': d.withoutReceipt},
      );
      final paidBack = payments.where((p) => p.method != PaymentMethod.exchange).fold(0, (s, p) => s + p.amount);
      return CompletedRefund(refundId: id, number: number, total: total, paidBack: paidBack);
    });
  }

  /// Puts back what the line used: what the sale recorded, in proportion,
  /// or (for older sales and refunds without a receipt) today's recipe.
  Future<void> _restock(
    RefundLineDraft l, {
    required String refundId,
    required int number,
    required String? saleId,
    required String byName,
    required DateTime at,
  }) async {
    final back = <String, int>{};
    final saleLine = l.saleLineId == null
        ? null
        : await (_db.select(_db.saleLines)..where((x) => x.id.equals(l.saleLineId!))).getSingleOrNull();
    if (saleLine?.stockUsed != null) {
      final used = Map<String, dynamic>.from(jsonDecode(saleLine!.stockUsed!) as Map);
      for (final MapEntry(key: item, value: qty) in used.entries) {
        back[item] = ((qty as int) * l.quantity + saleLine.quantity ~/ 2) ~/ saleLine.quantity;
      }
    } else if (l.variantId != null) {
      final weighed = l.sellBy != SellBy.each;
      Future<void> add(List<(String, int, int)> recipe) async {
        for (final (item, qty, _) in recipe) {
          final take = weighed ? (qty * l.quantity + 500) ~/ 1000 : qty * l.quantity;
          back[item] = (back[item] ?? 0) + take;
        }
      }

      await add(await _stock.recipe(variantId: l.variantId));
      for (final a in saleLine?.addons ?? const <SoldAddon>[]) {
        await add(await _stock.recipe(optionId: a.id));
      }
    }
    for (final MapEntry(key: item, value: qty) in back.entries) {
      if (qty <= 0) continue;
      final row = await (_db.select(_db.stockItems)..where((s) => s.id.equals(item))).getSingleOrNull();
      await _stock.record(
        stockItemId: item,
        quantityChange: qty,
        reason: StockReason.returned,
        unitCostMilli: row?.costMilli,
        saleId: saleId,
        refId: refundId,
        note: 'Refund ${formatRefundNumber(number)}',
        byName: byName,
        at: at,
      );
    }
  }

  /// Refunds given back per sale, for lists.
  Future<Map<String, int>> refundedBySale(List<String> saleIds) async {
    if (saleIds.isEmpty) return const {};
    final sum = _db.refunds.total.sum();
    final q = _db.selectOnly(_db.refunds)
      ..addColumns([_db.refunds.saleId, sum])
      ..where(_db.refunds.saleId.isIn(saleIds) & _db.refunds.deletedAt.isNull())
      ..groupBy([_db.refunds.saleId]);
    return {for (final r in await q.get()) r.read(_db.refunds.saleId)!: r.read(sum) ?? 0};
  }

  /// Newest first. With [saleId], that sale's refunds only.
  Future<List<RefundSummary>> list({String? saleId, DateTime? from, int limit = 100}) async {
    final query = _db.select(_db.refunds)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([
        (r) => OrderingTerm(expression: r.createdAt, mode: OrderingMode.desc),
        (r) => OrderingTerm(expression: r.number, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    if (saleId != null) query.where((r) => r.saleId.equals(saleId));
    if (from != null) query.where((r) => r.createdAt.isBiggerOrEqualValue(from));
    final rows = await query.get();
    final pays = rows.isEmpty
        ? const <RefundPaymentRow>[]
        : await (_db.select(_db.refundPayments)..where((p) => p.refundId.isIn(rows.map((r) => r.id)))).get();
    return [
      for (final r in rows)
        RefundSummary(
          id: r.id,
          number: r.number,
          at: r.createdAt,
          total: r.total,
          staffName: r.staffName,
          reason: r.reason,
          saleNumber: r.saleNumber,
          approverName: r.approverName,
          withoutReceipt: r.withoutReceipt,
          methods: [for (final p in pays.where((p) => p.refundId == r.id)) p.methodName],
        ),
    ];
  }

  /// "3 pcs" and the like for a refund's lines.
  static String quantityText(int quantity, SellBy sellBy) =>
      sellBy == SellBy.each ? '$quantity' : formatQuantity(quantity, sellBy == SellBy.kg ? StockUnit.g : StockUnit.ml);
}
