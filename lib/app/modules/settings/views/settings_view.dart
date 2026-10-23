import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/backup_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/local_backups_dialog.dart';

/// One searchable row. [keywords] widen what search finds.
class _Entry {
  const _Entry(this.group, this.tile, {this.keywords = const []});

  final String group;
  final InfoTile tile;
  final List<String> keywords;

  bool matches(String q) =>
      q.isEmpty ||
      [tile.title, tile.subtitle ?? '', group, ...keywords].any((t) => t.toLowerCase().contains(q));
}

/// Manage → Settings, grouped and searchable.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  static const dayStarts = [0, 3 * 60, 4 * 60, 5 * 60, 6 * 60];
  static const lockMinutes = [0, 1, 2, 3, 5, 10, 15];
  static const keepCounts = [7, 14, 30];
  static const reminderDays = [3, 7, 14];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final backups = Get.find<BackupController>();
    return SectionPage(
      title: l.navSettings,
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
        child: TextField(
          onChanged: (v) => controller.query.value = v.trim().toLowerCase(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: l.settingsSearch,
            isDense: true,
          ),
        ),
      ),
      child: Obx(() {
        final entries = _entries(l, backups).where((e) => e.matches(controller.query.value)).toList();
        final groups = <String, List<InfoTile>>{};
        for (final e in entries) {
          groups.putIfAbsent(e.group, () => []).add(e.tile);
        }
        if (groups.isEmpty) return EmptyState(icon: Icons.search_off, message: l.settingsNoMatch);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AbySpace.s4),
              children: [
                for (final g in groups.entries) GroupCard(title: g.key, children: g.value),
              ],
            ),
          ),
        );
      }),
    );
  }

  List<_Entry> _entries(AppLocalizations l, BackupController backups) {
    final c = controller;
    String minutesLabel(int m) => m == 0 ? l.settingsAutoLockOff : l.settingsMinutes(m);
    String themeLabel(String t) => switch (t) {
          'light' => l.settingsThemeLight,
          'dark' => l.settingsThemeDark,
          _ => l.settingsThemeSystem,
        };

    Future<void> editText(Setting<String> s, String title, {TextInputType? type}) async {
      final v = await textInputDialog(title: title, label: title, initial: c.value(s), keyboardType: type);
      if (v != null) await c.save(s, v.trim());
    }

    final shop = l.settingsGroupShop;
    final day = l.settingsGroupDay;
    final security = l.settingsGroupSecurity;
    final device = l.settingsGroupDevice;
    final data = l.settingsGroupData;
    final about = l.settingsGroupAbout;
    final local = c.lastLocalBackup.value;
    final offsite = c.lastOffsiteBackup.value;

    return [
      _Entry(shop, InfoTile(
        title: l.settingsShopName,
        value: c.value(AppSettings.shopName),
        onTap: () => editText(AppSettings.shopName, l.settingsShopName),
      )),
      _Entry(shop, InfoTile(
        title: l.settingsShopPhone,
        value: c.value(AppSettings.shopPhone).isEmpty ? l.settingsNotSet : c.value(AppSettings.shopPhone),
        onTap: () => editText(AppSettings.shopPhone, l.settingsShopPhone, type: TextInputType.phone),
      ), keywords: ['phone', 'momo']),
      _Entry(shop, InfoTile(
        title: l.settingsShopAddress,
        value: c.value(AppSettings.shopAddress).isEmpty ? l.settingsNotSet : c.value(AppSettings.shopAddress),
        onTap: () => editText(AppSettings.shopAddress, l.settingsShopAddress),
      ), keywords: ['location', 'landmark']),
      _Entry(day, InfoTile(
        title: l.settingsDayStart,
        subtitle: l.settingsDayStartHelp,
        value: formatMinutesOfDay(c.value(AppSettings.businessDayStart)),
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsDayStart,
            options: dayStarts,
            label: formatMinutesOfDay,
            selected: c.value(AppSettings.businessDayStart),
          );
          if (v != null) await c.save(AppSettings.businessDayStart, v);
        },
      ), keywords: ['midnight', 'business day', 'today']),
      _Entry(security, InfoTile(
        title: l.settingsAutoLock,
        subtitle: l.settingsAutoLockHelp,
        value: minutesLabel(c.value(AppSettings.autoLockMinutes)),
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsAutoLock,
            options: lockMinutes,
            label: minutesLabel,
            selected: c.value(AppSettings.autoLockMinutes),
          );
          if (v != null) await c.save(AppSettings.autoLockMinutes, v);
        },
      ), keywords: ['lock', 'idle', 'timeout']),
      _Entry(device, InfoTile(
        title: l.settingsDeviceName,
        value: c.value(AppSettings.deviceName).isEmpty ? l.settingsNotSet : c.value(AppSettings.deviceName),
        onTap: () => editText(AppSettings.deviceName, l.settingsDeviceName),
      )),
      _Entry(device, InfoTile(
        title: l.settingsTheme,
        value: themeLabel(c.value(AppSettings.themeMode)),
        onTap: () async {
          final v = await choiceDialog<String>(
            title: l.settingsTheme,
            options: const ['system', 'light', 'dark'],
            label: themeLabel,
            selected: c.value(AppSettings.themeMode),
          );
          if (v != null) await c.save(AppSettings.themeMode, v);
        },
      ), keywords: ['dark', 'light', 'colour']),
      _Entry(device, InfoTile(
        title: l.settingsLargeText,
        trailing: Switch(
          value: c.value(AppSettings.largeText),
          onChanged: (v) => c.save(AppSettings.largeText, v),
        ),
      ), keywords: ['font', 'size', 'accessibility']),
      _Entry(device, InfoTile(
        title: l.settingsLanguage,
        subtitle: l.settingsLanguageMore,
        value: 'English',
      ), keywords: ['twi', 'dagbani', 'hausa', 'ewe', 'ga']),
      _Entry(data, InfoTile(
        title: l.settingsAutoBackup,
        subtitle: local == null ? l.statusNever : l.statusLast(relativeTime(l, local)),
        trailing: Switch(
          value: c.value(AppSettings.autoBackupDaily),
          onChanged: (v) => c.save(AppSettings.autoBackupDaily, v),
        ),
      ), keywords: ['backup', 'daily']),
      _Entry(data, InfoTile(
        title: l.backupNow,
        leading: const Icon(Icons.backup_outlined),
        onTap: () async {
          await backups.backUpNow();
          await c.refreshBackupTimes();
        },
      ), keywords: ['backup']),
      _Entry(data, InfoTile(
        title: l.backupOnDevice,
        value: '${backups.localBackups.length}',
        leading: const Icon(Icons.inventory_2_outlined),
        onTap: () => showLocalBackups(backups),
      ), keywords: ['backup', 'restore']),
      _Entry(data, InfoTile(
        title: l.backupSend,
        subtitle: offsite == null ? l.statusNever : l.statusLast(relativeTime(l, offsite)),
        leading: const Icon(Icons.ios_share),
        onTap: () async {
          await backups.sendOffDevice();
          await c.refreshBackupTimes();
        },
      ), keywords: ['backup', 'drive', 'whatsapp', 'usb', 'export']),
      _Entry(data, InfoTile(
        title: backups.hasPassword.value ? l.backupPasswordChange : l.backupPasswordSet,
        leading: const Icon(Icons.password),
        onTap: backups.setPassword,
      ), keywords: ['backup', 'password', 'encrypt']),
      _Entry(data, InfoTile(
        title: l.backupRestoreFromFile,
        leading: const Icon(Icons.settings_backup_restore),
        danger: true,
        onTap: backups.restoreFromFile,
      ), keywords: ['backup', 'restore', 'import']),
      _Entry(data, InfoTile(
        title: l.settingsBackupsKeep,
        value: '${c.value(AppSettings.backupsToKeep)}',
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsBackupsKeep,
            options: keepCounts,
            label: (n) => '$n',
            selected: c.value(AppSettings.backupsToKeep),
          );
          if (v != null) await c.save(AppSettings.backupsToKeep, v);
        },
      ), keywords: ['backup']),
      _Entry(data, InfoTile(
        title: l.settingsOffsiteReminder,
        value: l.settingsDays(c.value(AppSettings.offsiteBackupDays)),
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsOffsiteReminder,
            options: reminderDays,
            label: l.settingsDays,
            selected: c.value(AppSettings.offsiteBackupDays),
          );
          if (v != null) await c.save(AppSettings.offsiteBackupDays, v);
        },
      ), keywords: ['backup', 'reminder']),
      _Entry(about, InfoTile(title: l.settingsVersion, value: '1.0.0')),
      _Entry(about, InfoTile(
        title: l.settingsDeviceId,
        subtitle: c.deviceId,
        trailing: IconButton(
          tooltip: l.commonCopy,
          icon: const Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: c.deviceId));
            showMessage(l.commonCopied);
          },
        ),
      )),
      _Entry(about, InfoTile(title: l.settingsDataVersion, value: '${c.schemaVersion}')),
    ];
  }
}
