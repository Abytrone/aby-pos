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
  String get settingsTheme => 'Colours';

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
  String get editorBarcodes => 'Barcodes';

  @override
  String get editorAddBarcode => 'Add barcode';

  @override
  String get editorBarcode => 'Barcode';

  @override
  String get editorBarcodeHelp => 'Type it, or scan it with a barcode scanner.';

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
  String importHelp(String columns) {
    return 'Columns: $columns. Import adds products and updates prices, costs and barcodes. It never removes anything.';
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
}
