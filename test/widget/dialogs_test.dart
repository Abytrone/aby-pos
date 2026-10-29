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
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(AlertDialog), findsNothing);
    expect(await result, 'done');
    expect(find.text('Saved'), findsOneWidget, reason: 'the message stays until it times out');

    await tester.pumpAndSettle(const Duration(seconds: 4));
  });
}
