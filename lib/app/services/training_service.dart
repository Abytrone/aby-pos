import 'dart:io';
import 'dart:isolate';

import 'package:get/get.dart';
import 'package:sqlite3/sqlite3.dart';

import '../app.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../models/audit.dart';
import '../models/staff.dart';

/// Training mode (APP-05): the till runs on a copy of the shop's data, so
/// new cashiers can practise on real products. Sales, refunds and stock
/// movements stay in the copy, never in the real books, reports, backups or
/// sync. Leaving training goes back to the real data untouched.
class TrainingService extends GetxService {
  TrainingService(
    this._db, {
    Future<File> Function()? realFile,
    Future<File> Function()? trainingFile,
    Future<File> Function()? markerFile,
    Future<void> Function()? restart,
    this._audit,
  })  : _realFile = realFile ?? databaseFile,
        _trainingFile = trainingFile ?? trainingDatabaseFile,
        _markerFile = markerFile ?? trainingMarkerFile,
        _restart = restart ?? AppRestarter.restart;

  final AppDatabase _db;
  final Future<File> Function() _realFile;
  final Future<File> Function() _trainingFile;
  final Future<File> Function() _markerFile;
  final Future<void> Function() _restart;
  final AuditRepository? _audit;

  /// Written into the copy, so the open database knows it is for training.
  static const metaKey = 'training_mode';

  final active = false.obs;

  /// Reads whether the open database is the training copy.
  Future<void> load() async => active.value = await _db.readMeta(metaKey) == '1';

  /// Marks a fresh copy as training and empties its outbox, so nothing in
  /// it is ever sent anywhere.
  static void _markCopy(String path) {
    final db = sqlite3.open(path);
    try {
      db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [metaKey, '1']);
      db.execute('DELETE FROM outbox');
    } finally {
      db.close();
    }
  }

  static Future<void> _deleteWithSidecars(File f) async {
    for (final path in [f.path, '${f.path}-wal', '${f.path}-shm', '${f.path}-journal']) {
      final x = File(path);
      if (await x.exists()) await x.delete();
    }
  }

  /// Copies the real data and restarts on the copy. Noted in the real
  /// activity log first: what happens in training stays in the copy.
  Future<void> enter({Staff? by}) async {
    await _audit?.record(action: AuditAction.trainingStarted, actor: by, summary: 'Started training mode');
    final copy = await _trainingFile();
    await _deleteWithSidecars(copy);
    await _db.customStatement('VACUUM INTO ?', [copy.path]);
    final path = copy.path;
    await Isolate.run(() => _markCopy(path));
    await (await _markerFile()).writeAsString('training');
    await _db.close();
    await _restart();
  }

  /// Back to the real data; the training copy stays until the next time.
  Future<void> leave() async {
    final marker = await _markerFile();
    if (await marker.exists()) await marker.delete();
    await _db.close();
    await _restart();
  }

  /// Throws the practice away: a fresh copy of the real data.
  Future<void> reset() async {
    await _db.close();
    final copy = await _trainingFile();
    await _deleteWithSidecars(copy);
    final from = (await _realFile()).path, to = copy.path;
    await Isolate.run(() {
      final real = sqlite3.open(from, mode: OpenMode.readOnly);
      try {
        real.execute('VACUUM INTO ?', [to]);
      } finally {
        real.close();
      }
      _markCopy(to);
    });
    await _restart();
  }
}
