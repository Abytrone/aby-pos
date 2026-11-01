import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../core/settings.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/audit_repository.dart';
import '../../models/audit.dart';
import '../../models/staff.dart';
import '../hub/hub_service.dart';
import '../pin_hasher.dart';
import '../settings_service.dart';
import '../training_service.dart';
import 'backup_codec.dart';

class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}

/// What a backup file holds, read before restoring it.
class BackupPreview {
  const BackupPreview({
    required this.databasePath,
    required this.shopName,
    required this.salesCount,
    required this.schemaVersion,
    this.lastSaleAt,
    this.temporary = false,
    this.fromThisDevice = true,
    this.linked = false,
  });

  /// A plain SQLite copy, ready to restore (decrypted if it came from an
  /// `.abybak`).
  final String databasePath;

  /// [databasePath] is a decrypted copy in the temp folder: delete it with
  /// [BackupService.discard] once done.
  final bool temporary;

  /// Made on this device (same device ID). When not, a restore asks whether
  /// this device replaces the one it came from.
  final bool fromThisDevice;

  /// The device it came from was the hub, or synced with one.
  final bool linked;

  final String shopName;
  final int salesCount;
  final int schemaVersion;
  final DateTime? lastSaleAt;
}

/// A backup kept on this device.
class LocalBackup {
  const LocalBackup({required this.file, required this.createdAt, required this.sizeBytes});

  final File file;
  final DateTime createdAt;
  final int sizeBytes;
}

/// Local snapshots (automatic and at day close), encrypted off-device
/// backups, and restore.
class BackupService extends GetxService {
  BackupService(
    this._db,
    this._audit,
    this._settings, {
    Future<Directory> Function()? backupsDirectory,
    Future<Directory> Function()? tempDirectory,
    Future<File> Function()? liveDatabaseFile,
    this.iterations = BackupCodec.defaultIterations,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _backupsDirectory = backupsDirectory ?? _defaultBackupsDirectory,
        _tempDirectory = tempDirectory ?? getTemporaryDirectory,
        _liveDatabaseFile = liveDatabaseFile ?? databaseFile;

  final AppDatabase _db;
  final AuditRepository _audit;
  final SettingsService _settings;
  final Future<Directory> Function() _backupsDirectory;
  final Future<Directory> Function() _tempDirectory;
  final Future<File> Function() _liveDatabaseFile;
  final DateTime Function() _clock;

  /// Key-stretching rounds for new `.abybak` files (lower in tests).
  final int iterations;

  static Future<Directory> _defaultBackupsDirectory() async =>
      Directory(p.join((await getApplicationSupportDirectory()).path, 'backups'));

  static const _localPrefix = 'aby-';
  static const _pendingRestoreKey = 'pending_restore_audit';
  static const minPasswordLength = 6;

  /// Set once [restore] has closed the database: the app must restart.
  bool closedForRestore = false;

  /// A backup is being written now (the header's dot pulses).
  final running = false.obs;

  /// When the newest local backup was made; changes the moment one finishes.
  final lastBackupAt = Rxn<DateTime>();

  /// The database's change counter when the last backup was taken: an
  /// automatic backup with nothing new to save is skipped.
  int? _changesAtLastBackup;

  Timer? _schedule;

  /// Where local backups are kept on this device.
  Future<Directory> backupsDirectory() => _backupsDirectory();

  /// Backups and restores belong to the real data, never the training copy.
  static bool get _training => Get.isRegistered<TrainingService>() && Get.find<TrainingService>().active.value;

  static void _refuseInTraining() {
    if (_training) throw const BackupException('Backups are for the real shop. Leave training mode first.');
  }

  // ---------------------------------------------------------------------------
  // Local snapshots

  /// Copies the live database (consistent, while open) and checks the copy.
  /// Keeps the newest [AppSettings.backupsToKeep].
  Future<LocalBackup> createLocalBackup({Staff? by, bool record = true}) async {
    _refuseInTraining();
    // One at a time: a backup asked for during an automatic one follows it.
    while (running.value) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    running.value = true;
    try {
      final dir = await _backupsDirectory();
      await dir.create(recursive: true);
      final now = _clock();
      final path = p.join(dir.path, '$_localPrefix${_stamp(now)}.sqlite');
      final file = File(path);
      if (await file.exists()) await file.delete();
      await _db.customStatement('VACUUM INTO ?', [path]);
      try {
        await _inspect(path);
      } catch (_) {
        if (await file.exists()) await file.delete();
        rethrow;
      }
      await _db.writeMeta(MetaKeys.lastLocalBackupAt, now.toUtc().toIso8601String());
      await _prune(dir);
      if (record) {
        await _audit.record(
          action: AuditAction.backupCreated,
          actor: by,
          entity: 'backup',
          entityId: p.basename(path),
          summary: by == null ? 'Automatic backup' : 'Backup made by ${by.name}',
        );
      }
      // Taken after this backup's own writes, so they do not count as news.
      _changesAtLastBackup = await _totalChanges();
      lastBackupAt.value = now;
      return LocalBackup(file: file, createdAt: now, sizeBytes: await file.length());
    } finally {
      running.value = false;
    }
  }

  /// Minutes between automatic backups ([AppSettings.backupEveryMinutes]).
  int get everyMinutes => _settings.get(AppSettings.backupEveryMinutes).clamp(1, minutesPerDay);

  static const minutesPerDay = 24 * 60;

  /// When the next automatic backup is due; null when they are off.
  DateTime? get nextBackupAt {
    if (!_settings.get(AppSettings.autoBackupDaily)) return null;
    final last = lastBackupAt.value;
    return last == null ? _clock() : last.add(Duration(minutes: everyMinutes));
  }

  /// The automatic backup, if it is switched on and due. Skipped when
  /// nothing has changed since the last one: that backup is still current.
  Future<LocalBackup?> autoBackupIfDue() async {
    if (!_settings.get(AppSettings.autoBackupDaily)) return null;
    // The training copy is never backed up.
    if (_training || running.value) return null;
    final last = await lastLocalBackupAt();
    lastBackupAt.value ??= last;
    final now = _clock();
    // A minute timer drifts a few seconds; a daily one waits from opening time.
    final dueAfter = everyMinutes >= minutesPerDay
        ? const Duration(hours: 20)
        : Duration(minutes: everyMinutes) - const Duration(seconds: 30);
    if (last != null && now.difference(last) < dueAfter) return null;
    if (_changesAtLastBackup != null && await _totalChanges() == _changesAtLastBackup) return null;
    // Only the day's first automatic backup goes in the activity log; one a
    // minute would bury everything else.
    final firstToday = last == null || _day(last) != _day(now);
    return createLocalBackup(record: firstToday);
  }

  /// Checks once a minute for a due automatic backup, for as long as the app
  /// is open. A failure is printed and tried again next minute; the status
  /// centre shows the backup as overdue if it keeps failing.
  void startSchedule() {
    _schedule?.cancel();
    Future<void> tick() async {
      try {
        await autoBackupIfDue();
      } catch (e) {
        debugPrint('Automatic backup failed: $e');
      }
    }

    unawaited(tick());
    _schedule = Timer.periodic(const Duration(minutes: 1), (_) => tick());
  }

  void stopSchedule() {
    _schedule?.cancel();
    _schedule = null;
  }

  @override
  void onClose() {
    stopSchedule();
    super.onClose();
  }

  Future<int> _totalChanges() async =>
      (await _db.customSelect('SELECT total_changes() AS n').getSingle()).read<int>('n');

  Future<List<LocalBackup>> listLocalBackups() async {
    final dir = await _backupsDirectory();
    if (!await dir.exists()) return const [];
    final backups = <LocalBackup>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!name.startsWith(_localPrefix) || !name.endsWith('.sqlite')) continue;
      final stat = await entity.stat();
      backups.add(LocalBackup(file: entity, createdAt: _parseStamp(name) ?? stat.modified, sizeBytes: stat.size));
    }
    backups.sort((a, b) => b.file.path.compareTo(a.file.path));
    return backups;
  }

  Future<DateTime?> lastLocalBackupAt() async =>
      DateTime.tryParse(await _db.readMeta(MetaKeys.lastLocalBackupAt) ?? '')?.toLocal();

  Future<DateTime?> lastOffsiteBackupAt() async =>
      DateTime.tryParse(await _db.readMeta(MetaKeys.lastOffsiteBackupAt) ?? '')?.toLocal();

  /// Keeps the newest [AppSettings.backupsToKeep] backups, and the last one
  /// of each earlier day until that many days are covered: backing up every
  /// minute still leaves something from last week.
  Future<void> _prune(Directory dir) async {
    final keep = _settings.get(AppSettings.backupsToKeep).clamp(1, 365);
    final all = await listLocalBackups();
    final days = {for (final b in all.take(keep)) _day(b.createdAt)};
    for (final old in all.skip(keep)) {
      if (days.length < keep && days.add(_day(old.createdAt))) continue;
      await old.file.delete();
    }
  }

  static DateTime _day(DateTime at) => DateTime(at.year, at.month, at.day);

  // ---------------------------------------------------------------------------
  // Backup password and off-device backups

  Future<bool> hasBackupPassword() async =>
      (await _db.readMeta(MetaKeys.backupPasswordHash)) != null;

  Future<bool> checkBackupPassword(String password) async {
    final stored = await _db.readMeta(MetaKeys.backupPasswordHash);
    return stored != null && PinHasher.verify(password, stored);
  }

  /// Only a hash is kept; the password itself is never stored.
  Future<void> setBackupPassword(String password) async {
    if (password.length < minPasswordLength) {
      throw const BackupException('Use at least $minPasswordLength characters.');
    }
    await _db.writeMeta(MetaKeys.backupPasswordHash, PinHasher.hash(password));
  }

  /// Makes a fresh snapshot and encrypts it. Returns the `.abybak` file in
  /// the temp folder, ready to share or save. Call [markOffsiteDone] once
  /// it has actually left the device.
  Future<File> exportEncrypted({
    required String password,
    required String shopName,
    required Staff by,
  }) async {
    if (!await checkBackupPassword(password)) {
      throw const BackupException("That isn't the backup password.");
    }
    final snapshot = await createLocalBackup(by: by, record: false);
    final encrypted = await BackupCodec.encrypt(
      await snapshot.file.readAsBytes(),
      password,
      iterations: iterations,
    );
    final tmp = await _tempDirectory();
    final safeShop = shopName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    final out = File(p.join(tmp.path, '${safeShop.isEmpty ? 'Aby' : safeShop}-${_stamp(DateTime.now())}.abybak'));
    await out.writeAsBytes(encrypted, flush: true);
    return out;
  }

  Future<void> markOffsiteDone({required String where, required Staff by}) async {
    await _db.writeMeta(MetaKeys.lastOffsiteBackupAt, DateTime.now().toUtc().toIso8601String());
    await _audit.record(
      action: AuditAction.backupExported,
      actor: by,
      entity: 'backup',
      summary: 'Backup sent off the device ($where)',
    );
  }

  // ---------------------------------------------------------------------------
  // Restore

  /// Opens a backup (`.abybak` needs [password]; a local `.sqlite` does not)
  /// and checks it. Throws [BackupDecryptException] or [BackupException].
  Future<BackupPreview> inspectFile(File file, {String? password}) async {
    final bytes = await file.readAsBytes();
    String path = file.path;
    if (BackupCodec.looksLikeBackup(bytes)) {
      if (password == null || password.isEmpty) {
        throw const BackupDecryptException('Enter the backup password.');
      }
      final clear = await BackupCodec.decrypt(bytes, password);
      final tmp = await _tempDirectory();
      path = p.join(tmp.path, 'restore-${_stamp(DateTime.now())}.sqlite');
      await File(path).writeAsBytes(clear, flush: true);
      try {
        return await _inspect(path, temporary: true);
      } catch (_) {
        await File(path).delete();
        rethrow;
      }
    }
    return _inspect(path);
  }

  /// Deletes a decrypted temp copy: the whole shop, unencrypted.
  Future<void> discard(BackupPreview preview) async {
    if (!preview.temporary) return;
    final f = File(preview.databasePath);
    if (await f.exists()) await f.delete();
  }

  Future<BackupPreview> _inspect(String path, {bool temporary = false}) async {
    final result = await Isolate.run(() => _readDatabaseSummary(path));
    if (result case {'error': final String error}) throw BackupException(error);
    final version = result['version'] as int;
    if (version > _db.schemaVersion) {
      throw const BackupException('This backup is from a newer version of Aby. Update the app first.');
    }
    final device = result['device'] as String?;
    return BackupPreview(
      fromThisDevice: device == null || device == await _db.readMeta(MetaKeys.deviceId),
      linked: result['linked'] == true,
      databasePath: path,
      shopName: result['shop'] as String,
      salesCount: result['sales'] as int,
      schemaVersion: version,
      lastSaleAt: result['lastSale'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch((result['lastSale'] as int) * 1000),
      temporary: temporary,
    );
  }

  /// Replaces the live database with [preview]. Makes a safety backup of
  /// the current data first. The database is closed afterwards: the caller
  /// must restart the app (AppRestarter) to open the restored data.
  ///
  /// The data comes from the backup; who this device is does not. It keeps
  /// its own device ID, hub link and (as the hub) paired devices, with
  /// their revocations, unless [replacing] the device a backup from
  /// elsewhere came from: then it becomes that device. Either way a linked
  /// device sends everything again on restart, so newer edits elsewhere
  /// win back (HubService).
  Future<void> restore(BackupPreview preview, {Staff? by, bool replacing = false}) async {
    _refuseInTraining();
    final live = await _liveDatabaseFile();
    final adopt = replacing && !preview.fromThisDevice;
    final keep = adopt ? null : await _identity();

    // Staged next to the live file first: the backup itself is never
    // changed, and the safety backup's pruning can't delete it from under
    // us. Swapped in with a rename, so a failed copy leaves the live data.
    final staged = File('${live.path}.restoring');
    if (await staged.exists()) await staged.delete();
    await File(preview.databasePath).copy(staged.path);

    // Leave a note in the restored file; the audit entry is written after
    // the restart, once the restored database is open and migrated.
    final note = jsonEncode({
      'by': by?.name,
      'byId': by?.id,
      'shop': preview.shopName,
      'sales': preview.salesCount,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    final stagedPath = staged.path;
    try {
      await Isolate.run(() {
        final db = sqlite3.open(stagedPath);
        try {
          db.execute(
            'INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)',
            [_pendingRestoreKey, note],
          );
          // A training copy restored as the real data would leave the shop
          // stuck in training: no backups, no hub.
          db.execute(
            'DELETE FROM meta WHERE key IN (?, ?)',
            [TrainingService.metaKey, TrainingService.dataKey],
          );
          if (keep != null) _keepIdentity(db, keep);
          _markForResync(db);
        } finally {
          db.close();
        }
      });
      if (await _hasData()) await createLocalBackup(by: by);
    } catch (_) {
      if (await staged.exists()) await staged.delete();
      rethrow;
    }

    stopSchedule();
    closedForRestore = true;
    await _db.close();
    for (final suffix in ['-wal', '-shm', '-journal']) {
      final f = File('${live.path}$suffix');
      if (await f.exists()) await f.delete();
    }
    await staged.rename(live.path);
  }

  /// Call once after start-up: records a restore that just happened.
  Future<void> finishPendingRestore() async {
    final note = await _db.readMeta(_pendingRestoreKey);
    if (note == null) return;
    final data = Map<String, dynamic>.from(jsonDecode(note) as Map);
    await _db.transaction(() async {
      await _audit.record(
        action: AuditAction.backupRestored,
        actorId: data['byId'] as String?,
        actorName: data['by'] as String?,
        entity: 'backup',
        summary: 'Restored a backup of ${data['shop']} (${data['sales']} sales)',
      );
      await _db.deleteMeta(_pendingRestoreKey);
    });
  }

  /// This device's ID, hub link and paired devices, to carry into a restore.
  Future<_Identity> _identity() async {
    final link = await _db.customSelect(
      'SELECT key, value FROM meta WHERE key IN (${List.filled(HubService.linkKeys.length, '?').join(', ')})',
      variables: [for (final k in HubService.linkKeys) Variable.withString(k)],
    ).get();
    final devices = await _db.customSelect('SELECT * FROM hub_devices').get();
    return _Identity(
      deviceId: (await _db.readMeta(MetaKeys.deviceId))!,
      link: {for (final r in link) r.read<String>('key'): r.read<String>('value')},
      devices: [for (final r in devices) r.data],
    );
  }

  /// Anything a shop would miss: a catalogue or staff before the first
  /// sale counts too.
  Future<bool> _hasData() async {
    final row = await _db.customSelect(
      'SELECT (SELECT COUNT(*) FROM sales) + (SELECT COUNT(*) FROM products) '
      '+ (SELECT COUNT(*) FROM staff) + (SELECT COUNT(*) FROM customers) AS n',
    ).getSingle();
    return row.read<int>('n') > 0;
  }

  static String _stamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    // Milliseconds too: a restore's safety copy can follow a snapshot within a second.
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}'
        '-${t.millisecond.toString().padLeft(3, '0')}';
  }

  /// When a backup was made, from its name: the file's own date can change
  /// when it is copied.
  static DateTime? _parseStamp(String name) {
    final m = RegExp(r'(\d{4})(\d\d)(\d\d)-(\d\d)(\d\d)(\d\d)(?:-(\d{3}))?').firstMatch(name);
    if (m == null) return null;
    final n = [for (var i = 1; i <= 7; i++) int.parse(m.group(i) ?? '0')];
    return DateTime(n[0], n[1], n[2], n[3], n[4], n[5], n[6]);
  }
}

/// Who a device is, apart from its data.
class _Identity {
  const _Identity({required this.deviceId, required this.link, required this.devices});

  final String deviceId;
  final Map<String, String> link;
  final List<Map<String, Object?>> devices;
}

/// Runs in an isolate, on the staged restore: makes it this device again.
void _keepIdentity(Database db, _Identity keep) {
  String? meta(String key) => db.select('SELECT value FROM meta WHERE key = ?', [key]).firstOrNull?['value'] as String?;
  final tables = {for (final r in db.select("SELECT name FROM sqlite_master WHERE type = 'table'")) r['name'] as String};
  if (meta(MetaKeys.deviceId) != keep.deviceId) {
    db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [MetaKeys.deviceId, keep.deviceId]);
    // Another hub's log.
    if (tables.contains('hub_changes')) db.execute('DELETE FROM hub_changes');
  }
  db.execute('DELETE FROM meta WHERE key IN (${List.filled(HubService.linkKeys.length, '?').join(', ')})', HubService.linkKeys);
  for (final e in keep.link.entries) {
    db.execute('INSERT INTO meta (key, value) VALUES (?, ?)', [e.key, e.value]);
  }
  // An older backup may not have the table yet: migrating creates it empty.
  if (!tables.contains('hub_devices')) return;
  final columns = {for (final r in db.select('PRAGMA table_info(hub_devices)')) r['name'] as String};
  db.execute('DELETE FROM hub_devices');
  for (final d in keep.devices) {
    final cols = [for (final c in d.keys) if (columns.contains(c)) c];
    db.execute(
      'INSERT INTO hub_devices (${cols.join(', ')}) VALUES (${List.filled(cols.length, '?').join(', ')})',
      [for (final c in cols) d[c]],
    );
  }
}

/// Runs in an isolate, on the staged restore: a linked device sends (and a
/// member pulls) everything again, and a hub starts a new log generation.
void _markForResync(Database db) {
  final role = db.select('SELECT value FROM meta WHERE key = ?', [HubService.roleKey]).firstOrNull?['value'];
  db.execute('DELETE FROM meta WHERE key = ?', [HubService.epochKey]);
  if (role == null || role == HubRole.none.name) {
    db.execute('DELETE FROM meta WHERE key = ?', [HubService.resyncKey]);
    return;
  }
  db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [HubService.cursorKey, '0']);
  db.execute('INSERT OR REPLACE INTO meta (key, value) VALUES (?, ?)', [HubService.resyncKey, '1']);
}

/// Runs in an isolate. Checks the file is a healthy Aby database and reads
/// what the restore preview shows.
Map<String, Object?> _readDatabaseSummary(String path) {
  final Database db;
  try {
    db = sqlite3.open(path, mode: OpenMode.readOnly);
  } catch (_) {
    return {'error': 'The file could not be opened as a database.'};
  }
  try {
    final integrity = db.select('PRAGMA integrity_check').first.values.first;
    if (integrity != 'ok') return {'error': 'The backup is damaged ($integrity).'};
    final tables = db
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((r) => r['name'] as String)
        .toSet();
    if (!tables.containsAll({'meta', 'sales', 'products'})) {
      return {'error': 'This is not an Aby database.'};
    }
    String shop = 'Unknown shop';
    if (tables.contains('settings')) {
      final rows = db.select("SELECT value FROM settings WHERE key = 'shop.name' AND deleted_at IS NULL");
      if (rows.isNotEmpty) shop = jsonDecode(rows.first['value'] as String) as String;
    } else {
      final rows = db.select("SELECT value FROM meta WHERE key = 'shop_name'");
      if (rows.isNotEmpty) shop = rows.first['value'] as String;
    }
    final sales = db.select('SELECT COUNT(*) AS n, MAX(created_at) AS last FROM sales').first;
    String? meta(String key) => db.select('SELECT value FROM meta WHERE key = ?', [key]).firstOrNull?['value'] as String?;
    final role = meta(HubService.roleKey);
    return {
      'device': meta(MetaKeys.deviceId),
      'linked': role != null && role != HubRole.none.name,
      'version': db.userVersion,
      'shop': shop,
      'sales': sales['n'] as int,
      'lastSale': sales['last'] as int?,
    };
  } catch (e) {
    return {'error': 'The backup could not be read.'};
  } finally {
    db.close();
  }
}
