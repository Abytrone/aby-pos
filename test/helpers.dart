import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/audit_repository.dart';
import 'package:aby_pos/app/data/repositories/day_close_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/device_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// A fresh in-memory database, seeded with the Scoops Tamale menu unless
/// [seed] is false. Streams close synchronously so widget tests are not left
/// with drift's cleanup timer.
AppDatabase memoryDb({bool seed = true}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    seed,
  );
}

class FakeDevice implements DeviceInfo {
  FakeDevice(this.deviceId);

  @override
  final String deviceId;
}

Role builtInRole(BuiltInRole r, String name) => Role(
      id: r.id,
      name: name,
      builtIn: r,
      permissions: r.defaultPermissions,
      maxDiscountPercent: r.defaultMaxDiscount,
    );

final ownerRole = builtInRole(BuiltInRole.owner, 'Owner');
final cashierRole = builtInRole(BuiltInRole.cashier, 'Cashier');

/// Not stored: fine wherever only the ID and name are written (sales, audit).
final owner = Staff(id: 'st-owner', name: 'Kofi', role: ownerRole);
final cashier = Staff(id: 'st-cashier', name: 'Ama', role: cashierRole);

/// Every repository wired to one database, as InitialBinding does.
class Repos {
  Repos._(this.db, this.device) : audit = AuditRepository(db, device) {
    stock = StockRepository(db, device);
    closes = DayCloseRepository(db, device, audit);
    sales = SaleRepository(db, stock, closes, audit, device);
    staff = StaffRepository(db, device, audit);
  }

  static Future<Repos> open(AppDatabase db) async =>
      Repos._(db, FakeDevice((await db.readMeta(MetaKeys.deviceId))!));

  final AppDatabase db;
  final FakeDevice device;
  final AuditRepository audit;
  late final StockRepository stock;
  late final DayCloseRepository closes;
  late final SaleRepository sales;
  late final StaffRepository staff;
}

/// Catalogue fixtures, prices in pesewas.
const sprinkles = Addon(id: 'a-sprinkles', name: 'Sprinkles', price: 300);
const crunch = Addon(id: 'a-crunch', name: 'Groundnut crunch', price: 500);
const single = Variant(id: 'v-single', name: 'Single scoop', price: 1500);
const double_ = Variant(id: 'v-double', name: 'Double scoop', price: 2200);

const vanillaCone = Product(
  id: 'p-vanilla',
  categoryId: 'c-cones',
  name: 'Vanilla cone',
  basePrice: 1500,
  variants: [single, double_],
  addons: [sprinkles, crunch],
);

const waffle = Product(
  id: 'p-waffle',
  categoryId: 'c-snacks',
  name: 'Waffle',
  basePrice: 1200,
  addons: [sprinkles],
);
