import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/period.dart';
import '../core/settings.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/profit_repository.dart';
import '../data/repositories/report_repository.dart';
import '../domain/accountant_pack.dart';
import '../models/audit.dart';
import 'pdf_brand_loader.dart';
import 'settings_service.dart';
import 'training_service.dart';

/// Scheduled accounting exports (INT-05): when [AppSettings.accountsMonthly]
/// is on, this device saves last month's accountant pack (REP-09) to
/// [folder] on its own, once per month. [reports] must cover every branch.
class AccountsExportService extends GetxService {
  AccountsExportService(
    this._db,
    this._reports,
    this._profit,
    this._settings,
    this._audit, {
    Future<Directory> Function()? defaultFolder,
    DateTime Function()? clock,
  })  : _defaultFolder = defaultFolder ?? _documentsFolder,
        _clock = clock ?? DateTime.now;

  final AppDatabase _db;
  final ReportRepository _reports;
  final ProfitRepository _profit;
  final SettingsService _settings;
  final AuditRepository _audit;
  final Future<Directory> Function() _defaultFolder;
  final DateTime Function() _clock;

  /// Older missed months are left for the Reports screen.
  static const maxCatchUp = 12;

  static const _doneKey = 'accounts_export_month';
  static const _atKey = 'accounts_export_at';
  static const _problemKey = 'accounts_export_problem';

  static Future<Directory> _documentsFolder() async =>
      Directory(p.join((await getApplicationDocumentsDirectory()).path, 'Aby accounts'));

  /// A folder can be chosen only on Windows: elsewhere the app may not
  /// write to it again after a restart, so packs stay in [folder] and are
  /// shared from Settings.
  static bool get canChooseFolder => Platform.isWindows;

  Timer? _timer;
  Future<List<File>>? _running;

  @override
  void onInit() {
    super.onInit();
    // A till left on over the month end still makes the pack.
    _timer = Timer.periodic(const Duration(hours: 1), (_) => exportIfDue().ignore());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  bool get isOn => _settings.get(AppSettings.accountsMonthly);

  Future<Directory> folder() async {
    final chosen = _settings.get(AppSettings.accountsFolder);
    return chosen.isEmpty ? _defaultFolder() : Directory(chosen);
  }

  Future<DateTime?> lastExportAt() async => DateTime.tryParse(await _db.readMeta(_atKey) ?? '')?.toLocal();

  /// Why the last try failed; null once a pack is saved.
  Future<String?> problem() async {
    final v = await _db.readMeta(_problemKey);
    return v == null || v.isEmpty ? null : v;
  }

  static String fileName(DateRange month) =>
      'aby_accounts_${AccountantPack.day(month.from)}_${AccountantPack.day(month.lastDay)}.zip';

  /// The newest pack in [folder], to share.
  Future<File?> latest() async {
    final dir = await folder();
    if (!await dir.exists()) return null;
    final packs = [
      await for (final f in dir.list())
        if (f is File && p.basename(f.path).startsWith('aby_accounts_') && f.path.endsWith('.zip')) f,
    ]..sort((a, b) => a.path.compareTo(b.path));
    return packs.lastOrNull;
  }

  /// The months still to save: those after the last one saved, up to last
  /// month. The first time, just last month.
  Future<List<DateRange>> dueMonths() async {
    final now = _clock();
    final last = DateRange.of(ReportPeriod.lastMonth, now);
    final done = _parseMonth(await _db.readMeta(_doneKey));
    if (done == null) return [last];
    final months = <DateRange>[];
    for (var m = DateTime(done.year, done.month + 1); !m.isAfter(last.from); m = DateTime(m.year, m.month + 1)) {
      months.add(DateRange(m, DateTime(m.year, m.month + 1)));
    }
    return months.length > maxCatchUp ? months.sublist(months.length - maxCatchUp) : months;
  }

  /// Saves every due month's pack, oldest first. Never throws: a failure is
  /// kept for the status centre and tried again on the next check.
  Future<List<File>> exportIfDue() {
    if (!isOn) return Future.value(const []);
    // The training copy's sales are practice.
    if (Get.isRegistered<TrainingService>() && Get.find<TrainingService>().active.value) return Future.value(const []);
    return _running ??= _export().whenComplete(() => _running = null);
  }

  Future<List<File>> _export() async {
    final saved = <File>[];
    try {
      final months = await dueMonths();
      if (months.isEmpty) return saved;
      final dir = await folder();
      if (_settings.get(AppSettings.accountsFolder).isEmpty) {
        await dir.create(recursive: true);
      } else if (!await dir.exists()) {
        // A USB stick or network drive that is not there: don't make a
        // folder in its place.
        throw FileSystemException('The folder is not there', dir.path);
      }
      for (final month in months) {
        saved.add(await _save(month, dir));
      }
      await _db.writeMeta(_problemKey, '');
    } catch (e) {
      debugPrint('Accounts export failed: $e');
      await _db.writeMeta(_problemKey, e is FileSystemException ? '${e.message}: ${e.path ?? ''}' : '$e');
    }
    return saved;
  }

  Future<File> _save(DateRange month, Directory dir) async {
    final zip = await AccountantPack(_db).build(
      shopName: _settings.get(AppSettings.shopName),
      range: month,
      summary: await _reports.sales(month),
      pnl: await _profit.forPeriod(month.from, month.to),
      stockTax: await _reports.stockAndTax(month),
      brand: await loadPdfBrand(),
    );
    final file = File(p.join(dir.path, fileName(month)));
    await file.writeAsBytes(zip, flush: true);
    await _db.writeMeta(_doneKey, _monthKey(month.from));
    await _db.writeMeta(_atKey, _clock().toUtc().toIso8601String());
    await _audit.record(
      action: AuditAction.accountsExported,
      entity: 'accounts',
      entityId: _monthKey(month.from),
      summary: 'Accountant pack for ${_monthKey(month.from)} saved to ${dir.path}',
    );
    return file;
  }

  static String _monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

  static DateTime? _parseMonth(String? v) {
    final m = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(v ?? '');
    return m == null ? null : DateTime(int.parse(m[1]!), int.parse(m[2]!));
  }
}
