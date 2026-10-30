import 'package:aby_pos/app/ui/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('goBack closes the dialog even while a message is up', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    showMessage('Saved');
    await tester.pump(const Duration(milliseconds: 500));
    final result = Get.dialog<String>(
      AlertDialog(actions: [TextButton(onPressed: () => goBack(result: 'done'), child: const Text('Done'))]),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AlertDialog), findsNothing);
    expect(await result, 'done');
    expect(find.text('Saved'), findsOneWidget, reason: 'the message stays until it times out');

    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('messages show across the top on phones and top right on wider screens', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    var text = 'Saved';
    showMessage(text, tone: MessageTone.success);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    var box = tester.getRect(find.ancestor(of: find.text(text), matching: find.byType(Material)).first);
    expect(box.top, lessThan(40));
    expect(box.left, 12);
    expect(box.right, 388);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Saved'), findsNothing, reason: 'it closes by itself');

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    text = 'Printer not found';
    showMessage(text, tone: MessageTone.error);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    box = tester.getRect(find.ancestor(of: find.text(text), matching: find.byType(Material)).first);
    expect(box.top, 80, reason: 'just below the shell header');
    expect(box.right, 1280 - 16);
    expect(box.width, 400);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Printer not found'), findsNothing);
  });

  testWidgets('dialog buttons sit side by side: one row when they fit, two to a row when not', (tester) async {
    Offset at(String label) => tester.getTopLeft(find.byKey(ValueKey(label)));

    await tester.pumpWidget(_buttons(500));
    expect(at('Send').dy, at('Done').dy, reason: 'one row');
    expect(at('Send').dx < at('Print receipt').dx && at('Print receipt').dx < at('Done').dx, isTrue);

    // A phone: never one on top of the other. Two side by side, the main
    // button across the bottom.
    await tester.pumpWidget(_buttons(300));
    expect(at('Send').dy, at('Print receipt').dy);
    expect(at('Print receipt').dx, greaterThan(at('Send').dx));
    expect(at('Done').dy, greaterThan(at('Send').dy));
    expect(tester.getSize(find.byKey(const ValueKey('Done'))).width, 300);
  });
}

Widget _buttons(double width) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: DialogButtons(children: [
              for (final label in ['Send', 'Print receipt', 'Done'])
                SizedBox(key: ValueKey(label), width: 120, height: 56, child: Text(label)),
            ]),
          ),
        ),
      ),
    );
