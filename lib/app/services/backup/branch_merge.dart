import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/sync/row_store.dart';
import '../../models/audit.dart';
import '../../models/staff.dart';
import 'backup_service.dart';

/// What a merge did.
class MergeResult {
  const MergeResult({required this.read, required this.changed, required this.skipped});

  /// Rows in the file.
  final int read;

  /// Rows that were new here, or newer than what was here.
  final int changed;

  /// Rows this database could not take.
  final int skipped;
}

/// Brings another branch's data in from its backup file (DAT-03, MDV-02):
/// the same file a backup makes, carried across when the branches have no
/// network between them. Unlike a restore, nothing here is replaced: each
/// row is merged, the later edit winning, as the hub does. A safety backup
/// is made first. What came in is queued to go on to the hub (or the cloud).
class BranchMerge {
  BranchMerge(this._db, this._audit, this._backups);

  final AppDatabase _db;
  final AuditRepository _audit;
  final BackupService _backups;

  Future<MergeResult> merge(BackupPreview preview, {Staff? by}) async {
    await _backups.createLocalBackup(by: by);
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    // Opening it brings an older file up to this version first.
    final other = AppDatabase(DatabaseConnection(NativeDatabase(File(preview.databasePath))), false);
    try {
      final theirs = RowStore(other);
      final ours = RowStore(_db);
      var read = 0, changed = 0, skipped = 0;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _db.transaction(() async {
        await for (final w in theirs.everything()) {
          read++;
          try {
            if (!await ours.apply(w)) continue;
          } on Object {
            skipped++;
            continue;
          }
          changed++;
          await _db.customInsert(
            "INSERT INTO outbox (entity, record_id, operation, payload, created_at) VALUES (?, ?, 'update', '{}', ?)",
            variables: [Variable.withString(w.entity), Variable.withString(w.id), Variable.withInt(now)],
            updates: {_db.outbox},
          );
        }
        await _audit.record(
          action: AuditAction.branchDataMerged,
          actor: by,
          entity: 'backup',
          summary: 'Brought in data from ${preview.shopName}: $changed changes ($read rows read, $skipped skipped)',
        );
      });
      return MergeResult(read: read, changed: changed, skipped: skipped);
    } finally {
      await other.close();
    }
  }
}
