import 'package:get/get.dart';

import '../data/database/app_database.dart';

/// Who and where a record comes from. Repositories depend on this, not on
/// GetX, so tests can pass a fixed device.
abstract interface class DeviceInfo {
  String get deviceId;
  String get shopName;
}

/// Loads this device's identity from the local database. The ID is created
/// once, on first open, and never changes.
class DeviceService extends GetxService implements DeviceInfo {
  DeviceService(this._db);

  final AppDatabase _db;

  /// Completes once the database is open (and seeded on first run) and the
  /// device details are loaded. Await before reading the fields.
  late final Future<void> ready = _load();

  @override
  late final String deviceId;
  @override
  late final String shopName;

  Future<void> _load() async {
    deviceId = (await _db.readMeta(MetaKeys.deviceId))!;
    shopName = await _db.readMeta(MetaKeys.shopName) ?? 'My shop';
  }
}
