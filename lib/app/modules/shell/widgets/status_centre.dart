import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/accounts_export_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/status_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/status_dot.dart';
import '../../settings/controllers/backup_controller.dart';
import '../controllers/shell_controller.dart';
import '../../../ui/dialogs.dart';

/// Every "is the data safe?" signal in one place, each with its fix.
Future<void> showStatusCentre() {
  final status = Get.find<StatusService>();
  final backups = Get.find<BackupController>();
  final shell = Get.find<ShellController>();
  status.refresh();
  return Get.dialog<void>(Builder(builder: (context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final narrow = context.isNarrow;
    return AlertDialog(
      title: Text(l.statusCentreTitle),
      content: SizedBox(
        width: 460,
        // Scrolls on short phones, where every check with its fix is too tall.
        child: SingleChildScrollView(
          child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final check in status.checks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                    child: Row(children: [
                      StatusDot(level: check.level, size: 12),
                      const SizedBox(width: AbySpace.s3),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_title(l, check.item),
                              style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                          Text(_detail(l, check), style: AbyText.caption.copyWith(color: c.inkMuted)),
                          // Beside the title, a long action squeezes it on a phone.
                          if (narrow) ?_action(l, check, backups, shell),
                        ]),
                      ),
                      if (!narrow) ?_action(l, check, backups, shell),
                    ]),
                  ),
              ],
            )),
        ),
      ),
      actions: [
        DialogButtons(children: [FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }));
}

String _title(AppLocalizations l, StatusItem item) => switch (item) {
      StatusItem.localBackup => l.statusLocalBackup,
      StatusItem.offsiteBackup => l.statusOffsiteBackup,
      StatusItem.activityLog => l.statusActivityLog,
      StatusItem.sync => l.statusSync,
      StatusItem.printer => l.statusPrinter,
      StatusItem.accounts => l.statusAccounts,
      StatusItem.recovery => l.statusRecovery,
    };

String _detail(AppLocalizations l, StatusCheck check) => switch (check.item) {
      StatusItem.localBackup || StatusItem.offsiteBackup =>
        check.at == null ? l.statusNever : l.statusLast(relativeTime(l, check.at!)),
      StatusItem.activityLog =>
        check.level == StatusLevel.ok ? l.statusChainIntact : l.statusChainBroken,
      StatusItem.sync => [
          if (check.detail != null) l.statusHubUnreachable,
          (check.count ?? 0) == 0 ? l.statusNothingWaiting : l.statusSalesWaiting(check.count!),
        ].join(' '),
      StatusItem.printer => check.detail == null
          ? l.statusPrinterReady
          : '${l.statusPrintsWaiting(check.count ?? 0)} ${check.detail}',
      StatusItem.recovery => check.level == StatusLevel.ok ? l.statusRecoveryOk : l.statusRecoveryMissing,
      StatusItem.accounts => check.detail != null
          ? l.statusAccountsFailed
          : check.at == null
              ? l.statusNever
              : l.statusLast(relativeTime(l, check.at!)),
    };

Widget? _action(AppLocalizations l, StatusCheck check, BackupController backups, ShellController shell) {
  if (check.level == StatusLevel.ok || check.level == StatusLevel.info) return null;
  return switch (check.item) {
    StatusItem.localBackup => TextButton(onPressed: backups.backUpNow, child: Text(l.backupNow)),
    StatusItem.offsiteBackup => TextButton(onPressed: backups.sendOffDevice, child: Text(l.backupSend)),
    StatusItem.activityLog => TextButton(
        onPressed: () {
          goBack<void>();
          shell.select(ShellSection.activity);
        },
        child: Text(l.statusOpenActivity),
      ),
    StatusItem.sync => null,
    StatusItem.printer => Row(mainAxisSize: MainAxisSize.min, children: [
        TextButton(onPressed: Get.find<PrintService>().clearQueue, child: Text(l.printClear)),
        TextButton(onPressed: Get.find<PrintService>().retryNow, child: Text(l.commonTryAgain)),
      ]),
    StatusItem.recovery => TextButton(
        onPressed: () {
          goBack<void>();
          shell.openMyProfile();
        },
        child: Text(l.recoveryMake),
      ),
    StatusItem.accounts => TextButton(
        onPressed: () async {
          await Get.find<AccountsExportService>().exportIfDue();
          await Get.find<StatusService>().refresh(checkChain: false);
        },
        child: Text(l.commonTryAgain),
      ),
  };
}
