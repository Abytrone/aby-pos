import 'dart:async';

import 'package:get/get.dart';

import '../core/settings.dart';
import '../data/repositories/audit_repository.dart';
import '../models/audit.dart';
import 'backup/backup_service.dart';
import 'printing/print_service.dart';
import 'settings_service.dart';
import 'sync_service.dart';

enum StatusLevel { ok, info, warning, problem }

enum StatusItem { localBackup, offsiteBackup, activityLog, sync, printer }

class StatusCheck {
  const StatusCheck(this.item, this.level, {this.at, this.count, this.detail});

  final StatusItem item;
  final StatusLevel level;

  /// When the thing last happened (backups).
  final DateTime? at;

  /// Waiting items (sync, printing).
  final int? count;

  /// What went wrong (printing).
  final String? detail;
}

/// "Is everything safe?": backups, the activity log chain and sync, in one
/// place. The header shows the worst level.
class StatusService extends GetxService {
  StatusService(this._backups, this._audit, this._settings, this._sync, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final BackupService _backups;
  final AuditRepository _audit;
  final SettingsService _settings;
  final SyncService _sync;
  final DateTime Function() _clock;

  final checks = <StatusCheck>[].obs;
  final chain = Rxn<AuditChainStatus>();

  Timer? _timer;
  StreamSubscription<int>? _syncSub;
  Worker? _printWorker, _onlineWorker;

  StatusLevel get overall => checks.fold(
        StatusLevel.ok,
        (worst, c) => c.level.index > worst.index ? c.level : worst,
      );

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => refresh());
    _syncSub = _sync.waitingSales.listen((_) => refresh(checkChain: false));
    _onlineWorker = ever(_sync.online, (_) => refresh(checkChain: false));
    if (Get.isRegistered<PrintService>()) {
      _printWorker = ever(Get.find<PrintService>().queue, (_) => refresh(checkChain: false));
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    _syncSub?.cancel();
    _printWorker?.dispose();
    _onlineWorker?.dispose();
    super.onClose();
  }

  Future<void> refresh({bool checkChain = true}) async {
    final now = _clock();
    final local = await _backups.lastLocalBackupAt();
    final offsite = await _backups.lastOffsiteBackupAt();
    if (checkChain || chain.value == null) chain.value = await _audit.verifyChain();
    final reminderDays = _settings.get(AppSettings.offsiteBackupDays);

    StatusLevel age(DateTime? at, Duration warnAfter, Duration problemAfter) {
      if (at == null) return StatusLevel.warning;
      final gone = now.difference(at);
      if (gone > problemAfter) return StatusLevel.problem;
      if (gone > warnAfter) return StatusLevel.warning;
      return StatusLevel.ok;
    }

    final waiting = _sync.waitingSales.value;
    final printer = Get.isRegistered<PrintService>() ? Get.find<PrintService>() : null;
    checks.assignAll([
      StatusCheck(StatusItem.localBackup,
          age(local, const Duration(days: 2), const Duration(days: 7)),
          at: local),
      StatusCheck(StatusItem.offsiteBackup,
          age(offsite, Duration(days: reminderDays), Duration(days: reminderDays * 2)),
          at: offsite),
      StatusCheck(StatusItem.activityLog,
          chain.value?.isIntact ?? true ? StatusLevel.ok : StatusLevel.problem),
      StatusCheck(
        StatusItem.sync,
        !_sync.linked.value
            ? StatusLevel.info
            : _sync.online.value
                ? StatusLevel.ok
                : StatusLevel.warning,
        count: waiting,
        detail: _sync.linked.value && !_sync.online.value ? _sync.problem.value : null,
      ),
      if (printer != null && printer.hasPrinter)
        StatusCheck(
          StatusItem.printer,
          printer.problem == null ? StatusLevel.ok : StatusLevel.warning,
          count: printer.queue.length,
          detail: printer.problem,
        ),
    ]);
  }
}
