import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../routes/app_routes.dart';
import '../../../services/display/display_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/backup/backup_service.dart';
import '../../../services/device_service.dart';
import '../../../services/price_scheduler.dart';
import '../../../services/branch_service.dart';
import '../../../services/hub/hub_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/training_service.dart';
import '../../../services/status_service.dart';

/// Opens the database, loads settings, finishes a restore if one just
/// happened, takes the daily backup if due, then goes to setup or sign-in.
class StartController extends GetxController {
  final DeviceService _device = Get.find();
  final SettingsService _settings = Get.find();
  final BackupService _backups = Get.find();
  final StatusService _status = Get.find();
  final StaffRepository _staff = Get.find();

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    await _device.ready;
    await _settings.load();
    await Get.find<BranchService>().load();
    await Get.find<TrainingService>().load();
    AppRestarter.applyTheme(_settings.get(AppSettings.themeMode));
    await _backups.finishPendingRestore();
    await Get.find<PriceScheduler>().run();
    final hasStaff = await _staff.hasStaff();
    if (hasStaff) unawaited(_dailyBackup());
    if (hasStaff) unawaited(Get.find<NotificationService>().start());
    unawaited(_startDisplays());
    unawaited(_startHub());
    await _status.refresh();
    await Get.offAllNamed<void>(hasStaff ? Routes.signIn : Routes.setup);
  }

  /// The screens for tablets and TVs, when this device serves them. A port
  /// already in use is shown in Settings, not here.
  Future<void> _startDisplays() async {
    try {
      await Get.find<DisplayService>().apply();
    } catch (e) {
      debugPrint('Display server did not start: $e');
    }
  }

  /// Carries on as the hub or a member; a problem shows in the status centre.
  Future<void> _startHub() async {
    // Practice sales never reach the other tills.
    if (Get.find<TrainingService>().active.value) return;
    try {
      await Get.find<HubService>().start();
    } catch (e) {
      debugPrint('Hub did not start: $e');
    }
  }

  /// Never blocks start-up; a failed automatic backup shows in the status
  /// centre as "backup due".
  Future<void> _dailyBackup() async {
    try {
      await _backups.autoBackupIfDue();
      await _status.refresh(checkChain: false);
    } catch (e) {
      debugPrint('Automatic backup failed: $e');
    }
  }
}
