import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/domain/business_templates.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:aby_pos/app/services/template_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late SettingsService settings;
  late TemplateService templates;

  setUp(() async {
    db = memoryDb(seed: false);
    r = await Repos.open(db);
    settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
    templates = TemplateService(r.catalog, settings);
  });
  tearDown(() => db.close());

  test('a provision shop starts with its own categories, no sample menu, and expiry on', () async {
    final taxes = (await r.catalog.load()).taxRates.length;
    await templates.apply(BusinessType.provision, by: owner);
    final menu = await r.catalog.load(includeInactive: true);
    expect(menu.products, isEmpty);
    expect(menu.categories.map((c) => c.name), unorderedEquals(['Drinks', 'Provisions', 'Toiletries', 'Snacks']));
    expect(menu.taxRates.length, taxes, reason: 'taxes are for every shop');
    expect(await r.stock.items(), isEmpty);
    expect(settings.get(AppSettings.expiryByDefault), isTrue);
    expect(settings.get(AppSettings.shopType), 'provision');
  });

  test('a chop bar gets order types and kitchen tickets; a salon commission', () async {
    await templates.apply(BusinessType.chopBar, by: owner);
    expect(settings.get(AppSettings.orderTypes), isTrue);
    expect(settings.get(AppSettings.ordersOn), isTrue);
    await templates.apply(BusinessType.salon, by: owner);
    expect(settings.get(AppSettings.commissionMode), 'percent');
    expect(settings.get(AppSettings.commissionPercent), 10);
  });

  test('every kind of shop starts empty but for its categories; existing ones are kept', () async {
    await templates.apply(BusinessType.iceCream, by: owner);
    final menu = await r.catalog.load(includeInactive: true);
    expect(menu.products, isEmpty);
    expect(menu.categories.map((c) => c.name), containsAll(['Cones', 'Cups']));
    expect(settings.get(AppSettings.loyaltyStyle), 'stamps');

    await templates.apply(BusinessType.boutique, by: owner);
    final after = await r.catalog.load(includeInactive: true);
    expect(after.categories.map((c) => c.name), containsAll(['Cones', 'Women', 'Men']));
  });
}
