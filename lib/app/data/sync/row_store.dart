import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../models/enums.dart';

/// One row on the wire: its table and its database columns.
class WireRow {
  const WireRow(this.entity, this.id, this.row);

  factory WireRow.fromJson(Map<String, dynamic> j) => WireRow(
    j['e'] as String,
    j['i'] as String,
    (j['r'] as Map).cast<String, Object?>(),
  );

  final String entity;
  final String id;
  final Map<String, Object?> row;

  Map<String, Object?> toJson() => {'e': entity, 'i': id, 'r': row};
}

/// Changes waiting to go, and the outbox entries they cover.
class PendingBatch {
  const PendingBatch(this.rows, this.outboxSeqs);

  final List<WireRow> rows;
  final List<int> outboxSeqs;

  bool get isEmpty => outboxSeqs.isEmpty;
}

/// Reads and writes synced rows generically, by table name, for the hub
/// (MDV-01). Every synced table has id, updated_at, deleted_at and
/// device_id; a row sent is the row as it is now, so several edits go as
/// one. Applying is last-write-wins on updated_at (the device ID breaks
/// ties), so every device ends up with the same row. Ledgers only ever add
/// rows, so they never meet a conflict.
class RowStore {
  RowStore(this._db);

  final AppDatabase _db;

  static const _required = {'id', 'updated_at', 'deleted_at', 'device_id'};

  late final Map<String, TableInfo<Table, Object?>> synced = {
    for (final t in _db.allTables)
      if (_required.every({for (final c in t.$columns) c.name}.contains))
        t.actualTableName: t,
  };

  Future<Map<String, Object?>?> read(String entity, String id) async {
    final t = synced[entity];
    if (t == null) return null;
    final rows = await _db
        .customSelect(
          'SELECT * FROM $entity WHERE id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {t},
        )
        .get();
    return rows.isEmpty ? null : rows.single.data;
  }

  /// Up to [limit] outbox entries, as the rows they changed (latest state,
  /// one per row).
  Future<PendingBatch> pending({int limit = 300}) async {
    final entries =
        await (_db.select(_db.outbox)
              ..orderBy([(o) => OrderingTerm(expression: o.seq)])
              ..limit(limit))
            .get();
    final seen = <String>{};
    final rows = <WireRow>[];
    for (final e in entries) {
      if (!seen.add('${e.entity}/${e.recordId}')) continue;
      final row = await read(e.entity, e.recordId);
      if (row != null) rows.add(WireRow(e.entity, e.recordId, row));
    }
    return PendingBatch(rows, [for (final e in entries) e.seq]);
  }

  Future<void> acknowledge(List<int> seqs) async {
    if (seqs.isEmpty) return;
    await (_db.delete(_db.outbox)..where((o) => o.seq.isIn(seqs))).go();
  }

  /// Puts every synced row in the outbox: a device joining a hub sends all
  /// it has (merge). Returns how many rows.
  Future<int> enqueueEverything() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _db.transaction(() async {
      for (final name in synced.keys) {
        await _db.customInsert(
          "INSERT INTO outbox (entity, record_id, operation, payload, created_at) SELECT '$name', id, 'update', '{}', ? FROM $name",
          variables: [Variable.withInt(now)],
          updates: {_db.outbox},
        );
      }
    });
    final count = await _db
        .customSelect('SELECT COUNT(*) AS n FROM outbox')
        .getSingle();
    return count.read<int>('n');
  }

  /// Every synced row, for a hub's starting change log.
  Stream<WireRow> everything() async* {
    for (final MapEntry(key: name, value: t) in synced.entries) {
      final rows = await _db
          .customSelect('SELECT * FROM $name', readsFrom: {t})
          .get();
      for (final r in rows) {
        yield WireRow(name, r.data['id'] as String, r.data);
      }
    }
  }

  /// Gives synced catalogue records a unique name on the receiving device.
  /// The hub sends this adjusted row to every member so they converge.
  Future<WireRow> uniqueNameRow(WireRow w) async {
    w = _trimName(w);
    if ((w.entity != 'products' && w.entity != 'stock_items') ||
        w.row['deleted_at'] != null ||
        w.row['name'] is! String) {
      return w;
    }

    final name = (w.row['name'] as String).trim();
    if (name.isEmpty) return w;
    Future<bool> taken(String candidate) async =>
        (await _db
                .customSelect(
                  'SELECT id FROM ${w.entity} '
                  'WHERE deleted_at IS NULL AND id != ? AND lower(trim(name)) = lower(trim(?)) LIMIT 1',
                  variables: [
                    Variable.withString(w.id),
                    Variable.withString(candidate),
                  ],
                )
                .get())
            .isNotEmpty;

    if (!await taken(name)) return w;
    var suffix = 2;
    var candidate = '$name ($suffix)';
    while (await taken(candidate)) {
      suffix++;
      candidate = '$name ($suffix)';
    }
    final row = Map<String, Object?>.of(w.row)..['name'] = candidate;
    return WireRow(w.entity, w.id, row);
  }

  /// Applies a row from another device unless this device has a later
  /// version. Returns whether the row changed; false for an older version,
  /// an unknown table or a row that breaks a rule here (logged by the caller).
  Future<bool> apply(WireRow w, {bool preferIncomingName = false}) async {
    final t = synced[w.entity];
    if (t == null) return false;
    w = _trimName(w);
    if (preferIncomingName) {
      await _makeRoomForIncomingName(w, t);
    } else {
      w = await uniqueNameRow(w);
    }
    final known = {for (final c in t.$columns) c.name};
    final cols = [
      for (final c in w.row.keys)
        if (known.contains(c)) c,
    ];
    if (!cols.contains('id') || !cols.contains('updated_at')) return false;
    final placeholders = List.filled(cols.length, '?').join(', ');
    final assignments = [
      for (final c in cols)
        if (c != 'id') '$c = excluded.$c',
    ].join(', ');
    final sql =
        'INSERT INTO ${w.entity} (${cols.join(', ')}) VALUES ($placeholders) '
        'ON CONFLICT(id) DO UPDATE SET $assignments '
        'WHERE excluded.updated_at > ${w.entity}.updated_at '
        'OR (excluded.updated_at = ${w.entity}.updated_at AND excluded.device_id >= ${w.entity}.device_id)';
    final before = await read(w.entity, w.id);
    await _db.customInsert(
      sql,
      variables: [for (final c in cols) _variable(w.row[c])],
      updates: {t},
    );
    final after = await read(w.entity, w.id);
    return jsonEncode(before) != jsonEncode(after);
  }

  WireRow _trimName(WireRow w) {
    if ((w.entity != 'products' && w.entity != 'stock_items') ||
        w.row['name'] is! String) {
      return w;
    }
    final trimmed = (w.row['name'] as String).trim();
    final name = trimmed.isEmpty
        ? (w.entity == 'products' ? 'Unnamed product' : 'Unnamed stock item')
        : trimmed;
    if (name == w.row['name']) return w;
    final row = Map<String, Object?>.of(w.row)..['name'] = name;
    return WireRow(w.entity, w.id, row);
  }

  Future<void> _makeRoomForIncomingName(
    WireRow w,
    TableInfo<Table, Object?> table,
  ) async {
    if ((w.entity != 'products' && w.entity != 'stock_items') ||
        w.row['deleted_at'] != null ||
        w.row['name'] is! String) {
      return;
    }

    final current = await read(w.entity, w.id);
    if (current != null) {
      final incomingTime = w.row['updated_at'];
      final currentTime = current['updated_at'];
      if (incomingTime is num && currentTime is num) {
        if (incomingTime < currentTime ||
            (incomingTime == currentTime &&
                '${w.row['device_id'] ?? ''}'.compareTo(
                      '${current['device_id'] ?? ''}',
                    ) <
                    0)) {
          return;
        }
      }
    }

    final name = (w.row['name'] as String).trim();
    if (name.isEmpty) return;
    final conflicts = await _db
        .customSelect(
          'SELECT id FROM ${w.entity} '
          'WHERE deleted_at IS NULL AND id != ? AND lower(trim(name)) = lower(trim(?))',
          variables: [Variable.withString(w.id), Variable.withString(name)],
        )
        .get();
    for (final conflict in conflicts) {
      final id = conflict.read<String>('id');
      var suffix = 2;
      var candidate = '$name ($suffix)';
      while ((await _db
              .customSelect(
                'SELECT id FROM ${w.entity} '
                'WHERE deleted_at IS NULL AND id NOT IN (?, ?) AND lower(trim(name)) = lower(trim(?)) LIMIT 1',
                variables: [
                  Variable.withString(w.id),
                  Variable.withString(id),
                  Variable.withString(candidate),
                ],
              )
              .get())
          .isNotEmpty) {
        suffix++;
        candidate = '$name ($suffix)';
      }

      final now = DateTime.now();
      await _db.customUpdate(
        'UPDATE ${w.entity} SET name = ?, updated_at = MAX(updated_at, ?, ?) + 1 WHERE id = ?',
        variables: [
          Variable.withString(candidate),
          Variable.withDateTime(now),
          if (w.row['updated_at'] is num)
            Variable.withInt((w.row['updated_at'] as num).toInt())
          else
            Variable.withDateTime(now),
          Variable.withString(id),
        ],
        updates: {table},
        updateKind: UpdateKind.update,
      );
      await _db
          .into(_db.outbox)
          .insert(
            OutboxCompanion.insert(
              entity: w.entity,
              recordId: id,
              operation: OutboxOperation.update,
              payload: '{}',
              createdAt: now,
            ),
          );
    }
  }

  static Variable<Object> _variable(Object? v) => switch (v) {
    null => const Variable(null),
    final int i => Variable.withInt(i),
    final double d => Variable.withReal(d),
    final bool b => Variable.withBool(b),
    final String s => Variable.withString(s),
    _ => Variable.withString(jsonEncode(v)),
  };
}
