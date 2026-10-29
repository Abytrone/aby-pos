import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/refund_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../models/catalog.dart';
import '../../../models/customer.dart';
import '../../../models/sale.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/receipt_actions.dart';
import '../../till/controllers/cart_controller.dart';
import '../../till/controllers/till_controller.dart';
import '../../till/views/till_view.dart' show showPicker;
import '../../till/widgets/entry_dialog.dart';
import '../../today/controllers/today_controller.dart';
import '../controllers/shell_controller.dart';

/// One thing the command bar found, with what can be done with it.
class CommandResult {
  const CommandResult({required this.group, required this.title, this.subtitle, required this.icon, required this.actions});

  final String group;
  final String title;
  final String? subtitle;
  final IconData icon;

  /// (label, what it does); the first is the default (Enter or a tap).
  final List<(String, FutureOr<void> Function())> actions;
}

/// A named action: "Close day", "Add expense", "Receive stock".
class _Action {
  const _Action(this.label, this.keywords, this.icon, this.run, {this.anyOf});

  final String label;
  final List<String> keywords;
  final IconData icon;
  final FutureOr<void> Function() run;

  /// Shown to people with any of these; null for everyone.
  final Set<Permission>? anyOf;
}

/// Universal search (APP-03): products, customers, sales by number or MoMo
/// reference, staff and actions, in one box. Ctrl+K or the search icon.
/// Results only offer what the signed-in person may do.
Future<void> showCommandBar() async {
  if (Get.isDialogOpen ?? false) return;
  await Get.dialog<void>(const _CommandBar(), barrierColor: Colors.black38);
}

class _CommandBar extends StatefulWidget {
  const _CommandBar();

  @override
  State<_CommandBar> createState() => _CommandBarState();
}

class _CommandBarState extends State<_CommandBar> {
  final _query = TextEditingController();
  Catalogue? _menu;
  List<CommandResult> _results = const [];
  Timer? _debounce;
  int _search = 0;

  AuthService get _auth => Get.find();
  bool _can(Set<Permission>? anyOf) => anyOf == null || anyOf.any(_auth.can);

  @override
  void initState() {
    super.initState();
    unawaited(Get.find<CatalogRepository>().load().then((m) {
      if (mounted) setState(() => _menu = m);
    }));
    _query.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 150), _run);
    });
    _run();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// Leaves the bar, then does [action].
  FutureOr<void> Function() _then(FutureOr<void> Function() action) => () async {
        Get.back<void>();
        await action();
      };

  ShellController? get _shell => Get.isRegistered<ShellController>() ? Get.find<ShellController>() : null;

  List<_Action> _actions(AppLocalizations l) {
    void go(ShellSection s) => _shell?.select(s);
    return [
      _Action(l.navSell, ['sell', 'till', 'cart'], Icons.point_of_sale_outlined, () => go(ShellSection.sell), anyOf: {Permission.sell}),
      _Action(l.navToday, ['today', 'sales', 'void', 'refund'], Icons.today_outlined, () => go(ShellSection.today)),
      _Action(l.closeDayButton, ['close day', 'cash up', 'z report', 'end of day'], Icons.lock_clock_outlined, () async {
        go(ShellSection.today);
        await Get.find<TodayController>().openCloseDay();
      }, anyOf: {Permission.closeDay}),
      _Action(l.todayRefundNoReceipt, ['refund', 'return'], Icons.undo, () => Get.toNamed<void>(Routes.refund), anyOf: {Permission.refundWithoutReceipt}),
      _Action(l.receiveNew, ['receive', 'delivery', 'stock in', 'goods'], Icons.local_shipping_outlined, () => Get.toNamed<void>(Routes.receive),
          anyOf: {Permission.receiveStock}),
      _Action(l.commandNewProduct, ['new product', 'add product'], Icons.add_box_outlined, () => Get.toNamed<void>(Routes.productEditor),
          anyOf: {Permission.editProducts}),
      _Action(l.commandAddExpense, ['expense', 'spend', 'bill', 'money'], Icons.receipt_long_outlined, () => go(ShellSection.money),
          anyOf: {Permission.manageExpenses}),
      _Action(l.navDashboard, ['dashboard', 'home'], Icons.dashboard_outlined, () => go(ShellSection.dashboard), anyOf: {Permission.viewReports}),
      _Action(l.navReports, ['reports', 'sales report', 'accountant'], Icons.bar_chart_outlined, () => go(ShellSection.reports),
          anyOf: {Permission.viewReports}),
      _Action(l.navProducts, ['products', 'menu', 'prices', 'labels'], Icons.sell_outlined, () => go(ShellSection.products),
          anyOf: {Permission.editProducts, Permission.changePrices}),
      _Action(l.navStock, ['stock', 'inventory', 'count', 'waste', 'expiring'], Icons.inventory_2_outlined, () => go(ShellSection.stock),
          anyOf: {Permission.receiveStock, Permission.adjustStock, Permission.approveStockCount}),
      _Action(l.navCustomers, ['customers', 'credit', 'vouchers'], Icons.people_outline, () => go(ShellSection.customers),
          anyOf: {Permission.manageCustomers, Permission.giveCredit}),
      _Action(l.navStaff, ['staff', 'timesheets', 'roles'], Icons.badge_outlined, () => go(ShellSection.staff), anyOf: {Permission.manageStaff}),
      _Action(l.navActivity, ['activity', 'log', 'audit'], Icons.history_outlined, () => go(ShellSection.activity),
          anyOf: {Permission.viewActivityLog}),
      _Action(l.navSettings, ['settings', 'printer', 'backup', 'promotions', 'loyalty'], Icons.settings_outlined, () => go(ShellSection.settings)),
    ];
  }

  Future<void> _run() async {
    // appL10n: the first search runs from initState.
    final l = appL10n();
    final q = _query.text.trim().toLowerCase();
    final run = ++_search;
    final out = <CommandResult>[];
    bool hit(String text) => text.toLowerCase().contains(q);

    for (final a in _actions(l)) {
      if (!_can(a.anyOf)) continue;
      if (q.isEmpty || hit(a.label) || a.keywords.any(hit)) {
        out.add(CommandResult(group: l.commandActions, title: a.label, icon: a.icon, actions: [(l.commandOpen, _then(a.run))]));
      }
    }

    if (q.isNotEmpty) {
      // Products.
      final menu = _menu;
      if (menu != null) {
        for (final p in menu.products.where((p) => hit(p.name) || p.variants.any((v) => v.barcodes.any(hit))).take(6)) {
          out.add(CommandResult(
            group: l.navProducts,
            title: p.name,
            subtitle: p.variants.length == 1 ? formatMoney(p.variants.single.price) : l.commandFrom(formatMoney(p.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b))),
            icon: Icons.sell_outlined,
            actions: [
              if (_auth.can(Permission.sell)) (l.commandAddToCart, _then(() => _addToCart(p))),
              if (_auth.can(Permission.editProducts)) (l.commandEditProduct, _then(() => Get.toNamed<void>(Routes.productEditor, arguments: p.id))),
            ],
          ));
        }
      }

      // Customers.
      if (_can({Permission.sell, Permission.manageCustomers})) {
        for (final c in (await Get.find<CustomerRepository>().list(query: q, limit: 5))) {
          out.add(CommandResult(
            group: l.navCustomers,
            title: c.name,
            subtitle: c.owed > 0 ? l.customerOwes(formatMoney(c.owed)) : c.phone,
            icon: Icons.person_outline,
            actions: [
              if (_auth.can(Permission.sell)) (l.commandAddToSale, _then(() => _attach(c))),
              if (_can({Permission.manageCustomers, Permission.giveCredit}))
                (l.commandOpenCustomer, _then(() => Get.toNamed<void>(Routes.customer, arguments: c.id))),
            ],
          ));
        }
      }

      // Sales by number or MoMo reference.
      for (final (id, number, total) in await _sales(q)) {
        out.add(CommandResult(
          group: l.commandSales,
          title: '${formatSaleNumber(number)}  ·  ${formatMoney(total)}',
          icon: Icons.receipt_outlined,
          actions: [
            (l.commandReprint, _then(() => printSaleReceipt(id))),
            if (_auth.can(Permission.refund)) (l.todayRefund, _then(() => Get.toNamed<void>(Routes.refund, arguments: id))),
          ],
        ));
      }

      // Staff.
      if (_auth.can(Permission.manageStaff)) {
        for (final s in (await Get.find<StaffRepository>().list()).where((s) => hit(s.name)).take(5)) {
          out.add(CommandResult(
            group: l.navStaff,
            title: s.name,
            icon: Icons.badge_outlined,
            actions: [(l.commandOpenProfile, _then(() => Get.toNamed<void>(Routes.staffProfile, arguments: s.id)))],
          ));
        }
      }
    }
    if (mounted && run == _search) setState(() => _results = [for (final r in out) if (r.actions.isNotEmpty) r]);
  }

  /// (sale ID, number, total) for "142", "#00142" or a MoMo reference.
  Future<List<(String, int, int)>> _sales(String q) async {
    final out = <(String, int, int)>[];
    final db = Get.find<AppDatabase>();
    final byNumber = await Get.find<RefundRepository>().saleIdByNumber(q);
    final ids = <String>{?byNumber};
    if (q.replaceAll(RegExp('[^0-9a-z]'), '').length >= 4) {
      final rows = await db.customSelect(
        'SELECT DISTINCT sale_id AS id FROM payments WHERE deleted_at IS NULL AND LOWER(momo_reference) LIKE ? LIMIT 5',
        variables: [Variable.withString('%$q%')],
        readsFrom: {db.payments},
      ).get();
      ids.addAll(rows.map((r) => r.read<String>('id')));
    }
    for (final id in ids) {
      final s = await (db.select(db.sales)..where((x) => x.id.equals(id))).getSingleOrNull();
      if (s != null) out.add((s.id, s.number, s.total));
    }
    return out;
  }

  Future<void> _addToCart(Product p) async {
    _shell?.select(ShellSection.sell);
    if (!Get.isRegistered<TillController>()) return;
    final till = Get.find<TillController>();
    final result = till.tapProduct(p);
    final context = Get.context;
    if (result == TapResult.picker && context != null && context.mounted) showPicker(context, till);
    if (result == TapResult.entry) await showEntryDialog(till);
  }

  void _attach(Customer c) {
    Get.find<CartController>().customer.value = c;
    _shell?.select(ShellSection.sell);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final groups = <String, List<CommandResult>>{};
    for (final r in _results) {
      groups.putIfAbsent(r.group, () => []).add(r);
    }
    return Align(
      alignment: const Alignment(0, -0.6),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(AbyRadius.md),
        elevation: 12,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(AbySpace.s3),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) {
                  final first = _results.firstOrNull;
                  if (first != null) first.actions.first.$2();
                },
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.commandHint, isDense: true),
              ),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.only(bottom: AbySpace.s3), children: [
                if (_results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AbySpace.s4),
                    child: Text(l.commandNothing, style: AbyText.body.copyWith(color: c.inkMuted)),
                  ),
                for (final MapEntry(key: group, value: list) in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s2, AbySpace.s4, AbySpace.s1),
                    child: Text(group.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                  ),
                  for (final r in list)
                    ListTile(
                      dense: true,
                      leading: Icon(r.icon, color: c.inkMuted),
                      title: Text(r.title),
                      subtitle: r.subtitle == null ? null : Text(r.subtitle!),
                      onTap: r.actions.first.$2,
                      trailing: r.actions.length < 2
                          ? null
                          : Wrap(spacing: AbySpace.s1, children: [
                              for (final (label, run) in r.actions.skip(1)) TextButton(onPressed: run, child: Text(label)),
                            ]),
                    ),
                ],
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
