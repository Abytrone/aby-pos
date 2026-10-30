import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../core/units.dart';
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

/// Stock counts (stocktakes). Each counted line remembers what the till
/// expected at that moment, so selling during a count is fine: sales after
/// a line is counted are simply on top of the correction.
class StockCountRepository {
  StockCountRepository(this._db, this._device, this._audit, this._stock);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final StockRepository _stock;

  Future<StockCount?> open() async {
    final row =
        await (_db.select(_db.stockCounts)
              ..where((c) => c.status.equalsValue(StockCountStatus.open) & c.deletedAt.isNull())
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toCount(row, await _lineCount(row.id));
  }

  Future<List<StockCount>> list({int limit = 30}) async {
    final rows =
        await (_db.select(_db.stockCounts)
              ..where((c) => c.deletedAt.isNull())
              ..orderBy([
                (c) => OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
                (c) => OrderingTerm(expression: c.id, mode: OrderingMode.desc),
              ])
              ..limit(limit))
            .get();
    return [for (final r in rows) _toCount(r, await _lineCount(r.id))];
  }

  Future<StockCount?> find(String id) async {
    final row = await (_db.select(_db.stockCounts)..where((c) => c.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toCount(row, await _lineCount(id));
  }

  Future<int> _lineCount(String countId) async {
    final n = _db.stockCountLines.id.count();
    final q = _db.selectOnly(_db.stockCountLines)
      ..addColumns([n])
      ..where(_db.stockCountLines.countId.equals(countId) & _db.stockCountLines.deletedAt.isNull());
    return await q.map((r) => r.read(n)).getSingle() ?? 0;
  }

  StockCount _toCount(StockCountRow r, int lines) => StockCount(
    id: r.id,
    status: r.status,
    startedAt: r.createdAt,
    startedByName: r.startedByName,
    blind: r.blind,
    lineCount: lines,
    postedAt: r.postedAt,
    postedByName: r.postedByName,
    note: r.note,
  );

  /// One open count at a time.
  Future<String> start({required bool blind, String? note, required Staff by}) async {
    if (await open() != null) throw const StockException('A stock count is already open.');
    final now = clock.now();
    final id = newId();
    await _db.insertTracked(
      _db.stockCounts,
      StockCountsCompanion.insert(
        id: id,
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        status: StockCountStatus.open,
        blind: Value(blind),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
        startedById: by.id,
        startedByName: by.name,
      ),
    );
    return id;
  }

  /// Every active stock item, with its count so far.
  Future<List<StockCountLine>> lines(String countId) async {
    final items =
        await (_db.select(_db.stockItems)
              ..where((s) => s.deletedAt.isNull() & s.active.equals(true))
              ..orderBy([(s) => OrderingTerm(expression: s.name)]))
            .get();
    final counted = {
      for (final l in await (_db.select(
        _db.stockCountLines,
      )..where((l) => l.countId.equals(countId) & l.deletedAt.isNull())).get())
        l.stockItemId: l,
    };
    return [
      for (final i in items)
        StockCountLine(
          stockItemId: i.id,
          name: i.name,
          unit: i.unit,
          costMilli: i.costMilli,
          expected: counted[i.id]?.expected,
          counted: counted[i.id]?.counted,
          countedByName: counted[i.id]?.countedByName,
        ),
    ];
  }

  /// Records (or corrects) how much was found. [quantity] in base units.
  Future<void> setCount(String countId, String stockItemId, int quantity, {required Staff by}) async {
    if (quantity < 0) throw const StockException('A count cannot be negative.');
    await _db.transaction(() async {
      final count = await find(countId);
      if (count?.status != StockCountStatus.open) throw const StockException('This count is closed.');
      final now = clock.now();
      final existing =
          await (_db.select(_db.stockCountLines)
                ..where((l) => l.countId.equals(countId) & l.stockItemId.equals(stockItemId) & l.deletedAt.isNull()))
              .getSingleOrNull();
      final expected = await _stock.onHand(stockItemId);
      if (existing == null) {
        await _db.insertTracked(
          _db.stockCountLines,
          StockCountLinesCompanion.insert(
            id: newId(),
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            countId: countId,
            stockItemId: stockItemId,
            expected: expected,
            counted: quantity,
            countedByName: by.name,
          ),
        );
      } else {
        await _db.updateTracked(
          _db.stockCountLines,
          existing.copyWith(expected: expected, counted: quantity, countedByName: by.name, updatedAt: now),
        );
      }
    });
  }

  /// Posts the differences to the stock ledger and closes the count.
  /// Returns the total value of the differences (pesewas, + found, − short).
  Future<int> post(String countId, {required Staff by}) {
    return _db.transaction(() async {
      final row = await (_db.select(_db.stockCounts)..where((c) => c.id.equals(countId))).getSingle();
      if (row.status != StockCountStatus.open) throw const StockException('This count is closed.');
      final lines = (await this.lines(countId)).where((l) => l.counted != null).toList();
      if (lines.isEmpty) throw const StockException('Nothing has been counted yet.');
      final now = clock.now();
      var value = 0;
      var changed = 0;
      for (final l in lines) {
        final diff = l.difference!;
        if (diff == 0) continue;
        changed++;
        value += costOf(diff, l.costMilli);
        await _stock.record(
          stockItemId: l.stockItemId,
          quantityChange: diff,
          reason: StockReason.count,
          unitCostMilli: l.costMilli,
          refId: countId,
          byName: by.name,
          note: 'Counted ${formatQuantity(l.counted!, l.unit)}',
          at: now,
        );
      }
      await _db.updateTracked(
        _db.stockCounts,
        row.copyWith(
          status: StockCountStatus.posted,
          postedAt: Value(now),
          postedById: Value(by.id),
          postedByName: Value(by.name),
          updatedAt: now,
        ),
      );
      await _audit.record(
        action: AuditAction.stockCountPosted,
        actor: by,
        entity: 'stock_counts',
        entityId: countId,
        summary:
            'Stock count: ${lines.length} counted, $changed different, '
            '${value == 0 ? 'no change in value' : '${value > 0 ? 'found' : 'short'} ${formatMoney(value.abs())}'}',
        details: {'counted': lines.length, 'changed': changed, 'value': value},
      );
      return value;
    });
  }

  Future<void> cancel(String countId, {required Staff by}) {
    return _db.transaction(() async {
    final row = await (_db.select(_db.stockCounts)..where((c) => c.id.equals(countId))).getSingle();
    if (row.status != StockCountStatus.open) return;
    await _db.updateTracked(
      _db.stockCounts,
      row.copyWith(status: StockCountStatus.cancelled, updatedAt: clock.now()),
    );
      await _audit.record(
        action: AuditAction.stockCountCancelled,
        actor: by,
        entity: 'stock_counts',
        entityId: countId,
        summary: 'Stock count from ${row.createdAt.toIso8601String().substring(0, 10)} cancelled before posting',
      );
    });
  }
}
