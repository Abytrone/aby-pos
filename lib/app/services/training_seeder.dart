import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:image/image.dart' as img;

import '../core/denominations.dart';
import '../core/permissions.dart';
import '../core/settings.dart';
import '../core/tax.dart';
import '../data/database/app_database.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/branch_repository.dart';
import '../data/repositories/cash_event_repository.dart';
import '../data/repositories/catalog_repository.dart';
import '../data/repositories/customer_repository.dart';
import '../data/repositories/day_close_repository.dart';
import '../data/repositories/discount_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/momo_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/repositories/parked_order_repository.dart';
import '../data/repositories/pay_method_repository.dart';
import '../data/repositories/promotion_repository.dart';
import '../data/repositories/purchase_order_repository.dart';
import '../data/repositories/receiving_repository.dart';
import '../data/repositories/refund_repository.dart';
import '../data/repositories/safe_repository.dart';
import '../data/repositories/sale_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/shift_repository.dart';
import '../data/repositories/staff_repository.dart';
import '../data/repositories/stock_count_repository.dart';
import '../data/repositories/stock_repository.dart';
import '../data/repositories/supplier_repository.dart';
import '../data/repositories/time_repository.dart';
import '../data/repositories/transfer_repository.dart';
import '../data/repositories/voucher_repository.dart';
import '../domain/business_templates.dart';
import '../domain/loyalty.dart';
import '../domain/orders.dart';
import '../domain/pricing.dart';
import '../domain/promotions.dart';
import '../domain/sample_shops.dart';
import '../models/models.dart';
import 'device_service.dart';

/// Fills a training copy with a pretend shop of the shop's kind (APP-05):
/// suppliers, stock, a menu, customers and staff, then four weeks of
/// trading played through the real repositories, so every sale, delivery,
/// count, refund and close is connected as it would be on a real till.
///
/// The shop's own staff, settings, roles, payment methods, taxes and
/// reasons stay; everything else in the copy is replaced.
class TrainingSeeder {
  TrainingSeeder(this._db, {this._photo, int seed = 7, this.days = 28}) : _random = Random(seed);

  final AppDatabase _db;
  final Future<Uint8List?> Function(String asset)? _photo;
  final Random _random;

  /// Days of history before today.
  final int days;

  /// Opens the copy at [file], seeds it and closes it again, in a
  /// background isolate so the screen keeps moving. The copy can be made
  /// again, so it is written without waiting for the disk.
  static Future<void> seedFile(File file, {Future<Uint8List?> Function(String asset)? photo}) async {
    // Assets can only be read here, so the pictures go over with the path.
    final photos = <String, Uint8List>{};
    for (final t in BusinessType.values) {
      for (final asset in SampleShop.of(t).products.map((p) => p.photo).nonNulls) {
        final bytes = await photo?.call(asset);
        if (bytes != null) photos[asset] = bytes;
      }
    }
    final path = file.path;
    await Isolate.run(() async {
      final db = AppDatabase(
        DatabaseConnection(NativeDatabase(
          File(path),
          setup: (raw) => raw
            ..execute('PRAGMA synchronous = OFF')
            ..execute('PRAGMA journal_mode = MEMORY'),
        )),
        false,
      );
      try {
        await TrainingSeeder(db, photo: (asset) async => photos[asset]).run();
      } finally {
        await db.close();
      }
    });
  }

  /// What the copy keeps from the real shop: who signs in and how the shop
  /// is set up. The local hub's tables go too (training never syncs).
  static const _replaced = [
    'categories', 'products', 'product_variants', 'option_groups', 'option_items', 'product_option_groups',
    'stock_items', 'recipe_items', 'product_taxes', 'barcodes', 'product_photos', 'price_changes',
    'suppliers', 'supplier_ledger', 'stock_receipts', 'stock_receipt_lines', 'stock_counts',
    'stock_count_lines', 'sales', 'sale_lines', 'sale_taxes', 'payments', 'customers', 'customer_ledger',
    'refunds', 'refund_lines', 'refund_payments', 'cash_events', 'receipt_photos', 'shifts', 'safe_entries',
    'momo_checks', 'expenses', 'recurring_expenses', 'owner_money', 'momo_charges', 'discounts',
    'parked_orders', 'stock_movements', 'day_closes', 'audit_log', 'promotions', 'gift_vouchers',
    'voucher_entries', 'purchase_orders', 'purchase_order_lines', 'stock_batches', 'time_entries',
    'hub_changes', 'hub_devices', 'stock_transfers', 'stock_transfer_lines', 'outbox',
  ];

  /// The till in the sample branch, which receives stock sent there.
  static const branchDeviceId = 'training-branch-till';

  late DateTime _now;
  late _Repos _r;
  late SampleShop _shop;
  late Map<String, Object?> _settings;
  late Staff _owner;
  late Staff _manager;
  late List<Staff> _cashiers;
  late Staff _stockKeeper;
  late PayMethod _cash;
  late List<PayMethod> _momo;
  late PayMethod _credit;
  late PayMethod _wallet;
  late PayMethod _voucher;
  PayMethod? _card;
  final _stockIds = <String, String>{};
  final _groupIds = <String, String>{};
  final _customerIds = <String>[];
  final _vouchers = <String>[];
  /// Sales with a weighed line, for the refund that brings one back.
  final _weighed = <String>[];
  final _reasons = <ReasonKind, String>{};
  late List<Promotion> _promotions;
  var _reference = 0;

  T _get<T extends Object>(Setting<T> s) => s.decode(_settings[s.key]);

  Future<void> run() async {
    final end = clock.now();
    await _wipe();
    final deviceId = (await _db.readMeta(MetaKeys.deviceId))!;
    final device = _Device(deviceId);
    final audit = AuditRepository(_db, device);
    _r = _Repos(_db, device, audit);
    _settings = await SettingsRepository(_db, device, audit).loadAll();
    _shop = SampleShop.of(BusinessType.values.asNameMap()[_get(AppSettings.shopType)] ?? BusinessType.other);

    final today = DateTime(end.year, end.month, end.day);
    final first = today.subtract(Duration(days: days));
    _now = first.add(const Duration(hours: 7));
    await withClock(Clock(() => _now), () async {
      await _setUp(first);
      for (var d = 0; d < days; d++) {
        // A day at a time: one write to the disk instead of hundreds.
        await _db.transaction(() => _trade(d, first.add(Duration(days: d))));
      }
      await _today(end);
    });
  }

  /// Moves the clock on to [t], never back, so the activity log stays in order.
  void _at(DateTime t) => _now = t.isAfter(_now) ? t : _now.add(const Duration(seconds: 20));

  DateTime _on(DateTime day, int hour, [int minute = 0]) => DateTime(day.year, day.month, day.day, hour, minute);

  int _between(int from, int to) => from + _random.nextInt(to - from + 1);

  bool _chance(double p) => _random.nextDouble() < p;

  T _pick<T>(List<T> from) => from[_random.nextInt(from.length)];

  Future<void> _wipe() async {
    await _db.customStatement('PRAGMA foreign_keys = OFF');
    await _db.transaction(() async {
      for (final t in _replaced) {
        await _db.customStatement('DELETE FROM $t');
      }
      await _db.deleteMeta('cart.current');
      // Placements of devices in branches that are not the shop's own.
      await _db.customStatement('DELETE FROM device_branches WHERE id = ?', [branchDeviceId]);
    });
    await _db.customStatement('PRAGMA foreign_keys = ON');
  }

  // ---------------------------------------------------------------------------
  // The shop before the first day

  Future<void> _setUp(DateTime first) async {
    final staff = await _r.staff.list();
    if (staff.isEmpty) throw StateError('Training needs the shop owner.');
    _owner = staff.firstWhere((s) => s.role.builtIn == BuiltInRole.owner, orElse: () => staff.first);
    await _staff(first);
    await _payMethods();

    // Suppliers and stock.
    final suppliers = <String>[];
    for (final s in _shop.suppliers) {
      suppliers.add(await _r.suppliers.save(
        SupplierDraft(name: s.name, phone: s.phone, address: s.address, paymentTermsDays: s.termsDays, notes: 'Sample supplier'),
        by: _manager,
      ));
    }
    for (final s in _shop.stock) {
      _stockIds[s.name] = await _r.stock.saveItem(
        StockItemDraft(
          name: s.name,
          unit: s.unit,
          costMilli: s.costMilli,
          reorderPoint: s.opening == 0 ? null : s.opening ~/ 4,
          reorderQty: s.opening == 0 ? null : s.opening,
          supplierId: suppliers[s.supplier],
          tracksExpiry: s.expiry,
        ),
        by: _stockKeeper,
      );
    }
    final made = _shop.made;
    if (made != null) {
      await _r.stock.saveProductionRecipe(
        _stockIds[made.item]!,
        batchYield: made.makes,
        lines: [for (final (name, qty) in made.uses) (_stockIds[name]!, qty)],
        by: _manager,
      );
    }

    await _menu();
    await _offers(first);
    _promotions = await _r.promotions.list();
    for (final k in ReasonKind.values) {
      _reasons[k] = (await _r.discounts.reasons(k)).firstOrNull?.name ?? 'Other';
    }
    await _branch();

    // Opening stock: an order to each supplier, delivered the same morning.
    _at(_on(first, 7, 30));
    for (final (i, id) in suppliers.indexed) {
      final lines = [
        for (final s in _shop.stock)
          if (s.supplier == i && s.opening > 0) (_stockIds[s.name]!, s.opening),
      ];
      if (lines.isEmpty) continue;
      final order = await _r.orders.create(
        PurchaseOrderDraft(supplierId: id, lines: lines, expectedOn: first, note: 'Opening stock'),
        by: _manager,
      );
      await _deliver(id, lines, orderId: order.id, payPart: _shop.suppliers[i].termsDays != null);
    }

    // Customers, some with money in their wallet, and the owner's capital.
    for (final c in sampleCustomers) {
      final (month, day) = c.birthday ?? (0, 0);
      _customerIds.add(await _r.customers.save(
        CustomerDraft(
          name: c.name,
          phone: c.phone,
          location: c.location,
          tags: c.tags,
          creditLimit: c.creditLimit,
          dueDays: c.dueDays,
          birthday: c.birthday == null ? null : DateTime(1990, month, day),
          notes: 'Sample customer',
        ),
        by: _manager,
      ));
    }
    await _r.expenses.ownerMoney(
      kind: OwnerMoneyKind.capital,
      amount: 300000,
      source: MoneySource.bank,
      note: 'Money to start the month',
      actor: _owner,
    );
  }

  Future<void> _staff(DateTime first) async {
    final made = <(Staff, String)>[];
    var pin = 1000;
    for (final (i, (name, role, phone, start, finish)) in sampleStaff.indexed) {
      Staff? s;
      while (s == null) {
        pin += 1111;
        if (pin > 9999) pin -= 9000;
        try {
          s = await _r.staff.create(name: name, roleId: BuiltInRole.values.byName(role).id, pin: '$pin', by: _owner);
        } on StaffException {
          continue;
        }
      }
      await _r.staff.updateDetails(
        s.id,
        StaffDetails(
          name: name,
          phone: phone,
          address: _pick(['Lamashegu', 'Kalpohin', 'Sakasaka', 'Vittin', 'Gumani']),
          emergencyName: 'Family contact',
          emergencyPhone: '02443003${90 + i}',
          idNumber: 'GHA-7000000${10 + i}-${i + 1}',
          dateOfBirth: DateTime(1992 + i, 3 + i, 10 + i),
          startedOn: first.subtract(Duration(days: 200 + 90 * i)),
          notes: 'Sample staff for training. PIN $pin.',
        ),
        by: _owner,
      );
      await _r.staff.setWorkHours(s.id, start: start, end: finish, by: _owner);
      await _r.staff.newBadge(s.id, by: _owner);
      await _r.staff.setPhoto(s.id, _avatar(name, i), by: _owner);
      made.add((s, role));
    }
    _manager = made.firstWhere((m) => m.$2 == 'manager').$1;
    _cashiers = [for (final (s, role) in made) if (role == 'cashier') s];
    _stockKeeper = made.firstWhere((m) => m.$2 == 'stockKeeper').$1;
  }

  Future<void> _payMethods() async {
    final all = await _r.payMethods.list(includeInactive: true);
    PayMethod kind(PaymentMethod k) => all.firstWhere((m) => m.kind == k && m.active, orElse: () => all.firstWhere((m) => m.kind == k));
    _cash = kind(PaymentMethod.cash);
    _credit = kind(PaymentMethod.credit);
    _wallet = kind(PaymentMethod.wallet);
    _voucher = kind(PaymentMethod.voucher);
    _momo = [for (final m in all) if (m.kind == PaymentMethod.momo && m.active) m];
    if (_momo.isEmpty) _momo = [kind(PaymentMethod.momo)];
    _card = all.where((m) => m.kind == PaymentMethod.card && m.active).firstOrNull;
  }

  Future<void> _menu() async {
    final taxes = [for (final t in (await _r.catalog.load()).taxRates) t.id];
    final categories = <String, String>{};
    for (final (name, tone) in _shop.categories) {
      categories[name] = await _r.catalog.saveCategory(CategoryDraft(name: name, tone: tone), by: _manager);
    }
    List<RecipeDraftLine> recipe(List<(String, int)> uses) =>
        [for (final (name, qty) in uses) RecipeDraftLine(stockItemId: _stockIds[name]!, quantity: qty)];
    for (final g in _shop.groups) {
      _groupIds[g.name] = await _r.catalog.saveOptionGroup(
        OptionGroupDraft(
          name: g.name,
          minSelect: g.min,
          maxSelect: g.max,
          allowRepeat: g.repeat,
          options: [
            for (final o in g.options) OptionDraft(name: o.name, priceDelta: o.price, isDefault: o.isDefault, recipe: recipe(o.uses)),
          ],
        ),
        by: _manager,
      );
    }
    final stocked = <String>[];
    for (final p in _shop.products) {
      final id = await _r.catalog.saveProduct(
        ProductDraft(
          categoryId: categories[p.category]!,
          name: p.name,
          detail: p.detail,
          sellBy: p.sellBy,
          openPrice: p.openPrice,
          minPrice: p.minPrice,
          maxPrice: p.maxPrice,
          onQuickTab: p.quick,
          groupIds: [for (final g in p.groups) _groupIds[g]!],
          taxIds: taxes,
          variants: [
            for (final v in p.variants) VariantDraft(name: v.name, price: v.price, manualCost: v.cost, recipe: recipe(v.uses)),
          ],
        ),
        by: _manager,
      );
      if (p.variants.every((v) => v.uses.isNotEmpty) && p.sellBy == SellBy.each) stocked.add(id);
      final asset = p.photo;
      final picture = asset == null ? null : await _photo?.call(asset);
      if (picture != null) await _r.catalog.setPhoto(id, picture);
    }
    // Shelf labels for what is on the shelf.
    final menu = await _r.catalog.load();
    await _r.catalog.generateBarcodes(
      [for (final p in menu.products) if (stocked.contains(p.id)) ...p.variants.map((v) => v.id)],
      by: _manager,
    );
  }

  Future<void> _offers(DateTime first) async {
    for (final (name, kind, value, scope) in const [
      ('Student 10%', DiscountKind.percent, 10, DiscountScope.any),
      ('Regular customer 5%', DiscountKind.percent, 5, DiscountScope.order),
      ('Staff GH₵ 5 off', DiscountKind.amount, 500, DiscountScope.order),
    ]) {
      await _r.discounts.saveDiscount(name: name, kind: kind, value: value, scope: scope, by: _manager);
    }
    final menu = await _r.catalog.load();
    String productId(String name) => menu.products.firstWhere((p) => p.name == name).id;
    for (final deal in _shop.deals) {
      final target = PromoTarget(products: {productId(deal.product)});
      final price = deal.price;
      await _r.promotions.save(
        Promotion(
          id: '',
          name: deal.name,
          kind: price == null ? PromotionKind.buyGet : PromotionKind.quantityBreak,
          rule: price == null
              ? PromoRule(target: target, reward: target, quantity: deal.quantity, percent: 100)
              : PromoRule(target: target, quantity: deal.quantity, amount: price),
        ),
        by: _manager,
      );
    }
    await _r.promotions.save(
      Promotion(
        id: '',
        name: 'Afternoon happy hour: 10% off ${_shop.categories.first.$1.toLowerCase()}',
        kind: PromotionKind.percentOff,
        rule: PromoRule(target: PromoTarget(categories: {menu.categories.first.id}), percent: 10),
        days: 31, // Monday to Friday
        fromMinute: 14 * 60,
        toMinute: 15 * 60,
      ),
      by: _manager,
    );
    await _r.promotions.save(
      Promotion(
        id: '',
        name: 'Spend ${_shop.spendThreshold ~/ 100} cedis, save 5%',
        kind: PromotionKind.spend,
        rule: PromoRule(threshold: _shop.spendThreshold, percent: 5),
        startsOn: first,
      ),
      by: _manager,
    );

    // The running costs, confirmed each month.
    final categories = await _r.expenses.categories();
    String category(String name) => categories.firstWhere((c) => c.name == name, orElse: () => categories.last).id;
    for (final (name, cat, amount, day, from) in [
      ('Shop rent', 'Rent', 80000, 1, MoneySource.bank),
      ('ECG prepaid', 'Electricity (ECG)', 25000, 10, MoneySource.momo),
      ('Water bill', 'Water', 6000, 15, MoneySource.momo),
      ('Staff wages', 'Staff wages', 180000, 25, MoneySource.bank),
    ]) {
      await _r.expenses.saveRecurring(name: name, categoryId: category(cat), amount: amount, dayOfMonth: day, paidFrom: from, by: _manager);
    }
  }

  Future<void> _branch() async {
    final id = await _r.branches.save(BranchDraft(name: _shop.branch, address: 'Tamale', phone: '0244300399'), by: _owner);
    await _r.branches.placeDevice(id, deviceId: branchDeviceId, deviceName: 'Branch till', by: _owner);
    _branchId = id;
  }

  late String _branchId;

  /// A delivery of [lines] (stock item → base units) from [supplierId].
  Future<void> _deliver(String supplierId, List<(String, int)> lines, {String? orderId, bool payPart = false}) async {
    final items = {for (final s in await _r.stock.items(includeInactive: true)) s.id: s};
    final draft = [
      for (final (id, qty) in lines)
        ReceiptLineDraft(
          stockItemId: id,
          quantity: qty,
          lineTotal: (qty * items[id]!.costMilli + 500) ~/ 1000,
          batchNo: items[id]!.tracksExpiry ? 'B${_between(10000, 99999)}' : null,
          expiresOn: items[id]!.tracksExpiry ? _now.add(Duration(days: _between(12, 120))) : null,
        ),
    ];
    final total = draft.fold(0, (s, l) => s + l.lineTotal);
    final paid = payPart ? total ~/ 2 : total;
    await _r.receiving.receive(
      ReceiptDraft(
        supplierId: supplierId,
        purchaseOrderId: orderId,
        invoiceRef: 'INV-${_between(1000, 9999)}',
        lines: draft,
        paidNow: paid,
        paidWith: paid == 0 ? null : _pick([SupplierPaymentMethod.cash, SupplierPaymentMethod.momo, SupplierPaymentMethod.bank]),
      ),
      by: _stockKeeper,
    );
  }

  // ---------------------------------------------------------------------------
  // A day's trading

  Future<void> _trade(int d, DateTime day) async {
    final cashier = _cashiers[d % _cashiers.length];
    final team = [cashier, _manager, if (day.weekday <= DateTime.friday) _stockKeeper];
    _at(_on(day, 7, 40));
    for (final s in team) {
      await _r.times.clockIn(s);
    }
    _at(_on(day, 8));
    await _r.shifts.open(float: 20000, count: const CashCount({2000: 5, 1000: 6, 500: 6, 100: 10}), by: cashier);

    // Last night's MoMo, ticked off against the statement.
    if (d > 0) await _checkMomo(day.subtract(const Duration(days: 1)));
    for (final r in await _r.expenses.due(now: _now)) {
      await _r.expenses.confirm(r, actor: _manager, now: _now);
    }
    await _oneOffs(d, day);

    final menu = await _r.catalog.load();
    final count = day.weekday == DateTime.sunday ? _between(3, 6) : _between(7, 14);
    final sold = <CompletedSale>[];
    for (var i = 0; i < count; i++) {
      _at(_on(day, 8, 30).add(Duration(minutes: 570 * i ~/ count + _between(0, 25))));
      if (i == count ~/ 2) {
        await _r.times.startBreak(cashier);
      }
      if (i == count ~/ 2 + 1) await _r.times.endBreak(cashier);
      final sale = await _sell(menu, cashier, d, i);
      if (sale != null) sold.add(sale);
      if (i == 2 && d % 3 == 0) {
        await _r.cashEvents.noSale(reason: _reasons[ReasonKind.noSale]!, actor: cashier);
      }
    }

    // Money in and out of the drawer.
    _at(_on(day, 13, 15));
    if (d % 2 == 0) {
      final cats = await _r.expenses.categories();
      await _r.expenses.add(
        ExpenseDraft(
          day: day,
          amount: _between(5, 30) * 100,
          categoryId: _pick(cats.where((c) => const {'Transport', 'Ice', 'Packaging', 'Phone credit and data'}.contains(c.name)).toList()).id,
          paidFrom: MoneySource.drawer,
          note: _pick(['Taxi to the market', 'Bought ice', 'Carrier bags', 'Data bundle for the shop phone']),
        ),
        photo: d % 4 == 0 ? _receipt() : null,
        actor: cashier,
      );
    }
    if (d % 6 == 1) {
      await _r.cashEvents.payInOrOut(payIn: true, amount: 5000, reason: 'Change from the bank', actor: _manager);
    }
    _at(_on(day, 15));
    if (d % 2 == 1) await _r.safe.drop(10000, actor: _manager, note: 'Afternoon drop');

    // Something sold earlier comes back, or is called off.
    if (sold.length > 3 && d % 4 == 2) await _refund(sold[1].saleId, cashier);
    // Once, something sold by weight comes back (it must come back whole).
    if (d == 6 && _weighed.isNotEmpty) await _refund(_weighed.last, cashier, weighed: true);
    if (sold.length > 3 && d % 5 == 3) {
      _at(_on(day, 16));
      await _r.sales.voidSale(sold.last.saleId, actor: cashier, approver: _manager, reason: _reasons[ReasonKind.voidSale]!);
    }
    if (d % 3 == 1) await _repay(day);
    if (d % 5 == 4) await _waste();

    final momo = sold.where((s) => s.total > 0).length * 15;
    await _r.momo.setCharges(day, momo, note: 'MoMo charges and e-levy', by: _manager);

    // Close the day, nearly always balanced.
    _at(_on(day, 18, 15));
    final period = await _r.closes.openPeriod();
    final expected = period.expectedCash(20000);
    final variance = _chance(0.8) ? 0 : _pick([-500, -200, -100, 100, 200]);
    final counted = max(0, expected + variance);
    await _r.closes.closeDay(
      openingFloat: 20000,
      countedCash: counted,
      closedBy: cashier,
      cashCount: _countOf(counted),
      varianceReason: variance == 0 ? null : (variance < 0 ? 'Short: change given wrongly' : 'Over: customer left change'),
    );
    _at(_on(day, 18, 30));
    for (final s in team) {
      await _r.times.clockOut(s);
    }

    // Weekly: bank the safe, pay suppliers, take drawings.
    if (d % 7 == 6) {
      _at(_on(day, 18, 45));
      final inSafe = await _r.safe.balance();
      if (inSafe > 0) {
        await _r.safe.deposit(inSafe, bank: 'GCB Bank', reference: 'DEP${_between(100000, 999999)}', slip: _receipt(), by: _manager);
      }
      await _r.expenses.ownerMoney(kind: OwnerMoneyKind.drawing, amount: 30000, source: MoneySource.bank, note: 'Weekly drawing', actor: _owner);
      for (final s in await _r.suppliers.list()) {
        if (s.balance > 1) {
          await _r.suppliers.recordPayment(s.id, amount: s.balance ~/ 2, method: SupplierPaymentMethod.momo, reference: 'SP${_between(10000, 99999)}', by: _manager);
        }
      }
    }
  }

  /// Things that happen once in the month, so every screen has an example.
  Future<void> _oneOffs(int d, DateTime day) async {
    if (d == 1) {
      for (final id in _customerIds.take(2)) {
        await _r.customers.topUp(id, amount: 5000, method: _cash, note: 'Paid in advance', by: _manager);
      }
    }
    if (d == 2) {
      for (final (i, amount) in [10000, 5000].indexed) {
        final v = await _r.vouchers.issue(
          amount: amount,
          method: i == 0 ? _cash : _momo.first,
          reference: i == 0 ? null : _nextReference(),
          shopName: _get(AppSettings.shopName),
          customerId: i == 0 ? _customerIds[2] : null,
          expiresOn: day.add(const Duration(days: 180)),
          note: 'Birthday present',
          by: _manager,
        );
        _vouchers.add(v.code);
      }
    }
    if (d == 3) {
      // A price rise from tomorrow, and one still to come after today.
      final menu = await _r.catalog.load();
      final v = menu.products.first.variants.first;
      await _r.catalog.schedulePrice(v.id, v.price + v.price ~/ 10, day.add(const Duration(days: 1)), by: _manager);
      final later = menu.products.last.variants.first;
      await _r.catalog.schedulePrice(later.id, later.price + later.price ~/ 20, day.add(Duration(days: days + 5)), by: _manager);
    }
    if (d == 4) await _r.catalog.applyDuePrices(now: _now);
    if (d == 5) {
      // An order called off.
      final supplier = (await _r.suppliers.list()).last;
      final item = _shop.stock.firstWhere((s) => s.opening > 0);
      final order = await _r.orders.create(
        PurchaseOrderDraft(supplierId: supplier.id, lines: [(_stockIds[item.name]!, item.opening ~/ 2)], note: 'Ordered twice by mistake'),
        by: _stockKeeper,
      );
      await _r.orders.cancel(order.id, by: _manager);
    }
    final made = _shop.made;
    if (made != null && d % 7 == 0) {
      await _r.stock.produce(_stockIds[made.item]!, made.makes * 3, note: 'Morning batch', by: _stockKeeper);
    }
    if (d % 7 == 3) await _reorder(partial: d == days - 4);
    if (d == 12) await _count();
    // Stock to the other branch: one received (one short), one on its way.
    if (d == days - 8) await _transfer(receive: true);
    if (d == days - 1) await _transfer(receive: false);
    if (d == 18) {
      final owing = await _r.customers.list(owing: true);
      if (owing.isNotEmpty) {
        await _r.customers.writeOff(owing.last.id, amount: min(1000, owing.last.owed), reason: 'Small balance forgiven', actor: _owner);
      }
    }
  }

  /// One customer at the till.
  Future<CompletedSale?> _sell(Catalogue menu, Staff cashier, int d, int i) async {
    final products = [
      for (final p in menu.products)
        if (p.active)
          for (var w = 0; w < (_shop.products.where((s) => s.name == p.name).firstOrNull?.popular ?? 1); w++) p,
    ];
    final lines = <CartLine>[];
    for (var n = _between(1, 3); n > 0; n--) {
      final p = _pick(products);
      if (lines.any((l) => l.product.id == p.id)) continue;
      final options = <Option>[];
      for (final g in p.groups) {
        final want = g.minSelect > 0 ? g.minSelect : (_chance(0.4) ? 1 : 0);
        for (var k = 0; k < want && g.options.isNotEmpty; k++) {
          options.add(_pick(g.options));
        }
      }
      final open = p.openPrice ? _between(((p.minPrice ?? 100) ~/ 100), ((p.maxPrice ?? 5000) ~/ 100) ~/ 3 + 1) * 100 : null;
      lines.add(CartLine(
        product: p,
        variant: _pick(p.variants),
        options: options,
        quantity: p.weighed ? _between(2, 10) * 250 : (_chance(0.75) ? 1 : _between(2, 4)),
        customPrice: open,
        discount: _chance(0.06)
            ? Discount(kind: DiscountKind.percent, value: 10, reason: _reasons[ReasonKind.discount]!, name: 'Student 10%')
            : null,
      ));
    }
    if (lines.isEmpty) return null;

    final taxMode = TaxMode.fromName(_get(AppSettings.taxMode));
    final loyalty = LoyaltyConfig.read(_get);
    final ordersOn = _get(AppSettings.ordersOn);
    final most = CartPricing.of(lines, taxMode: taxMode).total;
    final customerId = _chance(0.35) ? _pick(_customerIds) : null;
    final customer = customerId == null ? null : await _r.customers.find(customerId);

    var payments = <PaymentInput>[];
    var changeToWallet = false;
    final roll = _random.nextDouble();
    if (d == 9 && i == 1 && _vouchers.isNotEmpty) {
      payments = [PaymentInput.from(_voucher, reference: _vouchers.first, amount: max(1, min(most ~/ 2, 5000))), PaymentInput.from(_cash, tendered: _roundUp(most))];
    } else if (customer != null && customer.wallet > most && roll < 0.3) {
      payments = [PaymentInput.from(_wallet)];
    } else if (customer != null && customer.creditLimit != null && roll < 0.35) {
      payments = [PaymentInput.from(_credit, customer: customer.name)];
    } else if (roll < 0.55) {
      payments = [PaymentInput.from(_cash, tendered: _roundUp(most))];
      changeToWallet = customer != null && _chance(0.15);
    } else if (roll < 0.85) {
      payments = [PaymentInput.from(_pick(_momo), reference: _nextReference())];
    } else if (roll < 0.93 && most > 200) {
      final half = most ~/ 200 * 100;
      payments = [PaymentInput.from(_cash, amount: half, tendered: half), PaymentInput.from(_pick(_momo), reference: _nextReference())];
    } else if (_card != null) {
      payments = [PaymentInput.from(_card!, reference: 'POS${_between(100000, 999999)}')];
    } else {
      payments = [PaymentInput.from(_cash, tendered: _roundUp(most))];
    }

    final orders = ordersOn
        ? OrderConfig(
            prep: LoyaltyConfig.decodeTarget(_get(AppSettings.orderPrepTarget)),
            prefix: _get(AppSettings.orderPrefix),
            dayStartMinutes: _get(AppSettings.businessDayStart),
          )
        : null;
    try {
      final sale = await _r.sales.completeSale(
        lines: lines,
        payments: payments,
        cashier: cashier,
        taxMode: taxMode,
        orderType: _get(AppSettings.orderTypes) ? _pick(OrderType.values) : null,
        note: _chance(0.05) ? _pick(['Less sugar', 'Wrap it well', 'Collect at 4']) : null,
        customer: customer,
        changeToWallet: changeToWallet,
        creditApprover: _manager,
        promotions: _promotions,
        loyalty: loyalty,
        orders: orders,
        orderDiscount: customer != null && _chance(0.1)
            ? Discount(kind: DiscountKind.percent, value: 5, reason: _reasons[ReasonKind.discount]!, name: 'Regular customer 5%')
            : null,
      );
      if (sale.orderNumber != null) {
        for (final s in [OrderStatus.preparing, OrderStatus.ready, OrderStatus.collected]) {
          await _r.kitchen.setStatus(sale.saleId, s);
        }
      }
      if (lines.any((l) => l.weighed)) _weighed.add(sale.saleId);
      return sale;
    } on SaleException {
      // A pretend customer whose payment the till turned down: skip them.
      return null;
    }
  }

  int _roundUp(int pesewas) {
    final step = pesewas > 5000 ? 1000 : 500;
    return (pesewas + step - 1) ~/ step * step + (_chance(0.3) ? step : 0);
  }

  String _nextReference() => '${5200000000 + ++_reference * 7919}';

  Future<void> _refund(String saleId, Staff cashier, {bool weighed = false}) async {
    final refundable = await _r.refunds.refundable(saleId);
    final line = refundable?.lines.where((l) => !weighed || l.weighed).firstOrNull;
    if (refundable == null || line == null || refundable.voided) return;
    // Weighed lines come back whole; counted ones one at a time.
    final quantity = line.weighed ? line.left : min(1, line.left);
    if (quantity <= 0) return;
    final draft = RefundDraft(
      saleId: saleId,
      lines: [
        RefundLineDraft(saleLineId: line.saleLineId, name: line.title, quantity: quantity, sellBy: line.sellBy, restock: _chance(0.7)),
      ],
      reason: _reasons[ReasonKind.refund]!,
      note: 'Customer brought it back',
    );
    final (_, total) = await _r.refunds.price(draft);
    if (total <= 0) return;
    await _r.refunds.refund(
      draft,
      payments: [RefundPaymentInput(method: PaymentMethod.cash, methodId: _cash.id, methodName: _cash.name, amount: total)],
      actor: cashier,
      approver: _manager,
    );
  }

  Future<void> _repay(DateTime day) async {
    _at(_on(day, 16, 30));
    for (final c in (await _r.customers.list(owing: true)).take(2)) {
      final momo = _chance(0.5);
      await _r.customers.repay(
        c.id,
        amount: min(c.owed, max(100, c.owed ~/ 2 ~/ 100 * 100)),
        method: momo ? _momo.first : _cash,
        reference: momo ? _nextReference() : null,
        note: 'Part payment',
        by: _manager,
      );
    }
  }

  Future<void> _waste() async {
    final items = (await _r.stock.items()).where((s) => s.onHand > 10).toList();
    if (items.isEmpty) return;
    final s = _pick(items);
    await _r.stock.logWaste(
      s.id,
      max(1, s.onHand ~/ 50),
      reason: _pick([WasteReason.damaged, WasteReason.expired, WasteReason.powerCut, WasteReason.staffMeal]),
      note: 'Found at closing',
      by: _stockKeeper,
    );
  }

  /// Orders what is running low and receives it; with [partial], the first
  /// supplier brings only half.
  Future<void> _reorder({bool partial = false}) async {
    final low = (await _r.stock.items()).where((s) => s.reorderPoint != null && s.onHand <= s.reorderPoint! * 2).toList();
    final bySupplier = <String, List<StockItem>>{};
    for (final s in low) {
      if (s.supplierId != null) bySupplier.putIfAbsent(s.supplierId!, () => []).add(s);
    }
    for (final (i, MapEntry(key: supplier, value: items)) in bySupplier.entries.indexed) {
      final lines = [for (final s in items) (s.id, s.reorderQty!)];
      final order = await _r.orders.create(
        PurchaseOrderDraft(supplierId: supplier, lines: lines, expectedOn: _now.add(const Duration(days: 1)), note: 'Running low'),
        by: _stockKeeper,
      );
      await _deliver(
        supplier,
        [for (final (id, qty) in lines) (id, partial && i == 0 ? qty ~/ 2 : qty)],
        orderId: order.id,
        payPart: _chance(0.6),
      );
    }
  }

  Future<void> _transfer({required bool receive}) async {
    final items = (await _r.stock.items()).where((s) => s.onHand > 4).take(4).toList();
    if (items.isEmpty) return;
    final t = await _r.transfers.send(
      toBranch: _branchId,
      lines: {for (final s in items) s.id: max(1, s.onHand ~/ 10)},
      note: 'For the weekend at ${_shop.branch}',
      by: _stockKeeper,
    );
    if (!receive) return;
    _at(_now.add(const Duration(hours: 3)));
    final line = t.lines.first;
    await _r.branchTransfers.receive(t.id, received: {line.id: max(0, line.quantitySent - 1)}, by: _manager);
  }

  Future<void> _count() async {
    final id = await _r.counts.start(blind: true, note: 'Monthly count', by: _manager);
    for (final s in (await _r.stock.items()).where((s) => s.onHand > 0).take(6)) {
      await _r.counts.setCount(id, s.id, max(0, s.onHand - (_chance(0.5) ? max(1, s.onHand ~/ 100) : 0)), by: _stockKeeper);
    }
    await _r.counts.post(id, by: _manager);
  }

  Future<void> _checkMomo(DateTime day) async {
    final items = await _r.momo.items(day, day.add(const Duration(days: 1)));
    for (final (i, m) in items.indexed) {
      await _r.momo.check(m, i == 3 ? false : true, by: _manager);
    }
  }

  /// Today: carts put aside, an order on its way, stock in transit.
  Future<void> _today(DateTime end) async {
    _at(end.subtract(const Duration(minutes: 30)));
    final menu = await _r.catalog.load();
    for (final (name, n) in [('Table 2', 2), ('Blue shirt', 1)]) {
      final lines = [for (final p in menu.products.take(n + 1)) CartLine(product: p)];
      await _r.parked.park(
        name: name,
        cart: {'lines': [for (final l in lines) l.toJson()]},
        total: lines.fold(0, (s, l) => s + l.lineTotal),
        itemCount: lines.length,
        by: _cashiers.first,
      );
    }
    final low = (await _r.stock.items()).where((s) => s.reorderQty != null && s.supplierId != null).take(3).toList();
    if (low.isNotEmpty) {
      await _r.orders.create(
        PurchaseOrderDraft(
          supplierId: low.first.supplierId!,
          lines: [for (final s in low.where((s) => s.supplierId == low.first.supplierId)) (s.id, s.reorderQty!)],
          expectedOn: end.add(const Duration(days: 3)),
          note: 'For next week',
        ),
        by: _stockKeeper,
      );
    }
  }

  CashCount _countOf(int pesewas) {
    final pieces = <int, int>{};
    var left = pesewas;
    for (final d in const [20000, 10000, 5000, 2000, 1000, 500, 200, 100, 50, 20, 10]) {
      if (left >= d) {
        pieces[d] = left ~/ d;
        left %= d;
      }
    }
    return CashCount(pieces);
  }

  static const _colours = [(0x10, 0x13, 0x22), (0x2f, 0x6f, 0xeb), (0xe8, 0x5d, 0x4a), (0x3a, 0x8f, 0x5c)];

  /// A coloured square with initials, for the pretend staff.
  Uint8List _avatar(String name, int i) {
    final (r, g, b) = _colours[i % _colours.length];
    final image = img.Image(width: 160, height: 160);
    img.fill(image, color: img.ColorRgb8(r, g, b));
    final initials = name.split(' ').map((w) => w[0]).take(2).join();
    img.drawString(image, initials, font: img.arial48, x: 42, y: 52, color: img.ColorRgb8(255, 255, 255));
    return img.encodePng(image);
  }

  /// A plain slip, for receipts and bank deposits.
  Uint8List _receipt() {
    final image = img.Image(width: 240, height: 320);
    img.fill(image, color: img.ColorRgb8(0xf6, 0xf7, 0xf2));
    img.drawString(image, 'RECEIPT', font: img.arial24, x: 70, y: 24, color: img.ColorRgb8(0x10, 0x13, 0x22));
    for (var y = 80; y < 280; y += 28) {
      img.fillRect(image, x1: 24, y1: y, x2: 24 + _between(100, 190), y2: y + 8, color: img.ColorRgb8(0xbb, 0xbd, 0xb5));
    }
    return img.encodePng(image);
  }
}

class _Device implements DeviceInfo {
  const _Device(this.deviceId);

  @override
  final String deviceId;
}

/// Every repository the seeder uses, wired as InitialBinding wires them.
class _Repos {
  _Repos(AppDatabase db, DeviceInfo device, AuditRepository audit)
      : stock = StockRepository(db, device, audit),
        cashEvents = CashEventRepository(db, device, audit),
        customers = CustomerRepository(db, device, audit),
        shifts = ShiftRepository(db, device, audit),
        payMethods = PayMethodRepository(db, device, audit),
        vouchers = VoucherRepository(db, device, audit, random: Random(11)),
        suppliers = SupplierRepository(db, device, audit),
        catalog = CatalogRepository(db, device, audit),
        staff = StaffRepository(db, device, audit),
        discounts = DiscountRepository(db, device, audit),
        promotions = PromotionRepository(db, device, audit),
        parked = ParkedOrderRepository(db, device, audit),
        branches = BranchRepository(db, device, audit),
        momo = MomoRepository(db, device, audit),
        kitchen = OrderRepository(db),
        times = TimeRepository(db, device) {
    safe = SafeRepository(db, device, audit, cashEvents);
    expenses = ExpenseRepository(db, device, audit, cashEvents);
    closes = DayCloseRepository(db, device, audit, cashEvents, customers, shifts);
    refunds = RefundRepository(db, device, audit, stock, customers);
    sales = SaleRepository(db, stock, closes, audit, device, refunds, customers, vouchers);
    orders = PurchaseOrderRepository(db, device, audit, stock);
    receiving = ReceivingRepository(db, device, audit, stock, suppliers, orders);
    counts = StockCountRepository(db, device, audit, stock);
    transfers = TransferRepository(db, device, audit, stock);
    // The branch till, for stock sent there.
    const branchDevice = _Device(TrainingSeeder.branchDeviceId);
    final branchAudit = AuditRepository(db, branchDevice);
    branchTransfers = TransferRepository(db, branchDevice, branchAudit, StockRepository(db, branchDevice, branchAudit));
  }

  final StockRepository stock;
  final CashEventRepository cashEvents;
  final CustomerRepository customers;
  final ShiftRepository shifts;
  final PayMethodRepository payMethods;
  final VoucherRepository vouchers;
  final SupplierRepository suppliers;
  final CatalogRepository catalog;
  final StaffRepository staff;
  final DiscountRepository discounts;
  final PromotionRepository promotions;
  final ParkedOrderRepository parked;
  final BranchRepository branches;
  final MomoRepository momo;
  final OrderRepository kitchen;
  final TimeRepository times;
  late final SafeRepository safe;
  late final ExpenseRepository expenses;
  late final DayCloseRepository closes;
  late final RefundRepository refunds;
  late final SaleRepository sales;
  late final PurchaseOrderRepository orders;
  late final ReceivingRepository receiving;
  late final StockCountRepository counts;
  late final TransferRepository transfers;
  late final TransferRepository branchTransfers;
}
