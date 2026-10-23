import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/business_day.dart';
import '../../core/tax.dart';
import '../../core/units.dart';
import '../../domain/pricing.dart';
import '../../models/audit.dart';
import '../../models/cart_line.dart';
import '../../models/discount.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'day_close_repository.dart';
import 'stock_repository.dart';

/// Thrown when a sale cannot be saved as asked. Nothing has been written.
class SaleException implements Exception {
  const SaleException(this.message);
  final String message;

  @override
  String toString() => 'SaleException: $message';
}

class SaleRepository {
  SaleRepository(this._db, this._stock, this._closes, this._audit, this._device);

  final AppDatabase _db;
  final StockRepository _stock;
  final DayCloseRepository _closes;
  final AuditRepository _audit;
  final DeviceInfo _device;

  /// Saves a sale with its lines, discounts, taxes, payment, stock
  /// movements (from recipes) and outbox rows in one transaction: all of it
  /// is written, or none of it. Discounts and price overrides are audited.
  Future<CompletedSale> completeSale({
    required List<CartLine> lines,
    required PaymentInput payment,
    required Staff cashier,
    TaxMode taxMode = TaxMode.off,
    Discount? orderDiscount,
    String? note,
    OrderType? orderType,
  }) async {
    if (lines.isEmpty) throw const SaleException('The cart is empty.');
    if (lines.any((l) => l.quantity < 1)) {
      throw const SaleException('Every line needs a quantity of at least 1.');
    }
    if (lines.any((l) => l.unitPrice < 0)) throw const SaleException('A price cannot be negative.');
    final pricing = CartPricing.of(lines, orderDiscount: orderDiscount, taxMode: taxMode);
    final subtotal = pricing.subtotal;
    final taxTotal = pricing.taxTotal;
    final total = pricing.total;
    final change = _validatePayment(payment, total);
    final cleanNote = note?.trim().isEmpty ?? true ? null : note!.trim();

    return _db.transaction(() async {
      final now = DateTime.now();
      final saleId = newId();
      final number = await _nextSaleNumber();

      await _db.insertTracked(
        _db.sales,
        SalesCompanion.insert(
          id: saleId,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          number: number,
          status: SaleStatus.completed,
          subtotal: subtotal,
          total: total,
          taxTotal: Value(taxTotal),
          cashierId: Value(cashier.id),
          cashierName: cashier.name,
          discountTotal: Value(pricing.discountTotal),
          orderDiscount: Value(
            orderDiscount == null || pricing.orderDiscountAmount == 0 ? null : jsonEncode(orderDiscount.toJson()),
          ),
          note: Value(cleanNote),
          orderType: Value(orderType),
        ),
      );

      // Stock used, summed per stock item across the sale.
      final used = <String, int>{};
      final costs = <String, int>{};
      for (final priced in pricing.lines) {
        final line = priced.line;
        var lineCost = 0;
        // Recipes are per one sold, or per kg / litre for weighed lines.
        Future<void> consume(List<(String, int, int)> recipe) async {
          for (final (item, qty, costMilli) in recipe) {
            final take = line.weighed ? (qty * line.quantity + 500) ~/ 1000 : qty * line.quantity;
            used[item] = (used[item] ?? 0) + take;
            costs[item] = costMilli;
            lineCost += costOf(take, costMilli);
          }
        }

        await consume(await _recipe(variantId: line.variant.id));
        for (final option in line.options) {
          await consume(await _recipe(optionId: option.id));
        }

        await _db.insertTracked(
          _db.saleLines,
          SaleLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            saleId: saleId,
            productId: line.product.id,
            variantId: Value(line.variant.id),
            productName: line.product.name,
            variantName: Value(line.variant.name),
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            lineTotal: line.lineTotal,
            addons: Value([
              for (final o in line.options) SoldAddon(id: o.id, name: o.name, price: o.priceDelta),
            ]),
            costTotal: Value(lineCost),
            taxTotal: Value(priced.tax.taxTotal),
            sellBy: Value(line.product.sellBy),
            listPrice: Value(line.customPrice == null ? null : line.listPrice),
            priceOverriddenBy: Value(line.priceOverriddenBy),
            discount: Value(line.discountAmount),
            orderDiscountShare: Value(priced.orderShare),
            discountDetail: Value(line.discount == null ? null : jsonEncode(line.discount!.toJson())),
            note: Value(line.note?.trim().isEmpty ?? true ? null : line.note!.trim()),
          ),
        );
      }

      for (final MapEntry(key: item, value: qty) in used.entries) {
        await _stock.record(
          stockItemId: item,
          quantityChange: -qty,
          reason: StockReason.sale,
          unitCostMilli: costs[item],
          saleId: saleId,
          byName: cashier.name,
          at: now,
        );
      }

      // Tax per rate, for the tax report.
      final byRate = <String, (TaxRateSpec, int)>{};
      for (final t in pricing.lines.expand((l) => l.tax.taxes)) {
        final prev = byRate[t.rate.id];
        byRate[t.rate.id] = (t.rate, (prev?.$2 ?? 0) + t.amount);
      }
      for (final (rate, amount) in byRate.values) {
        await _db.insertTracked(
          _db.saleTaxes,
          SaleTaxesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            saleId: saleId,
            taxRateId: rate.id,
            name: rate.name,
            rateBp: rate.rateBp,
            amount: amount,
          ),
        );
      }

      await _db.insertTracked(
        _db.payments,
        PaymentsCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          saleId: saleId,
          method: payment.method,
          amount: total,
          tendered: Value(payment.tendered),
          changeGiven:
              Value(payment.method == PaymentMethod.cash ? change : null),
          momoReference: Value(payment.momoReference?.trim()),
          customer: Value(payment.customer?.trim()),
        ),
      );

      await _auditAdjustments(pricing, orderDiscount, saleId: saleId, number: number, cashier: cashier);

      // TODO(print): hand the saved sale to the receipt printer here.
      return CompletedSale(
        saleId: saleId,
        number: number,
        total: total,
        method: payment.method,
        changeDue: change,
      );
    });
  }

  /// One entry for the discounts on a sale and one for price overrides, so
  /// the owner can see who gave what away.
  Future<void> _auditAdjustments(
    CartPricing pricing,
    Discount? orderDiscount, {
    required String saleId,
    required int number,
    required Staff cashier,
  }) async {
    final saleNo = formatSaleNumber(number);
    if (pricing.discountTotal > 0) {
      final parts = [
        for (final l in pricing.lines.where((l) => l.line.discountAmount > 0))
          '${l.line.title} ${formatMoney(l.line.discountAmount)} (${_discountText(l.line.discount!)})',
        if (pricing.orderDiscountAmount > 0)
          'order ${formatMoney(pricing.orderDiscountAmount)} (${_discountText(orderDiscount!)})',
      ];
      await _audit.record(
        action: AuditAction.discountsGiven,
        actor: cashier,
        entity: 'sales',
        entityId: saleId,
        summary: '$saleNo: ${formatMoney(pricing.discountTotal)} off. ${parts.join('; ')}',
        details: {'discountTotal': pricing.discountTotal, 'subtotal': pricing.subtotal},
      );
    }
    final overridden = pricing.lines.where((l) => l.line.priceOverridden).toList();
    if (overridden.isNotEmpty) {
      final parts = [
        for (final l in overridden)
          '${l.line.title} ${formatMoney(l.line.listPrice)} to ${formatMoney(l.line.unitPrice)} '
              '(allowed by ${l.line.priceOverriddenBy})',
      ];
      await _audit.record(
        action: AuditAction.priceOverridden,
        actor: cashier,
        entity: 'sales',
        entityId: saleId,
        summary: '$saleNo: ${parts.join('; ')}',
      );
    }
  }

  static String _discountText(Discount d) => [
        d.name ?? d.label,
        d.reason,
        if (d.approvedBy != null) 'approved by ${d.approvedBy}',
      ].join(', ');

  /// The products sold most recently on this till, newest first.
  Future<List<String>> recentProductIds({int limit = 8}) async {
    final rows = await _db.customSelect(
      'SELECT l.product_id AS id, MAX(s.number) AS last FROM sale_lines l '
      'JOIN sales s ON s.id = l.sale_id '
      'WHERE s.device_id = ? AND s.deleted_at IS NULL AND l.deleted_at IS NULL '
      'GROUP BY l.product_id ORDER BY last DESC LIMIT ?',
      variables: [Variable.withString(_device.deviceId), Variable.withInt(limit)],
      readsFrom: {_db.sales, _db.saleLines},
    ).get();
    return [for (final r in rows) r.read<String>('id')];
  }

  /// (stock item, quantity, cost per base unit now) for a variant or option.
  Future<List<(String, int, int)>> _recipe({String? variantId, String? optionId}) async {
    final rows = await _db.customSelect(
      'SELECT r.stock_item_id AS item, r.quantity AS qty, s.cost_milli AS cost '
      'FROM recipe_items r JOIN stock_items s ON s.id = r.stock_item_id '
      'WHERE r.deleted_at IS NULL AND ${variantId != null ? 'r.variant_id' : 'r.option_id'} = ?',
      variables: [Variable.withString(variantId ?? optionId!)],
      readsFrom: {_db.recipeItems, _db.stockItems},
    ).get();
    return [for (final r in rows) (r.read<String>('item'), r.read<int>('qty'), r.read<int>('cost'))];
  }

  /// Returns the change due, or throws if the payment is not acceptable.
  int _validatePayment(PaymentInput payment, int total) {
    switch (payment.method) {
      case PaymentMethod.cash:
        final tendered = payment.tendered ?? 0;
        if (tendered < total) {
          throw const SaleException('Cash given is less than the total.');
        }
        return tendered - total;
      case PaymentMethod.momo:
        if ((payment.momoReference ?? '').trim().isEmpty) {
          throw const SaleException('Enter the MoMo transaction reference.');
        }
        return 0;
      case PaymentMethod.credit:
        if ((payment.customer ?? '').trim().isEmpty) {
          throw const SaleException('Enter the customer name or phone.');
        }
        return 0;
    }
  }

  Future<int> _nextSaleNumber() async {
    final max = _db.sales.number.max();
    final query = _db.selectOnly(_db.sales)
      ..addColumns([max])
      ..where(_db.sales.deviceId.equals(_device.deviceId));
    final current = await query.map((r) => r.read(max)).getSingle();
    return (current ?? 0) + 1;
  }

  /// Marks a sale as voided and puts its items back into stock. Records who
  /// asked ([actor]) and who approved, if someone else did ([approver]).
  /// One transaction, with outbox and audit rows. Sales in a closed day are
  /// locked.
  Future<void> voidSale(String saleId, {required Staff actor, Staff? approver, String? reason}) {
    final by = approver ?? actor;
    return _db.transaction(() async {
      final sale = await (_db.select(_db.sales)
            ..where((s) => s.id.equals(saleId)))
          .getSingleOrNull();
      if (sale == null) throw const SaleException('Sale not found.');
      if (sale.status == SaleStatus.voided) {
        throw const SaleException('This sale is already voided.');
      }
      if (sale.deviceId == _device.deviceId &&
          sale.number <= await _closes.closedUpTo()) {
        throw const SaleException(
            "This sale is in a closed day, so it can't be voided.");
      }

      final now = DateTime.now();
      await _db.updateTracked(
        _db.sales,
        sale.copyWith(
          status: SaleStatus.voided,
          voidedAt: Value(now),
          voidedById: Value(by.id),
          voidedBy: Value(by.name),
          updatedAt: now,
        ),
      );

      // Put back exactly what the sale took (stock items from v5, products
      // for older sales).
      final taken = await (_db.select(_db.stockMovements)
            ..where((m) => m.saleId.equals(saleId) & m.reason.equalsValue(StockReason.sale)))
          .get();
      for (final m in taken) {
        await _stock.record(
          stockItemId: m.stockItemId,
          productId: m.productId,
          variantId: m.variantId,
          quantityChange: -m.quantityChange,
          reason: StockReason.adjustment,
          unitCostMilli: m.unitCostMilli,
          saleId: saleId,
          note: 'Void ${formatSaleNumber(sale.number)}',
          byName: by.name,
          at: now,
        );
      }
      await _audit.record(
        action: AuditAction.saleVoided,
        actor: actor,
        approver: approver,
        entity: 'sales',
        entityId: saleId,
        summary: 'Voided ${formatSaleNumber(sale.number)} (${formatMoney(sale.total)})'
            '${reason == null || reason.trim().isEmpty ? '' : ': ${reason.trim()}'}',
      );
    });
  }

  /// Sales created from [from] (inclusive) to [to] (exclusive), newest first,
  /// with payments and item counts. Updates when sales change.
  Stream<List<Sale>> watchSales({required DateTime from, required DateTime to}) {
    final query = _db.select(_db.sales)
      ..where((s) =>
          s.deletedAt.isNull() &
          s.createdAt.isBiggerOrEqualValue(from) &
          s.createdAt.isSmallerThanValue(to))
      ..orderBy([
        (s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
        (s) => OrderingTerm(expression: s.number, mode: OrderingMode.desc),
      ]);
    return query.watch().asyncMap(_withDetails);
  }

  /// Sales in the current business day (see BusinessDay).
  Stream<List<Sale>> watchToday({required int dayStartMinutes}) {
    final day = BusinessDay.containing(DateTime.now(), startMinutes: dayStartMinutes);
    return watchSales(from: day.start, to: day.end);
  }

  Future<List<Sale>> _withDetails(List<SaleRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();

    final payments = await (_db.select(_db.payments)
          ..where((p) => p.saleId.isIn(ids) & p.deletedAt.isNull()))
        .get();
    final paymentsBySale = <String, List<Payment>>{};
    for (final p in payments) {
      paymentsBySale.putIfAbsent(p.saleId, () => []).add(Payment(
            id: p.id,
            method: p.method,
            amount: p.amount,
            tendered: p.tendered,
            changeGiven: p.changeGiven,
            momoReference: p.momoReference,
            customer: p.customer,
          ));
    }

    final qty = _db.saleLines.quantity.sum();
    final countQuery = _db.selectOnly(_db.saleLines)
      ..addColumns([_db.saleLines.saleId, qty])
      ..where(_db.saleLines.saleId.isIn(ids) & _db.saleLines.deletedAt.isNull())
      ..groupBy([_db.saleLines.saleId]);
    final counts = {
      for (final r in await countQuery.get())
        r.read(_db.saleLines.saleId)!: r.read(qty) ?? 0,
    };

    return [
      for (final r in rows)
        Sale(
          id: r.id,
          number: r.number,
          status: r.status,
          total: r.total,
          itemCount: counts[r.id] ?? 0,
          createdAt: r.createdAt,
          cashierName: r.cashierName,
          deviceId: r.deviceId,
          payments: paymentsBySale[r.id] ?? const [],
          voidedAt: r.voidedAt,
          voidedBy: r.voidedBy,
        ),
    ];
  }
}
