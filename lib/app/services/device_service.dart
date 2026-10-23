import 'package:get/get.dart';

import '../data/database/app_database.dart';

/// Which device records come from. Repositories depend on this, not on
/// GetX, so tests can pass a fixed device.
abstract interface class DeviceInfo {
  String get deviceId;
}

/// Loads this device's identity from the local database. The ID is created
/// once, on first open, and never changes.
class DeviceService extends GetxService implements DeviceInfo {
  DeviceService(this._db);

  final AppDatabase _db;

  /// Completes once the database is open (migrated, and seeded on first
  /// run). Await before reading [deviceId].
  late final Future<void> ready = _load();

  @override
  late final String deviceId;

  Future<void> _load() async {
    deviceId = (await _db.readMeta(MetaKeys.deviceId))!;
  }
}
