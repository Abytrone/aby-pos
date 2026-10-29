import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../controllers/backup_controller.dart';
import '../../../ui/dialogs.dart';

/// The backups kept on this device, newest first, each restorable.
Future<void> showLocalBackups(BackupController backups) async {
  await backups.refreshList();
  await Get.dialog<void>(Builder(builder: (context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.backupOnDevice),
      content: SizedBox(
        width: 460,
        child: Obx(() {
          final list = backups.localBackups.toList();
          if (list.isEmpty) return Text(l.backupNoneYet);
          return ListView.separated(
            shrinkWrap: true,
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = list[i];
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AbySize.tapPos),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(formatDateTime(b.createdAt), style: AbyText.body.copyWith(color: c.ink)),
                      Text('${(b.sizeBytes / 1024).ceil()} KB  ·  ${relativeTime(l, b.createdAt)}',
                          style: AbyText.caption.copyWith(color: c.inkMuted)),
                    ]),
                  ),
                  TextButton(
                    onPressed: () async {
                      goBack<void>();
                      await backups.restoreLocal(b);
                    },
                    child: Text(l.backupRestore),
                  ),
                ]),
              );
            },
          );
        }),
      ),
      actions: [FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone))],
    );
  }));
}
