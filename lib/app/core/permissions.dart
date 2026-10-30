/// Everything a role can be allowed to do. Stored by name in roles, so never
/// rename a value without a migration. Features that are not built yet
/// already have their permission, so roles set up today keep working.
enum Permission {
  // Sell
  sell(PermissionGroup.sell),
  overridePrice(PermissionGroup.sell),
  refund(PermissionGroup.sell),
  refundWithoutReceipt(PermissionGroup.sell),
  voidSale(PermissionGroup.sell),
  noSale(PermissionGroup.sell),

  // Products and stock
  editProducts(PermissionGroup.catalogue),
  changePrices(PermissionGroup.catalogue),
  receiveStock(PermissionGroup.catalogue),
  adjustStock(PermissionGroup.catalogue),
  approveStockCount(PermissionGroup.catalogue),

  // Customers
  manageCustomers(PermissionGroup.customers),
  giveCredit(PermissionGroup.customers),
  writeOffCredit(PermissionGroup.customers),

  // Cash
  closeDay(PermissionGroup.cash),
  payOut(PermissionGroup.cash),
  manageCash(PermissionGroup.cash),
  manageExpenses(PermissionGroup.cash),

  // Reports
  viewReports(PermissionGroup.reports),
  viewCostAndProfit(PermissionGroup.reports),

  // Admin
  manageStaff(PermissionGroup.admin),
  manageRoles(PermissionGroup.admin),
  changeSettings(PermissionGroup.admin),

  /// Pair, rename and remove devices, run or join the hub, and place this
  /// device in a branch. Managers have it unless the owner turns it off.
  manageDevices(PermissionGroup.admin),
  viewActivityLog(PermissionGroup.admin),
  exportData(PermissionGroup.admin),
  restoreBackup(PermissionGroup.admin);

  const Permission(this.group);
  final PermissionGroup group;
}

enum PermissionGroup { sell, catalogue, customers, cash, reports, admin }

extension PermissionLicensing on Permission {
  /// Allowed without a license: looking at the shop's data, exporting and
  /// backing it up, and the admin side (staff, settings, devices), so the
  /// owner is never locked out of their own books. Selling, stock,
  /// customers and cash need a license.
  bool get worksUnlicensed => group == PermissionGroup.reports || group == PermissionGroup.admin;
}

/// What anyone on this device may do at all, whatever their role. Everything
/// until LicenseService narrows it.
abstract final class PermissionGate {
  static bool Function(Permission permission) allows = everything;

  static bool everything(Permission _) => true;
}

/// Roles every shop starts with. Their IDs are fixed so that devices of the
/// same shop create the same rows and sync never duplicates them.
enum BuiltInRole {
  owner('00000000-0000-7000-8000-00000000a001'),
  manager('00000000-0000-7000-8000-00000000a002'),
  cashier('00000000-0000-7000-8000-00000000a003'),
  stockKeeper('00000000-0000-7000-8000-00000000a004');

  const BuiltInRole(this.id);
  final String id;

  /// Owners can always do everything; their list is not used.
  Set<Permission> get defaultPermissions => switch (this) {
        BuiltInRole.owner => Permission.values.toSet(),
        BuiltInRole.manager => Permission.values.toSet()
          ..removeAll({
            Permission.manageRoles,
            Permission.restoreBackup,
            Permission.writeOffCredit,
          }),
        BuiltInRole.cashier => {Permission.sell, Permission.closeDay},
        BuiltInRole.stockKeeper => {
            Permission.receiveStock,
            Permission.adjustStock,
            Permission.editProducts,
          },
      };

  /// Highest manual discount without approval, in percent.
  int get defaultMaxDiscount => switch (this) {
        BuiltInRole.owner => 100,
        BuiltInRole.manager => 50,
        BuiltInRole.cashier => 10,
        BuiltInRole.stockKeeper => 0,
      };
}
