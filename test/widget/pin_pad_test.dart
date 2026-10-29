import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:aby_pos/app/ui/l10n.dart';
import 'package:aby_pos/app/ui/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<String>> pad(WidgetTester tester, PinPadMode mode) async {
    final tried = <String>[];
    await tester.pumpWidget(MaterialApp(
      theme: AbyTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: PinPad(
            mode: mode,
            onSubmit: (pin) async {
              tried.add(pin);
              return 'Wrong PIN';
            },
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return tried;
  }

  Future<void> tapKeys(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.widgetWithText(InkWell, d));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('the keypad takes a PIN by tapping', (tester) async {
    final tried = await pad(tester, PinPadMode.standard);
    await tapKeys(tester, '1234');
    expect(tried, ['1234']);
    expect(find.text('Wrong PIN'), findsOneWidget);
  });

  testWidgets('typing on a keyboard folds the keypad away', (tester) async {
    final tried = await pad(tester, PinPadMode.standard);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InkWell, '5'), findsNothing, reason: 'no keys left to watch');
    expect(find.text('Show the keypad'), findsOneWidget);
    // The number pad, Backspace to fix a digit.
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad9);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    for (final k in [LogicalKeyboardKey.numpad3, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit1]) {
      await tester.sendKeyEvent(k);
    }
    await tester.pumpAndSettle();
    expect(tried, ['4321']);

    await tester.tap(find.text('Show the keypad'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InkWell, '5'), findsOneWidget);
  });

  testWidgets('Esc starts the PIN again', (tester) async {
    final tried = await pad(tester, PinPadMode.standard);
    for (final k in [LogicalKeyboardKey.digit9, LogicalKeyboardKey.digit9, LogicalKeyboardKey.escape]) {
      await tester.sendKeyEvent(k);
    }
    for (final k in [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4]) {
      await tester.sendKeyEvent(k);
    }
    await tester.pumpAndSettle();
    expect(tried, ['1234']);
  });

  testWidgets('the shuffled keypad has every digit once, and still works', (tester) async {
    final tried = await pad(tester, PinPadMode.shuffled);
    for (var d = 0; d <= 9; d++) {
      expect(find.widgetWithText(InkWell, '$d'), findsOneWidget);
    }
    await tapKeys(tester, '2580');
    expect(tried, ['2580']);
    // Every digit is still there after it moves them.
    for (var d = 0; d <= 9; d++) {
      expect(find.widgetWithText(InkWell, '$d'), findsOneWidget);
    }
  });

  testWidgets('keyboard only shows no keypad and takes typed digits', (tester) async {
    final tried = await pad(tester, PinPadMode.keyboard);
    expect(find.widgetWithText(InkWell, '1'), findsNothing);
    expect(find.text('Type your PIN on the keyboard'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '7531');
    await tester.pumpAndSettle();
    expect(tried, ['7531']);
  });
}
