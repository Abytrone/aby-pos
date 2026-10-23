import 'package:aby_pos/app/app.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

Future<void> _settle(WidgetTester tester) async {
  // Let drift's real async work finish, then settle the frames.
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.widgetWithText(InkWell, digit).last);
    await tester.pump();
  }
  await _settle(tester);
}

/// Unmounts the app and disposes every service, so their timers and drift
/// streams stop before the test ends.
Future<void> _dispose(WidgetTester tester) async {
  // Close messages and let their animations finish frame by frame.
  Get.closeAllSnackbars();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpWidget(const SizedBox());
  await Get.deleteAll(force: true);
  await tester.pump(const Duration(seconds: 1));
}

Future<AppDatabase> _shopWithStaff(WidgetTester tester) async {
  final db = memoryDb();
  await tester.runAsync(() async {
    final r = await Repos.open(db);
    final kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
    await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
  });
  return db;
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('tablet: cashier sells, a void needs an owner, close day, owner sees the activity',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db));
    await _settle(tester);

    // Sign in as the cashier.
    expect(find.text("Who's on the till?"), findsOneWidget);
    await tester.tap(find.text('Ama'));
    await _settle(tester);
    await _typePin(tester, '0000');
    expect(find.text('Wrong PIN. Try again.'), findsOneWidget);
    await _typePin(tester, '5678');

    // The shell: a cashier sees Sell, Today and Settings, not Staff or Activity.
    expect(find.text('Scoops Tamale'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
    expect(find.text('Activity'), findsNothing);
    expect(find.text('Tap a product to add it.'), findsOneWidget);

    // Ring up a double cone with sprinkles and a waffle.
    await tester.tap(find.text('Vanilla cone'));
    await _settle(tester);
    await tester.tap(find.text('Double scoop'));
    await tester.tap(find.text('Sprinkles'));
    await _settle(tester);
    await tester.tap(find.text('Add GH₵ 25.00'));
    await _settle(tester);
    await tester.tap(find.text('Waffle'));
    await _settle(tester);

    await tester.tap(find.text('Pay GH₵ 37.00'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), '50');
    await _settle(tester);
    expect(find.text('GH₵ 13.00'), findsOneWidget);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    expect(find.text('Sale complete'), findsOneWidget);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    // Today, from the rail.
    await tester.tap(find.text('Today'));
    await _settle(tester);
    expect(find.text('#00001'), findsOneWidget);

    // A cashier cannot void: someone allowed must approve with their PIN.
    await tester.tap(find.text('Void'));
    await _settle(tester);
    await tester.tap(find.text('Void sale'));
    await _settle(tester);
    expect(find.text('Approval needed'), findsOneWidget);
    await _typePin(tester, '5678');
    expect(find.text("That PIN can't approve this."), findsOneWidget);
    await _typePin(tester, '1234');
    expect(find.text('Approval needed'), findsNothing);
    expect(find.text('Voided'), findsOneWidget);

    // Cashiers may close the day.
    await tester.tap(find.widgetWithText(FilledButton, 'Close day'));
    await _settle(tester);
    expect(find.text('Since the first sale'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '99');
    await _settle(tester);
    expect(find.text('Short by'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Close day'));
    await tester.tap(find.widgetWithText(FilledButton, 'Close day'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Close day').last);
    await _settle(tester);
    expect(find.text('Day closed'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    // Lock from the user menu, then the owner signs in.
    await tester.tap(find.text('Ama'));
    await _settle(tester);
    await tester.tap(find.text('Lock'));
    await _settle(tester);
    expect(find.text("Who's on the till?"), findsOneWidget);
    await tester.tap(find.text('Kofi'));
    await _settle(tester);
    await _typePin(tester, '1234');

    // The owner sees everything, including who voided and who approved.
    expect(find.text('Staff'), findsOneWidget);
    await tester.tap(find.text('Activity'));
    await _settle(tester);
    expect(find.text('Checked: the activity log has not been changed.'), findsOneWidget);
    expect(find.text('Sale voided'), findsOneWidget);
    expect(find.textContaining('approved by Kofi'), findsOneWidget);

    // Settings: the owner changes the auto-lock time.
    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.tap(find.text('Lock the till after'));
    await _settle(tester);
    await tester.tap(find.text('10 minutes'));
    await _settle(tester);
    expect(find.text('10 minutes'), findsOneWidget);

    // The Owner role opens read-only (regression: an Obx with nothing to watch).
    await tester.tap(find.text('Staff'));
    await _settle(tester);
    await tester.tap(find.text('Roles'));
    await _settle(tester);
    await tester.tap(find.textContaining('Everything'));
    await _settle(tester);
    expect(find.text('Owners can always do everything. This role cannot be changed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    // A custom role's switches still work.
    await tester.tap(find.text('New role'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Shift lead');
    await tester.tap(find.text('Void sales'));
    await _settle(tester);
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Shift lead'), findsOneWidget);
    expect(find.textContaining('Nobody  ·  2 permissions'), findsOneWidget);

    // A staff profile: open Ama, add her phone number.
    await tester.tap(find.text('People'));
    await _settle(tester);
    await tester.tap(find.text('Ama'));
    await _settle(tester);
    expect(find.text('Staff profile'), findsOneWidget);
    expect(find.text('PERFORMANCE'), findsOneWidget);
    await tester.tap(find.text('Edit details'));
    await _settle(tester);
    final form = find.byType(TextField);
    await tester.enterText(form.at(1), '0241234567');
    await tester.enterText(form.at(2), 'not-an-email');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text("That doesn't look like an email address."), findsOneWidget);
    await tester.enterText(form.at(2), '');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('024 123 4567'), findsOneWidget);
    await tester.pageBack();
    await _settle(tester);

    // My profile, from the user menu.
    await tester.tap(find.text('Kofi').first);
    await _settle(tester);
    await tester.tap(find.text('My profile'));
    await _settle(tester);
    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('Kofi'), findsWidgets);

    await _dispose(tester);
  });

  testWidgets('tablet: owner adds a product with a recipe, sells it, logs waste', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db));
    await _settle(tester);
    await tester.tap(find.text('Kofi'));
    await _settle(tester);
    await _typePin(tester, '1234');

    // Products: the list, then a new product.
    await tester.tap(find.text('Products'));
    await _settle(tester);
    expect(find.text('Vanilla cone'), findsOneWidget);
    await tester.tap(find.text('New product'));
    await _settle(tester);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Kids cone');
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '8');
    await tester.tap(find.text('Add stock item'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Stock item'));
    await _settle(tester);
    await tester.tap(find.text('Wafer cones').last);
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '1');
    await _settle(tester);
    expect(find.textContaining('90% margin'), findsOneWidget, reason: 'GH₵ 0.80 cone on a GH₵ 8.00 price');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Kids cone'), findsOneWidget);

    // The other tabs open cleanly.
    await tester.tap(find.text('Options'));
    await _settle(tester);
    expect(find.textContaining('Toppings'), findsWidgets);
    await tester.tap(find.text('Tax'));
    await _settle(tester);
    expect(find.text('Prices include tax'), findsOneWidget);
    await tester.tap(find.text('Products').first);
    await _settle(tester);

    // It is on the till straight away, with how many cones are left.
    await tester.tap(find.text('Sell'));
    await _settle(tester);
    expect(find.text('Kids cone'), findsOneWidget);
    expect(find.text('200 left'), findsOneWidget);
    await tester.tap(find.text('Kids cone'));
    await _settle(tester);
    await tester.tap(find.text('Pay GH₵ 8.00'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Cash given'), '10');
    await _settle(tester);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    await tester.tap(find.text('New sale'));
    await _settle(tester);
    expect(find.text('199 left'), findsOneWidget);

    // Stock: the cones item, then waste.
    await tester.tap(find.text('Stock'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search stock'), 'wafer');
    await _settle(tester);
    await tester.tap(find.text('Wafer cones'));
    await _settle(tester);
    expect(find.text('199 pcs'), findsWidgets);
    await tester.tap(find.text('Log waste'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'How much'), '4');
    await tester.tap(find.text('Dropped or damaged'));
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('195 pcs'), findsWidgets);
    expect(find.text('Waste: Dropped or damaged'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: owner adds a supplier, receives a delivery on credit, pays it, counts stock', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db));
    await _settle(tester);
    await tester.tap(find.text('Kofi'));
    await _settle(tester);
    await _typePin(tester, '1234');
    await tester.tap(find.text('Stock'));
    await _settle(tester);

    // A supplier.
    await tester.tap(find.text('Suppliers'));
    await _settle(tester);
    await tester.tap(find.text('New supplier'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Supplier name'), 'Tamale Wholesale');
    await tester.enterText(find.widgetWithText(TextField, 'Days to pay'), '14');
    await tester.tap(find.text('Save').last);
    await _settle(tester);
    expect(find.text('Tamale Wholesale'), findsOneWidget);
    expect(find.text('Nothing owed'), findsOneWidget);

    // A delivery: 100 cones for GH₵ 100, GH₵ 40 paid on the day.
    await tester.tap(find.text('Deliveries'));
    await _settle(tester);
    await tester.tap(find.text('Receive delivery'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String?>, 'Supplier'));
    await _settle(tester);
    await tester.tap(find.text('Tamale Wholesale').last);
    await _settle(tester);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Stock item'));
    await _settle(tester);
    await tester.tap(find.text('Wafer cones').last);
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'How much'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'Cost of these'), '100');
    await _settle(tester);
    expect(find.text('GH₵ 100.00'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, 'Paid now'), '40');
    await _settle(tester);
    await tester.tap(find.text('Save delivery'));
    await _settle(tester);
    expect(find.textContaining('GRN-0001'), findsWidgets);
    expect(find.text('GH₵ 60.00 owed'), findsOneWidget);

    // Paying it off from the supplier's page.
    await tester.tap(find.text('Suppliers'));
    await _settle(tester);
    expect(find.text('You owe GH₵ 60.00'), findsOneWidget);
    await tester.tap(find.text('Tamale Wholesale'));
    await _settle(tester);
    await tester.tap(find.text('Record a payment'));
    await _settle(tester);
    expect(find.widgetWithText(TextField, 'Amount paid'), findsOneWidget);
    await tester.tap(find.text('Record a payment').last);
    await _settle(tester);
    expect(find.text('Nothing owed'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);

    // A count: 10 cones short of the 300 the till expects.
    await tester.tap(find.text('Counts'));
    await _settle(tester);
    await tester.tap(find.text('Start a count'));
    await _settle(tester);
    await tester.tap(find.text('Open: show what the till expects'));
    await _settle(tester);
    expect(find.text('Stock count'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Search stock').last, 'wafer');
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Found'), '290');
    await tester.tap(find.byTooltip('Save'));
    await _settle(tester);
    expect(find.text('1 of 12 counted'), findsOneWidget);
    expect(find.textContaining('short so far'), findsOneWidget);
    await tester.tap(find.text('Post count'));
    await _settle(tester);
    await tester.tap(find.text('Post count').last);
    await _settle(tester);
    expect(find.text('Posted by Kofi'), findsOneWidget);

    await tester.tap(find.text('Items'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search stock'), 'wafer');
    await _settle(tester);
    expect(find.text('290 pcs'), findsWidgets);

    await _dispose(tester);
  });

  testWidgets('phone portrait, first run: name the shop, create the owner, start selling', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AbyApp(openDatabase: memoryDb));
    await _settle(tester);

    expect(find.text('Set up your shop'), findsOneWidget);
    expect(find.text('Restore from a backup'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Scoops Lamashegu');
    await tester.enterText(fields.at(1), 'Kofi');
    await tester.enterText(fields.at(2), '1234');
    await tester.enterText(fields.at(3), '1243');
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);
    expect(find.text("The PINs don't match."), findsOneWidget);

    await tester.enterText(fields.at(3), '1234');
    await tester.ensureVisible(find.text('Create owner and start'));
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);

    // Phones get a bottom bar instead of the rail.
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Waffle'));
    await _settle(tester);
    expect(find.text('Cart (1)'), findsOneWidget);
    expect(find.text('Pay GH₵ 12.00'), findsOneWidget);

    // Owners have more places than a phone bar fits: the rest are under More.
    await tester.tap(find.text('More'));
    await _settle(tester);
    await tester.tap(find.text('Settings'));
    await _settle(tester);
    expect(find.text('Scoops Lamashegu'), findsOneWidget);

    // What a restore does at the end: rebuild everything on a reopened
    // database (here a fresh one, so setup shows again).
    await AppRestarter.restart();
    await _settle(tester);
    expect(find.text('Set up your shop'), findsOneWidget);
    expect(find.text('Scoops Lamashegu'), findsNothing);

    await _dispose(tester);
  });
}
