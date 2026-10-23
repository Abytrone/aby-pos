import '../models/enums.dart';

/// A typed setting with a default. Values are stored as JSON in the
/// settings table; a stored value of the wrong type falls back to the default.
class Setting<T extends Object> {
  const Setting(this.key, this.scope, this.defaultValue);

  final String key;
  final SettingScope scope;
  final T defaultValue;

  T decode(Object? json) => json is T ? json : defaultValue;
}

/// Every setting the app knows. Add new ones here.
abstract final class AppSettings {
  // Shop
  static const shopName = Setting<String>('shop.name', SettingScope.shop, 'My shop');
  static const shopPhone = Setting<String>('shop.phone', SettingScope.shop, '');
  static const shopAddress = Setting<String>('shop.address', SettingScope.shop, '');

  /// Minutes after midnight when the business day starts (default 05:00),
  /// so sales after midnight count on the evening's day.
  static const businessDayStart =
      Setting<int>('day.startMinutes', SettingScope.shop, 5 * 60);

  // Selling
  /// off | inclusive (prices include tax) | exclusive (tax added at the till).
  static const taxMode = Setting<String>('tax.mode', SettingScope.shop, 'off');

  /// Sell even when the till thinks an item has run out.
  static const allowNegativeStock = Setting<bool>('stock.allowNegative', SettingScope.shop, true);

  /// Ask takeaway, eat-in or delivery on each sale.
  static const orderTypes = Setting<bool>('selling.orderTypes', SettingScope.shop, false);

  /// Scale barcodes: the prefix the scale prints (empty = off), and whether
  /// the five value digits are a weight in grams or a price in pesewas.
  static const scalePrefix = Setting<String>('selling.scalePrefix', SettingScope.shop, '');
  static const scaleValue = Setting<String>('selling.scaleValue', SettingScope.shop, 'weight');

  /// Close day warns about parked orders older than this.
  static const parkedWarnHours = Setting<int>('selling.parkedWarnHours', SettingScope.shop, 12);

  /// Products below this gross margin are flagged.
  static const targetMarginPercent = Setting<int>('pricing.targetMargin', SettingScope.shop, 50);

  // Security
  /// Lock the till after this many idle minutes; 0 turns it off.
  static const autoLockMinutes =
      Setting<int>('security.autoLockMinutes', SettingScope.shop, 3);

  // Data
  static const autoBackupDaily = Setting<bool>('backup.autoDaily', SettingScope.shop, true);
  static const backupsToKeep = Setting<int>('backup.keep', SettingScope.shop, 14);

  /// Days before the off-device backup reminder turns amber.
  static const offsiteBackupDays =
      Setting<int>('backup.offsiteReminderDays', SettingScope.shop, 7);

  // This device
  static const deviceName = Setting<String>('device.name', SettingScope.device, '');

  /// system | light | dark
  static const themeMode = Setting<String>('device.theme', SettingScope.device, 'system');
  static const largeText = Setting<bool>('device.largeText', SettingScope.device, false);

  /// small | medium | large tiles on the till.
  static const tileSize = Setting<String>('device.tileSize', SettingScope.device, 'medium');
  static const language = Setting<String>('device.language', SettingScope.device, 'en');

  static const List<Setting<Object>> all = [
    shopName,
    shopPhone,
    shopAddress,
    businessDayStart,
    taxMode,
    allowNegativeStock,
    targetMarginPercent,
    orderTypes,
    scalePrefix,
    scaleValue,
    parkedWarnHours,
    autoLockMinutes,
    autoBackupDaily,
    backupsToKeep,
    offsiteBackupDays,
    deviceName,
    themeMode,
    largeText,
    tileSize,
    language,
  ];

  static Setting<Object>? byKey(String key) {
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }
}
