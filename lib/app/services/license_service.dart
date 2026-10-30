import 'dart:io';

import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/license.dart';
import '../core/permissions.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../models/audit.dart';
import '../models/staff.dart';
import 'machine_id.dart';

/// Where this device's own license is kept: outside the database, so a
/// restore or training mode never touches it.
Future<File> licenseFile() async => File(p.join((await getApplicationSupportDirectory()).path, 'aby_pos.license'));

/// Whether Aby is paid for on this device. A device holds its own license
/// (a till on its own, or the hub), or a member of a hub uses the hub's,
/// which the hub sends with every sync. Without one, [PermissionGate] lets
/// people look at, export and back up their data but not sell or change
/// stock, customers or cash. Training mode is always open: it is the demo.
class LicenseService extends GetxService {
  LicenseService(
    this._db, {
    this.training,
    this.audit,
    this.changed,
    Future<String> Function()? machineId,
    Future<File> Function()? file,
    this.publicKey = licensePublicKey,
    this.enforce = true,
  })  : _machineId = machineId ?? readMachineId,
        _file = file ?? licenseFile;

  final AppDatabase _db;

  /// Training mode is on.
  final bool Function()? training;
  final AuditRepository? audit;

  /// Called when what people may do changes, so screens checking
  /// permissions look again.
  final void Function()? changed;
  final Future<String> Function() _machineId;
  final Future<File> Function() _file;
  final String publicKey;

  /// False in tests of the whole app: everything stays allowed.
  final bool enforce;

  /// The hub's license, as a member last heard it. A restore keeps this
  /// device's (HubService.linkKeys); leaving the hub drops it.
  static const hubLicenseKey = 'hub.license';

  /// What a shop sends to buy a license ([deviceCode]). Set by [load].
  String machineCode = '';

  final license = Rxn<License>();

  /// [license] is the hub's, not this device's own.
  final viaHub = false.obs;

  /// This device's own license key, which a hub hands to its members.
  String? ownKey;

  bool get licensed => license.value != null;

  /// How many devices may share this device's license (the hub included),
  /// or null when it has none of its own.
  int? get seats => viaHub.value ? null : license.value?.devices;

  @override
  void onInit() {
    super.onInit();
    if (enforce) PermissionGate.allows = _allows;
  }

  @override
  void onClose() {
    if (PermissionGate.allows == _allows) PermissionGate.allows = PermissionGate.everything;
    super.onClose();
  }

  bool _allows(Permission permission) => licensed || permission.worksUnlicensed || (training?.call() ?? false);

  /// Reads this device's license, or the hub's when it has none.
  Future<void> load() async {
    try {
      if (machineCode.isEmpty) machineCode = deviceCode(await _machineId());
    } on Object {
      // No machine ID to be had: no license can match, so none is read.
    }
    License? own;
    try {
      final f = await _file();
      if (await f.exists()) {
        final key = await f.readAsString();
        final l = await LicenseCodec.read(key, publicKey: publicKey);
        if (machineCode.isNotEmpty && l.device == machineCode) {
          own = l;
          ownKey = key.trim();
        }
      }
    } on Object {
      // Unreadable or for another machine: as if there were none.
    }
    if (own != null) return _set(own, viaHub: false);
    _set(await _hubLicense(await _db.readMeta(hubLicenseKey)), viaHub: true);
  }

  /// Checks [key] is for this device and covers [linkedDevices] (the hub and
  /// its members), then keeps it. Throws [LicenseException].
  Future<License> activate(String key, {int linkedDevices = 1, Staff? by}) async {
    final l = await LicenseCodec.read(key, publicKey: publicKey);
    if (machineCode.isEmpty || l.device != machineCode) throw const LicenseException(LicenseProblem.otherDevice);
    if (l.devices < linkedDevices) throw const LicenseException(LicenseProblem.tooFewDevices);
    final f = await _file();
    await f.parent.create(recursive: true);
    await f.writeAsString(key.trim(), flush: true);
    ownKey = key.trim();
    _set(l, viaHub: false);
    await audit?.record(
      action: AuditAction.licenseActivated,
      actor: by,
      summary: 'Activated Aby for ${l.shop} (${l.devices} ${l.devices == 1 ? 'device' : 'devices'})',
    );
    return l;
  }

  /// A member heard from its hub: [key] is the hub's license, or null when
  /// it has none (or no longer takes this device).
  Future<void> fromHub(String? key) async {
    if (key == await _db.readMeta(hubLicenseKey)) return;
    if (key == null) {
      await _db.deleteMeta(hubLicenseKey);
    } else {
      await _db.writeMeta(hubLicenseKey, key);
    }
    if (license.value != null && !viaHub.value) return;
    _set(await _hubLicense(key), viaHub: true);
  }

  Future<License?> _hubLicense(String? key) async {
    if (key == null) return null;
    try {
      return await LicenseCodec.read(key, publicKey: publicKey);
    } on LicenseException {
      return null;
    }
  }

  void _set(License? l, {required bool viaHub}) {
    final before = license.value?.id;
    license.value = l;
    this.viaHub.value = l != null && viaHub;
    if (before != l?.id) changed?.call();
  }
}
