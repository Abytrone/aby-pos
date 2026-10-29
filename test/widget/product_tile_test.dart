import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/modules/till/widgets/product_tile.dart';
import 'package:aby_pos/app/theme/aby_theme.dart';
import 'package:aby_pos/app/ui/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Product _product(String name, List<String> sizes) => Product(
      id: name,
      categoryId: 'c',
      name: name,
      variants: [for (final (i, s) in sizes.indexed) Variant(id: '$name-$i', name: s, price: 1500 + i * 500)],
      groups: const [],
      taxes: const [],
    );

void main() {
  final long = _product('Ice cream cup', ['Small', 'Medium', 'Large', 'Family size', 'Party bucket']);
  final short = _product('Waffle', []);

  Future<BuildContext> pump(WidgetTester tester, Widget child, {double width = 180}) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      theme: AbyTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Builder(builder: (context) {
              ctx = context;
              return child;
            }),
          ),
        ),
      ),
    ));
    return ctx;
  }

  testWidgets('the grid keeps room for the longest size line, up to 3 lines', (tester) async {
    final context = await pump(tester, const SizedBox());
    final width = ProductTile.textWidth(180);
    expect(ProductTile.detailLinesFor(context, [short], width), 1);
    expect(ProductTile.detailLinesFor(context, [short, long], width), greaterThan(1));
    expect(ProductTile.detailLinesFor(context, [long], 40), 3, reason: 'never more than 3');
  });

  testWidgets('a long size line wraps on the tile and the row, without overflowing', (tester) async {
    final context = await pump(tester, const SizedBox());
    final lines = ProductTile.detailLinesFor(context, [long], ProductTile.textWidth(180));
    final height = 180 * 0.75 + ProductTile.textHeight(MediaQuery.textScalerOf(context), detailLines: lines) + 3;
    await pump(
      tester,
      SizedBox(
        height: height,
        child: ProductTile(product: long, tone: CategoryTone.blue, icon: 'ice-cream-bowl', inCart: 0, detailLines: lines, onTap: () {}),
      ),
    );
    final detail = tester.widget<Text>(find.text(long.sizeLine));
    expect(detail.maxLines, 3);
    expect(tester.getSize(find.text(long.sizeLine)).height, greaterThan(20), reason: 'more than one line');

    await pump(
      tester,
      ProductListRow(product: long, tone: CategoryTone.blue, icon: 'ice-cream-bowl', inCart: 0, onTap: () {}),
      width: 320,
    );
    expect(tester.widget<Text>(find.text(long.sizeLine)).maxLines, 3);
    expect(tester.takeException(), isNull);
  });
}
