import 'package:aby_pos/app/bindings/initial_binding.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/models/enums.dart';
import 'package:aby_pos/app/routes/app_pages.dart';
import 'package:aby_pos/app/services/device_service.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

Widget _app(AppDatabase db) => GetMaterialApp(
      theme: AbyTheme.light,
      initialBinding: InitialBinding(database: db),
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );

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

/// Unmounts the app so controllers cancel their drift streams before the
/// test ends.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('tablet: sign in, ring up, pay cash, see it in Today, close day', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final db = memoryDb();
    await tester.runAsync(() async {
      final deviceId = (await db.readMeta(MetaKeys.deviceId))!;
      final staff = StaffRepository(db, FakeDevice(deviceId));
      await staff.create(name: 'Kofi', role: StaffRole.owner, pin: '1234');
      await staff.create(name: 'Ama', role: StaffRole.cashier, pin: '5678');
    });

    await tester.pumpWidget(_app(db));
    await _settle(tester);

    expect(find.text("Who's on the till?"), findsOneWidget);
    await tester.tap(find.text('Ama'));
    await _settle(tester);
    await _typePin(tester, '0000');
    expect(find.text('Wrong PIN. Try again.'), findsOneWidget);
    await _typePin(tester, '5678');

    expect(find.text('Scoops Tamale'), findsOneWidget);
    expect(find.text('Tap a product to add it.'), findsOneWidget);

    // A product with sizes opens the picker.
    await tester.tap(find.text('Vanilla cone'));
    await _settle(tester);
    await tester.tap(find.text('Double scoop'));
    await tester.tap(find.text('Sprinkles'));
    await _settle(tester);
    await tester.tap(find.text('Add GH₵ 25.00'));
    await _settle(tester);

    // One tap adds a product without sizes.
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
    expect(find.textContaining('#00001'), findsOneWidget);

    await tester.tap(find.text('New sale'));
    await _settle(tester);
    expect(find.text('1 sale saved on this device'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await _settle(tester);
    expect(find.text('#00001'), findsOneWidget);
    expect(find.text('Ama'), findsOneWidget, reason: 'the sale shows who rang it up');
    expect(find.text('Staff'), findsNothing, reason: 'owner only');

    // A cashier's void needs an owner's PIN.
    await tester.tap(find.text('Void'));
    await _settle(tester);
    await tester.tap(find.text('Void sale'));
    await _settle(tester);
    expect(find.text('Owner approval'), findsOneWidget);
    await _typePin(tester, '5678');
    expect(find.text('That is not an owner PIN.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(find.text('Void'), findsOneWidget, reason: 'still not voided');

    await tester.tap(find.text('Close day'));
    await _settle(tester);
    expect(find.text('Since the first sale'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '130');
    await _settle(tester);
    expect(find.text('Short by'), findsOneWidget);
    expect(find.text('GH₵ 7.00'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Close day'));
    await tester.tap(find.widgetWithText(FilledButton, 'Close day'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Close day').last);
    await _settle(tester);
    expect(find.text('Day closed'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await _settle(tester);
    expect(find.text('Closed'), findsOneWidget, reason: 'sales in a closed day are locked');

    await _dispose(tester);
  });

  testWidgets('phone portrait, first run: create the owner and start selling', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(memoryDb()));
    await _settle(tester);

    expect(find.text('Set up Scoops Tamale'), findsOneWidget);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Kofi');
    await tester.enterText(fields.at(1), '1234');
    await tester.enterText(fields.at(2), '1243');
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);
    expect(find.text("The PINs don't match."), findsOneWidget);

    await tester.enterText(fields.at(2), '1234');
    await tester.tap(find.text('Create owner and start'));
    await _settle(tester);

    expect(Get.find<DeviceService>().shopName, 'Scoops Tamale');
    await tester.tap(find.text('Waffle'));
    await _settle(tester);
    expect(find.text('Cart (1)'), findsOneWidget);
    expect(find.text('Pay GH₵ 12.00'), findsOneWidget);

    await _dispose(tester);
  });
}
