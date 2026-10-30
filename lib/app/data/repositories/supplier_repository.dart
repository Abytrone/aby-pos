import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/purchasing.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'stock_repository.dart';

/// Suppliers and what the shop owes them. The balance is the sum of the
/// ledger, never a stored number.
class SupplierRepository {
  SupplierRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<Map<String, int>> _balances() async {
    final sum = _db.supplierLedger.amount.sum();
    final query = _db.selectOnly(_db.supplierLedger)
      ..addColumns([_db.supplierLedger.supplierId, sum])
      ..where(_db.supplierLedger.deletedAt.isNull())
      ..groupBy([_db.supplierLedger.supplierId]);
    return {for (final r in await query.get()) r.read(_db.supplierLedger.supplierId)!: r.read(sum) ?? 0};
  }

  Future<List<Supplier>> list({bool includeInactive = false}) async {
    final query = _db.select(_db.suppliers)
      ..where((s) => s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm(expression: s.name)]);
    if (!includeInactive) query.where((s) => s.active.equals(true));
    final balances = await _balances();
    return [for (final r in await query.get()) _toSupplier(r, balances[r.id] ?? 0)];
  }

  Future<Supplier?> find(String id) async {
    final row = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSupplier(row, (await _balances())[id] ?? 0);
  }

  Supplier _toSupplier(SupplierRow r, int balance) => Supplier(
    id: r.id,
    name: r.name,
    phone: r.phone,
    email: r.email,
    address: r.address,
    notes: r.notes,
    paymentTermsDays: r.paymentTermsDays,
    active: r.active,
    balance: balance,
  );

  /// Newest first.
  Future<List<SupplierEntry>> ledger(String supplierId, {int limit = 100}) async {
    final rows =
        await (_db.select(_db.supplierLedger)
              ..where((e) => e.supplierId.equals(supplierId) & e.deletedAt.isNull())
              ..orderBy([
                (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
                (e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc),
              ])
              ..limit(limit))
            .get();
    return [
      for (final r in rows)
        SupplierEntry(
          id: r.id,
          at: r.createdAt,
          kind: r.kind,
          amount: r.amount,
          byName: r.byName,
          method: r.method,
          receiptId: r.receiptId,
          reference: r.reference,
          note: r.note,
        ),
    ];
  }

  Future<String> save(SupplierDraft d, {required Staff by}) async {
    final name = d.name.trim();
    if (name.isEmpty) throw const StockException('Enter the supplier name.');
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    return _db.transaction(() async {
      final now = clock.now();
      final id = d.id ?? newId();
      if (d.id == null) {
        await _db.insertTracked(
          _db.suppliers,
          SuppliersCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: name,
            phone: Value(clean(d.phone)),
            email: Value(clean(d.email)),
            address: Value(clean(d.address)),
            notes: Value(clean(d.notes)),
            paymentTermsDays: Value(d.paymentTermsDays),
          ),
        );
      } else {
        final row = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingle();
        await _db.updateTracked(
          _db.suppliers,
          row.copyWith(
            name: name,
            phone: Value(clean(d.phone)),
            email: Value(clean(d.email)),
            address: Value(clean(d.address)),
            notes: Value(clean(d.notes)),
            paymentTermsDays: Value(d.paymentTermsDays),
            updatedAt: now,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.supplierSaved,
        actor: by,
        entity: 'suppliers',
        entityId: id,
        summary: '${d.id == null ? 'Added' : 'Changed'} supplier $name',
      );
      return id;
    });
  }

  Future<void> setActive(String id, {required bool active, required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.suppliers)..where((s) => s.id.equals(id))).getSingle();
      await _db.updateTracked(_db.suppliers, row.copyWith(active: active, updatedAt: clock.now()));
      await _audit.record(
        action: AuditAction.supplierSaved,
        actor: by,
        entity: 'suppliers',
        entityId: id,
        summary: '${active ? 'Restored' : 'Retired'} supplier ${row.name}',
      );
    });
  }

  /// Adds an entry inside the caller's transaction (deliveries use this).
  Future<void> addEntry({
    required String supplierId,
    required SupplierEntryKind kind,
    required int amount,
    required String byName,
    SupplierPaymentMethod? method,
    String? receiptId,
    String? reference,
    String? note,
  }) async {
    final now = clock.now();
    await _db.insertTracked(
      _db.supplierLedger,
      SupplierLedgerCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        supplierId: supplierId,
        kind: kind,
        amount: amount,
        method: Value(method),
        receiptId: Value(receiptId),
        reference: Value(reference),
        note: Value(note),
        byName: byName,
      ),
    );
  }

  /// Paying off what is owed (all or part).
  Future<void> recordPayment(
    String supplierId, {
    required int amount,
    required SupplierPaymentMethod method,
    String? reference,
    String? note,
    required Staff by,
  }) async {
    if (amount <= 0) throw const StockException('Enter the amount paid.');
    await _db.transaction(() async {
      final supplier = await find(supplierId);
      if (supplier == null) throw const StockException('Supplier not found.');
      await addEntry(
        supplierId: supplierId,
        kind: SupplierEntryKind.payment,
        amount: -amount,
        byName: by.name,
        method: method,
        reference: reference?.trim().isEmpty ?? true ? null : reference!.trim(),
        note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      );
      await _audit.record(
        action: AuditAction.supplierPaid,
        actor: by,
        entity: 'suppliers',
        entityId: supplierId,
        summary: 'Paid ${supplier.name} ${formatMoney(amount)} (${method.name})',
        details: {'amount': amount, 'owedBefore': supplier.balance},
      );
    });
  }
}
