import 'dart:async';
import 'dart:io';

import 'package:aby_pos/app/app.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/data/repositories/time_repository.dart';
import 'package:aby_pos/app/services/clock_service.dart';
import 'package:aby_pos/app/ui/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// A tap on a product with options opens the picker, the usual ones ticked;
/// Add puts it in as it stands.
Future<void> _addPlain(WidgetTester tester, String product) async {
  await tester.tap(find.text(product));
  await _settle(tester);
  await tester.tap(find.textContaining(RegExp(r'^Add GH₵')));
  await _settle(tester);
}

Future<void> _typePin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.widgetWithText(InkWell, digit).last);
    await tester.pump();
  }
  await _settle(tester);
}

/// Staff number, then PIN (sign-in, switching user, approvals).
Future<void> _signIn(WidgetTester tester, String number, String pin) async {
  await _typePin(tester, number);
  await _typePin(tester, pin);
}

/// The new owner's recovery code: Done waits until it is written down.
Future<void> _writeDownRecoveryCode(WidgetTester tester) async {
  expect(find.text('Your recovery code'), findsOneWidget);
  await tester.tap(find.text('Done'));
  await _settle(tester);
  expect(find.text('Your recovery code'), findsOneWidget, reason: 'not until it is written down');
  await tester.tap(find.text("I've written it down"));
  await tester.pump();
  await tester.tap(find.text('Done'));
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
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);

    // Sign in as the cashier: staff number, then PIN. No names are listed.
    expect(find.text("Who's on the till?"), findsOneWidget);
    expect(find.text('Ama'), findsNothing);
    expect(find.text('Kofi'), findsNothing);
    await _signIn(tester, '102', '0000');
    expect(find.text("That number and PIN don't match."), findsOneWidget);
    await _typePin(tester, '5678');

    // The shell: a cashier sees Sell, Today and Settings, not Staff or Activity.
    expect(find.text('Scoops Tamale'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
    expect(find.text('Activity'), findsNothing);
    expect(find.text('Tap a product, scan a barcode, or type to search.'), findsOneWidget);

    // Ring up a double cone with sprinkles and a waffle.
    await tester.tap(find.text('Vanilla cone'));
    await _settle(tester);
    await tester.tap(find.text('Double scoop'));
    await tester.tap(find.text('Sprinkles'));
    await _settle(tester);
    await tester.tap(find.text('Add GH₵ 25.00'));
    await _settle(tester);
    await _addPlain(tester, 'Waffle');

    await tester.tap(find.text('Pay GH₵ 37.00'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Cash given'), '50');
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
    await tester.tap(find.text('Wrong item rung up'));
    await _settle(tester);
    await tester.tap(find.text('Void sale'));
    await _settle(tester);
    expect(find.text('Approval needed'), findsOneWidget);
    await _signIn(tester, '102', '5678');
    expect(find.text("That number and PIN can't approve this."), findsOneWidget);
    await tester.tap(find.text('Staff no. 102 · Change'));
    await _settle(tester);
    await _signIn(tester, '101', '1234');
    expect(find.text('Approval needed'), findsNothing);
    expect(find.text('Voided'), findsOneWidget);

    // Cashiers may close the day.
    hideMessage(); // it covers the top right of the page
    await tester.pump();
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
    await _signIn(tester, '101', '1234');

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
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'lock');
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
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

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
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '4');
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
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');
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
    await tester.enterText(find.widgetWithText(TextField, 'Quantity'), '100');
    await tester.enterText(find.widgetWithText(TextField, 'Cost of this line'), '100');
    await _settle(tester);
    expect(find.text('GH₵ 100.00'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, 'Paid now'), '40');
    await _settle(tester);
    await tester.tap(find.text('Save delivery'));
    await _settle(tester);
    // What the delivery changed: the cones' stock before and after.
    expect(find.text('Delivery DEL-0001 received'), findsOneWidget);
    expect(find.text('Wafer cones'), findsWidgets);
    await tester.tap(find.text('Done').last);
    await _settle(tester);
    expect(find.textContaining('DEL-0001'), findsWidgets);
    expect(find.text('GH₵ 60.00 owed'), findsOneWidget);

    // Tapping the delivery opens it: its lines, what is owed, and its PDF.
    await tester.tap(find.text('GH₵ 60.00 owed'));
    await _settle(tester);
    expect(find.text('Save or print'), findsOneWidget);
    expect(find.text('Owed'), findsOneWidget);
    expect(find.text('pcs'), findsWidgets);

    // The delivery record updates its stock items: the cones take its price
    // as their cost, its supplier, and its quantity as their usual order.
    await tester.tap(find.text('Update stock items'));
    await _settle(tester);
    expect(find.text('Update stock items from DEL-0001'), findsOneWidget);
    expect(find.textContaining('Supplier none → Tamale Wholesale'), findsOneWidget);
    expect(find.textContaining('Usual order'), findsOneWidget);
    await tester.tap(find.text('Update 1 item'));
    await _settle(tester);
    expect(find.text('1 stock item updated.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await _settle(tester);
    // Used once: the delivery now says so, and the button rests.
    await tester.tap(find.text('GH₵ 60.00 owed'));
    await _settle(tester);
    expect(find.text('Stock items updated'), findsOneWidget);
    expect(find.text('Update stock items'), findsNothing);
    await tester.tap(find.text('Done').last);
    await _settle(tester);

    // The cones' history names the delivery, and opens it.
    await tester.tap(find.widgetWithText(Tab, 'Items'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search stock'), 'wafer');
    await _settle(tester);
    await tester.tap(find.text('Wafer cones'));
    await _settle(tester);
    expect(find.text('Received  ·  DEL-0001 from Tamale Wholesale'), findsOneWidget);
    await tester.tap(find.text('Received  ·  DEL-0001 from Tamale Wholesale'));
    await _settle(tester);
    expect(find.text('Save or print'), findsOneWidget);
    await tester.tap(find.text('Done').last);
    await _settle(tester);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);
    await tester.tap(find.byTooltip('Clear'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(Tab, 'Deliveries'));
    await _settle(tester);

    // Items not in stock yet come in with the delivery: "+ New stock items…"
    // at the top of a line's item list opens a table, saved to stock and
    // put on the delivery.
    await tester.tap(find.text('Receive delivery'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Stock item'));
    await _settle(tester);
    await tester.tap(find.text('+ New stock items…').last);
    await _settle(tester);
    Finder inDialog(String label) =>
        find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(TextField, label)).first;
    await tester.enterText(inDialog('Name'), 'Paper bags');
    await tester.enterText(inDialog('Quantity'), '50');
    await tester.enterText(inDialog('Cost per pcs'), '0.20');
    await _settle(tester);
    await tester.tap(find.text('Add 1 item'));
    await _settle(tester);
    expect(find.text('Paper bags'), findsWidgets);
    expect(find.widgetWithText(TextField, '10.00'), findsNWidgets(2), reason: '50 at GH₵ 0.20, and paid now follows the total');
    await tester.tap(find.text('Save delivery'));
    await _settle(tester);
    expect(find.text('Delivery DEL-0002 received'), findsOneWidget);
    await tester.tap(find.text('Done').last);
    await _settle(tester);

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
    expect(find.text('1 of 13 counted'), findsOneWidget);
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

  testWidgets('tablet: typed quantity, a line discount, park and resume, search and Enter', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '102', '5678');

    // "3" then a tap adds three.
    final search = find.widgetWithText(TextField, 'Search, scan, or type a code');
    await tester.enterText(search, '3');
    await _settle(tester);
    expect(find.text('Tap a product to add 3, or press Enter for code 3'), findsOneWidget);
    await _addPlain(tester, 'Waffle');
    expect(find.text('Pay GH₵ 36.00'), findsOneWidget);

    // 10% off the line is within a cashier's limit: no PIN needed.
    await tester.tap(find.text('GH₵ 12.00 each'));
    await _settle(tester);
    await tester.tap(find.text('Add a discount'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Percent off'), '10');
    await tester.tap(find.text('Regular customer'));
    await _settle(tester);
    expect(find.text('−GH₵ 3.60'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await _settle(tester);
    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(find.text('Pay GH₵ 32.40'), findsOneWidget);
    expect(find.text('10%: −GH₵ 3.60'), findsOneWidget);

    // Park it as Table 4; the cart empties and a tab appears.
    await tester.tap(find.text('Park'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Name or table'), 'Table 4');
    await tester.tap(find.widgetWithText(FilledButton, 'Park'));
    await _settle(tester);
    expect(find.text('Table 4  ·  GH₵ 32.40'), findsOneWidget);
    expect(find.text('Pay GH₵ 0.00'), findsOneWidget);

    // Typing on a keyboard goes into the search box (even when nothing has
    // focus); Enter adds the only match.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await _settle(tester);
    expect(find.widgetWithText(TextField, 'm'), findsOneWidget);
    // From here the box has focus and the platform types into it.
    await tester.enterText(search, 'milk');
    await _settle(tester);
    expect(find.text('Waffle'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);
    expect(find.text('Pay GH₵ 20.00'), findsOneWidget);

    // Back to Table 4: the milkshake is parked in its place.
    await tester.tap(find.text('Table 4  ·  GH₵ 32.40'));
    await _settle(tester);
    expect(find.text('Pay GH₵ 32.40'), findsOneWidget);
    expect(find.text('Table 4'), findsOneWidget, reason: 'the cart is titled with its name');
    expect(find.textContaining('GH₵ 20.00'), findsWidgets);

    await _dispose(tester);
  });

  testWidgets('tablet: split payment, then a refund approved by the owner', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '102', '5678');

    // Two waffles: GH₵ 10 by MTN MoMo, the rest in cash.
    final search = find.widgetWithText(TextField, 'Search, scan, or type a code');
    await tester.enterText(search, '2');
    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 24.00'));
    await _settle(tester);
    await tester.tap(find.text('MTN MoMo'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '10');
    await tester.enterText(find.widgetWithText(TextField, 'MTN MoMo transaction ID'), 'MP2410.55');
    await _settle(tester);
    await tester.tap(find.text('Take GH₵ 10.00, pay the rest another way'));
    await _settle(tester);
    expect(find.text('Left to pay'), findsOneWidget);
    await tester.tap(find.text('Cash'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Cash given'), '20');
    await _settle(tester);
    expect(find.text('GH₵ 6.00'), findsOneWidget, reason: 'change from 20 on the 14 left');
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    expect(find.text('Sale complete'), findsOneWidget);
    expect(find.textContaining('MTN MoMo GH₵ 10.00'), findsOneWidget);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    // Refund one waffle from Today: a cashier needs the owner's PIN.
    await tester.tap(find.text('Today'));
    await _settle(tester);
    await tester.tap(find.text('Refund'));
    await _settle(tester);
    expect(find.text('Refund #00001'), findsOneWidget);
    await tester.tap(find.byTooltip('One more'));
    await tester.tap(find.text('Wrong item'));
    await _settle(tester);
    await tester.scrollUntilVisible(find.text('Refund GH₵ 12.00'), 200,
        scrollable: find.ancestor(of: find.text('WHAT COMES BACK'), matching: find.byType(Scrollable)).first);
    await tester.tap(find.text('Refund GH₵ 12.00'));
    await _settle(tester);
    expect(find.text('Approval needed'), findsOneWidget);
    await _signIn(tester, '101', '1234');
    expect(find.text('Refund R-0001 saved'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(find.textContaining('Refunded GH₵ 12.00', findRichText: true), findsOneWidget);
    expect(find.textContaining('R-0001'), findsOneWidget);
    expect(find.text('Void'), findsNothing, reason: 'a refunded sale cannot be voided');

    // Tapping the sale opens it in full: what was bought, payments, refunds.
    await tester.tap(find.textContaining('Refunded GH₵ 12.00', findRichText: true));
    await _settle(tester);
    expect(find.text('WHAT WAS BOUGHT'), findsOneWidget);
    expect(find.text('GH₵ 12.00 refunded'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await _settle(tester);

    // A refund without a receipt opens too (its title is fixed text).
    await tester.tap(find.byTooltip('Cash'));
    await _settle(tester);
    await tester.tap(find.text('Refund without a receipt'));
    await _settle(tester);
    expect(find.text('Refund without a receipt'), findsOneWidget);
    expect(find.textContaining('a manager approves with their PIN'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await _settle(tester);

    await _dispose(tester);
  });

  testWidgets('tablet: a customer buys on credit, then pays it back', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    // A new customer from the till, with just a name and phone.
    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Add a customer'));
    await _settle(tester);
    await tester.tap(find.text('New customer'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Auntie Akos');
    await tester.enterText(find.widgetWithText(TextField, 'Phone'), '024 123 4567');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Auntie Akos'), findsOneWidget);

    // On credit.
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    await tester.tap(find.text('Credit (book)'));
    await _settle(tester);
    expect(find.text("Goes on Auntie Akos's account."), findsOneWidget);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    expect(find.text('Sale complete'), findsOneWidget);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    // Customers: she owes 12.00; she pays 5.00 in cash.
    await tester.tap(find.text('Customers'));
    await _settle(tester);
    expect(find.text('Customers owe GH₵ 12.00 in all.'), findsOneWidget);
    await tester.tap(find.text('Auntie Akos'));
    await _settle(tester);
    expect(find.text('GH₵ 12.00'), findsWidgets);
    await tester.tap(find.text('Record a payment'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount paid'), '5');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('GH₵ 7.00'), findsWidgets);
    expect(find.textContaining('Payment (Cash)'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: start the day, take cash out, close and balance', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Today'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Cash'));
    await _settle(tester);
    await tester.tap(find.text('Start the day').last);
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Float at the start'), '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Start the day'));
    await _settle(tester);
    // Starting the day does not clock anyone in: the owner is only asked.
    expect(find.text('Clock in too?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(find.textContaining('Day started by Kofi'), findsOneWidget);

    hideMessage(); // it covers the top right of the page
    await tester.pump();
    await tester.tap(find.byTooltip('Cash'));
    await _settle(tester);
    await tester.tap(find.text('Take cash out'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '10');
    await tester.tap(find.text('Ice').first); // the reason
    await tester.tap(find.text('Ice').last); // and it is an expense
    await tester.tap(find.text('Save'));
    await _settle(tester);

    hideMessage();
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Close day'));
    await _settle(tester);
    expect(find.textContaining('Day started by Kofi with a float of GH₵ 50.00'), findsOneWidget);
    expect(find.text('Cash taken out'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Cash counted now'), '40');
    await _settle(tester);
    expect(find.text('Drawer balances'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Close day'));
    await tester.tap(find.widgetWithText(FilledButton, 'Close day'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Close day').last);
    await _settle(tester);
    expect(find.text('Day closed'), findsOneWidget);
    // The owner's summary, ready to share.
    expect(find.text('Share the summary'), findsOneWidget);
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await _settle(tester);

    // The pay-out is on the expenses, once.
    await tester.tap(find.text('Money'));
    await _settle(tester);
    expect(find.text('Spent: GH₵ 10.00'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: the dashboard and every report open after a sale', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    await tester.tap(find.text('Exact'));
    await _settle(tester);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    await tester.tap(find.text('Dashboard'));
    await _settle(tester);
    expect(find.text('TOP PRODUCTS TODAY'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('NEEDS ATTENTION'), 200,
        scrollable: find.ancestor(of: find.text('TOP PRODUCTS TODAY'), matching: find.byType(Scrollable)).first);
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await _settle(tester);
    expect(find.text('GH₵ 12.00'), findsWidgets);
    for (final tab in ['Times', 'Products', 'Payments', 'Staff', 'Customers', 'Stock and tax']) {
      await tester.tap(find.widgetWithText(Tab, tab));
      await _settle(tester);
    }
    expect(find.text('Stock value at cost'.toUpperCase()), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: receipt buttons, the receipt designer and printer setup', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    await tester.tap(find.text('Exact'));
    await _settle(tester);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    expect(find.text('Send receipt'), findsOneWidget);
    await tester.tap(find.text('Print receipt'));
    await _settle(tester);
    expect(find.textContaining('No receipt printer on this device'), findsOneWidget);
    // No printer: it offers to send the receipt instead (WhatsApp, SMS, PDF).
    expect(find.text('WhatsApp'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    // Let the message go: it covers the buttons.
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'receipt');
    await _settle(tester);
    await tester.tap(find.text('Receipt design'));
    await _settle(tester);
    expect(find.textContaining('Receipt #00142'), findsOneWidget, reason: 'the live preview');
    await tester.enterText(find.widgetWithText(TextField, 'Footer'), 'Akwaaba to Scoops!');
    await _settle(tester);
    expect(find.textContaining('Akwaaba to Scoops!'), findsNWidgets(2), reason: 'the field and the preview');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Receipt design'), findsOneWidget);

    await tester.tap(find.text('Receipt printer'));
    await _settle(tester);
    expect(find.text('Print a test page'), findsOneWidget);
    // The kind picker only shows where there's more than network (Windows, Android).
    if (find.text('Network').evaluate().isNotEmpty) {
      await tester.tap(find.text('Network'));
      await _settle(tester);
    }
    await tester.enterText(find.widgetWithText(TextField, "Printer's IP address"), '192.168.1.50');
    await tester.tap(find.text('58 mm'));
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('192.168.1.50'), findsOneWidget);
    expect(find.text('Print every receipt'), findsOneWidget);
    expect(find.byTooltip('Reprint the last receipt'), findsOneWidget);

    // This device's other hardware: the scale (COM ports on Windows) and
    // which notifications this person gets.
    if (Platform.isWindows) {
      await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'scale');
      await _settle(tester);
      await tester.tap(find.text('Scale'));
      await _settle(tester);
      expect(find.text('Read the scale'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await _settle(tester);
    }
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'notifications');
    await _settle(tester);
    await tester.tap(find.text('Which notifications'));
    await _settle(tester);
    await tester.tap(find.text('Low stock'));
    await _settle(tester);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Low stock')).value, isFalse);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    await _dispose(tester);
  });

  testWidgets('tablet: the owner adds a promotion and the till applies it', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'promotion');
    await _settle(tester);
    await tester.tap(find.text('Promotions'));
    await _settle(tester);
    expect(find.text('No promotions yet.'), findsOneWidget);
    await tester.tap(find.text('New promotion'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Half price');
    await tester.enterText(find.widgetWithText(TextField, 'Percent off'), '50');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Half price'), findsOneWidget);
    expect(find.textContaining('On now'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    await tester.tap(find.text('Sell'));
    await _settle(tester);
    await _addPlain(tester, 'Waffle');
    expect(find.text('Half price: −GH₵ 6.00'), findsOneWidget);
    expect(find.text('Pay GH₵ 6.00'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: loyalty stamps on, and a gift voucher sold from Customers', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'loyalty');
    await _settle(tester);
    await tester.tap(find.text('Loyalty'));
    await _settle(tester);
    await tester.tap(find.text('Stamps'));
    await _settle(tester);
    expect(find.text('Stamps for a free item'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Stamps'), findsOneWidget, reason: 'the setting shows the style');

    await tester.tap(find.text('Customers'));
    await _settle(tester);
    await tester.tap(find.text('Gift vouchers'));
    await _settle(tester);
    expect(find.text('No gift vouchers yet.'), findsOneWidget);
    await tester.tap(find.text('Sell a gift voucher'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Value'), '50');
    await tester.tap(find.text('Sell voucher'));
    await _settle(tester);
    expect(find.textContaining(RegExp(r'^SCO-')), findsWidgets, reason: 'on the card and in the list behind');
    expect(find.text('GH₵ 50.00 left of GH₵ 50.00'), findsOneWidget);
    await tester.tap(find.text('Done').last);
    await _settle(tester);
    expect(find.textContaining('Sold for GH₵ 50.00'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: order numbers on, a waffle gets A1, and the Orders board moves it', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'order numbers');
    await _settle(tester);
    await tester.tap(find.byType(Switch).first);
    await _settle(tester);
    expect(find.text('Orders'), findsOneWidget, reason: 'the Orders section appears');

    await tester.tap(find.text('Sell'));
    await _settle(tester);
    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    await tester.tap(find.text('Exact'));
    await _settle(tester);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    expect(find.text('ORDER NUMBER'), findsOneWidget);
    expect(find.text('A1'), findsOneWidget);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    await tester.tap(find.text('Orders'));
    await _settle(tester);
    expect(find.text('A1'), findsOneWidget);
    await tester.tap(find.text('Move to Preparing'));
    await _settle(tester);
    expect(find.text('PREPARING  1'), findsOneWidget);
    await tester.tap(find.text('Move to Ready'));
    await _settle(tester);
    await tester.tap(find.text('Collected'));
    await _settle(tester);
    expect(find.textContaining('No open orders'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('tablet: purchase orders, expiring stock, and an item made here', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Stock'));
    await _settle(tester);
    await tester.tap(find.text('Expiring'));
    await _settle(tester);
    expect(find.textContaining('Nothing in stock expires'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(Tab, 'Orders'));
    await _settle(tester);
    expect(find.text('No purchase orders yet.'), findsOneWidget);
    await tester.tap(find.text('New order'));
    await _settle(tester);
    await tester.tap(find.text('Create order'));
    await _settle(tester);
    expect(find.text('Choose the supplier.'), findsOneWidget);
    // New stock items can go on an order too, from a line's item list.
    await tester.tap(find.text('Add item'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Stock item'));
    await _settle(tester);
    await tester.tap(find.text('+ New stock items…').last);
    await _settle(tester);
    expect(find.text('New stock items'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await _settle(tester);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(Tab, 'Items'));
    await _settle(tester);
    await tester.tap(find.text('Milk'));
    await _settle(tester);
    expect(find.text('BATCHES IN STOCK'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Made here? Set its recipe'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Made here? Set its recipe'));
    await _settle(tester);
    expect(find.text('What Milk is made from'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    await _dispose(tester);
  });

  testWidgets('tablet: clock in before selling, then the timesheet', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Search settings'), 'clock in');
    await _settle(tester);
    await tester.tap(find.byType(Switch).first);
    await _settle(tester);

    await tester.tap(find.text('Sell'));
    await _settle(tester);
    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    expect(find.text('Clock in to sell'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Clock in'));
    await _settle(tester);
    expect(find.text('Exact'), findsOneWidget, reason: 'on to checkout');
    await tester.tap(find.text('Exact'));
    await _settle(tester);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    await tester.tap(find.byTooltip('Signed in'));
    await _settle(tester);
    expect(find.text('Clock out'), findsOneWidget);
    expect(find.text('Start a break'), findsOneWidget);
    await tester.tapAt(const Offset(10, 790));
    await _settle(tester);

    await tester.tap(find.text('Staff'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(Tab, 'Timesheets'));
    await _settle(tester);
    expect(find.text('HOURS WORKED'), findsNothing);
    expect(find.text('Hours worked'), findsOneWidget);
    expect(find.textContaining('still in'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('hours left open at close wait in Staff, Timesheets for an owner, who decides with a reason', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    late TimeRepository times;
    await tester.runAsync(() async {
      final r = await Repos.open(db);
      times = TimeRepository(db, r.device, audit: r.audit);
      final ama = (await r.staff.list()).firstWhere((s) => s.name == 'Ama');
      final kofi = (await r.staff.list()).firstWhere((s) => s.name == 'Kofi');
      await times.clockIn(ama);
      await times.leaveOpenAtClose(by: kofi);
    });
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Staff'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(Tab, 'Timesheets'));
    await _settle(tester);
    expect(find.text('WAITING FOR YOUR DECISION'), findsOneWidget);
    expect(find.text('Not paid yet'), findsWidgets);

    await tester.tap(find.textContaining('Ama').first);
    await _settle(tester);
    expect(find.text('Review hours: Ama'), findsOneWidget);
    await tester.tap(find.text('Do not pay'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);
    expect(find.text('Review hours: Ama'), findsOneWidget, reason: 'a reason is needed');
    await tester.enterText(find.widgetWithText(TextField, 'Reason (kept in the activity log)'), 'Left without telling anyone');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);

    expect(find.text('WAITING FOR YOUR DECISION'), findsNothing);
    expect(find.textContaining('Left without telling anyone'), findsOneWidget);

    await _dispose(tester);
  });

  testWidgets('Today: Close day is off until something has happened since the last close', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Today'));
    await _settle(tester);
    FilledButton closeButton() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Close day'));
    expect(closeButton().onPressed, isNull, reason: 'a fresh till has nothing to close');

    // A started day is something to close.
    await tester.tap(find.byTooltip('Cash'));
    await _settle(tester);
    await tester.tap(find.text('Start the day').last);
    await _settle(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Float at the start'), '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Start the day'));
    await _settle(tester);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(closeButton().onPressed, isNotNull);

    await _dispose(tester);
  });

  testWidgets('tablet: Ctrl+K finds a product and adds it to the cart', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '101', '1234');

    await tester.tap(find.text('Settings'));
    await _settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(tester);
    expect(find.text('GO TO'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'waff');
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.text('PRODUCTS'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Waffle'));
    await _settle(tester);
    // Its toppings are offered first.
    await tester.tap(find.text('Add GH₵ 12.00'));
    await _settle(tester);
    expect(find.text('Pay GH₵ 12.00'), findsOneWidget, reason: 'on the Sell screen, in the cart');

    await tester.tap(find.byTooltip('Search everything (Ctrl+K)'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'close day');
    await tester.pump(const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.widgetWithText(ListTile, 'Close day'), findsOneWidget);
    await tester.tapAt(const Offset(5, 795));
    await _settle(tester);

    await _dispose(tester);
  });

  testWidgets('tablet, first run as a chop bar: its categories, order numbers on, nothing else', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AbyApp(openDatabase: () => memoryDb(seed: false), requireLicense: false));
    await _settle(tester);
    expect(find.text('What kind of shop?'), findsOneWidget);
    await tester.tap(find.text('Chop bar / restaurant'));
    await _settle(tester);
    final fields = find.byType(TextField);
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, isEmpty, reason: 'not the fallback name');
    await tester.enterText(fields.at(0), 'Auntie Mercy Chop Bar');
    await tester.enterText(fields.at(1), 'Mercy');
    await tester.enterText(fields.at(2), '2468');
    await tester.enterText(fields.at(3), '2468');
    await tester.ensureVisible(find.text('Create owner and start'));
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);
    await _writeDownRecoveryCode(tester);

    expect(find.text('Food'), findsWidgets);
    expect(find.text('Vanilla cone'), findsNothing);
    expect(find.text('Orders'), findsOneWidget, reason: 'kitchen tickets and the Orders board are on');

    await _dispose(tester);
  });

  testWidgets('the shop wants the day started and people clocked in: Pay asks for both, and for the end of a break',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = await _shopWithStaff(tester);
    await tester.runAsync(() async {
      final r = await Repos.open(db);
      final kofi = (await r.staff.list()).firstWhere((s) => s.name == 'Kofi');
      final settings = SettingsRepository(db, r.device, r.audit);
      await settings.write(AppSettings.startDayToSell, true, by: kofi);
      await settings.write(AppSettings.clockInToSell, true, by: kofi);
    });
    await tester.pumpWidget(AbyApp(openDatabase: () => db, requireLicense: false));
    await _settle(tester);
    await _signIn(tester, '102', '5678');

    // Asked to clock in on signing in; not now.
    expect(find.text('Clock in to sell'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);

    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    // First the float, then the opener is asked whether to clock in.
    expect(find.text('Start the day'), findsWidgets);
    await tester.enterText(find.widgetWithText(TextField, 'Float at the start'), '50');
    await tester.tap(find.widgetWithText(FilledButton, 'Start the day'));
    await _settle(tester);
    expect(find.text('Clock in too?'), findsOneWidget);
    await tester.tap(find.text('Clock in'));
    await _settle(tester);
    expect(find.text('Clock in to sell'), findsNothing, reason: 'the opener already clocked in');
    await tester.enterText(find.widgetWithText(TextField, 'Cash given'), '12');
    await _settle(tester);
    await tester.tap(find.text('Complete sale'));
    await _settle(tester);
    await tester.tap(find.text('New sale'));
    await _settle(tester);

    // On a break: Pay asks to end it. The day is started, so no float again.
    unawaited(Get.find<ClockService>().toggleBreak());
    await _settle(tester);
    await _addPlain(tester, 'Waffle');
    await tester.tap(find.text('Pay GH₵ 12.00'));
    await _settle(tester);
    expect(find.text('Float at the start'), findsNothing);
    expect(find.text("You're on a break"), findsOneWidget);
    await tester.tap(find.text('End the break'));
    await _settle(tester);
    expect(find.widgetWithText(TextField, 'Cash given'), findsOneWidget);
    expect(Get.find<ClockService>().state.value?.onBreak, isFalse);

    await _dispose(tester);
  });

  testWidgets('phone portrait, first run: name the shop, create the owner, start selling', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AbyApp(openDatabase: memoryDb, requireLicense: false));
    await _settle(tester);

    expect(find.text('Set up your shop'), findsOneWidget);
    expect(find.text('Restore from a backup'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Scoops Lamashegu');
    await tester.enterText(fields.at(1), 'Kofi');
    await tester.enterText(fields.at(2), '1234');
    await tester.enterText(fields.at(3), '1243');
    await tester.ensureVisible(find.text('Create owner and start'));
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);
    expect(find.text("The PINs don't match."), findsOneWidget);

    await tester.enterText(fields.at(3), '1234');
    await tester.ensureVisible(find.text('Create owner and start'));
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);
    await _writeDownRecoveryCode(tester);

    // New shops ask people to clock in before selling, starting now.
    expect(find.text('Clock in to sell'), findsOneWidget);
    await tester.tap(find.text('Clock in').last);
    await _settle(tester);
    expect(find.text('Clock in to sell'), findsNothing);

    // Phones get a bottom bar instead of the rail.
    expect(find.byType(NavigationBar), findsOneWidget);
    // Phones show the list view; Waffle is further down it.
    await tester.scrollUntilVisible(find.text('Waffle'), 200,
        scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
    await _addPlain(tester, 'Waffle');
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
