import 'package:aby_pos/app/models/audit.dart';
import 'package:aby_pos/app/modules/activity/widgets/activity_row.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:aby_pos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      theme: AbyTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

AuditEntry _entry(AuditAction action, Map<String, dynamic>? details) => AuditEntry(
      id: 'a',
      seq: 42,
      at: DateTime(2026, 10, 29, 9, 30),
      deviceId: 'd',
      action: action,
      summary: '2 prices: +GH₵ 1.00',
      actorName: 'Ama',
      details: details,
    );

void main() {
  testWidgets('an old bulk price entry opens to the products and their prices', (tester) async {
    await tester.pumpWidget(_host(ActivityRow(
      entry: _entry(AuditAction.pricesBulkChanged, {
        'v1': {'before': 1200, 'after': 1300},
        'v2': {'before': 1500, 'after': 1400},
      }),
      names: const {'v1': 'Waffle'},
    )));
    await tester.tap(find.text('2 prices: +GH₵ 1.00'));
    await tester.pumpAndSettle();
    expect(find.text('Waffle'), findsOneWidget);
    expect(find.text('A product no longer on file'), findsOneWidget);
    expect(find.text('1 up'), findsOneWidget);
    expect(find.text('1 down'), findsOneWidget);
    expect(find.textContaining('GH₵ 13.00'), findsOneWidget);
    expect(find.text("Entry 42 in this device's log"), findsOneWidget);
  });

  testWidgets('entries with nothing to show have no arrow', (tester) async {
    await tester.pumpWidget(_host(ActivityRow(entry: _entry(AuditAction.backupCreated, null))));
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('a setting reads in Settings words, never its key or JSON', (tester) async {
    AuditEntry setting(String key, Object before, Object after) => AuditEntry(
          id: 'a',
          seq: 7,
          at: DateTime(2026, 10, 29, 9, 30),
          deviceId: 'd',
          action: AuditAction.settingChanged,
          summary: 'Changed $key',
          entityId: key,
          details: {'before': before, 'after': after},
        );

    await tester.pumpWidget(_host(ActivityRow(entry: setting('stock.allowNegative', true, false))));
    expect(find.text('Sell when out of stock: On to Off'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing, reason: 'the line says it all');

    await tester.pumpWidget(_host(ActivityRow(
      entry: setting('loyalty.stampTarget', '{}', '{"products":["p1","p2"],"categories":["c1"]}'),
      names: const {'p1': 'Vanilla cone', 'p2': 'Chocolate cone', 'c1': 'Waffles'},
    )));
    expect(find.textContaining('loyalty.'), findsNothing);
    await tester.tap(find.text('Changed Items that earn stamps (and the free one)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Waffles, Vanilla cone, Chocolate cone'), findsOneWidget);
    expect(find.textContaining('{'), findsNothing);
  });
}
