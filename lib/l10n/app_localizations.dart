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

  /// No description provided for @signInPickName.
  ///
  /// In en, this message translates to:
  /// **'Pick your name.'**
  String get signInPickName;

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

  /// No description provided for @userSwitchNobody.
  ///
  /// In en, this message translates to:
  /// **'There is nobody else to switch to.'**
  String get userSwitchNobody;

  /// No description provided for @approvalTitle.
  ///
  /// In en, this message translates to:
  /// **'Approval needed'**
  String get approvalTitle;

  /// No description provided for @approvalPinTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN of the person approving'**
  String get approvalPinTitle;

  /// No description provided for @approvalWrongPin.
  ///
  /// In en, this message translates to:
  /// **'That PIN can\'t approve this.'**
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
  /// **'Day starts at'**
  String get settingsDayStart;

  /// No description provided for @settingsDayStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Sales before this time count on the previous day.'**
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
  /// **'Colours'**
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
  /// **'Back up every day'**
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

  /// No description provided for @pinMustBeDigits.
  ///
  /// In en, this message translates to:
  /// **'The PIN must be {count} digits.'**
  String pinMustBeDigits(int count);

  /// No description provided for @pinTooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait {seconds} seconds.'**
  String pinTooManyTries(int seconds);

  /// No description provided for @pinFor.
  ///
  /// In en, this message translates to:
  /// **'PIN for {name}'**
  String pinFor(String name);

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
  /// **'{name} added.'**
  String staffAdded(String name);

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
