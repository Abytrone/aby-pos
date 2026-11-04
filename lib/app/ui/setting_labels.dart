import 'dart:convert';

import '../../l10n/app_localizations.dart';
import '../domain/business_templates.dart';
import '../domain/loyalty.dart';
import '../models/receipt.dart';
import '../models/scale.dart';
import '../modules/settings/widgets/loyalty_settings.dart';
import '../modules/settings/widgets/printer_setup.dart';
import '../modules/setup/views/setup_view.dart';
import '../services/money.dart';
import 'format.dart';

/// Settings in the words the Settings screen uses, for the activity log.
/// Keys are stored and synced, so they stay as they are; people never see
/// them.

String settingThemeLabel(AppLocalizations l, String t) => switch (t) {
      'light' => l.settingsThemeLight,
      'dark' => l.settingsThemeDark,
      _ => l.settingsThemeSystem,
    };

String settingTileLabel(AppLocalizations l, String t) => switch (t) {
      'small' => l.settingsTilesSmall,
      'large' => l.settingsTilesLarge,
      _ => l.settingsTilesMedium,
    };

String settingViewLabel(AppLocalizations l, String v) => switch (v) {
      'grid' => l.settingsViewGrid,
      'list' => l.settingsViewList,
      _ => l.settingsViewAuto,
    };

String settingPinPadLabel(AppLocalizations l, String v) => switch (v) {
      'shuffled' => l.settingsPinPadShuffled,
      'keyboard' => l.settingsPinPadKeyboard,
      _ => l.settingsPinPadStandard,
    };

String settingScaleValueLabel(AppLocalizations l, String v) => v == 'price' ? l.settingsScalePrice : l.settingsScaleWeight;

String settingRoundLabel(AppLocalizations l, int p) => switch (p) {
      10 => l.settingsRound10,
      50 => l.settingsRound50,
      _ => l.settingsOff,
    };

/// How often automatic backups run: minutes, an hour, or once a day.
String settingBackupEveryLabel(AppLocalizations l, int m) => switch (m) {
      >= 24 * 60 => l.settingsBackupDaily,
      60 => l.settingsEveryHour,
      _ => l.settingsMinutes(m),
    };

/// The setting's title, as its row in Settings shows it.
String settingLabel(AppLocalizations l, String key) => knownSettingLabel(l, key) ?? _humanise(key);

/// Null for a key added to [AppSettings] without a title here.
String? knownSettingLabel(AppLocalizations l, String key) => switch (key) {
      'shop.name' => l.settingsShopName,
      'shop.phone' => l.settingsShopPhone,
      'shop.address' => l.settingsShopAddress,
      'shop.type' => l.settingKindOfShop,
      'day.startMinutes' => l.settingsDayStart,
      'stock.expiryByDefault' => l.settingsExpiryByDefault,
      'stock.allowNegative' => l.settingsNegativeStock,
      'tax.mode' => l.taxModeTitle,
      'selling.orderTypes' => l.settingsOrderTypes,
      'selling.scalePrefix' => l.settingsScalePrefix,
      'selling.scaleValue' => l.settingsScaleValue,
      'selling.parkedWarnHours' => l.settingsParkedWarn,
      'cash.roundTo' => l.settingsRounding,
      'credit.overLimit' => l.settingsOverLimit,
      'credit.reminder' => l.settingsReminder,
      'shift.blindCount' => l.settingsBlindCount,
      'shift.startDayToSell' => l.settingsStartDayToSell,
      'shift.varianceLimit' => l.settingsVarianceLimit,
      'pricing.targetMargin' => l.settingTargetMargin,
      'security.autoLockMinutes' => l.settingsAutoLock,
      'backup.autoDaily' => l.settingsAutoBackup,
      'backup.everyMinutes' => l.settingsBackupEvery,
      'backup.keep' => l.settingsBackupsKeep,
      'backup.offsiteReminderDays' => l.settingsOffsiteReminder,
      'device.accountsMonthly' => l.accountsMonthly,
      'device.accountsFolder' => l.accountsFolder,
      'loyalty.style' => l.loyaltyTitle,
      'loyalty.stampTarget' => l.loyaltyStampProducts,
      'loyalty.stamps' => l.loyaltyStampsNeeded,
      'loyalty.pointsPerCedi' => l.loyaltyPointsPerCedi,
      'loyalty.pointsForReward' => l.loyaltyPointsForReward,
      'loyalty.rewardValue' => l.loyaltyRewardValue,
      'loyalty.expireDays' => l.loyaltyExpireDays,
      'loyalty.goldSpend' => l.loyaltyGoldSpend,
      'loyalty.goldPercent' => l.loyaltyGoldPercent,
      'voucher.months' => l.settingVoucherMonths,
      'orders.on' => l.settingsOrderNumbers,
      'orders.prefix' => l.settingsOrderPrefix,
      'orders.prepTarget' => l.settingsOrderPrep,
      'staff.clockInToSell' => l.settingsClockInToSell,
      'staff.allowMissedClockOutEdit' => l.settingsAllowMissedClockOutEdit,
      'attendance.closeWithOthersIn' => l.settingsCloseWithOthersIn,
      'staff.commissionMode' => l.settingsCommission,
      'staff.commissionPercent' => l.settingCommissionRate,
      'receipt.header' => l.settingReceiptPart(l.receiptHeader),
      'receipt.footer' => l.settingReceiptPart(l.receiptFooter),
      'receipt.momo' => l.settingReceiptPart(l.receiptMomo),
      'receipt.logo' => l.settingReceiptPart(l.settingLogo),
      'receipt.showCashier' => l.settingReceiptPart(l.receiptShowCashier),
      'receipt.showCustomer' => l.settingReceiptPart(l.receiptShowCustomer),
      'receipt.showTax' => l.settingReceiptPart(l.receiptShowTax),
      'receipt.showQr' => l.settingReceiptPart(l.receiptShowQr),
      'receipt.copies' => l.settingReceiptCopies,
      'device.printer' => l.printerTitle,
      'device.paperMm' => l.printerPaper,
      'device.autoPrint' => l.settingsAutoPrint,
      'device.cashDrawer' => l.settingsCashDrawer,
      'device.kitchenPrinter' => l.kitchenPrinterTitle,
      'device.displayServer' => l.settingsScreens,
      'device.displayPort' => l.settingScreensPort,
      'device.scale' => l.scaleTitle,
      'device.cameraScan' => l.settingsCameraScan,
      'device.notifications' => l.settingsNotifications,
      'device.name' => l.settingsDeviceName,
      'device.theme' => l.settingsTheme,
      'device.largeText' => l.settingsLargeText,
      'device.tileSize' => l.settingsTiles,
      'device.productView' => l.settingsProductView,
      'device.pinPad' => l.settingsPinPad,
      'device.language' => l.settingsLanguage,
      _ => null,
    };

/// A stored value as Settings would show it: "On", "GH₵ 5.00", "Cones,
/// Waffle", never the JSON underneath. [names] are product and category
/// names by id.
String settingValueText(AppLocalizations l, String key, Object? value, {Map<String, String> names = const {}}) {
  String target(String json) {
    final t = LoyaltyConfig.decodeTarget(json);
    if (t.everything) return l.promoEverything;
    return [for (final id in [...t.categories, ...t.products]) names[id] ?? l.settingRemovedItem].join(', ');
  }

  String copies(String json) {
    final credit = ReceiptDesign.decodeCopies(json)['credit'] ?? 1;
    return credit >= 2 ? l.receiptTwoCopies : l.receiptOneCopy;
  }

  String printer(String json, {required bool kitchen}) => switch (PrinterTarget.decode(json)) {
        final p? => '${p.name} (${printerKindLabel(l, p.kind)})',
        null => kitchen ? l.kitchenPrinterSame : l.settingNone,
      };

  return switch ((key, value)) {
    (_, null) => l.settingsNotSet,
    (_, final bool on) => on ? l.settingOn : l.settingOff,
    ('loyalty.stampTarget' || 'orders.prepTarget', final String s) => target(s),
    ('receipt.copies', final String s) => copies(s),
    ('device.printer', final String s) => printer(s, kitchen: false),
    ('device.kitchenPrinter', final String s) => printer(s, kitchen: true),
    ('device.scale', final String s) => ScaleTarget.decode(s)?.name ?? l.settingNone,
    ('receipt.logo', final String s) => s.isEmpty ? l.settingNone : l.settingLogoAdded,
    ('shop.type', final String s) => businessTypeLabel(l, BusinessType.values.asNameMap()[s] ?? BusinessType.other),
    ('loyalty.style', final String s) => loyaltyStyleLabel(l, LoyaltyStyle.values.asNameMap()[s] ?? LoyaltyStyle.off),
    ('tax.mode', final String s) => switch (s) {
        'inclusive' => l.taxModeInclusive,
        'exclusive' => l.taxModeExclusive,
        _ => l.taxModeOff,
      },
    ('credit.overLimit', final String s) => s == 'block' ? l.settingsOverLimitBlock : l.settingsOverLimitApprove,
    ('staff.commissionMode', final String s) => switch (s) {
        'percent' => l.commissionPercentChoice,
        'perProduct' => l.commissionPerProduct,
        _ => l.settingsOff,
      },
    ('device.theme', final String s) => settingThemeLabel(l, s),
    ('device.tileSize', final String s) => settingTileLabel(l, s),
    ('device.productView', final String s) => settingViewLabel(l, s),
    ('device.pinPad', final String s) => settingPinPadLabel(l, s),
    ('selling.scaleValue', final String s) => settingScaleValueLabel(l, s),
    ('device.language', 'en') => 'English',
    ('cash.roundTo', final int p) => settingRoundLabel(l, p),
    ('day.startMinutes', final int m) => m == 0 ? l.settingsMidnight : formatMinutesOfDay(m),
    ('backup.everyMinutes', final int m) => settingBackupEveryLabel(l, m),
    ('security.autoLockMinutes', final int m) => m == 0 ? l.settingsAutoLockOff : l.settingsMinutes(m),
    ('shift.varianceLimit' || 'loyalty.rewardValue' || 'loyalty.goldSpend', final int p) => formatMoney(p),
    ('pricing.targetMargin' || 'loyalty.goldPercent' || 'staff.commissionPercent', final int p) => '$p%',
    ('selling.parkedWarnHours', final int h) => l.settingsHours(h),
    ('loyalty.expireDays', final int d) => d == 0 ? l.settingsAutoLockOff : l.settingsDays(d),
    ('backup.offsiteReminderDays', final int d) => l.settingsDays(d),
    ('voucher.months', final int m) => m == 0 ? l.settingsAutoLockOff : l.voucherMonths(m),
    ('device.paperMm', final int mm) => '$mm mm',
    (_, final String s) when s.trim().isEmpty => l.settingsNotSet,
    (_, final String s) => _looksLikeJson(s) ? l.settingChanged : s,
    _ => '$value',
  };
}

/// A setting this file does not know yet still never shows raw JSON.
bool _looksLikeJson(String s) {
  final t = s.trim();
  if (!(t.startsWith('{') || t.startsWith('['))) return false;
  try {
    jsonDecode(t);
    return true;
  } on FormatException {
    return false;
  }
}

/// "loyalty.stampTarget" → "Stamp target", for a key added without a label.
String _humanise(String key) {
  final last = key.split('.').last;
  final words = last.replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}').trim();
  return words.isEmpty ? key : '${words[0].toUpperCase()}${words.substring(1)}';
}
