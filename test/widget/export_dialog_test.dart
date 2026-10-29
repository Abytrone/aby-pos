import 'package:aby_pos/app/domain/documents/table_doc.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:aby_pos/app/ui/export_dialog.dart';
import 'package:aby_pos/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

TableDoc doc(int sheets) => TableDoc(
      title: 'Products report',
      shopName: 'S',
      sheets: [
        for (var i = 0; i < sheets; i++) DocSheet(name: 'Sheet $i', columns: const [DocColumn('Name')], rows: const [['Waffle']]),
      ],
    );

void main() {
  Future<void> open(WidgetTester tester) => tester.pumpWidget(GetMaterialApp(
        theme: AbyTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(),
      ));

  testWidgets('export offers Excel, PDF and CSV in one dialog; cancel sends nothing', (tester) async {
    await open(tester);
    final result = exportDocument(doc(1), fileStem: 'products');
    await tester.pumpAndSettle();
    expect(find.text('Export Products report'), findsOneWidget);
    expect(find.text('Excel workbook'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Save to a folder'), findsOneWidget);
    await tester.tap(find.text('PDF'));
    await tester.pump();
    // The tick moves to the PDF card.
    final pdfCard = find.ancestor(of: find.text('PDF'), matching: find.byType(InkWell)).first;
    expect(find.descendant(of: pdfCard, matching: find.byIcon(Icons.check_circle)), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('several tables: no CSV unless one is given; import files say so', (tester) async {
    await open(tester);
    var result = exportDocument(doc(2), fileStem: 'report');
    await tester.pumpAndSettle();
    expect(find.text('CSV'), findsNothing);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await result;

    result = exportDocument(doc(2), fileStem: 'stock', csv: 'a,b\r\n', csvImports: true);
    await tester.pumpAndSettle();
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('Plain data. Edit it and import it back into Aby.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });
}
