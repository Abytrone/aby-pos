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
  /// **'For example Toppings, Sugar level or Sauce.'**
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
  /// **'Barcodes'**
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
  /// **'Type it, or scan it with a barcode scanner.'**
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

  /// No description provided for @stockHowMuch.
  ///
  /// In en, this message translates to:
  /// **'How much'**
  String get stockHowMuch;

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
  /// **'Cost of these'**
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

  /// No description provided for @importHelp.
  ///
  /// In en, this message translates to:
  /// **'Columns: {columns}. Import adds products and updates prices, costs and barcodes. It never removes anything.'**
  String importHelp(String columns);

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
