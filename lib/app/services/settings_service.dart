import 'package:get/get.dart';

import '../core/settings.dart';
import '../data/repositories/settings_repository.dart';
import '../models/staff.dart';

/// Settings in memory, reactive: reading one inside Obx rebuilds when it
/// changes. Load once at start ([load]); writes go to the database first.
class SettingsService extends GetxService {
  SettingsService(this._repo);

  final SettingsRepository _repo;
  final _values = <String, Object?>{}.obs;

  Future<void> load() async => _values.assignAll(await _repo.loadAll());

  T get<T extends Object>(Setting<T> setting) => setting.decode(_values[setting.key]);

  /// Who may change it is checked by the caller (PermissionService).
  Future<void> set<T extends Object>(Setting<T> setting, T value, {required Staff by}) async {
    await _repo.write(setting, value, by: by);
    _values[setting.key] = value;
  }
}
