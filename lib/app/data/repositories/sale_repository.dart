import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/business_day.dart';
import '../../core/tax.dart';
import '../../core/units.dart';
import '../../domain/loyalty.dart';
import '../../domain/orders.dart';
import '../../domain/pricing.dart';
import '../../domain/promotions.dart';
import '../../domain/settlement.dart';
import '../../models/audit.dart';
import '../../models/cart_line.dart';
import '../../models/customer.dart';
import '../../models/discount.dart';
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
import 'day_close_repository.dart';
import 'refund_repository.dart';
import 'stock_repository.dart';
import 'voucher_repository.dart';

/// Thrown when a sale cannot be saved as asked. Nothing has been written.
class SaleException implements Exception {
  const SaleException(this.message);
  final String message;

  @override
  String toString() => 'SaleException: $message';
}

/// Items coming back as part of a sale (an exchange). Their value pays for
/// the new items; anything left over goes back by [payBack].
class ExchangeInput {
  const ExchangeInput({required this.returned, this.payBack, this.approver});

  final RefundDraft returned;

  /// How the difference goes back when the returned items are worth more.
  final PayMethod? payBack;

  /// Who approved the refund, when the cashier could not.
  final Staff? approver;
}

class SaleRepository {
  SaleRepository(
    this._db,
    this._stock,
    this._closes,
    this._audit,
    this._device, [
    this._refunds,
    this._customers,
    this._vouchers,
  ]);

  final AppDatabase _db;
  final StockRepository _stock;
  final DayCloseRepository _closes;
  final AuditRepository _audit;
  final DeviceInfo _device;
  final RefundRepository? _refunds;
  final CustomerRepository? _customers;
  final VoucherRepository? _vouchers;

  /// Short references (the last 4 of a MoMo ID) repeat over time, so they
  /// are only checked for reuse over this window.
  static const shortReferenceWindow = Duration(hours: 48);

  /// Saves a sale with its lines, discounts, taxes, payments, stock
  /// movements (from recipes) and outbox rows in one transaction: all of it
  /// is written, or none of it. Discounts and price overrides are audited.
  ///
  /// [payments] are taken in order (a split payment); [payment] is the
  /// one-payment shorthand. [roundTo] rounds a final cash payment to the
  /// nearest 10 or 50 pesewas. With [exchange], the returned items are
  /// refunded in the same transaction and their value pays first.
  Future<CompletedSale> completeSale({
    required List<CartLine> lines,
    PaymentInput? payment,
    List<PaymentInput> payments = const [],
    required Staff cashier,
    TaxMode taxMode = TaxMode.off,
    Discount? orderDiscount,
    String? note,
    OrderType? orderType,
    int roundTo = 0,
    ExchangeInput? exchange,
    Customer? customer,
    bool changeToWallet = false,
    Staff? creditApprover,
    List<Promotion> promotions = const [],
    LoyaltyConfig loyalty = const LoyaltyConfig(),
    OrderConfig? orders,
  }) async {
    if (lines.isEmpty) throw const SaleException('The cart is empty.');
    if (lines.any((l) => l.quantity < 1)) {
      throw const SaleException('Every line needs a quantity of at least 1.');
    }
    if (lines.any((l) => l.unitPrice < 0)) throw const SaleException('A price cannot be negative.');
    // The customer's loyalty reward, worked out as the cart showed it.
    final status = loyalty.on && customer != null && _customers != null
        ? await _customers.loyaltyStatus(customer.id, loyalty, byName: cashier.name)
        : null;
    final promoted = Loyalty.apply(lines, promotions, clock.now(), loyalty, status);
    final pricing = CartPricing.of(lines, orderDiscount: orderDiscount, taxMode: taxMode, promotions: promoted);
    final subtotal = pricing.subtotal;
    final taxTotal = pricing.taxTotal;
    final total = pricing.total;
    final cleanNote = note?.trim().isEmpty ?? true ? null : note!.trim();

    // An exchange: what comes back pays first.
    var credit = 0;
    if (exchange != null) {
      final refunds = _refunds;
      if (refunds == null) throw StateError('Exchanges need the refund repository.');
      try {
        credit = (await refunds.price(exchange.returned)).$2;
      } on RefundException catch (e) {
        throw SaleException(e.message);
      }
    }
    final fromExchange = credit < total ? credit : total;
    // Credit and wallet payments are on the attached customer's account.
    PaymentInput forCustomer(PaymentInput p) =>
        customer == null || p.method != PaymentMethod.credit || (p.customer ?? '').trim().isNotEmpty
            ? p
            : PaymentInput(
                method: p.method,
                methodId: p.methodId,
                methodName: p.methodName,
                amount: p.amount,
                customer: customer.name,
              );
    final tenders = [
      if (fromExchange > 0) PaymentInput(method: PaymentMethod.exchange, methodName: 'Exchange', amount: fromExchange),
      for (final p in [...payments, ?payment]) forCustomer(p),
    ];
    final onAccount = tenders.any((p) => p.method == PaymentMethod.credit || p.method == PaymentMethod.wallet);
    if (onAccount && customer == null && _customers != null) {
      throw const SaleException('Choose the customer: credit and wallet payments go on their account.');
    }
    final Settlement settlement;
    try {
      settlement = Settlement.of(total, tenders, roundTo: roundTo);
    } on PaymentException catch (e) {
      throw SaleException(e.message);
    }
    if (credit > total && exchange?.payBack == null) {
      throw const SaleException('Choose how to give back the difference.');
    }

    return _db.transaction(() async {
      for (final p in settlement.payments) {
        await _checkReference(p.input);
      }
      final account = customer == null ? null : await _customers?.find(customer.id);
      if (customer != null && account == null) throw const SaleException('Customer not found.');
      for (final p in settlement.payments) {
        if (p.input.method == PaymentMethod.wallet && p.amount > account!.wallet) {
          throw SaleException('${account.name} has ${formatMoney(account.wallet)} in their wallet.');
        }
        if (p.input.method == PaymentMethod.credit && account != null) {
          final limit = account.creditLimit;
          if (limit != null && account.owed + p.amount > limit && creditApprover == null) {
            throw SaleException(
              'This takes ${account.name} over their credit limit of ${formatMoney(limit)} '
              '(they owe ${formatMoney(account.owed)}).',
            );
          }
        }
      }
      // Change kept in the wallet stays in the drawer.
      final kept = changeToWallet && account != null ? settlement.change : 0;
      final now = clock.now();
      final saleId = newId();
      final number = await _nextSaleNumber();
      final orderNumber = orders != null && orders.needsPrep(lines) ? await _nextOrderNumber(orders, now) : null;

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
          rounding: Value(settlement.rounding),
          customerId: Value(customer?.id),
          orderNumber: Value(orderNumber),
          orderStatus: Value(orderNumber == null ? null : OrderStatus.fresh),
          orderStatusAt: Value(orderNumber == null ? null : now),
        ),
      );

      // Stock used, summed per stock item across the sale.
      final used = <String, int>{};
      final costs = <String, int>{};
      for (final priced in pricing.lines) {
        final line = priced.line;
        var lineCost = 0;
        final lineUsed = <String, int>{};
        // Recipes are per one sold, or per kg / litre for weighed lines.
        Future<void> consume(List<(String, int, int)> recipe) async {
          for (final (item, qty, costMilli) in recipe) {
            final take = line.weighed ? (qty * line.quantity + 500) ~/ 1000 : qty * line.quantity;
            used[item] = (used[item] ?? 0) + take;
            lineUsed[item] = (lineUsed[item] ?? 0) + take;
            costs[item] = costMilli;
            lineCost += costOf(take, costMilli);
          }
        }

        await consume(await _stock.recipe(variantId: line.variant.id));
        for (final option in line.options) {
          final own = await _stock.recipe(optionId: option.id);
          // A combo part with no recipe of its own uses its product's.
          final linked = option.variantId;
          await consume(own.isEmpty && linked != null ? await _stock.recipe(variantId: linked) : own);
        }
        // No recipe: the cost typed on the product (per one, or per kg / litre).
        final manual = line.variant.manualCost;
        if (line.variant.recipe.isEmpty && manual != null) {
          lineCost += line.weighed ? (manual * line.quantity + 500) ~/ 1000 : manual * line.quantity;
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
            // Manual and promotion discounts; promotion says how much was which.
            discount: Value(line.discountAmount + priced.promotion),
            promotion: Value(priced.promotion),
            promotionName: Value(priced.promotionNames.isEmpty ? null : priced.promotionNames.join(', ')),
            orderDiscountShare: Value(priced.orderShare),
            discountDetail: Value(line.discount == null ? null : jsonEncode(line.discount!.toJson())),
            note: Value(line.note?.trim().isEmpty ?? true ? null : line.note!.trim()),
            stockUsed: Value(lineUsed.isEmpty ? null : jsonEncode(lineUsed)),
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

      CompletedRefund? returned;
      if (exchange != null) {
        returned = await _refunds!.refund(
          exchange.returned,
          payments: [
            if (fromExchange > 0)
              RefundPaymentInput(
                method: PaymentMethod.exchange,
                methodName: 'Exchange',
                amount: fromExchange,
                reference: formatSaleNumber(number),
              ),
            if (credit > total)
              RefundPaymentInput(
                method: exchange.payBack!.kind,
                methodId: exchange.payBack!.id,
                methodName: exchange.payBack!.name,
                amount: credit - total,
              ),
          ],
          actor: cashier,
          approver: exchange.approver,
          exchangeSaleId: saleId,
        );
      }

      for (final p in settlement.payments) {
        final input = p.input;
        if (input.method == PaymentMethod.voucher) {
          try {
            await _vouchers!.spend(input.reference ?? '', p.amount, saleId: saleId, byName: cashier.name);
          } on VoucherException catch (e) {
            throw SaleException(e.message);
          }
        }
        final ref = input.reference == null ? null : Settlement.cleanReference(input.reference!);
        await _db.insertTracked(
          _db.payments,
          PaymentsCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            saleId: saleId,
            method: input.method,
            amount: p.amount,
            tendered: Value(input.method == PaymentMethod.cash ? (input.tendered ?? p.amount) : null),
            changeGiven: Value(input.method == PaymentMethod.cash ? p.change - (p.change > 0 ? kept : 0) : null),
            momoReference: Value(input.method == PaymentMethod.exchange ? returned?.displayNumber : (ref?.isEmpty ?? true) ? null : ref),
            customer: Value(input.customer?.trim()),
            methodId: Value(input.methodId),
            methodName: Value(input.methodName ?? input.method.label),
          ),
        );
      }

      if (account != null) {
        final customers = _customers!;
        for (final p in settlement.payments) {
          if (p.input.method == PaymentMethod.credit) {
            await customers.addEntry(
              customerId: account.id,
              account: CustomerAccount.credit,
              kind: CustomerEntryKind.creditSale,
              amount: p.amount,
              byName: cashier.name,
              saleId: saleId,
              at: now,
              dueOn: account.dueDays == null ? null : now.add(Duration(days: account.dueDays!)),
              methodName: p.input.label,
              approverName: creditApprover?.name,
            );
          } else if (p.input.method == PaymentMethod.wallet) {
            await customers.addEntry(
              customerId: account.id,
              account: CustomerAccount.wallet,
              kind: CustomerEntryKind.walletSpend,
              amount: -p.amount,
              byName: cashier.name,
              saleId: saleId,
              at: now,
              methodName: p.input.label,
            );
          }
        }
        if (kept > 0) {
          await customers.addEntry(
            customerId: account.id,
            account: CustomerAccount.wallet,
            kind: CustomerEntryKind.changeKept,
            amount: kept,
            byName: cashier.name,
            saleId: saleId,
            at: now,
            method: PaymentMethod.cash,
            methodName: 'Cash',
          );
        }
        if (loyalty.on) {
          final used = Loyalty.redeemed(loyalty, promoted);
          if (used > 0) {
            await customers.addEntry(
              customerId: account.id,
              account: CustomerAccount.loyalty,
              kind: CustomerEntryKind.loyaltyRedeem,
              amount: -used,
              byName: cashier.name,
              saleId: saleId,
              at: now,
            );
          }
          final got = Loyalty.earned(loyalty, lines, promoted, total);
          if (got > 0) {
            await customers.addEntry(
              customerId: account.id,
              account: CustomerAccount.loyalty,
              kind: CustomerEntryKind.loyaltyEarn,
              amount: got,
              byName: cashier.name,
              saleId: saleId,
              at: now,
            );
          }
        }
        if (creditApprover != null) {
          await _audit.record(
            action: AuditAction.customerCreditLimit,
            actor: cashier,
            approver: creditApprover,
            entity: 'sales',
            entityId: saleId,
            summary: '${formatSaleNumber(number)} on credit over ${account.name}\'s limit',
          );
        }
      }

      await _auditAdjustments(pricing, orderDiscount, saleId: saleId, number: number, cashier: cashier);

      // The checkout hands the saved sale to PrintService.afterSale.
      final main = settlement.payments.where((p) => p.input.method != PaymentMethod.exchange).firstOrNull ??
          settlement.payments.first;
      return CompletedSale(
        saleId: saleId,
        number: number,
        total: total,
        method: main.input.method,
        changeDue: settlement.change - kept,
        changeKept: kept,
        rounding: settlement.rounding,
        paymentLabels: [for (final p in settlement.payments) '${p.input.label} ${formatMoney(p.amount)}'],
        exchangeRefund: returned,
        orderNumber: orderNumber,
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

  /// A transaction reference may only be used once: the same SMS shown
  /// twice is a payment taken twice. Short references are checked over
  /// [shortReferenceWindow] only.
  Future<void> _checkReference(PaymentInput p) async {
    // A gift voucher's code is used until its balance runs out.
    if (p.method == PaymentMethod.voucher) {
      if (_vouchers == null) throw const SaleException('Gift vouchers are not available here.');
      try {
        await _vouchers.check(p.reference ?? '', p.amount ?? 0);
      } on VoucherException catch (e) {
        throw SaleException(e.message);
      }
      return;
    }
    if (!p.needsReference || p.reference == null) return;
    final ref = Settlement.cleanReference(p.reference!);
    if (ref.isEmpty) return;
    final rows = await _db.customSelect(
      'SELECT s.number AS number, s.device_id AS device FROM payments p JOIN sales s ON s.id = p.sale_id '
      "WHERE UPPER(REPLACE(p.momo_reference, ' ', '')) = ? AND s.status = 'completed' "
      'AND p.deleted_at IS NULL AND s.deleted_at IS NULL AND p.created_at >= ? LIMIT 1',
      variables: [
        Variable.withString(ref),
        Variable.withDateTime(p.shortReference ? clock.now().subtract(shortReferenceWindow) : DateTime(2000)),
      ],
      readsFrom: {_db.payments, _db.sales},
    ).get();
    if (rows.isNotEmpty) {
      throw SaleException('This reference was already used on sale ${formatSaleNumber(rows.first.read<int>('number'))}.');
    }
  }

  /// The next queue number on this device in today's business day.
  Future<int> _nextOrderNumber(OrderConfig orders, DateTime now) async {
    final day = BusinessDay.containing(now, startMinutes: orders.dayStartMinutes);
    final row = await _db.customSelect(
      'SELECT COALESCE(MAX(order_number), 0) AS n FROM sales WHERE device_id = ? AND created_at >= ? AND deleted_at IS NULL',
      variables: [Variable.withString(_device.deviceId), Variable.withDateTime(day.start)],
      readsFrom: {_db.sales},
    ).getSingle();
    return row.read<int>('n') + 1;
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
      final refunded = await (_db.select(_db.refunds)
            ..where((r) => r.saleId.equals(saleId) & r.deletedAt.isNull())
            ..limit(1))
          .getSingleOrNull();
      if (refunded != null) {
        throw const SaleException('Part of this sale was refunded, so it cannot be voided. Refund the rest instead.');
      }
      if (sale.deviceId == _device.deviceId &&
          sale.number <= await _closes.closedUpTo()) {
        throw const SaleException(
            "This sale is in a closed day, so it can't be voided.");
      }

      final now = clock.now();
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
      // Credit owed, wallet money, stamps, points and vouchers go back too.
      await _customers?.reverseSale(saleId, byName: by.name, saleNumber: formatSaleNumber(sale.number));
      await _vouchers?.reverseSale(saleId, byName: by.name);
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
  /// with payments, item counts and refunds. Updates when sales or refunds
  /// change.
  Stream<List<Sale>> watchSales({required DateTime from, required DateTime to}) async* {
    final query = _db.select(_db.sales)
      ..where((s) =>
          s.deletedAt.isNull() &
          s.createdAt.isBiggerOrEqualValue(from) &
          s.createdAt.isSmallerThanValue(to))
      ..orderBy([
        (s) => OrderingTerm(expression: s.createdAt, mode: OrderingMode.desc),
        (s) => OrderingTerm(expression: s.number, mode: OrderingMode.desc),
      ]);
    yield await _withDetails(await query.get());
    await for (final _ in _db.tableUpdates(TableUpdateQuery.onAllTables([_db.sales, _db.refunds]))) {
      yield await _withDetails(await query.get());
    }
  }

  /// Sales in the current business day (see BusinessDay).
  Stream<List<Sale>> watchToday({required int dayStartMinutes}) {
    final day = BusinessDay.containing(clock.now(), startMinutes: dayStartMinutes);
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
            methodName: p.methodName,
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

    final refundSum = _db.refunds.total.sum();
    final refundQuery = _db.selectOnly(_db.refunds)
      ..addColumns([_db.refunds.saleId, refundSum])
      ..where(_db.refunds.saleId.isIn(ids) & _db.refunds.deletedAt.isNull())
      ..groupBy([_db.refunds.saleId]);
    final refunded = {
      for (final r in await refundQuery.get()) r.read(_db.refunds.saleId)!: r.read(refundSum) ?? 0,
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
          refunded: refunded[r.id] ?? 0,
        ),
    ];
  }
}
