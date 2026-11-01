import 'package:aby_pos/app/ui/query_field.dart';
import 'package:aby_pos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Widget _page(RxString query, {required bool shown}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: shown ? QueryField(query: query, hint: 'Search products') : const Text('Elsewhere')),
    );

void main() {
  testWidgets('leaving and coming back shows the search still in force, and the x clears it', (tester) async {
    // Lives on, like a section's controller.
    final query = ''.obs;
    await tester.pumpWidget(_page(query, shown: true));
    await tester.enterText(find.byType(TextField), 'waff');
    await tester.pump();
    expect(query.value, 'waff');

    await tester.pumpWidget(_page(query, shown: false));
    await tester.pumpWidget(_page(query, shown: true));
    expect(find.widgetWithText(TextField, 'waff'), findsOneWidget, reason: 'not an empty box over a filtered list');

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();
    expect(query.value, isEmpty);
    expect(find.widgetWithText(TextField, 'waff'), findsNothing);
    expect(find.byTooltip('Clear'), findsNothing);

    // Cleared from elsewhere: the box follows.
    query.value = 'milk';
    await tester.pump();
    expect(find.widgetWithText(TextField, 'milk'), findsOneWidget);
  });
}
