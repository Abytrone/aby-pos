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
}
