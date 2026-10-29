import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/branch.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../branch_scope.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';
import 'stock_repository.dart';

/// Stock moved between branches (INV-10). Sending takes it off this
/// branch's stock at once; it is in transit until the other branch receives
/// it and says what arrived. The transfer reaches the other branch through
/// the hub, or in a branch file when there is no network between them.
class TransferRepository {
  TransferRepository(this._db, this._device, this._audit, this._stock);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final StockRepository _stock;

  Stream<void> watch() =>
      _db.tableUpdates(TableUpdateQuery.onAllTables([_db.stockTransfers, _db.stockTransferLines])).map((_) {});

  /// Newest first: transfers from or to this branch (or every one, for
  /// [allBranches]).
  Future<List<StockTransfer>> list({bool allBranches = false}) async {
    final here = await _db.branchOf(_device.deviceId);
    final query = _db.select(_db.stockTransfers)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]);
    if (!allBranches) query.where((t) => t.fromBranch.equals(here) | t.toBranch.equals(here));
    return _load(await query.get());
  }

  Future<StockTransfer?> find(String id) async {
    final rows = await (_db.select(_db.stockTransfers)..where((t) => t.id.equals(id))).get();
    final list = await _load(rows);
    return list.isEmpty ? null : list.single;
  }

  Future<List<StockTransfer>> _load(List<StockTransferRow> rows) async {
    if (rows.isEmpty) return const [];
    final ids = [for (final r in rows) r.id];
    final lines = await (_db.select(_db.stockTransferLines)
          ..where((l) => l.transferId.isIn(ids) & l.deletedAt.isNull())
          ..orderBy([(l) => OrderingTerm(expression: l.createdAt), (l) => OrderingTerm(expression: l.id)]))
        .get();
    final items = {for (final i in await _db.select(_db.stockItems).get()) i.id: i};
    final branches = {for (final b in await _db.select(_db.branches).get()) b.id: b.name};
    return [
      for (final r in rows)
        StockTransfer(
          id: r.id,
          fromBranch: r.fromBranch,
          toBranch: r.toBranch,
          fromName: branches[r.fromBranch] ?? r.fromBranch,
          toName: branches[r.toBranch] ?? r.toBranch,
          status: r.status,
          sentAt: r.createdAt,
          sentBy: r.sentBy,
          note: r.note,
          receivedAt: r.receivedAt,
          receivedBy: r.receivedBy,
          lines: [
            for (final l in lines)
              if (l.transferId == r.id)
                TransferLine(
                  id: l.id,
                  stockItemId: l.stockItemId,
                  itemName: items[l.stockItemId]?.name ?? '?',
                  unit: items[l.stockItemId]?.unit ?? StockUnit.piece,
                  quantitySent: l.quantitySent,
                  quantityReceived: l.quantityReceived,
                  unitCostMilli: l.unitCostMilli,
                ),
          ],
        ),
    ];
  }

  /// Sends [lines] (stock item → base units) to [toBranch].
  Future<StockTransfer> send({
    required String toBranch,
    required Map<String, int> lines,
    String? note,
    required Staff by,
  }) async {
    final from = await _db.branchOf(_device.deviceId);
    if (toBranch == from) throw const StockException('Choose another branch.');
    final to = await (_db.select(_db.branches)..where((b) => b.id.equals(toBranch))).getSingleOrNull();
    if (to == null || !to.active) throw const StockException('Choose an open branch.');
    final wanted = {for (final e in lines.entries) if (e.value > 0) e.key: e.value};
    if (wanted.isEmpty) throw const StockException('Add what to send.');
    return _db.transaction(() async {
      final now = DateTime.now();
      final id = newId();
      final items = {
        for (final i in await (_db.select(_db.stockItems)..where((s) => s.id.isIn(wanted.keys))).get()) i.id: i,
      };
      await _db.insertTracked(
        _db.stockTransfers,
        StockTransfersCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          fromBranch: from,
          toBranch: toBranch,
          status: TransferStatus.sent,
          sentBy: by.name,
          note: Value(note == null || note.trim().isEmpty ? null : note.trim()),
        ),
      );
      for (final MapEntry(key: itemId, value: qty) in wanted.entries) {
        final cost = items[itemId]?.costMilli ?? 0;
        await _db.insertTracked(
          _db.stockTransferLines,
          StockTransferLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            transferId: id,
            stockItemId: itemId,
            quantitySent: qty,
            unitCostMilli: Value(cost),
          ),
        );
        await _stock.record(
          stockItemId: itemId,
          quantityChange: -qty,
          reason: StockReason.transferOut,
          unitCostMilli: cost,
          refId: id,
          note: to.name,
          byName: by.name,
          at: now,
        );
      }
      final t = (await find(id))!;
      await _audit.record(
        action: AuditAction.stockTransferSent,
        actor: by,
        entity: 'stock_transfers',
        entityId: id,
        summary: '${t.code} to ${t.toName}: ${t.lines.length} items',
      );
      return t;
    });
  }

  /// The receiving branch says what arrived ([received]: line ID → base
  /// units; a line left out arrived in full). It goes into this branch's
  /// stock; any difference is flagged. Returns the transfer.
  Future<StockTransfer> receive(String id, {Map<String, int> received = const {}, required Staff by}) async {
    final t = await find(id);
    if (t == null) throw const StockException('Transfer not found.');
    if (t.status != TransferStatus.sent) throw const StockException('This transfer is already closed.');
    if (await _db.branchOf(_device.deviceId) != t.toBranch) {
      throw const StockException('Only the branch it was sent to can receive it.');
    }
    return _db.transaction(() async {
      final now = DateTime.now();
      for (final l in t.lines) {
        final got = received[l.id] ?? l.quantitySent;
        if (got < 0) throw const StockException('A quantity cannot be negative.');
        final row = await (_db.select(_db.stockTransferLines)..where((x) => x.id.equals(l.id))).getSingle();
        await _db.updateTracked(_db.stockTransferLines, row.copyWith(quantityReceived: Value(got), updatedAt: now));
        if (got > 0) {
          await _stock.record(
            stockItemId: l.stockItemId,
            quantityChange: got,
            reason: StockReason.transferIn,
            unitCostMilli: l.unitCostMilli,
            refId: id,
            note: t.fromName,
            byName: by.name,
            at: now,
          );
        }
      }
      final row = await (_db.select(_db.stockTransfers)..where((x) => x.id.equals(id))).getSingle();
      await _db.updateTracked(
        _db.stockTransfers,
        row.copyWith(status: TransferStatus.received, receivedAt: Value(now), receivedBy: Value(by.name), updatedAt: now),
      );
      final done = (await find(id))!;
      final short = [for (final l in done.lines) if (l.difference != 0) '${l.itemName} ${l.difference > 0 ? '+' : ''}${l.difference}'];
      await _audit.record(
        action: AuditAction.stockTransferReceived,
        actor: by,
        entity: 'stock_transfers',
        entityId: id,
        summary: '${done.code} from ${done.fromName}${short.isEmpty ? '' : ', differences: ${short.join(', ')}'}',
      );
      return done;
    });
  }

  /// Calls back a transfer not yet received: the stock comes back to the
  /// branch that sent it.
  Future<void> cancel(String id, {required Staff by}) async {
    final t = await find(id);
    if (t == null) throw const StockException('Transfer not found.');
    if (t.status != TransferStatus.sent) throw const StockException('This transfer is already closed.');
    if (await _db.branchOf(_device.deviceId) != t.fromBranch) {
      throw const StockException('Only the branch that sent it can call it back.');
    }
    await _db.transaction(() async {
      final now = DateTime.now();
      for (final l in t.lines) {
        await _stock.record(
          stockItemId: l.stockItemId,
          quantityChange: l.quantitySent,
          reason: StockReason.transferIn,
          unitCostMilli: l.unitCostMilli,
          refId: id,
          note: t.code,
          byName: by.name,
          at: now,
        );
      }
      final row = await (_db.select(_db.stockTransfers)..where((x) => x.id.equals(id))).getSingle();
      await _db.updateTracked(_db.stockTransfers, row.copyWith(status: TransferStatus.cancelled, updatedAt: now));
      await _audit.record(
        action: AuditAction.stockTransferCancelled,
        actor: by,
        entity: 'stock_transfers',
        entityId: id,
        summary: '${t.code} to ${t.toName} called back',
      );
    });
  }
}
