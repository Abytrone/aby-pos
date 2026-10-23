import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Read side of the outbox. Rows are written by [AppDatabase.insertTracked]
/// and [AppDatabase.updateTracked] in the same transaction as the change.
class OutboxRepository {
  OutboxRepository(this._db);

  final AppDatabase _db;

  /// Number of sales with changes not yet sent. Counts each sale once, even
  /// if it was also voided.
  Stream<int> watchPendingSalesCount() {
    final count = _db.outbox.recordId.count(distinct: true);
    final query = _db.selectOnly(_db.outbox)
      ..addColumns([count])
      ..where(_db.outbox.entity.equals(_db.sales.actualTableName));
    return query.map((r) => r.read(count) ?? 0).watchSingle();
  }

  /// Oldest first, for the sync engine to send in order.
  Future<List<OutboxRow>> pending({int limit = 100}) =>
      (_db.select(_db.outbox)
            ..orderBy([(o) => OrderingTerm(expression: o.seq)])
            ..limit(limit))
          .get();

  // TODO(sync): call once the server confirms a batch, and stamp syncedAt on
  // the source rows in the same transaction.
  Future<void> acknowledge(List<int> seqs) =>
      (_db.delete(_db.outbox)..where((o) => o.seq.isIn(seqs))).go();
}
