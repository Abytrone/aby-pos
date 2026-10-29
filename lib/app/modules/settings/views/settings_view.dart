import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../domain/business_templates.dart';
import '../../../domain/loyalty.dart';
import '../../../models/enums.dart';
import '../../../models/receipt.dart';
import '../../../models/scale.dart';
import '../../../services/branch_service.dart';
import '../../../services/hub/hub_service.dart';
import '../../../services/money.dart';
import '../../../services/display/display_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/training_service.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/backup_controller.dart';
import '../controllers/settings_controller.dart';
import '../../setup/views/setup_view.dart' show businessTypeLabel;
import '../widgets/device_hardware.dart';
import '../widgets/local_backups_dialog.dart';
import '../widgets/loyalty_settings.dart';
import '../widgets/pay_methods_dialog.dart';
import '../widgets/printer_setup.dart';
import '../widgets/promotions_dialog.dart';
import '../widgets/receipt_designer.dart';
import '../widgets/branches_page.dart';
import '../widgets/hub_devices.dart';
import '../widgets/screens_dialog.dart';
import '../widgets/selling_lists.dart';

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

/// Settings → Items that need prep: products and categories that get a
/// queue number and a kitchen ticket.
Future<void> editPrepItems(SettingsController c) async {
  final picked = await pickProducts(
    appL10n().settingsOrderPrep,
    LoyaltyConfig.decodeTarget(c.value(AppSettings.orderPrepTarget)),
  );
  if (picked != null) await c.save(AppSettings.orderPrepTarget, jsonEncode(picked.toJson()));
}

/// Training mode on or off, or a fresh copy (owner, or with a PIN).
Future<void> setTraining(SettingsController c, bool on, {bool reset = false}) async {
  final l = appL10n();
  final ok = await confirmDialog(
    title: reset ? l.trainingReset : (on ? l.trainingStartTitle : l.trainingStopTitle),
    message: reset ? l.trainingResetHelp : (on ? l.trainingStartBody : l.trainingStopBody),
    confirmLabel: reset ? l.trainingReset : (on ? l.trainingStart : l.trainingStop),
  );
  if (!ok) return;
  if (!await c.authorizeChange()) return;
  final training = Get.find<TrainingService>();
  if (reset) {
    await training.reset();
  } else if (on) {
    await training.enter();
  } else {
    await training.leave();
  }
}

/// Manage → Settings, grouped and searchable.
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  static const dayStarts = [0, 3 * 60, 4 * 60, 5 * 60, 6 * 60];
  static const lockMinutes = [0, 1, 2, 3, 5, 10, 15];
  static const keepCounts = [7, 14, 30];
  static const reminderDays = [3, 7, 14];
  static const parkedHours = [4, 8, 12, 24, 48];

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
    String tileLabel(String t) => switch (t) {
          'small' => l.settingsTilesSmall,
          'large' => l.settingsTilesLarge,
          _ => l.settingsTilesMedium,
        };
    String scaleValueLabel(String v) => v == 'price' ? l.settingsScalePrice : l.settingsScaleWeight;

    Future<void> editText(Setting<String> s, String title, {TextInputType? type}) async {
      final v = await textInputDialog(title: title, label: title, initial: c.value(s), keyboardType: type);
      if (v != null) await c.save(s, v.trim());
    }

    final shop = l.settingsGroupShop;
    final day = l.settingsGroupDay;
    final selling = l.settingsGroupSelling;
    final payments = l.settingsGroupPayments;
    String roundLabel(int p) => switch (p) {
          10 => l.settingsRound10,
          50 => l.settingsRound50,
          _ => l.settingsOff,
        };
    final security = l.settingsGroupSecurity;
    final printing = l.settingsGroupPrinting;
    final printer = PrinterTarget.decode(c.value(AppSettings.receiptPrinter));
    final scale = ScaleTarget.decode(c.value(AppSettings.scale));
    final orders = l.settingsGroupOrders;
    final features = l.settingsGroupFeatures;
    String commissionLabel(String m) => switch (m) {
          'percent' => l.commissionPercentOfSales(c.value(AppSettings.commissionPercent)),
          'perProduct' => l.commissionPerProduct,
          _ => l.settingsOff,
        };
    final kitchen = PrinterTarget.decode(c.value(AppSettings.kitchenPrinter));
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
      _Entry(shop, InfoTile(
        title: l.branchesTitle,
        subtitle: l.branchesSettingsHelp,
        value: Get.find<BranchService>().many ? Get.find<BranchService>().current.value?.name : null,
        leading: const Icon(Icons.storefront_outlined),
        onTap: () => showBranches(backups),
      ), keywords: ['branch', 'location', 'shop', 'transfer', 'second shop']),
      _Entry(features, InfoTile(
        title: l.setupShopType,
        subtitle: l.settingsFeaturesHelp,
        value: businessTypeLabel(l, BusinessType.values.asNameMap()[c.value(AppSettings.shopType)] ?? BusinessType.other),
      ), keywords: ['features', 'shop type', 'business']),
      _Entry(features, InfoTile(
        title: l.settingsExpiryByDefault,
        subtitle: l.settingsExpiryByDefaultHelp,
        trailing: Switch(value: c.value(AppSettings.expiryByDefault), onChanged: (v) => c.save(AppSettings.expiryByDefault, v)),
      ), keywords: ['expiry', 'batches', 'features']),
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
      _Entry(payments, InfoTile(
        title: l.settingsPayMethods,
        subtitle: l.settingsPayMethodsHelp,
        leading: const Icon(Icons.payments_outlined),
        onTap: showPayMethods,
      ), keywords: ['momo', 'mtn', 'telecel', 'card', 'bank', 'merchant']),
      _Entry(payments, InfoTile(
        title: l.settingsRounding,
        subtitle: l.settingsRoundingHelp,
        value: roundLabel(c.value(AppSettings.cashRoundTo)),
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsRounding,
            options: const [0, 10, 50],
            label: roundLabel,
            selected: c.value(AppSettings.cashRoundTo),
          );
          if (v != null) await c.save(AppSettings.cashRoundTo, v);
        },
      ), keywords: ['coins', 'pesewas', 'round']),
      _Entry(payments, InfoTile(
        title: l.settingsOverLimit,
        subtitle: l.settingsOverLimitHelp,
        value: c.value(AppSettings.creditOverLimit) == 'block' ? l.settingsOverLimitBlock : l.settingsOverLimitApprove,
        onTap: () async {
          final v = await choiceDialog<String>(
            title: l.settingsOverLimit,
            options: const ['approve', 'block'],
            label: (o) => o == 'block' ? l.settingsOverLimitBlock : l.settingsOverLimitApprove,
            selected: c.value(AppSettings.creditOverLimit),
          );
          if (v != null) await c.save(AppSettings.creditOverLimit, v);
        },
      ), keywords: ['credit', 'limit', 'book']),
      _Entry(payments, InfoTile(
        title: l.settingsReminder,
        subtitle: c.value(AppSettings.creditReminder),
        onTap: () async {
          final v = await textInputDialog(
            title: l.settingsReminder,
            label: l.settingsReminder,
            helper: l.settingsReminderHelp,
            initial: c.value(AppSettings.creditReminder),
          );
          if (v != null && v.trim().isNotEmpty) await c.save(AppSettings.creditReminder, v.trim());
        },
      ), keywords: ['whatsapp', 'sms', 'credit', 'reminder']),
      _Entry(features, InfoTile(
        title: l.settingsOrderTypes,
        subtitle: l.settingsOrderTypesHelp,
        trailing: Switch(value: c.value(AppSettings.orderTypes), onChanged: (v) => c.save(AppSettings.orderTypes, v)),
      ), keywords: ['takeaway', 'eat in', 'delivery', 'restaurant']),
      _Entry(selling, InfoTile(
        title: l.settingsNegativeStock,
        subtitle: l.settingsNegativeStockHelp,
        trailing: Switch(
          value: c.value(AppSettings.allowNegativeStock),
          onChanged: (v) => c.save(AppSettings.allowNegativeStock, v),
        ),
      ), keywords: ['out of stock', 'sold out']),
      _Entry(selling, InfoTile(
        title: l.settingsDiscounts,
        subtitle: l.settingsDiscountsHelp,
        leading: const Icon(Icons.local_offer_outlined),
        onTap: showSavedDiscounts,
      ), keywords: ['discount', 'student', 'staff']),
      _Entry(features, InfoTile(
        title: l.loyaltyTitle,
        subtitle: l.loyaltySettingsHelp,
        value: loyaltyStyleLabel(l, LoyaltyStyle.values.asNameMap()[c.value(AppSettings.loyaltyStyle)] ?? LoyaltyStyle.off),
        leading: const Icon(Icons.loyalty_outlined),
        onTap: () => showLoyaltySettings(c),
      ), keywords: ['loyalty', 'stamps', 'points', 'gold', 'reward', 'free']),
      _Entry(features, InfoTile(
        title: l.promoTitle,
        subtitle: l.promoSettingsHelp,
        leading: const Icon(Icons.celebration_outlined),
        onTap: showPromotions,
      ), keywords: ['promotion', 'happy hour', 'buy', 'free', 'bundle', 'combo', 'deal', 'offer']),
      for (final kind in ReasonKind.values)
        _Entry(selling, InfoTile(
          title: reasonKindLabel(l, kind),
          leading: const Icon(Icons.list_alt),
          onTap: () => showReasons(kind),
        ), keywords: ['reasons', 'void', 'refund', 'no sale']),
      _Entry(selling, InfoTile(
        title: l.settingsScalePrefix,
        subtitle: l.settingsScalePrefixHelp,
        value: c.value(AppSettings.scalePrefix).isEmpty ? l.settingsOff : c.value(AppSettings.scalePrefix),
        onTap: () => editText(AppSettings.scalePrefix, l.settingsScalePrefix, type: TextInputType.number),
      ), keywords: ['scale', 'barcode', 'weight', 'ean']),
      if (c.value(AppSettings.scalePrefix).isNotEmpty)
        _Entry(selling, InfoTile(
          title: l.settingsScaleValue,
          value: scaleValueLabel(c.value(AppSettings.scaleValue)),
          onTap: () async {
            final v = await choiceDialog<String>(
              title: l.settingsScaleValue,
              options: const ['weight', 'price'],
              label: scaleValueLabel,
              selected: c.value(AppSettings.scaleValue),
            );
            if (v != null) await c.save(AppSettings.scaleValue, v);
          },
        ), keywords: ['scale', 'barcode']),
      _Entry(selling, InfoTile(
        title: l.settingsParkedWarn,
        subtitle: l.settingsParkedWarnHelp,
        value: l.settingsHours(c.value(AppSettings.parkedWarnHours)),
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsParkedWarn,
            options: parkedHours,
            label: l.settingsHours,
            selected: c.value(AppSettings.parkedWarnHours),
          );
          if (v != null) await c.save(AppSettings.parkedWarnHours, v);
        },
      ), keywords: ['park', 'hold', 'open orders']),
      _Entry(payments, InfoTile(
        title: l.settingsBlindCount,
        subtitle: l.settingsBlindCountHelp,
        trailing: Switch(value: c.value(AppSettings.blindCount), onChanged: (v) => c.save(AppSettings.blindCount, v)),
      ), keywords: ['close day', 'count', 'drawer', 'shift']),
      _Entry(payments, InfoTile(
        title: l.settingsVarianceLimit,
        subtitle: l.settingsVarianceLimitHelp,
        value: formatMoney(c.value(AppSettings.varianceLimit)),
        onTap: () async {
          final v = await choiceDialog<int>(
            title: l.settingsVarianceLimit,
            options: const [0, 100, 200, 500, 1000, 2000],
            label: formatMoney,
            selected: c.value(AppSettings.varianceLimit),
          );
          if (v != null) await c.save(AppSettings.varianceLimit, v);
        },
      ), keywords: ['short', 'over', 'close day', 'drawer']),
      _Entry(printing, InfoTile(
        title: l.printerTitle,
        subtitle: printer == null ? l.printerNoneHelp : '${printerKindLabel(l, printer.kind)}  ·  ${c.value(AppSettings.paperWidth)} mm',
        value: printer?.name ?? l.settingsNotSet,
        leading: const Icon(Icons.print_outlined),
        onTap: () => showPrinterSetup(c),
      ), keywords: ['printer', 'bluetooth', 'usb', 'wifi', 'network', 'thermal', 'paper', '58', '80']),
      if (printer != null)
        _Entry(printing, InfoTile(
          title: l.settingsAutoPrint,
          subtitle: l.settingsAutoPrintHelp,
          trailing: Switch(value: c.value(AppSettings.autoPrint), onChanged: (v) => c.save(AppSettings.autoPrint, v)),
        ), keywords: ['printer', 'receipt', 'paper']),
      if (printer != null)
        _Entry(printing, InfoTile(
          title: l.settingsCashDrawer,
          subtitle: l.settingsCashDrawerHelp,
          trailing: Switch(value: c.value(AppSettings.cashDrawer), onChanged: (v) => c.save(AppSettings.cashDrawer, v)),
        ), keywords: ['drawer', 'cash', 'kick']),
      if (printer != null && c.value(AppSettings.cashDrawer))
        _Entry(printing, InfoTile(
          title: l.settingsTestDrawer,
          leading: const Icon(Icons.point_of_sale_outlined),
          onTap: Get.find<PrintService>().openDrawer,
        ), keywords: ['drawer', 'cash']),
      _Entry(printing, InfoTile(
        title: l.receiptDesign,
        subtitle: l.receiptDesignHelp,
        leading: const Icon(Icons.receipt_long_outlined),
        onTap: () => showReceiptDesigner(c),
      ), keywords: ['receipt', 'logo', 'footer', 'header', 'qr', 'momo', 'copies']),
      _Entry(features, InfoTile(
        title: l.settingsOrderNumbers,
        subtitle: l.settingsOrderNumbersHelp,
        trailing: Switch(value: c.value(AppSettings.ordersOn), onChanged: (v) => c.save(AppSettings.ordersOn, v)),
      ), keywords: ['order', 'queue', 'kitchen', 'ticket', 'prep', 'number']),
      if (c.value(AppSettings.ordersOn)) ...[
        _Entry(orders, InfoTile(
          title: l.settingsOrderPrefix,
          value: '${c.value(AppSettings.orderPrefix)}23',
          onTap: () => editText(AppSettings.orderPrefix, l.settingsOrderPrefix),
        ), keywords: ['order', 'letter']),
        _Entry(orders, InfoTile(
          title: l.settingsOrderPrep,
          subtitle: l.settingsOrderPrepHelp,
          leading: const Icon(Icons.soup_kitchen_outlined),
          onTap: () => editPrepItems(c),
        ), keywords: ['kitchen', 'prep', 'milkshake', 'waffle']),
        _Entry(orders, InfoTile(
          title: l.kitchenPrinterTitle,
          subtitle: l.kitchenPrinterHelp,
          value: kitchen?.name ?? l.kitchenPrinterSame,
          leading: const Icon(Icons.print_outlined),
          onTap: () => showPrinterSetup(c, kitchen: true),
        ), keywords: ['kitchen', 'printer', 'ticket']),
      ],
      _Entry(orders, InfoTile(
        title: l.settingsScreens,
        subtitle: l.settingsScreensHelp,
        trailing: Switch(
          value: c.value(AppSettings.displayServer),
          onChanged: (v) async {
            await c.save(AppSettings.displayServer, v);
            try {
              await Get.find<DisplayService>().apply();
            } on Object catch (e) {
              showMessage(l.screensCannotStart('$e'));
            }
          },
        ),
      ), keywords: ['customer display', 'second screen', 'tv', 'tablet', 'monitor', 'now serving', 'kitchen']),
      if (c.value(AppSettings.displayServer))
        _Entry(orders, InfoTile(
          title: l.screensTitle,
          leading: const Icon(Icons.connected_tv_outlined),
          onTap: showScreenLinks,
        ), keywords: ['link', 'qr', 'display']),
      _Entry(features, InfoTile(
        title: l.settingsClockInToSell,
        subtitle: l.settingsClockInToSellHelp,
        trailing: Switch(value: c.value(AppSettings.clockInToSell), onChanged: (v) => c.save(AppSettings.clockInToSell, v)),
      ), keywords: ['clock', 'time', 'attendance', 'shift']),
      _Entry(features, InfoTile(
        title: l.settingsCommission,
        subtitle: l.settingsCommissionHelp,
        value: commissionLabel(c.value(AppSettings.commissionMode)),
        onTap: () async {
          final mode = await choiceDialog<String>(
            title: l.settingsCommission,
            options: const ['off', 'percent', 'perProduct'],
            label: (m) => m == 'percent' ? l.commissionPercentChoice : commissionLabel(m),
            selected: c.value(AppSettings.commissionMode),
          );
          if (mode == null) return;
          if (mode == 'percent') {
            final percent = await choiceDialog<int>(
              title: l.commissionPercentChoice,
              options: const [1, 2, 3, 5, 7, 10, 15],
              label: (p) => '$p%',
              selected: c.value(AppSettings.commissionPercent),
            );
            if (percent == null) return;
            await c.saveAll([(AppSettings.commissionMode, mode), (AppSettings.commissionPercent, percent)]);
            c.saved();
          } else {
            await c.save(AppSettings.commissionMode, mode);
          }
        },
      ), keywords: ['commission', 'pay', 'wages', 'bonus']),
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
        title: l.hubTitle,
        subtitle: l.hubSettingsHelp,
        value: hubRoleText(l, Get.find<HubService>().role.value),
        leading: const Icon(Icons.hub_outlined),
        onTap: showHubDevices,
      ), keywords: ['hub', 'sync', 'devices', 'tills', 'wifi', 'network', 'pair', 'join']),
      if (scaleKindHere != null)
        _Entry(device, InfoTile(
          title: l.scaleTitle,
          subtitle: l.scaleHelp,
          value: scale?.name ?? l.settingsNotSet,
          leading: const Icon(Icons.scale_outlined),
          onTap: () => showScaleSetup(c),
        ), keywords: ['scale', 'weight', 'kg', 'serial', 'com', 'bluetooth']),
      if (Platform.isAndroid)
        _Entry(device, InfoTile(
          title: l.settingsCameraScan,
          subtitle: l.settingsCameraScanHelp,
          trailing: Switch(value: c.value(AppSettings.cameraScan), onChanged: (v) => c.save(AppSettings.cameraScan, v)),
        ), keywords: ['camera', 'scan', 'barcode', 'qr']),
      _Entry(device, InfoTile(
        title: l.settingsNotifications,
        subtitle: l.settingsNotificationsHelp,
        trailing: Switch(value: c.value(AppSettings.notifications), onChanged: (v) => c.save(AppSettings.notifications, v)),
      ), keywords: ['notifications', 'alerts', 'reminders']),
      if (c.value(AppSettings.notifications))
        _Entry(device, InfoTile(
          title: l.notifyTitle,
          leading: const Icon(Icons.notifications_outlined),
          onTap: showNotificationChoices,
        ), keywords: ['notifications', 'alerts', 'low stock', 'credit']),
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
        title: l.settingsTiles,
        value: tileLabel(c.value(AppSettings.tileSize)),
        onTap: () async {
          final v = await choiceDialog<String>(
            title: l.settingsTiles,
            options: const ['small', 'medium', 'large'],
            label: tileLabel,
            selected: c.value(AppSettings.tileSize),
          );
          if (v != null) await c.save(AppSettings.tileSize, v);
        },
      ), keywords: ['till', 'tiles', 'size', 'grid']),
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
        title: l.trainingTitle,
        subtitle: l.trainingHelp,
        leading: const Icon(Icons.school_outlined),
        trailing: Switch(value: Get.find<TrainingService>().active.value, onChanged: (on) => setTraining(c, on)),
      ), keywords: ['training', 'practice', 'sandbox', 'new cashier']),
      if (Get.find<TrainingService>().active.value)
        _Entry(data, InfoTile(
          title: l.trainingReset,
          subtitle: l.trainingResetHelp,
          leading: const Icon(Icons.restart_alt),
          onTap: () => setTraining(c, true, reset: true),
        ), keywords: ['training', 'reset']),
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
      _Entry(data, InfoTile(
        title: l.accountsMonthly,
        subtitle: c.value(AppSettings.accountsMonthly)
            ? (c.lastAccountsPack.value == null
                ? l.accountsNone
                : l.statusLast(relativeTime(l, c.lastAccountsPack.value!)))
            : l.accountsMonthlyHelp,
        trailing: Switch(
          value: c.value(AppSettings.accountsMonthly),
          onChanged: c.setAccountsMonthly,
        ),
      ), keywords: ['accountant', 'accounts', 'export', 'monthly', 'month end']),
      if (c.value(AppSettings.accountsMonthly)) ...[
        _Entry(data, InfoTile(
          title: l.accountsFolder,
          subtitle: c.canChooseAccountsFolder ? c.accountsFolder.value : l.accountsFolderInApp,
          leading: const Icon(Icons.folder_outlined),
          onTap: c.canChooseAccountsFolder ? c.chooseAccountsFolder : null,
        ), keywords: ['accountant', 'folder']),
        _Entry(data, InfoTile(
          title: l.accountsShareLatest,
          leading: const Icon(Icons.ios_share),
          onTap: c.shareLatestAccounts,
        ), keywords: ['accountant', 'share', 'whatsapp', 'email']),
      ],
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
