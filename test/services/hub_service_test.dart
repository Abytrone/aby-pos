import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/hub/hub_service.dart';
import 'package:aby_pos/app/services/hub/sealed_box.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase a, b;
  late Repos ra, rb;
  late HubService hub, member;

  const never = Duration(hours: 1);

  setUp(() async {
    a = memoryDb();
    b = memoryDb(seed: false);
    ra = await Repos.open(a);
    rb = await Repos.open(b);
    hub = HubService(a, ra.device, port: 0, beaconPort: 0, every: never);
    member = HubService(b, rb.device, port: 0, beaconPort: 0, every: never);
  });
  tearDown(() async {
    await member.stop();
    await hub.stop();
    await a.close();
    await b.close();
  });

  Future<List<String>> local() async => ['http://127.0.0.1:${hub.boundPort}'];

  test('sealed messages open only with their secret', () async {
    final s = SealedBox.newSecret();
    final sealed = await SealedBox.seal({'hello': 1}, s);
    expect(await SealedBox.open(sealed, s), {'hello': 1});
    await expectLater(SealedBox.open(sealed, SealedBox.newSecret()), throwsA(anything));
    final k1 = await SealedBox.keyFromCode('abcd2345', 'hub-1');
    expect(k1, await SealedBox.keyFromCode('ABCD2345', 'hub-1'), reason: 'codes are typed in any case');
    expect(k1, isNot(await SealedBox.keyFromCode('ABCD2345', 'hub-2')));
  });

  test('a device joins, both shops merge, and later changes go both ways', () async {
    final theirs = await rb.customers.save(const CustomerDraft(name: 'Esi'), by: owner);
    await hub.becomeHub();
    expect(hub.role.value, HubRole.hub);
    final offer = await hub.offerPairing();
    expect(offer.code, hasLength(8));
    final parsed = PairingOffer.parse(offer.qr)!;
    expect(parsed.$2, offer.code);

    await member.join(await local(), offer.code.toLowerCase(), hubId: offer.hubId, deviceName: 'Till 2');
    expect(member.role.value, HubRole.member);
    expect(member.online.value, isTrue, reason: '${member.problem.value}');
    expect(hub.offer.value, isNull, reason: 'a code works once');

    // Merged: the hub's menu came over, the member's customer went up.
    expect((await rb.catalog.load()).products.map((p) => p.name), contains('Vanilla cone'));
    expect((await ra.customers.find(theirs))!.name, 'Esi');
    expect(await b.select(b.outbox).get(), isEmpty, reason: 'everything was sent');
    final paired = await hub.devices();
    expect(paired.single.name, 'Till 2');
    expect(paired.single.lastSeenAt, isNotNull);

    // A sale on the member reaches the hub; a customer on the hub reaches
    // the member.
    final menu = await rb.catalog.load();
    final sale = await rb.sales.completeSale(
      lines: [CartLine(product: menu.products.firstWhere((p) => p.name == 'Waffle'))],
      payments: [const PaymentInput.cash(tendered: 2000)],
      cashier: cashier,
    );
    final ours = await ra.customers.save(const CustomerDraft(name: 'Kwame'), by: owner);
    await hub.drainOwnOutbox();
    await member.syncNow();
    expect(member.online.value, isTrue);
    expect((await rb.customers.find(ours))!.name, 'Kwame');
    final onHub = await a.customSelect('SELECT id FROM sales WHERE id = ?', variables: [Variable.withString(sale.saleId)]).get();
    expect(onHub, hasLength(1));
    expect(await rb.audit.verifyChain(), isA<AuditChainStatus>().having((c) => c.isIntact, 'intact', isTrue));
    expect(await ra.audit.verifyChain(), isA<AuditChainStatus>().having((c) => c.isIntact, 'intact', isTrue),
        reason: 'each device keeps its own chain on the hub');
  });

  test("a joining device takes the hub's shop settings, keeps its own device settings, and sees later changes live", () async {
    final mine = SettingsService(SettingsRepository(b, rb.device, rb.audit));
    await mine.load();
    // Set up after the hub, so these are the newer values.
    await mine.set(AppSettings.shopName, 'Other shop', by: owner);
    await mine.set(AppSettings.deviceName, 'Till 2', by: owner);
    await hub.becomeHub();
    final offer = await hub.offerPairing();

    await member.join(await local(), offer.code, hubId: offer.hubId);
    await pumpEventQueue();
    expect(mine.get(AppSettings.shopName), 'Scoops Tamale', reason: 'no restart needed');
    expect(mine.get(AppSettings.deviceName), 'Till 2');
    final onHub = SettingsService(SettingsRepository(a, ra.device, ra.audit));
    await onHub.load();
    expect(onHub.get(AppSettings.shopName), 'Scoops Tamale', reason: "the member's did not win");

    await onHub.set(AppSettings.autoLockMinutes, 10, by: owner);
    await hub.drainOwnOutbox();
    await member.syncNow();
    await pumpEventQueue();
    expect(mine.get(AppSettings.autoLockMinutes), 10);
  });

  test("a new install joining from its first screen takes the hub's data as it is and sends nothing", () async {
    await ra.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1111');
    await hub.becomeHub();
    final offer = await hub.offerPairing();

    await member.join(await local(), offer.code, hubId: offer.hubId, fresh: true);
    expect(member.online.value, isTrue, reason: '${member.problem.value}');
    Future<int> count(AppDatabase db, String table) async =>
        (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle()).read<int>('n');
    expect(await count(b, 'tax_rates'), await count(a, 'tax_rates'), reason: 'its own starting tax presets do not appear twice');
    expect(await rb.staff.hasStaff(), isTrue);
    expect((await rb.catalog.load()).products.map((p) => p.name), contains('Vanilla cone'));
    final sent = await a.customSelect(
      'SELECT COUNT(*) AS n FROM hub_changes WHERE origin_device = ?',
      variables: [Variable.withString(rb.device.deviceId)],
    ).getSingle();
    expect(sent.read<int>('n'), 0);
  });

  test('a wrong code is refused; a removed device can no longer sync', () async {
    await hub.becomeHub();
    final offer = await hub.offerPairing();
    await expectLater(
      member.join(await local(), 'WRONG234', hubId: offer.hubId),
      throwsA(isA<HubException>().having((e) => e.error, 'error', HubError.wrongCode)),
    );
    expect(member.role.value, HubRole.none);

    await member.join(await local(), offer.code, hubId: offer.hubId);
    await hub.revoke(rb.device.deviceId);
    await rb.customers.save(const CustomerDraft(name: 'Late'), by: owner);
    await member.syncNow();
    expect(member.online.value, isFalse);
    expect(member.problem.value, HubError.revoked);

    await member.leave();
    expect(member.role.value, HubRole.none);
    expect(await b.readMeta('hub.secret'), isNull);
  });

  test('names that appear twice after a merge are listed', () async {
    await rb.customers.save(const CustomerDraft(name: 'Ama'), by: owner);
    await ra.customers.save(const CustomerDraft(name: 'ama '), by: owner);
    await hub.becomeHub();
    final offer = await hub.offerPairing();
    await member.join(await local(), offer.code, hubId: offer.hubId);
    expect(await hub.duplicates(), contains(('customer', 'Ama')));
  });
}
