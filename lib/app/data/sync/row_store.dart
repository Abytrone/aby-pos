import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// One row on the wire: its table and its database columns.
class WireRow {
  const WireRow(this.entity, this.id, this.row);

  factory WireRow.fromJson(Map<String, dynamic> j) =>
      WireRow(j['e'] as String, j['i'] as String, (j['r'] as Map).cast<String, Object?>());

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
      if (_required.every({for (final c in t.$columns) c.name}.contains)) t.actualTableName: t,
  };

  Future<Map<String, Object?>?> read(String entity, String id) async {
    final t = synced[entity];
    if (t == null) return null;
    final rows = await _db.customSelect('SELECT * FROM $entity WHERE id = ?', variables: [Variable.withString(id)], readsFrom: {t}).get();
    return rows.isEmpty ? null : rows.single.data;
  }

  /// Up to [limit] outbox entries, as the rows they changed (latest state,
  /// one per row).
  Future<PendingBatch> pending({int limit = 300}) async {
    final entries = await (_db.select(_db.outbox)
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
    final count = await _db.customSelect('SELECT COUNT(*) AS n FROM outbox').getSingle();
    return count.read<int>('n');
  }

  /// Every synced row, for a hub's starting change log.
  Stream<WireRow> everything() async* {
    for (final MapEntry(key: name, value: t) in synced.entries) {
      final rows = await _db.customSelect('SELECT * FROM $name', readsFrom: {t}).get();
      for (final r in rows) {
        yield WireRow(name, r.data['id'] as String, r.data);
      }
    }
  }

  /// Applies a row from another device unless this device has a later
  /// version. Never writes to the outbox (it came from elsewhere). Returns
  /// whether the row changed; false for an older version, an unknown table
  /// or a row that breaks a rule here (logged by the caller).
  Future<bool> apply(WireRow w) async {
    final t = synced[w.entity];
    if (t == null) return false;
    final known = {for (final c in t.$columns) c.name};
    final cols = [for (final c in w.row.keys) if (known.contains(c)) c];
    if (!cols.contains('id') || !cols.contains('updated_at')) return false;
    final placeholders = List.filled(cols.length, '?').join(', ');
    final assignments = [for (final c in cols) if (c != 'id') '$c = excluded.$c'].join(', ');
    final sql = 'INSERT INTO ${w.entity} (${cols.join(', ')}) VALUES ($placeholders) '
        'ON CONFLICT(id) DO UPDATE SET $assignments '
        'WHERE excluded.updated_at > ${w.entity}.updated_at '
        'OR (excluded.updated_at = ${w.entity}.updated_at AND excluded.device_id >= ${w.entity}.device_id)';
    final before = await read(w.entity, w.id);
    await _db.customInsert(sql, variables: [for (final c in cols) _variable(w.row[c])], updates: {t});
    final after = await read(w.entity, w.id);
    return jsonEncode(before) != jsonEncode(after);
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
