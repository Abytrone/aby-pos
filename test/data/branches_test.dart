import 'dart:io';

import 'package:aby_pos/app/core/period.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/branch_repository.dart';
import 'package:aby_pos/app/data/repositories/report_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/data/repositories/stock_repository.dart';
import 'package:aby_pos/app/data/repositories/transfer_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/backup/backup_service.dart';
import 'package:aby_pos/app/services/backup/branch_merge.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos main, osu;
  late BranchRepository branches;
  late String osuId;
  late StockItem cones;

  setUp(() async {
    db = memoryDb();
    main = await Repos.open(db);
    osu = Repos.onDevice(db, 'dev-osu');
    branches = BranchRepository(db, main.device, main.audit);
    osuId = await branches.save(
      const BranchDraft(name: 'Osu', phone: '0244000000'),
      by: owner,
    );
    await BranchRepository(db, osu.device, osu.audit).placeDevice(osuId, deviceName: 'Osu till', by: owner);
    cones = (await main.stock.items()).firstWhere((i) => i.onHand > 0);
  });
  tearDown(() => db.close());

  test('every shop has the main branch; a device not placed is in it', () async {
    final list = await branches.list();
    expect(list.map((b) => b.name), ['Main branch', 'Osu']);
    expect(await branches.currentId(), mainBranchId);
    expect(await BranchRepository(db, osu.device, osu.audit).currentId(), osuId);
    await expectLater(branches.save(const BranchDraft(name: 'osu'), by: owner), throwsA(isA<BranchException>()));
    await expectLater(
      branches.setActive(osuId, active: false, by: owner),
      throwsA(isA<BranchException>()),
      reason: 'a device is still there',
    );
    await expectLater(branches.setActive(mainBranchId, active: false, by: owner), throwsA(isA<BranchException>()));
  });

  test('staff placed at a branch sign in only there; owners everywhere', () async {
    final kofi = await main.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1111');
    final ama = await main.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '2222', by: kofi);
    final yaw = await main.staff.create(name: 'Yaw', roleId: BuiltInRole.cashier.id, pin: '3333', by: kofi);
    await main.staff.setBranch(ama.id, osuId, by: kofi);
    expect((await main.staff.profile(ama.id))!.branchId, osuId);
    expect((await main.staff.list(atBranch: osuId)).map((s) => s.name), unorderedEquals(['Kofi', 'Ama', 'Yaw']));
    expect((await main.staff.list(atBranch: mainBranchId)).map((s) => s.name), unorderedEquals(['Kofi', 'Yaw']));
    await main.staff.setBranch(yaw.id, osuId, by: kofi);
    await main.staff.setBranch(kofi.id, osuId, by: kofi);
    expect((await main.staff.list(atBranch: mainBranchId)).map((s) => s.name), ['Kofi']);
  });

  test('stock is counted per branch; a transfer is in transit until received, with differences flagged', () async {
    final before = cones.onHand;
    expect(await osu.stock.onHand(cones.id), 0, reason: 'the new branch starts empty');

    final transfers = TransferRepository(db, main.device, main.audit, main.stock);
    final atOsu = TransferRepository(db, osu.device, osu.audit, osu.stock);
    final t = await transfers.send(toBranch: osuId, lines: {cones.id: 30}, note: 'Weekend', by: owner);
    expect(t.status, TransferStatus.sent);
    expect(t.code, startsWith('TR-'));
    expect(t.toName, 'Osu');
    expect(await main.stock.onHand(cones.id), before - 30);
    expect(await osu.stock.onHand(cones.id), 0, reason: 'in transit');
    await expectLater(
      transfers.receive(t.id, by: owner),
      throwsA(isA<StockException>()),
      reason: 'not the receiving branch',
    );
    await expectLater(
      transfers.send(toBranch: mainBranchId, lines: {cones.id: 1}, by: owner),
      throwsA(isA<StockException>()),
    );

    final got = await atOsu.receive(t.id, received: {t.lines.single.id: 28}, by: cashier);
    expect(got.status, TransferStatus.received);
    expect(got.hasDifferences, isTrue);
    expect(got.lines.single.difference, -2);
    expect(await osu.stock.onHand(cones.id), 28);
    expect(await main.stock.onHand(cones.id), before - 30);
    expect((await osu.stock.movements(cones.id)).single.reason, StockReason.transferIn);
    expect((await atOsu.list()).single.id, t.id);
    await expectLater(atOsu.receive(t.id, by: owner), throwsA(isA<StockException>()), reason: 'already closed');

    // Called back before it arrives: the stock comes home.
    final back = await transfers.send(toBranch: osuId, lines: {cones.id: 10}, by: owner);
    await expectLater(atOsu.cancel(back.id, by: owner), throwsA(isA<StockException>()));
    await transfers.cancel(back.id, by: owner);
    expect(await main.stock.onHand(cones.id), before - 30);
    expect((await transfers.find(back.id))!.status, TransferStatus.cancelled);
  });

  test('reports show one branch or all of them', () async {
    String? looking;
    final reports = ReportRepository(db, main.stock, main.customers, branch: () => looking);
    final menu = await main.catalog.load();
    final waffle = menu.products.firstWhere((x) => x.name == 'Waffle');
    Future<CompletedSale> sell(Repos at) => at.sales.completeSale(
      lines: [CartLine(product: waffle)],
      payments: [const PaymentInput.cash(tendered: 5000)],
      cashier: cashier,
      allowNegativeStock: true,
    );
    await sell(main);
    await sell(main);
    final there = await sell(osu);
    final today = DateRange(
      DateTime.now().subtract(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 1)),
    );
    expect((await reports.sales(today)).count, 3);
    looking = osuId;
    expect((await reports.sales(today)).count, 1);
    expect((await reports.payments(today)).$1.values.fold(0, (a, b) => a + b), there.total);
    expect((await reports.staff(today)).single.sales, 1);
    expect((await reports.options(today)), isEmpty);
    looking = mainBranchId;
    expect((await reports.sales(today)).count, 2);
    expect((await reports.products(today)).single.quantity, 2);
  });

  test("another branch's backup is merged in, not restored over", () async {
    final tmp = await Directory.systemTemp.createTemp('aby-branch-merge');
    addTearDown(() => tmp.delete(recursive: true));
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    // The other branch: its own database file, with a customer of its own.
    final path = p.join(tmp.path, 'osu.sqlite');
    final other = AppDatabase(DatabaseConnection(NativeDatabase(File(path))), false);
    final ro = await Repos.open(other);
    final esi = await ro.customers.save(const CustomerDraft(name: 'Esi from Osu'), by: owner);
    await other.close();

    final settings = SettingsService(SettingsRepository(db, main.device, main.audit));
    await settings.load();
    final backups = BackupService(
      db,
      main.audit,
      settings,
      backupsDirectory: () async => Directory(p.join(tmp.path, 'backups')),
      tempDirectory: () async => tmp,
      liveDatabaseFile: () async => File(p.join(tmp.path, 'live.sqlite')),
      iterations: 1000,
    );
    final mine = await main.customers.save(const CustomerDraft(name: 'Kofi'), by: owner);
    await db.delete(db.outbox).go();
    final preview = await backups.inspectFile(File(path));
    final result = await BranchMerge(db, main.audit, backups).merge(preview, by: owner);

    expect(result.changed, greaterThan(0));
    expect(result.skipped, 0);
    expect((await main.customers.find(esi))!.name, 'Esi from Osu');
    expect((await main.customers.find(mine))!.name, 'Kofi', reason: 'nothing here was replaced');
    final queued = await db.select(db.outbox).get();
    expect(queued.length, greaterThanOrEqualTo(result.changed));
    expect(queued.any((o) => o.recordId == esi), isTrue, reason: 'queued for the hub');
    expect(await backups.listLocalBackups(), isNotEmpty, reason: 'a safety backup first');

    final again = await BranchMerge(db, main.audit, backups).merge(await backups.inspectFile(File(path)), by: owner);
    expect(again.changed, 0, reason: 'bringing the same file twice changes nothing');
  });
}
