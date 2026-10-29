import 'dart:io';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/accounts_export_service.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers.dart';

void main() {
  late Directory tmp;
  late AppDatabase db;
  late Repos r;
  late SettingsService settings;
  late AccountsExportService accounts;
  var now = DateTime(2026, 11, 1, 9);

  Directory inApp() => Directory(p.join(tmp.path, 'Aby accounts'));
  List<String> saved(Directory dir) => [for (final f in dir.listSync()) p.basename(f.path)]..sort();

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('aby-accounts-test');
    now = DateTime(2026, 11, 1, 9);
    db = memoryDb();
    r = await Repos.open(db);
    settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
    accounts = AccountsExportService(db, r.reports, r.profit, settings, r.audit,
        defaultFolder: () async => inApp(), clock: () => now);
  });
  tearDown(() async {
    await db.close();
    await tmp.delete(recursive: true);
  });

  /// A waffle sold on [day].
  Future<void> sellOn(DateTime day) async {
    final menu = await r.catalog.load();
    final waffle = menu.products.firstWhere((x) => x.name == 'Waffle');
    final sale = await r.sales.completeSale(
      lines: [CartLine(product: waffle)],
      payments: [const PaymentInput.cash(tendered: 2000)],
      cashier: cashier,
    );
    final at = day.millisecondsSinceEpoch ~/ 1000;
    await db.customStatement('UPDATE sales SET created_at = ? WHERE id = ?', [at, sale.saleId]);
    await db.customStatement('UPDATE payments SET created_at = ? WHERE sale_id = ?', [at, sale.saleId]);
  }

  test('off: nothing is saved', () async {
    expect(await accounts.exportIfDue(), isEmpty);
    expect(inApp().existsSync(), isFalse);
  });

  test("on: last month's pack is saved once, with last month's sales", () async {
    await settings.set(AppSettings.accountsMonthly, true, by: owner);
    await sellOn(DateTime(2026, 10, 15, 12));

    final files = await accounts.exportIfDue();
    expect(saved(inApp()), ['aby_accounts_2026-10-01_2026-10-31.zip']);
    final zip = ZipDecoder().decodeBytes(await files.single.readAsBytes());
    final sales = String.fromCharCodes(zip.files.firstWhere((f) => f.name == 'sales.csv').content);
    expect(sales, contains('12.00'));
    expect(zip.files.map((f) => f.name), contains('summary.pdf'));

    expect(await accounts.exportIfDue(), isEmpty, reason: 'once per month');
    expect(await accounts.lastExportAt(), now);
    expect(await accounts.problem(), isNull);
    final log = await r.audit.list(actions: {AuditAction.accountsExported});
    expect(log.map((e) => e.entityId), ['2026-10']);
  });

  test('a device left off for months catches up, oldest first', () async {
    await settings.set(AppSettings.accountsMonthly, true, by: owner);
    await accounts.exportIfDue();
    now = DateTime(2027, 2, 3, 8);
    final files = await accounts.exportIfDue();
    expect([for (final f in files) p.basename(f.path)], [
      'aby_accounts_2026-11-01_2026-11-30.zip',
      'aby_accounts_2026-12-01_2026-12-31.zip',
      'aby_accounts_2027-01-01_2027-01-31.zip',
    ]);
    expect(p.basename((await accounts.latest())!.path), 'aby_accounts_2027-01-01_2027-01-31.zip');
  });

  test('a chosen folder that is not there: nothing saved, the problem kept, then saved when it is back', () async {
    final usb = Directory(p.join(tmp.path, 'usb'));
    await settings.set(AppSettings.accountsMonthly, true, by: owner);
    await settings.set(AppSettings.accountsFolder, usb.path, by: owner);

    expect(await accounts.exportIfDue(), isEmpty);
    expect(usb.existsSync(), isFalse, reason: 'no folder made in its place');
    expect(await accounts.problem(), isNotNull);
    expect(await accounts.lastExportAt(), isNull);

    await usb.create();
    expect(await accounts.exportIfDue(), hasLength(1));
    expect(saved(usb), ['aby_accounts_2026-10-01_2026-10-31.zip']);
    expect(await accounts.problem(), isNull);
  });
}
