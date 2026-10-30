import 'dart:io';
import 'dart:isolate';

import 'package:get/get.dart';
import 'package:sqlite3/sqlite3.dart';

import '../app.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../models/audit.dart';
import '../models/staff.dart';
import 'demo_photos.dart';
import 'training_seeder.dart';

/// What training practises on: a pretend shop of the same kind, with a
/// month of trading (TrainingSeeder), or a copy of the shop itself.
enum TrainingData { sample, shop }

/// Training mode (APP-05): the till runs on a copy of the shop's data, so
/// new cashiers can practise. The copy keeps the shop's staff and settings,
/// and either its own products and history or a sample shop's
/// ([TrainingData]). Sales, refunds and stock movements stay in the copy,
/// never in the real books, reports, backups or sync. Leaving training goes
/// back to the real data untouched.
class TrainingService extends GetxService {
  TrainingService(
    this._db, {
    Future<File> Function()? realFile,
    Future<File> Function()? trainingFile,
    Future<File> Function()? markerFile,
    Future<void> Function()? restart,
    Future<void> Function(File copy)? seed,
    this._audit,
  })  : _realFile = realFile ?? databaseFile,
        _trainingFile = trainingFile ?? trainingDatabaseFile,
        _markerFile = markerFile ?? trainingMarkerFile,
        _restart = restart ?? AppRestarter.restart,
        _seed = seed ?? ((copy) => TrainingSeeder.seedFile(copy, photo: loadSamplePhoto));

  final AppDatabase _db;
  final Future<File> Function() _realFile;
  final Future<File> Function() _trainingFile;
  final Future<File> Function() _markerFile;
  final Future<void> Function() _restart;
  final Future<void> Function(File copy) _seed;
  final AuditRepository? _audit;

  /// Written into the copy, so the open database knows it is for training.
  static const metaKey = 'training_mode';

  /// Which [TrainingData] the copy was made with, so a reset makes the same.
  static const dataKey = 'training_data';

  final active = false.obs;
  final data = TrainingData.sample.obs;

  /// Reads whether the open database is the training copy, and of what.
  Future<void> load() async {
    active.value = await _db.readMeta(metaKey) == '1';
    // Copies from before the sample shops are copies of the shop.
    data.value = TrainingData.values.asNameMap()[await _db.readMeta(dataKey)] ?? TrainingData.shop;
  }

  /// Marks a fresh copy as training and empties its outbox, so nothing in
  /// it is ever sent anywhere.
  static void _markCopy(String path, TrainingData data) {
    final db = sqlite3.open(path);
    try {
      db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [metaKey, '1']);
      db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [dataKey, data.name]);
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

  /// Copies the real data (filling it with the sample shop for
  /// [TrainingData.sample]) and restarts on the copy. Noted in the real
  /// activity log first: what happens in training stays in the copy.
  Future<void> enter({Staff? by, TrainingData data = TrainingData.sample}) async {
    await _audit?.record(
      action: AuditAction.trainingStarted,
      actor: by,
      summary: data == TrainingData.sample ? 'Started training mode with a sample shop' : 'Started training mode',
    );
    final copy = await _trainingFile();
    await _deleteWithSidecars(copy);
    await _db.customStatement('VACUUM INTO ?', [copy.path]);
    if (data == TrainingData.sample) await _seed(copy);
    final path = copy.path;
    await Isolate.run(() => _markCopy(path, data));
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

  /// Throws the practice away: a fresh copy of the real data, made the way
  /// this one was.
  Future<void> reset() async {
    final made = data.value;
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
    });
    if (made == TrainingData.sample) await _seed(copy);
    await Isolate.run(() => _markCopy(to, made));
    await _restart();
  }
}
