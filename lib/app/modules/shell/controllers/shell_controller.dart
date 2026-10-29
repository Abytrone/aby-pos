import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/branch_scope.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';
import '../../../services/session_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/status_service.dart';
import '../../../services/sync_service.dart';
import '../../../ui/l10n.dart';
import '../widgets/command_bar.dart';

enum Workspace { sell, manage }

/// The places in the app. A section shows only to people allowed [permission]
/// (null: everyone signed in).
enum ShellSection {
  sell(Icons.point_of_sale_outlined, Icons.point_of_sale, Workspace.sell, {Permission.sell}),
  today(Icons.today_outlined, Icons.today, Workspace.sell, null),

  /// Only when the shop uses order numbers (SEL-11).
  orders(Icons.receipt_long_outlined, Icons.receipt_long, Workspace.sell, {Permission.sell}),
  dashboard(Icons.dashboard_outlined, Icons.dashboard, Workspace.manage, {Permission.viewReports}),
  products(Icons.sell_outlined, Icons.sell, Workspace.manage, {Permission.editProducts, Permission.changePrices}),
  stock(Icons.inventory_2_outlined, Icons.inventory_2, Workspace.manage,
      {Permission.receiveStock, Permission.adjustStock, Permission.approveStockCount}),
  customers(Icons.people_outline, Icons.people, Workspace.manage, {Permission.manageCustomers, Permission.giveCredit}),
  money(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, Workspace.manage,
      {Permission.manageExpenses, Permission.viewCostAndProfit}),
  reports(Icons.bar_chart_outlined, Icons.bar_chart, Workspace.manage, {Permission.viewReports}),
  staff(Icons.badge_outlined, Icons.badge, Workspace.manage, {Permission.manageStaff}),
  activity(Icons.history_outlined, Icons.history, Workspace.manage, {Permission.viewActivityLog}),
  settings(Icons.settings_outlined, Icons.settings, Workspace.manage, null);

  const ShellSection(this.icon, this.selectedIcon, this.workspace, this.anyOf);

  final IconData icon;
  final IconData selectedIcon;
  final Workspace workspace;

  /// Shown to people with any of these; null for everyone signed in.
  final Set<Permission>? anyOf;

  String label(AppLocalizations l) => switch (this) {
        ShellSection.sell => l.navSell,
        ShellSection.today => l.navToday,
        ShellSection.orders => l.navOrders,
        ShellSection.dashboard => l.navDashboard,
        ShellSection.products => l.navProducts,
        ShellSection.stock => l.navStock,
        ShellSection.customers => l.navCustomers,
        ShellSection.money => l.navMoney,
        ShellSection.reports => l.navReports,
        ShellSection.staff => l.navStaff,
        ShellSection.activity => l.navActivity,
        ShellSection.settings => l.navSettings,
      };
}

class ShellController extends GetxController {
  final AuthService auth = Get.find();
  final SettingsService _settings = Get.find();
  final StatusService status = Get.find();
  final SyncService sync = Get.find();
  final SessionService _session = Get.find();
  final StaffRepository _staff = Get.find();

  final section = ShellSection.sell.obs;

  /// Sections built so far; others stay unbuilt until first opened.
  final visited = <ShellSection>{}.obs;

  StreamSubscription<Staff?>? _userSub;

  /// Reactive: reads the signed-in person.
  List<ShellSection> get sections => [
        for (final s in ShellSection.values)
          if ((s.anyOf == null || s.anyOf!.any(auth.can)) && (s != ShellSection.orders || _settings.get(AppSettings.ordersOn))) s,
      ];

  String get shopName => _settings.get(AppSettings.shopName);

  @override
  void onInit() {
    super.onInit();
    _ensureAllowed();
    _userSub = auth.currentUser.listen((_) => _ensureAllowed());
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  /// Ctrl+K opens the command bar (APP-03).
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || e.logicalKey != LogicalKeyboardKey.keyK) return false;
    if (!HardwareKeyboard.instance.isControlPressed || auth.currentUser.value == null) return false;
    unawaited(showCommandBar());
    return true;
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _userSub?.cancel();
    super.onClose();
  }

  void select(ShellSection s) {
    if (!sections.contains(s)) return;
    visited.add(s);
    section.value = s;
  }

  /// After a user switch, leave a section the new person cannot see.
  void _ensureAllowed() {
    final allowed = sections;
    if (allowed.isEmpty) return;
    if (!allowed.contains(section.value)) section.value = allowed.first;
    visited.add(section.value);
  }

  Future<void> lock() => _session.lockNow();

  void openMyProfile() => Get.toNamed<void>(Routes.staffProfile, arguments: auth.user.id);

  Future<List<Staff>> switchCandidates() async =>
      (await _staff.list(atBranch: await Get.find<AppDatabase>().branchOf(Get.find<DeviceService>().deviceId)))
          .where((s) => s != auth.currentUser.value)
          .toList();

  /// Returns an error message, or null once switched.
  Future<String?> switchTo(Staff person, String pin) async {
    final l = appL10n();
    switch (await auth.signIn(person, pin)) {
      case SignInResult.ok:
        return null;
      case SignInResult.wrongPin:
        return l.pinWrong;
      case SignInResult.lockedOut:
        return l.pinTooManyTries(auth.lockedFor(person.id)?.inSeconds ?? AuthService.lockout.inSeconds);
    }
  }
}
