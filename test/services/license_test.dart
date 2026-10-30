import 'dart:convert';
import 'dart:io';

import 'package:aby_pos/app/core/license.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/audit_repository.dart';
import 'package:aby_pos/app/services/hub/hub_service.dart';
import 'package:aby_pos/app/services/license_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

/// A signing key of the tests' own; the app's private key is not in the repo.
final _seed = List.generate(32, (i) => i * 7 % 256);

Future<String> _key({required String device, int devices = 1, String shop = 'Scoops Tamale'}) => LicenseCodec.sign(
      License(id: 'lic-$device-$devices', shop: shop, device: device, devices: devices, issued: DateTime(2026, 10, 30)),
      _seed,
    );

void main() {
  late String publicKey;
  late Directory dir;

  setUpAll(() async => publicKey = await LicenseCodec.publicKeyOf(_seed));
  setUp(() async => dir = await Directory.systemTemp.createTemp('aby_license'));
  tearDown(() async {
    PermissionGate.allows = PermissionGate.everything;
    await dir.delete(recursive: true);
  });

  LicenseService service(AppDatabase db, String machine,
          {bool Function()? training, void Function()? changed, AuditRepository? audit}) =>
      LicenseService(
        db,
        machineId: () async => machine,
        file: () async => File('${dir.path}/$machine.license'),
        publicKey: publicKey,
        training: training,
        changed: changed,
        audit: audit,
      );

  group('license keys', () {
    test('read back what was signed, through spaces and line breaks', () async {
      final key = await _key(device: deviceCode('machine-a'), devices: 3);
      final wrapped = '${key.substring(0, 30)}\n ${key.substring(30)}  ';
      final l = await LicenseCodec.read(wrapped, publicKey: publicKey);
      expect(l.shop, 'Scoops Tamale');
      expect(l.devices, 3);
      expect(l.device, deviceCode('machine-a'));
    });

    test('a changed license, or one signed with another key, is refused', () async {
      final key = await _key(device: deviceCode('machine-a'));
      final [payload, signature] = key.substring(LicenseCodec.prefix.length).split('.');
      final more = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(payload)))) as Map<String, dynamic>
        ..['devices'] = 50;
      final edited = '${LicenseCodec.prefix}${base64Url.encode(utf8.encode(jsonEncode(more))).replaceAll('=', '')}.$signature';
      await expectLater(LicenseCodec.read(edited, publicKey: publicKey),
          throwsA(isA<LicenseException>().having((e) => e.problem, 'problem', LicenseProblem.forged)));
      await expectLater(LicenseCodec.read(key),
          throwsA(isA<LicenseException>().having((e) => e.problem, 'problem', LicenseProblem.forged)),
          reason: "the app's own key did not sign it");
      for (final junk in ['', 'hello', 'ABY1.abc', key.substring(0, key.length ~/ 2)]) {
        await expectLater(LicenseCodec.read(junk, publicKey: publicKey), throwsA(isA<LicenseException>()), reason: junk);
      }
    });

    test('device codes are stable, easy to read out, and typed in any form', () {
      final code = deviceCode('8f0c2d1e-0000-4c7a-9a1b-112233445566');
      expect(code, matches(RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$')));
      expect(code, isNot(contains(RegExp('[01IO]'))));
      expect(deviceCode('8f0c2d1e-0000-4c7a-9a1b-112233445566'), code);
      expect(deviceCode('another machine'), isNot(code));
      expect(normalizeDeviceCode(' ${code.toLowerCase().replaceAll('-', ' ')} '), code);
    });
  });

  group('on a device', () {
    late AppDatabase db;
    setUp(() => db = memoryDb());
    tearDown(() => db.close());

    test('without a license, people may look, export and back up, but not sell; training is open', () async {
      var training = false;
      final s = service(db, 'machine-a', training: () => training)..onInit();
      await s.load();
      expect(s.licensed, isFalse);
      expect(owner.can(Permission.sell), isFalse);
      expect(owner.can(Permission.editProducts), isFalse);
      expect(owner.can(Permission.manageCash), isFalse);
      expect(owner.can(Permission.viewReports), isTrue);
      expect(owner.can(Permission.exportData), isTrue);
      expect(owner.can(Permission.manageDevices), isTrue, reason: 'so the owner can activate');
      training = true;
      expect(cashier.can(Permission.sell), isTrue);
      s.onClose();
      expect(PermissionGate.allows(Permission.sell), isTrue);
    });

    test("activates with this device's license only, keeps it, and reads it again on the next start", () async {
      var changed = 0;
      final s = service(db, 'machine-a', changed: () => changed++, audit: AuditRepository(db, FakeDevice('dev-a')))..onInit();
      await s.load();
      await expectLater(s.activate(await _key(device: deviceCode('machine-b'))),
          throwsA(isA<LicenseException>().having((e) => e.problem, 'problem', LicenseProblem.otherDevice)));
      await expectLater(s.activate(await _key(device: s.machineCode, devices: 2), linkedDevices: 3),
          throwsA(isA<LicenseException>().having((e) => e.problem, 'problem', LicenseProblem.tooFewDevices)));
      expect(s.licensed, isFalse);

      await s.activate(await _key(device: s.machineCode, devices: 3), linkedDevices: 3, by: owner);
      expect(s.licensed, isTrue);
      expect(s.seats, 3);
      expect(changed, 1, reason: 'screens look at permissions again');
      expect(cashier.can(Permission.sell), isTrue);
      final logged = await db.customSelect("SELECT summary FROM audit_log WHERE action = 'licenseActivated'").get();
      expect(logged.single.read<String>('summary'), contains('Scoops Tamale'));

      final again = service(db, 'machine-a');
      await again.load();
      expect(again.license.value?.devices, 3);
      final elsewhere = service(db, 'machine-b');
      await File('${dir.path}/machine-a.license').copy('${dir.path}/machine-b.license');
      await elsewhere.load();
      expect(elsewhere.licensed, isFalse, reason: 'a copied license file does not work on another machine');
    });
  });

  group('through the hub', () {
    late AppDatabase a, b, c;
    late Repos ra, rb, rc;
    late LicenseService la, lb, lc;
    late HubService hub, member, third;
    const never = Duration(hours: 1);

    setUp(() async {
      a = memoryDb();
      b = memoryDb(seed: false);
      c = memoryDb(seed: false);
      ra = await Repos.open(a);
      rb = await Repos.open(b);
      rc = await Repos.open(c);
      la = service(a, 'hub-pc');
      lb = service(b, 'till-2');
      lc = service(c, 'till-3');
      for (final l in [la, lb, lc]) {
        await l.load();
      }
      hub = HubService(a, ra.device, licenses: la, port: 0, beaconPort: 0, every: never);
      member = HubService(b, rb.device, licenses: lb, port: 0, beaconPort: 0, every: never);
      third = HubService(c, rc.device, licenses: lc, port: 0, beaconPort: 0, every: never);
      await hub.becomeHub();
    });
    tearDown(() async {
      for (final h in [third, member, hub]) {
        await h.stop();
      }
      for (final db in [a, b, c]) {
        await db.close();
      }
    });

    Future<void> join(HubService h) async {
      final offer = await hub.offerPairing();
      await h.join(['http://127.0.0.1:${hub.boundPort}'], offer.code, hubId: offer.hubId);
    }

    test("members use the hub's license, and no more devices pair than it covers", () async {
      await la.activate(await _key(device: la.machineCode, devices: 2));
      await join(member);
      expect(lb.licensed, isTrue);
      expect(lb.viaHub.value, isTrue);
      expect(lb.seats, isNull, reason: 'a member hands nothing on');

      await expectLater(join(third), throwsA(isA<HubException>().having((e) => e.error, 'error', HubError.noSeats)));
      expect(await hub.deviceCount(), 2);

      // Removing a device frees its place; the removed one loses the license.
      await hub.revoke(rb.device.deviceId);
      await member.syncNow();
      expect(lb.licensed, isFalse);
      await join(third);
      expect(lc.licensed, isTrue);

      // A restart reads the hub's license the member last heard.
      final again = service(c, 'till-3');
      await again.load();
      expect(again.viaHub.value, isTrue);
      await third.leave();
      expect(lc.licensed, isFalse);
      expect(await c.readMeta(LicenseService.hubLicenseKey), isNull);
    });

    test('a hub activated after its members joined passes the license on at the next sync', () async {
      await join(member);
      expect(lb.licensed, isFalse);
      await expectLater(la.activate(await _key(device: la.machineCode), linkedDevices: await hub.deviceCount()),
          throwsA(isA<LicenseException>().having((e) => e.problem, 'problem', LicenseProblem.tooFewDevices)));
      await la.activate(await _key(device: la.machineCode, devices: 5), linkedDevices: await hub.deviceCount());
      await member.syncNow();
      expect(lb.license.value?.devices, 5);
    });
  });
}
