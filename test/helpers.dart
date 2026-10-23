import 'package:aby_pos/app/data/database/app_database.dart';
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
  @override
  String get shopName => 'Test shop';
}

const owner = Staff(id: 'st-owner', name: 'Kofi', role: StaffRole.owner);
const cashier = Staff(id: 'st-cashier', name: 'Ama', role: StaffRole.cashier);

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
