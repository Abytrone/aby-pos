import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/modules/products/widgets/product_row.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:aby_pos/app/ui/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'shows the gross margin percentage and value for the lowest-margin variant',
    (tester) async {
      final product = Product(
        id: 'p',
        categoryId: 'c',
        name: 'Coffee',
        variants: const [
          Variant(id: 'small', name: 'Small', price: 1000, manualCost: 600),
          Variant(id: 'large', name: 'Large', price: 5000, manualCost: 3500),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AbyTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ProductRow(
              product: product,
              category: null,
              photo: null,
              showCost: true,
              targetMargin: 35,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('30% margin · GH₵ 15.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
