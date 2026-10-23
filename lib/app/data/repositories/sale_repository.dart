import 'package:drift/drift.dart';

import '../../core/business_day.dart';
import '../../models/audit.dart';
import '../../models/cart_line.dart';
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

  /// Saves a sale with its lines, payment, stock movements and outbox rows
  /// in one transaction: all of it is written, or none of it.
  Future<CompletedSale> completeSale({
    required List<CartLine> lines,
    required PaymentInput payment,
    required Staff cashier,
  }) async {
    if (lines.isEmpty) throw const SaleException('The cart is empty.');
    if (lines.any((l) => l.quantity < 1)) {
      throw const SaleException('Every line needs a quantity of at least 1.');
    }
    final total = lines.fold(0, (sum, l) => sum + l.lineTotal);
    final change = _validatePayment(payment, total);

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
          subtotal: total,
          total: total,
          cashierId: Value(cashier.id),
          cashierName: cashier.name,
        ),
      );

      for (final line in lines) {
        await _db.insertTracked(
          _db.saleLines,
          SaleLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            saleId: saleId,
            productId: line.product.id,
            variantId: Value(line.variant?.id),
            productName: line.product.name,
            variantName: Value(line.variant?.name),
            quantity: line.quantity,
            unitPrice: line.unitPrice,
            lineTotal: line.lineTotal,
            addons: Value([
              for (final a in line.addons)
                SoldAddon(id: a.id, name: a.name, price: a.price),
            ]),
          ),
        );
        await _stock.record(
          productId: line.product.id,
          variantId: line.variant?.id,
          quantityChange: -line.quantity,
          reason: StockReason.sale,
          saleId: saleId,
          at: now,
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

      final lines = await (_db.select(_db.saleLines)
            ..where((l) => l.saleId.equals(saleId)))
          .get();
      for (final line in lines) {
        await _stock.record(
          productId: line.productId,
          variantId: line.variantId,
          quantityChange: line.quantity,
          reason: StockReason.adjustment,
          saleId: saleId,
          note: 'Void ${formatSaleNumber(sale.number)}',
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
