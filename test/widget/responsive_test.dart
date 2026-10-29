import 'dart:io';

import 'package:aby_pos/app/app.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/modules/shell/controllers/shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

/// The real fonts: the test font's square glyphs are wider than Figtree's,
/// so text would overflow here that fits on a device.
Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
    }
    await loader.load();
  }

  await load('Figtree', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black']) 'fonts/Figtree-$w.ttf',
  ]);
  await load('JetBrains Mono', ['fonts/JetBrainsMono-Regular.ttf', 'fonts/JetBrainsMono-Bold.ttf']);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 300));
  }
}

const _sizes = {
  'small phone': Size(320, 640),
  'phone': Size(360, 780),
  'tablet portrait': Size(768, 1024),
};

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  setUpAll(_loadFonts);

  for (final MapEntry(key: name, value: size) in _sizes.entries) {
    testWidgets('$name: every section, tab and main page lays out without overflowing', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      // Collect layout errors with where they happened, rather than stopping
      // at the first.
      final problems = <String>[];
      var where = 'sign-in';
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        final text = d.toString();
        final widget = RegExp(r'relevant error-causing widget was:\s*\n\s*(.+?)\n\s*(\S+)').firstMatch(text);
        problems.add('[$where] ${d.exceptionAsString().split('\n').first}'
            '${widget == null ? '' : '  ${widget.group(1)} ${widget.group(2)}'}');
      };

      final db = memoryDb();
      await tester.runAsync(() async {
        final r = await Repos.open(db);
        await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      });
      await tester.pumpWidget(AbyApp(openDatabase: () => db));
      await _settle(tester);
      await tester.tap(find.text('Kofi'));
      await _settle(tester);
      for (final digit in '1234'.split('')) {
        await tester.tap(find.widgetWithText(InkWell, digit).last);
        await tester.pump();
      }
      await _settle(tester);

      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f.first);
        await _settle(tester);
        await tester.tap(f.first);
        await _settle(tester);
      }

      final shell = Get.find<ShellController>();
      for (final s in shell.sections) {
        where = s.name;
        shell.select(s);
        await _settle(tester);
        final tabs = find.byType(Tab).evaluate().length;
        for (var i = 1; i < tabs; i++) {
          where = '${s.name} tab $i';
          await tap(find.byType(Tab).at(i));
        }
        if (tabs > 1) await tap(find.byType(Tab).first);
      }

      Future<void> page(String name, ShellSection? section, Future<void> Function() open) async {
        where = name;
        if (section != null) {
          shell.select(section);
          await _settle(tester);
        }
        await open();
        final nav = Get.key.currentState!;
        if (nav.canPop()) nav.pop();
        await _settle(tester);
      }

      await page('variants', ShellSection.sell, () => tap(find.text('Vanilla cone')));
      await page('checkout', ShellSection.sell, () async {
        // On a small phone the list view shows the first few products.
        await tester.scrollUntilVisible(find.text('Ice cream tub'), 200,
            scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first);
        await tap(find.text('Ice cream tub'));
        await tap(find.textContaining('Pay GH'));
      });
      await page('product editor', ShellSection.products, () => tap(find.text('Vanilla cone')));
      await page('stock item', ShellSection.stock, () => tap(find.textContaining('Chocolate ice')));
      await page('receive', ShellSection.stock, () async {
        await tap(find.text('Deliveries'));
        await tap(find.text('Receive delivery'));
      });
      await page('new customer', ShellSection.customers, () => tap(find.text('New customer')));
      await page('add expense', ShellSection.money, () => tap(find.text('Add an expense')));
      await page('close day', ShellSection.today, () => tap(find.text('Close day')));
      await page('staff profile', ShellSection.staff, () => tap(find.textContaining('Kofi')));
      await page('status centre', null, () => tap(find.byType(Tooltip).at(1)));

      FlutterError.onError = original;
      expect(problems, isEmpty);

      Get.closeAllSnackbars();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpWidget(const SizedBox());
      await Get.deleteAll(force: true);
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
