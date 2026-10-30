// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDone => 'Done';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied.';

  @override
  String get commonMore => 'More';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get navSell => 'Sell';

  @override
  String get navToday => 'Today';

  @override
  String get navStaff => 'Staff';

  @override
  String get navActivity => 'Activity';

  @override
  String get navSettings => 'Settings';

  @override
  String get navManage => 'Manage';

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinAgainLabel => 'PIN again';

  @override
  String get pinNewLabel => 'New PIN';

  @override
  String get pinWrong => 'Wrong PIN. Try again.';

  @override
  String get pinMismatch => 'The PINs don\'t match.';

  @override
  String get signInWho => 'Who\'s on the till?';

  @override
  String get signInPickName => 'Pick your name.';

  @override
  String get setupTitle => 'Set up your shop';

  @override
  String get setupShopName => 'Shop name';

  @override
  String get setupYourName => 'Your name';

  @override
  String get setupCreateOwner => 'Create owner and start';

  @override
  String get setupShopNameMissing => 'Enter the shop name.';

  @override
  String get setupNameMissing => 'Enter your name.';

  @override
  String get setupMovingDevice =>
      'Moving to a new device? Bring everything across from a backup.';

  @override
  String get setupRestore => 'Restore from a backup';

  @override
  String get setupJoinHelp =>
      'Adding a till to a shop that already uses Aby? Join the shop\'s hub and everything comes across.';

  @override
  String get setupJoinHub => 'Join the shop\'s hub';

  @override
  String get setupJoinRetry => 'Sync with the hub again';

  @override
  String get setupJoinNoStaff =>
      'Joined the hub, but the shop\'s staff have not come across yet. Keep the hub on and sync again.';

  @override
  String get userMenu => 'Signed in';

  @override
  String get userSwitch => 'Switch user';

  @override
  String get userLock => 'Lock';

  @override
  String get userSwitchTitle => 'Hand over the till';

  @override
  String get userSwitchNobody => 'There is nobody else to switch to.';

  @override
  String get approvalTitle => 'Approval needed';

  @override
  String get approvalPinTitle => 'PIN of the person approving';

  @override
  String get approvalWrongPin => 'That PIN can\'t approve this.';

  @override
  String get statusCentreTitle => 'Is everything safe?';

  @override
  String get statusAllSafe => 'All safe';

  @override
  String get statusNeedsAttention => 'Needs attention';

  @override
  String get statusProblem => 'Problem';

  @override
  String get statusLocalBackup => 'Backup on this device';

  @override
  String get statusOffsiteBackup => 'Backup off this device';

  @override
  String get statusActivityLog => 'Activity log';

  @override
  String get statusSync => 'Sync';

  @override
  String get statusNever => 'Never';

  @override
  String get statusChainIntact => 'Checked. Nothing has been changed.';

  @override
  String get statusChainBroken =>
      'Entries were changed or removed outside Aby.';

  @override
  String get statusNothingWaiting => 'Nothing waiting.';

  @override
  String get statusOpenActivity => 'Open activity';

  @override
  String get timeJustNow => 'just now';

  @override
  String get todaySales => 'Sales';

  @override
  String get todayNoSales => 'No sales yet today.';

  @override
  String get closeDayButton => 'Close day';

  @override
  String get closeDayApprovalReason => 'Close the day and count the drawer.';

  @override
  String get voidConfirm => 'Void sale';

  @override
  String get voidKeep => 'Keep sale';

  @override
  String get staffAdd => 'Add staff';

  @override
  String get staffPeople => 'People';

  @override
  String get staffRoles => 'Roles';

  @override
  String get staffName => 'Name';

  @override
  String get staffRole => 'Role';

  @override
  String get staffPickRole => 'Pick a role.';

  @override
  String get staffChangePin => 'Change PIN';

  @override
  String get staffChangeRole => 'Change role';

  @override
  String get staffDeactivate => 'Deactivate';

  @override
  String get staffReactivate => 'Reactivate';

  @override
  String get staffCantDeactivateSelf => 'You can\'t deactivate yourself.';

  @override
  String get staffDeactivateBody =>
      'They won\'t be able to sign in. Their sales and history stay.';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleCashier => 'Cashier';

  @override
  String get roleStockKeeper => 'Stock keeper';

  @override
  String get rolesAdd => 'New role';

  @override
  String get rolesName => 'Role name';

  @override
  String get rolesMaxDiscount => 'Highest discount without approval';

  @override
  String get rolesMaxDiscountHelp =>
      'Bigger discounts will need someone with a higher limit.';

  @override
  String get rolesOwnerFixed =>
      'Owners can always do everything. This role cannot be changed.';

  @override
  String get rolesSaved => 'Role saved.';

  @override
  String get rolesBuiltIn => 'Built in';

  @override
  String get rolesEverything => 'Everything';

  @override
  String get rolesDelete => 'Delete role';

  @override
  String get rolesDeleteBody =>
      'Nobody has this role. It will be removed from the list.';

  @override
  String get rolesCannotGrant =>
      'You can\'t give a role permissions you don\'t have yourself.';

  @override
  String get permSell => 'Sell';

  @override
  String get permOverridePrice => 'Change a price at the till';

  @override
  String get permRefund => 'Give refunds';

  @override
  String get permRefundWithoutReceipt => 'Refund without a receipt';

  @override
  String get permVoidSale => 'Void sales';

  @override
  String get permNoSale => 'Open the drawer without a sale';

  @override
  String get permEditProducts => 'Add and edit products';

  @override
  String get permChangePrices => 'Change prices';

  @override
  String get permReceiveStock => 'Receive stock';

  @override
  String get permAdjustStock => 'Adjust stock';

  @override
  String get permApproveStockCount => 'Approve stock counts';

  @override
  String get permGiveCredit => 'Sell on credit';

  @override
  String get permWriteOffCredit => 'Write off credit';

  @override
  String get permCloseDay => 'Close the day';

  @override
  String get permPayOut => 'Pay out from the drawer';

  @override
  String get permViewReports => 'See reports';

  @override
  String get permViewCostAndProfit => 'See costs and profit';

  @override
  String get permManageStaff => 'Manage staff';

  @override
  String get permManageRoles => 'Manage roles';

  @override
  String get permChangeSettings => 'Change settings';

  @override
  String get permManageDevices => 'Manage devices and the hub';

  @override
  String get permViewActivityLog => 'See the activity log';

  @override
  String get permExportData => 'Export data and backups';

  @override
  String get permRestoreBackup => 'Restore a backup';

  @override
  String get permGroupSell => 'Selling';

  @override
  String get permGroupCatalogue => 'Products and stock';

  @override
  String get permGroupCustomers => 'Customers';

  @override
  String get permGroupCash => 'Cash';

  @override
  String get permGroupReports => 'Reports';

  @override
  String get permGroupAdmin => 'Admin';

  @override
  String get auditSignedIn => 'Signed in';

  @override
  String get auditSignInFailed => 'Wrong PIN';

  @override
  String get auditLockedOut => 'Locked out';

  @override
  String get auditLocked => 'Till locked';

  @override
  String get auditApprovalRefused => 'Approval locked';

  @override
  String get auditSaleVoided => 'Sale voided';

  @override
  String get auditDayClosed => 'Day closed';

  @override
  String get auditStaffAdded => 'Staff added';

  @override
  String get auditStaffPinChanged => 'PIN changed';

  @override
  String get auditStaffRoleChanged => 'Role changed';

  @override
  String get auditStaffDeactivated => 'Staff deactivated';

  @override
  String get auditStaffReactivated => 'Staff reactivated';

  @override
  String get auditRoleCreated => 'Role created';

  @override
  String get auditRoleUpdated => 'Role changed';

  @override
  String get auditRoleDeleted => 'Role deleted';

  @override
  String get auditSettingChanged => 'Setting changed';

  @override
  String get auditBackupCreated => 'Backup made';

  @override
  String get auditBackupExported => 'Backup sent';

  @override
  String get auditBackupRestored => 'Backup restored';

  @override
  String get activitySubtitle =>
      'Every sensitive action, who did it and who approved it.';

  @override
  String get activityEmpty => 'Nothing here for these filters.';

  @override
  String get activityEveryone => 'Everyone';

  @override
  String get activityFilterAll => 'All';

  @override
  String get activityFilterImportant => 'Important';

  @override
  String get activityFilterSignIns => 'Sign-ins';

  @override
  String get activityFilterSales => 'Sales';

  @override
  String get activityFilterStaff => 'Staff and roles';

  @override
  String get activityFilterSettings => 'Settings and data';

  @override
  String get activityBefore => 'Before';

  @override
  String get activityAfter => 'After';

  @override
  String get activityChainIntact =>
      'Checked: the activity log has not been changed.';

  @override
  String get rangeToday => 'Today';

  @override
  String get rangeWeek => 'Last 7 days';

  @override
  String get rangeMonth => 'Last 30 days';

  @override
  String get rangeAll => 'All time';

  @override
  String get settingsSearch => 'Search settings';

  @override
  String get settingsNoMatch => 'No settings match.';

  @override
  String get settingsSaved => 'Saved.';

  @override
  String get settingsNotSet => 'Not set';

  @override
  String get settingsApprovalReason => 'Change a shop setting.';

  @override
  String get settingsGroupShop => 'Shop';

  @override
  String get settingsGroupDay => 'Business day';

  @override
  String get settingsGroupSecurity => 'Security';

  @override
  String get settingsGroupDevice => 'This device';

  @override
  String get settingsGroupData => 'Backup and restore';

  @override
  String get settingsGroupAbout => 'About';

  @override
  String get settingsShopName => 'Shop name';

  @override
  String get settingsShopPhone => 'Phone';

  @override
  String get settingsShopAddress => 'Address or landmark';

  @override
  String get settingsDayStart => 'Day starts at';

  @override
  String get settingsDayStartHelp =>
      'Sales before this time count on the previous day.';

  @override
  String get settingsAutoLock => 'Lock the till after';

  @override
  String get settingsAutoLockHelp =>
      'When nobody touches it. The cart is kept.';

  @override
  String get settingsAutoLockOff => 'Never';

  @override
  String get settingsDeviceName => 'Device name';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'Same as the device';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsLargeText => 'Larger text';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageMore => 'More languages are coming.';

  @override
  String get settingsAutoBackup => 'Back up every day';

  @override
  String get settingsBackupsKeep => 'Backups to keep on this device';

  @override
  String get settingsOffsiteReminder => 'Remind me to send a backup every';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDeviceId => 'Device ID';

  @override
  String get settingsDataVersion => 'Data version';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupDone => 'Backup saved on this device.';

  @override
  String get backupFailed => 'The backup didn\'t work. Try again.';

  @override
  String get backupOnDevice => 'Backups on this device';

  @override
  String get backupNoneYet => 'No backups yet.';

  @override
  String get backupSend => 'Send a backup off this device';

  @override
  String get backupSendHelp =>
      'The file is locked with this password. Keep it somewhere safe: without it the backup cannot be opened.';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupPasswordSet => 'Set a backup password';

  @override
  String get backupPasswordChange => 'Change the backup password';

  @override
  String get backupPasswordNew => 'New backup password';

  @override
  String get backupPasswordAgain => 'Backup password again';

  @override
  String get backupPasswordHelp =>
      'Used to lock backups that leave this device. Old backups keep their old password.';

  @override
  String get backupPasswordMismatch => 'The passwords don\'t match.';

  @override
  String get backupPasswordSaved => 'Backup password saved.';

  @override
  String get backupPasswordWrong => 'That isn\'t the backup password.';

  @override
  String get backupEncrypting => 'Making and locking the backup...';

  @override
  String get backupWhere => 'Where should it go?';

  @override
  String get backupShare => 'Share (WhatsApp, Drive, email...)';

  @override
  String get backupSaveToFolder => 'Save to a folder or USB stick';

  @override
  String get backupShareUnavailable =>
      'Sharing is not available here. Save to a folder instead.';

  @override
  String get backupSent => 'Backup sent. Keep the password safe.';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupRestoreFromFile => 'Restore from a file';

  @override
  String get backupPickFile => 'Pick the backup file';

  @override
  String get backupChecking => 'Checking the backup...';

  @override
  String get backupRestoring => 'Restoring...';

  @override
  String get backupRestoreConfirmTitle => 'Replace everything on this device?';

  @override
  String get backupRestoreReplacing =>
      'This backup is from another device. Is this device replacing it?';

  @override
  String get backupRestoreReplacingYes => 'Yes, it replaces that device';

  @override
  String get backupRestoreReplacingNo => 'No, keep this as a separate device';

  @override
  String get backupRestoreLinked =>
      'This device syncs with other tills. Changes made on them since this backup will come back after restoring.';

  @override
  String get backupNoSales => 'none';

  @override
  String get auditStaffDetailsChanged => 'Details changed';

  @override
  String get commonClear => 'Clear';

  @override
  String get profileTitle => 'Staff profile';

  @override
  String get profileMine => 'My profile';

  @override
  String get profileEdit => 'Edit details';

  @override
  String get profileNotAllowed => 'You can only see your own profile.';

  @override
  String get profileActive => 'Active';

  @override
  String get profileDeactivated => 'Deactivated';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profileTakePhoto => 'Take a photo';

  @override
  String get profileChoosePhoto => 'Choose a photo';

  @override
  String get profileRemovePhoto => 'Remove photo';

  @override
  String get profilePhotoSaved => 'Photo saved.';

  @override
  String get profileContact => 'Contact';

  @override
  String get profilePhone => 'Phone';

  @override
  String get profilePhoneHelp => 'For example 024 123 4567.';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileAddress => 'Address or landmark';

  @override
  String get profileEmergency => 'Emergency contact';

  @override
  String get profileEmergencyName => 'Name and relationship';

  @override
  String get profileIdentityWork => 'Identity and work';

  @override
  String get profileManagerOnly => 'Only a manager can change these.';

  @override
  String get profileGhanaCard => 'Ghana Card number';

  @override
  String get profileGhanaCardHelp => 'For example GHA-123456789-0.';

  @override
  String get profileDateOfBirth => 'Date of birth';

  @override
  String get profileStartedOn => 'Started work';

  @override
  String get profileNotes => 'Notes';

  @override
  String get profilePhoneInvalid =>
      'That doesn\'t look like a Ghana phone number.';

  @override
  String get profileEmailInvalid => 'That doesn\'t look like an email address.';

  @override
  String get profileIdInvalid =>
      'A Ghana Card number looks like GHA-123456789-0.';

  @override
  String get profileSaved => 'Details saved.';

  @override
  String get profileCurrentPin => 'Current PIN';

  @override
  String get profilePinReason => 'Change someone else\'s PIN.';

  @override
  String get profilePerformance => 'Performance';

  @override
  String get profileSalesToday => 'Sales today';

  @override
  String get profileSales30 => 'Last 30 days';

  @override
  String get profileAverageSale => 'Average sale';

  @override
  String get profileVoids => 'Voids';

  @override
  String get profileCloses => 'Day closes';

  @override
  String get profileClosesBalanced => 'All balanced';

  @override
  String get profileSecurity => 'Security';

  @override
  String get profileLastSignIn => 'Last signed in';

  @override
  String get profileWrongPins => 'Wrong PINs';

  @override
  String get profileRecentActivity => 'Recent activity';

  @override
  String get navProducts => 'Products';

  @override
  String get navStock => 'Stock';

  @override
  String get activityFilterCatalogue => 'Products and stock';

  @override
  String get auditProductCreated => 'Product added';

  @override
  String get auditProductUpdated => 'Product changed';

  @override
  String get auditProductArchived => 'Product archived';

  @override
  String get auditProductRestored => 'Product restored';

  @override
  String get auditPriceChanged => 'Price changed';

  @override
  String get auditCategorySaved => 'Category changed';

  @override
  String get auditOptionGroupSaved => 'Options changed';

  @override
  String get auditTaxRateSaved => 'Tax changed';

  @override
  String get auditStockItemSaved => 'Stock item changed';

  @override
  String get auditStockReceived => 'Delivery received';

  @override
  String get auditStockAdjusted => 'Stock corrected';

  @override
  String get auditStockWasted => 'Waste logged';

  @override
  String get auditStockCountPosted => 'Stock count posted';

  @override
  String get auditSupplierSaved => 'Supplier changed';

  @override
  String get auditSupplierPaid => 'Supplier paid';

  @override
  String get auditPriceScheduled => 'Price scheduled';

  @override
  String get auditPricesBulkChanged => 'Prices changed in bulk';

  @override
  String get auditCatalogueImported => 'Products imported';

  @override
  String get cartTax => 'Tax';

  @override
  String get cartTaxIncluded => 'Includes tax';

  @override
  String get cartTotal => 'Total';

  @override
  String get tileOut => 'None left';

  @override
  String get pickerSize => 'Size';

  @override
  String get pickerRemoveOne => 'One less';

  @override
  String get groupOptional => 'Optional';

  @override
  String get productsTab => 'Products';

  @override
  String get categoriesTab => 'Categories';

  @override
  String get optionsTab => 'Options';

  @override
  String get taxTab => 'Tax';

  @override
  String get productsNew => 'New product';

  @override
  String get productsSearch => 'Search name or barcode';

  @override
  String get productsAllCategories => 'All categories';

  @override
  String get productsFilterAll => 'All';

  @override
  String get productsFilterOnTill => 'On the till';

  @override
  String get productsFilterOffTill => 'Off the till';

  @override
  String get productsFilterLowMargin => 'Low margin';

  @override
  String get productsFilterArchived => 'Archived';

  @override
  String get productsNone => 'No products here.';

  @override
  String get productsNoCost => 'No cost set';

  @override
  String get productsDuplicate => 'Duplicate';

  @override
  String get productsArchive => 'Archive';

  @override
  String get productsRestore => 'Restore';

  @override
  String get productsArchiveBody =>
      'It comes off the till and the lists. Past sales keep it, and you can restore it later.';

  @override
  String get productsEditReason => 'Change products.';

  @override
  String get productsArchiveReason => 'Archive a product.';

  @override
  String get productsDuplicateReason => 'Copy a product.';

  @override
  String get categoriesNew => 'New category';

  @override
  String get categoriesEdit => 'Change category';

  @override
  String get categoriesName => 'Category name';

  @override
  String get categoriesColour => 'Colour';

  @override
  String get categoriesInside => 'Put it inside';

  @override
  String get categoriesTopLevel => 'Nothing (top level)';

  @override
  String get categoriesHidden => 'Hidden';

  @override
  String get categoriesNone => 'No categories yet.';

  @override
  String get optionsNew => 'New options';

  @override
  String get optionsEdit => 'Change options';

  @override
  String get optionsName => 'Name';

  @override
  String get optionsNameHelp => 'For example Toppings, Sugar level or Sauce.';

  @override
  String get optionsMin => 'Must pick at least';

  @override
  String get optionsMinHelp => '0 makes it optional.';

  @override
  String get optionsMax => 'Can pick up to';

  @override
  String get optionsMaxHelp => 'Empty: no limit.';

  @override
  String get optionsRepeat => 'The same option can be picked twice';

  @override
  String get optionsRepeatHelp => 'For example double sprinkles.';

  @override
  String get optionsOptionName => 'Option';

  @override
  String get optionsExtra => 'Extra';

  @override
  String get optionsRemove => 'Remove option';

  @override
  String get optionsDefault => 'Ticked when the picker opens';

  @override
  String get optionsAdd => 'Add option';

  @override
  String get optionsNone => 'No options yet.';

  @override
  String get optionsUnused => 'Not on any product yet.';

  @override
  String get taxModeTitle => 'How tax works here';

  @override
  String get taxModeOff => 'No tax';

  @override
  String get taxModeInclusive => 'Prices include tax';

  @override
  String get taxModeExclusive => 'Add tax at the till';

  @override
  String get taxModeHelp =>
      'Most shops in Ghana show prices with tax included. Only turn tax on if the shop is registered.';

  @override
  String get taxRates => 'Tax rates';

  @override
  String get taxNone => 'No tax rates.';

  @override
  String get taxNew => 'New tax rate';

  @override
  String get taxEdit => 'Change tax rate';

  @override
  String get taxName => 'Name';

  @override
  String get taxNameHelp => 'As it should appear on receipts.';

  @override
  String get taxRate => 'Rate';

  @override
  String get taxRateInvalid => 'Enter a rate like 15 or 2.5.';

  @override
  String get taxCompound => 'Charged on top of the other taxes';

  @override
  String get taxCompoundHelp =>
      'VAT in Ghana is charged on the price plus NHIL and GETFund.';

  @override
  String get taxApprovalReason => 'Change tax settings.';

  @override
  String get taxAccountant =>
      'Check the rates and which products they apply to with your accountant. Aby does not decide tax for you.';

  @override
  String get editorTitle => 'Change product';

  @override
  String get editorSaved => 'Product saved.';

  @override
  String get editorName => 'Product name';

  @override
  String get editorCategory => 'Category';

  @override
  String get editorTileLine => 'Size line on the tile';

  @override
  String get editorTileLineHelp => 'Optional, for example \"500 ml\".';

  @override
  String get editorDescription => 'Description';

  @override
  String get editorOnTill => 'On the till';

  @override
  String get editorOnTillHelp => 'Off: kept, but cashiers cannot sell it.';

  @override
  String get editorPrices => 'Prices';

  @override
  String get editorPricesHelp =>
      'One price, or several sizes or kinds, each with its own price and recipe.';

  @override
  String get editorAddSizes => 'Add sizes or kinds';

  @override
  String get editorAddVariant => 'Add another';

  @override
  String get editorVariantName => 'Size or kind';

  @override
  String get editorVariantNameHelp =>
      'For example Small, Double scoop, 500 ml.';

  @override
  String get editorPrice => 'Price';

  @override
  String get editorCost => 'Cost';

  @override
  String get editorCostFromRecipe => 'From the recipe';

  @override
  String get editorCostHelp => 'Optional';

  @override
  String get editorMoveUp => 'Move up';

  @override
  String get editorMoveDown => 'Move down';

  @override
  String get editorRemoveVariant => 'Remove';

  @override
  String get editorBarcodes => 'Barcodes and codes';

  @override
  String get editorAddBarcode => 'Add barcode';

  @override
  String get editorBarcode => 'Barcode';

  @override
  String get editorBarcodeHelp =>
      'Scan it, or type a short code (like 12) that rings this up when typed at the till.';

  @override
  String get editorOptions => 'Options';

  @override
  String get editorNoOptions =>
      'No option groups yet. Add them on the Options tab.';

  @override
  String get editorTaxes => 'Taxes';

  @override
  String get editorNoTaxes => 'No tax rates. Set them up on the Tax tab.';

  @override
  String get editorTaxesHelp => 'Only used when tax is on (Products, Tax).';

  @override
  String get editorPriceMissing => 'Enter a price for each size or kind.';

  @override
  String get editorCostInvalid => 'Check the cost.';

  @override
  String get editorRecipeInvalid => 'Check the recipe amounts.';

  @override
  String get editorCategoryMissing => 'Pick a category.';

  @override
  String get editorPriceReason => 'Change prices.';

  @override
  String get recipeUses => 'What it uses';

  @override
  String get recipeHelp =>
      'Each sale takes these from stock and works out the cost.';

  @override
  String get recipeItem => 'Stock item';

  @override
  String get recipeAmount => 'Amount';

  @override
  String get recipeRemove => 'Remove';

  @override
  String get recipeAdd => 'Add stock item';

  @override
  String get recipeNoStockItems => 'Add stock items first (Stock)';

  @override
  String get stockNew => 'New stock item';

  @override
  String get stockEdit => 'Change stock item';

  @override
  String get stockSearch => 'Search stock';

  @override
  String get stockFilterAll => 'All';

  @override
  String get stockFilterRetired => 'Retired';

  @override
  String get stockNone => 'No stock items here.';

  @override
  String get stockLow => 'Low';

  @override
  String get stockName => 'Name';

  @override
  String get stockNameHelp =>
      'What you buy, for example Wafer cones or Vanilla ice cream.';

  @override
  String get stockUnit => 'Counted in';

  @override
  String get unitPieces => 'Pieces';

  @override
  String get unitWeight => 'Weight (g, kg)';

  @override
  String get unitVolume => 'Volume (ml, L)';

  @override
  String get stockCostHelp => 'Deliveries update this to the average cost.';

  @override
  String get stockReorderAt => 'Low below';

  @override
  String get stockReorderQty => 'Usually order';

  @override
  String get stockReorderHelp => 'Both optional.';

  @override
  String get stockCostInvalid => 'Check the cost.';

  @override
  String get stockQuantityInvalid => 'Check the amount.';

  @override
  String get stockEditReason => 'Change stock items.';

  @override
  String get stockOnHand => 'On hand';

  @override
  String get stockHistory => 'History';

  @override
  String get stockNoMovements => 'Nothing yet.';

  @override
  String get stockLogWaste => 'Log waste';

  @override
  String get stockAdjust => 'Correct stock';

  @override
  String get stockRetire => 'Retire';

  @override
  String get stockRestore => 'Restore';

  @override
  String get stockUsedBy => 'Used by';

  @override
  String get stockUsedByNone => 'No product uses it yet.';

  @override
  String get stockLess => 'There is less';

  @override
  String get stockMore => 'There is more';

  @override
  String get stockHowMuch => 'How much';

  @override
  String get stockNoteOptional => 'Note (optional)';

  @override
  String get stockWhy => 'Why';

  @override
  String get stockAdjusted => 'Stock corrected.';

  @override
  String get stockWasted => 'Waste logged.';

  @override
  String get moveSale => 'Sold';

  @override
  String get moveReceived => 'Delivery';

  @override
  String get moveAdjustment => 'Correction';

  @override
  String get moveCount => 'Stock count';

  @override
  String get wasteMelted => 'Melted';

  @override
  String get wastePowerCut => 'Power cut';

  @override
  String get wasteExpired => 'Expired';

  @override
  String get wasteDamaged => 'Dropped or damaged';

  @override
  String get wasteStaffMeal => 'Staff';

  @override
  String get wasteSample => 'Free sample';

  @override
  String get wasteOther => 'Other';

  @override
  String get stockItemsTab => 'Items';

  @override
  String get deliveriesTab => 'Deliveries';

  @override
  String get countsTab => 'Counts';

  @override
  String get suppliersTab => 'Suppliers';

  @override
  String get exportButton => 'Export';

  @override
  String get exportWhere => 'Where should the file go?';

  @override
  String exportTitle(String what) {
    return 'Export $what';
  }

  @override
  String get exportExcel => 'Excel workbook';

  @override
  String get exportExcelHelp =>
      'In Aby colours, with totals and filters. Opens in Excel, Google Sheets and Numbers.';

  @override
  String get exportPdfHelp =>
      'Ready to print, or to send on WhatsApp or by email.';

  @override
  String get exportCsvHelp => 'Plain data for other software.';

  @override
  String get exportCsvImportHelp =>
      'Plain data. Edit it and import it back into Aby.';

  @override
  String get exportShare => 'Share';

  @override
  String get exportSave => 'Save to a folder';

  @override
  String get exportMaking => 'Making the file...';

  @override
  String get printHow => 'Print or share?';

  @override
  String get printOnPrinter => 'On the receipt printer';

  @override
  String get printAsPdf => 'As a PDF (share or save)';

  @override
  String get printNoPrinterPdf =>
      'No receipt printer here. Share or save it as a PDF instead:';

  @override
  String get reportExportAll => 'Export the report';

  @override
  String get importPick => 'Pick the CSV file';

  @override
  String get productsTools => 'Tools';

  @override
  String get receiveNew => 'Receive delivery';

  @override
  String get receiveSave => 'Save delivery';

  @override
  String get receiveSupplier => 'Supplier';

  @override
  String get receiveNoSupplier => 'No supplier (paid in full)';

  @override
  String get receiveInvoice => 'Invoice or receipt number';

  @override
  String get receiveWhatCame => 'What came';

  @override
  String get receiveAddLow => 'Add everything low';

  @override
  String get receiveAddLine => 'Add item';

  @override
  String get receiveLineCost => 'Cost of these';

  @override
  String get receiveTotal => 'Delivery total';

  @override
  String get receivePaidNow => 'Paid now';

  @override
  String get receivePaidNowHelp =>
      'The rest is added to what you owe this supplier.';

  @override
  String get receivePaidNowNoSupplier =>
      'Without a supplier the delivery must be paid in full.';

  @override
  String get receivePaidInvalid => 'Check the amount paid.';

  @override
  String get receiveReason => 'Receive a delivery.';

  @override
  String get payCash => 'Cash';

  @override
  String get payMomo => 'Mobile money';

  @override
  String get payBank => 'Bank';

  @override
  String get payOther => 'Other';

  @override
  String get deliveriesNone => 'No deliveries yet.';

  @override
  String get countStart => 'Start a count';

  @override
  String get countContinue => 'Continue the count';

  @override
  String get countBlind => 'Blind: counters do not see what the till expects';

  @override
  String get countOpen => 'Open: show what the till expects';

  @override
  String get countStartReason => 'Start a stock count.';

  @override
  String get countTitle => 'Stock count';

  @override
  String get countsNone => 'No counts yet.';

  @override
  String get countOpenStatus => 'Open';

  @override
  String get countCancelledStatus => 'Cancelled';

  @override
  String get countBlindShort => 'Blind';

  @override
  String get countCancel => 'Cancel count';

  @override
  String get countCancelTitle => 'Cancel this count?';

  @override
  String get countCancelBody =>
      'What was counted is kept for the record, but stock does not change.';

  @override
  String get countPost => 'Post count';

  @override
  String get countPostTitle => 'Post the count?';

  @override
  String get countPostReason => 'Post a stock count.';

  @override
  String get countPostedSame => 'Count posted. Everything matched.';

  @override
  String get countNoDifference => 'No differences so far';

  @override
  String get countFound => 'Found';

  @override
  String get suppliersNone => 'No suppliers yet.';

  @override
  String get supplierNew => 'New supplier';

  @override
  String get supplierEdit => 'Change supplier';

  @override
  String get supplierName => 'Supplier name';

  @override
  String get supplierTerms => 'Days to pay';

  @override
  String get supplierTermsHelp => 'Leave empty if you pay on delivery.';

  @override
  String get supplierDays => 'days';

  @override
  String get supplierSettled => 'Nothing owed';

  @override
  String get supplierEditReason => 'Change suppliers.';

  @override
  String get supplierBalance => 'Balance';

  @override
  String get supplierPay => 'Record a payment';

  @override
  String get supplierAmount => 'Amount paid';

  @override
  String get supplierReference => 'Reference (optional)';

  @override
  String get supplierLedger => 'Account';

  @override
  String get supplierEntryPurchase => 'Delivery';

  @override
  String get stockUsage => 'Use';

  @override
  String get stockUsePerDay => 'Uses about, per day';

  @override
  String get stockNotUsed => 'Not used in the last 4 weeks';

  @override
  String get stockLasts => 'Lasts about';

  @override
  String get stockSuggestedLow => 'Suggested low level';

  @override
  String get stockSuggestedHelp => 'Three days of use, plus half again.';

  @override
  String get stockUseThis => 'Use this';

  @override
  String get bulkTitle => 'Change prices in bulk';

  @override
  String get bulkRaise => 'Raise';

  @override
  String get bulkLower => 'Lower';

  @override
  String get bulkNoRounding => 'No rounding';

  @override
  String get importTitle => 'Import products';

  @override
  String get importApply => 'Import';

  @override
  String get editorSchedule => 'Schedule a new price';

  @override
  String get editorScheduleWhen => 'From which day?';

  @override
  String get auditCartCleared => 'Cart cleared';

  @override
  String get auditCartLinesRemoved => 'Taken off a cart';

  @override
  String get auditDiscountSaved => 'Saved discount changed';

  @override
  String get auditDiscountsGiven => 'Discounts given';

  @override
  String get auditOrderParked => 'Order parked';

  @override
  String get auditParkedOrderDiscarded => 'Parked order discarded';

  @override
  String get auditPriceOverridden => 'Price overridden';

  @override
  String get auditReasonSaved => 'Reasons list changed';

  @override
  String get cartTitle => 'Current sale';

  @override
  String get cartEmpty => 'Tap a product, scan a barcode, or type to search.';

  @override
  String get cartClear => 'Clear the cart';

  @override
  String get cartClearTitle => 'Clear the cart?';

  @override
  String get cartSubtotal => 'Before discounts';

  @override
  String get cartDiscount => 'Discounts';

  @override
  String get cartOneLess => 'One less';

  @override
  String get cartOneMore => 'One more';

  @override
  String get cartOrderDiscount => 'Discount on the whole sale';

  @override
  String get cartWholeOrder => 'the whole sale';

  @override
  String get cartAddNote => 'Add a note';

  @override
  String get cartEditNote => 'Change the note';

  @override
  String get cartNoteTitle => 'Note for this sale';

  @override
  String get cartNote => 'Note';

  @override
  String get cartNoteHelp =>
      'Printed on the order ticket, e.g. \"Collect at 3 pm\".';

  @override
  String get orderTakeaway => 'Takeaway';

  @override
  String get orderEatIn => 'Eat in';

  @override
  String get orderDelivery => 'Delivery';

  @override
  String get parkButton => 'Park';

  @override
  String get parkTitle => 'Park this sale';

  @override
  String get parkName => 'Name or table';

  @override
  String get parkNameHelp =>
      'So you can find it again: \"Blue shirt\", \"Table 4\".';

  @override
  String get parkGone => 'Another till already opened that order.';

  @override
  String get parkRename => 'Rename';

  @override
  String get parkMerge => 'Add to this sale';

  @override
  String get parkDiscard => 'Throw away';

  @override
  String get parkDiscardBody =>
      'The order is removed without a sale. This is recorded in Activity.';

  @override
  String get discountSaved => 'Saved discounts';

  @override
  String get discountPercent => 'Percent off';

  @override
  String get discountAmount => 'Amount off';

  @override
  String get discountReason => 'Reason';

  @override
  String get discountOff => 'Comes off';

  @override
  String get discountRemove => 'Remove discount';

  @override
  String get discountApply => 'Apply';

  @override
  String get discountPickReason => 'Pick a reason.';

  @override
  String get discountPercentInvalid => 'Enter a percentage from 1 to 100.';

  @override
  String get discountAmountInvalid => 'Enter the amount off.';

  @override
  String get discountNew => 'New discount';

  @override
  String get discountEdit => 'Change discount';

  @override
  String get discountName => 'Name';

  @override
  String get discountNameHelp => 'As the cashier will see it: \"Student 10%\".';

  @override
  String get discountScope => 'Use it on';

  @override
  String get discountScopeLine => 'Items';

  @override
  String get discountScopeOrder => 'Whole sale';

  @override
  String get discountScopeAny => 'Both';

  @override
  String get discountsNone => 'No saved discounts yet.';

  @override
  String get editorSelling => 'Selling';

  @override
  String get editorQuickTab => 'On the Quick tab';

  @override
  String get editorQuickTabHelp =>
      'The first tab on the till, for the things you sell most.';

  @override
  String get editorSellBy => 'Sold by';

  @override
  String get editorSellByEachHelp => 'Counted: 1, 2, 3...';

  @override
  String get editorSellByWeightHelp =>
      'The price is per kg or litre and the till asks how much. Recipes are per kg or litre too.';

  @override
  String get editorOpenPrice => 'Price typed at the till';

  @override
  String get editorOpenPriceHelp =>
      'For \"Miscellaneous\", repairs and the like. The price above is the suggestion.';

  @override
  String get editorMinPrice => 'Lowest price (optional)';

  @override
  String get editorMaxPrice => 'Highest price (optional)';

  @override
  String get editorLimitsInvalid => 'Check the lowest and highest prices.';

  @override
  String get sellByEach => 'Each';

  @override
  String get sellByKg => 'Weight (kg)';

  @override
  String get sellByLitre => 'Volume (litre)';

  @override
  String get entryAdd => 'Add';

  @override
  String get entryPrice => 'Price';

  @override
  String get entryWeight => 'Weight';

  @override
  String get entryVolume => 'How much';

  @override
  String get lineQuantity => 'Quantity';

  @override
  String get lineQuantityInvalid => 'Enter a quantity of at least 1.';

  @override
  String get linePrice => 'Price for one';

  @override
  String get linePriceHelp =>
      'Changing it needs permission to override prices.';

  @override
  String get lineNote => 'Note';

  @override
  String get lineNoteHelp =>
      'For the kitchen or the order ticket, e.g. \"no nuts\".';

  @override
  String get lineAddDiscount => 'Add a discount';

  @override
  String get lineDiscount => 'Discount';

  @override
  String get lineChangePick => 'Change size or options';

  @override
  String get lineRemove => 'Remove';

  @override
  String get overrideRefused => 'The price was not changed.';

  @override
  String get quickArrange => 'Arrange the Quick tab';

  @override
  String get quickArrangeHelp =>
      'Drag to reorder. Add products from the list below.';

  @override
  String get quickRemove => 'Take off the Quick tab';

  @override
  String get quickAddHint => 'Find a product to add';

  @override
  String get quickArrangeReason => 'Change the Quick tab.';

  @override
  String get reasonsDiscount => 'Discount reasons';

  @override
  String get reasonsVoid => 'Void reasons';

  @override
  String get reasonsRefund => 'Refund reasons';

  @override
  String get reasonsNoSale => 'No-sale reasons';

  @override
  String get reasonNew => 'New reason';

  @override
  String get reasonEdit => 'Change reason';

  @override
  String get reasonName => 'Reason';

  @override
  String get settingsGroupSelling => 'Selling';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsOrderTypes => 'Takeaway, eat in or delivery';

  @override
  String get settingsOrderTypesHelp =>
      'Ask on each sale; shown on the order ticket.';

  @override
  String get settingsNegativeStock => 'Sell when out of stock';

  @override
  String get settingsNegativeStockHelp =>
      'The till warns but still sells. Off: it refuses.';

  @override
  String get settingsDiscounts => 'Saved discounts';

  @override
  String get settingsDiscountsHelp =>
      'Named discounts cashiers can pick: \"Student 10%\", \"Staff meal GH₵ 5 off\".';

  @override
  String get settingsScalePrefix => 'Scale barcodes';

  @override
  String get settingsScalePrefixHelp =>
      'The first digits your scale prints (often 2 or 21). Leave empty if you have no scale.';

  @override
  String get settingsScaleValue => 'The scale barcode holds';

  @override
  String get settingsScaleWeight => 'The weight';

  @override
  String get settingsScalePrice => 'The price';

  @override
  String get settingsParkedWarn => 'Warn about parked orders after';

  @override
  String get settingsParkedWarnHelp =>
      'Close day shows parked orders older than this.';

  @override
  String get settingsTiles => 'Till tile size';

  @override
  String get settingsTilesSmall => 'Small';

  @override
  String get settingsTilesMedium => 'Medium';

  @override
  String get settingsTilesLarge => 'Large';

  @override
  String get tileOpenPrice => 'Any price';

  @override
  String get tillQuick => 'Quick';

  @override
  String get tillAll => 'All';

  @override
  String get tillRecent => 'Recent';

  @override
  String get tillSearchHint => 'Search, scan, or type a code';

  @override
  String get tillNoMatch =>
      'Check the spelling, or press Enter to look it up as a code.';

  @override
  String get tillNothingHere => 'Nothing here yet.';

  @override
  String get tillQuickEmpty => 'Nothing on the Quick tab yet.';

  @override
  String get tillCodeUnknownBody => 'Add a new product with this barcode?';

  @override
  String get tillCodeCreate => 'New product';

  @override
  String get tillPriceInvalid => 'Enter the price.';

  @override
  String get tillWeightInvalid => 'Enter how much.';

  @override
  String get commonEdit => 'Change';

  @override
  String get auditNoSale => 'Drawer opened (no sale)';

  @override
  String get auditPayMethodSaved => 'Payment method changed';

  @override
  String get auditRefundGiven => 'Refund given';

  @override
  String get moveReturned => 'Returned (refund)';

  @override
  String get cartExchangeCancel => 'Cancel the exchange';

  @override
  String get checkoutTitle => 'Payment';

  @override
  String get checkoutBack => 'Back to the till';

  @override
  String get checkoutComplete => 'Complete sale';

  @override
  String get checkoutReturned => 'Returned items';

  @override
  String get checkoutLeftToPay => 'Left to pay';

  @override
  String get checkoutRemovePayment => 'Remove this payment';

  @override
  String get checkoutAmount => 'Amount';

  @override
  String get checkoutAmountHelp => 'Leave as it is to pay the rest this way.';

  @override
  String get checkoutReferenceHelp =>
      'Required, from the payment message. Each one can only be used once.';

  @override
  String get checkoutReferenceShort =>
      'The last 4 characters are enough. Each one can only be used once.';

  @override
  String get checkoutCashGiven => 'Cash given';

  @override
  String get checkoutExact => 'Exact';

  @override
  String get checkoutStillToPay => 'Still to pay';

  @override
  String get checkoutChange => 'Change due';

  @override
  String get checkoutDone => 'Sale complete';

  @override
  String get checkoutNewSale => 'New sale';

  @override
  String get checkoutSavedHere =>
      'Saved on this device. Will sync when you\'re online.';

  @override
  String get checkoutGiveBackNow => 'Give back';

  @override
  String get checkoutSaveFailed => 'Could not save the sale. Try again.';

  @override
  String get exchangeAlready =>
      'An exchange is already waiting on the till. Finish or cancel it first.';

  @override
  String get noSaleButton => 'Open the drawer (no sale)';

  @override
  String get noSaleTitle => 'Why open the drawer?';

  @override
  String get noSaleApprovalReason => 'Open the drawer without a sale.';

  @override
  String get noSaleDone => 'Drawer opened. This is recorded.';

  @override
  String get payKindCash => 'Cash';

  @override
  String get payKindMomo => 'Mobile money';

  @override
  String get payKindCredit => 'Credit (book)';

  @override
  String get payKindCard => 'Card';

  @override
  String get payKindBank => 'Bank transfer';

  @override
  String get payKindCheque => 'Cheque';

  @override
  String get payKindExchange => 'Exchange';

  @override
  String get payKindOther => 'Other';

  @override
  String get payMethodNew => 'New payment method';

  @override
  String get payMethodEdit => 'Change payment method';

  @override
  String get payMethodName => 'Name';

  @override
  String get payMethodKind => 'Kind of payment';

  @override
  String get payMerchantNumber => 'Your number or merchant ID (optional)';

  @override
  String get payMerchantNumberHelp =>
      'Shown large, with a QR code, for the customer to pay to.';

  @override
  String get payNeedsReference => 'Needs a transaction ID';

  @override
  String get payNeedsReferenceHelp =>
      'The cashier types it from the payment message; it cannot be used twice.';

  @override
  String get payShortReference => 'The last 4 characters are enough';

  @override
  String get payShortReferenceHelp =>
      'Faster, but only checked for reuse over two days.';

  @override
  String get refundNoReceiptTitle => 'Refund without a receipt';

  @override
  String get refundVoided =>
      'This sale was voided: there is nothing to refund.';

  @override
  String get refundNothingLeft => 'Everything on this sale has been refunded.';

  @override
  String get refundWhatComesBack => 'What comes back';

  @override
  String get refundEverything => 'Everything';

  @override
  String get refundRestock => 'Back into stock';

  @override
  String get refundRestockHelp => 'It can be sold again.';

  @override
  String get refundDamagedHelp => 'Damaged: it does not go back into stock.';

  @override
  String get refundReason => 'Reason';

  @override
  String get refundHow => 'Give the money back by';

  @override
  String get refundReference => 'Transaction ID (optional)';

  @override
  String get refundReferenceHelp => 'Of the money sent back, for the record.';

  @override
  String get refundTotal => 'Refund';

  @override
  String get refundExchange => 'Exchange instead';

  @override
  String get refundExchangeHelp =>
      'The returned items pay for new ones on the till; only the difference is paid or given back.';

  @override
  String get refundPickReason => 'Pick a reason.';

  @override
  String get refundNoReceiptHelp =>
      'Without a receipt: a manager approves with their PIN, and it is marked in reports.';

  @override
  String get refundAmount => 'Give back';

  @override
  String get refundAddItem => 'Find what is coming back';

  @override
  String get refundGiveBack => 'Give back';

  @override
  String get settingsGroupPayments => 'Payments';

  @override
  String get settingsPayMethods => 'Payment methods';

  @override
  String get settingsPayMethodsHelp =>
      'MTN MoMo, Telecel Cash, card, bank... Switch on what you take and add your merchant number.';

  @override
  String get settingsRounding => 'Round cash totals';

  @override
  String get settingsRoundingHelp =>
      'When there are no small coins. The rounding is recorded on each sale.';

  @override
  String get settingsRound10 => 'To the nearest 10 pesewas';

  @override
  String get settingsRound50 => 'To the nearest 50 pesewas';

  @override
  String get todayClosed => 'Closed';

  @override
  String get todayFind => 'Find a sale';

  @override
  String get todayFindLabel => 'Sale number';

  @override
  String get todayFindHelp => 'From the receipt, e.g. 142 for #00142.';

  @override
  String get todayFindButton => 'Find';

  @override
  String get todayNoReceipt => 'no receipt';

  @override
  String get todayRefund => 'Refund';

  @override
  String get todayRefundNoReceipt => 'Refund without a receipt';

  @override
  String get todayRefundedAll => 'Refunded';

  @override
  String get todayRefunds => 'Refunds';

  @override
  String get todaySalesCount => 'Number of sales';

  @override
  String get todayTotalSales => 'Total sales';

  @override
  String get todayVoid => 'Void';

  @override
  String get todayVoided => 'Voided';

  @override
  String get voidWhy => 'Why?';

  @override
  String get photoPickerUnavailable =>
      'Photos cannot be picked on this device right now. Close Aby fully and open it again.';

  @override
  String get navCustomers => 'Customers';

  @override
  String get permManageCustomers => 'Look after customers and their accounts';

  @override
  String get payKindWallet => 'Wallet';

  @override
  String get auditCreditWrittenOff => 'Credit written off';

  @override
  String get auditCustomerCreditLimit => 'Credit limit';

  @override
  String get auditCustomerRepaid => 'Customer paid';

  @override
  String get auditCustomerSaved => 'Customer changed';

  @override
  String get auditWalletTopUp => 'Money into a wallet';

  @override
  String get cartAddCustomer => 'Add a customer';

  @override
  String get cartRemoveCustomer => 'Take the customer off';

  @override
  String get checkoutChooseCustomer => 'Choose the customer';

  @override
  String get customerNew => 'New customer';

  @override
  String get customerEdit => 'Change details';

  @override
  String get customerQuickAdd => 'New customer';

  @override
  String get customerPick => 'Customer';

  @override
  String get customerName => 'Name';

  @override
  String get customerPhoneHelp =>
      'Their main number: how you find them at the till.';

  @override
  String get customerPhone2 => 'Second phone (optional)';

  @override
  String get customerLocation => 'Where they are (optional)';

  @override
  String get customerLocationHelp =>
      'As they give directions: \"near the mosque, Lamashegu\".';

  @override
  String get customerBirthday => 'Birthday';

  @override
  String get customerTags => 'Tags';

  @override
  String get customerTagsHelp => 'Separated by commas: Wholesale, Staff.';

  @override
  String get customerLimit => 'Credit limit (optional)';

  @override
  String get customerLimitHelp => 'The most they may owe. Empty: no limit.';

  @override
  String get customerLimitInvalid => 'Check the credit limit.';

  @override
  String get customerDueDays => 'Days to pay (optional)';

  @override
  String get customerDueDaysHelp => 'After this a credit sale is overdue.';

  @override
  String get customerSearchHint => 'Phone (4 digits are enough) or name';

  @override
  String get customersNone => 'No customers yet.';

  @override
  String get customersOwing => 'Owe money';

  @override
  String get customerOwesLabel => 'Owes';

  @override
  String get customerWalletLabel => 'Wallet';

  @override
  String get customerRecordPayment => 'Record a payment';

  @override
  String get customerAddToWallet => 'Add money to the wallet';

  @override
  String get customerStatement => 'Statement';

  @override
  String get customerRemind => 'Send a reminder';

  @override
  String get customerWriteOff => 'Write off';

  @override
  String get customerWriteOffWhy => 'Why is it written off?';

  @override
  String get customerRemindMessage => 'Message';

  @override
  String get customerRemindWhatsApp => 'Open WhatsApp';

  @override
  String get customerEditReason => 'Change customer details.';

  @override
  String get customerAmountInvalid => 'Enter the amount.';

  @override
  String get customerNoPhone => 'Add a phone number first.';

  @override
  String get customerCannotOpen =>
      'WhatsApp could not be opened on this device.';

  @override
  String get customerHabits => 'Buying';

  @override
  String get customerSpend => 'Spent in all';

  @override
  String get customerVisits => 'Visits';

  @override
  String get customerLastVisit => 'Last visit';

  @override
  String get customerFavourites => 'Buys most';

  @override
  String get customerUnpaid => 'Still owed';

  @override
  String get customerAccount => 'Account';

  @override
  String get customerNoEntries => 'Nothing on the account yet.';

  @override
  String get customerSales => 'Sales';

  @override
  String get customerPayFor => 'Pay for';

  @override
  String get customerOldestFirst => 'Oldest first';

  @override
  String get settingsOverLimit => 'Credit over the limit';

  @override
  String get settingsOverLimitHelp =>
      'When a credit sale takes a customer over their limit.';

  @override
  String get settingsOverLimitApprove =>
      'Someone allowed approves with their PIN';

  @override
  String get settingsOverLimitBlock => 'Not allowed';

  @override
  String get settingsReminder => 'Credit reminder message';

  @override
  String get settingsReminderHelp =>
      'The customer\'s name, what they owe and the shop\'s name are filled in.';

  @override
  String get permManageCash => 'Look after the safe and check MoMo';

  @override
  String get reasonsPayIn => 'Pay-in reasons';

  @override
  String get reasonsPayOut => 'Pay-out reasons';

  @override
  String get auditBankDeposit => 'Banked from the safe';

  @override
  String get auditCashPaidIn => 'Cash put in';

  @override
  String get auditCashPaidOut => 'Cash taken out';

  @override
  String get auditMomoChecked => 'MoMo payment missing';

  @override
  String get auditSafeDrop => 'Cash to the safe';

  @override
  String get auditShiftOpened => 'Shift opened';

  @override
  String get todayCash => 'Cash';

  @override
  String get xReportTitle => 'X report (so far)';

  @override
  String get shiftOpen => 'Open the shift';

  @override
  String get shiftOpenHelp =>
      'Count the float: the cash in the drawer before the first sale.';

  @override
  String get shiftCountFloat => 'Count the float';

  @override
  String get shiftOpenReason => 'Open the shift.';

  @override
  String get shiftAlreadyOpen => 'A shift is already open on this till.';

  @override
  String get payInTitle => 'Put cash in';

  @override
  String get payOutTitle => 'Take cash out';

  @override
  String get cashAddReceipt => 'Photo of the receipt';

  @override
  String get cashReceiptAdded => 'Photo added';

  @override
  String get safeTitle => 'Safe';

  @override
  String get safeBalance => 'In the safe';

  @override
  String get safeEntries => 'In and out';

  @override
  String get safeNone => 'Nothing in the safe yet.';

  @override
  String get safeDropTitle => 'Move cash to the safe';

  @override
  String get safeDropHelp =>
      'Keeps the drawer low. It comes off what the drawer should hold.';

  @override
  String get safeAdjustment => 'Correction';

  @override
  String get bankDepositTitle => 'Take to the bank';

  @override
  String get bankName => 'Bank';

  @override
  String get bankSlip => 'Slip number (optional)';

  @override
  String get bankSlipPhoto => 'Photo of the slip';

  @override
  String get momoTitle => 'Check MoMo';

  @override
  String get momoHelp =>
      'Tap each payment once it is on your MoMo statement (tap again if it is missing).';

  @override
  String get momoSummary => 'This day';

  @override
  String get momoCharges => 'Charges and e-levy';

  @override
  String get momoChargesHelp => 'Taken off by MoMo. Tap to enter.';

  @override
  String get momoNet => 'Should be in the MoMo wallet';

  @override
  String get momoTicked => 'Found on the statement';

  @override
  String get momoPayments => 'Payments';

  @override
  String get momoNone => 'No MoMo payments on this day.';

  @override
  String get momoNoReference => 'No reference';

  @override
  String get countCashTitle => 'Count the cash';

  @override
  String get countCashButton => 'Count notes';

  @override
  String get countCashUse => 'Use this total';

  @override
  String get closeSinceFirst => 'Since the first sale';

  @override
  String get closeDiscounts => 'Discounts';

  @override
  String get closeFloat => 'Float at the start';

  @override
  String get closeCustomerCash => 'Cash from customers';

  @override
  String get closePayIns => 'Cash put in';

  @override
  String get closePayOuts => 'Cash taken out';

  @override
  String get closeSafeDrops => 'Moved to the safe';

  @override
  String get closeExpected => 'Expected in the drawer';

  @override
  String get closeCountTitle => 'Count the drawer';

  @override
  String get closeBlindHelp => 'Count first: the expected amount shows after.';

  @override
  String get closeFloatLabel => 'Float at the start';

  @override
  String get closeFloatHelp =>
      'Cash that was in the drawer before the first sale.';

  @override
  String get closeCountedLabel => 'Cash counted now';

  @override
  String get closeCheckCount => 'Check the count';

  @override
  String get closeReason => 'Why is it over or short?';

  @override
  String get closeConfirmTitle => 'Close the day?';

  @override
  String get closeConfirmBody =>
      'Sales up to now can\'t be voided after this. New sales start a new day.';

  @override
  String get closeNotYet => 'Not yet';

  @override
  String get closeDone => 'Day closed';

  @override
  String get closeFailed => 'Could not close the day. Try again.';

  @override
  String get closePast => 'Past closes';

  @override
  String get closeNone => 'No closes yet.';

  @override
  String get closeBalanced => 'Balanced';

  @override
  String get closeEnterCount => 'Enter the cash you counted';

  @override
  String get closeBalancesBox => 'Drawer balances';

  @override
  String get closeOverBy => 'Over by';

  @override
  String get closeShortBy => 'Short by';

  @override
  String get closeVarianceTitle => 'Over and short, last 30 days';

  @override
  String get settingsBlindCount => 'Blind count at close day';

  @override
  String get settingsBlindCountHelp =>
      'The cashier counts before seeing what the drawer should hold.';

  @override
  String get settingsVarianceLimit => 'Ask why when out by more than';

  @override
  String get settingsVarianceLimitHelp =>
      'Over or short by more than this needs a reason.';

  @override
  String get navMoney => 'Money';

  @override
  String get permManageExpenses => 'Record expenses and the owner\'s money';

  @override
  String get auditExpenseAdded => 'Expense recorded';

  @override
  String get auditExpenseCategorySaved => 'Expense list changed';

  @override
  String get auditOwnerCapital => 'Owner put money in';

  @override
  String get auditOwnerDrawing => 'Owner took money';

  @override
  String get moneyExpenses => 'Expenses';

  @override
  String get moneyProfit => 'Profit';

  @override
  String get moneyOwner => 'Owner\'s money';

  @override
  String get periodToday => 'Today';

  @override
  String get periodThisWeek => 'This week';

  @override
  String get periodThisMonth => 'This month';

  @override
  String get periodLastMonth => 'Last month';

  @override
  String get periodCustom => 'Choose dates';

  @override
  String get expenseNew => 'Add an expense';

  @override
  String get expenseCategory => 'Category';

  @override
  String get expenseCategories => 'Expense categories';

  @override
  String get expenseCategoryNew => 'New category';

  @override
  String get expenseCategoryReason => 'Change the expense categories.';

  @override
  String get expensePaidFrom => 'Paid from';

  @override
  String get expenseDrawerHelp =>
      'It comes out of the drawer, so close day expects less cash.';

  @override
  String get expenseDay => 'Day';

  @override
  String get expenseSupplier => 'Supplier (optional)';

  @override
  String get expenseNoSupplier => 'No supplier';

  @override
  String get expensePickCategory => 'Pick a category.';

  @override
  String get expensesByCategory => 'By category';

  @override
  String get expensesNone => 'No expenses in this period.';

  @override
  String get sourceDrawer => 'Drawer cash';

  @override
  String get sourceMomo => 'MoMo';

  @override
  String get sourceBank => 'Bank';

  @override
  String get sourceOwner => 'Owner\'s pocket';

  @override
  String get payOutExpense => 'Is it an expense? (optional)';

  @override
  String get recurringTitle => 'Monthly reminders';

  @override
  String get recurringNew => 'New reminder';

  @override
  String get recurringEdit => 'Change reminder';

  @override
  String get recurringNone => 'No reminders yet. Add rent, ECG and the like.';

  @override
  String get recurringName => 'Name';

  @override
  String get recurringNameHelp => 'For example \"Shop rent\".';

  @override
  String get recurringDay => 'Day of the month';

  @override
  String get recurringReason => 'Change the monthly reminders.';

  @override
  String get recurringConfirm => 'Record it';

  @override
  String get recurringSkip => 'Not this month';

  @override
  String get profitThisPeriod => 'THIS PERIOD';

  @override
  String get profitBefore => 'BEFORE';

  @override
  String get profitSales => 'Sales at menu prices';

  @override
  String get profitDiscounts => 'Discounts';

  @override
  String get profitRefunds => 'Refunds';

  @override
  String get profitTax => 'Tax collected (for GRA)';

  @override
  String get profitNetSales => 'Net sales';

  @override
  String get profitCost => 'What the stock cost';

  @override
  String get profitGross => 'Gross profit';

  @override
  String get profitWaste => 'Stock thrown away';

  @override
  String get profitCounts => 'Stock count differences';

  @override
  String get profitNet => 'Net profit';

  @override
  String get profitHelp =>
      'A simple view, not full accounts. \"Before\" is the same length of time just before. Stock costs come from recipes and deliveries.';

  @override
  String get ownerTook => 'Owner took money';

  @override
  String get ownerPut => 'Owner put money in';

  @override
  String get ownerTookHelp =>
      'Money taken home. It is not an expense, so profit is not understated.';

  @override
  String get ownerPutHelp =>
      'The owner\'s own money put into the shop. It is not a sale.';

  @override
  String get ownerTookTotal => 'Taken by the owner';

  @override
  String get ownerPutTotal => 'Put in by the owner';

  @override
  String get ownerTakeHome => 'Taken home, net';

  @override
  String get ownerTakeHomeHelp => 'Taken out less put in.';

  @override
  String get ownerHelp =>
      'Keep the owner\'s own money apart from the shop\'s: drawings and money put in.';

  @override
  String get ownerEntries => 'History';

  @override
  String get ownerNone => 'Nothing in this period.';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navReports => 'Reports';

  @override
  String get dashSales => 'Today';

  @override
  String get dashTop => 'Top products today';

  @override
  String get dashDrawer => 'The drawer';

  @override
  String get dashAlerts => 'Needs attention';

  @override
  String get dashAllGood => 'Nothing needs attention.';

  @override
  String get dashArrange => 'Arrange the dashboard';

  @override
  String get dashRefresh => 'Refresh';

  @override
  String get dashNoShift => 'No shift opened';

  @override
  String get alertBackup => 'The backup is not up to date. See the status dot.';

  @override
  String get reportSales => 'Sales';

  @override
  String get reportTimes => 'Times';

  @override
  String get reportProducts => 'Products';

  @override
  String get reportPayments => 'Payments';

  @override
  String get reportStaff => 'Staff';

  @override
  String get reportCustomers => 'Customers';

  @override
  String get reportStockTax => 'Stock and tax';

  @override
  String get reportAccountant => 'For the accountant';

  @override
  String get reportNetSales => 'Net sales';

  @override
  String get reportSalesCount => 'Sales';

  @override
  String get reportAverageSale => 'Average sale';

  @override
  String get reportItemsPerSale => 'Items per sale';

  @override
  String get reportBreakdown => 'How it adds up';

  @override
  String get reportTax => 'Tax';

  @override
  String get reportByDay => 'Day by day';

  @override
  String get reportTimesHelp =>
      'When the shop is busy, to plan staff and prep.';

  @override
  String get reportByHour => 'By hour';

  @override
  String get reportHeatmap => 'Day and hour';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get reportAbcHelp =>
      'A: the products bringing in the first 80% of sales; B: the next 15%; C: the rest.';

  @override
  String get reportByCategory => 'By category';

  @override
  String get reportOptions => 'Options picked';

  @override
  String get reportSlow => 'Not selling';

  @override
  String get reportSlowHelp => 'On the till but not sold in the last 14 days.';

  @override
  String get reportSlowNone => 'Everything sold in the last 14 days.';

  @override
  String get reportNeverSold => 'Never sold';

  @override
  String get reportVoids => 'Voids';

  @override
  String get reportRefundsGiven => 'Refunds given';

  @override
  String get reportNoSales => 'Drawer opened without a sale';

  @override
  String get reportNewCustomers => 'New customers';

  @override
  String get reportReturning => 'Came back';

  @override
  String get reportOwed => 'Owed now';

  @override
  String get reportOverdue => 'Late now';

  @override
  String get reportWallets => 'In wallets';

  @override
  String get reportTopCustomers => 'Top customers';

  @override
  String get reportStockValue => 'Stock value at cost';

  @override
  String get reportMovements => 'Stock in and out, at cost';

  @override
  String get reportNoTax => 'No tax charged.';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get statusPrinter => 'Receipt printer';

  @override
  String get statusPrinterReady => 'Ready. Nothing waiting.';

  @override
  String get printClear => 'Clear';

  @override
  String get printSent => 'Sent to the printer.';

  @override
  String get printNoPrinter =>
      'No receipt printer on this device. Set one up in Settings, Receipts and printing.';

  @override
  String get printReprintLast => 'Reprint the last receipt';

  @override
  String get printNothingYet => 'No sale to reprint yet.';

  @override
  String get receiptPrint => 'Print receipt';

  @override
  String get receiptPrintAgain => 'Print again';

  @override
  String get receiptSend => 'Send receipt';

  @override
  String get receiptPhone => 'Customer\'s phone';

  @override
  String get receiptPhoneHelp => 'Leave it empty to pick the chat in WhatsApp.';

  @override
  String get receiptPhoneInvalid =>
      'Enter a Ghana phone number, like 024 123 4567.';

  @override
  String get receiptSms => 'SMS';

  @override
  String get receiptPdf => 'PDF';

  @override
  String get refundPrintSlip => 'Print refund slip';

  @override
  String get closePrintZ => 'Print Z report';

  @override
  String get customerPrintBalance => 'Print the balance';

  @override
  String get settingsGroupPrinting => 'Receipts and printing';

  @override
  String get printerTitle => 'Receipt printer';

  @override
  String get printerNoneHelp =>
      'Bluetooth, USB or network thermal printers, 58 or 80 mm.';

  @override
  String get printerNetwork => 'Network';

  @override
  String get printerWindows => 'This computer';

  @override
  String get printerBluetooth => 'Bluetooth';

  @override
  String get printerAddress => 'Printer\'s IP address';

  @override
  String get printerAddressHelp =>
      'Like 192.168.1.50. Print the printer\'s own test page to find it.';

  @override
  String get printerWindowsHelp =>
      'USB printers show here once their Windows driver is installed.';

  @override
  String get printerBluetoothHelp =>
      'Pair the printer in Android\'s Bluetooth settings first (the PIN is often 0000 or 1234).';

  @override
  String get printerNoneFound => 'No printers found.';

  @override
  String get printerLookAgain => 'Look again';

  @override
  String get printerPaper => 'Paper width';

  @override
  String get printerTest => 'Print a test page';

  @override
  String get printerTestSent =>
      'Sent. If nothing came out, check the paper and that the printer is on.';

  @override
  String get printerChooseFirst => 'Choose a printer first.';

  @override
  String get printerRemove => 'Remove printer';

  @override
  String get settingsAutoPrint => 'Print every receipt';

  @override
  String get settingsAutoPrintHelp =>
      'Off: print only when asked, or use Send receipt for no paper.';

  @override
  String get settingsCashDrawer => 'Cash drawer';

  @override
  String get settingsCashDrawerHelp =>
      'Plugged into the printer. Opens for cash sales, cash refunds, pay in or out, and no-sales.';

  @override
  String get settingsTestDrawer => 'Open the drawer to test it';

  @override
  String get receiptDesign => 'Receipt design';

  @override
  String get receiptDesignHelp =>
      'Logo, header, footer, MoMo number and what each receipt shows.';

  @override
  String get receiptShopFromSettings =>
      'The shop name, address and phone come from the Shop settings.';

  @override
  String get receiptLogoAdd => 'Add a logo';

  @override
  String get receiptLogoChange => 'Change the logo';

  @override
  String get receiptLogoRemove => 'Remove the logo';

  @override
  String get receiptLogoUnreadable =>
      'That picture could not be read. Try a PNG or JPEG.';

  @override
  String get receiptHeader => 'Header';

  @override
  String get receiptHeaderHelp =>
      'Under the shop name, like opening hours or a landmark.';

  @override
  String get receiptMomo => 'MoMo number to pay';

  @override
  String get receiptFooter => 'Footer';

  @override
  String get receiptShowCashier => 'Who served';

  @override
  String get receiptShowCustomer => 'The customer\'s name';

  @override
  String get receiptShowTax => 'Tax included';

  @override
  String get receiptShowQr => 'QR code for refunds and reprints';

  @override
  String get receiptCreditCopies => 'Credit sales';

  @override
  String get receiptOneCopy => 'One copy';

  @override
  String get receiptTwoCopies => 'Customer and shop copy';

  @override
  String get scanWithCamera => 'Scan with the camera';

  @override
  String get scanTorch => 'Torch';

  @override
  String get scanHint => 'Hold the barcode or receipt QR code inside the box.';

  @override
  String get scanNoPermission =>
      'Aby needs the camera to scan. Allow it in Android settings, then try again.';

  @override
  String get scanCameraError =>
      'The camera could not start. Close other apps using it and try again.';

  @override
  String get settingsCameraScan => 'Scan with the camera';

  @override
  String get settingsCameraScanHelp =>
      'Shows a camera button next to search, receipts and barcodes.';

  @override
  String get scaleTitle => 'Scale';

  @override
  String get scaleHelp => 'Reads the weight for products sold by the kilo.';

  @override
  String get scaleSerialHelp =>
      'Scales with a serial or USB cable show as a COM port once their driver is installed.';

  @override
  String get scaleBluetoothHelp =>
      'Pair the scale in Android\'s Bluetooth settings first.';

  @override
  String get scalePort => 'Port';

  @override
  String get scaleDevice => 'Paired scale';

  @override
  String get scaleBaud => 'Speed (baud)';

  @override
  String get scaleRequest => 'How to ask for the weight';

  @override
  String get scaleRequestHelp =>
      'See the scale\'s manual. Most send the weight all the time.';

  @override
  String get scaleRequestNone => 'Nothing: it sends the weight all the time';

  @override
  String get scaleRequestEnq => 'Send ENQ (05)';

  @override
  String get scaleRead => 'Read the scale';

  @override
  String get scaleNoneFound => 'Nothing found. Check the cable or the pairing.';

  @override
  String get scaleChooseFirst => 'Choose the scale first.';

  @override
  String get scaleRemove => 'Remove scale';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsHelp =>
      'Phone or Windows notifications for low stock, late credit, backups and more.';

  @override
  String get notifyTitle => 'Which notifications';

  @override
  String get notifyLowStock => 'Low stock';

  @override
  String get notifyCredit => 'Customers late paying';

  @override
  String get notifyBackup => 'Backups not up to date';

  @override
  String get notifyDayOpen => 'A day not closed';

  @override
  String get notifyParked => 'Old parked orders';

  @override
  String get notifyExpenses => 'Expenses due';

  @override
  String get commonDelete => 'Delete';

  @override
  String get auditPromotionSaved => 'Promotion changed';

  @override
  String get optionsComboPart => 'Is a product (combo part)';

  @override
  String get optionsComboPartHelp =>
      'Uses that product\'s recipe, so its stock goes down.';

  @override
  String get optionsNotAProduct => 'No, just an option';

  @override
  String get promoTitle => 'Promotions';

  @override
  String get promoSettingsHelp =>
      'Happy hours, buy X get Y, bundles, quantity prices and spend rewards.';

  @override
  String get promoHelp =>
      'They apply themselves at the till when their conditions are met. When several could apply, the best deal for the customer wins.';

  @override
  String get promoNone => 'No promotions yet.';

  @override
  String get promoNew => 'New promotion';

  @override
  String get promoEdit => 'Change promotion';

  @override
  String get promoRunningNow => 'On now';

  @override
  String get promoApprovalReason => 'Promotions change prices.';

  @override
  String get promoName => 'Name';

  @override
  String get promoNameHelp =>
      'Shown on the cart and the receipt, like Happy hour.';

  @override
  String get promoNameRequired => 'Give the promotion a name.';

  @override
  String get promoKind => 'What it does';

  @override
  String get promoKindPercent => 'Percent off';

  @override
  String get promoKindPercentExample => 'Happy hour 2 to 4 pm: 15% off cups.';

  @override
  String get promoKindBuyGet => 'Buy some, get some';

  @override
  String get promoKindBuyGetExample =>
      'Buy 2 cones, get 1 free (the cheapest).';

  @override
  String get promoKindBundle => 'Bundle price';

  @override
  String get promoKindBundleExample =>
      'Cone and milkshake together for GH₵ 32.';

  @override
  String get promoKindQuantity => 'Quantity price';

  @override
  String get promoKindQuantityExample => '6 or more tubs: GH₵ 55 each.';

  @override
  String get promoKindSpend => 'Spend reward';

  @override
  String get promoKindSpendExample => 'Spend GH₵ 100, get a free waffle.';

  @override
  String get promoEverything => 'Everything';

  @override
  String get promoPickHelp =>
      'Pick categories, products or both. Nothing picked means everything.';

  @override
  String get promoOn => 'On';

  @override
  String get promoPercentOff => 'Percent off';

  @override
  String get promoMinQuantity => 'How many at least';

  @override
  String get promoPriceEach => 'Price each';

  @override
  String get promoBuy => 'Buy';

  @override
  String get promoOf => 'Of';

  @override
  String get promoGet => 'Get';

  @override
  String get promoOfSameOrOther => 'Of (Everything: the same as bought)';

  @override
  String get promoRewardPercent => 'Percent off what they get (100 = free)';

  @override
  String get promoAddPart => 'Add a part';

  @override
  String get promoBundlePrice => 'Bundle price';

  @override
  String get promoSpendAtLeast => 'When they spend at least';

  @override
  String get promoRewardPercentOff => 'Percent off';

  @override
  String get promoRewardAmountOff => 'Money off';

  @override
  String get promoRewardFree => 'A free item';

  @override
  String get promoAmountOff => 'Money off';

  @override
  String get promoFreeItem => 'Free item (the cheapest in the cart)';

  @override
  String get promoWhen => 'When';

  @override
  String get promoAllDay => 'All day';

  @override
  String get promoStartsNow => 'From now';

  @override
  String get promoNoEnd => 'No end date';

  @override
  String get promoAnyDate => 'Any date';

  @override
  String get promoStackable => 'Works with other promotions';

  @override
  String get promoStackableHelp => 'Off: only the best deal applies.';

  @override
  String get promoOn2 => 'On';

  @override
  String get promoPercentInvalid => 'Enter a percentage from 1 to 100.';

  @override
  String get promoAmountInvalid => 'Enter an amount, like 32 or 5.50.';

  @override
  String get promoQuantityInvalid => 'Enter how many, 1 or more.';

  @override
  String get promoThresholdInvalid => 'Enter how much they must spend.';

  @override
  String get promoPartsInvalid => 'A bundle needs at least 2 parts.';

  @override
  String get promoDaysRequired => 'Pick at least one day.';

  @override
  String get auditVoucherIssued => 'Gift voucher sold';

  @override
  String get payKindVoucher => 'Gift voucher';

  @override
  String get loyaltyTitle => 'Loyalty';

  @override
  String get loyaltySettingsHelp =>
      'Stamp card, points or Gold customers. Customers are known by their phone number.';

  @override
  String get loyaltyHelp =>
      'Pick one style for the shop. Attach the customer at the till: rewards apply by themselves.';

  @override
  String get loyaltyOffHelp => 'No loyalty rewards.';

  @override
  String get loyaltyStampCard => 'Stamps';

  @override
  String get loyaltyPointsStyle => 'Points';

  @override
  String get loyaltyTiers => 'Gold';

  @override
  String get loyaltyStampsNeeded => 'Stamps for a free item';

  @override
  String get loyaltyStampsNeededHelp =>
      '9 means buy 9, get the 10th free. One stamp per item.';

  @override
  String get loyaltyStampProducts =>
      'Items that earn stamps (and the free one)';

  @override
  String get loyaltyPointsPerCedi => 'Points per GH₵ 1 spent';

  @override
  String get loyaltyPointsForReward => 'Points for a reward';

  @override
  String get loyaltyRewardValue => 'Reward value';

  @override
  String get loyaltyExpireDays => 'Points expire after';

  @override
  String get loyaltyExpireDaysHelp => 'Days without a purchase. 0 means never.';

  @override
  String get loyaltyDays => 'days';

  @override
  String get loyaltyTiersHelp =>
      'Customers who spent enough in the last 90 days are Gold and get a discount on everything.';

  @override
  String get loyaltyGoldSpend => 'Gold from this spend in 90 days';

  @override
  String get loyaltyGoldPercent => 'Gold discount';

  @override
  String get loyaltyNumbersInvalid =>
      'Check the numbers: each needs to be 1 or more.';

  @override
  String get voucherTitle => 'Gift vouchers';

  @override
  String get voucherTitleOne => 'Gift voucher';

  @override
  String get voucherHelp =>
      'Sold for money now, spent later as a payment. What is left stays on the code.';

  @override
  String get voucherNone => 'No gift vouchers yet.';

  @override
  String get voucherSell => 'Sell a gift voucher';

  @override
  String get voucherSellButton => 'Sell voucher';

  @override
  String get voucherExpired => 'This voucher has expired.';

  @override
  String get voucherValue => 'Value';

  @override
  String get voucherPaidBy => 'Paid by';

  @override
  String get voucherLasts => 'Can be used for';

  @override
  String get voucherNoExpiry => 'Always';

  @override
  String get voucherNote => 'Note (optional), like who it is for';

  @override
  String get voucherReferenceNeeded => 'Enter the payment reference.';

  @override
  String get voucherSend => 'Send';

  @override
  String get voucherCode => 'Gift voucher code';

  @override
  String get voucherCodeHelp => 'Type or scan the code on the voucher.';

  @override
  String get voucherNotFound => 'No voucher with this code.';

  @override
  String get voucherUsedUp => 'Nothing is left on this voucher.';

  @override
  String get navOrders => 'Orders';

  @override
  String get ordersNone =>
      'No open orders. Sales with prep items get a number here.';

  @override
  String get orderNew => 'New';

  @override
  String get orderPreparing => 'Preparing';

  @override
  String get orderReady => 'Ready';

  @override
  String get orderCollected => 'Collected';

  @override
  String get orderMarkCollected => 'Collected';

  @override
  String get orderPrintTicket => 'Print kitchen ticket';

  @override
  String get orderNumberLabel => 'Order number';

  @override
  String get settingsGroupOrders => 'Orders and screens';

  @override
  String get settingsOrderNumbers => 'Order numbers';

  @override
  String get settingsOrderNumbersHelp =>
      'Sales with prep items get a number like A23, a kitchen ticket and a place on the Orders board.';

  @override
  String get settingsOrderPrefix => 'Order letter';

  @override
  String get settingsOrderPrep => 'Items that need prep';

  @override
  String get settingsOrderPrepHelp =>
      'Like milkshakes and waffles. Nothing picked means everything.';

  @override
  String get kitchenPrinterTitle => 'Kitchen printer';

  @override
  String get kitchenPrinterHelp => 'Kitchen tickets print here.';

  @override
  String get kitchenPrinterSame => 'The receipt printer';

  @override
  String get settingsScreens => 'Screens on other devices';

  @override
  String get settingsScreensHelp =>
      'A customer display, a prep screen and Now serving, in the browser of a tablet, TV or second monitor on the same Wi-Fi.';

  @override
  String get screensTitle => 'Open on a tablet or TV';

  @override
  String get screensHelp =>
      'Scan a code with the tablet or type its link into the browser. Keep the links to yourself: anyone with one on this Wi-Fi can open it.';

  @override
  String get screensNetwork => 'This device on';

  @override
  String get screensNotRunning =>
      'The screens are not running. Turn them off and on again, or another app may be using the port.';

  @override
  String get screensNoNetwork =>
      'This device is not on a network. Connect it to the shop Wi-Fi.';

  @override
  String get screensCustomer => 'Customer display';

  @override
  String get screensCustomerHelp =>
      'Faces the customer: the cart, the total, the MoMo number and QR code, then thank you and change.';

  @override
  String get screensPrep => 'Prep screen';

  @override
  String get screensPrepHelp =>
      'For whoever makes the orders: New, Preparing, Ready, with buttons.';

  @override
  String get screensServing => 'Now serving';

  @override
  String get screensServingHelp =>
      'Order numbers being prepared and ready to collect, for a TV.';

  @override
  String get screensNewLinks => 'New links';

  @override
  String get screensNewLinksDone =>
      'New links made. The old ones no longer work.';

  @override
  String get auditBarcodesGenerated => 'Barcodes made';

  @override
  String get labelsTitle => 'Labels';

  @override
  String get labelsHelp =>
      'How many labels for each product: name, price and barcode.';

  @override
  String get labelsSheet => 'A4 sheet (24)';

  @override
  String get labelsRoll => 'Label roll 50 × 30';

  @override
  String get labelsReceiptPrinter => 'Receipt printer';

  @override
  String get labelsNoBarcode => 'no barcode';

  @override
  String get labelsMakeBarcodes => 'Make barcodes for products';

  @override
  String get labelsForDelivery => 'Labels for this delivery?';

  @override
  String get auditPurchaseOrderSaved => 'Purchase order';

  @override
  String get auditStockProduced => 'Stock made';

  @override
  String get moveProduction => 'Made here';

  @override
  String get notifyExpiring => 'Stock about to expire';

  @override
  String get stockTracksExpiry => 'Batches and expiry dates';

  @override
  String get stockTracksExpiryHelp =>
      'Ask for the batch and expiry date when it comes in, like milk and ice cream base.';

  @override
  String get receiveBatchNo => 'Batch';

  @override
  String get receiveExpiry => 'Expiry date';

  @override
  String get expiryTitle => 'Expiring';

  @override
  String get expiryNone => 'Nothing in stock expires in the next 30 days.';

  @override
  String get expiryBatches => 'Batches in stock';

  @override
  String get expiryNoBatches => 'No batches in stock.';

  @override
  String get expiryNoDate => 'No expiry date';

  @override
  String get poTab => 'Orders';

  @override
  String get poNone => 'No purchase orders yet.';

  @override
  String get poNew => 'New order';

  @override
  String get poCreate => 'Create order';

  @override
  String get poOpen => 'Waiting';

  @override
  String get poPartial => 'Part delivered';

  @override
  String get poReceived => 'Delivered';

  @override
  String get poCancelled => 'Cancelled';

  @override
  String get poNeededByPick => 'Needed by';

  @override
  String get poCancel => 'Cancel order';

  @override
  String get poSend => 'Send';

  @override
  String get poReceive => 'Receive delivery';

  @override
  String get poPickSupplier => 'Choose the supplier.';

  @override
  String get poAddItems => 'Add what to order.';

  @override
  String get poSuggestHelp =>
      'Their items that are low come in at the usual order.';

  @override
  String get poReason => 'Purchase orders spend the shop money.';

  @override
  String get produceSetUp => 'Made here? Set its recipe';

  @override
  String get produceMadeHere => 'Made here';

  @override
  String get produceRecord => 'Record a batch made';

  @override
  String get produceRecipeHelp =>
      'For one batch: how much it makes and what goes in. Making it takes the ingredients off stock and adds what was made, at what they cost.';

  @override
  String get produceOneBatchMakes => 'One batch makes';

  @override
  String get produceIngredients => 'Ingredients for one batch';

  @override
  String get produceYieldInvalid => 'Enter how much one batch makes.';

  @override
  String get produceNeedsIngredients => 'Add at least one ingredient.';

  @override
  String get produceStop => 'Not made here';

  @override
  String get produceHowMuch => 'How much was made';

  @override
  String get produceUses => 'This uses';

  @override
  String get badgeTitle => 'Badge and hours';

  @override
  String get badgeNone => 'No sign-in badge';

  @override
  String get badgeHas => 'Has a sign-in badge';

  @override
  String get badgeHelp =>
      'A QR code to scan at sign-in, instead of picking the name. The PIN is still needed.';

  @override
  String get badgeMake => 'Make a badge';

  @override
  String get badgeNew => 'New badge';

  @override
  String get badgeRemove => 'Remove the badge';

  @override
  String get badgeRemoved => 'Badge removed. It no longer works.';

  @override
  String get badgeUnknown => 'That badge is not known. Pick your name instead.';

  @override
  String get workHours => 'Usual hours';

  @override
  String get workHoursHelp =>
      'For late arrivals and early leaves on the timesheet.';

  @override
  String get workStarts => 'Starts at';

  @override
  String get workEnds => 'Finishes at';

  @override
  String get clockIn => 'Clock in';

  @override
  String get clockOut => 'Clock out';

  @override
  String get clockStartBreak => 'Start a break';

  @override
  String get clockEndBreak => 'End the break';

  @override
  String get clockedIn => 'Clocked in.';

  @override
  String get clockedOut => 'Clocked out.';

  @override
  String get clockInToSellTitle => 'Clock in to sell';

  @override
  String get clockInToSellBody =>
      'The shop asks staff to clock in before selling. Clock in now?';

  @override
  String get timeTab => 'Timesheets';

  @override
  String get timeNone => 'No one clocked in during these dates.';

  @override
  String get timeWorked => 'Hours worked';

  @override
  String get timeStillIn => 'still in';

  @override
  String get reportItems => 'Items sold';

  @override
  String get reportCommission => 'Commission';

  @override
  String get settingsClockInToSell => 'Clock in before selling';

  @override
  String get settingsClockInToSellHelp =>
      'Staff clock in and out from their name at the top. Timesheets are in Staff.';

  @override
  String get settingsCommission => 'Commission';

  @override
  String get settingsCommissionHelp =>
      'Worked out per person in Reports, Staff, for any dates.';

  @override
  String get commissionPercentChoice => 'A percent of their sales';

  @override
  String get commissionPerProduct => 'An amount per product';

  @override
  String get editorCommission => 'Commission';

  @override
  String get editorCommissionPer => 'Commission per one sold';

  @override
  String get editorCommissionHelp =>
      'Paid to whoever sells it. Leave empty for none.';

  @override
  String get commandTooltip => 'Search everything (Ctrl+K)';

  @override
  String get commandHint =>
      'Products, customers, sale numbers, MoMo references, actions...';

  @override
  String get commandNothing => 'Nothing found.';

  @override
  String get commandActions => 'Go to';

  @override
  String get commandSales => 'Sales';

  @override
  String get commandOpen => 'Open';

  @override
  String get commandAddToCart => 'Add to cart';

  @override
  String get commandEditProduct => 'Edit product';

  @override
  String get commandAddToSale => 'Add to the sale';

  @override
  String get commandOpenCustomer => 'Open';

  @override
  String get commandReprint => 'Reprint';

  @override
  String get commandOpenProfile => 'Open profile';

  @override
  String get commandNewProduct => 'New product';

  @override
  String get commandAddExpense => 'Add an expense';

  @override
  String get insightsTitle => 'Worth knowing';

  @override
  String get insightOrderMore => 'Order more';

  @override
  String get insightSeeTimes => 'See the times';

  @override
  String get insightReviewPrice => 'Review price';

  @override
  String get insightSendReminders => 'Send reminders';

  @override
  String get insightSeeStaff => 'See staff';

  @override
  String get insightDismiss => 'Not now';

  @override
  String get insightTurnOff => 'Don\'t show these';

  @override
  String get summaryProfitLabel => 'Profit before expenses';

  @override
  String get summaryCash => 'Cash';

  @override
  String get summaryTopLabel => 'Top product';

  @override
  String get summaryShare => 'Share the summary';

  @override
  String get trainingTitle => 'Training mode';

  @override
  String get trainingHelp =>
      'Practise on a sample shop or a copy of this one. Nothing reaches the real sales, stock, reports or backups.';

  @override
  String get trainingBand => 'TRAINING: NOT REAL SALES';

  @override
  String get trainingWith => 'Practise with';

  @override
  String get trainingSample =>
      'A sample shop: made-up products, stock, suppliers, customers and a month of sales';

  @override
  String get trainingCopy =>
      'A copy of this shop: its own products and sales as they are now';

  @override
  String get trainingPreparing => 'Getting the practice shop ready…';

  @override
  String get trainingStopTitle => 'Leave training mode?';

  @override
  String get trainingStopBody =>
      'Aby restarts on the real shop. The practice stays in the copy until it is reset.';

  @override
  String get trainingStop => 'Leave training';

  @override
  String get trainingReset => 'Reset training data';

  @override
  String get trainingResetHelp =>
      'Throw the practice away and start again, from a fresh sample shop or the real shop as it is now.';

  @override
  String get trainingNoBackups =>
      'Backups are for the real shop. Leave training mode first.';

  @override
  String get setupShopType => 'What kind of shop?';

  @override
  String get shopTypeIceCream => 'Ice cream / cold store';

  @override
  String get shopTypeProvision => 'Provision shop';

  @override
  String get shopTypeChopBar => 'Chop bar / restaurant';

  @override
  String get shopTypePharmacy => 'Pharmacy shop';

  @override
  String get shopTypeSalon => 'Salon / barber';

  @override
  String get shopTypePhones => 'Phones and accessories';

  @override
  String get shopTypeBoutique => 'Boutique';

  @override
  String get shopTypeBuilding => 'Building materials';

  @override
  String get shopTypeOther => 'Something else';

  @override
  String get settingsGroupFeatures => 'Features';

  @override
  String get settingsFeaturesHelp =>
      'Chosen at setup. Every feature below can be switched on or off.';

  @override
  String get settingsExpiryByDefault => 'Expiry dates for new stock';

  @override
  String get settingsExpiryByDefaultHelp =>
      'New stock items ask for batches and expiry dates when they come in.';

  @override
  String get hubTitle => 'Devices and hub';

  @override
  String get hubSettingsHelp =>
      'Tills on the same Wi-Fi share sales, stock and customers, without internet.';

  @override
  String get hubRoleNone => 'Working alone';

  @override
  String get hubRoleHub => 'This device is the hub';

  @override
  String get hubRoleMember => 'Connected to the hub';

  @override
  String get hubNoneHelp =>
      'Make one device the hub (the main till or a back-office PC), then join the others to it. Each device keeps selling when the Wi-Fi drops and catches up later.';

  @override
  String get hubHubHelp =>
      'Other devices sync through this one. Keep it on and on the shop Wi-Fi during trading.';

  @override
  String get hubMemberHelp =>
      'Sales and changes here go to the hub every few seconds, and changes from the other tills come back.';

  @override
  String get hubApprovalReason => 'Manage this shop\'s devices.';

  @override
  String get hubBecome => 'Make this the hub';

  @override
  String get hubBecomeTitle => 'Make this device the hub?';

  @override
  String get hubBecomeBody =>
      'The other devices will join this one and send it their sales. Its menu, stock and customers become the shop data that others merge into.';

  @override
  String get hubJoin => 'Join a hub';

  @override
  String get hubJoinTitle => 'Join the hub?';

  @override
  String get hubJoinBody =>
      'Everything on this device is merged into the hub, and the hub data comes here. This device takes the shop settings from the hub. Products or customers on both may then appear twice and can be tidied up.';

  @override
  String get hubJoined => 'Joined the hub. Syncing now.';

  @override
  String get hubAddress => 'Hub address';

  @override
  String get hubAddressHelp =>
      'Shown on the hub under Add a device, for example 192.168.1.20:8787';

  @override
  String get hubCode => 'Pairing code';

  @override
  String get hubCodeHelp => 'The 8 letters the hub shows under Add a device';

  @override
  String get hubNotACode =>
      'That is not an Aby pairing code. Scan the code on the hub under Add a device.';

  @override
  String get hubAddDevice => 'Add a device';

  @override
  String get hubAddHelp =>
      'On a new device, tap Join the shop\'s hub on its first screen (or, if it is already set up, Settings, This device, Devices and hub, then Join a hub) and type this code. It finds this hub on the Wi-Fi by itself.';

  @override
  String get hubPaired => 'Device added. It is syncing now.';

  @override
  String get hubSyncNow => 'Sync now';

  @override
  String get hubNeverSynced => 'Not synced yet';

  @override
  String get hubStop => 'Stop the hub';

  @override
  String get hubStopTitle => 'Stop being the hub?';

  @override
  String get hubStopBody =>
      'The other devices stop syncing until a hub is set up again. Nothing is deleted.';

  @override
  String get hubLeave => 'Leave the hub';

  @override
  String get hubLeaveTitle => 'Leave the hub?';

  @override
  String get hubLeaveBody =>
      'This device stops syncing and works alone. It keeps all its data.';

  @override
  String get hubDevices => 'Paired devices';

  @override
  String get hubNoDevices => 'No devices yet. Use Add a device on each till.';

  @override
  String get hubDeviceTill => 'Till';

  @override
  String get hubDeviceKitchen => 'Kitchen';

  @override
  String get hubDeviceDisplay => 'Display';

  @override
  String get hubDeviceOwner => 'Owner\'s device';

  @override
  String get hubRename => 'Rename';

  @override
  String get hubSetRole => 'What is it used for?';

  @override
  String get hubRevoke => 'Remove from the hub';

  @override
  String get hubRevokeBody =>
      'Use this for a lost or stolen device. It can no longer sync. What it already sent is kept.';

  @override
  String get hubRevoked => 'Removed';

  @override
  String get hubDuplicates => 'May be duplicates';

  @override
  String get hubDuplicatesHelp =>
      'These names appear more than once after merging. Check them and delete or rename the extra ones.';

  @override
  String get hubKindProduct => 'product';

  @override
  String get hubKindCustomer => 'customer';

  @override
  String get hubKindStaff => 'staff';

  @override
  String get hubErrAlreadyLinked => 'This device is already part of a hub.';

  @override
  String get hubErrNoCode =>
      'No pairing code is on offer. Tap Add a device on the hub.';

  @override
  String get hubErrTooManyTries =>
      'Too many wrong tries. Show a new code on the hub.';

  @override
  String get hubErrWrongCode => 'That pairing code is not right.';

  @override
  String get hubErrNotPaired =>
      'This device is not paired with the hub. Leave and join again.';

  @override
  String get hubErrRevoked => 'This device was removed from the hub.';

  @override
  String get hubErrUnreachable =>
      'Cannot reach the hub. Check both devices are on the same Wi-Fi and the hub is on.';

  @override
  String get hubErrRefused => 'The hub refused the request.';

  @override
  String get statusHubUnreachable => 'Cannot reach the hub.';

  @override
  String get hubTraining =>
      'Training mode is on: this copy does not sync. Leave training mode to use the hub.';

  @override
  String get moveTransferOut => 'Sent to another branch';

  @override
  String get moveTransferIn => 'From another branch';

  @override
  String get auditBranchSaved => 'Branch saved';

  @override
  String get auditDeviceBranchChanged => 'Device moved to a branch';

  @override
  String get auditTransferSent => 'Stock transfer sent';

  @override
  String get auditTransferReceived => 'Stock transfer received';

  @override
  String get auditTransferCancelled => 'Stock transfer called back';

  @override
  String get auditBranchDataMerged => 'Branch data brought in';

  @override
  String get branchesTitle => 'Branches';

  @override
  String get branchesSettingsHelp =>
      'More than one shop location, each with its own stock.';

  @override
  String get branchesHelp =>
      'Each branch has its own stock and its own devices. Reports show one branch or all of them. Devices on the same Wi-Fi sync through the hub; between branches far apart, carry the data in a file, or later through Aby Cloud.';

  @override
  String get branchThisDevice => 'This device is at';

  @override
  String get branchThisDeviceHelp =>
      'Its sales and stock count for this branch.';

  @override
  String get branchMoveBody =>
      'Its sales and stock movements, the earlier ones too, will count for that branch.';

  @override
  String get branchMove => 'Move';

  @override
  String get branchAdd => 'Add a branch';

  @override
  String get branchesList => 'Branches';

  @override
  String get branchMain => 'Main branch';

  @override
  String get branchClosed => 'Closed';

  @override
  String get branchClose => 'Close branch';

  @override
  String get branchReopen => 'Reopen branch';

  @override
  String get branchName => 'Branch name';

  @override
  String get branchAddress => 'Address or landmark';

  @override
  String get branchPhone => 'Phone';

  @override
  String get branchFiles => 'Data between branches';

  @override
  String get branchSendData => 'Send this branch data';

  @override
  String get branchSendDataHelp =>
      'Makes a backup file (with the backup password) to carry or send to the other branch.';

  @override
  String get branchMerge => 'Bring in a branch data file';

  @override
  String get branchMergeHelp =>
      'Adds the sales, stock and changes from another branch backup. Nothing here is replaced.';

  @override
  String get branchMergeConfirmTitle => 'Bring this data in?';

  @override
  String get branchMerging => 'Bringing the data in...';

  @override
  String get branchAll => 'All branches';

  @override
  String get branchPick => 'Branch';

  @override
  String get staffWorksAt => 'Works at';

  @override
  String get staffWorksAtHelp =>
      'They can sign in only at this branch. Owners can sign in everywhere.';

  @override
  String get transfersTab => 'Transfers';

  @override
  String get transferNew => 'Send stock';

  @override
  String get transferNewHelp =>
      'The stock leaves this branch now and shows as on its way until the other branch receives it.';

  @override
  String get transferToBranch => 'To branch';

  @override
  String get transferNote => 'Note';

  @override
  String get transferSend => 'Send';

  @override
  String get transferInTransit => 'On its way';

  @override
  String get transferReceived => 'Received';

  @override
  String get transferCancelled => 'Called back';

  @override
  String get transferNone =>
      'No transfers yet. Use Send stock to move stock to another branch.';

  @override
  String get transferDifferences => 'differences';

  @override
  String get transferArrivedAll => 'All arrived';

  @override
  String get transferCallBack => 'Call back';

  @override
  String get transferCallBackTitle => 'Call this transfer back?';

  @override
  String get transferCallBackBody =>
      'The stock comes back into this branch. Do this only if it never left.';

  @override
  String get transferReceive => 'Receive';

  @override
  String get transferReceiveHelp =>
      'Count what arrived. Anything different from what was sent is flagged.';

  @override
  String get transferReceivedAll => 'Received. Everything arrived.';

  @override
  String get transferReceivedShort =>
      'Received, with differences. They are in the activity log.';

  @override
  String get transferNoBranches =>
      'Add another branch first, in Settings, Branches.';

  @override
  String pinMustBeDigits(int count) {
    return 'The PIN must be $count digits.';
  }

  @override
  String pinTooManyTries(int seconds) {
    return 'Too many tries. Wait $seconds seconds.';
  }

  @override
  String pinFor(String name) {
    return 'PIN for $name';
  }

  @override
  String setupIntro(int digits) {
    return 'You\'re the owner. Pick a $digits-digit PIN to sign in and to approve things like voids. You can add staff later.';
  }

  @override
  String approvalNeeds(String permission) {
    return 'Needs someone who can: $permission';
  }

  @override
  String statusLast(String when) {
    return 'Last: $when';
  }

  @override
  String statusSalesWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales saved on this device. Will sync when online.',
      one: '1 sale saved on this device. Will sync when online.',
    );
    return '$_temp0';
  }

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String voidConfirmTitle(String number) {
    return 'Void sale $number?';
  }

  @override
  String voidConfirmBody(String total) {
    return '$total will come off today\'s takings and the items go back into stock. This cannot be undone.';
  }

  @override
  String voidApprovalReason(String number) {
    return 'Void sale $number';
  }

  @override
  String voidDone(String number) {
    return 'Sale $number voided.';
  }

  @override
  String staffAdded(String name) {
    return '$name added.';
  }

  @override
  String staffPinChanged(String name) {
    return 'PIN changed for $name.';
  }

  @override
  String staffRoleChanged(String name) {
    return 'Role changed for $name.';
  }

  @override
  String staffDeactivated(String name) {
    return '$name deactivated.';
  }

  @override
  String staffReactivated(String name) {
    return '$name can sign in again.';
  }

  @override
  String staffYou(String name) {
    return '$name (you)';
  }

  @override
  String staffDeactivatedRole(String role) {
    return '$role, deactivated';
  }

  @override
  String staffNewPinFor(String name) {
    return 'New PIN for $name';
  }

  @override
  String staffChangeRoleFor(String name) {
    return 'Role for $name';
  }

  @override
  String staffDeactivateTitle(String name) {
    return 'Deactivate $name?';
  }

  @override
  String rolesDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String rolesDeleted(String name) {
    return '$name deleted.';
  }

  @override
  String rolesPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
      zero: 'Nobody',
    );
    return '$_temp0';
  }

  @override
  String rolesPermissionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count permissions',
      one: '1 permission',
    );
    return '$_temp0';
  }

  @override
  String activityApprovedBy(String name) {
    return 'approved by $name';
  }

  @override
  String activityChainBroken(int seq) {
    return 'Warning: the activity log was changed outside Aby, from entry $seq. Keep this device as it is and check your backups.';
  }

  @override
  String settingsMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String settingsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String backupPasswordTooShort(int count) {
    return 'Use at least $count characters.';
  }

  @override
  String backupShareSubject(String shop) {
    return '$shop backup';
  }

  @override
  String backupRestoreConfirmBody(String shop, int sales, String lastSale) {
    return 'This backup is from $shop: $sales sales, last sale $lastSale. Everything on this device will be replaced. A copy of what is here now is kept first.';
  }

  @override
  String profileInAbySince(String date) {
    return 'In Aby since $date';
  }

  @override
  String profileSalesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
      zero: 'No sales',
    );
    return '$_temp0';
  }

  @override
  String profileVoidsApproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count approved for others',
      one: '1 approved for others',
      zero: 'None approved for others',
    );
    return '$_temp0';
  }

  @override
  String profileClosesOver(String amount) {
    return 'Over $amount in total';
  }

  @override
  String profileClosesShort(String amount) {
    return 'Short $amount in total';
  }

  @override
  String profileAge(int years) {
    return '$years years old';
  }

  @override
  String profileTenure(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
      zero: 'Less than a month',
    );
    return '$_temp0';
  }

  @override
  String tileFrom(String price) {
    return 'from $price';
  }

  @override
  String tileLeft(int count) {
    return '$count left';
  }

  @override
  String pickerAdd(String price) {
    return 'Add $price';
  }

  @override
  String groupUpTo(int max) {
    return 'Up to $max';
  }

  @override
  String groupPickExactly(int count) {
    return 'Pick $count';
  }

  @override
  String groupPickAtLeast(int count) {
    return 'Pick at least $count';
  }

  @override
  String groupPickBetween(int min, int max) {
    return 'Pick $min to $max';
  }

  @override
  String productsVariantCount(int count) {
    return '$count prices';
  }

  @override
  String productsMargin(int percent) {
    return '$percent% margin';
  }

  @override
  String productsArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String productsArchived(String name) {
    return '$name archived.';
  }

  @override
  String productsRestored(String name) {
    return '$name restored.';
  }

  @override
  String productsDuplicated(String name) {
    return 'Copy of $name added, off the till until you check it.';
  }

  @override
  String optionsUsedBy(String names) {
    return 'On: $names';
  }

  @override
  String optionsPriceInvalid(String name) {
    return 'Check the extra price for \"$name\".';
  }

  @override
  String taxExample(String base, String tax, String total) {
    return 'Example: a GH₵ 100.00 sale is $base plus $tax tax, $total in all.';
  }

  @override
  String editorMarginLine(int percent, String profit) {
    return '$percent% margin, $profit each';
  }

  @override
  String stockFilterLow(int count) {
    return 'Low ($count)';
  }

  @override
  String stockTotalValue(String value) {
    return 'Worth $value at cost';
  }

  @override
  String stockCostEach(String price, String unit) {
    return '$price per $unit';
  }

  @override
  String stockCostPer(String unit) {
    return 'Cost per $unit';
  }

  @override
  String stockWorth(String value, String price, String unit) {
    return 'Worth $value ($price per $unit)';
  }

  @override
  String stockReorderLine(String amount) {
    return 'Low below $amount';
  }

  @override
  String stockLogWasteOf(String name) {
    return 'Waste: $name';
  }

  @override
  String stockAdjustOf(String name) {
    return 'Correct: $name';
  }

  @override
  String stockAdjustReason(String name) {
    return 'Correct stock of $name.';
  }

  @override
  String stockWasteReason(String name) {
    return 'Log waste of $name.';
  }

  @override
  String moveWaste(String reason) {
    return 'Waste: $reason';
  }

  @override
  String receiveDone(String number) {
    return 'Delivery $number saved.';
  }

  @override
  String receiveLineInvalid(String name) {
    return 'Check the amount and cost for $name.';
  }

  @override
  String deliveriesItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String deliveriesOwed(String amount) {
    return '$amount owed';
  }

  @override
  String countPostedStatus(String name) {
    return 'Posted by $name';
  }

  @override
  String countLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items counted',
      one: '1 item counted',
    );
    return '$_temp0';
  }

  @override
  String countPostBody(int count) {
    return 'Stock for the $count items counted will be set to what was found. Items not counted do not change.';
  }

  @override
  String countPostedFound(String amount) {
    return 'Count posted: $amount more than expected.';
  }

  @override
  String countPostedShort(String amount) {
    return 'Count posted: $amount short.';
  }

  @override
  String countProgress(int done, int total) {
    return '$done of $total counted';
  }

  @override
  String countFoundValue(String amount) {
    return '$amount more than expected';
  }

  @override
  String countShortValue(String amount) {
    return '$amount short so far';
  }

  @override
  String countCounted(String amount) {
    return 'Counted $amount';
  }

  @override
  String countExpected(String amount) {
    return 'expected $amount';
  }

  @override
  String suppliersOwedTotal(String amount) {
    return 'You owe $amount in all.';
  }

  @override
  String supplierTermsShort(int days) {
    return 'Pay within $days days';
  }

  @override
  String supplierOwe(String amount) {
    return 'You owe $amount';
  }

  @override
  String supplierCredit(String amount) {
    return 'In credit $amount';
  }

  @override
  String supplierPayTitle(String name) {
    return 'Pay $name';
  }

  @override
  String supplierPayReason(String name) {
    return 'Pay $name.';
  }

  @override
  String supplierPaid(String amount) {
    return '$amount payment recorded.';
  }

  @override
  String supplierEntryPayment(String method) {
    return 'Payment $method';
  }

  @override
  String bulkScope(int count) {
    return 'Applies to the $count products in the list now (use the search and filters to narrow it).';
  }

  @override
  String bulkRoundTo(String amount) {
    return 'Round to $amount';
  }

  @override
  String bulkPreview(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prices change',
      one: '1 price changes',
    );
    return '$_temp0';
  }

  @override
  String bulkApply(int count) {
    return 'Change $count';
  }

  @override
  String bulkDone(int count) {
    return '$count prices changed.';
  }

  @override
  String importSummary(int created, int updated, int same) {
    return '$created new, $updated changed, $same unchanged.';
  }

  @override
  String importNewCategories(String names) {
    return 'New categories: $names';
  }

  @override
  String importProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems',
      one: '1 problem',
    );
    return '$_temp0';
  }

  @override
  String importRow(int row, String message) {
    return 'Row $row: $message';
  }

  @override
  String importDone(int created, int updated) {
    return 'Imported: $created new, $updated changed.';
  }

  @override
  String editorSchedulePrice(String date) {
    return 'New price from $date';
  }

  @override
  String editorScheduled(String price, String date) {
    return '$price from $date';
  }

  @override
  String approvalNeedsDiscount(int percent) {
    return 'Needs someone allowed to give $percent% off';
  }

  @override
  String cartButton(int count) {
    return 'Cart ($count)';
  }

  @override
  String cartButtonParked(int count, int parked) {
    return 'Cart ($count) · $parked parked';
  }

  @override
  String cartClearBody(int count) {
    return '$count items come off. This is recorded in Activity.';
  }

  @override
  String cartDiscountWith(String name) {
    return 'Discounts (incl. $name)';
  }

  @override
  String cartDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are no longer on the menu and were left out.',
      one: '1 item is no longer on the menu and was left out.',
    );
    return '$_temp0';
  }

  @override
  String cartEach(String price) {
    return '$price each';
  }

  @override
  String cartPer(String price, String unit) {
    return '$price per $unit';
  }

  @override
  String cartWas(String price) {
    return 'menu price $price';
  }

  @override
  String cartLineDiscount(String name, String amount) {
    return '$name: −$amount';
  }

  @override
  String parkDefaultName(int number) {
    return 'Order $number';
  }

  @override
  String parkDone(String name) {
    return 'Parked \"$name\".';
  }

  @override
  String parkDiscardTitle(String name) {
    return 'Throw away \"$name\"?';
  }

  @override
  String parkDiscardReason(String name) {
    return 'Throw away the parked order \"$name\".';
  }

  @override
  String closeParkedWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count parked orders have been waiting a long time. Were they paid?',
      one: '1 parked order has been waiting a long time. Was it paid?',
    );
    return '$_temp0';
  }

  @override
  String discountApprovalReason(String discount, String what) {
    return 'Give $discount off $what.';
  }

  @override
  String entryPricePer(String price, String unit) {
    return '$price per $unit';
  }

  @override
  String entryPricePerLabel(String unit) {
    return 'Price per $unit';
  }

  @override
  String entryMin(String price) {
    return 'From $price';
  }

  @override
  String entryMax(String price) {
    return 'up to $price';
  }

  @override
  String lineMenuPrice(String price) {
    return 'Menu price $price';
  }

  @override
  String lineDiscountTitle(String item) {
    return 'Discount on $item';
  }

  @override
  String pickerUpdate(String price) {
    return 'Update · $price';
  }

  @override
  String overrideReason(String item, String price) {
    return 'Change the price of $item to $price.';
  }

  @override
  String settingsHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String tillQuantityHint(int count) {
    return 'Tap a product to add $count, or press Enter for code $count';
  }

  @override
  String tillCodeNotFound(String code) {
    return 'No product has the code $code.';
  }

  @override
  String tillCodeUnknownTitle(String code) {
    return 'No product has $code';
  }

  @override
  String tillOutBlocked(String name) {
    return '$name is out of stock.';
  }

  @override
  String tillOutWarning(String name) {
    return 'The till thinks $name has run out. Check the shelf.';
  }

  @override
  String tillPriceLow(String price) {
    return 'The price must be at least $price.';
  }

  @override
  String tillPriceHigh(String price) {
    return 'The price can be at most $price.';
  }

  @override
  String cartExchange(String amount) {
    return 'Exchange: returned items worth $amount pay first.';
  }

  @override
  String checkoutGiveBack(String amount) {
    return 'The returned items are worth $amount more. Give it back by:';
  }

  @override
  String checkoutTakePart(String amount) {
    return 'Take $amount, pay the rest another way';
  }

  @override
  String checkoutReference(String method) {
    return '$method transaction ID';
  }

  @override
  String checkoutPayTo(String method) {
    return 'Pay to $method';
  }

  @override
  String checkoutRounded(String amount, String difference) {
    return 'Cash rounded to $amount ($difference difference).';
  }

  @override
  String checkoutRoundingLine(String amount, String sign) {
    return 'Cash rounding $sign$amount';
  }

  @override
  String checkoutExchangeLine(String number, String amount) {
    return 'Exchange: refund $number, $amount returned';
  }

  @override
  String get closeRounding => 'Cash rounding';

  @override
  String closeRefunds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count refunds',
      one: '1 refund',
    );
    return '$_temp0';
  }

  @override
  String closeRefundsBy(String method) {
    return 'Refunded by $method';
  }

  @override
  String closeNoSales(String name) {
    return 'Drawer opened without a sale: $name';
  }

  @override
  String exchangeApprovalReason(String amount) {
    return 'Take back items worth $amount as an exchange.';
  }

  @override
  String refundTitle(String number) {
    return 'Refund $number';
  }

  @override
  String refundAlready(String amount) {
    return '$amount has already been refunded.';
  }

  @override
  String refundSold(String quantity, String amount) {
    return 'Sold $quantity for $amount';
  }

  @override
  String refundBackAlready(String quantity) {
    return '$quantity already back';
  }

  @override
  String refundButton(String amount) {
    return 'Refund $amount';
  }

  @override
  String refundApprovalReason(String amount) {
    return 'Give a refund of $amount.';
  }

  @override
  String refundDone(String number) {
    return 'Refund $number saved';
  }

  @override
  String todayApprovedBy(String name) {
    return 'approved by $name';
  }

  @override
  String todayFindNone(String number) {
    return 'No sale $number on this till.';
  }

  @override
  String todayItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String todayRefunded(String amount) {
    return 'Refunded $amount';
  }

  @override
  String todayVoidedBy(String name) {
    return 'Voided by $name';
  }

  @override
  String checkoutKeepChange(String amount) {
    return 'Keep $amount change in their wallet';
  }

  @override
  String checkoutKeepChangeHelp(String name) {
    return '$name can spend it next time.';
  }

  @override
  String checkoutOnAccount(String name) {
    return 'Goes on $name\'s account.';
  }

  @override
  String checkoutOnAccountLimit(String name, String left) {
    return 'Goes on $name\'s account ($left left of their limit).';
  }

  @override
  String checkoutOverLimit(String name, String limit) {
    return 'This takes $name over their credit limit of $limit.';
  }

  @override
  String checkoutOverLimitReason(String name, String owed, String limit) {
    return 'Let $name owe $owed (their limit is $limit).';
  }

  @override
  String checkoutWalletHas(String name, String amount) {
    return '$name has $amount in their wallet.';
  }

  @override
  String customersOwedTotal(String amount) {
    return 'Customers owe $amount in all.';
  }

  @override
  String customerOwes(String amount) {
    return 'owes $amount';
  }

  @override
  String customerWallet(String amount) {
    return 'wallet $amount';
  }

  @override
  String customerLimitLine(String limit, String left) {
    return 'Limit $limit, $left left';
  }

  @override
  String customerOverdueLine(String a, String b, String c) {
    return 'Overdue: $a (1–30 days), $b (31–60), $c (over 60)';
  }

  @override
  String customerRepayReason(String name) {
    return 'Record a payment from $name.';
  }

  @override
  String customerTopUpReason(String name) {
    return 'Put money into $name\'s wallet.';
  }

  @override
  String customerWriteOffReason(String name) {
    return 'Write off what $name owes.';
  }

  @override
  String customerRepaid(String amount) {
    return '$amount payment recorded.';
  }

  @override
  String customerToppedUp(String amount) {
    return '$amount added to the wallet.';
  }

  @override
  String customerWrittenOff(String amount) {
    return '$amount written off.';
  }

  @override
  String customerStatementText(String name) {
    return 'Statement for $name';
  }

  @override
  String customerDaysLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String customerDue(String date) {
    return 'Due $date';
  }

  @override
  String shiftOpened(String amount) {
    return 'Shift opened with $amount.';
  }

  @override
  String shiftLine(String name, String time, String float) {
    return 'Shift opened by $name at $time with $float.';
  }

  @override
  String payInReason(String amount) {
    return 'Put $amount into the drawer.';
  }

  @override
  String payOutReason(String amount) {
    return 'Take $amount out of the drawer.';
  }

  @override
  String payInDone(String amount) {
    return '$amount put in. This is recorded.';
  }

  @override
  String payOutDone(String amount) {
    return '$amount taken out. This is recorded.';
  }

  @override
  String safeDropReason(String amount) {
    return 'Move $amount to the safe.';
  }

  @override
  String safeDropDone(String amount) {
    return '$amount moved to the safe.';
  }

  @override
  String bankDepositAt(String bank) {
    return 'Banked at $bank';
  }

  @override
  String bankDepositReason(String amount) {
    return 'Bank $amount from the safe.';
  }

  @override
  String momoReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count payments',
      one: '1 payment',
    );
    return '$_temp0';
  }

  @override
  String momoUnchecked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count not checked yet',
      one: '1 not checked yet',
    );
    return '$_temp0';
  }

  @override
  String momoMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missing from the statement',
      one: '1 missing from the statement',
    );
    return '$_temp0';
  }

  @override
  String closeSince(String time) {
    return 'Since $time';
  }

  @override
  String closeShiftBy(String name, String float) {
    return 'Shift opened by $name with $float';
  }

  @override
  String closeSales(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0';
  }

  @override
  String closeVoided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voided',
      one: '1 voided',
    );
    return '$_temp0';
  }

  @override
  String closeReasonHelp(String amount) {
    return 'Needed when the drawer is out by more than $amount.';
  }

  @override
  String closeDoneLine(int count, String total, String name) {
    return '$count sales  ·  $total  ·  by $name';
  }

  @override
  String closeOver(String amount) {
    return 'Over $amount';
  }

  @override
  String closeShort(String amount) {
    return 'Short $amount';
  }

  @override
  String closeVarianceLine(String name, int shorts, String amount, int overs) {
    return '$name: short $shorts times ($amount), over $overs times';
  }

  @override
  String expenseReason(String amount) {
    return 'Record an expense of $amount.';
  }

  @override
  String expenseSaved(String amount) {
    return '$amount expense recorded.';
  }

  @override
  String expensesTotal(String amount) {
    return 'Spent: $amount';
  }

  @override
  String recurringLine(String amount, int day, String category) {
    return '$amount on day $day  ·  $category';
  }

  @override
  String recurringDue(String name, String amount, int day) {
    return '$name: $amount, due on day $day';
  }

  @override
  String profitMargin(int percent) {
    return '$percent% of net sales';
  }

  @override
  String ownerTookReason(String amount) {
    return 'Record the owner taking $amount.';
  }

  @override
  String ownerPutReason(String amount) {
    return 'Record the owner putting in $amount.';
  }

  @override
  String dashLastWeek(String amount) {
    return 'same day last week $amount';
  }

  @override
  String dashLastWeekCount(int count) {
    return 'same day last week $count';
  }

  @override
  String dashShiftBy(String name) {
    return 'Shift opened by $name';
  }

  @override
  String alertLowStock(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stock items are low: $names',
      one: '1 stock item is low: $names',
    );
    return '$_temp0';
  }

  @override
  String alertCredit(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers are late paying: $amount',
      one: '1 customer is late paying: $amount',
    );
    return '$_temp0';
  }

  @override
  String alertDayOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A day was not closed: $count sales from before today',
      one: 'A day was not closed: 1 sale from before today',
    );
    return '$_temp0';
  }

  @override
  String alertExpenses(String names, String amount) {
    return 'Due: $names ($amount). See Money.';
  }

  @override
  String reportSold(int count) {
    return '$count sold';
  }

  @override
  String reportProfitLine(String amount, String percent) {
    return 'profit $amount ($percent%)';
  }

  @override
  String reportShorts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Short $count times',
      one: 'Short once',
    );
    return '$_temp0';
  }

  @override
  String statusPrintsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waiting to print.',
      one: '1 waiting to print.',
    );
    return '$_temp0';
  }

  @override
  String scaleRequestLetter(String letter) {
    return 'Send the letter $letter';
  }

  @override
  String scaleReadOk(String kg) {
    return 'The scale says $kg kg.';
  }

  @override
  String notifyHelp(String name) {
    return 'For $name on this device.';
  }

  @override
  String reportPromotionsPart(String amount) {
    return 'Promotions: $amount';
  }

  @override
  String promoAllIn(String category) {
    return 'All $category';
  }

  @override
  String promoPart(int n) {
    return 'Part $n';
  }

  @override
  String promoFrom(String date) {
    return 'from $date';
  }

  @override
  String promoUntil(String date) {
    return 'until $date';
  }

  @override
  String loyaltyFreeReady(String name) {
    return '$name has a free item';
  }

  @override
  String loyaltyStampsHave(int count, int needed) {
    return '$count of $needed stamps';
  }

  @override
  String loyaltyPointsHave(int count) {
    return '$count points';
  }

  @override
  String loyaltyPointsReward(int count, String amount) {
    return '$count points: $amount off';
  }

  @override
  String loyaltyGold(int percent) {
    return 'Gold: $percent% off';
  }

  @override
  String voucherSoldFor(String amount, String date) {
    return 'Sold for $amount on $date';
  }

  @override
  String voucherUseBy(String date) {
    return 'Use by $date';
  }

  @override
  String voucherMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String voucherLeft(String left, String amount) {
    return '$left left of $amount';
  }

  @override
  String voucherHas(String code, String amount) {
    return '$code: $amount left';
  }

  @override
  String orderMoveTo(String status) {
    return 'Move to $status';
  }

  @override
  String orderBack(String status) {
    return 'Back to $status';
  }

  @override
  String screensCannotStart(String error) {
    return 'The screens could not start: $error';
  }

  @override
  String labelsMakeMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Make barcodes for the $count without one',
      one: 'Make a barcode for the 1 without one',
    );
    return '$_temp0';
  }

  @override
  String labelsBarcodesMade(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count barcodes made.',
      one: '1 barcode made.',
    );
    return '$_temp0';
  }

  @override
  String labelsPrint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Print $count labels',
      one: 'Print 1 label',
    );
    return '$_temp0';
  }

  @override
  String labelsForDeliveryBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count products came in that are sold as is. Print their price labels?',
      one: '1 product came in that is sold as is. Print its price labels?',
    );
    return '$_temp0';
  }

  @override
  String alertExpiring(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items expire within a week: $names',
      one: '1 item expires within a week: $names',
    );
    return '$_temp0';
  }

  @override
  String receiveExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String receiveAgainst(String order, String supplier) {
    return 'Against $order from $supplier';
  }

  @override
  String expiryOn(String date) {
    return 'Expires $date';
  }

  @override
  String expiryExpired(String date) {
    return 'Expired $date';
  }

  @override
  String expiryReceived(String date) {
    return 'came in $date';
  }

  @override
  String poNeededBy(String date) {
    return 'Needed by $date';
  }

  @override
  String poLineReceived(String amount) {
    return '$amount received';
  }

  @override
  String poShareText(String number) {
    return 'Purchase order $number';
  }

  @override
  String produceBatchMakes(String amount) {
    return 'One batch makes $amount';
  }

  @override
  String produceRecordTitle(String name) {
    return 'Made $name';
  }

  @override
  String produceRecipeTitle(String name) {
    return 'What $name is made from';
  }

  @override
  String produceReason(String name) {
    return 'Making $name uses up stock.';
  }

  @override
  String produceDone(String amount, String cost) {
    return 'Made $amount, $cost of ingredients.';
  }

  @override
  String badgeFor(String name) {
    return 'Badge for $name';
  }

  @override
  String clockInSince(String time) {
    return 'In since $time';
  }

  @override
  String timeHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String timeBreak(int minutes) {
    return '$minutes min break';
  }

  @override
  String timeLate(int minutes) {
    return '$minutes min late';
  }

  @override
  String timeEarly(int minutes) {
    return 'left $minutes min early';
  }

  @override
  String timeLateCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'late $count times',
      one: 'late once',
    );
    return '$_temp0';
  }

  @override
  String timeEarlyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'left early $count times',
      one: 'left early once',
    );
    return '$_temp0';
  }

  @override
  String commissionPercentOfSales(int percent) {
    return '$percent% of sales';
  }

  @override
  String commandFrom(String price) {
    return 'from $price';
  }

  @override
  String insightRunningOut(String item, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$item will run out in about $count days at this week\'s pace.',
      one: '$item will run out in about a day at this week\'s pace.',
    );
    return '$_temp0';
  }

  @override
  String insightBusyDay(String day, int percent) {
    return '$day sales are $percent% higher than weekdays. Plan enough staff.';
  }

  @override
  String insightMarginDrop(String product, int before, int now) {
    return '$product margin fell from $before% to $now% this week. Costs may have gone up.';
  }

  @override
  String insightLateCredit(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count customers owe for more than 30 days: $amount in total.',
      one: '1 customer owes for more than 30 days: $amount.',
    );
    return '$_temp0';
  }

  @override
  String insightCashShort(int count, String amount) {
    return 'Cash was short $count times this month: $amount in all.';
  }

  @override
  String summarySales(String amount, int count) {
    return 'Sales: $amount ($count)';
  }

  @override
  String summaryProfit(String amount) {
    return 'Profit before expenses: $amount';
  }

  @override
  String summaryTop(String product) {
    return 'Top: $product';
  }

  @override
  String summaryClosedBy(String name) {
    return 'Closed by $name';
  }

  @override
  String summarySalesLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sales',
      one: '1 sale',
    );
    return '$_temp0';
  }

  @override
  String hubCodeExpires(String time) {
    return 'The code works once, until $time.';
  }

  @override
  String hubLastSync(String when) {
    return 'Last synced $when';
  }

  @override
  String hubLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String hubRevokeTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String hubCannotStart(String error) {
    return 'The hub could not start: $error';
  }

  @override
  String branchMoveTitle(String name) {
    return 'Move this device to $name?';
  }

  @override
  String branchDevices(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devices',
      one: '1 device',
    );
    return '$_temp0';
  }

  @override
  String branchMergeConfirmBody(String shop, int count, String last) {
    return '$shop: $count sales, last sale $last. Everything in it is added to this device, newer changes winning. A backup of this device is made first.';
  }

  @override
  String branchMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes brought in.',
      one: '1 change brought in.',
      zero: 'Nothing new in that file.',
    );
    return '$_temp0';
  }

  @override
  String transferFrom(String name) {
    return 'from $name';
  }

  @override
  String transferTo(String name) {
    return 'to $name';
  }

  @override
  String transferSentBy(String when, String name) {
    return 'Sent $when by $name';
  }

  @override
  String transferReceivedBy(String when, String name) {
    return 'received $when by $name';
  }

  @override
  String transferArrived(String qty) {
    return 'Arrived: $qty';
  }

  @override
  String transferReceiveTitle(String code) {
    return 'Receive $code';
  }

  @override
  String transferSentQty(String qty) {
    return 'Sent: $qty';
  }

  @override
  String transferSent(String code) {
    return '$code sent.';
  }

  @override
  String transferNotEnough(String item, String qty) {
    return 'Only $qty of $item here.';
  }

  @override
  String get auditAccountsExported => 'Accountant pack saved';

  @override
  String get accountsMonthly => 'Save the accountant\'s pack every month';

  @override
  String get accountsMonthlyHelp =>
      'On the 1st, last month\'s pack (sales, payments, expenses, purchases, tax and stock, every branch) is saved on this device.';

  @override
  String get accountsFolder => 'Where the packs are saved';

  @override
  String get accountsFolderInApp =>
      'Kept in the app on this device. Use Share to send one.';

  @override
  String get accountsShareLatest => 'Share the latest pack';

  @override
  String get accountsNone => 'No pack saved yet.';

  @override
  String accountsSaved(String name) {
    return 'Accountant pack saved: $name';
  }

  @override
  String get statusAccounts => 'Accountant pack';

  @override
  String get statusAccountsFailed =>
      'The last pack could not be saved. Check the folder in Settings, Backup.';

  @override
  String get tillViewGrid => 'Grid view';

  @override
  String get tillViewList => 'List view';

  @override
  String tillNoMatchTitle(String query) {
    return 'No match for “$query”';
  }

  @override
  String get tillClearSearch => 'Clear search';

  @override
  String get editorPhotoNotPicture =>
      'That file is not a picture. Pick a JPG or PNG photo.';

  @override
  String get editorPhotoNone =>
      'No photo yet: the till shows the category picture.';

  @override
  String get categoriesPicture => 'Picture';

  @override
  String get categoriesPictureAuto => 'Picked from the name';

  @override
  String get settingsTabShop => 'Shop';

  @override
  String get settingsTabSelling => 'Selling';

  @override
  String get settingsTabReceipts => 'Receipts and orders';

  @override
  String get settingsTabDevice => 'This device';

  @override
  String get settingsTabData => 'Backup';

  @override
  String get settingsGroupScreen => 'Screen';

  @override
  String get settingsProductView => 'Products on the till';

  @override
  String get settingsProductViewHelp =>
      'The grid shows photos; the list fits more on a phone. Cashiers can switch on the till.';

  @override
  String get settingsViewAuto => 'Grid on tablets, list on phones';

  @override
  String get settingsViewGrid => 'Grid';

  @override
  String get settingsViewList => 'List';

  @override
  String get settingsPinPad => 'PIN keypad';

  @override
  String get settingsPinPadHelp =>
      'How staff type their PIN on this device, so no one learns it by watching.';

  @override
  String get settingsPinPadStandard => 'Standard';

  @override
  String get settingsPinPadShuffled => 'Shuffled: the digits move every time';

  @override
  String get settingsPinPadKeyboard => 'Keyboard only: no keypad on screen';

  @override
  String pinDigitsEntered(int count, int total) {
    return '$count of $total digits entered';
  }

  @override
  String get pinTypeOnKeyboard => 'Type your PIN on the keyboard';

  @override
  String get pinKeyboardWorks => 'You can also type your PIN on the keyboard';

  @override
  String get pinClear => 'Clear';

  @override
  String get pinDelete => 'Delete';

  @override
  String get pinShowKeypad => 'Show the keypad';

  @override
  String get hubJoinSteps =>
      'On the hub, open Settings, This device, Devices and hub, and tap Add a device. Type the code it shows.';

  @override
  String get hubJoinButton => 'Join';

  @override
  String get hubScanInstead => 'Scan the QR code instead';

  @override
  String get hubLooking => 'Looking for the hub on this Wi-Fi…';

  @override
  String get hubNoneHeard =>
      'No hub heard on this Wi-Fi yet. Check the hub is on, and on the same Wi-Fi.';

  @override
  String get hubLookAgain => 'Look again';

  @override
  String get hubPickOne => 'Pick your shop\'s hub';

  @override
  String hubFound(String name) {
    return 'Hub: $name';
  }

  @override
  String get hubTypeAddress => 'Type the hub\'s address instead';

  @override
  String get hubFindOnWifi => 'Find the hub on the Wi-Fi instead';

  @override
  String get importIntro =>
      'Add or update many products at once from a spreadsheet: one row per product, or one per size when it has several prices.';

  @override
  String get importStep1 =>
      'Download the sample. It is filled in for your kind of shop.';

  @override
  String get importStep2 =>
      'Replace the examples with your products, in Excel or Google Sheets.';

  @override
  String get importStep3 =>
      'Save it as CSV and pick it here. You see what changes before anything is saved.';

  @override
  String get importDownloadSample => 'Download sample';

  @override
  String get importStartFromMine => 'Start from my products instead';

  @override
  String get importColumns => 'Columns';

  @override
  String get importColCategory =>
      'The category. A new name becomes a new category.';

  @override
  String get importColProduct =>
      'Needed. Rows with the same name are one product.';

  @override
  String get importColVariant =>
      'Size or flavour, when the product has several prices.';

  @override
  String get importColPrice => 'Needed. In cedis, for example 15.00.';

  @override
  String get importColCost =>
      'What you pay, for profit. Leave it empty if you are not sure.';

  @override
  String get importColBarcodes => 'One or more, split with |.';

  @override
  String get importColTileLine =>
      'A short line on the till tile, for example 500 ml.';

  @override
  String get importColOnTill => 'yes or no. No keeps it off the till for now.';

  @override
  String get importNeverRemoves =>
      'Importing adds products and updates prices, costs and barcodes. It never removes anything.';

  @override
  String get importFixHint =>
      'Fix these rows in the file and pick it again. Headings like Name, Selling price and Barcode work too.';

  @override
  String get productsNoneYet =>
      'No products yet. Add them one by one, or bring in a whole price list at once.';

  @override
  String get productsImportCta => 'Import from a spreadsheet';

  @override
  String get auditPriceScheduleCancelled => 'Price change called off';

  @override
  String get auditStockCountCancelled => 'Stock count cancelled';

  @override
  String get auditReceiptReprinted => 'Receipt printed again';

  @override
  String get auditTrainingStarted => 'Training mode started';

  @override
  String get activityYes => 'Yes';

  @override
  String get activityNo => 'No';

  @override
  String get activityNotSet => 'Not set';

  @override
  String get activityPrice => 'Price';

  @override
  String get activityValue => 'Value';

  @override
  String get activityProductGone => 'A product no longer on file';

  @override
  String activityPricesUp(int count) {
    return '$count up';
  }

  @override
  String activityPricesDown(int count) {
    return '$count down';
  }

  @override
  String activityShowAll(int count) {
    return 'Show all $count';
  }

  @override
  String get activityShowFewer => 'Show fewer';

  @override
  String get activityCanNow => 'Can now';

  @override
  String get activityCanNoLonger => 'Can no longer';

  @override
  String activityEntryNumber(int seq) {
    return 'Entry $seq in this device\'s log';
  }

  @override
  String get activityFieldName => 'Name';

  @override
  String get activityFieldPhone => 'Phone';

  @override
  String get activityFieldEmail => 'Email';

  @override
  String get activityFieldAddress => 'Address';

  @override
  String get activityFieldEmergencyName => 'Emergency contact';

  @override
  String get activityFieldEmergencyPhone => 'Emergency phone';

  @override
  String get activityFieldIdNumber => 'ID number';

  @override
  String get activityFieldDateOfBirth => 'Date of birth';

  @override
  String get activityFieldStartedOn => 'Started on';

  @override
  String get activityFieldNotes => 'Notes';

  @override
  String get activityFieldRate => 'Rate';

  @override
  String get activityFieldCompound => 'Tax on tax';

  @override
  String get activityFieldKind => 'Type';

  @override
  String get activityFieldScope => 'Used on';

  @override
  String get activityFieldReason => 'Reason';

  @override
  String get activityFieldCounted => 'Items counted';

  @override
  String get activityFieldChanged => 'Items different';

  @override
  String get activityFieldStockValue => 'Stock value';

  @override
  String get activityFieldTotal => 'Total';

  @override
  String get activityFieldSubtotal => 'Before discounts';

  @override
  String get activityFieldDiscountTotal => 'Discounts';

  @override
  String get activityFieldWithoutReceipt => 'Without a receipt';

  @override
  String get activityFieldAmount => 'Amount';

  @override
  String get activityFieldCost => 'Cost';

  @override
  String get activityFieldOwedBefore => 'Owed before';

  @override
  String get activityFieldMaxDiscount => 'Biggest discount allowed';

  @override
  String get toneMidnight => 'Midnight';

  @override
  String get toneLime => 'Lime';

  @override
  String get toneBlue => 'Blue';

  @override
  String get toneCoral => 'Coral';

  @override
  String get toneAmber => 'Amber';

  @override
  String get toneTeal => 'Teal';

  @override
  String get toneViolet => 'Violet';

  @override
  String get toneRose => 'Rose';

  @override
  String get categoriesIconsFood => 'Food and drink';

  @override
  String get categoriesIconsShop => 'Other shops';

  @override
  String tillProductCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String get auditMomoChargesSet => 'MoMo charges entered';

  @override
  String get settingKindOfShop => 'Kind of shop';

  @override
  String get settingTargetMargin => 'Target margin';

  @override
  String get settingVoucherMonths => 'Gift vouchers can be spent for';

  @override
  String get settingCommissionRate => 'Commission rate';

  @override
  String settingReceiptPart(String part) {
    return 'Receipt: $part';
  }

  @override
  String get settingLogo => 'Logo';

  @override
  String get settingLogoAdded => 'A logo';

  @override
  String get settingReceiptCopies => 'Receipt copies for credit sales';

  @override
  String get settingScreensPort => 'Screens port';

  @override
  String get settingNone => 'None';

  @override
  String get settingOn => 'On';

  @override
  String get settingOff => 'Off';

  @override
  String get settingRemovedItem => 'an item no longer on file';

  @override
  String get settingChanged => 'Changed';

  @override
  String activitySettingChanged(String setting) {
    return 'Changed $setting';
  }

  @override
  String activitySettingChangedTo(String setting, String before, String after) {
    return '$setting: $before to $after';
  }
}
