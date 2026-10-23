import 'package:get/get.dart';

import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../models/audit.dart';
import '../../../models/staff.dart';
import '../../../services/status_service.dart';

enum ActivityFilter {
  all,
  important,
  signIns,
  sales,
  staff,
  settingsAndData;

  Set<AuditAction>? get actions => switch (this) {
        ActivityFilter.all => null,
        ActivityFilter.important => AuditAction.values.where((a) => a.isSensitive).toSet(),
        ActivityFilter.signIns => {
            AuditAction.signedIn,
            AuditAction.signInFailed,
            AuditAction.lockedOut,
            AuditAction.locked,
            AuditAction.approvalRefused,
          },
        ActivityFilter.sales => {AuditAction.saleVoided, AuditAction.dayClosed},
        ActivityFilter.staff => {
            AuditAction.staffAdded,
            AuditAction.staffPinChanged,
            AuditAction.staffDetailsChanged,
            AuditAction.staffRoleChanged,
            AuditAction.staffDeactivated,
            AuditAction.staffReactivated,
            AuditAction.roleCreated,
            AuditAction.roleUpdated,
            AuditAction.roleDeleted,
          },
        ActivityFilter.settingsAndData => {
            AuditAction.settingChanged,
            AuditAction.backupCreated,
            AuditAction.backupExported,
            AuditAction.backupRestored,
          },
      };
}

enum ActivityRange { today, week, month, all }

/// Manage → Activity: the audit log, newest first, with filters.
class ActivityController extends GetxController {
  final AuditRepository _audit = Get.find();
  final StaffRepository _staff = Get.find();
  final StatusService _status = Get.find();

  final entries = <AuditEntry>[].obs;
  final people = <Staff>[].obs;
  final filter = ActivityFilter.all.obs;
  final range = ActivityRange.week.obs;
  final person = Rxn<Staff>();
  final loading = true.obs;

  Rxn<AuditChainStatus> get chain => _status.chain;

  @override
  void onInit() {
    super.onInit();
    everAll([filter, range, person], (_) => load());
    _start();
  }

  Future<void> _start() async {
    people.assignAll(await _staff.list(includeInactive: true));
    await load();
  }

  Future<void> load() async {
    loading.value = true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = switch (range.value) {
      ActivityRange.today => today,
      ActivityRange.week => today.subtract(const Duration(days: 6)),
      ActivityRange.month => today.subtract(const Duration(days: 29)),
      ActivityRange.all => null,
    };
    entries.assignAll(await _audit.list(
      actorId: person.value?.id,
      actions: filter.value.actions,
      from: from,
      limit: 500,
    ));
    loading.value = false;
  }

  /// Re-check the chain and reload.
  Future<void> refreshAll() async {
    await _status.refresh();
    await load();
  }
}
