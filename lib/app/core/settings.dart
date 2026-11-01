import '../models/enums.dart';

/// A typed setting with a default. Values are stored as JSON in the
/// settings table; a stored value of the wrong type falls back to the default.
class Setting<T extends Object> {
  const Setting(this.key, this.scope, this.defaultValue, {this.audited = true});

  final String key;
  final SettingScope scope;
  final T defaultValue;

  /// False for a personal preference anyone may flip (the till's grid or
  /// list), which would only bury real changes in the activity log.
  final bool audited;

  T decode(Object? json) => json is T ? json : defaultValue;
}

/// Every setting the app knows. Add new ones here.
abstract final class AppSettings {
  // Shop
  static const shopName = Setting<String>('shop.name', SettingScope.shop, 'My shop');
  static const shopPhone = Setting<String>('shop.phone', SettingScope.shop, '');
  static const shopAddress = Setting<String>('shop.address', SettingScope.shop, '');

  /// Minutes after midnight when the business day starts (default 05:00,
  /// up to 10:00), so sales after midnight count on the evening's day.
  static const businessDayStart =
      Setting<int>('day.startMinutes', SettingScope.shop, 5 * 60);

  /// The kind of shop chosen at setup (APP-04): iceCream, provision, ...
  static const shopType = Setting<String>('shop.type', SettingScope.shop, 'iceCream');

  /// New stock items ask for batches and expiry dates.
  static const expiryByDefault = Setting<bool>('stock.expiryByDefault', SettingScope.shop, false);

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

  /// Round cash totals to the nearest this many pesewas (0 = off, 10, 50).
  static const cashRoundTo = Setting<int>('cash.roundTo', SettingScope.shop, 0);

  /// A credit sale over the customer's limit: 'approve' (someone allowed to
  /// give credit enters their PIN) or 'block'.
  static const creditOverLimit = Setting<String>('credit.overLimit', SettingScope.shop, 'approve');

  /// The reminder sent by WhatsApp or SMS. {name}, {amount}, {shop}.
  static const creditReminder = Setting<String>(
    'credit.reminder',
    SettingScope.shop,
    'Hello {name}, a friendly reminder from {shop}: your balance is {amount}. Thank you!',
  );

  /// Close day hides what the drawer should hold until the cash is counted.
  static const blindCount = Setting<bool>('shift.blindCount', SettingScope.shop, false);

  /// Each till starts the day with a counted float before its first sale.
  /// Off for shops from before it; new shops turn it on (SetupController).
  static const startDayToSell = Setting<bool>('shift.startDayToSell', SettingScope.shop, false);

  /// Pesewas over or short above which close day asks for a reason.
  static const varianceLimit = Setting<int>('shift.varianceLimit', SettingScope.shop, 500);

  /// Close day warns about parked orders older than this.
  static const parkedWarnHours = Setting<int>('selling.parkedWarnHours', SettingScope.shop, 12);

  /// Products below this gross margin are flagged.
  static const targetMarginPercent = Setting<int>('pricing.targetMargin', SettingScope.shop, 50);

  // Security
  /// Lock the till after this many idle minutes; 0 turns it off.
  static const autoLockMinutes =
      Setting<int>('security.autoLockMinutes', SettingScope.shop, 3);

  // Data
  /// Automatic backups on or off (the key is from when they were daily).
  static const autoBackupDaily = Setting<bool>('backup.autoDaily', SettingScope.shop, true);

  /// Minutes between automatic backups: 1 to 60, or 1440 for once a day.
  static const backupEveryMinutes = Setting<int>('backup.everyMinutes', SettingScope.shop, 30);
  static const backupsToKeep = Setting<int>('backup.keep', SettingScope.shop, 14);

  /// Days before the off-device backup reminder turns amber.
  static const offsiteBackupDays =
      Setting<int>('backup.offsiteReminderDays', SettingScope.shop, 7);

  /// INT-05: this device saves last month's accountant pack each month, to
  /// [accountsFolder] (empty = Documents/Aby accounts).
  static const accountsMonthly = Setting<bool>('device.accountsMonthly', SettingScope.device, false);
  static const accountsFolder = Setting<String>('device.accountsFolder', SettingScope.device, '');

  // Loyalty (CUS-04): one style per shop.
  /// off | stamps | points | tiers
  static const loyaltyStyle = Setting<String>('loyalty.style', SettingScope.shop, 'off');

  /// Which products earn stamps ([PromoTarget] as JSON; empty = everything).
  static const loyaltyStampTarget = Setting<String>('loyalty.stampTarget', SettingScope.shop, '{}');

  /// Buy this many, get the next one free.
  static const loyaltyStamps = Setting<int>('loyalty.stamps', SettingScope.shop, 9);
  static const loyaltyPointsPerCedi = Setting<int>('loyalty.pointsPerCedi', SettingScope.shop, 1);
  static const loyaltyPointsForReward = Setting<int>('loyalty.pointsForReward', SettingScope.shop, 100);

  /// Pesewas off for each [loyaltyPointsForReward] points.
  static const loyaltyRewardValue = Setting<int>('loyalty.rewardValue', SettingScope.shop, 500);

  /// Points are lost after this many days without a purchase (0 = never).
  static const loyaltyExpireDays = Setting<int>('loyalty.expireDays', SettingScope.shop, 0);

  /// Gold: pesewas spent in the last 90 days, and the Gold discount.
  static const loyaltyGoldSpend = Setting<int>('loyalty.goldSpend', SettingScope.shop, 50000);
  static const loyaltyGoldPercent = Setting<int>('loyalty.goldPercent', SettingScope.shop, 5);

  /// Gift vouchers can be spent for this many months (0 = no expiry).
  static const voucherMonths = Setting<int>('voucher.months', SettingScope.shop, 12);

  // Order numbers and prep (SEL-11)
  /// Sales with prep items get a daily queue number and a kitchen ticket.
  static const ordersOn = Setting<bool>('orders.on', SettingScope.shop, false);

  /// Letter before the number: "A" gives A23.
  static const orderPrefix = Setting<String>('orders.prefix', SettingScope.shop, 'A');

  /// Items that need prep ([PromoTarget] as JSON; empty = everything).
  static const orderPrepTarget = Setting<String>('orders.prepTarget', SettingScope.shop, '{}');

  // Staff (STF-04, STF-07)
  /// Someone must be clocked in to sell. Off for shops from before it; new
  /// shops turn it on (SetupController).
  static const clockInToSell = Setting<bool>('staff.clockInToSell', SettingScope.shop, false);

  /// off | percent | perProduct
  static const commissionMode = Setting<String>('staff.commissionMode', SettingScope.shop, 'off');

  /// Whole percent of each person's sales.
  static const commissionPercent = Setting<int>('staff.commissionPercent', SettingScope.shop, 5);

  // Receipts (Settings → Receipt design)
  static const receiptHeader = Setting<String>('receipt.header', SettingScope.shop, '');
  static const receiptFooter = Setting<String>('receipt.footer', SettingScope.shop, 'Thank you. Come again!');
  static const receiptMomo = Setting<String>('receipt.momo', SettingScope.shop, '');

  /// The logo as a base64 PNG, already sized for 80 mm paper ('' = none).
  static const receiptLogo = Setting<String>('receipt.logo', SettingScope.shop, '');
  static const receiptShowCashier = Setting<bool>('receipt.showCashier', SettingScope.shop, true);
  static const receiptShowCustomer = Setting<bool>('receipt.showCustomer', SettingScope.shop, true);
  static const receiptShowTax = Setting<bool>('receipt.showTax', SettingScope.shop, true);
  static const receiptShowQr = Setting<bool>('receipt.showQr', SettingScope.shop, true);

  /// Copies per kind of payment, as JSON: credit sales print a customer copy
  /// and a shop copy to sign.
  static const receiptCopies = Setting<String>('receipt.copies', SettingScope.shop, '{"credit":2}');

  // This device's hardware (Settings → This device)
  /// The receipt printer ([PrinterTarget] as JSON; '' = none).
  static const receiptPrinter = Setting<String>('device.printer', SettingScope.device, '');

  /// 58 or 80.
  static const paperWidth = Setting<int>('device.paperMm', SettingScope.device, 80);

  /// Print each sale's receipt without asking (off: the button only, or no
  /// paper at all).
  static const autoPrint = Setting<bool>('device.autoPrint', SettingScope.device, true);

  /// A cash drawer on the printer's drawer port: opens after cash sales,
  /// cash refunds, pay-ins and outs, and no-sales.
  static const cashDrawer = Setting<bool>('device.cashDrawer', SettingScope.device, false);

  /// Where kitchen tickets print ([PrinterTarget] as JSON; '' = the
  /// receipt printer).
  static const kitchenPrinter = Setting<String>('device.kitchenPrinter', SettingScope.device, '');

  /// Serve the customer display, prep screen and "Now serving" to browsers
  /// on the shop's network.
  static const displayServer = Setting<bool>('device.displayServer', SettingScope.device, false);
  static const displayPort = Setting<int>('device.displayPort', SettingScope.device, 8080);

  /// The scale ([ScaleTarget] as JSON; '' = none).
  static const scale = Setting<String>('device.scale', SettingScope.device, '');

  /// The Scan button opens the camera (phones and tablets).
  static const cameraScan = Setting<bool>('device.cameraScan', SettingScope.device, true);

  /// Phone / Windows notifications for alerts on this device.
  static const notifications = Setting<bool>('device.notifications', SettingScope.device, true);

  // This device
  static const deviceName = Setting<String>('device.name', SettingScope.device, '');

  /// system | light | dark
  static const themeMode = Setting<String>('device.theme', SettingScope.device, 'system');
  static const largeText = Setting<bool>('device.largeText', SettingScope.device, false);

  /// small | medium | large tiles on the till.
  static const tileSize = Setting<String>('device.tileSize', SettingScope.device, 'medium');

  /// auto | grid | list: how the till shows products. Auto is the grid on
  /// tablets and tills, the list on phones. A cashier's choice, per device.
  static const productView = Setting<String>('device.productView', SettingScope.device, 'auto', audited: false);

  /// standard | shuffled | keyboard: how PINs are typed on this device.
  /// Shuffled moves the digits every time, so no one learns a PIN from
  /// where a finger lands; keyboard hides the on-screen keypad.
  static const pinPad = Setting<String>('device.pinPad', SettingScope.device, 'standard');
  static const language = Setting<String>('device.language', SettingScope.device, 'en');

  static const List<Setting<Object>> all = [
    shopName,
    shopPhone,
    shopAddress,
    shopType,
    expiryByDefault,
    businessDayStart,
    taxMode,
    allowNegativeStock,
    targetMarginPercent,
    orderTypes,
    scalePrefix,
    scaleValue,
    parkedWarnHours,
    cashRoundTo,
    creditOverLimit,
    blindCount,
    startDayToSell,
    varianceLimit,
    creditReminder,
    autoLockMinutes,
    autoBackupDaily,
    backupEveryMinutes,
    backupsToKeep,
    offsiteBackupDays,
    accountsMonthly,
    accountsFolder,
    clockInToSell,
    commissionMode,
    commissionPercent,
    ordersOn,
    orderPrefix,
    orderPrepTarget,
    kitchenPrinter,
    displayServer,
    displayPort,
    loyaltyStyle,
    loyaltyStampTarget,
    loyaltyStamps,
    loyaltyPointsPerCedi,
    loyaltyPointsForReward,
    loyaltyRewardValue,
    loyaltyExpireDays,
    loyaltyGoldSpend,
    loyaltyGoldPercent,
    voucherMonths,
    receiptHeader,
    receiptFooter,
    receiptMomo,
    receiptLogo,
    receiptShowCashier,
    receiptShowCustomer,
    receiptShowTax,
    receiptShowQr,
    receiptCopies,
    receiptPrinter,
    paperWidth,
    autoPrint,
    cashDrawer,
    scale,
    cameraScan,
    notifications,
    deviceName,
    themeMode,
    largeText,
    tileSize,
    productView,
    pinPad,
    language,
  ];

  static Setting<Object>? byKey(String key) {
    for (final s in all) {
      if (s.key == key) return s;
    }
    return null;
  }
}
