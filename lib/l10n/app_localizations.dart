import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get commonCopied;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @navSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get navSell;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get navManage;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @pinAgainLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN again'**
  String get pinAgainLabel;

  /// No description provided for @pinNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get pinNewLabel;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Try again.'**
  String get pinWrong;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs don\'t match.'**
  String get pinMismatch;

  /// No description provided for @signInWho.
  ///
  /// In en, this message translates to:
  /// **'Who\'s on the till?'**
  String get signInWho;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your shop'**
  String get setupTitle;

  /// No description provided for @setupShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get setupShopName;

  /// No description provided for @setupYourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get setupYourName;

  /// No description provided for @setupCreateOwner.
  ///
  /// In en, this message translates to:
  /// **'Create owner and start'**
  String get setupCreateOwner;

  /// No description provided for @setupShopNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter the shop name.'**
  String get setupShopNameMissing;

  /// No description provided for @setupNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get setupNameMissing;

  /// No description provided for @setupMovingDevice.
  ///
  /// In en, this message translates to:
  /// **'Moving to a new device? Bring everything across from a backup.'**
  String get setupMovingDevice;

  /// No description provided for @setupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from a backup'**
  String get setupRestore;

  /// No description provided for @setupJoinHelp.
  ///
  /// In en, this message translates to:
  /// **'Adding a till to a shop that already uses Aby? Join the shop\'s hub and everything comes across.'**
  String get setupJoinHelp;

  /// No description provided for @setupJoinHub.
  ///
  /// In en, this message translates to:
  /// **'Join the shop\'s hub'**
  String get setupJoinHub;

  /// No description provided for @setupJoinRetry.
  ///
  /// In en, this message translates to:
  /// **'Sync with the hub again'**
  String get setupJoinRetry;

  /// No description provided for @setupJoinNoStaff.
  ///
  /// In en, this message translates to:
  /// **'Joined the hub, but the shop\'s staff have not come across yet. Keep the hub on and sync again.'**
  String get setupJoinNoStaff;

  /// No description provided for @userMenu.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get userMenu;

  /// No description provided for @userSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch user'**
  String get userSwitch;

  /// No description provided for @userLock.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get userLock;

  /// No description provided for @userSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Hand over the till'**
  String get userSwitchTitle;

  /// No description provided for @approvalTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval needed'**
  String get approvalTitle;

  /// No description provided for @approvalPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Their PIN'**
  String get approvalPinTitle;

  /// No description provided for @approvalWrongPin.
  ///
  /// In en, this message translates to:
  /// **'That number and PIN can\'t approve this.'**
  String get approvalWrongPin;

  /// No description provided for @statusCentreTitle.
  ///
  /// In en, this message translates to:
  /// **'Is everything safe?'**
  String get statusCentreTitle;

  /// No description provided for @statusAllSafe.
  ///
  /// In en, this message translates to:
  /// **'All safe'**
  String get statusAllSafe;

  /// No description provided for @statusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get statusNeedsAttention;

  /// No description provided for @statusProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get statusProblem;

  /// No description provided for @statusLocalBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup on this device'**
  String get statusLocalBackup;

  /// No description provided for @statusOffsiteBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup off this device'**
  String get statusOffsiteBackup;

  /// No description provided for @statusActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get statusActivityLog;

  /// No description provided for @statusSync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get statusSync;

  /// No description provided for @statusNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get statusNever;

  /// No description provided for @statusChainIntact.
  ///
  /// In en, this message translates to:
  /// **'Checked. Nothing has been changed.'**
  String get statusChainIntact;

  /// No description provided for @statusChainBroken.
  ///
  /// In en, this message translates to:
  /// **'Entries were changed or removed outside Aby.'**
  String get statusChainBroken;

  /// No description provided for @statusNothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting.'**
  String get statusNothingWaiting;

  /// No description provided for @statusOpenActivity.
  ///
  /// In en, this message translates to:
  /// **'Open activity'**
  String get statusOpenActivity;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @todaySales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get todaySales;

  /// No description provided for @todayNoSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet today.'**
  String get todayNoSales;

  /// No description provided for @closeDayButton.
  ///
  /// In en, this message translates to:
  /// **'Close day'**
  String get closeDayButton;

  /// No description provided for @closeDayApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Close the day and count the drawer.'**
  String get closeDayApprovalReason;

  /// No description provided for @voidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Void sale'**
  String get voidConfirm;

  /// No description provided for @voidKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep sale'**
  String get voidKeep;

  /// No description provided for @staffAdd.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get staffAdd;

  /// No description provided for @staffPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get staffPeople;

  /// No description provided for @staffRoles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get staffRoles;

  /// No description provided for @staffName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get staffName;

  /// No description provided for @staffRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get staffRole;

  /// No description provided for @staffPickRole.
  ///
  /// In en, this message translates to:
  /// **'Pick a role.'**
  String get staffPickRole;

  /// No description provided for @staffChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get staffChangePin;

  /// No description provided for @staffChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get staffChangeRole;

  /// No description provided for @staffDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get staffDeactivate;

  /// No description provided for @staffReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get staffReactivate;

  /// No description provided for @staffCantDeactivateSelf.
  ///
  /// In en, this message translates to:
  /// **'You can\'t deactivate yourself.'**
  String get staffCantDeactivateSelf;

  /// No description provided for @staffDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to sign in. Their sales and history stay.'**
  String get staffDeactivateBody;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get roleCashier;

  /// No description provided for @roleStockKeeper.
  ///
  /// In en, this message translates to:
  /// **'Stock keeper'**
  String get roleStockKeeper;

  /// No description provided for @rolesAdd.
  ///
  /// In en, this message translates to:
  /// **'New role'**
  String get rolesAdd;

  /// No description provided for @rolesName.
  ///
  /// In en, this message translates to:
  /// **'Role name'**
  String get rolesName;

  /// No description provided for @rolesMaxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Highest discount without approval'**
  String get rolesMaxDiscount;

  /// No description provided for @rolesMaxDiscountHelp.
  ///
  /// In en, this message translates to:
  /// **'Bigger discounts will need someone with a higher limit.'**
  String get rolesMaxDiscountHelp;

  /// No description provided for @rolesOwnerFixed.
  ///
  /// In en, this message translates to:
  /// **'Owners can always do everything. This role cannot be changed.'**
  String get rolesOwnerFixed;

  /// No description provided for @rolesSaved.
  ///
  /// In en, this message translates to:
  /// **'Role saved.'**
  String get rolesSaved;

  /// No description provided for @rolesBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Built in'**
  String get rolesBuiltIn;

  /// No description provided for @rolesEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get rolesEverything;

  /// No description provided for @rolesDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete role'**
  String get rolesDelete;

  /// No description provided for @rolesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Nobody has this role. It will be removed from the list.'**
  String get rolesDeleteBody;

  /// No description provided for @rolesCannotGrant.
  ///
  /// In en, this message translates to:
  /// **'You can\'t give a role permissions you don\'t have yourself.'**
  String get rolesCannotGrant;

  /// No description provided for @permSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get permSell;

  /// No description provided for @permOverridePrice.
  ///
  /// In en, this message translates to:
  /// **'Change a price at the till'**
  String get permOverridePrice;

  /// No description provided for @permRefund.
  ///
  /// In en, this message translates to:
  /// **'Give refunds'**
  String get permRefund;

  /// No description provided for @permRefundWithoutReceipt.
  ///
  /// In en, this message translates to:
  /// **'Refund without a receipt'**
  String get permRefundWithoutReceipt;

  /// No description provided for @permVoidSale.
  ///
  /// In en, this message translates to:
  /// **'Void sales'**
  String get permVoidSale;

  /// No description provided for @permNoSale.
  ///
  /// In en, this message translates to:
  /// **'Open the drawer without a sale'**
  String get permNoSale;

  /// No description provided for @permEditProducts.
  ///
  /// In en, this message translates to:
  /// **'Add and edit products'**
  String get permEditProducts;

  /// No description provided for @permChangePrices.
  ///
  /// In en, this message translates to:
  /// **'Change prices'**
  String get permChangePrices;

  /// No description provided for @permReceiveStock.
  ///
  /// In en, this message translates to:
  /// **'Receive stock'**
  String get permReceiveStock;

  /// No description provided for @permAdjustStock.
  ///
  /// In en, this message translates to:
  /// **'Adjust stock'**
  String get permAdjustStock;

  /// No description provided for @permApproveStockCount.
  ///
  /// In en, this message translates to:
  /// **'Approve stock counts'**
  String get permApproveStockCount;

  /// No description provided for @permGiveCredit.
  ///
  /// In en, this message translates to:
  /// **'Sell on credit'**
  String get permGiveCredit;

  /// No description provided for @permWriteOffCredit.
  ///
  /// In en, this message translates to:
  /// **'Write off credit'**
  String get permWriteOffCredit;

  /// No description provided for @permCloseDay.
  ///
  /// In en, this message translates to:
  /// **'Close the day'**
  String get permCloseDay;

  /// No description provided for @permPayOut.
  ///
  /// In en, this message translates to:
  /// **'Pay out from the drawer'**
  String get permPayOut;

  /// No description provided for @permViewReports.
  ///
  /// In en, this message translates to:
  /// **'See reports'**
  String get permViewReports;

  /// No description provided for @permViewCostAndProfit.
  ///
  /// In en, this message translates to:
  /// **'See costs and profit'**
  String get permViewCostAndProfit;

  /// No description provided for @permManageStaff.
  ///
  /// In en, this message translates to:
  /// **'Manage staff'**
  String get permManageStaff;

  /// No description provided for @permManageRoles.
  ///
  /// In en, this message translates to:
  /// **'Manage roles'**
  String get permManageRoles;

  /// No description provided for @permChangeSettings.
  ///
  /// In en, this message translates to:
  /// **'Change settings'**
  String get permChangeSettings;

  /// No description provided for @permManageDevices.
  ///
  /// In en, this message translates to:
  /// **'Manage devices and the hub'**
  String get permManageDevices;

  /// No description provided for @permViewActivityLog.
  ///
  /// In en, this message translates to:
  /// **'See the activity log'**
  String get permViewActivityLog;

  /// No description provided for @permExportData.
  ///
  /// In en, this message translates to:
  /// **'Export data and backups'**
  String get permExportData;

  /// No description provided for @permRestoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get permRestoreBackup;

  /// No description provided for @permGroupSell.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get permGroupSell;

  /// No description provided for @permGroupCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Products and stock'**
  String get permGroupCatalogue;

  /// No description provided for @permGroupCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get permGroupCustomers;

  /// No description provided for @permGroupCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get permGroupCash;

  /// No description provided for @permGroupReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get permGroupReports;

  /// No description provided for @permGroupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get permGroupAdmin;

  /// No description provided for @auditSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get auditSignedIn;

  /// No description provided for @auditSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get auditSignInFailed;

  /// No description provided for @auditLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Locked out'**
  String get auditLockedOut;

  /// No description provided for @auditLocked.
  ///
  /// In en, this message translates to:
  /// **'Till locked'**
  String get auditLocked;

  /// No description provided for @auditApprovalRefused.
  ///
  /// In en, this message translates to:
  /// **'Approval locked'**
  String get auditApprovalRefused;

  /// No description provided for @auditSaleVoided.
  ///
  /// In en, this message translates to:
  /// **'Sale voided'**
  String get auditSaleVoided;

  /// No description provided for @auditDayClosed.
  ///
  /// In en, this message translates to:
  /// **'Day closed'**
  String get auditDayClosed;

  /// No description provided for @auditStaffAdded.
  ///
  /// In en, this message translates to:
  /// **'Staff added'**
  String get auditStaffAdded;

  /// No description provided for @auditStaffPinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get auditStaffPinChanged;

  /// No description provided for @auditStaffRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'Role changed'**
  String get auditStaffRoleChanged;

  /// No description provided for @auditStaffDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Staff deactivated'**
  String get auditStaffDeactivated;

  /// No description provided for @auditStaffReactivated.
  ///
  /// In en, this message translates to:
  /// **'Staff reactivated'**
  String get auditStaffReactivated;

  /// No description provided for @auditRoleCreated.
  ///
  /// In en, this message translates to:
  /// **'Role created'**
  String get auditRoleCreated;

  /// No description provided for @auditRoleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Role changed'**
  String get auditRoleUpdated;

  /// No description provided for @auditRoleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Role deleted'**
  String get auditRoleDeleted;

  /// No description provided for @auditSettingChanged.
  ///
  /// In en, this message translates to:
  /// **'Setting changed'**
  String get auditSettingChanged;

  /// No description provided for @auditBackupCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup made'**
  String get auditBackupCreated;

  /// No description provided for @auditBackupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup sent'**
  String get auditBackupExported;

  /// No description provided for @auditBackupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get auditBackupRestored;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every sensitive action, who did it and who approved it.'**
  String get activitySubtitle;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here for these filters.'**
  String get activityEmpty;

  /// No description provided for @activityEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get activityEveryone;

  /// No description provided for @activityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get activityFilterAll;

  /// No description provided for @activityFilterImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get activityFilterImportant;

  /// No description provided for @activityFilterSignIns.
  ///
  /// In en, this message translates to:
  /// **'Sign-ins'**
  String get activityFilterSignIns;

  /// No description provided for @activityFilterSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get activityFilterSales;

  /// No description provided for @activityFilterStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff and roles'**
  String get activityFilterStaff;

  /// No description provided for @activityFilterSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings and data'**
  String get activityFilterSettings;

  /// No description provided for @activityBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get activityBefore;

  /// No description provided for @activityAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get activityAfter;

  /// No description provided for @activityChainIntact.
  ///
  /// In en, this message translates to:
  /// **'Checked: the activity log has not been changed.'**
  String get activityChainIntact;

  /// No description provided for @rangeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rangeToday;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get rangeMonth;

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get rangeAll;

  /// No description provided for @settingsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search settings'**
  String get settingsSearch;

  /// No description provided for @settingsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No settings match.'**
  String get settingsNoMatch;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get settingsSaved;

  /// No description provided for @settingsNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsNotSet;

  /// No description provided for @settingsApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Change a shop setting.'**
  String get settingsApprovalReason;

  /// No description provided for @settingsGroupShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get settingsGroupShop;

  /// No description provided for @settingsGroupDay.
  ///
  /// In en, this message translates to:
  /// **'Business day'**
  String get settingsGroupDay;

  /// No description provided for @settingsGroupSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsGroupSecurity;

  /// No description provided for @settingsGroupDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsGroupDevice;

  /// No description provided for @settingsGroupData.
  ///
  /// In en, this message translates to:
  /// **'Backup and restore'**
  String get settingsGroupData;

  /// No description provided for @settingsGroupAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsGroupAbout;

  /// No description provided for @settingsShopName.
  ///
  /// In en, this message translates to:
  /// **'Shop name'**
  String get settingsShopName;

  /// No description provided for @settingsShopPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get settingsShopPhone;

  /// No description provided for @settingsShopAddress.
  ///
  /// In en, this message translates to:
  /// **'Address or landmark'**
  String get settingsShopAddress;

  /// No description provided for @settingsDayStart.
  ///
  /// In en, this message translates to:
  /// **'Business day starts at'**
  String get settingsDayStart;

  /// No description provided for @settingsDayStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Open past midnight? Pick a time after you close, so late sales stay on the evening they belong to.'**
  String get settingsDayStartHelp;

  /// No description provided for @settingsAutoLock.
  ///
  /// In en, this message translates to:
  /// **'Lock the till after'**
  String get settingsAutoLock;

  /// No description provided for @settingsAutoLockHelp.
  ///
  /// In en, this message translates to:
  /// **'When nobody touches it. The cart is kept.'**
  String get settingsAutoLockHelp;

  /// No description provided for @settingsAutoLockOff.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get settingsAutoLockOff;

  /// No description provided for @settingsDeviceName.
  ///
  /// In en, this message translates to:
  /// **'Device name'**
  String get settingsDeviceName;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as the device'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLargeText.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get settingsLargeText;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageMore.
  ///
  /// In en, this message translates to:
  /// **'More languages are coming.'**
  String get settingsLanguageMore;

  /// No description provided for @settingsAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups'**
  String get settingsAutoBackup;

  /// No description provided for @settingsBackupsKeep.
  ///
  /// In en, this message translates to:
  /// **'Backups to keep on this device'**
  String get settingsBackupsKeep;

  /// No description provided for @settingsOffsiteReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me to send a backup every'**
  String get settingsOffsiteReminder;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsErrorLog.
  ///
  /// In en, this message translates to:
  /// **'Error log'**
  String get settingsErrorLog;

  /// No description provided for @settingsErrorLogHelp.
  ///
  /// In en, this message translates to:
  /// **'Send it to Aby support when something went wrong.'**
  String get settingsErrorLogHelp;

  /// No description provided for @settingsErrorLogNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing has gone wrong on this device.'**
  String get settingsErrorLogNone;

  /// No description provided for @settingsDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get settingsDeviceId;

  /// No description provided for @settingsDataVersion.
  ///
  /// In en, this message translates to:
  /// **'Data version'**
  String get settingsDataVersion;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup saved on this device.'**
  String get backupDone;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The backup didn\'t work. Try again.'**
  String get backupFailed;

  /// No description provided for @backupOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Backups on this device'**
  String get backupOnDevice;

  /// No description provided for @backupNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No backups yet.'**
  String get backupNoneYet;

  /// No description provided for @backupSend.
  ///
  /// In en, this message translates to:
  /// **'Send a backup off this device'**
  String get backupSend;

  /// No description provided for @backupSendHelp.
  ///
  /// In en, this message translates to:
  /// **'The file is locked with this password. Keep it somewhere safe: without it the backup cannot be opened.'**
  String get backupSendHelp;

  /// No description provided for @backupPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password'**
  String get backupPassword;

  /// No description provided for @backupPasswordSet.
  ///
  /// In en, this message translates to:
  /// **'Set a backup password'**
  String get backupPasswordSet;

  /// No description provided for @backupPasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Change the backup password'**
  String get backupPasswordChange;

  /// No description provided for @backupPasswordNew.
  ///
  /// In en, this message translates to:
  /// **'New backup password'**
  String get backupPasswordNew;

  /// No description provided for @backupPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'Backup password again'**
  String get backupPasswordAgain;

  /// No description provided for @backupPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Used to lock backups that leave this device. Old backups keep their old password.'**
  String get backupPasswordHelp;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The passwords don\'t match.'**
  String get backupPasswordMismatch;

  /// No description provided for @backupPasswordSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup password saved.'**
  String get backupPasswordSaved;

  /// No description provided for @backupPasswordWrong.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t the backup password.'**
  String get backupPasswordWrong;

  /// No description provided for @backupEncrypting.
  ///
  /// In en, this message translates to:
  /// **'Making and locking the backup...'**
  String get backupEncrypting;

  /// No description provided for @backupWhere.
  ///
  /// In en, this message translates to:
  /// **'Where should it go?'**
  String get backupWhere;

  /// No description provided for @backupShare.
  ///
  /// In en, this message translates to:
  /// **'Share (WhatsApp, Drive, email...)'**
  String get backupShare;

  /// No description provided for @backupSaveToFolder.
  ///
  /// In en, this message translates to:
  /// **'Save to a folder or USB stick'**
  String get backupSaveToFolder;

  /// No description provided for @backupShareUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available here. Save to a folder instead.'**
  String get backupShareUnavailable;

  /// No description provided for @backupSent.
  ///
  /// In en, this message translates to:
  /// **'Backup sent. Keep the password safe.'**
  String get backupSent;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestore;

  /// No description provided for @backupRestoreFromFile.
  ///
  /// In en, this message translates to:
  /// **'Restore from a file'**
  String get backupRestoreFromFile;

  /// No description provided for @backupPickFile.
  ///
  /// In en, this message translates to:
  /// **'Pick the backup file'**
  String get backupPickFile;

  /// No description provided for @backupChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking the backup...'**
  String get backupChecking;

  /// No description provided for @backupRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get backupRestoring;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace everything on this device?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreReplacing.
  ///
  /// In en, this message translates to:
  /// **'This backup is from another device. Is this device replacing it?'**
  String get backupRestoreReplacing;

  /// No description provided for @backupRestoreReplacingYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, it replaces that device'**
  String get backupRestoreReplacingYes;

  /// No description provided for @backupRestoreReplacingNo.
  ///
  /// In en, this message translates to:
  /// **'No, keep this as a separate device'**
  String get backupRestoreReplacingNo;

  /// No description provided for @backupRestoreLinked.
  ///
  /// In en, this message translates to:
  /// **'This device syncs with other tills. Changes made on them since this backup will come back after restoring.'**
  String get backupRestoreLinked;

  /// No description provided for @backupNoSales.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get backupNoSales;

  /// No description provided for @auditStaffDetailsChanged.
  ///
  /// In en, this message translates to:
  /// **'Details changed'**
  String get auditStaffDetailsChanged;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff profile'**
  String get profileTitle;

  /// No description provided for @profileMine.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get profileMine;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get profileEdit;

  /// No description provided for @profileNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'You can only see your own profile.'**
  String get profileNotAllowed;

  /// No description provided for @profileActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileActive;

  /// No description provided for @profileDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get profileDeactivated;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profileTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get profileTakePhoto;

  /// No description provided for @profileChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a photo'**
  String get profileChoosePhoto;

  /// No description provided for @profileRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get profileRemovePhoto;

  /// No description provided for @profilePhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved.'**
  String get profilePhotoSaved;

  /// No description provided for @profileContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get profileContact;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhone;

  /// No description provided for @profilePhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'For example 024 123 4567.'**
  String get profilePhoneHelp;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileAddress.
  ///
  /// In en, this message translates to:
  /// **'Address or landmark'**
  String get profileAddress;

  /// No description provided for @profileEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get profileEmergency;

  /// No description provided for @profileEmergencyName.
  ///
  /// In en, this message translates to:
  /// **'Name and relationship'**
  String get profileEmergencyName;

  /// No description provided for @profileIdentityWork.
  ///
  /// In en, this message translates to:
  /// **'Identity and work'**
  String get profileIdentityWork;

  /// No description provided for @profileManagerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only a manager can change these.'**
  String get profileManagerOnly;

  /// No description provided for @profileGhanaCard.
  ///
  /// In en, this message translates to:
  /// **'Ghana Card number'**
  String get profileGhanaCard;

  /// No description provided for @profileGhanaCardHelp.
  ///
  /// In en, this message translates to:
  /// **'For example GHA-123456789-0.'**
  String get profileGhanaCardHelp;

  /// No description provided for @profileDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get profileDateOfBirth;

  /// No description provided for @profileStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started work'**
  String get profileStartedOn;

  /// No description provided for @profileNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get profileNotes;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like a Ghana phone number.'**
  String get profilePhoneInvalid;

  /// No description provided for @profileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an email address.'**
  String get profileEmailInvalid;

  /// No description provided for @profileIdInvalid.
  ///
  /// In en, this message translates to:
  /// **'A Ghana Card number looks like GHA-123456789-0.'**
  String get profileIdInvalid;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Details saved.'**
  String get profileSaved;

  /// No description provided for @profileCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get profileCurrentPin;

  /// No description provided for @profilePinReason.
  ///
  /// In en, this message translates to:
  /// **'Change someone else\'s PIN.'**
  String get profilePinReason;

  /// No description provided for @profilePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get profilePerformance;

  /// No description provided for @profileSalesToday.
  ///
  /// In en, this message translates to:
  /// **'Sales today'**
  String get profileSalesToday;

  /// No description provided for @profileSales30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get profileSales30;

  /// No description provided for @profileAverageSale.
  ///
  /// In en, this message translates to:
  /// **'Average sale'**
  String get profileAverageSale;

  /// No description provided for @profileVoids.
  ///
  /// In en, this message translates to:
  /// **'Voids'**
  String get profileVoids;

  /// No description provided for @profileCloses.
  ///
  /// In en, this message translates to:
  /// **'Day closes'**
  String get profileCloses;

  /// No description provided for @profileClosesBalanced.
  ///
  /// In en, this message translates to:
  /// **'All balanced'**
  String get profileClosesBalanced;

  /// No description provided for @profileSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSecurity;

  /// No description provided for @profileLastSignIn.
  ///
  /// In en, this message translates to:
  /// **'Last signed in'**
  String get profileLastSignIn;

  /// No description provided for @profileWrongPins.
  ///
  /// In en, this message translates to:
  /// **'Wrong PINs'**
  String get profileWrongPins;

  /// No description provided for @profileRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get profileRecentActivity;

  /// No description provided for @navProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get navProducts;

  /// No description provided for @navStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get navStock;

  /// No description provided for @activityFilterCatalogue.
  ///
  /// In en, this message translates to:
  /// **'Products and stock'**
  String get activityFilterCatalogue;

  /// No description provided for @auditProductCreated.
  ///
  /// In en, this message translates to:
  /// **'Product added'**
  String get auditProductCreated;

  /// No description provided for @auditProductUpdated.
  ///
  /// In en, this message translates to:
  /// **'Product changed'**
  String get auditProductUpdated;

  /// No description provided for @auditProductArchived.
  ///
  /// In en, this message translates to:
  /// **'Product archived'**
  String get auditProductArchived;

  /// No description provided for @auditProductRestored.
  ///
  /// In en, this message translates to:
  /// **'Product restored'**
  String get auditProductRestored;

  /// No description provided for @auditPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Price changed'**
  String get auditPriceChanged;

  /// No description provided for @auditCategorySaved.
  ///
  /// In en, this message translates to:
  /// **'Category changed'**
  String get auditCategorySaved;

  /// No description provided for @auditOptionGroupSaved.
  ///
  /// In en, this message translates to:
  /// **'Options changed'**
  String get auditOptionGroupSaved;

  /// No description provided for @auditTaxRateSaved.
  ///
  /// In en, this message translates to:
  /// **'Tax changed'**
  String get auditTaxRateSaved;

  /// No description provided for @auditStockItemSaved.
  ///
  /// In en, this message translates to:
  /// **'Stock item changed'**
  String get auditStockItemSaved;

  /// No description provided for @auditStockReceived.
  ///
  /// In en, this message translates to:
  /// **'Delivery received'**
  String get auditStockReceived;

  /// No description provided for @auditStockAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock corrected'**
  String get auditStockAdjusted;

  /// No description provided for @auditStockWasted.
  ///
  /// In en, this message translates to:
  /// **'Waste logged'**
  String get auditStockWasted;

  /// No description provided for @auditStockCountPosted.
  ///
  /// In en, this message translates to:
  /// **'Stock count posted'**
  String get auditStockCountPosted;

  /// No description provided for @auditSupplierSaved.
  ///
  /// In en, this message translates to:
  /// **'Supplier changed'**
  String get auditSupplierSaved;

  /// No description provided for @auditSupplierPaid.
  ///
  /// In en, this message translates to:
  /// **'Supplier paid'**
  String get auditSupplierPaid;

  /// No description provided for @auditPriceScheduled.
  ///
  /// In en, this message translates to:
  /// **'Price scheduled'**
  String get auditPriceScheduled;

  /// No description provided for @auditPricesBulkChanged.
  ///
  /// In en, this message translates to:
  /// **'Prices changed in bulk'**
  String get auditPricesBulkChanged;

  /// No description provided for @auditCatalogueImported.
  ///
  /// In en, this message translates to:
  /// **'Products imported'**
  String get auditCatalogueImported;

  /// No description provided for @auditStockImported.
  ///
  /// In en, this message translates to:
  /// **'Stock imported'**
  String get auditStockImported;

  /// No description provided for @auditProductsFromStock.
  ///
  /// In en, this message translates to:
  /// **'Products made from stock'**
  String get auditProductsFromStock;

  /// No description provided for @cartTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get cartTax;

  /// No description provided for @cartTaxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes tax'**
  String get cartTaxIncluded;

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cartTotal;

  /// No description provided for @tileOut.
  ///
  /// In en, this message translates to:
  /// **'None left'**
  String get tileOut;

  /// No description provided for @pickerSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get pickerSize;

  /// No description provided for @pickerRemoveOne.
  ///
  /// In en, this message translates to:
  /// **'One less'**
  String get pickerRemoveOne;

  /// No description provided for @groupOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get groupOptional;

  /// No description provided for @productsTab.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsTab;

  /// No description provided for @categoriesTab.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTab;

  /// No description provided for @optionsTab.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsTab;

  /// No description provided for @taxTab.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxTab;

  /// No description provided for @productsNew.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get productsNew;

  /// No description provided for @productsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search name or barcode'**
  String get productsSearch;

  /// No description provided for @productsAllCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get productsAllCategories;

  /// No description provided for @productsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get productsFilterAll;

  /// No description provided for @productsFilterOnTill.
  ///
  /// In en, this message translates to:
  /// **'On the till'**
  String get productsFilterOnTill;

  /// No description provided for @productsFilterOffTill.
  ///
  /// In en, this message translates to:
  /// **'Off the till'**
  String get productsFilterOffTill;

  /// No description provided for @productsFilterLowMargin.
  ///
  /// In en, this message translates to:
  /// **'Low margin'**
  String get productsFilterLowMargin;

  /// No description provided for @productsFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get productsFilterArchived;

  /// No description provided for @productsNone.
  ///
  /// In en, this message translates to:
  /// **'No products here.'**
  String get productsNone;

  /// No description provided for @productsNoCost.
  ///
  /// In en, this message translates to:
  /// **'No cost set'**
  String get productsNoCost;

  /// No description provided for @productsDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get productsDuplicate;

  /// No description provided for @productsArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get productsArchive;

  /// No description provided for @productsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get productsRestore;

  /// No description provided for @productsArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'It comes off the till and the lists. Past sales keep it, and you can restore it later.'**
  String get productsArchiveBody;

  /// No description provided for @productsEditReason.
  ///
  /// In en, this message translates to:
  /// **'Change products.'**
  String get productsEditReason;

  /// No description provided for @productsArchiveReason.
  ///
  /// In en, this message translates to:
  /// **'Archive a product.'**
  String get productsArchiveReason;

  /// No description provided for @productsDuplicateReason.
  ///
  /// In en, this message translates to:
  /// **'Copy a product.'**
  String get productsDuplicateReason;

  /// No description provided for @categoriesNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoriesNew;

  /// No description provided for @categoriesEdit.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get categoriesEdit;

  /// No description provided for @categoriesName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoriesName;

  /// No description provided for @categoriesColour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get categoriesColour;

  /// No description provided for @categoriesInside.
  ///
  /// In en, this message translates to:
  /// **'Put it inside'**
  String get categoriesInside;

  /// No description provided for @categoriesTopLevel.
  ///
  /// In en, this message translates to:
  /// **'Nothing (top level)'**
  String get categoriesTopLevel;

  /// No description provided for @categoriesHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get categoriesHidden;

  /// No description provided for @categoriesNone.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get categoriesNone;

  /// No description provided for @optionsNew.
  ///
  /// In en, this message translates to:
  /// **'New options'**
  String get optionsNew;

  /// No description provided for @optionsEdit.
  ///
  /// In en, this message translates to:
  /// **'Change options'**
  String get optionsEdit;

  /// No description provided for @optionsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get optionsName;

  /// No description provided for @optionsNameHelp.
  ///
  /// In en, this message translates to:
  /// **'For example Extras, Sugar level or Sauce.'**
  String get optionsNameHelp;

  /// No description provided for @optionsMin.
  ///
  /// In en, this message translates to:
  /// **'Must pick at least'**
  String get optionsMin;

  /// No description provided for @optionsMinHelp.
  ///
  /// In en, this message translates to:
  /// **'0 makes it optional.'**
  String get optionsMinHelp;

  /// No description provided for @optionsMax.
  ///
  /// In en, this message translates to:
  /// **'Can pick up to'**
  String get optionsMax;

  /// No description provided for @optionsMaxHelp.
  ///
  /// In en, this message translates to:
  /// **'Empty: no limit.'**
  String get optionsMaxHelp;

  /// No description provided for @optionsRepeat.
  ///
  /// In en, this message translates to:
  /// **'The same option can be picked twice'**
  String get optionsRepeat;

  /// No description provided for @optionsRepeatHelp.
  ///
  /// In en, this message translates to:
  /// **'For example double sprinkles.'**
  String get optionsRepeatHelp;

  /// No description provided for @optionsOptionName.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get optionsOptionName;

  /// No description provided for @optionsExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get optionsExtra;

  /// No description provided for @optionsRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove option'**
  String get optionsRemove;

  /// No description provided for @optionsDefault.
  ///
  /// In en, this message translates to:
  /// **'Ticked when the picker opens'**
  String get optionsDefault;

  /// No description provided for @optionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get optionsAdd;

  /// No description provided for @optionsNone.
  ///
  /// In en, this message translates to:
  /// **'No options yet.'**
  String get optionsNone;

  /// No description provided for @optionsUnused.
  ///
  /// In en, this message translates to:
  /// **'Not on any product yet.'**
  String get optionsUnused;

  /// No description provided for @taxModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How tax works here'**
  String get taxModeTitle;

  /// No description provided for @taxModeOff.
  ///
  /// In en, this message translates to:
  /// **'No tax'**
  String get taxModeOff;

  /// No description provided for @taxModeInclusive.
  ///
  /// In en, this message translates to:
  /// **'Prices include tax'**
  String get taxModeInclusive;

  /// No description provided for @taxModeExclusive.
  ///
  /// In en, this message translates to:
  /// **'Add tax at the till'**
  String get taxModeExclusive;

  /// No description provided for @taxModeHelp.
  ///
  /// In en, this message translates to:
  /// **'Most shops in Ghana show prices with tax included. Only turn tax on if the shop is registered.'**
  String get taxModeHelp;

  /// No description provided for @taxRates.
  ///
  /// In en, this message translates to:
  /// **'Tax rates'**
  String get taxRates;

  /// No description provided for @taxNone.
  ///
  /// In en, this message translates to:
  /// **'No tax rates.'**
  String get taxNone;

  /// No description provided for @taxNew.
  ///
  /// In en, this message translates to:
  /// **'New tax rate'**
  String get taxNew;

  /// No description provided for @taxEdit.
  ///
  /// In en, this message translates to:
  /// **'Change tax rate'**
  String get taxEdit;

  /// No description provided for @taxName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get taxName;

  /// No description provided for @taxNameHelp.
  ///
  /// In en, this message translates to:
  /// **'As it should appear on receipts.'**
  String get taxNameHelp;

  /// No description provided for @taxRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get taxRate;

  /// No description provided for @taxRateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate like 15 or 2.5.'**
  String get taxRateInvalid;

  /// No description provided for @taxCompound.
  ///
  /// In en, this message translates to:
  /// **'Charged on top of the other taxes'**
  String get taxCompound;

  /// No description provided for @taxCompoundHelp.
  ///
  /// In en, this message translates to:
  /// **'VAT in Ghana is charged on the price plus NHIL and GETFund.'**
  String get taxCompoundHelp;

  /// No description provided for @taxApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Change tax settings.'**
  String get taxApprovalReason;

  /// No description provided for @taxAccountant.
  ///
  /// In en, this message translates to:
  /// **'Check the rates and which products they apply to with your accountant. Aby does not decide tax for you.'**
  String get taxAccountant;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Change product'**
  String get editorTitle;

  /// No description provided for @editorSaved.
  ///
  /// In en, this message translates to:
  /// **'Product saved.'**
  String get editorSaved;

  /// No description provided for @editorName.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get editorName;

  /// No description provided for @editorCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get editorCategory;

  /// No description provided for @editorTileLine.
  ///
  /// In en, this message translates to:
  /// **'Size line on the tile'**
  String get editorTileLine;

  /// No description provided for @editorTileLineHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional, for example \"500 ml\".'**
  String get editorTileLineHelp;

  /// No description provided for @editorDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get editorDescription;

  /// No description provided for @editorOnTill.
  ///
  /// In en, this message translates to:
  /// **'On the till'**
  String get editorOnTill;

  /// No description provided for @editorOnTillHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: kept, but cashiers cannot sell it.'**
  String get editorOnTillHelp;

  /// No description provided for @editorPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get editorPrices;

  /// No description provided for @editorPricesHelp.
  ///
  /// In en, this message translates to:
  /// **'One price, or several sizes or kinds, each with its own price and recipe.'**
  String get editorPricesHelp;

  /// No description provided for @editorAddSizes.
  ///
  /// In en, this message translates to:
  /// **'Add sizes or kinds'**
  String get editorAddSizes;

  /// No description provided for @editorAddVariant.
  ///
  /// In en, this message translates to:
  /// **'Add another'**
  String get editorAddVariant;

  /// No description provided for @editorVariantName.
  ///
  /// In en, this message translates to:
  /// **'Size or kind'**
  String get editorVariantName;

  /// No description provided for @editorVariantNameHelp.
  ///
  /// In en, this message translates to:
  /// **'For example Small, Double scoop, 500 ml.'**
  String get editorVariantNameHelp;

  /// No description provided for @editorPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get editorPrice;

  /// No description provided for @editorCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get editorCost;

  /// No description provided for @editorCostFromRecipe.
  ///
  /// In en, this message translates to:
  /// **'From the recipe'**
  String get editorCostFromRecipe;

  /// No description provided for @editorCostHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get editorCostHelp;

  /// No description provided for @editorMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get editorMoveUp;

  /// No description provided for @editorMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get editorMoveDown;

  /// No description provided for @editorRemoveVariant.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get editorRemoveVariant;

  /// No description provided for @editorBarcodes.
  ///
  /// In en, this message translates to:
  /// **'Barcodes and codes'**
  String get editorBarcodes;

  /// No description provided for @editorAddBarcode.
  ///
  /// In en, this message translates to:
  /// **'Add barcode'**
  String get editorAddBarcode;

  /// No description provided for @editorBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get editorBarcode;

  /// No description provided for @editorBarcodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Scan it, or type a short code (like 12) that rings this up when typed at the till.'**
  String get editorBarcodeHelp;

  /// No description provided for @editorOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get editorOptions;

  /// No description provided for @editorNoOptions.
  ///
  /// In en, this message translates to:
  /// **'No option groups yet. Add them on the Options tab.'**
  String get editorNoOptions;

  /// No description provided for @editorTaxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get editorTaxes;

  /// No description provided for @editorNoTaxes.
  ///
  /// In en, this message translates to:
  /// **'No tax rates. Set them up on the Tax tab.'**
  String get editorNoTaxes;

  /// No description provided for @editorTaxesHelp.
  ///
  /// In en, this message translates to:
  /// **'Only used when tax is on (Products, Tax).'**
  String get editorTaxesHelp;

  /// No description provided for @editorPriceMissing.
  ///
  /// In en, this message translates to:
  /// **'Enter a price for each size or kind.'**
  String get editorPriceMissing;

  /// No description provided for @editorCostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the cost.'**
  String get editorCostInvalid;

  /// No description provided for @editorRecipeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the recipe amounts.'**
  String get editorRecipeInvalid;

  /// No description provided for @editorCategoryMissing.
  ///
  /// In en, this message translates to:
  /// **'Pick a category.'**
  String get editorCategoryMissing;

  /// No description provided for @editorPriceReason.
  ///
  /// In en, this message translates to:
  /// **'Change prices.'**
  String get editorPriceReason;

  /// No description provided for @recipeUses.
  ///
  /// In en, this message translates to:
  /// **'What it uses'**
  String get recipeUses;

  /// No description provided for @recipeHelp.
  ///
  /// In en, this message translates to:
  /// **'Each sale takes these from stock and works out the cost.'**
  String get recipeHelp;

  /// No description provided for @recipeItem.
  ///
  /// In en, this message translates to:
  /// **'Stock item'**
  String get recipeItem;

  /// No description provided for @recipeAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recipeAmount;

  /// No description provided for @recipeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get recipeRemove;

  /// No description provided for @recipeAdd.
  ///
  /// In en, this message translates to:
  /// **'Add stock item'**
  String get recipeAdd;

  /// No description provided for @recipeNoStockItems.
  ///
  /// In en, this message translates to:
  /// **'Add stock items first (Stock)'**
  String get recipeNoStockItems;

  /// No description provided for @stockNew.
  ///
  /// In en, this message translates to:
  /// **'New stock item'**
  String get stockNew;

  /// No description provided for @stockEdit.
  ///
  /// In en, this message translates to:
  /// **'Change stock item'**
  String get stockEdit;

  /// No description provided for @stockSearch.
  ///
  /// In en, this message translates to:
  /// **'Search stock'**
  String get stockSearch;

  /// No description provided for @stockFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get stockFilterAll;

  /// No description provided for @stockFilterRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get stockFilterRetired;

  /// No description provided for @stockNone.
  ///
  /// In en, this message translates to:
  /// **'No stock items here.'**
  String get stockNone;

  /// No description provided for @stockLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get stockLow;

  /// No description provided for @stockName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get stockName;

  /// No description provided for @stockNameHelp.
  ///
  /// In en, this message translates to:
  /// **'What you buy, for example Wafer cones or Vanilla ice cream.'**
  String get stockNameHelp;

  /// No description provided for @stockUnit.
  ///
  /// In en, this message translates to:
  /// **'Counted in'**
  String get stockUnit;

  /// No description provided for @unitPieces.
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get unitPieces;

  /// No description provided for @unitWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (g, kg)'**
  String get unitWeight;

  /// No description provided for @unitVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume (ml, L)'**
  String get unitVolume;

  /// No description provided for @stockCostHelp.
  ///
  /// In en, this message translates to:
  /// **'Deliveries update this to the average cost.'**
  String get stockCostHelp;

  /// No description provided for @stockReorderAt.
  ///
  /// In en, this message translates to:
  /// **'Low below'**
  String get stockReorderAt;

  /// No description provided for @stockReorderQty.
  ///
  /// In en, this message translates to:
  /// **'Usually order'**
  String get stockReorderQty;

  /// No description provided for @stockReorderHelp.
  ///
  /// In en, this message translates to:
  /// **'Both optional.'**
  String get stockReorderHelp;

  /// No description provided for @stockCostInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the cost.'**
  String get stockCostInvalid;

  /// No description provided for @stockQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the amount.'**
  String get stockQuantityInvalid;

  /// No description provided for @stockEditReason.
  ///
  /// In en, this message translates to:
  /// **'Change stock items.'**
  String get stockEditReason;

  /// No description provided for @stockOnHand.
  ///
  /// In en, this message translates to:
  /// **'On hand'**
  String get stockOnHand;

  /// No description provided for @stockHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get stockHistory;

  /// No description provided for @stockNoMovements.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get stockNoMovements;

  /// No description provided for @stockLogWaste.
  ///
  /// In en, this message translates to:
  /// **'Log waste'**
  String get stockLogWaste;

  /// No description provided for @stockAdjust.
  ///
  /// In en, this message translates to:
  /// **'Correct stock'**
  String get stockAdjust;

  /// No description provided for @stockRetire.
  ///
  /// In en, this message translates to:
  /// **'Retire'**
  String get stockRetire;

  /// No description provided for @stockRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get stockRestore;

  /// No description provided for @stockUsedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by'**
  String get stockUsedBy;

  /// No description provided for @stockUsedByNone.
  ///
  /// In en, this message translates to:
  /// **'No product uses it yet.'**
  String get stockUsedByNone;

  /// No description provided for @stockLess.
  ///
  /// In en, this message translates to:
  /// **'There is less'**
  String get stockLess;

  /// No description provided for @stockMore.
  ///
  /// In en, this message translates to:
  /// **'There is more'**
  String get stockMore;

  /// No description provided for @stockQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get stockQuantity;

  /// No description provided for @stockNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get stockNoteOptional;

  /// No description provided for @stockWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get stockWhy;

  /// No description provided for @stockAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Stock corrected.'**
  String get stockAdjusted;

  /// No description provided for @stockWasted.
  ///
  /// In en, this message translates to:
  /// **'Waste logged.'**
  String get stockWasted;

  /// No description provided for @moveSale.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get moveSale;

  /// No description provided for @moveReceived.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get moveReceived;

  /// No description provided for @moveAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get moveAdjustment;

  /// No description provided for @moveCount.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get moveCount;

  /// No description provided for @wasteMelted.
  ///
  /// In en, this message translates to:
  /// **'Melted'**
  String get wasteMelted;

  /// No description provided for @wastePowerCut.
  ///
  /// In en, this message translates to:
  /// **'Power cut'**
  String get wastePowerCut;

  /// No description provided for @wasteExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get wasteExpired;

  /// No description provided for @wasteDamaged.
  ///
  /// In en, this message translates to:
  /// **'Dropped or damaged'**
  String get wasteDamaged;

  /// No description provided for @wasteStaffMeal.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get wasteStaffMeal;

  /// No description provided for @wasteSample.
  ///
  /// In en, this message translates to:
  /// **'Free sample'**
  String get wasteSample;

  /// No description provided for @wasteOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get wasteOther;

  /// No description provided for @stockItemsTab.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get stockItemsTab;

  /// No description provided for @deliveriesTab.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get deliveriesTab;

  /// No description provided for @countsTab.
  ///
  /// In en, this message translates to:
  /// **'Counts'**
  String get countsTab;

  /// No description provided for @suppliersTab.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliersTab;

  /// No description provided for @exportButton.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportButton;

  /// No description provided for @exportWhere.
  ///
  /// In en, this message translates to:
  /// **'Where should the file go?'**
  String get exportWhere;

  /// No description provided for @exportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {what}'**
  String exportTitle(String what);

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Excel workbook'**
  String get exportExcel;

  /// No description provided for @exportExcelHelp.
  ///
  /// In en, this message translates to:
  /// **'In Aby colours, with totals and filters. Opens in Excel, Google Sheets and Numbers.'**
  String get exportExcelHelp;

  /// No description provided for @exportPdfHelp.
  ///
  /// In en, this message translates to:
  /// **'Ready to print, or to send on WhatsApp or by email.'**
  String get exportPdfHelp;

  /// No description provided for @exportCsvHelp.
  ///
  /// In en, this message translates to:
  /// **'Plain data for other software.'**
  String get exportCsvHelp;

  /// No description provided for @exportCsvImportHelp.
  ///
  /// In en, this message translates to:
  /// **'Plain data. Edit it and import it back into Aby.'**
  String get exportCsvImportHelp;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get exportShare;

  /// No description provided for @exportSave.
  ///
  /// In en, this message translates to:
  /// **'Save to a folder'**
  String get exportSave;

  /// No description provided for @exportMaking.
  ///
  /// In en, this message translates to:
  /// **'Making the file...'**
  String get exportMaking;

  /// No description provided for @printHow.
  ///
  /// In en, this message translates to:
  /// **'Print or share?'**
  String get printHow;

  /// No description provided for @printOnPrinter.
  ///
  /// In en, this message translates to:
  /// **'On the receipt printer'**
  String get printOnPrinter;

  /// No description provided for @printAsPdf.
  ///
  /// In en, this message translates to:
  /// **'As a PDF (share or save)'**
  String get printAsPdf;

  /// No description provided for @printNoPrinterPdf.
  ///
  /// In en, this message translates to:
  /// **'No receipt printer here. Share or save it as a PDF instead:'**
  String get printNoPrinterPdf;

  /// No description provided for @reportExportAll.
  ///
  /// In en, this message translates to:
  /// **'Export the report'**
  String get reportExportAll;

  /// No description provided for @importPick.
  ///
  /// In en, this message translates to:
  /// **'Pick the CSV file'**
  String get importPick;

  /// No description provided for @productsTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get productsTools;

  /// No description provided for @receiveNew.
  ///
  /// In en, this message translates to:
  /// **'Receive delivery'**
  String get receiveNew;

  /// No description provided for @receiveSave.
  ///
  /// In en, this message translates to:
  /// **'Save delivery'**
  String get receiveSave;

  /// No description provided for @receiveSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get receiveSupplier;

  /// No description provided for @receiveNoSupplier.
  ///
  /// In en, this message translates to:
  /// **'No supplier (paid in full)'**
  String get receiveNoSupplier;

  /// No description provided for @receiveInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice or receipt number'**
  String get receiveInvoice;

  /// No description provided for @receiveWhatCame.
  ///
  /// In en, this message translates to:
  /// **'What came'**
  String get receiveWhatCame;

  /// No description provided for @receiveAddLow.
  ///
  /// In en, this message translates to:
  /// **'Add everything low'**
  String get receiveAddLow;

  /// No description provided for @receiveAddLine.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get receiveAddLine;

  /// No description provided for @receiveLineCost.
  ///
  /// In en, this message translates to:
  /// **'Cost of this line'**
  String get receiveLineCost;

  /// No description provided for @receiveTotal.
  ///
  /// In en, this message translates to:
  /// **'Delivery total'**
  String get receiveTotal;

  /// No description provided for @receivePaidNow.
  ///
  /// In en, this message translates to:
  /// **'Paid now'**
  String get receivePaidNow;

  /// No description provided for @receivePaidNowHelp.
  ///
  /// In en, this message translates to:
  /// **'The rest is added to what you owe this supplier.'**
  String get receivePaidNowHelp;

  /// No description provided for @receivePaidNowNoSupplier.
  ///
  /// In en, this message translates to:
  /// **'Without a supplier the delivery must be paid in full.'**
  String get receivePaidNowNoSupplier;

  /// No description provided for @receivePaidInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the amount paid.'**
  String get receivePaidInvalid;

  /// No description provided for @receiveReason.
  ///
  /// In en, this message translates to:
  /// **'Receive a delivery.'**
  String get receiveReason;

  /// No description provided for @payCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payCash;

  /// No description provided for @payMomo.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get payMomo;

  /// No description provided for @payBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get payBank;

  /// No description provided for @payOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get payOther;

  /// No description provided for @deliveriesNone.
  ///
  /// In en, this message translates to:
  /// **'No deliveries yet.'**
  String get deliveriesNone;

  /// No description provided for @countStart.
  ///
  /// In en, this message translates to:
  /// **'Start a count'**
  String get countStart;

  /// No description provided for @countContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue the count'**
  String get countContinue;

  /// No description provided for @countBlind.
  ///
  /// In en, this message translates to:
  /// **'Blind: counters do not see what the till expects'**
  String get countBlind;

  /// No description provided for @countOpen.
  ///
  /// In en, this message translates to:
  /// **'Open: show what the till expects'**
  String get countOpen;

  /// No description provided for @countStartReason.
  ///
  /// In en, this message translates to:
  /// **'Start a stock count.'**
  String get countStartReason;

  /// No description provided for @countTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock count'**
  String get countTitle;

  /// No description provided for @countsNone.
  ///
  /// In en, this message translates to:
  /// **'No counts yet.'**
  String get countsNone;

  /// No description provided for @countOpenStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get countOpenStatus;

  /// No description provided for @countCancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get countCancelledStatus;

  /// No description provided for @countBlindShort.
  ///
  /// In en, this message translates to:
  /// **'Blind'**
  String get countBlindShort;

  /// No description provided for @countCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel count'**
  String get countCancel;

  /// No description provided for @countCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this count?'**
  String get countCancelTitle;

  /// No description provided for @countCancelBody.
  ///
  /// In en, this message translates to:
  /// **'What was counted is kept for the record, but stock does not change.'**
  String get countCancelBody;

  /// No description provided for @countPost.
  ///
  /// In en, this message translates to:
  /// **'Post count'**
  String get countPost;

  /// No description provided for @countPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Post the count?'**
  String get countPostTitle;

  /// No description provided for @countPostReason.
  ///
  /// In en, this message translates to:
  /// **'Post a stock count.'**
  String get countPostReason;

  /// No description provided for @countPostedSame.
  ///
  /// In en, this message translates to:
  /// **'Count posted. Everything matched.'**
  String get countPostedSame;

  /// No description provided for @countNoDifference.
  ///
  /// In en, this message translates to:
  /// **'No differences so far'**
  String get countNoDifference;

  /// No description provided for @countFound.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get countFound;

  /// No description provided for @suppliersNone.
  ///
  /// In en, this message translates to:
  /// **'No suppliers yet.'**
  String get suppliersNone;

  /// No description provided for @supplierNew.
  ///
  /// In en, this message translates to:
  /// **'New supplier'**
  String get supplierNew;

  /// No description provided for @supplierEdit.
  ///
  /// In en, this message translates to:
  /// **'Change supplier'**
  String get supplierEdit;

  /// No description provided for @supplierName.
  ///
  /// In en, this message translates to:
  /// **'Supplier name'**
  String get supplierName;

  /// No description provided for @supplierTerms.
  ///
  /// In en, this message translates to:
  /// **'Days to pay'**
  String get supplierTerms;

  /// No description provided for @supplierTermsHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if you pay on delivery.'**
  String get supplierTermsHelp;

  /// No description provided for @supplierDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get supplierDays;

  /// No description provided for @supplierSettled.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed'**
  String get supplierSettled;

  /// No description provided for @supplierEditReason.
  ///
  /// In en, this message translates to:
  /// **'Change suppliers.'**
  String get supplierEditReason;

  /// No description provided for @supplierBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get supplierBalance;

  /// No description provided for @supplierPay.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get supplierPay;

  /// No description provided for @supplierAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount paid'**
  String get supplierAmount;

  /// No description provided for @supplierReference.
  ///
  /// In en, this message translates to:
  /// **'Reference (optional)'**
  String get supplierReference;

  /// No description provided for @supplierLedger.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supplierLedger;

  /// No description provided for @supplierEntryPurchase.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get supplierEntryPurchase;

  /// No description provided for @stockUsage.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get stockUsage;

  /// No description provided for @stockUsePerDay.
  ///
  /// In en, this message translates to:
  /// **'Uses about, per day'**
  String get stockUsePerDay;

  /// No description provided for @stockNotUsed.
  ///
  /// In en, this message translates to:
  /// **'Not used in the last 4 weeks'**
  String get stockNotUsed;

  /// No description provided for @stockLasts.
  ///
  /// In en, this message translates to:
  /// **'Lasts about'**
  String get stockLasts;

  /// No description provided for @stockSuggestedLow.
  ///
  /// In en, this message translates to:
  /// **'Suggested low level'**
  String get stockSuggestedLow;

  /// No description provided for @stockSuggestedHelp.
  ///
  /// In en, this message translates to:
  /// **'Three days of use, plus half again.'**
  String get stockSuggestedHelp;

  /// No description provided for @stockUseThis.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get stockUseThis;

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Change prices in bulk'**
  String get bulkTitle;

  /// No description provided for @bulkRaise.
  ///
  /// In en, this message translates to:
  /// **'Raise'**
  String get bulkRaise;

  /// No description provided for @bulkLower.
  ///
  /// In en, this message translates to:
  /// **'Lower'**
  String get bulkLower;

  /// No description provided for @bulkNoRounding.
  ///
  /// In en, this message translates to:
  /// **'No rounding'**
  String get bulkNoRounding;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import products'**
  String get importTitle;

  /// No description provided for @importApply.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importApply;

  /// No description provided for @editorSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule a new price'**
  String get editorSchedule;

  /// No description provided for @editorScheduleWhen.
  ///
  /// In en, this message translates to:
  /// **'From which day?'**
  String get editorScheduleWhen;

  /// No description provided for @auditCartCleared.
  ///
  /// In en, this message translates to:
  /// **'Cart cleared'**
  String get auditCartCleared;

  /// No description provided for @auditCartLinesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Taken off a cart'**
  String get auditCartLinesRemoved;

  /// No description provided for @auditDiscountSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved discount changed'**
  String get auditDiscountSaved;

  /// No description provided for @auditDiscountsGiven.
  ///
  /// In en, this message translates to:
  /// **'Discounts given'**
  String get auditDiscountsGiven;

  /// No description provided for @auditOrderParked.
  ///
  /// In en, this message translates to:
  /// **'Order parked'**
  String get auditOrderParked;

  /// No description provided for @auditParkedOrderDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Parked order discarded'**
  String get auditParkedOrderDiscarded;

  /// No description provided for @auditPriceOverridden.
  ///
  /// In en, this message translates to:
  /// **'Price overridden'**
  String get auditPriceOverridden;

  /// No description provided for @auditReasonSaved.
  ///
  /// In en, this message translates to:
  /// **'Reasons list changed'**
  String get auditReasonSaved;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Current sale'**
  String get cartTitle;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tap a product, scan a barcode, or type to search.'**
  String get cartEmpty;

  /// No description provided for @cartClear.
  ///
  /// In en, this message translates to:
  /// **'Clear the cart'**
  String get cartClear;

  /// No description provided for @cartClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the cart?'**
  String get cartClearTitle;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Before discounts'**
  String get cartSubtotal;

  /// No description provided for @cartDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get cartDiscount;

  /// No description provided for @cartOneLess.
  ///
  /// In en, this message translates to:
  /// **'One less'**
  String get cartOneLess;

  /// No description provided for @cartOneMore.
  ///
  /// In en, this message translates to:
  /// **'One more'**
  String get cartOneMore;

  /// No description provided for @cartOrderDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount on the whole sale'**
  String get cartOrderDiscount;

  /// No description provided for @cartWholeOrder.
  ///
  /// In en, this message translates to:
  /// **'the whole sale'**
  String get cartWholeOrder;

  /// No description provided for @cartAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get cartAddNote;

  /// No description provided for @cartEditNote.
  ///
  /// In en, this message translates to:
  /// **'Change the note'**
  String get cartEditNote;

  /// No description provided for @cartNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Note for this sale'**
  String get cartNoteTitle;

  /// No description provided for @cartNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get cartNote;

  /// No description provided for @cartNoteHelp.
  ///
  /// In en, this message translates to:
  /// **'Printed on the order ticket, e.g. \"Collect at 3 pm\".'**
  String get cartNoteHelp;

  /// No description provided for @orderTakeaway.
  ///
  /// In en, this message translates to:
  /// **'Takeaway'**
  String get orderTakeaway;

  /// No description provided for @orderEatIn.
  ///
  /// In en, this message translates to:
  /// **'Eat in'**
  String get orderEatIn;

  /// No description provided for @orderDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get orderDelivery;

  /// No description provided for @parkButton.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get parkButton;

  /// No description provided for @parkTitle.
  ///
  /// In en, this message translates to:
  /// **'Park this sale'**
  String get parkTitle;

  /// No description provided for @parkName.
  ///
  /// In en, this message translates to:
  /// **'Name or table'**
  String get parkName;

  /// No description provided for @parkNameHelp.
  ///
  /// In en, this message translates to:
  /// **'So you can find it again: \"Blue shirt\", \"Table 4\".'**
  String get parkNameHelp;

  /// No description provided for @parkGone.
  ///
  /// In en, this message translates to:
  /// **'Another till already opened that order.'**
  String get parkGone;

  /// No description provided for @parkRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get parkRename;

  /// No description provided for @parkMerge.
  ///
  /// In en, this message translates to:
  /// **'Add to this sale'**
  String get parkMerge;

  /// No description provided for @parkDiscard.
  ///
  /// In en, this message translates to:
  /// **'Throw away'**
  String get parkDiscard;

  /// No description provided for @parkDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'The order is removed without a sale. This is recorded in Activity.'**
  String get parkDiscardBody;

  /// No description provided for @discountSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved discounts'**
  String get discountSaved;

  /// No description provided for @discountPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get discountPercent;

  /// No description provided for @discountAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount off'**
  String get discountAmount;

  /// No description provided for @discountReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get discountReason;

  /// No description provided for @discountOff.
  ///
  /// In en, this message translates to:
  /// **'Comes off'**
  String get discountOff;

  /// No description provided for @discountRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove discount'**
  String get discountRemove;

  /// No description provided for @discountApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get discountApply;

  /// No description provided for @discountPickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason.'**
  String get discountPickReason;

  /// No description provided for @discountPercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a percentage from 1 to 100.'**
  String get discountPercentInvalid;

  /// No description provided for @discountAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount off.'**
  String get discountAmountInvalid;

  /// No description provided for @discountNew.
  ///
  /// In en, this message translates to:
  /// **'New discount'**
  String get discountNew;

  /// No description provided for @discountEdit.
  ///
  /// In en, this message translates to:
  /// **'Change discount'**
  String get discountEdit;

  /// No description provided for @discountName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get discountName;

  /// No description provided for @discountNameHelp.
  ///
  /// In en, this message translates to:
  /// **'As the cashier will see it: \"Student 10%\".'**
  String get discountNameHelp;

  /// No description provided for @discountScope.
  ///
  /// In en, this message translates to:
  /// **'Use it on'**
  String get discountScope;

  /// No description provided for @discountScopeLine.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get discountScopeLine;

  /// No description provided for @discountScopeOrder.
  ///
  /// In en, this message translates to:
  /// **'Whole sale'**
  String get discountScopeOrder;

  /// No description provided for @discountScopeAny.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get discountScopeAny;

  /// No description provided for @discountsNone.
  ///
  /// In en, this message translates to:
  /// **'No saved discounts yet.'**
  String get discountsNone;

  /// No description provided for @editorSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get editorSelling;

  /// No description provided for @editorQuickTab.
  ///
  /// In en, this message translates to:
  /// **'On the Quick tab'**
  String get editorQuickTab;

  /// No description provided for @editorQuickTabHelp.
  ///
  /// In en, this message translates to:
  /// **'The first tab on the till, for the things you sell most.'**
  String get editorQuickTabHelp;

  /// No description provided for @editorSellBy.
  ///
  /// In en, this message translates to:
  /// **'Sold by'**
  String get editorSellBy;

  /// No description provided for @editorSellByEachHelp.
  ///
  /// In en, this message translates to:
  /// **'Counted: 1, 2, 3...'**
  String get editorSellByEachHelp;

  /// No description provided for @editorSellByWeightHelp.
  ///
  /// In en, this message translates to:
  /// **'The price is per kg or litre and the till asks how much. Recipes are per kg or litre too.'**
  String get editorSellByWeightHelp;

  /// No description provided for @editorOpenPrice.
  ///
  /// In en, this message translates to:
  /// **'Price typed at the till'**
  String get editorOpenPrice;

  /// No description provided for @editorOpenPriceHelp.
  ///
  /// In en, this message translates to:
  /// **'For \"Miscellaneous\", repairs and the like. The price above is the suggestion.'**
  String get editorOpenPriceHelp;

  /// No description provided for @editorMinPrice.
  ///
  /// In en, this message translates to:
  /// **'Lowest price (optional)'**
  String get editorMinPrice;

  /// No description provided for @editorMaxPrice.
  ///
  /// In en, this message translates to:
  /// **'Highest price (optional)'**
  String get editorMaxPrice;

  /// No description provided for @editorLimitsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the lowest and highest prices.'**
  String get editorLimitsInvalid;

  /// No description provided for @sellByEach.
  ///
  /// In en, this message translates to:
  /// **'Each'**
  String get sellByEach;

  /// No description provided for @sellByKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get sellByKg;

  /// No description provided for @sellByLitre.
  ///
  /// In en, this message translates to:
  /// **'Volume (litre)'**
  String get sellByLitre;

  /// No description provided for @entryAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get entryAdd;

  /// No description provided for @entryPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get entryPrice;

  /// No description provided for @entryWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get entryWeight;

  /// No description provided for @entryVolume.
  ///
  /// In en, this message translates to:
  /// **'How much'**
  String get entryVolume;

  /// No description provided for @lineQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get lineQuantity;

  /// No description provided for @lineQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a quantity of at least 1.'**
  String get lineQuantityInvalid;

  /// No description provided for @linePrice.
  ///
  /// In en, this message translates to:
  /// **'Price for one'**
  String get linePrice;

  /// No description provided for @linePriceHelp.
  ///
  /// In en, this message translates to:
  /// **'A changed price is recorded under your name.'**
  String get linePriceHelp;

  /// No description provided for @lineNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get lineNote;

  /// No description provided for @lineNoteHelp.
  ///
  /// In en, this message translates to:
  /// **'For the kitchen or the order ticket, e.g. \"no nuts\".'**
  String get lineNoteHelp;

  /// No description provided for @lineAddDiscount.
  ///
  /// In en, this message translates to:
  /// **'Add a discount'**
  String get lineAddDiscount;

  /// No description provided for @lineDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get lineDiscount;

  /// No description provided for @lineChangePick.
  ///
  /// In en, this message translates to:
  /// **'Change size or options'**
  String get lineChangePick;

  /// No description provided for @lineRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get lineRemove;

  /// No description provided for @overrideRefused.
  ///
  /// In en, this message translates to:
  /// **'The price was not changed.'**
  String get overrideRefused;

  /// No description provided for @quickArrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange the Quick tab'**
  String get quickArrange;

  /// No description provided for @quickArrangeHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Add products from the list below.'**
  String get quickArrangeHelp;

  /// No description provided for @quickRemove.
  ///
  /// In en, this message translates to:
  /// **'Take off the Quick tab'**
  String get quickRemove;

  /// No description provided for @quickAddHint.
  ///
  /// In en, this message translates to:
  /// **'Find a product to add'**
  String get quickAddHint;

  /// No description provided for @quickArrangeReason.
  ///
  /// In en, this message translates to:
  /// **'Change the Quick tab.'**
  String get quickArrangeReason;

  /// No description provided for @reasonsDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount reasons'**
  String get reasonsDiscount;

  /// No description provided for @reasonsVoid.
  ///
  /// In en, this message translates to:
  /// **'Void reasons'**
  String get reasonsVoid;

  /// No description provided for @reasonsRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund reasons'**
  String get reasonsRefund;

  /// No description provided for @reasonsNoSale.
  ///
  /// In en, this message translates to:
  /// **'No-sale reasons'**
  String get reasonsNoSale;

  /// No description provided for @reasonNew.
  ///
  /// In en, this message translates to:
  /// **'New reason'**
  String get reasonNew;

  /// No description provided for @reasonEdit.
  ///
  /// In en, this message translates to:
  /// **'Change reason'**
  String get reasonEdit;

  /// No description provided for @reasonName.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonName;

  /// No description provided for @settingsGroupSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get settingsGroupSelling;

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// No description provided for @settingsOrderTypes.
  ///
  /// In en, this message translates to:
  /// **'Takeaway, eat in or delivery'**
  String get settingsOrderTypes;

  /// No description provided for @settingsOrderTypesHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask on each sale; shown on the order ticket.'**
  String get settingsOrderTypesHelp;

  /// No description provided for @settingsNegativeStock.
  ///
  /// In en, this message translates to:
  /// **'Sell when out of stock'**
  String get settingsNegativeStock;

  /// No description provided for @settingsNegativeStockHelp.
  ///
  /// In en, this message translates to:
  /// **'The till warns but still sells. Off: it refuses.'**
  String get settingsNegativeStockHelp;

  /// No description provided for @settingsDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Saved discounts'**
  String get settingsDiscounts;

  /// No description provided for @settingsDiscountsHelp.
  ///
  /// In en, this message translates to:
  /// **'Named discounts cashiers can pick: \"Student 10%\", \"Staff meal GH₵ 5 off\".'**
  String get settingsDiscountsHelp;

  /// No description provided for @settingsScalePrefix.
  ///
  /// In en, this message translates to:
  /// **'Scale barcodes'**
  String get settingsScalePrefix;

  /// No description provided for @settingsScalePrefixHelp.
  ///
  /// In en, this message translates to:
  /// **'The first digits your scale prints (often 2 or 21). Leave empty if you have no scale.'**
  String get settingsScalePrefixHelp;

  /// No description provided for @settingsScaleValue.
  ///
  /// In en, this message translates to:
  /// **'The scale barcode holds'**
  String get settingsScaleValue;

  /// No description provided for @settingsScaleWeight.
  ///
  /// In en, this message translates to:
  /// **'The weight'**
  String get settingsScaleWeight;

  /// No description provided for @settingsScalePrice.
  ///
  /// In en, this message translates to:
  /// **'The price'**
  String get settingsScalePrice;

  /// No description provided for @settingsParkedWarn.
  ///
  /// In en, this message translates to:
  /// **'Warn about parked orders after'**
  String get settingsParkedWarn;

  /// No description provided for @settingsParkedWarnHelp.
  ///
  /// In en, this message translates to:
  /// **'Close day shows parked orders older than this.'**
  String get settingsParkedWarnHelp;

  /// No description provided for @settingsTiles.
  ///
  /// In en, this message translates to:
  /// **'Till tile size'**
  String get settingsTiles;

  /// No description provided for @settingsTilesSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get settingsTilesSmall;

  /// No description provided for @settingsTilesMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsTilesMedium;

  /// No description provided for @settingsTilesLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get settingsTilesLarge;

  /// No description provided for @tileOpenPrice.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get tileOpenPrice;

  /// No description provided for @tillQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick'**
  String get tillQuick;

  /// No description provided for @tillAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tillAll;

  /// No description provided for @tillRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tillRecent;

  /// No description provided for @tillSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search, scan, or type a code'**
  String get tillSearchHint;

  /// No description provided for @tillNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Check the spelling, or press Enter to look it up as a code.'**
  String get tillNoMatch;

  /// No description provided for @tillNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get tillNothingHere;

  /// No description provided for @tillQuickEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the Quick tab yet.'**
  String get tillQuickEmpty;

  /// No description provided for @tillCodeUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'Add a new product with this barcode?'**
  String get tillCodeUnknownBody;

  /// No description provided for @tillCodeCreate.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get tillCodeCreate;

  /// No description provided for @tillPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the price.'**
  String get tillPriceInvalid;

  /// No description provided for @tillWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter how much.'**
  String get tillWeightInvalid;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get commonEdit;

  /// No description provided for @auditNoSale.
  ///
  /// In en, this message translates to:
  /// **'Drawer opened (no sale)'**
  String get auditNoSale;

  /// No description provided for @auditPayMethodSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment method changed'**
  String get auditPayMethodSaved;

  /// No description provided for @auditRefundGiven.
  ///
  /// In en, this message translates to:
  /// **'Refund given'**
  String get auditRefundGiven;

  /// No description provided for @moveReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned (refund)'**
  String get moveReturned;

  /// No description provided for @cartExchangeCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel the exchange'**
  String get cartExchangeCancel;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get checkoutTitle;

  /// No description provided for @checkoutBack.
  ///
  /// In en, this message translates to:
  /// **'Back to the till'**
  String get checkoutBack;

  /// No description provided for @checkoutComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete sale'**
  String get checkoutComplete;

  /// No description provided for @checkoutReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned items'**
  String get checkoutReturned;

  /// No description provided for @checkoutLeftToPay.
  ///
  /// In en, this message translates to:
  /// **'Left to pay'**
  String get checkoutLeftToPay;

  /// No description provided for @checkoutRemovePayment.
  ///
  /// In en, this message translates to:
  /// **'Remove this payment'**
  String get checkoutRemovePayment;

  /// No description provided for @checkoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get checkoutAmount;

  /// No description provided for @checkoutAmountHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave as it is to pay the rest this way.'**
  String get checkoutAmountHelp;

  /// No description provided for @checkoutReferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Required, from the payment message. Each one can only be used once.'**
  String get checkoutReferenceHelp;

  /// No description provided for @checkoutReferenceShort.
  ///
  /// In en, this message translates to:
  /// **'The last 4 characters are enough. Each one can only be used once.'**
  String get checkoutReferenceShort;

  /// No description provided for @checkoutCashGiven.
  ///
  /// In en, this message translates to:
  /// **'Cash given'**
  String get checkoutCashGiven;

  /// No description provided for @checkoutExact.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get checkoutExact;

  /// No description provided for @checkoutStillToPay.
  ///
  /// In en, this message translates to:
  /// **'Still to pay'**
  String get checkoutStillToPay;

  /// No description provided for @checkoutChange.
  ///
  /// In en, this message translates to:
  /// **'Change due'**
  String get checkoutChange;

  /// No description provided for @checkoutDone.
  ///
  /// In en, this message translates to:
  /// **'Sale complete'**
  String get checkoutDone;

  /// No description provided for @checkoutNewSale.
  ///
  /// In en, this message translates to:
  /// **'New sale'**
  String get checkoutNewSale;

  /// No description provided for @checkoutSavedHere.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. Will sync when you\'re online.'**
  String get checkoutSavedHere;

  /// No description provided for @checkoutGiveBackNow.
  ///
  /// In en, this message translates to:
  /// **'Give back'**
  String get checkoutGiveBackNow;

  /// No description provided for @checkoutSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the sale. Try again.'**
  String get checkoutSaveFailed;

  /// No description provided for @exchangeAlready.
  ///
  /// In en, this message translates to:
  /// **'An exchange is already waiting on the till. Finish or cancel it first.'**
  String get exchangeAlready;

  /// No description provided for @noSaleButton.
  ///
  /// In en, this message translates to:
  /// **'Open the drawer (no sale)'**
  String get noSaleButton;

  /// No description provided for @noSaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Why open the drawer?'**
  String get noSaleTitle;

  /// No description provided for @noSaleApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Open the drawer without a sale.'**
  String get noSaleApprovalReason;

  /// No description provided for @noSaleDone.
  ///
  /// In en, this message translates to:
  /// **'Drawer opened. This is recorded.'**
  String get noSaleDone;

  /// No description provided for @payKindCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get payKindCash;

  /// No description provided for @payKindMomo.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get payKindMomo;

  /// No description provided for @payKindCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit (book)'**
  String get payKindCredit;

  /// No description provided for @payKindCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get payKindCard;

  /// No description provided for @payKindBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get payKindBank;

  /// No description provided for @payKindCheque.
  ///
  /// In en, this message translates to:
  /// **'Cheque'**
  String get payKindCheque;

  /// No description provided for @payKindExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange'**
  String get payKindExchange;

  /// No description provided for @payKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get payKindOther;

  /// No description provided for @payMethodNew.
  ///
  /// In en, this message translates to:
  /// **'New payment method'**
  String get payMethodNew;

  /// No description provided for @payMethodEdit.
  ///
  /// In en, this message translates to:
  /// **'Change payment method'**
  String get payMethodEdit;

  /// No description provided for @payMethodName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get payMethodName;

  /// No description provided for @payMethodKind.
  ///
  /// In en, this message translates to:
  /// **'Kind of payment'**
  String get payMethodKind;

  /// No description provided for @payMerchantNumber.
  ///
  /// In en, this message translates to:
  /// **'Your number or merchant ID (optional)'**
  String get payMerchantNumber;

  /// No description provided for @payMerchantNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown large, with a QR code, for the customer to pay to.'**
  String get payMerchantNumberHelp;

  /// No description provided for @payNeedsReference.
  ///
  /// In en, this message translates to:
  /// **'Needs a transaction ID'**
  String get payNeedsReference;

  /// No description provided for @payNeedsReferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'The cashier types it from the payment message; it cannot be used twice.'**
  String get payNeedsReferenceHelp;

  /// No description provided for @payShortReference.
  ///
  /// In en, this message translates to:
  /// **'The last 4 characters are enough'**
  String get payShortReference;

  /// No description provided for @payShortReferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Faster, but only checked for reuse over two days.'**
  String get payShortReferenceHelp;

  /// No description provided for @refundNoReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund without a receipt'**
  String get refundNoReceiptTitle;

  /// No description provided for @refundVoided.
  ///
  /// In en, this message translates to:
  /// **'This sale was voided: there is nothing to refund.'**
  String get refundVoided;

  /// No description provided for @refundNothingLeft.
  ///
  /// In en, this message translates to:
  /// **'Everything on this sale has been refunded.'**
  String get refundNothingLeft;

  /// No description provided for @refundWhatComesBack.
  ///
  /// In en, this message translates to:
  /// **'What comes back'**
  String get refundWhatComesBack;

  /// No description provided for @refundEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get refundEverything;

  /// No description provided for @refundRestock.
  ///
  /// In en, this message translates to:
  /// **'Back into stock'**
  String get refundRestock;

  /// No description provided for @refundRestockHelp.
  ///
  /// In en, this message translates to:
  /// **'It can be sold again.'**
  String get refundRestockHelp;

  /// No description provided for @refundDamagedHelp.
  ///
  /// In en, this message translates to:
  /// **'Damaged: it does not go back into stock.'**
  String get refundDamagedHelp;

  /// No description provided for @refundReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get refundReason;

  /// No description provided for @refundHow.
  ///
  /// In en, this message translates to:
  /// **'Give the money back by'**
  String get refundHow;

  /// No description provided for @refundReference.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID (optional)'**
  String get refundReference;

  /// No description provided for @refundReferenceHelp.
  ///
  /// In en, this message translates to:
  /// **'Of the money sent back, for the record.'**
  String get refundReferenceHelp;

  /// No description provided for @refundTotal.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refundTotal;

  /// No description provided for @refundExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange instead'**
  String get refundExchange;

  /// No description provided for @refundExchangeHelp.
  ///
  /// In en, this message translates to:
  /// **'The returned items pay for new ones on the till; only the difference is paid or given back.'**
  String get refundExchangeHelp;

  /// No description provided for @refundPickReason.
  ///
  /// In en, this message translates to:
  /// **'Pick a reason.'**
  String get refundPickReason;

  /// No description provided for @refundNoReceiptHelp.
  ///
  /// In en, this message translates to:
  /// **'Without a receipt: a manager approves with their PIN, and it is marked in reports.'**
  String get refundNoReceiptHelp;

  /// No description provided for @refundAmount.
  ///
  /// In en, this message translates to:
  /// **'Give back'**
  String get refundAmount;

  /// No description provided for @refundAddItem.
  ///
  /// In en, this message translates to:
  /// **'Find what is coming back'**
  String get refundAddItem;

  /// No description provided for @refundGiveBack.
  ///
  /// In en, this message translates to:
  /// **'Give back'**
  String get refundGiveBack;

  /// No description provided for @settingsGroupPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get settingsGroupPayments;

  /// No description provided for @settingsPayMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get settingsPayMethods;

  /// No description provided for @settingsPayMethodsHelp.
  ///
  /// In en, this message translates to:
  /// **'MTN MoMo, Telecel Cash, card, bank... Switch on what you take and add your merchant number.'**
  String get settingsPayMethodsHelp;

  /// No description provided for @settingsRounding.
  ///
  /// In en, this message translates to:
  /// **'Round cash totals'**
  String get settingsRounding;

  /// No description provided for @settingsRoundingHelp.
  ///
  /// In en, this message translates to:
  /// **'When there are no small coins. The rounding is recorded on each sale.'**
  String get settingsRoundingHelp;

  /// No description provided for @settingsRound10.
  ///
  /// In en, this message translates to:
  /// **'To the nearest 10 pesewas'**
  String get settingsRound10;

  /// No description provided for @settingsRound50.
  ///
  /// In en, this message translates to:
  /// **'To the nearest 50 pesewas'**
  String get settingsRound50;

  /// No description provided for @todayClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get todayClosed;

  /// No description provided for @todayFind.
  ///
  /// In en, this message translates to:
  /// **'Find a sale'**
  String get todayFind;

  /// No description provided for @todayFindLabel.
  ///
  /// In en, this message translates to:
  /// **'Sale number'**
  String get todayFindLabel;

  /// No description provided for @todayFindHelp.
  ///
  /// In en, this message translates to:
  /// **'From the receipt, e.g. 142 for #00142.'**
  String get todayFindHelp;

  /// No description provided for @todayFindButton.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get todayFindButton;

  /// No description provided for @todayNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'no receipt'**
  String get todayNoReceipt;

  /// No description provided for @todayRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get todayRefund;

  /// No description provided for @todayRefundNoReceipt.
  ///
  /// In en, this message translates to:
  /// **'Refund without a receipt'**
  String get todayRefundNoReceipt;

  /// No description provided for @todayRefundedAll.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get todayRefundedAll;

  /// No description provided for @todayRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get todayRefunds;

  /// No description provided for @todaySalesCount.
  ///
  /// In en, this message translates to:
  /// **'Number of sales'**
  String get todaySalesCount;

  /// No description provided for @todayTotalSales.
  ///
  /// In en, this message translates to:
  /// **'Total sales'**
  String get todayTotalSales;

  /// No description provided for @todayVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get todayVoid;

  /// No description provided for @todayVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided'**
  String get todayVoided;

  /// No description provided for @voidWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get voidWhy;

  /// No description provided for @photoPickerUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photos cannot be picked on this device right now. Close Aby fully and open it again.'**
  String get photoPickerUnavailable;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @permManageCustomers.
  ///
  /// In en, this message translates to:
  /// **'Look after customers and their accounts'**
  String get permManageCustomers;

  /// No description provided for @payKindWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get payKindWallet;

  /// No description provided for @auditCreditWrittenOff.
  ///
  /// In en, this message translates to:
  /// **'Credit written off'**
  String get auditCreditWrittenOff;

  /// No description provided for @auditCustomerCreditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get auditCustomerCreditLimit;

  /// No description provided for @auditCustomerRepaid.
  ///
  /// In en, this message translates to:
  /// **'Customer paid'**
  String get auditCustomerRepaid;

  /// No description provided for @auditCustomerSaved.
  ///
  /// In en, this message translates to:
  /// **'Customer changed'**
  String get auditCustomerSaved;

  /// No description provided for @auditWalletTopUp.
  ///
  /// In en, this message translates to:
  /// **'Money into a wallet'**
  String get auditWalletTopUp;

  /// No description provided for @cartAddCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add a customer'**
  String get cartAddCustomer;

  /// No description provided for @cartRemoveCustomer.
  ///
  /// In en, this message translates to:
  /// **'Take the customer off'**
  String get cartRemoveCustomer;

  /// No description provided for @checkoutChooseCustomer.
  ///
  /// In en, this message translates to:
  /// **'Choose the customer'**
  String get checkoutChooseCustomer;

  /// No description provided for @customerNew.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get customerNew;

  /// No description provided for @customerEdit.
  ///
  /// In en, this message translates to:
  /// **'Change details'**
  String get customerEdit;

  /// No description provided for @customerQuickAdd.
  ///
  /// In en, this message translates to:
  /// **'New customer'**
  String get customerQuickAdd;

  /// No description provided for @customerPick.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerPick;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customerName;

  /// No description provided for @customerPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Their main number: how you find them at the till.'**
  String get customerPhoneHelp;

  /// No description provided for @customerPhone2.
  ///
  /// In en, this message translates to:
  /// **'Second phone (optional)'**
  String get customerPhone2;

  /// No description provided for @customerLocation.
  ///
  /// In en, this message translates to:
  /// **'Where they are (optional)'**
  String get customerLocation;

  /// No description provided for @customerLocationHelp.
  ///
  /// In en, this message translates to:
  /// **'As they give directions: \"near the mosque, Lamashegu\".'**
  String get customerLocationHelp;

  /// No description provided for @customerBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get customerBirthday;

  /// No description provided for @customerTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get customerTags;

  /// No description provided for @customerTagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Separated by commas: Wholesale, Staff.'**
  String get customerTagsHelp;

  /// No description provided for @customerLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit limit (optional)'**
  String get customerLimit;

  /// No description provided for @customerLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'The most they may owe. Empty: no limit.'**
  String get customerLimitHelp;

  /// No description provided for @customerLimitInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the credit limit.'**
  String get customerLimitInvalid;

  /// No description provided for @customerDueDays.
  ///
  /// In en, this message translates to:
  /// **'Days to pay (optional)'**
  String get customerDueDays;

  /// No description provided for @customerDueDaysHelp.
  ///
  /// In en, this message translates to:
  /// **'After this a credit sale is overdue.'**
  String get customerDueDaysHelp;

  /// No description provided for @customerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Phone (4 digits are enough) or name'**
  String get customerSearchHint;

  /// No description provided for @customersNone.
  ///
  /// In en, this message translates to:
  /// **'No customers yet.'**
  String get customersNone;

  /// No description provided for @customersOwing.
  ///
  /// In en, this message translates to:
  /// **'Owe money'**
  String get customersOwing;

  /// No description provided for @customerOwesLabel.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get customerOwesLabel;

  /// No description provided for @customerWalletLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get customerWalletLabel;

  /// No description provided for @customerRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get customerRecordPayment;

  /// No description provided for @customerAddToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add money to the wallet'**
  String get customerAddToWallet;

  /// No description provided for @customerStatement.
  ///
  /// In en, this message translates to:
  /// **'Statement'**
  String get customerStatement;

  /// No description provided for @customerRemind.
  ///
  /// In en, this message translates to:
  /// **'Send a reminder'**
  String get customerRemind;

  /// No description provided for @customerWriteOff.
  ///
  /// In en, this message translates to:
  /// **'Write off'**
  String get customerWriteOff;

  /// No description provided for @customerWriteOffWhy.
  ///
  /// In en, this message translates to:
  /// **'Why is it written off?'**
  String get customerWriteOffWhy;

  /// No description provided for @customerRemindMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get customerRemindMessage;

  /// No description provided for @customerRemindWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Open WhatsApp'**
  String get customerRemindWhatsApp;

  /// No description provided for @customerEditReason.
  ///
  /// In en, this message translates to:
  /// **'Change customer details.'**
  String get customerEditReason;

  /// No description provided for @customerAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount.'**
  String get customerAmountInvalid;

  /// No description provided for @customerNoPhone.
  ///
  /// In en, this message translates to:
  /// **'Add a phone number first.'**
  String get customerNoPhone;

  /// No description provided for @customerCannotOpen.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp could not be opened on this device.'**
  String get customerCannotOpen;

  /// No description provided for @customerHabits.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get customerHabits;

  /// No description provided for @customerSpend.
  ///
  /// In en, this message translates to:
  /// **'Spent in all'**
  String get customerSpend;

  /// No description provided for @customerVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get customerVisits;

  /// No description provided for @customerLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get customerLastVisit;

  /// No description provided for @customerFavourites.
  ///
  /// In en, this message translates to:
  /// **'Buys most'**
  String get customerFavourites;

  /// No description provided for @customerUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Still owed'**
  String get customerUnpaid;

  /// No description provided for @customerAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get customerAccount;

  /// No description provided for @customerNoEntries.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the account yet.'**
  String get customerNoEntries;

  /// No description provided for @customerSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get customerSales;

  /// No description provided for @customerPayFor.
  ///
  /// In en, this message translates to:
  /// **'Pay for'**
  String get customerPayFor;

  /// No description provided for @customerOldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get customerOldestFirst;

  /// No description provided for @settingsOverLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit over the limit'**
  String get settingsOverLimit;

  /// No description provided for @settingsOverLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'When a credit sale takes a customer over their limit.'**
  String get settingsOverLimitHelp;

  /// No description provided for @settingsOverLimitApprove.
  ///
  /// In en, this message translates to:
  /// **'Someone allowed approves with their PIN'**
  String get settingsOverLimitApprove;

  /// No description provided for @settingsOverLimitBlock.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get settingsOverLimitBlock;

  /// No description provided for @settingsReminder.
  ///
  /// In en, this message translates to:
  /// **'Credit reminder message'**
  String get settingsReminder;

  /// No description provided for @settingsReminderHelp.
  ///
  /// In en, this message translates to:
  /// **'The customer\'s name, what they owe and the shop\'s name are filled in.'**
  String get settingsReminderHelp;

  /// No description provided for @permManageCash.
  ///
  /// In en, this message translates to:
  /// **'Look after the safe and check MoMo'**
  String get permManageCash;

  /// No description provided for @reasonsPayIn.
  ///
  /// In en, this message translates to:
  /// **'Pay-in reasons'**
  String get reasonsPayIn;

  /// No description provided for @reasonsPayOut.
  ///
  /// In en, this message translates to:
  /// **'Pay-out reasons'**
  String get reasonsPayOut;

  /// No description provided for @auditBankDeposit.
  ///
  /// In en, this message translates to:
  /// **'Banked from the safe'**
  String get auditBankDeposit;

  /// No description provided for @auditCashPaidIn.
  ///
  /// In en, this message translates to:
  /// **'Cash put in'**
  String get auditCashPaidIn;

  /// No description provided for @auditCashPaidOut.
  ///
  /// In en, this message translates to:
  /// **'Cash taken out'**
  String get auditCashPaidOut;

  /// No description provided for @auditMomoChecked.
  ///
  /// In en, this message translates to:
  /// **'MoMo payment missing'**
  String get auditMomoChecked;

  /// No description provided for @auditSafeDrop.
  ///
  /// In en, this message translates to:
  /// **'Cash to the safe'**
  String get auditSafeDrop;

  /// No description provided for @auditDayStarted.
  ///
  /// In en, this message translates to:
  /// **'Day started'**
  String get auditDayStarted;

  /// No description provided for @todayCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get todayCash;

  /// No description provided for @xReportTitle.
  ///
  /// In en, this message translates to:
  /// **'X report (so far)'**
  String get xReportTitle;

  /// No description provided for @dayStart.
  ///
  /// In en, this message translates to:
  /// **'Start the day'**
  String get dayStart;

  /// No description provided for @dayStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Count the float: the cash in the drawer before the first sale.'**
  String get dayStartHelp;

  /// No description provided for @dayCountFloat.
  ///
  /// In en, this message translates to:
  /// **'Count the float'**
  String get dayCountFloat;

  /// No description provided for @dayStartReason.
  ///
  /// In en, this message translates to:
  /// **'Start the day.'**
  String get dayStartReason;

  /// No description provided for @dayAlreadyStarted.
  ///
  /// In en, this message translates to:
  /// **'The day is already started on this till.'**
  String get dayAlreadyStarted;

  /// No description provided for @payInTitle.
  ///
  /// In en, this message translates to:
  /// **'Put cash in'**
  String get payInTitle;

  /// No description provided for @payOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Take cash out'**
  String get payOutTitle;

  /// No description provided for @cashAddReceipt.
  ///
  /// In en, this message translates to:
  /// **'Photo of the receipt'**
  String get cashAddReceipt;

  /// No description provided for @cashReceiptAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added'**
  String get cashReceiptAdded;

  /// No description provided for @safeTitle.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get safeTitle;

  /// No description provided for @safeBalance.
  ///
  /// In en, this message translates to:
  /// **'In the safe'**
  String get safeBalance;

  /// No description provided for @safeEntries.
  ///
  /// In en, this message translates to:
  /// **'In and out'**
  String get safeEntries;

  /// No description provided for @safeNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the safe yet.'**
  String get safeNone;

  /// No description provided for @safeDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Move cash to the safe'**
  String get safeDropTitle;

  /// No description provided for @safeDropHelp.
  ///
  /// In en, this message translates to:
  /// **'Keeps the drawer low. It comes off what the drawer should hold.'**
  String get safeDropHelp;

  /// No description provided for @safeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get safeAdjustment;

  /// No description provided for @bankDepositTitle.
  ///
  /// In en, this message translates to:
  /// **'Take to the bank'**
  String get bankDepositTitle;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankName;

  /// No description provided for @bankSlip.
  ///
  /// In en, this message translates to:
  /// **'Slip number (optional)'**
  String get bankSlip;

  /// No description provided for @bankSlipPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the slip'**
  String get bankSlipPhoto;

  /// No description provided for @momoTitle.
  ///
  /// In en, this message translates to:
  /// **'Check MoMo'**
  String get momoTitle;

  /// No description provided for @momoHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap each payment once it is on your MoMo statement (tap again if it is missing).'**
  String get momoHelp;

  /// No description provided for @momoSummary.
  ///
  /// In en, this message translates to:
  /// **'This day'**
  String get momoSummary;

  /// No description provided for @momoCharges.
  ///
  /// In en, this message translates to:
  /// **'Charges and e-levy'**
  String get momoCharges;

  /// No description provided for @momoChargesHelp.
  ///
  /// In en, this message translates to:
  /// **'Taken off by MoMo. Tap to enter.'**
  String get momoChargesHelp;

  /// No description provided for @momoNet.
  ///
  /// In en, this message translates to:
  /// **'Should be in the MoMo wallet'**
  String get momoNet;

  /// No description provided for @momoTicked.
  ///
  /// In en, this message translates to:
  /// **'Found on the statement'**
  String get momoTicked;

  /// No description provided for @momoPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get momoPayments;

  /// No description provided for @momoNone.
  ///
  /// In en, this message translates to:
  /// **'No MoMo payments on this day.'**
  String get momoNone;

  /// No description provided for @momoNoReference.
  ///
  /// In en, this message translates to:
  /// **'No reference'**
  String get momoNoReference;

  /// No description provided for @countCashTitle.
  ///
  /// In en, this message translates to:
  /// **'Count the cash'**
  String get countCashTitle;

  /// No description provided for @countCashButton.
  ///
  /// In en, this message translates to:
  /// **'Count notes'**
  String get countCashButton;

  /// No description provided for @countCashUse.
  ///
  /// In en, this message translates to:
  /// **'Use this total'**
  String get countCashUse;

  /// No description provided for @closeSinceFirst.
  ///
  /// In en, this message translates to:
  /// **'Since the first sale'**
  String get closeSinceFirst;

  /// No description provided for @closeDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get closeDiscounts;

  /// No description provided for @closeFloat.
  ///
  /// In en, this message translates to:
  /// **'Float at the start'**
  String get closeFloat;

  /// No description provided for @closeCustomerCash.
  ///
  /// In en, this message translates to:
  /// **'Cash from customers'**
  String get closeCustomerCash;

  /// No description provided for @closePayIns.
  ///
  /// In en, this message translates to:
  /// **'Cash put in'**
  String get closePayIns;

  /// No description provided for @closePayOuts.
  ///
  /// In en, this message translates to:
  /// **'Cash taken out'**
  String get closePayOuts;

  /// No description provided for @closeSafeDrops.
  ///
  /// In en, this message translates to:
  /// **'Moved to the safe'**
  String get closeSafeDrops;

  /// No description provided for @closeExpected.
  ///
  /// In en, this message translates to:
  /// **'Expected in the drawer'**
  String get closeExpected;

  /// No description provided for @closeCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Count the drawer'**
  String get closeCountTitle;

  /// No description provided for @closeBlindHelp.
  ///
  /// In en, this message translates to:
  /// **'Count first: the expected amount shows after.'**
  String get closeBlindHelp;

  /// No description provided for @closeFloatLabel.
  ///
  /// In en, this message translates to:
  /// **'Float at the start'**
  String get closeFloatLabel;

  /// No description provided for @closeFloatHelp.
  ///
  /// In en, this message translates to:
  /// **'Cash that was in the drawer before the first sale.'**
  String get closeFloatHelp;

  /// No description provided for @closeCountedLabel.
  ///
  /// In en, this message translates to:
  /// **'Cash counted now'**
  String get closeCountedLabel;

  /// No description provided for @closeCheckCount.
  ///
  /// In en, this message translates to:
  /// **'Check the count'**
  String get closeCheckCount;

  /// No description provided for @closeReason.
  ///
  /// In en, this message translates to:
  /// **'Why is it over or short?'**
  String get closeReason;

  /// No description provided for @closeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the day?'**
  String get closeConfirmTitle;

  /// No description provided for @closeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Sales up to now can\'t be voided after this. New sales start a new day.'**
  String get closeConfirmBody;

  /// No description provided for @closeNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get closeNotYet;

  /// No description provided for @closeDone.
  ///
  /// In en, this message translates to:
  /// **'Day closed'**
  String get closeDone;

  /// No description provided for @closeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not close the day. Try again.'**
  String get closeFailed;

  /// No description provided for @closePast.
  ///
  /// In en, this message translates to:
  /// **'Past closes'**
  String get closePast;

  /// No description provided for @closeNone.
  ///
  /// In en, this message translates to:
  /// **'No closes yet.'**
  String get closeNone;

  /// No description provided for @closeBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get closeBalanced;

  /// No description provided for @closeEnterCount.
  ///
  /// In en, this message translates to:
  /// **'Enter the cash you counted'**
  String get closeEnterCount;

  /// No description provided for @closeBalancesBox.
  ///
  /// In en, this message translates to:
  /// **'Drawer balances'**
  String get closeBalancesBox;

  /// No description provided for @closeOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by'**
  String get closeOverBy;

  /// No description provided for @closeShortBy.
  ///
  /// In en, this message translates to:
  /// **'Short by'**
  String get closeShortBy;

  /// No description provided for @closeVarianceTitle.
  ///
  /// In en, this message translates to:
  /// **'Over and short, last 30 days'**
  String get closeVarianceTitle;

  /// No description provided for @settingsBlindCount.
  ///
  /// In en, this message translates to:
  /// **'Blind count at close day'**
  String get settingsBlindCount;

  /// No description provided for @settingsBlindCountHelp.
  ///
  /// In en, this message translates to:
  /// **'The cashier counts before seeing what the drawer should hold.'**
  String get settingsBlindCountHelp;

  /// No description provided for @settingsVarianceLimit.
  ///
  /// In en, this message translates to:
  /// **'Ask why when out by more than'**
  String get settingsVarianceLimit;

  /// No description provided for @settingsVarianceLimitHelp.
  ///
  /// In en, this message translates to:
  /// **'Over or short by more than this needs a reason.'**
  String get settingsVarianceLimitHelp;

  /// No description provided for @navMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get navMoney;

  /// No description provided for @permManageExpenses.
  ///
  /// In en, this message translates to:
  /// **'Record expenses and the owner\'s money'**
  String get permManageExpenses;

  /// No description provided for @auditExpenseAdded.
  ///
  /// In en, this message translates to:
  /// **'Expense recorded'**
  String get auditExpenseAdded;

  /// No description provided for @auditExpenseCategorySaved.
  ///
  /// In en, this message translates to:
  /// **'Expense list changed'**
  String get auditExpenseCategorySaved;

  /// No description provided for @auditOwnerCapital.
  ///
  /// In en, this message translates to:
  /// **'Owner put money in'**
  String get auditOwnerCapital;

  /// No description provided for @auditOwnerDrawing.
  ///
  /// In en, this message translates to:
  /// **'Owner took money'**
  String get auditOwnerDrawing;

  /// No description provided for @moneyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get moneyExpenses;

  /// No description provided for @moneyProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get moneyProfit;

  /// No description provided for @moneyOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s money'**
  String get moneyOwner;

  /// No description provided for @periodToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get periodToday;

  /// No description provided for @periodThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get periodThisWeek;

  /// No description provided for @periodThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get periodThisMonth;

  /// No description provided for @periodLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get periodLastMonth;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose dates'**
  String get periodCustom;

  /// No description provided for @expenseNew.
  ///
  /// In en, this message translates to:
  /// **'Add an expense'**
  String get expenseNew;

  /// No description provided for @expenseCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategory;

  /// No description provided for @expenseCategories.
  ///
  /// In en, this message translates to:
  /// **'Expense categories'**
  String get expenseCategories;

  /// No description provided for @expenseCategoryNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get expenseCategoryNew;

  /// No description provided for @expenseCategoryReason.
  ///
  /// In en, this message translates to:
  /// **'Change the expense categories.'**
  String get expenseCategoryReason;

  /// No description provided for @expensePaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get expensePaidFrom;

  /// No description provided for @expenseDrawerHelp.
  ///
  /// In en, this message translates to:
  /// **'It comes out of the drawer, so close day expects less cash.'**
  String get expenseDrawerHelp;

  /// No description provided for @expenseDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get expenseDay;

  /// No description provided for @expenseSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier (optional)'**
  String get expenseSupplier;

  /// No description provided for @expenseNoSupplier.
  ///
  /// In en, this message translates to:
  /// **'No supplier'**
  String get expenseNoSupplier;

  /// No description provided for @expensePickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category.'**
  String get expensePickCategory;

  /// No description provided for @expensesByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get expensesByCategory;

  /// No description provided for @expensesNone.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get expensesNone;

  /// No description provided for @sourceDrawer.
  ///
  /// In en, this message translates to:
  /// **'Drawer cash'**
  String get sourceDrawer;

  /// No description provided for @sourceMomo.
  ///
  /// In en, this message translates to:
  /// **'MoMo'**
  String get sourceMomo;

  /// No description provided for @sourceBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get sourceBank;

  /// No description provided for @sourceOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s pocket'**
  String get sourceOwner;

  /// No description provided for @payOutExpense.
  ///
  /// In en, this message translates to:
  /// **'Is it an expense? (optional)'**
  String get payOutExpense;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly reminders'**
  String get recurringTitle;

  /// No description provided for @recurringNew.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get recurringNew;

  /// No description provided for @recurringEdit.
  ///
  /// In en, this message translates to:
  /// **'Change reminder'**
  String get recurringEdit;

  /// No description provided for @recurringNone.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet. Add rent, ECG and the like.'**
  String get recurringNone;

  /// No description provided for @recurringName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get recurringName;

  /// No description provided for @recurringNameHelp.
  ///
  /// In en, this message translates to:
  /// **'For example \"Shop rent\".'**
  String get recurringNameHelp;

  /// No description provided for @recurringDay.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get recurringDay;

  /// No description provided for @recurringReason.
  ///
  /// In en, this message translates to:
  /// **'Change the monthly reminders.'**
  String get recurringReason;

  /// No description provided for @recurringConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record it'**
  String get recurringConfirm;

  /// No description provided for @recurringSkip.
  ///
  /// In en, this message translates to:
  /// **'Not this month'**
  String get recurringSkip;

  /// No description provided for @profitThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'THIS PERIOD'**
  String get profitThisPeriod;

  /// No description provided for @profitBefore.
  ///
  /// In en, this message translates to:
  /// **'BEFORE'**
  String get profitBefore;

  /// No description provided for @profitSales.
  ///
  /// In en, this message translates to:
  /// **'Sales at menu prices'**
  String get profitSales;

  /// No description provided for @profitDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get profitDiscounts;

  /// No description provided for @profitRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get profitRefunds;

  /// No description provided for @profitTax.
  ///
  /// In en, this message translates to:
  /// **'Tax collected (for GRA)'**
  String get profitTax;

  /// No description provided for @profitNetSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get profitNetSales;

  /// No description provided for @profitCost.
  ///
  /// In en, this message translates to:
  /// **'What the stock cost'**
  String get profitCost;

  /// No description provided for @profitGross.
  ///
  /// In en, this message translates to:
  /// **'Gross profit'**
  String get profitGross;

  /// No description provided for @profitWaste.
  ///
  /// In en, this message translates to:
  /// **'Stock thrown away'**
  String get profitWaste;

  /// No description provided for @profitCounts.
  ///
  /// In en, this message translates to:
  /// **'Stock count differences'**
  String get profitCounts;

  /// No description provided for @profitNet.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get profitNet;

  /// No description provided for @profitHelp.
  ///
  /// In en, this message translates to:
  /// **'A simple view, not full accounts. \"Before\" is the same length of time just before. Stock costs come from recipes and deliveries.'**
  String get profitHelp;

  /// No description provided for @ownerTook.
  ///
  /// In en, this message translates to:
  /// **'Owner took money'**
  String get ownerTook;

  /// No description provided for @ownerPut.
  ///
  /// In en, this message translates to:
  /// **'Owner put money in'**
  String get ownerPut;

  /// No description provided for @ownerTookHelp.
  ///
  /// In en, this message translates to:
  /// **'Money taken home. It is not an expense, so profit is not understated.'**
  String get ownerTookHelp;

  /// No description provided for @ownerPutHelp.
  ///
  /// In en, this message translates to:
  /// **'The owner\'s own money put into the shop. It is not a sale.'**
  String get ownerPutHelp;

  /// No description provided for @ownerTookTotal.
  ///
  /// In en, this message translates to:
  /// **'Taken by the owner'**
  String get ownerTookTotal;

  /// No description provided for @ownerPutTotal.
  ///
  /// In en, this message translates to:
  /// **'Put in by the owner'**
  String get ownerPutTotal;

  /// No description provided for @ownerTakeHome.
  ///
  /// In en, this message translates to:
  /// **'Taken home, net'**
  String get ownerTakeHome;

  /// No description provided for @ownerTakeHomeHelp.
  ///
  /// In en, this message translates to:
  /// **'Taken out less put in.'**
  String get ownerTakeHomeHelp;

  /// No description provided for @ownerHelp.
  ///
  /// In en, this message translates to:
  /// **'Keep the owner\'s own money apart from the shop\'s: drawings and money put in.'**
  String get ownerHelp;

  /// No description provided for @ownerEntries.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get ownerEntries;

  /// No description provided for @ownerNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this period.'**
  String get ownerNone;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get navReports;

  /// No description provided for @dashSales.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashSales;

  /// No description provided for @dashTop.
  ///
  /// In en, this message translates to:
  /// **'Top products today'**
  String get dashTop;

  /// No description provided for @dashDrawer.
  ///
  /// In en, this message translates to:
  /// **'The drawer'**
  String get dashDrawer;

  /// No description provided for @dashAlerts.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get dashAlerts;

  /// No description provided for @dashAllGood.
  ///
  /// In en, this message translates to:
  /// **'Nothing needs attention.'**
  String get dashAllGood;

  /// No description provided for @dashArrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange the dashboard'**
  String get dashArrange;

  /// No description provided for @dashRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get dashRefresh;

  /// No description provided for @dashDayNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Day not started'**
  String get dashDayNotStarted;

  /// No description provided for @alertBackup.
  ///
  /// In en, this message translates to:
  /// **'The backup is not up to date. See the status dot.'**
  String get alertBackup;

  /// No description provided for @reportSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportSales;

  /// No description provided for @reportTimes.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get reportTimes;

  /// No description provided for @reportProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get reportProducts;

  /// No description provided for @reportPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get reportPayments;

  /// No description provided for @reportStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get reportStaff;

  /// No description provided for @reportCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get reportCustomers;

  /// No description provided for @reportStockTax.
  ///
  /// In en, this message translates to:
  /// **'Stock and tax'**
  String get reportStockTax;

  /// No description provided for @reportAccountant.
  ///
  /// In en, this message translates to:
  /// **'For the accountant'**
  String get reportAccountant;

  /// No description provided for @reportNetSales.
  ///
  /// In en, this message translates to:
  /// **'Net sales'**
  String get reportNetSales;

  /// No description provided for @reportSalesCount.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get reportSalesCount;

  /// No description provided for @reportAverageSale.
  ///
  /// In en, this message translates to:
  /// **'Average sale'**
  String get reportAverageSale;

  /// No description provided for @reportItemsPerSale.
  ///
  /// In en, this message translates to:
  /// **'Items per sale'**
  String get reportItemsPerSale;

  /// No description provided for @reportBreakdown.
  ///
  /// In en, this message translates to:
  /// **'How it adds up'**
  String get reportBreakdown;

  /// No description provided for @reportTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get reportTax;

  /// No description provided for @reportByDay.
  ///
  /// In en, this message translates to:
  /// **'Day by day'**
  String get reportByDay;

  /// No description provided for @reportTimesHelp.
  ///
  /// In en, this message translates to:
  /// **'When the shop is busy, to plan staff and prep.'**
  String get reportTimesHelp;

  /// No description provided for @reportByHour.
  ///
  /// In en, this message translates to:
  /// **'By hour'**
  String get reportByHour;

  /// No description provided for @reportHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Day and hour'**
  String get reportHeatmap;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @reportAbcHelp.
  ///
  /// In en, this message translates to:
  /// **'A: the products bringing in the first 80% of sales; B: the next 15%; C: the rest.'**
  String get reportAbcHelp;

  /// No description provided for @reportByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get reportByCategory;

  /// No description provided for @reportOptions.
  ///
  /// In en, this message translates to:
  /// **'Options picked'**
  String get reportOptions;

  /// No description provided for @reportSlow.
  ///
  /// In en, this message translates to:
  /// **'Not selling'**
  String get reportSlow;

  /// No description provided for @reportSlowHelp.
  ///
  /// In en, this message translates to:
  /// **'On the till but not sold in the last 14 days.'**
  String get reportSlowHelp;

  /// No description provided for @reportSlowNone.
  ///
  /// In en, this message translates to:
  /// **'Everything sold in the last 14 days.'**
  String get reportSlowNone;

  /// No description provided for @reportNeverSold.
  ///
  /// In en, this message translates to:
  /// **'Never sold'**
  String get reportNeverSold;

  /// No description provided for @reportVoids.
  ///
  /// In en, this message translates to:
  /// **'Voids'**
  String get reportVoids;

  /// No description provided for @reportRefundsGiven.
  ///
  /// In en, this message translates to:
  /// **'Refunds given'**
  String get reportRefundsGiven;

  /// No description provided for @reportNoSales.
  ///
  /// In en, this message translates to:
  /// **'Drawer opened without a sale'**
  String get reportNoSales;

  /// No description provided for @reportNewCustomers.
  ///
  /// In en, this message translates to:
  /// **'New customers'**
  String get reportNewCustomers;

  /// No description provided for @reportReturning.
  ///
  /// In en, this message translates to:
  /// **'Came back'**
  String get reportReturning;

  /// No description provided for @reportOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed now'**
  String get reportOwed;

  /// No description provided for @reportOverdue.
  ///
  /// In en, this message translates to:
  /// **'Late now'**
  String get reportOverdue;

  /// No description provided for @reportWallets.
  ///
  /// In en, this message translates to:
  /// **'In wallets'**
  String get reportWallets;

  /// No description provided for @reportTopCustomers.
  ///
  /// In en, this message translates to:
  /// **'Top customers'**
  String get reportTopCustomers;

  /// No description provided for @reportStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value at cost'**
  String get reportStockValue;

  /// No description provided for @reportMovements.
  ///
  /// In en, this message translates to:
  /// **'Stock in and out, at cost'**
  String get reportMovements;

  /// No description provided for @reportNoTax.
  ///
  /// In en, this message translates to:
  /// **'No tax charged.'**
  String get reportNoTax;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @statusPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get statusPrinter;

  /// No description provided for @statusPrinterReady.
  ///
  /// In en, this message translates to:
  /// **'Ready. Nothing waiting.'**
  String get statusPrinterReady;

  /// No description provided for @printClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get printClear;

  /// No description provided for @printSent.
  ///
  /// In en, this message translates to:
  /// **'Sent to the printer.'**
  String get printSent;

  /// No description provided for @printNoPrinter.
  ///
  /// In en, this message translates to:
  /// **'No receipt printer on this device. Set one up in Settings, Receipts and printing.'**
  String get printNoPrinter;

  /// No description provided for @printReprintLast.
  ///
  /// In en, this message translates to:
  /// **'Reprint the last receipt'**
  String get printReprintLast;

  /// No description provided for @printNothingYet.
  ///
  /// In en, this message translates to:
  /// **'No sale to reprint yet.'**
  String get printNothingYet;

  /// No description provided for @receiptPrint.
  ///
  /// In en, this message translates to:
  /// **'Print receipt'**
  String get receiptPrint;

  /// No description provided for @receiptPrintAgain.
  ///
  /// In en, this message translates to:
  /// **'Print again'**
  String get receiptPrintAgain;

  /// No description provided for @receiptSend.
  ///
  /// In en, this message translates to:
  /// **'Send receipt'**
  String get receiptSend;

  /// No description provided for @receiptPhone.
  ///
  /// In en, this message translates to:
  /// **'Customer\'s phone'**
  String get receiptPhone;

  /// No description provided for @receiptPhoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Leave it empty to pick the chat in WhatsApp.'**
  String get receiptPhoneHelp;

  /// No description provided for @receiptPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a Ghana phone number, like 024 123 4567.'**
  String get receiptPhoneInvalid;

  /// No description provided for @receiptSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get receiptSms;

  /// No description provided for @receiptPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get receiptPdf;

  /// No description provided for @refundPrintSlip.
  ///
  /// In en, this message translates to:
  /// **'Print refund slip'**
  String get refundPrintSlip;

  /// No description provided for @closePrintZ.
  ///
  /// In en, this message translates to:
  /// **'Print Z report'**
  String get closePrintZ;

  /// No description provided for @customerPrintBalance.
  ///
  /// In en, this message translates to:
  /// **'Print the balance'**
  String get customerPrintBalance;

  /// No description provided for @settingsGroupPrinting.
  ///
  /// In en, this message translates to:
  /// **'Receipts and printing'**
  String get settingsGroupPrinting;

  /// No description provided for @printerTitle.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get printerTitle;

  /// No description provided for @printerNoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth, USB or network thermal printers, 58 or 80 mm.'**
  String get printerNoneHelp;

  /// No description provided for @printerNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get printerNetwork;

  /// No description provided for @printerWindows.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get printerWindows;

  /// No description provided for @printerBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get printerBluetooth;

  /// No description provided for @printerAddress.
  ///
  /// In en, this message translates to:
  /// **'Printer\'s IP address'**
  String get printerAddress;

  /// No description provided for @printerAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Like 192.168.1.50. Print the printer\'s own test page to find it.'**
  String get printerAddressHelp;

  /// No description provided for @printerWindowsHelp.
  ///
  /// In en, this message translates to:
  /// **'USB printers show here once their Windows driver is installed.'**
  String get printerWindowsHelp;

  /// No description provided for @printerBluetoothHelp.
  ///
  /// In en, this message translates to:
  /// **'Pair the printer in Android\'s Bluetooth settings first (the PIN is often 0000 or 1234).'**
  String get printerBluetoothHelp;

  /// No description provided for @printerNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No printers found.'**
  String get printerNoneFound;

  /// No description provided for @printerLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get printerLookAgain;

  /// No description provided for @printerPaper.
  ///
  /// In en, this message translates to:
  /// **'Paper width'**
  String get printerPaper;

  /// No description provided for @printerTest.
  ///
  /// In en, this message translates to:
  /// **'Print a test page'**
  String get printerTest;

  /// No description provided for @printerTestSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. If nothing came out, check the paper and that the printer is on.'**
  String get printerTestSent;

  /// No description provided for @printerChooseFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose a printer first.'**
  String get printerChooseFirst;

  /// No description provided for @printerRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove printer'**
  String get printerRemove;

  /// No description provided for @settingsAutoPrint.
  ///
  /// In en, this message translates to:
  /// **'Print every receipt'**
  String get settingsAutoPrint;

  /// No description provided for @settingsAutoPrintHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: print only when asked, or use Send receipt for no paper.'**
  String get settingsAutoPrintHelp;

  /// No description provided for @settingsCashDrawer.
  ///
  /// In en, this message translates to:
  /// **'Cash drawer'**
  String get settingsCashDrawer;

  /// No description provided for @settingsCashDrawerHelp.
  ///
  /// In en, this message translates to:
  /// **'Plugged into the printer. Opens for cash sales, cash refunds, pay in or out, and no-sales.'**
  String get settingsCashDrawerHelp;

  /// No description provided for @settingsTestDrawer.
  ///
  /// In en, this message translates to:
  /// **'Open the drawer to test it'**
  String get settingsTestDrawer;

  /// No description provided for @receiptDesign.
  ///
  /// In en, this message translates to:
  /// **'Receipt design'**
  String get receiptDesign;

  /// No description provided for @receiptDesignHelp.
  ///
  /// In en, this message translates to:
  /// **'Logo, header, footer, MoMo number and what each receipt shows.'**
  String get receiptDesignHelp;

  /// No description provided for @receiptShopFromSettings.
  ///
  /// In en, this message translates to:
  /// **'The shop name, address and phone come from the Shop settings.'**
  String get receiptShopFromSettings;

  /// No description provided for @receiptLogoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a logo'**
  String get receiptLogoAdd;

  /// No description provided for @receiptLogoChange.
  ///
  /// In en, this message translates to:
  /// **'Change the logo'**
  String get receiptLogoChange;

  /// No description provided for @receiptLogoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the logo'**
  String get receiptLogoRemove;

  /// No description provided for @receiptLogoUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That picture could not be read. Try a PNG or JPEG.'**
  String get receiptLogoUnreadable;

  /// No description provided for @receiptHeader.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get receiptHeader;

  /// No description provided for @receiptHeaderHelp.
  ///
  /// In en, this message translates to:
  /// **'Under the shop name, like opening hours or a landmark.'**
  String get receiptHeaderHelp;

  /// No description provided for @receiptMomo.
  ///
  /// In en, this message translates to:
  /// **'MoMo number to pay'**
  String get receiptMomo;

  /// No description provided for @receiptFooter.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get receiptFooter;

  /// No description provided for @receiptShowCashier.
  ///
  /// In en, this message translates to:
  /// **'Who served'**
  String get receiptShowCashier;

  /// No description provided for @receiptShowCustomer.
  ///
  /// In en, this message translates to:
  /// **'The customer\'s name'**
  String get receiptShowCustomer;

  /// No description provided for @receiptShowTax.
  ///
  /// In en, this message translates to:
  /// **'Tax included'**
  String get receiptShowTax;

  /// No description provided for @receiptShowQr.
  ///
  /// In en, this message translates to:
  /// **'QR code for refunds and reprints'**
  String get receiptShowQr;

  /// No description provided for @receiptCreditCopies.
  ///
  /// In en, this message translates to:
  /// **'Credit sales'**
  String get receiptCreditCopies;

  /// No description provided for @receiptOneCopy.
  ///
  /// In en, this message translates to:
  /// **'One copy'**
  String get receiptOneCopy;

  /// No description provided for @receiptTwoCopies.
  ///
  /// In en, this message translates to:
  /// **'Customer and shop copy'**
  String get receiptTwoCopies;

  /// No description provided for @scanWithCamera.
  ///
  /// In en, this message translates to:
  /// **'Scan with the camera'**
  String get scanWithCamera;

  /// No description provided for @scanTorch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get scanTorch;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Hold the barcode or receipt QR code inside the box.'**
  String get scanHint;

  /// No description provided for @scanNoPermission.
  ///
  /// In en, this message translates to:
  /// **'Aby needs the camera to scan. Allow it in Android settings, then try again.'**
  String get scanNoPermission;

  /// No description provided for @scanCameraError.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start. Close other apps using it and try again.'**
  String get scanCameraError;

  /// No description provided for @settingsCameraScan.
  ///
  /// In en, this message translates to:
  /// **'Scan with the camera'**
  String get settingsCameraScan;

  /// No description provided for @settingsCameraScanHelp.
  ///
  /// In en, this message translates to:
  /// **'Shows a camera button next to search, receipts and barcodes.'**
  String get settingsCameraScanHelp;

  /// No description provided for @scaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get scaleTitle;

  /// No description provided for @scaleHelp.
  ///
  /// In en, this message translates to:
  /// **'Reads the weight for products sold by the kilo.'**
  String get scaleHelp;

  /// No description provided for @scaleSerialHelp.
  ///
  /// In en, this message translates to:
  /// **'Scales with a serial or USB cable show as a COM port once their driver is installed.'**
  String get scaleSerialHelp;

  /// No description provided for @scaleBluetoothHelp.
  ///
  /// In en, this message translates to:
  /// **'Pair the scale in Android\'s Bluetooth settings first.'**
  String get scaleBluetoothHelp;

  /// No description provided for @scalePort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get scalePort;

  /// No description provided for @scaleDevice.
  ///
  /// In en, this message translates to:
  /// **'Paired scale'**
  String get scaleDevice;

  /// No description provided for @scaleBaud.
  ///
  /// In en, this message translates to:
  /// **'Speed (baud)'**
  String get scaleBaud;

  /// No description provided for @scaleRequest.
  ///
  /// In en, this message translates to:
  /// **'How to ask for the weight'**
  String get scaleRequest;

  /// No description provided for @scaleRequestHelp.
  ///
  /// In en, this message translates to:
  /// **'See the scale\'s manual. Most send the weight all the time.'**
  String get scaleRequestHelp;

  /// No description provided for @scaleRequestNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing: it sends the weight all the time'**
  String get scaleRequestNone;

  /// No description provided for @scaleRequestEnq.
  ///
  /// In en, this message translates to:
  /// **'Send ENQ (05)'**
  String get scaleRequestEnq;

  /// No description provided for @scaleRead.
  ///
  /// In en, this message translates to:
  /// **'Read the scale'**
  String get scaleRead;

  /// No description provided for @scaleNoneFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Check the cable or the pairing.'**
  String get scaleNoneFound;

  /// No description provided for @scaleChooseFirst.
  ///
  /// In en, this message translates to:
  /// **'Choose the scale first.'**
  String get scaleChooseFirst;

  /// No description provided for @scaleRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove scale'**
  String get scaleRemove;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsHelp.
  ///
  /// In en, this message translates to:
  /// **'Phone or Windows notifications for low stock, late credit, backups and more.'**
  String get settingsNotificationsHelp;

  /// No description provided for @notifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Which notifications'**
  String get notifyTitle;

  /// No description provided for @notifyLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get notifyLowStock;

  /// No description provided for @notifyCredit.
  ///
  /// In en, this message translates to:
  /// **'Customers late paying'**
  String get notifyCredit;

  /// No description provided for @notifyBackup.
  ///
  /// In en, this message translates to:
  /// **'Backups not up to date'**
  String get notifyBackup;

  /// No description provided for @notifyDayOpen.
  ///
  /// In en, this message translates to:
  /// **'A day not closed'**
  String get notifyDayOpen;

  /// No description provided for @notifyParked.
  ///
  /// In en, this message translates to:
  /// **'Old parked orders'**
  String get notifyParked;

  /// No description provided for @notifyExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses due'**
  String get notifyExpenses;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @auditPromotionSaved.
  ///
  /// In en, this message translates to:
  /// **'Promotion changed'**
  String get auditPromotionSaved;

  /// No description provided for @optionsComboPart.
  ///
  /// In en, this message translates to:
  /// **'Is a product (combo part)'**
  String get optionsComboPart;

  /// No description provided for @optionsComboPartHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses that product\'s recipe, so its stock goes down.'**
  String get optionsComboPartHelp;

  /// No description provided for @optionsNotAProduct.
  ///
  /// In en, this message translates to:
  /// **'No, just an option'**
  String get optionsNotAProduct;

  /// No description provided for @promoTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promoTitle;

  /// No description provided for @promoSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Happy hours, buy X get Y, bundles, quantity prices and spend rewards.'**
  String get promoSettingsHelp;

  /// No description provided for @promoHelp.
  ///
  /// In en, this message translates to:
  /// **'They apply themselves at the till when their conditions are met. When several could apply, the best deal for the customer wins.'**
  String get promoHelp;

  /// No description provided for @promoNone.
  ///
  /// In en, this message translates to:
  /// **'No promotions yet.'**
  String get promoNone;

  /// No description provided for @promoNew.
  ///
  /// In en, this message translates to:
  /// **'New promotion'**
  String get promoNew;

  /// No description provided for @promoEdit.
  ///
  /// In en, this message translates to:
  /// **'Change promotion'**
  String get promoEdit;

  /// No description provided for @promoRunningNow.
  ///
  /// In en, this message translates to:
  /// **'On now'**
  String get promoRunningNow;

  /// No description provided for @promoApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Promotions change prices.'**
  String get promoApprovalReason;

  /// No description provided for @promoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get promoName;

  /// No description provided for @promoNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown on the cart and the receipt, like Happy hour.'**
  String get promoNameHelp;

  /// No description provided for @promoNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the promotion a name.'**
  String get promoNameRequired;

  /// No description provided for @promoKind.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get promoKind;

  /// No description provided for @promoKindPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get promoKindPercent;

  /// No description provided for @promoKindPercentExample.
  ///
  /// In en, this message translates to:
  /// **'Happy hour 2 to 4 pm: 15% off cups.'**
  String get promoKindPercentExample;

  /// No description provided for @promoKindBuyGet.
  ///
  /// In en, this message translates to:
  /// **'Buy some, get some'**
  String get promoKindBuyGet;

  /// No description provided for @promoKindBuyGetExample.
  ///
  /// In en, this message translates to:
  /// **'Buy 2 cones, get 1 free (the cheapest).'**
  String get promoKindBuyGetExample;

  /// No description provided for @promoKindBundle.
  ///
  /// In en, this message translates to:
  /// **'Bundle price'**
  String get promoKindBundle;

  /// No description provided for @promoKindBundleExample.
  ///
  /// In en, this message translates to:
  /// **'Cone and milkshake together for GH₵ 32.'**
  String get promoKindBundleExample;

  /// No description provided for @promoKindQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity price'**
  String get promoKindQuantity;

  /// No description provided for @promoKindQuantityExample.
  ///
  /// In en, this message translates to:
  /// **'6 or more tubs: GH₵ 55 each.'**
  String get promoKindQuantityExample;

  /// No description provided for @promoKindSpend.
  ///
  /// In en, this message translates to:
  /// **'Spend reward'**
  String get promoKindSpend;

  /// No description provided for @promoKindSpendExample.
  ///
  /// In en, this message translates to:
  /// **'Spend GH₵ 100, get a free waffle.'**
  String get promoKindSpendExample;

  /// No description provided for @promoEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get promoEverything;

  /// No description provided for @promoPickHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick categories, products or both. Nothing picked means everything.'**
  String get promoPickHelp;

  /// No description provided for @promoOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get promoOn;

  /// No description provided for @promoPercentOff.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get promoPercentOff;

  /// No description provided for @promoMinQuantity.
  ///
  /// In en, this message translates to:
  /// **'How many at least'**
  String get promoMinQuantity;

  /// No description provided for @promoPriceEach.
  ///
  /// In en, this message translates to:
  /// **'Price each'**
  String get promoPriceEach;

  /// No description provided for @promoBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get promoBuy;

  /// No description provided for @promoOf.
  ///
  /// In en, this message translates to:
  /// **'Of'**
  String get promoOf;

  /// No description provided for @promoGet.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get promoGet;

  /// No description provided for @promoOfSameOrOther.
  ///
  /// In en, this message translates to:
  /// **'Of (Everything: the same as bought)'**
  String get promoOfSameOrOther;

  /// No description provided for @promoRewardPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent off what they get (100 = free)'**
  String get promoRewardPercent;

  /// No description provided for @promoAddPart.
  ///
  /// In en, this message translates to:
  /// **'Add a part'**
  String get promoAddPart;

  /// No description provided for @promoBundlePrice.
  ///
  /// In en, this message translates to:
  /// **'Bundle price'**
  String get promoBundlePrice;

  /// No description provided for @promoSpendAtLeast.
  ///
  /// In en, this message translates to:
  /// **'When they spend at least'**
  String get promoSpendAtLeast;

  /// No description provided for @promoRewardPercentOff.
  ///
  /// In en, this message translates to:
  /// **'Percent off'**
  String get promoRewardPercentOff;

  /// No description provided for @promoRewardAmountOff.
  ///
  /// In en, this message translates to:
  /// **'Money off'**
  String get promoRewardAmountOff;

  /// No description provided for @promoRewardFree.
  ///
  /// In en, this message translates to:
  /// **'A free item'**
  String get promoRewardFree;

  /// No description provided for @promoAmountOff.
  ///
  /// In en, this message translates to:
  /// **'Money off'**
  String get promoAmountOff;

  /// No description provided for @promoFreeItem.
  ///
  /// In en, this message translates to:
  /// **'Free item (the cheapest in the cart)'**
  String get promoFreeItem;

  /// No description provided for @promoWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get promoWhen;

  /// No description provided for @promoAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get promoAllDay;

  /// No description provided for @promoStartsNow.
  ///
  /// In en, this message translates to:
  /// **'From now'**
  String get promoStartsNow;

  /// No description provided for @promoNoEnd.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get promoNoEnd;

  /// No description provided for @promoAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get promoAnyDate;

  /// No description provided for @promoStackable.
  ///
  /// In en, this message translates to:
  /// **'Works with other promotions'**
  String get promoStackable;

  /// No description provided for @promoStackableHelp.
  ///
  /// In en, this message translates to:
  /// **'Off: only the best deal applies.'**
  String get promoStackableHelp;

  /// No description provided for @promoOn2.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get promoOn2;

  /// No description provided for @promoPercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a percentage from 1 to 100.'**
  String get promoPercentInvalid;

  /// No description provided for @promoAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount, like 32 or 5.50.'**
  String get promoAmountInvalid;

  /// No description provided for @promoQuantityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter how many, 1 or more.'**
  String get promoQuantityInvalid;

  /// No description provided for @promoThresholdInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter how much they must spend.'**
  String get promoThresholdInvalid;

  /// No description provided for @promoPartsInvalid.
  ///
  /// In en, this message translates to:
  /// **'A bundle needs at least 2 parts.'**
  String get promoPartsInvalid;

  /// No description provided for @promoDaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get promoDaysRequired;

  /// No description provided for @auditVoucherIssued.
  ///
  /// In en, this message translates to:
  /// **'Gift voucher sold'**
  String get auditVoucherIssued;

  /// No description provided for @payKindVoucher.
  ///
  /// In en, this message translates to:
  /// **'Gift voucher'**
  String get payKindVoucher;

  /// No description provided for @loyaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty'**
  String get loyaltyTitle;

  /// No description provided for @loyaltySettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Stamp card, points or Gold customers. Customers are known by their phone number.'**
  String get loyaltySettingsHelp;

  /// No description provided for @loyaltyHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick one style for the shop. Attach the customer at the till: rewards apply by themselves.'**
  String get loyaltyHelp;

  /// No description provided for @loyaltyOffHelp.
  ///
  /// In en, this message translates to:
  /// **'No loyalty rewards.'**
  String get loyaltyOffHelp;

  /// No description provided for @loyaltyStampCard.
  ///
  /// In en, this message translates to:
  /// **'Stamps'**
  String get loyaltyStampCard;

  /// No description provided for @loyaltyPointsStyle.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get loyaltyPointsStyle;

  /// No description provided for @loyaltyTiers.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get loyaltyTiers;

  /// No description provided for @loyaltyStampsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Stamps for a free item'**
  String get loyaltyStampsNeeded;

  /// No description provided for @loyaltyStampsNeededHelp.
  ///
  /// In en, this message translates to:
  /// **'9 means buy 9, get the 10th free. One stamp per item.'**
  String get loyaltyStampsNeededHelp;

  /// No description provided for @loyaltyStampProducts.
  ///
  /// In en, this message translates to:
  /// **'Items that earn stamps (and the free one)'**
  String get loyaltyStampProducts;

  /// No description provided for @loyaltyPointsPerCedi.
  ///
  /// In en, this message translates to:
  /// **'Points per GH₵ 1 spent'**
  String get loyaltyPointsPerCedi;

  /// No description provided for @loyaltyPointsForReward.
  ///
  /// In en, this message translates to:
  /// **'Points for a reward'**
  String get loyaltyPointsForReward;

  /// No description provided for @loyaltyRewardValue.
  ///
  /// In en, this message translates to:
  /// **'Reward value'**
  String get loyaltyRewardValue;

  /// No description provided for @loyaltyExpireDays.
  ///
  /// In en, this message translates to:
  /// **'Points expire after'**
  String get loyaltyExpireDays;

  /// No description provided for @loyaltyExpireDaysHelp.
  ///
  /// In en, this message translates to:
  /// **'Days without a purchase. 0 means never.'**
  String get loyaltyExpireDaysHelp;

  /// No description provided for @loyaltyDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get loyaltyDays;

  /// No description provided for @loyaltyTiersHelp.
  ///
  /// In en, this message translates to:
  /// **'Customers who spent enough in the last 90 days are Gold and get a discount on everything.'**
  String get loyaltyTiersHelp;

  /// No description provided for @loyaltyGoldSpend.
  ///
  /// In en, this message translates to:
  /// **'Gold from this spend in 90 days'**
  String get loyaltyGoldSpend;

  /// No description provided for @loyaltyGoldPercent.
  ///
  /// In en, this message translates to:
  /// **'Gold discount'**
  String get loyaltyGoldPercent;

  /// No description provided for @loyaltyNumbersInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the numbers: each needs to be 1 or more.'**
  String get loyaltyNumbersInvalid;

  /// No description provided for @voucherTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift vouchers'**
  String get voucherTitle;

  /// No description provided for @voucherTitleOne.
  ///
  /// In en, this message translates to:
  /// **'Gift voucher'**
  String get voucherTitleOne;

  /// No description provided for @voucherHelp.
  ///
  /// In en, this message translates to:
  /// **'Sold for money now, spent later as a payment. What is left stays on the code.'**
  String get voucherHelp;

  /// No description provided for @voucherNone.
  ///
  /// In en, this message translates to:
  /// **'No gift vouchers yet.'**
  String get voucherNone;

  /// No description provided for @voucherSell.
  ///
  /// In en, this message translates to:
  /// **'Sell a gift voucher'**
  String get voucherSell;

  /// No description provided for @voucherSellButton.
  ///
  /// In en, this message translates to:
  /// **'Sell voucher'**
  String get voucherSellButton;

  /// No description provided for @voucherExpired.
  ///
  /// In en, this message translates to:
  /// **'This voucher has expired.'**
  String get voucherExpired;

  /// No description provided for @voucherValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get voucherValue;

  /// No description provided for @voucherPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get voucherPaidBy;

  /// No description provided for @voucherLasts.
  ///
  /// In en, this message translates to:
  /// **'Can be used for'**
  String get voucherLasts;

  /// No description provided for @voucherNoExpiry.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get voucherNoExpiry;

  /// No description provided for @voucherNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional), like who it is for'**
  String get voucherNote;

  /// No description provided for @voucherReferenceNeeded.
  ///
  /// In en, this message translates to:
  /// **'Enter the payment reference.'**
  String get voucherReferenceNeeded;

  /// No description provided for @voucherSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get voucherSend;

  /// No description provided for @voucherCode.
  ///
  /// In en, this message translates to:
  /// **'Gift voucher code'**
  String get voucherCode;

  /// No description provided for @voucherCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Type or scan the code on the voucher.'**
  String get voucherCodeHelp;

  /// No description provided for @voucherNotFound.
  ///
  /// In en, this message translates to:
  /// **'No voucher with this code.'**
  String get voucherNotFound;

  /// No description provided for @voucherUsedUp.
  ///
  /// In en, this message translates to:
  /// **'Nothing is left on this voucher.'**
  String get voucherUsedUp;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @ordersNone.
  ///
  /// In en, this message translates to:
  /// **'No open orders. Sales with prep items get a number here.'**
  String get ordersNone;

  /// No description provided for @orderNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get orderNew;

  /// No description provided for @orderPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get orderPreparing;

  /// No description provided for @orderReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get orderReady;

  /// No description provided for @orderCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get orderCollected;

  /// No description provided for @orderMarkCollected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get orderMarkCollected;

  /// No description provided for @orderPrintTicket.
  ///
  /// In en, this message translates to:
  /// **'Print kitchen ticket'**
  String get orderPrintTicket;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get orderNumberLabel;

  /// No description provided for @settingsGroupOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders and screens'**
  String get settingsGroupOrders;

  /// No description provided for @settingsOrderNumbers.
  ///
  /// In en, this message translates to:
  /// **'Order numbers'**
  String get settingsOrderNumbers;

  /// No description provided for @settingsOrderNumbersHelp.
  ///
  /// In en, this message translates to:
  /// **'Sales with prep items get a number like A23, a kitchen ticket and a place on the Orders board.'**
  String get settingsOrderNumbersHelp;

  /// No description provided for @settingsOrderPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order letter'**
  String get settingsOrderPrefix;

  /// No description provided for @settingsOrderPrep.
  ///
  /// In en, this message translates to:
  /// **'Items that need prep'**
  String get settingsOrderPrep;

  /// No description provided for @settingsOrderPrepHelp.
  ///
  /// In en, this message translates to:
  /// **'Like milkshakes and waffles. Nothing picked means everything.'**
  String get settingsOrderPrepHelp;

  /// No description provided for @kitchenPrinterTitle.
  ///
  /// In en, this message translates to:
  /// **'Kitchen printer'**
  String get kitchenPrinterTitle;

  /// No description provided for @kitchenPrinterHelp.
  ///
  /// In en, this message translates to:
  /// **'Kitchen tickets print here.'**
  String get kitchenPrinterHelp;

  /// No description provided for @kitchenPrinterSame.
  ///
  /// In en, this message translates to:
  /// **'The receipt printer'**
  String get kitchenPrinterSame;

  /// No description provided for @settingsScreens.
  ///
  /// In en, this message translates to:
  /// **'Screens on other devices'**
  String get settingsScreens;

  /// No description provided for @settingsScreensHelp.
  ///
  /// In en, this message translates to:
  /// **'A customer display, a prep screen and Now serving, in the browser of a tablet, TV or second monitor on the same Wi-Fi.'**
  String get settingsScreensHelp;

  /// No description provided for @screensTitle.
  ///
  /// In en, this message translates to:
  /// **'Open on a tablet or TV'**
  String get screensTitle;

  /// No description provided for @screensHelp.
  ///
  /// In en, this message translates to:
  /// **'Scan a code with the tablet or type its link into the browser. Keep the links to yourself: anyone with one on this Wi-Fi can open it.'**
  String get screensHelp;

  /// No description provided for @screensNetwork.
  ///
  /// In en, this message translates to:
  /// **'This device on'**
  String get screensNetwork;

  /// No description provided for @screensNotRunning.
  ///
  /// In en, this message translates to:
  /// **'The screens are not running. Turn them off and on again, or another app may be using the port.'**
  String get screensNotRunning;

  /// No description provided for @screensNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'This device is not on a network. Connect it to the shop Wi-Fi.'**
  String get screensNoNetwork;

  /// No description provided for @screensCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer display'**
  String get screensCustomer;

  /// No description provided for @screensCustomerHelp.
  ///
  /// In en, this message translates to:
  /// **'Faces the customer: the cart, the total, the MoMo number and QR code, then thank you and change.'**
  String get screensCustomerHelp;

  /// No description provided for @screensPrep.
  ///
  /// In en, this message translates to:
  /// **'Prep screen'**
  String get screensPrep;

  /// No description provided for @screensPrepHelp.
  ///
  /// In en, this message translates to:
  /// **'For whoever makes the orders: New, Preparing, Ready, with buttons.'**
  String get screensPrepHelp;

  /// No description provided for @screensServing.
  ///
  /// In en, this message translates to:
  /// **'Now serving'**
  String get screensServing;

  /// No description provided for @screensServingHelp.
  ///
  /// In en, this message translates to:
  /// **'Order numbers being prepared and ready to collect, for a TV.'**
  String get screensServingHelp;

  /// No description provided for @screensNewLinks.
  ///
  /// In en, this message translates to:
  /// **'New links'**
  String get screensNewLinks;

  /// No description provided for @screensNewLinksDone.
  ///
  /// In en, this message translates to:
  /// **'New links made. The old ones no longer work.'**
  String get screensNewLinksDone;

  /// No description provided for @auditBarcodesGenerated.
  ///
  /// In en, this message translates to:
  /// **'Barcodes made'**
  String get auditBarcodesGenerated;

  /// No description provided for @labelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsTitle;

  /// No description provided for @labelsHelp.
  ///
  /// In en, this message translates to:
  /// **'How many labels for each product: name, price and barcode.'**
  String get labelsHelp;

  /// No description provided for @labelsSheet.
  ///
  /// In en, this message translates to:
  /// **'A4 sheet (24)'**
  String get labelsSheet;

  /// No description provided for @labelsRoll.
  ///
  /// In en, this message translates to:
  /// **'Label roll 50 × 30'**
  String get labelsRoll;

  /// No description provided for @labelsReceiptPrinter.
  ///
  /// In en, this message translates to:
  /// **'Receipt printer'**
  String get labelsReceiptPrinter;

  /// No description provided for @labelsNoBarcode.
  ///
  /// In en, this message translates to:
  /// **'no barcode'**
  String get labelsNoBarcode;

  /// No description provided for @labelsMakeBarcodes.
  ///
  /// In en, this message translates to:
  /// **'Make barcodes for products'**
  String get labelsMakeBarcodes;

  /// No description provided for @labelsForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Labels for this delivery?'**
  String get labelsForDelivery;

  /// No description provided for @auditPurchaseOrderSaved.
  ///
  /// In en, this message translates to:
  /// **'Purchase order'**
  String get auditPurchaseOrderSaved;

  /// No description provided for @auditStockProduced.
  ///
  /// In en, this message translates to:
  /// **'Stock made'**
  String get auditStockProduced;

  /// No description provided for @moveProduction.
  ///
  /// In en, this message translates to:
  /// **'Made here'**
  String get moveProduction;

  /// No description provided for @notifyExpiring.
  ///
  /// In en, this message translates to:
  /// **'Stock about to expire'**
  String get notifyExpiring;

  /// No description provided for @stockTracksExpiry.
  ///
  /// In en, this message translates to:
  /// **'Batches and expiry dates'**
  String get stockTracksExpiry;

  /// No description provided for @stockTracksExpiryHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask for the batch and expiry date when it comes in, like milk and ice cream base.'**
  String get stockTracksExpiryHelp;

  /// No description provided for @receiveBatchNo.
  ///
  /// In en, this message translates to:
  /// **'Batch'**
  String get receiveBatchNo;

  /// No description provided for @receiveExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get receiveExpiry;

  /// No description provided for @expiryTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiryTitle;

  /// No description provided for @expiryNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing in stock expires in the next 30 days.'**
  String get expiryNone;

  /// No description provided for @expiryBatches.
  ///
  /// In en, this message translates to:
  /// **'Batches in stock'**
  String get expiryBatches;

  /// No description provided for @expiryNoBatches.
  ///
  /// In en, this message translates to:
  /// **'No batches in stock.'**
  String get expiryNoBatches;

  /// No description provided for @expiryNoDate.
  ///
  /// In en, this message translates to:
  /// **'No expiry date'**
  String get expiryNoDate;

  /// No description provided for @poTab.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get poTab;

  /// No description provided for @poNone.
  ///
  /// In en, this message translates to:
  /// **'No purchase orders yet.'**
  String get poNone;

  /// No description provided for @poNew.
  ///
  /// In en, this message translates to:
  /// **'New order'**
  String get poNew;

  /// No description provided for @poCreate.
  ///
  /// In en, this message translates to:
  /// **'Create order'**
  String get poCreate;

  /// No description provided for @poOpen.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get poOpen;

  /// No description provided for @poPartial.
  ///
  /// In en, this message translates to:
  /// **'Part delivered'**
  String get poPartial;

  /// No description provided for @poReceived.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get poReceived;

  /// No description provided for @poCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get poCancelled;

  /// No description provided for @poNeededByPick.
  ///
  /// In en, this message translates to:
  /// **'Needed by'**
  String get poNeededByPick;

  /// No description provided for @poCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get poCancel;

  /// No description provided for @poSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get poSend;

  /// No description provided for @poReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive delivery'**
  String get poReceive;

  /// No description provided for @poPickSupplier.
  ///
  /// In en, this message translates to:
  /// **'Choose the supplier.'**
  String get poPickSupplier;

  /// No description provided for @poAddItems.
  ///
  /// In en, this message translates to:
  /// **'Add what to order.'**
  String get poAddItems;

  /// No description provided for @poSuggestHelp.
  ///
  /// In en, this message translates to:
  /// **'Their items that are low come in at the usual order.'**
  String get poSuggestHelp;

  /// No description provided for @poReason.
  ///
  /// In en, this message translates to:
  /// **'Purchase orders spend the shop money.'**
  String get poReason;

  /// No description provided for @produceSetUp.
  ///
  /// In en, this message translates to:
  /// **'Made here? Set its recipe'**
  String get produceSetUp;

  /// No description provided for @produceMadeHere.
  ///
  /// In en, this message translates to:
  /// **'Made here'**
  String get produceMadeHere;

  /// No description provided for @produceRecord.
  ///
  /// In en, this message translates to:
  /// **'Record a batch made'**
  String get produceRecord;

  /// No description provided for @produceRecipeHelp.
  ///
  /// In en, this message translates to:
  /// **'For one batch: how much it makes and what goes in. Making it takes the ingredients off stock and adds what was made, at what they cost.'**
  String get produceRecipeHelp;

  /// No description provided for @produceOneBatchMakes.
  ///
  /// In en, this message translates to:
  /// **'One batch makes'**
  String get produceOneBatchMakes;

  /// No description provided for @produceIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients for one batch'**
  String get produceIngredients;

  /// No description provided for @produceYieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter how much one batch makes.'**
  String get produceYieldInvalid;

  /// No description provided for @produceNeedsIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add at least one ingredient.'**
  String get produceNeedsIngredients;

  /// No description provided for @produceStop.
  ///
  /// In en, this message translates to:
  /// **'Not made here'**
  String get produceStop;

  /// No description provided for @produceHowMuch.
  ///
  /// In en, this message translates to:
  /// **'How much was made'**
  String get produceHowMuch;

  /// No description provided for @produceUses.
  ///
  /// In en, this message translates to:
  /// **'This uses'**
  String get produceUses;

  /// No description provided for @badgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Badge and hours'**
  String get badgeTitle;

  /// No description provided for @badgeNone.
  ///
  /// In en, this message translates to:
  /// **'No sign-in badge'**
  String get badgeNone;

  /// No description provided for @badgeHas.
  ///
  /// In en, this message translates to:
  /// **'Has a sign-in badge'**
  String get badgeHas;

  /// No description provided for @badgeHelp.
  ///
  /// In en, this message translates to:
  /// **'A QR code to scan at sign-in, instead of typing the staff number. The PIN is still needed.'**
  String get badgeHelp;

  /// No description provided for @badgeMake.
  ///
  /// In en, this message translates to:
  /// **'Make a badge'**
  String get badgeMake;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New badge'**
  String get badgeNew;

  /// No description provided for @badgeRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove the badge'**
  String get badgeRemove;

  /// No description provided for @badgeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Badge removed. It no longer works.'**
  String get badgeRemoved;

  /// No description provided for @badgeUnknown.
  ///
  /// In en, this message translates to:
  /// **'That badge is not known. Type your staff number instead.'**
  String get badgeUnknown;

  /// No description provided for @workHours.
  ///
  /// In en, this message translates to:
  /// **'Usual hours'**
  String get workHours;

  /// No description provided for @workHoursHelp.
  ///
  /// In en, this message translates to:
  /// **'For late arrivals and early leaves on the timesheet.'**
  String get workHoursHelp;

  /// No description provided for @workStarts.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get workStarts;

  /// No description provided for @workEnds.
  ///
  /// In en, this message translates to:
  /// **'Finishes at'**
  String get workEnds;

  /// No description provided for @clockIn.
  ///
  /// In en, this message translates to:
  /// **'Clock in'**
  String get clockIn;

  /// No description provided for @clockOut.
  ///
  /// In en, this message translates to:
  /// **'Clock out'**
  String get clockOut;

  /// No description provided for @clockStartBreak.
  ///
  /// In en, this message translates to:
  /// **'Start a break'**
  String get clockStartBreak;

  /// No description provided for @clockEndBreak.
  ///
  /// In en, this message translates to:
  /// **'End the break'**
  String get clockEndBreak;

  /// No description provided for @clockedIn.
  ///
  /// In en, this message translates to:
  /// **'Clocked in.'**
  String get clockedIn;

  /// No description provided for @clockedOut.
  ///
  /// In en, this message translates to:
  /// **'Clocked out.'**
  String get clockedOut;

  /// No description provided for @clockInToSellTitle.
  ///
  /// In en, this message translates to:
  /// **'Clock in to sell'**
  String get clockInToSellTitle;

  /// No description provided for @clockInToSellBody.
  ///
  /// In en, this message translates to:
  /// **'The shop asks staff to clock in before selling. Clock in now?'**
  String get clockInToSellBody;

  /// No description provided for @timeTab.
  ///
  /// In en, this message translates to:
  /// **'Timesheets'**
  String get timeTab;

  /// No description provided for @timeNone.
  ///
  /// In en, this message translates to:
  /// **'No one clocked in during these dates.'**
  String get timeNone;

  /// No description provided for @timeWorked.
  ///
  /// In en, this message translates to:
  /// **'Hours worked'**
  String get timeWorked;

  /// No description provided for @timeStillIn.
  ///
  /// In en, this message translates to:
  /// **'still in'**
  String get timeStillIn;

  /// No description provided for @reportItems.
  ///
  /// In en, this message translates to:
  /// **'Items sold'**
  String get reportItems;

  /// No description provided for @reportCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get reportCommission;

  /// No description provided for @settingsClockInToSell.
  ///
  /// In en, this message translates to:
  /// **'Clock in before selling'**
  String get settingsClockInToSell;

  /// No description provided for @settingsClockInToSellHelp.
  ///
  /// In en, this message translates to:
  /// **'Staff clock in and out from their name at the top. Timesheets are in Staff.'**
  String get settingsClockInToSellHelp;

  /// No description provided for @settingsStartDayToSell.
  ///
  /// In en, this message translates to:
  /// **'Start the day before selling'**
  String get settingsStartDayToSell;

  /// No description provided for @settingsStartDayToSellHelp.
  ///
  /// In en, this message translates to:
  /// **'Each till counts its float into the drawer before its first sale. Close day then checks the cash against it.'**
  String get settingsStartDayToSellHelp;

  /// No description provided for @clockOnBreakTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on a break'**
  String get clockOnBreakTitle;

  /// No description provided for @clockOnBreakBody.
  ///
  /// In en, this message translates to:
  /// **'End your break to sell?'**
  String get clockOnBreakBody;

  /// No description provided for @closeDayNotStarted.
  ///
  /// In en, this message translates to:
  /// **'The day was not started on this till, so the float was not counted before the first sale. Type it below.'**
  String get closeDayNotStarted;

  /// No description provided for @closeStillClockedIn.
  ///
  /// In en, this message translates to:
  /// **'Still clocked in on this till: {names}. If they have gone home, correct their hours in Staff, Timesheets.'**
  String closeStillClockedIn(String names);

  /// No description provided for @timeCorrectTitle.
  ///
  /// In en, this message translates to:
  /// **'Correct the hours'**
  String get timeCorrectTitle;

  /// No description provided for @timeCorrectApproval.
  ///
  /// In en, this message translates to:
  /// **'Correct someone\'s hours.'**
  String get timeCorrectApproval;

  /// No description provided for @timeCorrectHelp.
  ///
  /// In en, this message translates to:
  /// **'For a forgotten clock out, or a time typed wrong. The change and the reason go in the activity log.'**
  String get timeCorrectHelp;

  /// No description provided for @timeClockInAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked in'**
  String get timeClockInAt;

  /// No description provided for @timeClockOutAt.
  ///
  /// In en, this message translates to:
  /// **'Clocked out'**
  String get timeClockOutAt;

  /// No description provided for @timeStillClockedIn.
  ///
  /// In en, this message translates to:
  /// **'Still clocked in'**
  String get timeStillClockedIn;

  /// No description provided for @timeBreakMinutes.
  ///
  /// In en, this message translates to:
  /// **'Break (minutes)'**
  String get timeBreakMinutes;

  /// No description provided for @timeReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get timeReason;

  /// No description provided for @timeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'For example: forgot to clock out'**
  String get timeReasonHint;

  /// No description provided for @timeCorrected.
  ///
  /// In en, this message translates to:
  /// **'Hours corrected.'**
  String get timeCorrected;

  /// No description provided for @timeTooLong.
  ///
  /// In en, this message translates to:
  /// **'Over 16 hours: was the clock out forgotten?'**
  String get timeTooLong;

  /// No description provided for @timeCorrectedNote.
  ///
  /// In en, this message translates to:
  /// **'Corrected: {reason}'**
  String timeCorrectedNote(String reason);

  /// No description provided for @settingsCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get settingsCommission;

  /// No description provided for @settingsCommissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Worked out per person in Reports, Staff, for any dates.'**
  String get settingsCommissionHelp;

  /// No description provided for @commissionPercentChoice.
  ///
  /// In en, this message translates to:
  /// **'A percent of their sales'**
  String get commissionPercentChoice;

  /// No description provided for @commissionPerProduct.
  ///
  /// In en, this message translates to:
  /// **'An amount per product'**
  String get commissionPerProduct;

  /// No description provided for @editorCommission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get editorCommission;

  /// No description provided for @editorCommissionPer.
  ///
  /// In en, this message translates to:
  /// **'Commission per one sold'**
  String get editorCommissionPer;

  /// No description provided for @editorCommissionHelp.
  ///
  /// In en, this message translates to:
  /// **'Paid to whoever sells it. Leave empty for none.'**
  String get editorCommissionHelp;

  /// No description provided for @commandTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search everything (Ctrl+K)'**
  String get commandTooltip;

  /// No description provided for @commandHint.
  ///
  /// In en, this message translates to:
  /// **'Products, customers, sale numbers, MoMo references, actions...'**
  String get commandHint;

  /// No description provided for @commandNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get commandNothing;

  /// No description provided for @commandActions.
  ///
  /// In en, this message translates to:
  /// **'Go to'**
  String get commandActions;

  /// No description provided for @commandSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get commandSales;

  /// No description provided for @commandOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commandOpen;

  /// No description provided for @commandAddToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get commandAddToCart;

  /// No description provided for @commandEditProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get commandEditProduct;

  /// No description provided for @commandAddToSale.
  ///
  /// In en, this message translates to:
  /// **'Add to the sale'**
  String get commandAddToSale;

  /// No description provided for @commandOpenCustomer.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commandOpenCustomer;

  /// No description provided for @commandReprint.
  ///
  /// In en, this message translates to:
  /// **'Reprint'**
  String get commandReprint;

  /// No description provided for @commandOpenProfile.
  ///
  /// In en, this message translates to:
  /// **'Open profile'**
  String get commandOpenProfile;

  /// No description provided for @commandNewProduct.
  ///
  /// In en, this message translates to:
  /// **'New product'**
  String get commandNewProduct;

  /// No description provided for @commandAddExpense.
  ///
  /// In en, this message translates to:
  /// **'Add an expense'**
  String get commandAddExpense;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worth knowing'**
  String get insightsTitle;

  /// No description provided for @insightOrderMore.
  ///
  /// In en, this message translates to:
  /// **'Order more'**
  String get insightOrderMore;

  /// No description provided for @insightSeeTimes.
  ///
  /// In en, this message translates to:
  /// **'See the times'**
  String get insightSeeTimes;

  /// No description provided for @insightReviewPrice.
  ///
  /// In en, this message translates to:
  /// **'Review price'**
  String get insightReviewPrice;

  /// No description provided for @insightSendReminders.
  ///
  /// In en, this message translates to:
  /// **'Send reminders'**
  String get insightSendReminders;

  /// No description provided for @insightSeeStaff.
  ///
  /// In en, this message translates to:
  /// **'See staff'**
  String get insightSeeStaff;

  /// No description provided for @insightDismiss.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get insightDismiss;

  /// No description provided for @insightTurnOff.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show these'**
  String get insightTurnOff;

  /// No description provided for @summaryProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit before expenses'**
  String get summaryProfitLabel;

  /// No description provided for @summaryCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get summaryCash;

  /// No description provided for @summaryTopLabel.
  ///
  /// In en, this message translates to:
  /// **'Top product'**
  String get summaryTopLabel;

  /// No description provided for @summaryShare.
  ///
  /// In en, this message translates to:
  /// **'Share the summary'**
  String get summaryShare;

  /// No description provided for @trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Training mode'**
  String get trainingTitle;

  /// No description provided for @trainingHelp.
  ///
  /// In en, this message translates to:
  /// **'Practise on a sample shop or a copy of this one. Nothing reaches the real sales, stock, reports or backups.'**
  String get trainingHelp;

  /// No description provided for @trainingBand.
  ///
  /// In en, this message translates to:
  /// **'TRAINING: NOT REAL SALES'**
  String get trainingBand;

  /// No description provided for @trainingWith.
  ///
  /// In en, this message translates to:
  /// **'Practise with'**
  String get trainingWith;

  /// No description provided for @trainingSample.
  ///
  /// In en, this message translates to:
  /// **'A sample shop: made-up products, stock, suppliers, customers and a month of sales'**
  String get trainingSample;

  /// No description provided for @trainingCopy.
  ///
  /// In en, this message translates to:
  /// **'A copy of this shop: its own products and sales as they are now'**
  String get trainingCopy;

  /// No description provided for @trainingPreparing.
  ///
  /// In en, this message translates to:
  /// **'Getting the practice shop ready…'**
  String get trainingPreparing;

  /// No description provided for @trainingStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave training mode?'**
  String get trainingStopTitle;

  /// No description provided for @trainingStopBody.
  ///
  /// In en, this message translates to:
  /// **'Aby restarts on the real shop. The practice stays in the copy until it is reset.'**
  String get trainingStopBody;

  /// No description provided for @trainingStop.
  ///
  /// In en, this message translates to:
  /// **'Leave training'**
  String get trainingStop;

  /// No description provided for @trainingReset.
  ///
  /// In en, this message translates to:
  /// **'Reset training data'**
  String get trainingReset;

  /// No description provided for @trainingResetHelp.
  ///
  /// In en, this message translates to:
  /// **'Throw the practice away and start again, from a fresh sample shop or the real shop as it is now.'**
  String get trainingResetHelp;

  /// No description provided for @trainingNoBackups.
  ///
  /// In en, this message translates to:
  /// **'Backups are for the real shop. Leave training mode first.'**
  String get trainingNoBackups;

  /// No description provided for @setupShopType.
  ///
  /// In en, this message translates to:
  /// **'What kind of shop?'**
  String get setupShopType;

  /// No description provided for @shopTypeIceCream.
  ///
  /// In en, this message translates to:
  /// **'Ice cream / cold store'**
  String get shopTypeIceCream;

  /// No description provided for @shopTypeProvision.
  ///
  /// In en, this message translates to:
  /// **'Provision shop'**
  String get shopTypeProvision;

  /// No description provided for @shopTypeChopBar.
  ///
  /// In en, this message translates to:
  /// **'Chop bar / restaurant'**
  String get shopTypeChopBar;

  /// No description provided for @shopTypePharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy shop'**
  String get shopTypePharmacy;

  /// No description provided for @shopTypeSalon.
  ///
  /// In en, this message translates to:
  /// **'Salon / barber'**
  String get shopTypeSalon;

  /// No description provided for @shopTypePhones.
  ///
  /// In en, this message translates to:
  /// **'Phones and accessories'**
  String get shopTypePhones;

  /// No description provided for @shopTypeBoutique.
  ///
  /// In en, this message translates to:
  /// **'Boutique'**
  String get shopTypeBoutique;

  /// No description provided for @shopTypeBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building materials'**
  String get shopTypeBuilding;

  /// No description provided for @shopTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get shopTypeOther;

  /// No description provided for @settingsGroupFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get settingsGroupFeatures;

  /// No description provided for @settingsFeaturesHelp.
  ///
  /// In en, this message translates to:
  /// **'Chosen at setup. Every feature below can be switched on or off.'**
  String get settingsFeaturesHelp;

  /// No description provided for @settingsExpiryByDefault.
  ///
  /// In en, this message translates to:
  /// **'Expiry dates for new stock'**
  String get settingsExpiryByDefault;

  /// No description provided for @settingsExpiryByDefaultHelp.
  ///
  /// In en, this message translates to:
  /// **'New stock items ask for batches and expiry dates when they come in.'**
  String get settingsExpiryByDefaultHelp;

  /// No description provided for @hubTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices and hub'**
  String get hubTitle;

  /// No description provided for @hubSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Tills on the same Wi-Fi share sales, stock and customers, without internet.'**
  String get hubSettingsHelp;

  /// No description provided for @hubRoleNone.
  ///
  /// In en, this message translates to:
  /// **'Working alone'**
  String get hubRoleNone;

  /// No description provided for @hubRoleHub.
  ///
  /// In en, this message translates to:
  /// **'This device is the hub'**
  String get hubRoleHub;

  /// No description provided for @hubRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Connected to the hub'**
  String get hubRoleMember;

  /// No description provided for @hubNoneHelp.
  ///
  /// In en, this message translates to:
  /// **'Make one device the hub (the main till or a back-office PC), then join the others to it. Each device keeps selling when the Wi-Fi drops and catches up later.'**
  String get hubNoneHelp;

  /// No description provided for @hubHubHelp.
  ///
  /// In en, this message translates to:
  /// **'Other devices sync through this one. Keep it on and on the shop Wi-Fi during trading.'**
  String get hubHubHelp;

  /// No description provided for @hubMemberHelp.
  ///
  /// In en, this message translates to:
  /// **'Sales and changes here go to the hub every few seconds, and changes from the other tills come back.'**
  String get hubMemberHelp;

  /// No description provided for @hubApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Manage this shop\'s devices.'**
  String get hubApprovalReason;

  /// No description provided for @hubBecome.
  ///
  /// In en, this message translates to:
  /// **'Make this the hub'**
  String get hubBecome;

  /// No description provided for @hubBecomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Make this device the hub?'**
  String get hubBecomeTitle;

  /// No description provided for @hubBecomeBody.
  ///
  /// In en, this message translates to:
  /// **'The other devices will join this one and send it their sales. Its menu, stock and customers become the shop data that others merge into.'**
  String get hubBecomeBody;

  /// No description provided for @hubJoin.
  ///
  /// In en, this message translates to:
  /// **'Join a hub'**
  String get hubJoin;

  /// No description provided for @hubJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the hub?'**
  String get hubJoinTitle;

  /// No description provided for @hubJoinBody.
  ///
  /// In en, this message translates to:
  /// **'Everything on this device is merged into the hub, and the hub data comes here. This device takes the shop settings from the hub. Products or customers on both may then appear twice and can be tidied up.'**
  String get hubJoinBody;

  /// No description provided for @hubJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined the hub. Syncing now.'**
  String get hubJoined;

  /// No description provided for @hubAddress.
  ///
  /// In en, this message translates to:
  /// **'Hub address'**
  String get hubAddress;

  /// No description provided for @hubAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown on the hub under Add a device, for example 192.168.1.20:8787'**
  String get hubAddressHelp;

  /// No description provided for @hubCode.
  ///
  /// In en, this message translates to:
  /// **'Pairing code'**
  String get hubCode;

  /// No description provided for @hubCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'The 8 letters the hub shows under Add a device'**
  String get hubCodeHelp;

  /// No description provided for @hubNotACode.
  ///
  /// In en, this message translates to:
  /// **'That is not an Aby pairing code. Scan the code on the hub under Add a device.'**
  String get hubNotACode;

  /// No description provided for @hubAddDevice.
  ///
  /// In en, this message translates to:
  /// **'Add a device'**
  String get hubAddDevice;

  /// No description provided for @hubAddHelp.
  ///
  /// In en, this message translates to:
  /// **'On a new device, tap Join the shop\'s hub on its first screen (or, if it is already set up, Settings, This device, Devices and hub, then Join a hub) and type this code. It finds this hub on the Wi-Fi by itself.'**
  String get hubAddHelp;

  /// No description provided for @hubPaired.
  ///
  /// In en, this message translates to:
  /// **'Device added. It is syncing now.'**
  String get hubPaired;

  /// No description provided for @hubSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get hubSyncNow;

  /// No description provided for @hubNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get hubNeverSynced;

  /// No description provided for @hubStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the hub'**
  String get hubStop;

  /// No description provided for @hubStopTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop being the hub?'**
  String get hubStopTitle;

  /// No description provided for @hubStopBody.
  ///
  /// In en, this message translates to:
  /// **'The other devices stop syncing until a hub is set up again. Nothing is deleted.'**
  String get hubStopBody;

  /// No description provided for @hubLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave the hub'**
  String get hubLeave;

  /// No description provided for @hubLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the hub?'**
  String get hubLeaveTitle;

  /// No description provided for @hubLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'This device stops syncing and works alone. It keeps all its data.'**
  String get hubLeaveBody;

  /// No description provided for @hubDevices.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get hubDevices;

  /// No description provided for @hubNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices yet. Use Add a device on each till.'**
  String get hubNoDevices;

  /// No description provided for @hubDeviceTill.
  ///
  /// In en, this message translates to:
  /// **'Till'**
  String get hubDeviceTill;

  /// No description provided for @hubDeviceKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get hubDeviceKitchen;

  /// No description provided for @hubDeviceDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get hubDeviceDisplay;

  /// No description provided for @hubDeviceOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s device'**
  String get hubDeviceOwner;

  /// No description provided for @hubRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get hubRename;

  /// No description provided for @hubSetRole.
  ///
  /// In en, this message translates to:
  /// **'What is it used for?'**
  String get hubSetRole;

  /// No description provided for @hubRevoke.
  ///
  /// In en, this message translates to:
  /// **'Remove from the hub'**
  String get hubRevoke;

  /// No description provided for @hubRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'Use this for a lost or stolen device. It can no longer sync. What it already sent is kept.'**
  String get hubRevokeBody;

  /// No description provided for @hubRevoked.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get hubRevoked;

  /// No description provided for @hubDuplicates.
  ///
  /// In en, this message translates to:
  /// **'May be duplicates'**
  String get hubDuplicates;

  /// No description provided for @hubDuplicatesHelp.
  ///
  /// In en, this message translates to:
  /// **'These names appear more than once after merging. Check them and delete or rename the extra ones.'**
  String get hubDuplicatesHelp;

  /// No description provided for @hubKindProduct.
  ///
  /// In en, this message translates to:
  /// **'product'**
  String get hubKindProduct;

  /// No description provided for @hubKindCustomer.
  ///
  /// In en, this message translates to:
  /// **'customer'**
  String get hubKindCustomer;

  /// No description provided for @hubKindStaff.
  ///
  /// In en, this message translates to:
  /// **'staff'**
  String get hubKindStaff;

  /// No description provided for @hubErrAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This device is already part of a hub.'**
  String get hubErrAlreadyLinked;

  /// No description provided for @hubErrNoCode.
  ///
  /// In en, this message translates to:
  /// **'No pairing code is on offer. Tap Add a device on the hub.'**
  String get hubErrNoCode;

  /// No description provided for @hubErrTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong tries. Show a new code on the hub.'**
  String get hubErrTooManyTries;

  /// No description provided for @hubErrWrongCode.
  ///
  /// In en, this message translates to:
  /// **'That pairing code is not right.'**
  String get hubErrWrongCode;

  /// No description provided for @hubErrNotPaired.
  ///
  /// In en, this message translates to:
  /// **'This device is not paired with the hub. Leave and join again.'**
  String get hubErrNotPaired;

  /// No description provided for @hubErrRevoked.
  ///
  /// In en, this message translates to:
  /// **'This device was removed from the hub.'**
  String get hubErrRevoked;

  /// No description provided for @hubErrUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the hub. Check both devices are on the same Wi-Fi and the hub is on.'**
  String get hubErrUnreachable;

  /// No description provided for @hubErrRefused.
  ///
  /// In en, this message translates to:
  /// **'The hub refused the request.'**
  String get hubErrRefused;

  /// No description provided for @statusHubUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the hub.'**
  String get statusHubUnreachable;

  /// No description provided for @hubTraining.
  ///
  /// In en, this message translates to:
  /// **'Training mode is on: this copy does not sync. Leave training mode to use the hub.'**
  String get hubTraining;

  /// No description provided for @moveTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Sent to another branch'**
  String get moveTransferOut;

  /// No description provided for @moveTransferIn.
  ///
  /// In en, this message translates to:
  /// **'From another branch'**
  String get moveTransferIn;

  /// No description provided for @auditBranchSaved.
  ///
  /// In en, this message translates to:
  /// **'Branch saved'**
  String get auditBranchSaved;

  /// No description provided for @auditDeviceBranchChanged.
  ///
  /// In en, this message translates to:
  /// **'Device moved to a branch'**
  String get auditDeviceBranchChanged;

  /// No description provided for @auditTransferSent.
  ///
  /// In en, this message translates to:
  /// **'Stock transfer sent'**
  String get auditTransferSent;

  /// No description provided for @auditTransferReceived.
  ///
  /// In en, this message translates to:
  /// **'Stock transfer received'**
  String get auditTransferReceived;

  /// No description provided for @auditTransferCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stock transfer called back'**
  String get auditTransferCancelled;

  /// No description provided for @auditBranchDataMerged.
  ///
  /// In en, this message translates to:
  /// **'Branch data brought in'**
  String get auditBranchDataMerged;

  /// No description provided for @branchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesTitle;

  /// No description provided for @branchesSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'More than one shop location, each with its own stock.'**
  String get branchesSettingsHelp;

  /// No description provided for @branchesHelp.
  ///
  /// In en, this message translates to:
  /// **'Each branch has its own stock and its own devices. Reports show one branch or all of them. Devices on the same Wi-Fi sync through the hub; between branches far apart, carry the data in a file, or later through Aby Cloud.'**
  String get branchesHelp;

  /// No description provided for @branchThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device is at'**
  String get branchThisDevice;

  /// No description provided for @branchThisDeviceHelp.
  ///
  /// In en, this message translates to:
  /// **'Its sales and stock count for this branch.'**
  String get branchThisDeviceHelp;

  /// No description provided for @branchMoveBody.
  ///
  /// In en, this message translates to:
  /// **'Its sales and stock movements, the earlier ones too, will count for that branch.'**
  String get branchMoveBody;

  /// No description provided for @branchMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get branchMove;

  /// No description provided for @branchAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a branch'**
  String get branchAdd;

  /// No description provided for @branchesList.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get branchesList;

  /// No description provided for @branchMain.
  ///
  /// In en, this message translates to:
  /// **'Main branch'**
  String get branchMain;

  /// No description provided for @branchClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get branchClosed;

  /// No description provided for @branchClose.
  ///
  /// In en, this message translates to:
  /// **'Close branch'**
  String get branchClose;

  /// No description provided for @branchReopen.
  ///
  /// In en, this message translates to:
  /// **'Reopen branch'**
  String get branchReopen;

  /// No description provided for @branchName.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchName;

  /// No description provided for @branchAddress.
  ///
  /// In en, this message translates to:
  /// **'Address or landmark'**
  String get branchAddress;

  /// No description provided for @branchPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get branchPhone;

  /// No description provided for @branchFiles.
  ///
  /// In en, this message translates to:
  /// **'Data between branches'**
  String get branchFiles;

  /// No description provided for @branchSendData.
  ///
  /// In en, this message translates to:
  /// **'Send this branch data'**
  String get branchSendData;

  /// No description provided for @branchSendDataHelp.
  ///
  /// In en, this message translates to:
  /// **'Makes a backup file (with the backup password) to carry or send to the other branch.'**
  String get branchSendDataHelp;

  /// No description provided for @branchMerge.
  ///
  /// In en, this message translates to:
  /// **'Bring in a branch data file'**
  String get branchMerge;

  /// No description provided for @branchMergeHelp.
  ///
  /// In en, this message translates to:
  /// **'Adds the sales, stock and changes from another branch backup. Nothing here is replaced.'**
  String get branchMergeHelp;

  /// No description provided for @branchMergeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Bring this data in?'**
  String get branchMergeConfirmTitle;

  /// No description provided for @branchMerging.
  ///
  /// In en, this message translates to:
  /// **'Bringing the data in...'**
  String get branchMerging;

  /// No description provided for @branchAll.
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get branchAll;

  /// No description provided for @branchPick.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchPick;

  /// No description provided for @staffWorksAt.
  ///
  /// In en, this message translates to:
  /// **'Works at'**
  String get staffWorksAt;

  /// No description provided for @staffWorksAtHelp.
  ///
  /// In en, this message translates to:
  /// **'They can sign in only at this branch. Owners can sign in everywhere.'**
  String get staffWorksAtHelp;

  /// No description provided for @transfersTab.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get transfersTab;

  /// No description provided for @transferNew.
  ///
  /// In en, this message translates to:
  /// **'Send stock'**
  String get transferNew;

  /// No description provided for @transferNewHelp.
  ///
  /// In en, this message translates to:
  /// **'The stock leaves this branch now and shows as on its way until the other branch receives it.'**
  String get transferNewHelp;

  /// No description provided for @transferToBranch.
  ///
  /// In en, this message translates to:
  /// **'To branch'**
  String get transferToBranch;

  /// No description provided for @transferNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transferNote;

  /// No description provided for @transferSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get transferSend;

  /// No description provided for @transferInTransit.
  ///
  /// In en, this message translates to:
  /// **'On its way'**
  String get transferInTransit;

  /// No description provided for @transferReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get transferReceived;

  /// No description provided for @transferCancelled.
  ///
  /// In en, this message translates to:
  /// **'Called back'**
  String get transferCancelled;

  /// No description provided for @transferNone.
  ///
  /// In en, this message translates to:
  /// **'No transfers yet. Use Send stock to move stock to another branch.'**
  String get transferNone;

  /// No description provided for @transferDifferences.
  ///
  /// In en, this message translates to:
  /// **'differences'**
  String get transferDifferences;

  /// No description provided for @transferArrivedAll.
  ///
  /// In en, this message translates to:
  /// **'All arrived'**
  String get transferArrivedAll;

  /// No description provided for @transferCallBack.
  ///
  /// In en, this message translates to:
  /// **'Call back'**
  String get transferCallBack;

  /// No description provided for @transferCallBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Call this transfer back?'**
  String get transferCallBackTitle;

  /// No description provided for @transferCallBackBody.
  ///
  /// In en, this message translates to:
  /// **'The stock comes back into this branch. Do this only if it never left.'**
  String get transferCallBackBody;

  /// No description provided for @transferReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive'**
  String get transferReceive;

  /// No description provided for @transferReceiveHelp.
  ///
  /// In en, this message translates to:
  /// **'Count what arrived. Anything different from what was sent is flagged.'**
  String get transferReceiveHelp;

  /// No description provided for @transferReceivedAll.
  ///
  /// In en, this message translates to:
  /// **'Received. Everything arrived.'**
  String get transferReceivedAll;

  /// No description provided for @transferReceivedShort.
  ///
  /// In en, this message translates to:
  /// **'Received, with differences. They are in the activity log.'**
  String get transferReceivedShort;

  /// No description provided for @transferNoBranches.
  ///
  /// In en, this message translates to:
  /// **'Add another branch first, in Settings, Branches.'**
  String get transferNoBranches;

  /// No description provided for @pinMustBeDigits.
  ///
  /// In en, this message translates to:
  /// **'The PIN must be {count} digits.'**
  String pinMustBeDigits(int count);

  /// No description provided for @pinTooManyTriesMinutes.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait {minutes, plural, =1{1 minute} other{{minutes} minutes}}.'**
  String pinTooManyTriesMinutes(int minutes);

  /// No description provided for @pinTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait {seconds} seconds.'**
  String pinTooManyTries(int seconds);

  /// No description provided for @setupIntro.
  ///
  /// In en, this message translates to:
  /// **'You\'re the owner. Pick a {digits}-digit PIN to sign in and to approve things like voids. You can add staff later.'**
  String setupIntro(int digits);

  /// No description provided for @approvalNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs someone who can: {permission}'**
  String approvalNeeds(String permission);

  /// No description provided for @statusLast.
  ///
  /// In en, this message translates to:
  /// **'Last: {when}'**
  String statusLast(String when);

  /// No description provided for @statusSalesWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale saved on this device. Will sync when online.} other{{count} sales saved on this device. Will sync when online.}}'**
  String statusSalesWaiting(int count);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @voidConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Void sale {number}?'**
  String voidConfirmTitle(String number);

  /// No description provided for @voidConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{total} will come off today\'s takings and the items go back into stock. This cannot be undone.'**
  String voidConfirmBody(String total);

  /// No description provided for @voidApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Void sale {number}'**
  String voidApprovalReason(String number);

  /// No description provided for @voidDone.
  ///
  /// In en, this message translates to:
  /// **'Sale {number} voided.'**
  String voidDone(String number);

  /// No description provided for @staffAdded.
  ///
  /// In en, this message translates to:
  /// **'{name} added. Their staff number is {number}: they type it, then their PIN, to sign in.'**
  String staffAdded(String name, String number);

  /// No description provided for @staffPinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed for {name}.'**
  String staffPinChanged(String name);

  /// No description provided for @staffRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'Role changed for {name}.'**
  String staffRoleChanged(String name);

  /// No description provided for @staffDeactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} deactivated.'**
  String staffDeactivated(String name);

  /// No description provided for @staffReactivated.
  ///
  /// In en, this message translates to:
  /// **'{name} can sign in again.'**
  String staffReactivated(String name);

  /// No description provided for @staffYou.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String staffYou(String name);

  /// No description provided for @staffDeactivatedRole.
  ///
  /// In en, this message translates to:
  /// **'{role}, deactivated'**
  String staffDeactivatedRole(String role);

  /// No description provided for @staffNewPinFor.
  ///
  /// In en, this message translates to:
  /// **'New PIN for {name}'**
  String staffNewPinFor(String name);

  /// No description provided for @staffChangeRoleFor.
  ///
  /// In en, this message translates to:
  /// **'Role for {name}'**
  String staffChangeRoleFor(String name);

  /// No description provided for @staffDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate {name}?'**
  String staffDeactivateTitle(String name);

  /// No description provided for @rolesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String rolesDeleteTitle(String name);

  /// No description provided for @rolesDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted.'**
  String rolesDeleted(String name);

  /// No description provided for @rolesPeople.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nobody} =1{1 person} other{{count} people}}'**
  String rolesPeople(int count);

  /// No description provided for @rolesPermissionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 permission} other{{count} permissions}}'**
  String rolesPermissionCount(int count);

  /// No description provided for @activityApprovedBy.
  ///
  /// In en, this message translates to:
  /// **'approved by {name}'**
  String activityApprovedBy(String name);

  /// No description provided for @activityChainBroken.
  ///
  /// In en, this message translates to:
  /// **'Warning: the activity log was changed outside Aby, from entry {seq}. Keep this device as it is and check your backups.'**
  String activityChainBroken(int seq);

  /// No description provided for @settingsMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String settingsMinutes(int count);

  /// No description provided for @settingsDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String settingsDays(int count);

  /// No description provided for @backupPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least {count} characters.'**
  String backupPasswordTooShort(int count);

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'{shop} backup'**
  String backupShareSubject(String shop);

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This backup is from {shop}: {sales} sales, last sale {lastSale}. Everything on this device will be replaced. A copy of what is here now is kept first.'**
  String backupRestoreConfirmBody(String shop, int sales, String lastSale);

  /// No description provided for @profileInAbySince.
  ///
  /// In en, this message translates to:
  /// **'In Aby since {date}'**
  String profileInAbySince(String date);

  /// No description provided for @profileSalesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sales} =1{1 sale} other{{count} sales}}'**
  String profileSalesCount(int count);

  /// No description provided for @profileVoidsApproved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None approved for others} =1{1 approved for others} other{{count} approved for others}}'**
  String profileVoidsApproved(int count);

  /// No description provided for @profileClosesOver.
  ///
  /// In en, this message translates to:
  /// **'Over {amount} in total'**
  String profileClosesOver(String amount);

  /// No description provided for @profileClosesShort.
  ///
  /// In en, this message translates to:
  /// **'Short {amount} in total'**
  String profileClosesShort(String amount);

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'{years} years old'**
  String profileAge(int years);

  /// No description provided for @profileTenure.
  ///
  /// In en, this message translates to:
  /// **'{months, plural, =0{Less than a month} =1{1 month} other{{months} months}}'**
  String profileTenure(int months);

  /// No description provided for @tileFrom.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String tileFrom(String price);

  /// No description provided for @tileLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String tileLeft(int count);

  /// No description provided for @pickerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {price}'**
  String pickerAdd(String price);

  /// No description provided for @groupUpTo.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}'**
  String groupUpTo(int max);

  /// No description provided for @groupPickExactly.
  ///
  /// In en, this message translates to:
  /// **'Pick {count}'**
  String groupPickExactly(int count);

  /// No description provided for @groupPickAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Pick at least {count}'**
  String groupPickAtLeast(int count);

  /// No description provided for @groupPickBetween.
  ///
  /// In en, this message translates to:
  /// **'Pick {min} to {max}'**
  String groupPickBetween(int min, int max);

  /// No description provided for @productsVariantCount.
  ///
  /// In en, this message translates to:
  /// **'{count} prices'**
  String productsVariantCount(int count);

  /// No description provided for @productsMargin.
  ///
  /// In en, this message translates to:
  /// **'{percent}% margin'**
  String productsMargin(int percent);

  /// No description provided for @productsArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive {name}?'**
  String productsArchiveTitle(String name);

  /// No description provided for @productsArchived.
  ///
  /// In en, this message translates to:
  /// **'{name} archived.'**
  String productsArchived(String name);

  /// No description provided for @productsRestored.
  ///
  /// In en, this message translates to:
  /// **'{name} restored.'**
  String productsRestored(String name);

  /// No description provided for @productsDuplicated.
  ///
  /// In en, this message translates to:
  /// **'Copy of {name} added, off the till until you check it.'**
  String productsDuplicated(String name);

  /// No description provided for @optionsUsedBy.
  ///
  /// In en, this message translates to:
  /// **'On: {names}'**
  String optionsUsedBy(String names);

  /// No description provided for @optionsPriceInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the extra price for \"{name}\".'**
  String optionsPriceInvalid(String name);

  /// No description provided for @taxExample.
  ///
  /// In en, this message translates to:
  /// **'Example: a GH₵ 100.00 sale is {base} plus {tax} tax, {total} in all.'**
  String taxExample(String base, String tax, String total);

  /// No description provided for @editorMarginLine.
  ///
  /// In en, this message translates to:
  /// **'{percent}% margin, {profit} each'**
  String editorMarginLine(int percent, String profit);

  /// No description provided for @stockFilterLow.
  ///
  /// In en, this message translates to:
  /// **'Low ({count})'**
  String stockFilterLow(int count);

  /// No description provided for @stockTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Worth {value} at cost'**
  String stockTotalValue(String value);

  /// No description provided for @stockCostEach.
  ///
  /// In en, this message translates to:
  /// **'{price} per {unit}'**
  String stockCostEach(String price, String unit);

  /// No description provided for @stockCostPer.
  ///
  /// In en, this message translates to:
  /// **'Cost per {unit}'**
  String stockCostPer(String unit);

  /// No description provided for @stockWorth.
  ///
  /// In en, this message translates to:
  /// **'Worth {value} ({price} per {unit})'**
  String stockWorth(String value, String price, String unit);

  /// No description provided for @stockReorderLine.
  ///
  /// In en, this message translates to:
  /// **'Low below {amount}'**
  String stockReorderLine(String amount);

  /// No description provided for @stockLogWasteOf.
  ///
  /// In en, this message translates to:
  /// **'Waste: {name}'**
  String stockLogWasteOf(String name);

  /// No description provided for @stockAdjustOf.
  ///
  /// In en, this message translates to:
  /// **'Correct: {name}'**
  String stockAdjustOf(String name);

  /// No description provided for @stockAdjustReason.
  ///
  /// In en, this message translates to:
  /// **'Correct stock of {name}.'**
  String stockAdjustReason(String name);

  /// No description provided for @stockWasteReason.
  ///
  /// In en, this message translates to:
  /// **'Log waste of {name}.'**
  String stockWasteReason(String name);

  /// No description provided for @moveWaste.
  ///
  /// In en, this message translates to:
  /// **'Waste: {reason}'**
  String moveWaste(String reason);

  /// No description provided for @receiveDone.
  ///
  /// In en, this message translates to:
  /// **'Delivery {number} saved.'**
  String receiveDone(String number);

  /// No description provided for @receiveLineInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the amount and cost for {name}.'**
  String receiveLineInvalid(String name);

  /// No description provided for @deliveriesItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String deliveriesItems(int count);

  /// No description provided for @deliveriesOwed.
  ///
  /// In en, this message translates to:
  /// **'{amount} owed'**
  String deliveriesOwed(String amount);

  /// No description provided for @countPostedStatus.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name}'**
  String countPostedStatus(String name);

  /// No description provided for @countLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item counted} other{{count} items counted}}'**
  String countLines(int count);

  /// No description provided for @countPostBody.
  ///
  /// In en, this message translates to:
  /// **'Stock for the {count} items counted will be set to what was found. Items not counted do not change.'**
  String countPostBody(int count);

  /// No description provided for @countPostedFound.
  ///
  /// In en, this message translates to:
  /// **'Count posted: {amount} more than expected.'**
  String countPostedFound(String amount);

  /// No description provided for @countPostedShort.
  ///
  /// In en, this message translates to:
  /// **'Count posted: {amount} short.'**
  String countPostedShort(String amount);

  /// No description provided for @countProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} counted'**
  String countProgress(int done, int total);

  /// No description provided for @countFoundValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than expected'**
  String countFoundValue(String amount);

  /// No description provided for @countShortValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} short so far'**
  String countShortValue(String amount);

  /// No description provided for @countCounted.
  ///
  /// In en, this message translates to:
  /// **'Counted {amount}'**
  String countCounted(String amount);

  /// No description provided for @countExpected.
  ///
  /// In en, this message translates to:
  /// **'expected {amount}'**
  String countExpected(String amount);

  /// No description provided for @suppliersOwedTotal.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount} in all.'**
  String suppliersOwedTotal(String amount);

  /// No description provided for @supplierTermsShort.
  ///
  /// In en, this message translates to:
  /// **'Pay within {days} days'**
  String supplierTermsShort(int days);

  /// No description provided for @supplierOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String supplierOwe(String amount);

  /// No description provided for @supplierCredit.
  ///
  /// In en, this message translates to:
  /// **'In credit {amount}'**
  String supplierCredit(String amount);

  /// No description provided for @supplierPayTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay {name}'**
  String supplierPayTitle(String name);

  /// No description provided for @supplierPayReason.
  ///
  /// In en, this message translates to:
  /// **'Pay {name}.'**
  String supplierPayReason(String name);

  /// No description provided for @supplierPaid.
  ///
  /// In en, this message translates to:
  /// **'{amount} payment recorded.'**
  String supplierPaid(String amount);

  /// No description provided for @supplierEntryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment {method}'**
  String supplierEntryPayment(String method);

  /// No description provided for @bulkScope.
  ///
  /// In en, this message translates to:
  /// **'Applies to the {count} products in the list now (use the search and filters to narrow it).'**
  String bulkScope(int count);

  /// No description provided for @bulkRoundTo.
  ///
  /// In en, this message translates to:
  /// **'Round to {amount}'**
  String bulkRoundTo(String amount);

  /// No description provided for @bulkPreview.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 price changes} other{{count} prices change}}'**
  String bulkPreview(int count);

  /// No description provided for @bulkApply.
  ///
  /// In en, this message translates to:
  /// **'Change {count}'**
  String bulkApply(int count);

  /// No description provided for @bulkDone.
  ///
  /// In en, this message translates to:
  /// **'{count} prices changed.'**
  String bulkDone(int count);

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{created} new, {updated} changed, {same} unchanged.'**
  String importSummary(int created, int updated, int same);

  /// No description provided for @importNewCategories.
  ///
  /// In en, this message translates to:
  /// **'New categories: {names}'**
  String importNewCategories(String names);

  /// No description provided for @importProblems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 problem} other{{count} problems}}'**
  String importProblems(int count);

  /// No description provided for @importRow.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {message}'**
  String importRow(int row, String message);

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported: {created} new, {updated} changed.'**
  String importDone(int created, int updated);

  /// No description provided for @editorSchedulePrice.
  ///
  /// In en, this message translates to:
  /// **'New price from {date}'**
  String editorSchedulePrice(String date);

  /// No description provided for @editorScheduled.
  ///
  /// In en, this message translates to:
  /// **'{price} from {date}'**
  String editorScheduled(String price, String date);

  /// No description provided for @approvalNeedsDiscount.
  ///
  /// In en, this message translates to:
  /// **'Needs someone allowed to give {percent}% off'**
  String approvalNeedsDiscount(int percent);

  /// No description provided for @cartButton.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count})'**
  String cartButton(int count);

  /// No description provided for @cartButtonParked.
  ///
  /// In en, this message translates to:
  /// **'Cart ({count}) · {parked} parked'**
  String cartButtonParked(int count, int parked);

  /// No description provided for @cartClearBody.
  ///
  /// In en, this message translates to:
  /// **'{count} items come off. This is recorded in Activity.'**
  String cartClearBody(int count);

  /// No description provided for @cartDiscountWith.
  ///
  /// In en, this message translates to:
  /// **'Discounts (incl. {name})'**
  String cartDiscountWith(String name);

  /// No description provided for @cartDropped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is no longer on the menu and was left out.} other{{count} items are no longer on the menu and were left out.}}'**
  String cartDropped(int count);

  /// No description provided for @cartEach.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String cartEach(String price);

  /// No description provided for @cartPer.
  ///
  /// In en, this message translates to:
  /// **'{price} per {unit}'**
  String cartPer(String price, String unit);

  /// No description provided for @cartWas.
  ///
  /// In en, this message translates to:
  /// **'menu price {price}'**
  String cartWas(String price);

  /// No description provided for @cartLineDiscount.
  ///
  /// In en, this message translates to:
  /// **'{name}: −{amount}'**
  String cartLineDiscount(String name, String amount);

  /// No description provided for @parkDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String parkDefaultName(int number);

  /// No description provided for @parkDone.
  ///
  /// In en, this message translates to:
  /// **'Parked \"{name}\".'**
  String parkDone(String name);

  /// No description provided for @parkDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Throw away \"{name}\"?'**
  String parkDiscardTitle(String name);

  /// No description provided for @parkDiscardReason.
  ///
  /// In en, this message translates to:
  /// **'Throw away the parked order \"{name}\".'**
  String parkDiscardReason(String name);

  /// No description provided for @closeParkedWarning.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 parked order has been waiting a long time. Was it paid?} other{{count} parked orders have been waiting a long time. Were they paid?}}'**
  String closeParkedWarning(int count);

  /// No description provided for @discountApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Give {discount} off {what}.'**
  String discountApprovalReason(String discount, String what);

  /// No description provided for @entryPricePer.
  ///
  /// In en, this message translates to:
  /// **'{price} per {unit}'**
  String entryPricePer(String price, String unit);

  /// No description provided for @entryPricePerLabel.
  ///
  /// In en, this message translates to:
  /// **'Price per {unit}'**
  String entryPricePerLabel(String unit);

  /// No description provided for @entryMin.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String entryMin(String price);

  /// No description provided for @entryMax.
  ///
  /// In en, this message translates to:
  /// **'up to {price}'**
  String entryMax(String price);

  /// No description provided for @lineOpenPriceBetween.
  ///
  /// In en, this message translates to:
  /// **'Between {min} and {max}.'**
  String lineOpenPriceBetween(String min, String max);

  /// No description provided for @lineOpenPriceMin.
  ///
  /// In en, this message translates to:
  /// **'At least {min}.'**
  String lineOpenPriceMin(String min);

  /// No description provided for @lineOpenPriceMax.
  ///
  /// In en, this message translates to:
  /// **'Up to {max}.'**
  String lineOpenPriceMax(String max);

  /// No description provided for @lineMenuPrice.
  ///
  /// In en, this message translates to:
  /// **'Menu price {price}'**
  String lineMenuPrice(String price);

  /// No description provided for @lineDiscountTitle.
  ///
  /// In en, this message translates to:
  /// **'Discount on {item}'**
  String lineDiscountTitle(String item);

  /// No description provided for @pickerUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update · {price}'**
  String pickerUpdate(String price);

  /// No description provided for @overrideReason.
  ///
  /// In en, this message translates to:
  /// **'Change the price of {item} to {price}.'**
  String overrideReason(String item, String price);

  /// No description provided for @settingsHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String settingsHours(int count);

  /// No description provided for @tillQuantityHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a product to add {count}, or press Enter for code {count}'**
  String tillQuantityHint(int count);

  /// No description provided for @tillCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No product has the code {code}.'**
  String tillCodeNotFound(String code);

  /// No description provided for @tillCodeUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'No product has {code}'**
  String tillCodeUnknownTitle(String code);

  /// No description provided for @tillOutBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} is out of stock.'**
  String tillOutBlocked(String name);

  /// No description provided for @tillOutWarning.
  ///
  /// In en, this message translates to:
  /// **'The till thinks {name} has run out. Check the shelf.'**
  String tillOutWarning(String name);

  /// No description provided for @tillPriceLow.
  ///
  /// In en, this message translates to:
  /// **'The price must be at least {price}.'**
  String tillPriceLow(String price);

  /// No description provided for @tillPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'The price can be at most {price}.'**
  String tillPriceHigh(String price);

  /// No description provided for @cartExchange.
  ///
  /// In en, this message translates to:
  /// **'Exchange: returned items worth {amount} pay first.'**
  String cartExchange(String amount);

  /// No description provided for @checkoutGiveBack.
  ///
  /// In en, this message translates to:
  /// **'The returned items are worth {amount} more. Give it back by:'**
  String checkoutGiveBack(String amount);

  /// No description provided for @checkoutTakePart.
  ///
  /// In en, this message translates to:
  /// **'Take {amount}, pay the rest another way'**
  String checkoutTakePart(String amount);

  /// No description provided for @checkoutReference.
  ///
  /// In en, this message translates to:
  /// **'{method} transaction ID'**
  String checkoutReference(String method);

  /// No description provided for @checkoutPayTo.
  ///
  /// In en, this message translates to:
  /// **'Pay to {method}'**
  String checkoutPayTo(String method);

  /// No description provided for @checkoutRounded.
  ///
  /// In en, this message translates to:
  /// **'Cash rounded to {amount} ({difference} difference).'**
  String checkoutRounded(String amount, String difference);

  /// No description provided for @checkoutRoundingLine.
  ///
  /// In en, this message translates to:
  /// **'Cash rounding {sign}{amount}'**
  String checkoutRoundingLine(String amount, String sign);

  /// No description provided for @checkoutExchangeLine.
  ///
  /// In en, this message translates to:
  /// **'Exchange: refund {number}, {amount} returned'**
  String checkoutExchangeLine(String number, String amount);

  /// No description provided for @closeRounding.
  ///
  /// In en, this message translates to:
  /// **'Cash rounding'**
  String get closeRounding;

  /// No description provided for @closeRefunds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 refund} other{{count} refunds}}'**
  String closeRefunds(int count);

  /// No description provided for @closeRefundsBy.
  ///
  /// In en, this message translates to:
  /// **'Refunded by {method}'**
  String closeRefundsBy(String method);

  /// No description provided for @closeNoSales.
  ///
  /// In en, this message translates to:
  /// **'Drawer opened without a sale: {name}'**
  String closeNoSales(String name);

  /// No description provided for @exchangeApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Take back items worth {amount} as an exchange.'**
  String exchangeApprovalReason(String amount);

  /// No description provided for @refundTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund {number}'**
  String refundTitle(String number);

  /// No description provided for @refundAlready.
  ///
  /// In en, this message translates to:
  /// **'{amount} has already been refunded.'**
  String refundAlready(String amount);

  /// No description provided for @refundSold.
  ///
  /// In en, this message translates to:
  /// **'Sold {quantity} for {amount}'**
  String refundSold(String quantity, String amount);

  /// No description provided for @refundBackAlready.
  ///
  /// In en, this message translates to:
  /// **'{quantity} already back'**
  String refundBackAlready(String quantity);

  /// No description provided for @refundButton.
  ///
  /// In en, this message translates to:
  /// **'Refund {amount}'**
  String refundButton(String amount);

  /// No description provided for @refundApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Give a refund of {amount}.'**
  String refundApprovalReason(String amount);

  /// No description provided for @refundDone.
  ///
  /// In en, this message translates to:
  /// **'Refund {number} saved'**
  String refundDone(String number);

  /// No description provided for @todayApprovedBy.
  ///
  /// In en, this message translates to:
  /// **'approved by {name}'**
  String todayApprovedBy(String name);

  /// No description provided for @todayFindNone.
  ///
  /// In en, this message translates to:
  /// **'No sale {number} on this till.'**
  String todayFindNone(String number);

  /// No description provided for @todayItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String todayItems(int count);

  /// No description provided for @todayRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded {amount}'**
  String todayRefunded(String amount);

  /// No description provided for @todayVoidedBy.
  ///
  /// In en, this message translates to:
  /// **'Voided by {name}'**
  String todayVoidedBy(String name);

  /// No description provided for @checkoutKeepChange.
  ///
  /// In en, this message translates to:
  /// **'Keep {amount} change in their wallet'**
  String checkoutKeepChange(String amount);

  /// No description provided for @checkoutKeepChangeHelp.
  ///
  /// In en, this message translates to:
  /// **'{name} can spend it next time.'**
  String checkoutKeepChangeHelp(String name);

  /// No description provided for @checkoutOnAccount.
  ///
  /// In en, this message translates to:
  /// **'Goes on {name}\'s account.'**
  String checkoutOnAccount(String name);

  /// No description provided for @checkoutOnAccountLimit.
  ///
  /// In en, this message translates to:
  /// **'Goes on {name}\'s account ({left} left of their limit).'**
  String checkoutOnAccountLimit(String name, String left);

  /// No description provided for @checkoutOverLimit.
  ///
  /// In en, this message translates to:
  /// **'This takes {name} over their credit limit of {limit}.'**
  String checkoutOverLimit(String name, String limit);

  /// No description provided for @checkoutOverLimitReason.
  ///
  /// In en, this message translates to:
  /// **'Let {name} owe {owed} (their limit is {limit}).'**
  String checkoutOverLimitReason(String name, String owed, String limit);

  /// No description provided for @checkoutWalletHas.
  ///
  /// In en, this message translates to:
  /// **'{name} has {amount} in their wallet.'**
  String checkoutWalletHas(String name, String amount);

  /// No description provided for @customersOwedTotal.
  ///
  /// In en, this message translates to:
  /// **'Customers owe {amount} in all.'**
  String customersOwedTotal(String amount);

  /// No description provided for @customerOwes.
  ///
  /// In en, this message translates to:
  /// **'owes {amount}'**
  String customerOwes(String amount);

  /// No description provided for @customerWallet.
  ///
  /// In en, this message translates to:
  /// **'wallet {amount}'**
  String customerWallet(String amount);

  /// No description provided for @customerLimitLine.
  ///
  /// In en, this message translates to:
  /// **'Limit {limit}, {left} left'**
  String customerLimitLine(String limit, String left);

  /// No description provided for @customerOverdueLine.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {a} (1–30 days), {b} (31–60), {c} (over 60)'**
  String customerOverdueLine(String a, String b, String c);

  /// No description provided for @customerRepayReason.
  ///
  /// In en, this message translates to:
  /// **'Record a payment from {name}.'**
  String customerRepayReason(String name);

  /// No description provided for @customerTopUpReason.
  ///
  /// In en, this message translates to:
  /// **'Put money into {name}\'s wallet.'**
  String customerTopUpReason(String name);

  /// No description provided for @customerWriteOffReason.
  ///
  /// In en, this message translates to:
  /// **'Write off what {name} owes.'**
  String customerWriteOffReason(String name);

  /// No description provided for @customerRepaid.
  ///
  /// In en, this message translates to:
  /// **'{amount} payment recorded.'**
  String customerRepaid(String amount);

  /// No description provided for @customerToppedUp.
  ///
  /// In en, this message translates to:
  /// **'{amount} added to the wallet.'**
  String customerToppedUp(String amount);

  /// No description provided for @customerWrittenOff.
  ///
  /// In en, this message translates to:
  /// **'{amount} written off.'**
  String customerWrittenOff(String amount);

  /// No description provided for @customerStatementText.
  ///
  /// In en, this message translates to:
  /// **'Statement for {name}'**
  String customerStatementText(String name);

  /// No description provided for @customerDaysLate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day late} other{{count} days late}}'**
  String customerDaysLate(int count);

  /// No description provided for @customerDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String customerDue(String date);

  /// No description provided for @dayStarted.
  ///
  /// In en, this message translates to:
  /// **'Day started with a float of {amount}.'**
  String dayStarted(String amount);

  /// No description provided for @dayStartedLine.
  ///
  /// In en, this message translates to:
  /// **'Day started by {name} at {time} with a float of {float}.'**
  String dayStartedLine(String name, String time, String float);

  /// No description provided for @payInReason.
  ///
  /// In en, this message translates to:
  /// **'Put {amount} into the drawer.'**
  String payInReason(String amount);

  /// No description provided for @payOutReason.
  ///
  /// In en, this message translates to:
  /// **'Take {amount} out of the drawer.'**
  String payOutReason(String amount);

  /// No description provided for @payInDone.
  ///
  /// In en, this message translates to:
  /// **'{amount} put in. This is recorded.'**
  String payInDone(String amount);

  /// No description provided for @payOutDone.
  ///
  /// In en, this message translates to:
  /// **'{amount} taken out. This is recorded.'**
  String payOutDone(String amount);

  /// No description provided for @safeDropReason.
  ///
  /// In en, this message translates to:
  /// **'Move {amount} to the safe.'**
  String safeDropReason(String amount);

  /// No description provided for @safeDropDone.
  ///
  /// In en, this message translates to:
  /// **'{amount} moved to the safe.'**
  String safeDropDone(String amount);

  /// No description provided for @bankDepositAt.
  ///
  /// In en, this message translates to:
  /// **'Banked at {bank}'**
  String bankDepositAt(String bank);

  /// No description provided for @bankDepositReason.
  ///
  /// In en, this message translates to:
  /// **'Bank {amount} from the safe.'**
  String bankDepositReason(String amount);

  /// No description provided for @momoReceived.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 payment} other{{count} payments}}'**
  String momoReceived(int count);

  /// No description provided for @momoUnchecked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 not checked yet} other{{count} not checked yet}}'**
  String momoUnchecked(int count);

  /// No description provided for @momoMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 missing from the statement} other{{count} missing from the statement}}'**
  String momoMissing(int count);

  /// No description provided for @closeSince.
  ///
  /// In en, this message translates to:
  /// **'Since {time}'**
  String closeSince(String time);

  /// No description provided for @closeDayStartedBy.
  ///
  /// In en, this message translates to:
  /// **'Day started by {name} with a float of {float}'**
  String closeDayStartedBy(String name, String float);

  /// No description provided for @closeSales.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale} other{{count} sales}}'**
  String closeSales(int count);

  /// No description provided for @closeVoided.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 voided} other{{count} voided}}'**
  String closeVoided(int count);

  /// No description provided for @closeReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Needed when the drawer is out by more than {amount}.'**
  String closeReasonHelp(String amount);

  /// No description provided for @closeDoneLine.
  ///
  /// In en, this message translates to:
  /// **'{count} sales  ·  {total}  ·  by {name}'**
  String closeDoneLine(int count, String total, String name);

  /// No description provided for @closeOver.
  ///
  /// In en, this message translates to:
  /// **'Over {amount}'**
  String closeOver(String amount);

  /// No description provided for @closeShort.
  ///
  /// In en, this message translates to:
  /// **'Short {amount}'**
  String closeShort(String amount);

  /// No description provided for @closeVarianceLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: short {shorts} times ({amount}), over {overs} times'**
  String closeVarianceLine(String name, int shorts, String amount, int overs);

  /// No description provided for @expenseReason.
  ///
  /// In en, this message translates to:
  /// **'Record an expense of {amount}.'**
  String expenseReason(String amount);

  /// No description provided for @expenseSaved.
  ///
  /// In en, this message translates to:
  /// **'{amount} expense recorded.'**
  String expenseSaved(String amount);

  /// No description provided for @expensesTotal.
  ///
  /// In en, this message translates to:
  /// **'Spent: {amount}'**
  String expensesTotal(String amount);

  /// No description provided for @recurringLine.
  ///
  /// In en, this message translates to:
  /// **'{amount} on day {day}  ·  {category}'**
  String recurringLine(String amount, int day, String category);

  /// No description provided for @recurringDue.
  ///
  /// In en, this message translates to:
  /// **'{name}: {amount}, due on day {day}'**
  String recurringDue(String name, String amount, int day);

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of net sales'**
  String profitMargin(int percent);

  /// No description provided for @ownerTookReason.
  ///
  /// In en, this message translates to:
  /// **'Record the owner taking {amount}.'**
  String ownerTookReason(String amount);

  /// No description provided for @ownerPutReason.
  ///
  /// In en, this message translates to:
  /// **'Record the owner putting in {amount}.'**
  String ownerPutReason(String amount);

  /// No description provided for @dashLastWeek.
  ///
  /// In en, this message translates to:
  /// **'same day last week {amount}'**
  String dashLastWeek(String amount);

  /// No description provided for @dashLastWeekCount.
  ///
  /// In en, this message translates to:
  /// **'same day last week {count}'**
  String dashLastWeekCount(int count);

  /// No description provided for @dashDayStartedBy.
  ///
  /// In en, this message translates to:
  /// **'Day started by {name}'**
  String dashDayStartedBy(String name);

  /// No description provided for @alertLowStock.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 stock item is low: {names}} other{{count} stock items are low: {names}}}'**
  String alertLowStock(int count, String names);

  /// No description provided for @alertCredit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer is late paying: {amount}} other{{count} customers are late paying: {amount}}}'**
  String alertCredit(int count, String amount);

  /// No description provided for @alertDayOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A day was not closed: 1 sale from before today} other{A day was not closed: {count} sales from before today}}'**
  String alertDayOpen(int count);

  /// No description provided for @alertExpenses.
  ///
  /// In en, this message translates to:
  /// **'Due: {names} ({amount}). See Money.'**
  String alertExpenses(String names, String amount);

  /// No description provided for @reportSold.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String reportSold(int count);

  /// No description provided for @reportProfitLine.
  ///
  /// In en, this message translates to:
  /// **'profit {amount} ({percent}%)'**
  String reportProfitLine(String amount, String percent);

  /// No description provided for @reportShorts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Short once} other{Short {count} times}}'**
  String reportShorts(int count);

  /// No description provided for @statusPrintsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 waiting to print.} other{{count} waiting to print.}}'**
  String statusPrintsWaiting(int count);

  /// No description provided for @scaleRequestLetter.
  ///
  /// In en, this message translates to:
  /// **'Send the letter {letter}'**
  String scaleRequestLetter(String letter);

  /// No description provided for @scaleReadOk.
  ///
  /// In en, this message translates to:
  /// **'The scale says {kg} kg.'**
  String scaleReadOk(String kg);

  /// No description provided for @notifyHelp.
  ///
  /// In en, this message translates to:
  /// **'For {name} on this device.'**
  String notifyHelp(String name);

  /// No description provided for @reportPromotionsPart.
  ///
  /// In en, this message translates to:
  /// **'Promotions: {amount}'**
  String reportPromotionsPart(String amount);

  /// No description provided for @promoAllIn.
  ///
  /// In en, this message translates to:
  /// **'All {category}'**
  String promoAllIn(String category);

  /// No description provided for @promoPart.
  ///
  /// In en, this message translates to:
  /// **'Part {n}'**
  String promoPart(int n);

  /// No description provided for @promoFrom.
  ///
  /// In en, this message translates to:
  /// **'from {date}'**
  String promoFrom(String date);

  /// No description provided for @promoUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String promoUntil(String date);

  /// No description provided for @loyaltyFreeReady.
  ///
  /// In en, this message translates to:
  /// **'{name} has a free item'**
  String loyaltyFreeReady(String name);

  /// No description provided for @loyaltyStampsHave.
  ///
  /// In en, this message translates to:
  /// **'{count} of {needed} stamps'**
  String loyaltyStampsHave(int count, int needed);

  /// No description provided for @loyaltyPointsHave.
  ///
  /// In en, this message translates to:
  /// **'{count} points'**
  String loyaltyPointsHave(int count);

  /// No description provided for @loyaltyPointsReward.
  ///
  /// In en, this message translates to:
  /// **'{count} points: {amount} off'**
  String loyaltyPointsReward(int count, String amount);

  /// No description provided for @loyaltyGold.
  ///
  /// In en, this message translates to:
  /// **'Gold: {percent}% off'**
  String loyaltyGold(int percent);

  /// No description provided for @voucherSoldFor.
  ///
  /// In en, this message translates to:
  /// **'Sold for {amount} on {date}'**
  String voucherSoldFor(String amount, String date);

  /// No description provided for @voucherUseBy.
  ///
  /// In en, this message translates to:
  /// **'Use by {date}'**
  String voucherUseBy(String date);

  /// No description provided for @voucherMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String voucherMonths(int count);

  /// No description provided for @voucherLeft.
  ///
  /// In en, this message translates to:
  /// **'{left} left of {amount}'**
  String voucherLeft(String left, String amount);

  /// No description provided for @voucherHas.
  ///
  /// In en, this message translates to:
  /// **'{code}: {amount} left'**
  String voucherHas(String code, String amount);

  /// No description provided for @orderMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {status}'**
  String orderMoveTo(String status);

  /// No description provided for @orderBack.
  ///
  /// In en, this message translates to:
  /// **'Back to {status}'**
  String orderBack(String status);

  /// No description provided for @screensCannotStart.
  ///
  /// In en, this message translates to:
  /// **'The screens could not start: {error}'**
  String screensCannotStart(String error);

  /// No description provided for @labelsMakeMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Make a barcode for the 1 without one} other{Make barcodes for the {count} without one}}'**
  String labelsMakeMissing(int count);

  /// No description provided for @labelsBarcodesMade.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 barcode made.} other{{count} barcodes made.}}'**
  String labelsBarcodesMade(int count);

  /// No description provided for @labelsPrint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Print 1 label} other{Print {count} labels}}'**
  String labelsPrint(int count);

  /// No description provided for @labelsForDeliveryBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product came in that is sold as is. Print its price labels?} other{{count} products came in that are sold as is. Print their price labels?}}'**
  String labelsForDeliveryBody(int count);

  /// No description provided for @alertExpiring.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item expires within a week: {names}} other{{count} items expire within a week: {names}}}'**
  String alertExpiring(int count, String names);

  /// No description provided for @receiveExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String receiveExpiresOn(String date);

  /// No description provided for @receiveAgainst.
  ///
  /// In en, this message translates to:
  /// **'Against {order} from {supplier}'**
  String receiveAgainst(String order, String supplier);

  /// No description provided for @expiryOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiryOn(String date);

  /// No description provided for @expiryExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String expiryExpired(String date);

  /// No description provided for @expiryReceived.
  ///
  /// In en, this message translates to:
  /// **'came in {date}'**
  String expiryReceived(String date);

  /// No description provided for @poNeededBy.
  ///
  /// In en, this message translates to:
  /// **'Needed by {date}'**
  String poNeededBy(String date);

  /// No description provided for @poLineReceived.
  ///
  /// In en, this message translates to:
  /// **'{amount} received'**
  String poLineReceived(String amount);

  /// No description provided for @poShareText.
  ///
  /// In en, this message translates to:
  /// **'Purchase order {number}'**
  String poShareText(String number);

  /// No description provided for @produceBatchMakes.
  ///
  /// In en, this message translates to:
  /// **'One batch makes {amount}'**
  String produceBatchMakes(String amount);

  /// No description provided for @produceRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Made {name}'**
  String produceRecordTitle(String name);

  /// No description provided for @produceRecipeTitle.
  ///
  /// In en, this message translates to:
  /// **'What {name} is made from'**
  String produceRecipeTitle(String name);

  /// No description provided for @produceReason.
  ///
  /// In en, this message translates to:
  /// **'Making {name} uses up stock.'**
  String produceReason(String name);

  /// No description provided for @produceDone.
  ///
  /// In en, this message translates to:
  /// **'Made {amount}, {cost} of ingredients.'**
  String produceDone(String amount, String cost);

  /// No description provided for @badgeFor.
  ///
  /// In en, this message translates to:
  /// **'Badge for {name}'**
  String badgeFor(String name);

  /// No description provided for @clockInSince.
  ///
  /// In en, this message translates to:
  /// **'In since {time}'**
  String clockInSince(String time);

  /// No description provided for @timeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String timeHours(int hours, int minutes);

  /// No description provided for @timeBreak.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min break'**
  String timeBreak(int minutes);

  /// No description provided for @timeLate.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min late'**
  String timeLate(int minutes);

  /// No description provided for @timeEarly.
  ///
  /// In en, this message translates to:
  /// **'left {minutes} min early'**
  String timeEarly(int minutes);

  /// No description provided for @timeLateCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{late once} other{late {count} times}}'**
  String timeLateCount(int count);

  /// No description provided for @timeEarlyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{left early once} other{left early {count} times}}'**
  String timeEarlyCount(int count);

  /// No description provided for @commissionPercentOfSales.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of sales'**
  String commissionPercentOfSales(int percent);

  /// No description provided for @commandFrom.
  ///
  /// In en, this message translates to:
  /// **'from {price}'**
  String commandFrom(String price);

  /// No description provided for @insightRunningOut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{item} will run out in about a day at this week\'s pace.} other{{item} will run out in about {count} days at this week\'s pace.}}'**
  String insightRunningOut(String item, int count);

  /// No description provided for @insightBusyDay.
  ///
  /// In en, this message translates to:
  /// **'{day} sales are {percent}% higher than weekdays. Plan enough staff.'**
  String insightBusyDay(String day, int percent);

  /// No description provided for @insightMarginDrop.
  ///
  /// In en, this message translates to:
  /// **'{product} margin fell from {before}% to {now}% this week. Costs may have gone up.'**
  String insightMarginDrop(String product, int before, int now);

  /// No description provided for @insightLateCredit.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 customer owes for more than 30 days: {amount}.} other{{count} customers owe for more than 30 days: {amount} in total.}}'**
  String insightLateCredit(int count, String amount);

  /// No description provided for @insightCashShort.
  ///
  /// In en, this message translates to:
  /// **'Cash was short {count} times this month: {amount} in all.'**
  String insightCashShort(int count, String amount);

  /// No description provided for @summarySales.
  ///
  /// In en, this message translates to:
  /// **'Sales: {amount} ({count})'**
  String summarySales(String amount, int count);

  /// No description provided for @summaryProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit before expenses: {amount}'**
  String summaryProfit(String amount);

  /// No description provided for @summaryTop.
  ///
  /// In en, this message translates to:
  /// **'Top: {product}'**
  String summaryTop(String product);

  /// No description provided for @summaryClosedBy.
  ///
  /// In en, this message translates to:
  /// **'Closed by {name}'**
  String summaryClosedBy(String name);

  /// No description provided for @summarySalesLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sale} other{{count} sales}}'**
  String summarySalesLabel(int count);

  /// No description provided for @hubCodeExpires.
  ///
  /// In en, this message translates to:
  /// **'The code works once, until {time}.'**
  String hubCodeExpires(String time);

  /// No description provided for @hubLastSync.
  ///
  /// In en, this message translates to:
  /// **'Last synced {when}'**
  String hubLastSync(String when);

  /// No description provided for @hubLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String hubLastSeen(String when);

  /// No description provided for @hubRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String hubRevokeTitle(String name);

  /// No description provided for @hubCannotStart.
  ///
  /// In en, this message translates to:
  /// **'The hub could not start: {error}'**
  String hubCannotStart(String error);

  /// No description provided for @branchMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move this device to {name}?'**
  String branchMoveTitle(String name);

  /// No description provided for @branchDevices.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 device} other{{count} devices}}'**
  String branchDevices(int count);

  /// No description provided for @branchMergeConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{shop}: {count} sales, last sale {last}. Everything in it is added to this device, newer changes winning. A backup of this device is made first.'**
  String branchMergeConfirmBody(String shop, int count, String last);

  /// No description provided for @branchMerged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing new in that file.} =1{1 change brought in.} other{{count} changes brought in.}}'**
  String branchMerged(int count);

  /// No description provided for @transferFrom.
  ///
  /// In en, this message translates to:
  /// **'from {name}'**
  String transferFrom(String name);

  /// No description provided for @transferTo.
  ///
  /// In en, this message translates to:
  /// **'to {name}'**
  String transferTo(String name);

  /// No description provided for @transferSentBy.
  ///
  /// In en, this message translates to:
  /// **'Sent {when} by {name}'**
  String transferSentBy(String when, String name);

  /// No description provided for @transferReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'received {when} by {name}'**
  String transferReceivedBy(String when, String name);

  /// No description provided for @transferArrived.
  ///
  /// In en, this message translates to:
  /// **'Arrived: {qty}'**
  String transferArrived(String qty);

  /// No description provided for @transferReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive {code}'**
  String transferReceiveTitle(String code);

  /// No description provided for @transferSentQty.
  ///
  /// In en, this message translates to:
  /// **'Sent: {qty}'**
  String transferSentQty(String qty);

  /// No description provided for @transferSent.
  ///
  /// In en, this message translates to:
  /// **'{code} sent.'**
  String transferSent(String code);

  /// No description provided for @transferNotEnough.
  ///
  /// In en, this message translates to:
  /// **'Only {qty} of {item} here.'**
  String transferNotEnough(String item, String qty);

  /// No description provided for @auditAccountsExported.
  ///
  /// In en, this message translates to:
  /// **'Accountant pack saved'**
  String get auditAccountsExported;

  /// No description provided for @accountsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Save the accountant\'s pack every month'**
  String get accountsMonthly;

  /// No description provided for @accountsMonthlyHelp.
  ///
  /// In en, this message translates to:
  /// **'On the 1st, last month\'s pack (sales, payments, expenses, purchases, tax and stock, every branch) is saved on this device.'**
  String get accountsMonthlyHelp;

  /// No description provided for @accountsFolder.
  ///
  /// In en, this message translates to:
  /// **'Where the packs are saved'**
  String get accountsFolder;

  /// No description provided for @accountsFolderInApp.
  ///
  /// In en, this message translates to:
  /// **'Kept in the app on this device. Use Share to send one.'**
  String get accountsFolderInApp;

  /// No description provided for @accountsShareLatest.
  ///
  /// In en, this message translates to:
  /// **'Share the latest pack'**
  String get accountsShareLatest;

  /// No description provided for @accountsNone.
  ///
  /// In en, this message translates to:
  /// **'No pack saved yet.'**
  String get accountsNone;

  /// No description provided for @accountsSaved.
  ///
  /// In en, this message translates to:
  /// **'Accountant pack saved: {name}'**
  String accountsSaved(String name);

  /// No description provided for @statusAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accountant pack'**
  String get statusAccounts;

  /// No description provided for @statusAccountsFailed.
  ///
  /// In en, this message translates to:
  /// **'The last pack could not be saved. Check the folder in Settings, Backup.'**
  String get statusAccountsFailed;

  /// No description provided for @tillViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid view'**
  String get tillViewGrid;

  /// No description provided for @tillViewList.
  ///
  /// In en, this message translates to:
  /// **'List view'**
  String get tillViewList;

  /// No description provided for @tillNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No match for “{query}”'**
  String tillNoMatchTitle(String query);

  /// No description provided for @tillClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get tillClearSearch;

  /// No description provided for @editorPhotoNotPicture.
  ///
  /// In en, this message translates to:
  /// **'That file is not a picture. Pick a JPG or PNG photo.'**
  String get editorPhotoNotPicture;

  /// No description provided for @editorPhotoNone.
  ///
  /// In en, this message translates to:
  /// **'No photo yet: the till shows the category picture.'**
  String get editorPhotoNone;

  /// No description provided for @categoriesPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get categoriesPicture;

  /// No description provided for @categoriesPictureAuto.
  ///
  /// In en, this message translates to:
  /// **'Picked from the name'**
  String get categoriesPictureAuto;

  /// No description provided for @settingsTabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get settingsTabShop;

  /// No description provided for @settingsTabSelling.
  ///
  /// In en, this message translates to:
  /// **'Selling'**
  String get settingsTabSelling;

  /// No description provided for @settingsTabReceipts.
  ///
  /// In en, this message translates to:
  /// **'Receipts and orders'**
  String get settingsTabReceipts;

  /// No description provided for @settingsTabDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get settingsTabDevice;

  /// No description provided for @settingsTabData.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settingsTabData;

  /// No description provided for @settingsGroupScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get settingsGroupScreen;

  /// No description provided for @settingsProductView.
  ///
  /// In en, this message translates to:
  /// **'Products on the till'**
  String get settingsProductView;

  /// No description provided for @settingsProductViewHelp.
  ///
  /// In en, this message translates to:
  /// **'The grid shows photos; the list fits more on a phone. Cashiers can switch on the till.'**
  String get settingsProductViewHelp;

  /// No description provided for @settingsViewAuto.
  ///
  /// In en, this message translates to:
  /// **'Grid on tablets, list on phones'**
  String get settingsViewAuto;

  /// No description provided for @settingsViewGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get settingsViewGrid;

  /// No description provided for @settingsViewList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get settingsViewList;

  /// No description provided for @settingsPinPad.
  ///
  /// In en, this message translates to:
  /// **'PIN keypad'**
  String get settingsPinPad;

  /// No description provided for @settingsPinPadHelp.
  ///
  /// In en, this message translates to:
  /// **'How staff type their PIN on this device, so no one learns it by watching.'**
  String get settingsPinPadHelp;

  /// No description provided for @settingsPinPadStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get settingsPinPadStandard;

  /// No description provided for @settingsPinPadShuffled.
  ///
  /// In en, this message translates to:
  /// **'Shuffled: the digits move every time'**
  String get settingsPinPadShuffled;

  /// No description provided for @settingsPinPadKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard only: no keypad on screen'**
  String get settingsPinPadKeyboard;

  /// No description provided for @pinDigitsEntered.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} digits entered'**
  String pinDigitsEntered(int count, int total);

  /// No description provided for @pinTypeOnKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Type your PIN on the keyboard'**
  String get pinTypeOnKeyboard;

  /// No description provided for @pinKeyboardWorks.
  ///
  /// In en, this message translates to:
  /// **'You can also type your PIN on the keyboard'**
  String get pinKeyboardWorks;

  /// No description provided for @pinClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get pinClear;

  /// No description provided for @pinDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pinDelete;

  /// No description provided for @pinShowKeypad.
  ///
  /// In en, this message translates to:
  /// **'Show the keypad'**
  String get pinShowKeypad;

  /// No description provided for @hubJoinSteps.
  ///
  /// In en, this message translates to:
  /// **'On the hub, open Settings, This device, Devices and hub, and tap Add a device. Type the code it shows.'**
  String get hubJoinSteps;

  /// No description provided for @hubJoinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get hubJoinButton;

  /// No description provided for @hubScanInstead.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code instead'**
  String get hubScanInstead;

  /// No description provided for @hubLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking for the hub on this Wi-Fi…'**
  String get hubLooking;

  /// No description provided for @hubNoneHeard.
  ///
  /// In en, this message translates to:
  /// **'No hub heard on this Wi-Fi yet. Check the hub is on, and on the same Wi-Fi.'**
  String get hubNoneHeard;

  /// No description provided for @hubLookAgain.
  ///
  /// In en, this message translates to:
  /// **'Look again'**
  String get hubLookAgain;

  /// No description provided for @hubPickOne.
  ///
  /// In en, this message translates to:
  /// **'Pick your shop\'s hub'**
  String get hubPickOne;

  /// No description provided for @hubFound.
  ///
  /// In en, this message translates to:
  /// **'Hub: {name}'**
  String hubFound(String name);

  /// No description provided for @hubTypeAddress.
  ///
  /// In en, this message translates to:
  /// **'Type the hub\'s address instead'**
  String get hubTypeAddress;

  /// No description provided for @hubFindOnWifi.
  ///
  /// In en, this message translates to:
  /// **'Find the hub on the Wi-Fi instead'**
  String get hubFindOnWifi;

  /// No description provided for @importIntro.
  ///
  /// In en, this message translates to:
  /// **'Add or update many products at once from a spreadsheet: one row per product, or one per size when it has several prices.'**
  String get importIntro;

  /// No description provided for @importStep1.
  ///
  /// In en, this message translates to:
  /// **'Download the sample. It is filled in for your kind of shop.'**
  String get importStep1;

  /// No description provided for @importStep2.
  ///
  /// In en, this message translates to:
  /// **'Replace the examples with your products, in Excel or Google Sheets.'**
  String get importStep2;

  /// No description provided for @importStep3.
  ///
  /// In en, this message translates to:
  /// **'Save it as CSV and pick it here. You see what changes before anything is saved.'**
  String get importStep3;

  /// No description provided for @importDownloadSample.
  ///
  /// In en, this message translates to:
  /// **'Download sample'**
  String get importDownloadSample;

  /// No description provided for @importStartFromMine.
  ///
  /// In en, this message translates to:
  /// **'Start from my products instead'**
  String get importStartFromMine;

  /// No description provided for @importColumns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get importColumns;

  /// No description provided for @importColCategory.
  ///
  /// In en, this message translates to:
  /// **'The category. A new name becomes a new category.'**
  String get importColCategory;

  /// No description provided for @importColProduct.
  ///
  /// In en, this message translates to:
  /// **'Needed. Rows with the same name are one product.'**
  String get importColProduct;

  /// No description provided for @importColVariant.
  ///
  /// In en, this message translates to:
  /// **'Size or flavour, when the product has several prices.'**
  String get importColVariant;

  /// No description provided for @importColPrice.
  ///
  /// In en, this message translates to:
  /// **'Needed. In cedis, for example 15.00.'**
  String get importColPrice;

  /// No description provided for @importColCost.
  ///
  /// In en, this message translates to:
  /// **'What you pay, for profit. Leave it empty if you are not sure.'**
  String get importColCost;

  /// No description provided for @importColBarcodes.
  ///
  /// In en, this message translates to:
  /// **'One or more, split with |.'**
  String get importColBarcodes;

  /// No description provided for @importColTileLine.
  ///
  /// In en, this message translates to:
  /// **'A short line on the till tile, for example 500 ml.'**
  String get importColTileLine;

  /// No description provided for @importColOnTill.
  ///
  /// In en, this message translates to:
  /// **'yes or no. No keeps it off the till for now.'**
  String get importColOnTill;

  /// No description provided for @importNeverRemoves.
  ///
  /// In en, this message translates to:
  /// **'Importing adds products and updates prices, costs and barcodes. It never removes anything.'**
  String get importNeverRemoves;

  /// No description provided for @importFixHint.
  ///
  /// In en, this message translates to:
  /// **'Fix these rows in the file and pick it again. Headings like Name, Selling price and Barcode work too.'**
  String get importFixHint;

  /// No description provided for @productsNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No products yet. Add them one by one, or bring in a whole price list at once.'**
  String get productsNoneYet;

  /// No description provided for @productsImportCta.
  ///
  /// In en, this message translates to:
  /// **'Import from a spreadsheet'**
  String get productsImportCta;

  /// No description provided for @auditPriceScheduleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Price change called off'**
  String get auditPriceScheduleCancelled;

  /// No description provided for @auditStockCountCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stock count cancelled'**
  String get auditStockCountCancelled;

  /// No description provided for @auditReceiptReprinted.
  ///
  /// In en, this message translates to:
  /// **'Receipt printed again'**
  String get auditReceiptReprinted;

  /// No description provided for @auditTrainingStarted.
  ///
  /// In en, this message translates to:
  /// **'Training mode started'**
  String get auditTrainingStarted;

  /// No description provided for @activityYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get activityYes;

  /// No description provided for @activityNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get activityNo;

  /// No description provided for @activityNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get activityNotSet;

  /// No description provided for @activityPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get activityPrice;

  /// No description provided for @activityValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get activityValue;

  /// No description provided for @activityProductGone.
  ///
  /// In en, this message translates to:
  /// **'A product no longer on file'**
  String get activityProductGone;

  /// No description provided for @activityPricesUp.
  ///
  /// In en, this message translates to:
  /// **'{count} up'**
  String activityPricesUp(int count);

  /// No description provided for @activityPricesDown.
  ///
  /// In en, this message translates to:
  /// **'{count} down'**
  String activityPricesDown(int count);

  /// No description provided for @activityShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all {count}'**
  String activityShowAll(int count);

  /// No description provided for @activityShowFewer.
  ///
  /// In en, this message translates to:
  /// **'Show fewer'**
  String get activityShowFewer;

  /// No description provided for @activityCanNow.
  ///
  /// In en, this message translates to:
  /// **'Can now'**
  String get activityCanNow;

  /// No description provided for @activityCanNoLonger.
  ///
  /// In en, this message translates to:
  /// **'Can no longer'**
  String get activityCanNoLonger;

  /// No description provided for @activityEntryNumber.
  ///
  /// In en, this message translates to:
  /// **'Entry {seq} in this device\'s log'**
  String activityEntryNumber(int seq);

  /// No description provided for @activityFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get activityFieldName;

  /// No description provided for @activityFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get activityFieldPhone;

  /// No description provided for @activityFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get activityFieldEmail;

  /// No description provided for @activityFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get activityFieldAddress;

  /// No description provided for @activityFieldEmergencyName.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get activityFieldEmergencyName;

  /// No description provided for @activityFieldEmergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency phone'**
  String get activityFieldEmergencyPhone;

  /// No description provided for @activityFieldIdNumber.
  ///
  /// In en, this message translates to:
  /// **'ID number'**
  String get activityFieldIdNumber;

  /// No description provided for @activityFieldDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get activityFieldDateOfBirth;

  /// No description provided for @activityFieldStartedOn.
  ///
  /// In en, this message translates to:
  /// **'Started on'**
  String get activityFieldStartedOn;

  /// No description provided for @activityFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get activityFieldNotes;

  /// No description provided for @activityFieldRate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get activityFieldRate;

  /// No description provided for @activityFieldCompound.
  ///
  /// In en, this message translates to:
  /// **'Tax on tax'**
  String get activityFieldCompound;

  /// No description provided for @activityFieldKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get activityFieldKind;

  /// No description provided for @activityFieldScope.
  ///
  /// In en, this message translates to:
  /// **'Used on'**
  String get activityFieldScope;

  /// No description provided for @activityFieldReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get activityFieldReason;

  /// No description provided for @activityFieldCounted.
  ///
  /// In en, this message translates to:
  /// **'Items counted'**
  String get activityFieldCounted;

  /// No description provided for @activityFieldChanged.
  ///
  /// In en, this message translates to:
  /// **'Items different'**
  String get activityFieldChanged;

  /// No description provided for @activityFieldStockValue.
  ///
  /// In en, this message translates to:
  /// **'Stock value'**
  String get activityFieldStockValue;

  /// No description provided for @activityFieldTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get activityFieldTotal;

  /// No description provided for @activityFieldSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Before discounts'**
  String get activityFieldSubtotal;

  /// No description provided for @activityFieldDiscountTotal.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get activityFieldDiscountTotal;

  /// No description provided for @activityFieldWithoutReceipt.
  ///
  /// In en, this message translates to:
  /// **'Without a receipt'**
  String get activityFieldWithoutReceipt;

  /// No description provided for @activityFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get activityFieldAmount;

  /// No description provided for @activityFieldCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get activityFieldCost;

  /// No description provided for @activityFieldOwedBefore.
  ///
  /// In en, this message translates to:
  /// **'Owed before'**
  String get activityFieldOwedBefore;

  /// No description provided for @activityFieldMaxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Biggest discount allowed'**
  String get activityFieldMaxDiscount;

  /// No description provided for @toneMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get toneMidnight;

  /// No description provided for @toneLime.
  ///
  /// In en, this message translates to:
  /// **'Lime'**
  String get toneLime;

  /// No description provided for @toneBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get toneBlue;

  /// No description provided for @toneCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get toneCoral;

  /// No description provided for @toneAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get toneAmber;

  /// No description provided for @toneTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get toneTeal;

  /// No description provided for @toneViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get toneViolet;

  /// No description provided for @toneRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get toneRose;

  /// No description provided for @categoriesIconsFood.
  ///
  /// In en, this message translates to:
  /// **'Food and drink'**
  String get categoriesIconsFood;

  /// No description provided for @categoriesIconsShop.
  ///
  /// In en, this message translates to:
  /// **'Other shops'**
  String get categoriesIconsShop;

  /// No description provided for @tillProductCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No products} =1{1 product} other{{count} products}}'**
  String tillProductCount(int count);

  /// No description provided for @auditMomoChargesSet.
  ///
  /// In en, this message translates to:
  /// **'MoMo charges entered'**
  String get auditMomoChargesSet;

  /// No description provided for @settingKindOfShop.
  ///
  /// In en, this message translates to:
  /// **'Kind of shop'**
  String get settingKindOfShop;

  /// No description provided for @settingTargetMargin.
  ///
  /// In en, this message translates to:
  /// **'Target margin'**
  String get settingTargetMargin;

  /// No description provided for @settingVoucherMonths.
  ///
  /// In en, this message translates to:
  /// **'Gift vouchers can be spent for'**
  String get settingVoucherMonths;

  /// No description provided for @settingCommissionRate.
  ///
  /// In en, this message translates to:
  /// **'Commission rate'**
  String get settingCommissionRate;

  /// No description provided for @settingReceiptPart.
  ///
  /// In en, this message translates to:
  /// **'Receipt: {part}'**
  String settingReceiptPart(String part);

  /// No description provided for @settingLogo.
  ///
  /// In en, this message translates to:
  /// **'Logo'**
  String get settingLogo;

  /// No description provided for @settingLogoAdded.
  ///
  /// In en, this message translates to:
  /// **'A logo'**
  String get settingLogoAdded;

  /// No description provided for @settingReceiptCopies.
  ///
  /// In en, this message translates to:
  /// **'Receipt copies for credit sales'**
  String get settingReceiptCopies;

  /// No description provided for @settingScreensPort.
  ///
  /// In en, this message translates to:
  /// **'Screens port'**
  String get settingScreensPort;

  /// No description provided for @settingNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingNone;

  /// No description provided for @settingOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingOn;

  /// No description provided for @settingOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingOff;

  /// No description provided for @settingRemovedItem.
  ///
  /// In en, this message translates to:
  /// **'an item no longer on file'**
  String get settingRemovedItem;

  /// No description provided for @settingChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get settingChanged;

  /// No description provided for @activitySettingChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed {setting}'**
  String activitySettingChanged(String setting);

  /// No description provided for @activitySettingChangedTo.
  ///
  /// In en, this message translates to:
  /// **'{setting}: {before} to {after}'**
  String activitySettingChangedTo(String setting, String before, String after);

  /// No description provided for @licenseTitle.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get licenseTitle;

  /// No description provided for @licenseActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Aby'**
  String get licenseActivateTitle;

  /// No description provided for @licenseSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Aby is a one-time purchase for your shop: one license on the hub covers its devices.'**
  String get licenseSettingsHelp;

  /// No description provided for @licenseNotActivated.
  ///
  /// In en, this message translates to:
  /// **'Not activated'**
  String get licenseNotActivated;

  /// No description provided for @licenseLicensedTo.
  ///
  /// In en, this message translates to:
  /// **'{shop} · {count, plural, =1{1 device} other{{count} devices}}'**
  String licenseLicensedTo(String shop, int count);

  /// No description provided for @licenseViaHub.
  ///
  /// In en, this message translates to:
  /// **'Through the hub: {license}'**
  String licenseViaHub(String license);

  /// No description provided for @licenseFromHub.
  ///
  /// In en, this message translates to:
  /// **'This device uses the hub\'s license.'**
  String get licenseFromHub;

  /// No description provided for @licenseHowTo.
  ///
  /// In en, this message translates to:
  /// **'To buy Aby, send this device code to Aby. You get a license key back: paste it below or open the file.'**
  String get licenseHowTo;

  /// No description provided for @licenseMemberHelp.
  ///
  /// In en, this message translates to:
  /// **'This device is linked to a hub. Activate Aby on the hub and every linked device can sell.'**
  String get licenseMemberHelp;

  /// No description provided for @licenseDeviceCode.
  ///
  /// In en, this message translates to:
  /// **'Device code'**
  String get licenseDeviceCode;

  /// No description provided for @licenseKey.
  ///
  /// In en, this message translates to:
  /// **'License key'**
  String get licenseKey;

  /// No description provided for @licenseReplace.
  ///
  /// In en, this message translates to:
  /// **'New license key (for more devices)'**
  String get licenseReplace;

  /// No description provided for @licenseOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Open a license file'**
  String get licenseOpenFile;

  /// No description provided for @licenseActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get licenseActivate;

  /// No description provided for @licenseActivated.
  ///
  /// In en, this message translates to:
  /// **'Aby is activated. Thank you!'**
  String get licenseActivated;

  /// No description provided for @licenseShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get licenseShop;

  /// No description provided for @licenseDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get licenseDevices;

  /// No description provided for @licenseIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get licenseIssued;

  /// No description provided for @licenseApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Activate Aby'**
  String get licenseApprovalReason;

  /// No description provided for @licenseErrUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That isn\'t a complete license key. Copy all of it and try again.'**
  String get licenseErrUnreadable;

  /// No description provided for @licenseErrForged.
  ///
  /// In en, this message translates to:
  /// **'That license key wasn\'t made by Aby, or it was changed.'**
  String get licenseErrForged;

  /// No description provided for @licenseErrOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'That license is for another device. Check the device code you sent.'**
  String get licenseErrOtherDevice;

  /// No description provided for @licenseErrTooFewDevices.
  ///
  /// In en, this message translates to:
  /// **'That license covers fewer devices than are linked to this hub. Remove devices you no longer use under Hub first.'**
  String get licenseErrTooFewDevices;

  /// No description provided for @licenseBanner.
  ///
  /// In en, this message translates to:
  /// **'Aby isn\'t activated on this device. You can look at reports, export and back up, but not sell or change stock, customers or cash.'**
  String get licenseBanner;

  /// No description provided for @licenseBannerMember.
  ///
  /// In en, this message translates to:
  /// **'The hub this device is linked to isn\'t activated. Activate Aby on the hub to sell here.'**
  String get licenseBannerMember;

  /// No description provided for @hubErrNoSeats.
  ///
  /// In en, this message translates to:
  /// **'The shop\'s license has no room for another device. Remove a device you no longer use, or get a license for more devices.'**
  String get hubErrNoSeats;

  /// No description provided for @auditLicenseActivated.
  ///
  /// In en, this message translates to:
  /// **'Aby activated'**
  String get auditLicenseActivated;

  /// No description provided for @signInHow.
  ///
  /// In en, this message translates to:
  /// **'Type your staff number, then your PIN.'**
  String get signInHow;

  /// No description provided for @signInForgotNumber.
  ///
  /// In en, this message translates to:
  /// **'Forgot your number? A manager can see it under Staff.'**
  String get signInForgotNumber;

  /// No description provided for @signInWrong.
  ///
  /// In en, this message translates to:
  /// **'That number and PIN don\'t match.'**
  String get signInWrong;

  /// No description provided for @signInBadgeRead.
  ///
  /// In en, this message translates to:
  /// **'Badge read. Now your PIN.'**
  String get signInBadgeRead;

  /// No description provided for @signInUseNumber.
  ///
  /// In en, this message translates to:
  /// **'Use my staff number'**
  String get signInUseNumber;

  /// No description provided for @signInPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Your PIN'**
  String get signInPinTitle;

  /// No description provided for @staffNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Your staff number'**
  String get staffNumberTitle;

  /// No description provided for @approvalNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff number of the person approving'**
  String get approvalNumberTitle;

  /// No description provided for @staffNumberChange.
  ///
  /// In en, this message translates to:
  /// **'Staff no. {number} · Change'**
  String staffNumberChange(String number);

  /// No description provided for @staffNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Staff no. {number}'**
  String staffNumberLabel(String number);

  /// No description provided for @setupNumberNote.
  ///
  /// In en, this message translates to:
  /// **'You will be staff number {number}. You sign in with it and your PIN.'**
  String setupNumberNote(String number);

  /// No description provided for @digitsTypeOnKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Type it on the keyboard'**
  String get digitsTypeOnKeyboard;

  /// No description provided for @digitsKeyboardWorks.
  ///
  /// In en, this message translates to:
  /// **'You can also type it on the keyboard'**
  String get digitsKeyboardWorks;

  /// No description provided for @auditStaffRecoveryCodeMade.
  ///
  /// In en, this message translates to:
  /// **'Recovery code made'**
  String get auditStaffRecoveryCodeMade;

  /// No description provided for @auditStaffPinReset.
  ///
  /// In en, this message translates to:
  /// **'Forgotten PIN reset'**
  String get auditStaffPinReset;

  /// No description provided for @forgotPinLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot your PIN?'**
  String get forgotPinLink;

  /// No description provided for @forgotPinIntro.
  ///
  /// In en, this message translates to:
  /// **'Staff: ask a manager or the owner to set a new PIN for you under Staff.\n\nOwners can get back in here.'**
  String get forgotPinIntro;

  /// No description provided for @forgotPinUseCode.
  ///
  /// In en, this message translates to:
  /// **'I have my recovery code'**
  String get forgotPinUseCode;

  /// No description provided for @forgotPinAskSupplier.
  ///
  /// In en, this message translates to:
  /// **'Ask my Aby supplier'**
  String get forgotPinAskSupplier;

  /// No description provided for @recoveryCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery code'**
  String get recoveryCodeLabel;

  /// No description provided for @recoveryCodeWrong.
  ///
  /// In en, this message translates to:
  /// **'That staff number and recovery code don\'t match an owner.'**
  String get recoveryCodeWrong;

  /// No description provided for @supplierRequestIntro.
  ///
  /// In en, this message translates to:
  /// **'Send this request code to your Aby supplier with your shop\'s name. They will check it\'s you and send back a reset code.'**
  String get supplierRequestIntro;

  /// No description provided for @supplierRequestCode.
  ///
  /// In en, this message translates to:
  /// **'Request code'**
  String get supplierRequestCode;

  /// No description provided for @supplierResetCode.
  ///
  /// In en, this message translates to:
  /// **'Reset code from the supplier'**
  String get supplierResetCode;

  /// No description provided for @supplierResetWrong.
  ///
  /// In en, this message translates to:
  /// **'That reset code doesn\'t match this request, or the staff number isn\'t an owner\'s.'**
  String get supplierResetWrong;

  /// No description provided for @supplierGetRequest.
  ///
  /// In en, this message translates to:
  /// **'Get a request code'**
  String get supplierGetRequest;

  /// No description provided for @newPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new PIN'**
  String get newPinTitle;

  /// No description provided for @newPinSave.
  ///
  /// In en, this message translates to:
  /// **'Save and sign in'**
  String get newPinSave;

  /// No description provided for @recoveryCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your recovery code'**
  String get recoveryCodeTitle;

  /// No description provided for @recoveryCodeIntro.
  ///
  /// In en, this message translates to:
  /// **'If you forget your PIN, this code lets you set a new one. Write it down and keep it somewhere safe, away from the till. Aby won\'t show it again.'**
  String get recoveryCodeIntro;

  /// No description provided for @recoveryCodeOnce.
  ///
  /// In en, this message translates to:
  /// **'It works once. After you use it, Aby gives you a new one.'**
  String get recoveryCodeOnce;

  /// No description provided for @recoveryCodeWritten.
  ///
  /// In en, this message translates to:
  /// **'I\'ve written it down'**
  String get recoveryCodeWritten;

  /// No description provided for @recoverySection.
  ///
  /// In en, this message translates to:
  /// **'PIN recovery'**
  String get recoverySection;

  /// No description provided for @recoveryHas.
  ///
  /// In en, this message translates to:
  /// **'You have a recovery code'**
  String get recoveryHas;

  /// No description provided for @recoveryNone.
  ///
  /// In en, this message translates to:
  /// **'No recovery code yet'**
  String get recoveryNone;

  /// No description provided for @recoveryHelp.
  ///
  /// In en, this message translates to:
  /// **'Sets a new PIN if you forget yours. Making a new code stops the old one working.'**
  String get recoveryHelp;

  /// No description provided for @recoveryMake.
  ///
  /// In en, this message translates to:
  /// **'Make a code'**
  String get recoveryMake;

  /// No description provided for @recoveryMakeNew.
  ///
  /// In en, this message translates to:
  /// **'Make a new code'**
  String get recoveryMakeNew;

  /// No description provided for @recoveryConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Your PIN, to make a new code'**
  String get recoveryConfirmPin;

  /// No description provided for @statusRecovery.
  ///
  /// In en, this message translates to:
  /// **'PIN recovery code'**
  String get statusRecovery;

  /// No description provided for @statusRecoveryMissing.
  ///
  /// In en, this message translates to:
  /// **'You have no recovery code. Without one, a forgotten PIN needs your Aby supplier.'**
  String get statusRecoveryMissing;

  /// No description provided for @statusRecoveryOk.
  ///
  /// In en, this message translates to:
  /// **'You have one.'**
  String get statusRecoveryOk;

  /// No description provided for @forgotPinHaveResetCode.
  ///
  /// In en, this message translates to:
  /// **'I have my supplier\'s reset code'**
  String get forgotPinHaveResetCode;

  /// No description provided for @supplierWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your supplier'**
  String get supplierWaiting;

  /// No description provided for @supplierWaitNote.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to wait here. Close this and the till keeps working for everyone else. This request stays open on this till until {date}. When your supplier replies, tap \"Enter your supplier\'s reset code\" on the sign-in screen.'**
  String supplierWaitNote(String date);

  /// No description provided for @supplierStartAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get supplierStartAgain;

  /// No description provided for @forgotPinCloseForNow.
  ///
  /// In en, this message translates to:
  /// **'Close for now'**
  String get forgotPinCloseForNow;

  /// No description provided for @signInResetWaiting.
  ///
  /// In en, this message translates to:
  /// **'Enter your supplier\'s reset code'**
  String get signInResetWaiting;

  /// No description provided for @auditStaffPinResetCancelled.
  ///
  /// In en, this message translates to:
  /// **'PIN reset request cancelled'**
  String get auditStaffPinResetCancelled;

  /// No description provided for @auditTimeEntryCorrected.
  ///
  /// In en, this message translates to:
  /// **'Hours corrected'**
  String get auditTimeEntryCorrected;

  /// No description provided for @resetRequestDropped.
  ///
  /// In en, this message translates to:
  /// **'Welcome back. Your PIN reset request is cancelled, so a reset code from your supplier won\'t work now. Let them know you don\'t need it.'**
  String get resetRequestDropped;

  /// No description provided for @settingsDayMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight to midnight, like the calendar.'**
  String get settingsDayMidnight;

  /// No description provided for @settingsDayRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs {start} to {end} the next morning. Sales before {start} count on the day before.'**
  String settingsDayRuns(String start, String end);

  /// No description provided for @settingsDayRunsShort.
  ///
  /// In en, this message translates to:
  /// **'Until {end} the next morning'**
  String settingsDayRunsShort(String end);

  /// No description provided for @settingsMidnight.
  ///
  /// In en, this message translates to:
  /// **'Midnight'**
  String get settingsMidnight;

  /// No description provided for @settingsBackupEvery.
  ///
  /// In en, this message translates to:
  /// **'Back up every'**
  String get settingsBackupEvery;

  /// No description provided for @settingsBackupEveryHelp.
  ///
  /// In en, this message translates to:
  /// **'Skipped when nothing has changed since the last one.'**
  String get settingsBackupEveryHelp;

  /// No description provided for @settingsBackupDaily.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get settingsBackupDaily;

  /// No description provided for @settingsEveryHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get settingsEveryHour;

  /// No description provided for @settingsBackupNextAt.
  ///
  /// In en, this message translates to:
  /// **'next at {time}'**
  String settingsBackupNextAt(String time);

  /// No description provided for @settingsBackupsKeepHelp.
  ///
  /// In en, this message translates to:
  /// **'The newest {count}, and one a day for {count} days before them.'**
  String settingsBackupsKeepHelp(int count);

  /// No description provided for @backupFolder.
  ///
  /// In en, this message translates to:
  /// **'Backup folder'**
  String get backupFolder;

  /// No description provided for @backupFolderOpen.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get backupFolderOpen;

  /// No description provided for @backupFolderCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get backupFolderCopy;

  /// No description provided for @backupFolderCopied.
  ///
  /// In en, this message translates to:
  /// **'Folder path copied.'**
  String get backupFolderCopied;

  /// No description provided for @backupFolderCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the folder. Copy its path from Settings instead.'**
  String get backupFolderCouldNotOpen;

  /// No description provided for @statusBackingUp.
  ///
  /// In en, this message translates to:
  /// **'Backing up…'**
  String get statusBackingUp;

  /// No description provided for @statusBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Backed up'**
  String get statusBackedUp;

  /// No description provided for @statusAutoBackupOff.
  ///
  /// In en, this message translates to:
  /// **'Automatic backups are off.'**
  String get statusAutoBackupOff;

  /// No description provided for @statusBackupNext.
  ///
  /// In en, this message translates to:
  /// **'Next automatic backup at {time}.'**
  String statusBackupNext(String time);

  /// No description provided for @statusChipLocal.
  ///
  /// In en, this message translates to:
  /// **'Backup due'**
  String get statusChipLocal;

  /// No description provided for @statusChipOffsite.
  ///
  /// In en, this message translates to:
  /// **'Copy a backup off'**
  String get statusChipOffsite;

  /// No description provided for @statusChipLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log changed'**
  String get statusChipLog;

  /// No description provided for @statusChipSync.
  ///
  /// In en, this message translates to:
  /// **'Hub offline'**
  String get statusChipSync;

  /// No description provided for @statusChipPrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer problem'**
  String get statusChipPrinter;

  /// No description provided for @statusChipRecovery.
  ///
  /// In en, this message translates to:
  /// **'No recovery code'**
  String get statusChipRecovery;

  /// No description provided for @statusChipAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts pack failed'**
  String get statusChipAccounts;

  /// No description provided for @statusChipMore.
  ///
  /// In en, this message translates to:
  /// **'{label} +{count}'**
  String statusChipMore(String label, int count);

  /// No description provided for @saleDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Sale {number}'**
  String saleDetailTitle(String number);

  /// No description provided for @saleDetailServedBy.
  ///
  /// In en, this message translates to:
  /// **'Served by {name}'**
  String saleDetailServedBy(String name);

  /// No description provided for @saleDetailOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order {number}'**
  String saleDetailOrderNumber(String number);

  /// No description provided for @saleDetailVoided.
  ///
  /// In en, this message translates to:
  /// **'Voided by {name}, {when}. It counts for nothing.'**
  String saleDetailVoided(String name, String when);

  /// No description provided for @saleDetailRefunded.
  ///
  /// In en, this message translates to:
  /// **'{amount} refunded'**
  String saleDetailRefunded(String amount);

  /// No description provided for @saleDetailRefundedAll.
  ///
  /// In en, this message translates to:
  /// **'Refunded in full'**
  String get saleDetailRefundedAll;

  /// No description provided for @saleDetailItems.
  ///
  /// In en, this message translates to:
  /// **'What was bought'**
  String get saleDetailItems;

  /// No description provided for @saleDetailPriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Menu price {price}, changed by {name}'**
  String saleDetailPriceChanged(String price, String name);

  /// No description provided for @saleDetailPriceTyped.
  ///
  /// In en, this message translates to:
  /// **'Price typed at the till (suggested {price})'**
  String saleDetailPriceTyped(String price);

  /// No description provided for @saleDetailDiscountTag.
  ///
  /// In en, this message translates to:
  /// **'{label} off: {reason}'**
  String saleDetailDiscountTag(String label, String reason);

  /// No description provided for @saleDetailApprovedBy.
  ///
  /// In en, this message translates to:
  /// **'approved by {name}'**
  String saleDetailApprovedBy(String name);

  /// No description provided for @saleDetailPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get saleDetailPromotion;

  /// No description provided for @saleDetailSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get saleDetailSubtotal;

  /// No description provided for @saleDetailItemDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Item discounts'**
  String get saleDetailItemDiscounts;

  /// No description provided for @saleDetailPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get saleDetailPromotions;

  /// No description provided for @saleDetailOrderDiscount.
  ///
  /// In en, this message translates to:
  /// **'Order discount'**
  String get saleDetailOrderDiscount;

  /// No description provided for @saleDetailTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get saleDetailTax;

  /// No description provided for @saleDetailTaxIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes tax'**
  String get saleDetailTaxIncluded;

  /// No description provided for @saleDetailRounding.
  ///
  /// In en, this message translates to:
  /// **'Rounding'**
  String get saleDetailRounding;

  /// No description provided for @saleDetailTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get saleDetailTotal;

  /// No description provided for @saleDetailPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get saleDetailPayments;

  /// No description provided for @saleDetailGiven.
  ///
  /// In en, this message translates to:
  /// **'Given {amount}'**
  String saleDetailGiven(String amount);

  /// No description provided for @saleDetailChange.
  ///
  /// In en, this message translates to:
  /// **'Change {amount}'**
  String saleDetailChange(String amount);

  /// No description provided for @saleDetailRef.
  ///
  /// In en, this message translates to:
  /// **'Ref {reference}'**
  String saleDetailRef(String reference);

  /// No description provided for @saleDetailCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get saleDetailCost;

  /// No description provided for @saleDetailProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get saleDetailProfit;

  /// No description provided for @saleDetailMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get saleDetailMargin;

  /// No description provided for @saleDetailRefunds.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get saleDetailRefunds;

  /// No description provided for @saleDetailRefundLine.
  ///
  /// In en, this message translates to:
  /// **'{number}  ·  {when}  ·  {name}: {reason}'**
  String saleDetailRefundLine(
    String number,
    String when,
    String name,
    String reason,
  );

  /// No description provided for @saleDetailHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get saleDetailHistory;

  /// No description provided for @saleDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get saleDetailNote;

  /// No description provided for @saleDetailGone.
  ///
  /// In en, this message translates to:
  /// **'This sale could not be found.'**
  String get saleDetailGone;

  /// No description provided for @saleDetailOpen.
  ///
  /// In en, this message translates to:
  /// **'See the whole sale'**
  String get saleDetailOpen;

  /// No description provided for @todayDiscountOff.
  ///
  /// In en, this message translates to:
  /// **'{amount} off'**
  String todayDiscountOff(String amount);

  /// No description provided for @todayMoreItems.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String todayMoreItems(int count);

  /// No description provided for @stockImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import stock'**
  String get stockImportTitle;

  /// No description provided for @stockImportIntro.
  ///
  /// In en, this message translates to:
  /// **'Add or update many stock items at once from a spreadsheet: one row per item. The counts in the file become what you have on hand.'**
  String get stockImportIntro;

  /// No description provided for @stockImportStep1.
  ///
  /// In en, this message translates to:
  /// **'Download the sample, or start from the stock you already have.'**
  String get stockImportStep1;

  /// No description provided for @stockImportStep2.
  ///
  /// In en, this message translates to:
  /// **'Fill in your items in Excel or Google Sheets.'**
  String get stockImportStep2;

  /// No description provided for @stockImportColItem.
  ///
  /// In en, this message translates to:
  /// **'Needed. A name already here updates that item.'**
  String get stockImportColItem;

  /// No description provided for @stockImportColUnit.
  ///
  /// In en, this message translates to:
  /// **'How it is kept: piece, g or ml.'**
  String get stockImportColUnit;

  /// No description provided for @stockImportColCostPer.
  ///
  /// In en, this message translates to:
  /// **'What the cost and counts are in: pcs, kg, g, L or ml.'**
  String get stockImportColCostPer;

  /// No description provided for @stockImportColCost.
  ///
  /// In en, this message translates to:
  /// **'What you pay for one of cost_per, in cedis.'**
  String get stockImportColCost;

  /// No description provided for @stockImportColOnHand.
  ///
  /// In en, this message translates to:
  /// **'How many you have now. Leave it empty to keep the count.'**
  String get stockImportColOnHand;

  /// No description provided for @stockImportColLowBelow.
  ///
  /// In en, this message translates to:
  /// **'Warn when stock falls to this.'**
  String get stockImportColLowBelow;

  /// No description provided for @stockImportStartFromMine.
  ///
  /// In en, this message translates to:
  /// **'Start from my stock instead'**
  String get stockImportStartFromMine;

  /// No description provided for @stockImportFooter.
  ///
  /// In en, this message translates to:
  /// **'Importing adds stock items and updates costs and counts. It never removes anything.'**
  String get stockImportFooter;

  /// No description provided for @stockImportRecounted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 count changes. It is recorded as an adjustment.} other{{count} counts change. Each is recorded as an adjustment.}}'**
  String stockImportRecounted(int count);

  /// No description provided for @stockImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get stockImportButton;

  /// No description provided for @fromStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Products from stock'**
  String get fromStockTitle;

  /// No description provided for @fromStockButton.
  ///
  /// In en, this message translates to:
  /// **'Make products'**
  String get fromStockButton;

  /// No description provided for @fromStockIntro.
  ///
  /// In en, this message translates to:
  /// **'Tick the stock items you sell as they are. Each becomes a product that takes stock off when sold, priced from its cost.'**
  String get fromStockIntro;

  /// No description provided for @fromStockMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get fromStockMargin;

  /// No description provided for @fromStockMarkup.
  ///
  /// In en, this message translates to:
  /// **'Markup'**
  String get fromStockMarkup;

  /// No description provided for @fromStockMarginHelp.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of each price is profit.'**
  String fromStockMarginHelp(String percent);

  /// No description provided for @fromStockMarkupHelp.
  ///
  /// In en, this message translates to:
  /// **'{percent}% is added to each cost.'**
  String fromStockMarkupHelp(String percent);

  /// No description provided for @fromStockPercentInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a margin below 100%.'**
  String get fromStockPercentInvalid;

  /// No description provided for @fromStockCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fromStockCategory;

  /// No description provided for @fromStockNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category…'**
  String get fromStockNewCategory;

  /// No description provided for @fromStockNewCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Name of the new category'**
  String get fromStockNewCategoryName;

  /// No description provided for @fromStockOnTill.
  ///
  /// In en, this message translates to:
  /// **'Put them on the till'**
  String get fromStockOnTill;

  /// No description provided for @fromStockAll.
  ///
  /// In en, this message translates to:
  /// **'Tick all'**
  String get fromStockAll;

  /// No description provided for @fromStockNone.
  ///
  /// In en, this message translates to:
  /// **'Untick all'**
  String get fromStockNone;

  /// No description provided for @fromStockAlreadySold.
  ///
  /// In en, this message translates to:
  /// **'Already sold as a product'**
  String get fromStockAlreadySold;

  /// No description provided for @fromStockNameTaken.
  ///
  /// In en, this message translates to:
  /// **'A product has this name'**
  String get fromStockNameTaken;

  /// No description provided for @fromStockNoCost.
  ///
  /// In en, this message translates to:
  /// **'No cost: tap the price to type one'**
  String get fromStockNoCost;

  /// No description provided for @fromStockCostLine.
  ///
  /// In en, this message translates to:
  /// **'Cost {amount}'**
  String fromStockCostLine(String amount);

  /// No description provided for @fromStockPerUnit.
  ///
  /// In en, this message translates to:
  /// **'{amount} per {unit}'**
  String fromStockPerUnit(String amount, String unit);

  /// No description provided for @fromStockProfit.
  ///
  /// In en, this message translates to:
  /// **'{amount} profit'**
  String fromStockProfit(String amount);

  /// No description provided for @fromStockTypePrice.
  ///
  /// In en, this message translates to:
  /// **'Price for {name}'**
  String fromStockTypePrice(String name);

  /// No description provided for @fromStockCreate.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Make products} =1{Make 1 product} other{Make {count} products}}'**
  String fromStockCreate(int count);

  /// No description provided for @fromStockDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product made.} other{{count} products made.}}'**
  String fromStockDone(int count);

  /// No description provided for @fromStockEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stock items to make products from. Add stock items first, or import them.'**
  String get fromStockEmpty;

  /// No description provided for @fromStockReason.
  ///
  /// In en, this message translates to:
  /// **'Make products from stock'**
  String get fromStockReason;

  /// No description provided for @receiveOrdered.
  ///
  /// In en, this message translates to:
  /// **'Ordered {ordered}  ·  {received} received before'**
  String receiveOrdered(String ordered, String received);

  /// No description provided for @receiveOrderedOnly.
  ///
  /// In en, this message translates to:
  /// **'Ordered {ordered}'**
  String receiveOrderedOnly(String ordered);

  /// No description provided for @receiveZeroHelp.
  ///
  /// In en, this message translates to:
  /// **'Put 0 for what did not come. The order waits for it.'**
  String get receiveZeroHelp;

  /// No description provided for @receiveNothing.
  ///
  /// In en, this message translates to:
  /// **'Enter what came: nothing on this delivery has a quantity.'**
  String get receiveNothing;

  /// No description provided for @receiveFromWhich.
  ///
  /// In en, this message translates to:
  /// **'Is this delivery for an order?'**
  String get receiveFromWhich;

  /// No description provided for @receiveWithoutOrder.
  ///
  /// In en, this message translates to:
  /// **'No, receive without an order'**
  String get receiveWithoutOrder;

  /// No description provided for @receiveOrderLine.
  ///
  /// In en, this message translates to:
  /// **'{number}  ·  {supplier}  ·  {items}'**
  String receiveOrderLine(String number, String supplier, String items);

  /// No description provided for @receiveSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery {number} received'**
  String receiveSummaryTitle(String number);

  /// No description provided for @receiveSummaryStock.
  ///
  /// In en, this message translates to:
  /// **'Stock now'**
  String get receiveSummaryStock;

  /// No description provided for @receiveSummaryOnHand.
  ///
  /// In en, this message translates to:
  /// **'{before} → {after}'**
  String receiveSummaryOnHand(String before, String after);

  /// No description provided for @receiveSummaryCost.
  ///
  /// In en, this message translates to:
  /// **'Cost {before} → {after} per {unit}'**
  String receiveSummaryCost(String before, String after, String unit);

  /// No description provided for @receiveSummaryOrderDone.
  ///
  /// In en, this message translates to:
  /// **'Order {number} is fully delivered.'**
  String receiveSummaryOrderDone(String number);

  /// No description provided for @receiveSummaryOrderWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Order {number} still waits for 1 item.} other{Order {number} still waits for {count} items.}}'**
  String receiveSummaryOrderWaiting(int count, String number);

  /// No description provided for @receiveSummaryLowMargin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product is now below your {target}% margin: {names}.} other{{count} products are now below your {target}% margin: {names}.}}'**
  String receiveSummaryLowMargin(int count, String target, String names);

  /// No description provided for @receiveSummaryReview.
  ///
  /// In en, this message translates to:
  /// **'Review prices'**
  String get receiveSummaryReview;

  /// No description provided for @receiveSummaryLabels.
  ///
  /// In en, this message translates to:
  /// **'Print labels'**
  String get receiveSummaryLabels;

  /// No description provided for @stockImportColSupplier.
  ///
  /// In en, this message translates to:
  /// **'Who you buy it from. A new name becomes a new supplier.'**
  String get stockImportColSupplier;

  /// No description provided for @stockImportColOrderQty.
  ///
  /// In en, this message translates to:
  /// **'How much you usually order, in cost_per units.'**
  String get stockImportColOrderQty;

  /// No description provided for @stockImportNewSuppliers.
  ///
  /// In en, this message translates to:
  /// **'New suppliers: {names}'**
  String stockImportNewSuppliers(String names);

  /// No description provided for @fileOpenToPrint.
  ///
  /// In en, this message translates to:
  /// **'Open to print'**
  String get fileOpenToPrint;

  /// No description provided for @fileOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be opened. Save it to a folder and open it from there.'**
  String get fileOpenFailed;

  /// No description provided for @deliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery {number}'**
  String deliveryTitle(String number);

  /// No description provided for @deliveryFrom.
  ///
  /// In en, this message translates to:
  /// **'From {supplier}'**
  String deliveryFrom(String supplier);

  /// No description provided for @deliveryAgainstOrder.
  ///
  /// In en, this message translates to:
  /// **'For order {number}'**
  String deliveryAgainstOrder(String number);

  /// No description provided for @deliveryPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get deliveryPaid;

  /// No description provided for @deliveryOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed'**
  String get deliveryOwed;

  /// No description provided for @deliveryPdf.
  ///
  /// In en, this message translates to:
  /// **'Save or print'**
  String get deliveryPdf;

  /// No description provided for @deliveryShareText.
  ///
  /// In en, this message translates to:
  /// **'Goods received {number}'**
  String deliveryShareText(String number);

  /// No description provided for @deliveryEach.
  ///
  /// In en, this message translates to:
  /// **'{amount} per {unit}'**
  String deliveryEach(String amount, String unit);

  /// No description provided for @stockNewItemInline.
  ///
  /// In en, this message translates to:
  /// **'New stock item…'**
  String get stockNewItemInline;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
