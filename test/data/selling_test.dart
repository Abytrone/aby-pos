import 'dart:convert';

import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/audit_repository.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/discount_repository.dart';
import 'package:aby_pos/app/data/repositories/parked_order_repository.dart';
import 'package:aby_pos/app/domain/catalogue_rules.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/modules/till/controllers/cart_controller.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:aby_pos/app/services/permission_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

Discount percent(int v, {String reason = 'Regular customer'}) =>
    Discount(kind: DiscountKind.percent, value: v, reason: reason);
Discount amount(int v) => Discount(kind: DiscountKind.amount, value: v, reason: 'Staff');

/// Lets fire-and-forget writes (the cart's audit entries) land.
Future<void> settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
  });
  tearDown(() => db.close());

  group('Sales with discounts, overrides and weights', () {
    test('discounts are stored per line and audited; the total is what was paid', () async {
      final waffle = named('Waffle');
      final cone = named('Vanilla cone');
      final done = await r.sales.completeSale(
        lines: [
          CartLine(product: waffle, discount: percent(10), note: 'no sauce'),
          CartLine(product: cone, variant: cone.variants[1]),
        ],
        payment: const PaymentInput.cash(tendered: 3000),
        cashier: cashier,
        orderDiscount: amount(500),
        note: 'Collect at 3 pm',
        orderType: OrderType.takeaway,
      );
      expect(done.total, 2780);
      expect(done.changeDue, 220);

      final sale = await db.select(db.sales).getSingle();
      expect(sale.subtotal, 3400);
      expect(sale.discountTotal, 620);
      expect(sale.total, 2780);
      expect(sale.note, 'Collect at 3 pm');
      expect(sale.orderType, OrderType.takeaway);
      expect((jsonDecode(sale.orderDiscount!) as Map)['value'], 500);

      final lines = await db.select(db.saleLines).get();
      final w = lines.firstWhere((l) => l.productName == 'Waffle');
      expect(w.discount, 120);
      expect(w.note, 'no sauce');
      expect((jsonDecode(w.discountDetail!) as Map)['reason'], 'Regular customer');
      expect(lines.fold(0, (s, l) => s + l.orderDiscountShare), 500);

      final audit = await r.audit.list(actions: {AuditAction.discountsGiven});
      expect(audit.single.summary, contains('GH₵ 6.20 off'));
      expect(await r.audit.list(actions: {AuditAction.priceOverridden}), isEmpty);
    });

    test('a price override keeps the menu price and who allowed it', () async {
      final waffle = named('Waffle');
      await r.sales.completeSale(
        lines: [CartLine(product: waffle, customPrice: 1000, priceOverriddenBy: 'Kofi')],
        payment: const PaymentInput.cash(tendered: 1000),
        cashier: cashier,
      );
      final line = await db.select(db.saleLines).getSingle();
      expect(line.unitPrice, 1000);
      expect(line.listPrice, 1200);
      expect(line.priceOverriddenBy, 'Kofi');
      expect((await r.audit.list(actions: {AuditAction.priceOverridden})).single.summary, contains('allowed by Kofi'));
    });

    test('a weighed product uses its recipe per kg', () async {
      final crunch = (await r.stock.items()).firstWhere((i) => i.name == 'Groundnut crunch');
      final snacks = menu.categories.firstWhere((c) => c.name == 'Snacks');
      final id = await CatalogueRules(r.catalog).saveProduct(
        ProductDraft(
          categoryId: snacks.id,
          name: 'Loose groundnuts',
          sellBy: SellBy.kg,
          variants: [
            VariantDraft(price: 4000, recipe: [RecipeDraftLine(stockItemId: crunch.id, quantity: 1000)]),
          ],
        ),
        by: owner,
      );
      final nuts = (await r.catalog.load()).products.firstWhere((p) => p.id == id);
      expect(nuts.weighed, isTrue);
      final done = await r.sales.completeSale(
        lines: [CartLine(product: nuts, quantity: 250)],
        payment: const PaymentInput.cash(tendered: 1000),
        cashier: cashier,
      );
      expect(done.total, 1000);
      expect((await r.stock.items()).firstWhere((i) => i.name == 'Groundnut crunch').onHand, 2000 - 250);
      final line = await db.select(db.saleLines).getSingle();
      expect(line.sellBy, SellBy.kg);
      expect(line.quantity, 250);
    });

    test('open-price products stay within their limits', () async {
      final snacks = menu.categories.firstWhere((c) => c.name == 'Snacks');
      final rules = CatalogueRules(r.catalog);
      await expectLater(
        rules.saveProduct(
          ProductDraft(
            categoryId: snacks.id,
            name: 'Miscellaneous',
            openPrice: true,
            minPrice: 500,
            maxPrice: 100,
            variants: const [VariantDraft(price: 0)],
          ),
          by: owner,
        ),
        throwsA(isA<CatalogueException>()),
      );
      final id = await rules.saveProduct(
        ProductDraft(
          categoryId: snacks.id,
          name: 'Miscellaneous',
          openPrice: true,
          minPrice: 100,
          maxPrice: 50000,
          onQuickTab: true,
          variants: const [VariantDraft(price: 0)],
        ),
        by: owner,
      );
      final misc = (await r.catalog.load()).products.firstWhere((p) => p.id == id);
      expect(misc.openPrice, isTrue);
      expect(misc.minPrice, 100);
      expect(misc.quickOrder, 0);
    });

    test('the Quick tab keeps the order it is given', () async {
      final ids = [named('Waffle').id, named('Milkshake').id];
      await r.catalog.setQuickTab(ids);
      var quick = (await r.catalog.load()).products.where((p) => p.quickOrder != null).toList()
        ..sort((a, b) => a.quickOrder!.compareTo(b.quickOrder!));
      expect(quick.map((p) => p.name), ['Waffle', 'Milkshake']);
      await r.catalog.setQuickTab([ids[1]]);
      quick = (await r.catalog.load()).products.where((p) => p.quickOrder != null).toList();
      expect(quick.map((p) => p.name), ['Milkshake']);
    });

    test('recent products are the latest sold on this till', () async {
      var n = 0;
      Future<void> sell(String name) => r.sales.completeSale(
            lines: [CartLine(product: named(name))],
            payment: PaymentInput.momo(momoReference: 'TX${n++}'),
            cashier: cashier,
          );
      await sell('Waffle');
      await sell('Milkshake');
      await sell('Waffle');
      final recent = await r.sales.recentProductIds();
      expect(recent, [named('Waffle').id, named('Milkshake').id]);
    });
  });

  group('ParkedOrderRepository', () {
    late ParkedOrderRepository parked;
    setUp(() => parked = ParkedOrderRepository(db, r.device, r.audit));

    test('park, take once, and the order leaves the list', () async {
      final id = await parked.park(name: 'Table 4', cart: {'lines': []}, total: 4500, itemCount: 3, by: cashier);
      expect((await parked.parked()).single.name, 'Table 4');
      expect(await parked.take(id), isTrue);
      expect(await parked.take(id), isFalse, reason: 'another till took it');
      expect(await parked.parked(), isEmpty);
    });

    test('throwing one away is recorded with who approved it', () async {
      final id = await parked.park(name: 'Blue shirt', cart: {'lines': []}, total: 1200, itemCount: 1, by: cashier);
      await parked.discard(id, actor: cashier, approver: owner);
      expect(await parked.parked(), isEmpty);
      final entry = (await r.audit.list(actions: {AuditAction.parkedOrderDiscarded})).single;
      expect(entry.approverName, 'Kofi');
      expect(entry.summary, contains('Blue shirt'));
    });

    test('old parked orders are counted for close day', () async {
      await parked.park(name: 'A', cart: {'lines': []}, total: 100, itemCount: 1, by: cashier);
      expect(await parked.olderThan(const Duration(hours: 1)), 0);
      expect(await parked.olderThan(const Duration(seconds: -5)), 1);
    });

    test('the current cart is saved on the device and cleared', () async {
      await parked.saveCurrent({'lines': [], 'note': 'hi'});
      expect((await parked.loadCurrent())!['note'], 'hi');
      await parked.saveCurrent(null);
      expect(await parked.loadCurrent(), isNull);
    });
  });

  group('DiscountRepository', () {
    late DiscountRepository discounts;
    setUp(() => discounts = DiscountRepository(db, r.device, r.audit));

    test('a new shop starts with reasons for each purpose', () async {
      for (final kind in ReasonKind.values) {
        expect(await discounts.reasons(kind), isNotEmpty, reason: kind.name);
      }
      expect((await discounts.reasons(ReasonKind.discount)).first.name, 'Regular customer');
    });

    test('saved discounts are checked and audited', () async {
      for (final (kind, value) in [(DiscountKind.percent, 0), (DiscountKind.percent, 101), (DiscountKind.amount, 0)]) {
        await expectLater(
          discounts.saveDiscount(name: 'X', kind: kind, value: value, scope: DiscountScope.any, by: owner),
          throwsA(isA<DiscountException>()),
        );
      }
      final id = await discounts.saveDiscount(
        name: 'Student 10%',
        kind: DiscountKind.percent,
        value: 10,
        scope: DiscountScope.order,
        by: owner,
      );
      final saved = (await discounts.discounts()).single;
      expect(saved.forOrders, isTrue);
      expect(saved.forLines, isFalse);
      expect(saved.apply(reason: 'Student').name, 'Student 10%');
      await discounts.setDiscountActive(id, active: false, by: owner);
      expect(await discounts.discounts(), isEmpty);
      expect(await discounts.discounts(includeInactive: true), hasLength(1));
      expect(await r.audit.list(actions: {AuditAction.discountSaved}), hasLength(2));
    });

    test('reasons are unique per list and new ones go last', () async {
      await expectLater(
        discounts.saveReason(kind: ReasonKind.discount, name: 'staff', by: owner),
        throwsA(isA<DiscountException>()),
      );
      await discounts.saveReason(kind: ReasonKind.discount, name: 'Birthday', by: owner);
      expect((await discounts.reasons(ReasonKind.discount)).last.name, 'Birthday');
      await discounts.saveReason(kind: ReasonKind.refund, name: 'Staff', by: owner);
      expect((await discounts.reasons(ReasonKind.refund)).map((x) => x.name), contains('Staff'));
    });
  });

  group('Discount approvals', () {
    late AuthService auth;
    late PermissionService permissions;
    late Staff kofi;
    late Staff esi;
    late Staff ama;

    setUp(() async {
      Get.testMode = true;
      auth = AuthService(r.staff, r.audit);
      permissions = PermissionService(auth);
      kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      esi = await r.staff.create(name: 'Esi', roleId: BuiltInRole.manager.id, pin: '2222', by: kofi);
      ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
    });
    tearDown(Get.reset);

    test('within the role limit, no prompt; above it, someone whose limit covers it', () async {
      auth.signInAsNew(ama);
      ApprovalNeed? asked;
      permissions.prompter = (need, _) async {
        asked = need;
        return esi;
      };
      final within = await permissions.authorizeDiscount(10, reason: 'x');
      expect(within!.approver, isNull);
      expect(asked, isNull);
      final above = await permissions.authorizeDiscount(40, reason: 'x');
      expect(above!.approver, esi);
      expect(asked!.discountPercent, 40);
    });

    test('approver PINs only count when their limit covers the discount', () async {
      expect(await r.staff.approverWithPin('2222', Permission.sell, discountPercent: 40), esi);
      expect(await r.staff.approverWithPin('2222', Permission.sell, discountPercent: 60), isNull, reason: 'managers stop at 50%');
      expect(await r.staff.approverWithPin('1234', Permission.sell, discountPercent: 100), kofi);
      expect(await r.staff.approverWithPin('5678', Permission.sell, discountPercent: 20), isNull);
    });
  });

  group('CartController', () {
    late CartController cart;
    late ParkedOrderRepository store;

    setUp(() async {
      Get.testMode = true;
      store = Get.put(ParkedOrderRepository(db, r.device, r.audit));
      Get.put<AuditRepository>(r.audit);
      final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      Get.put(AuthService(r.staff, r.audit)).signInAsNew(kofi);
      cart = Get.put(CartController());
    });
    tearDown(() {
      cart.onClose(); // stops the pending save before the database closes
      Get.reset();
    });

    test('plain picks share a line; a line with a note or discount does not', () {
      final waffle = named('Waffle');
      cart.add(waffle);
      cart.add(waffle);
      expect(cart.lines.single.quantity, 2);
      cart.setLineNote(cart.lines.single.key, 'extra hot');
      cart.add(waffle);
      expect(cart.lines, hasLength(2));
      cart.setLineDiscount(cart.lines.last.key, percent(10));
      cart.add(waffle);
      expect(cart.lines, hasLength(3));
      expect(cart.itemCount, 4);
    });

    test('changing the pick keeps the quantity, note and discount', () {
      final cone = named('Vanilla cone');
      final line = cart.add(cone, quantity: 2);
      cart.setLineNote(line.key, 'no nuts');
      cart.setLineDiscount(line.key, percent(10));
      cart.setLinePrice(line.key, 1000, by: 'Kofi');
      cart.replacePick(line.key, variant: cone.variants[1], options: const []);
      final changed = cart.line(line.key)!;
      expect(changed.variant.id, cone.variants[1].id);
      expect(changed.quantity, 2);
      expect(changed.note, 'no nuts');
      expect(changed.discount!.value, 10);
      expect(changed.customPrice, isNull, reason: 'override is for the old pick');
    });

    test('a snapshot comes back the same; lines no longer on the menu are dropped', () {
      final waffle = named('Waffle');
      cart.add(waffle, quantity: 3);
      cart.orderDiscount.value = amount(200);
      cart.setOrderNote('Table 4');
      final json = jsonDecode(jsonEncode(cart.snapshot())) as Map<String, dynamic>;
      final total = cart.total;
      cart.reset();
      expect(cart.isEmpty, isTrue);
      expect(cart.load(json, menu.products), 0);
      expect(cart.total, total);
      expect(cart.note.value, 'Table 4');
      expect(cart.load(json, menu.products.where((p) => p.name != 'Waffle').toList()), 1);
      expect(cart.isEmpty, isTrue);
    });

    test('the cart is saved as it changes and comes back after a restart', () async {
      cart.add(named('Milkshake'), quantity: 2);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(await store.loadCurrent(), isNotNull);
      final again = CartController()..onInit();
      expect(await again.restoreSaved(menu.products), 0);
      expect(again.lines.single.quantity, 2);
      again.onClose();
    });

    test('taking things off the cart is recorded; finishing a sale is not', () async {
      final waffle = named('Waffle');
      final line = cart.add(waffle, quantity: 3);
      cart.decrement(line.key);
      cart.remove(line.key);
      cart.add(waffle);
      cart.clear();
      cart.add(waffle);
      cart.reset();
      await settle();
      final removed = await r.audit.list(actions: {AuditAction.cartLinesRemoved});
      expect(removed.map((e) => e.summary), [
        contains('Removed 2 × Waffle'),
        contains('Took 1 × Waffle'),
      ]);
      expect(await r.audit.list(actions: {AuditAction.cartCleared}), hasLength(1));
    });
  });
}
