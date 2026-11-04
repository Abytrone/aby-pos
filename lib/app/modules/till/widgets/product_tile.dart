import 'package:flutter/material.dart';

import '../../../models/catalog.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/product_picture.dart';
import 'category_dot.dart';

/// What a tile or row says about one product, worked out once for both
/// views so they never disagree.
class _Facts {
  _Facts(BuildContext context, Product p, int? left, bool low)
    : out = left != null && left <= 0,
      stock = left == null
          ? null
          : (left <= 0
                ? context.l10n.tileOut
                : low
                ? context.l10n.tileLowLeft(left)
                : context.l10n.tileLeft(left)),
      low = low,
      price = p.openPrice
          ? context.l10n.tileOpenPrice
          : [
              p.pricesDiffer ? context.l10n.tileFrom(formatMoney(p.fromPrice)) : formatMoney(p.fromPrice),
              if (p.perUnit != null) '/${p.perUnit}',
            ].join();

  final bool out;
  final bool low;
  final String? stock;
  final String price;

  String semantics(Product p, int inCart) =>
      '${p.name}, $price${stock != null ? ', $stock' : ''}${inCart > 0 ? ', $inCart in cart' : ''}';
}

/// The line under the name: stock when it is low ("3 left" in warning),
/// else the size.
class _Detail extends StatelessWidget {
  const _Detail({required this.product, required this.facts});

  final Product product;
  final _Facts facts;

  /// Sizes and flavours wrap rather than being cut off.
  static const maxLines = 3;
  static TextStyle style(AbyColors c) => AbyText.caption.copyWith(color: c.inkMuted);

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    if (facts.stock != null) {
      return Text(
        facts.stock!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AbyText.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: facts.out
              ? c.danger
              : facts.low
              ? c.warning
              : c.inkMuted,
        ),
      );
    }
    if (product.sizeLine.isEmpty) return const SizedBox.shrink();
    return Text(product.sizeLine, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: style(c));
  }
}

/// Product names on tiles and rows (the brand's tile style at 16).
const _nameStyle = TextStyle(fontFamily: AbyText.family, fontSize: 16, height: 21 / 16, fontWeight: FontWeight.w600);

/// Grid view: one tap adds one item. A 4:3 photo (or the category icon on
/// its tint), the name, the size or stock, and the price. The category dot
/// sits on the photo's corner; a lime count shows how many are in the cart.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.tone,
    required this.icon,
    required this.inCart,
    this.left,
    this.low = false,
    this.photo,
    this.detailLines = 1,
    required this.onTap,
    this.onLongPress,
  });

  final Product product;
  final CategoryTone tone;

  /// Lines kept for the size line, the same for every tile in the grid
  /// (see [detailLinesFor]) so photos and prices line up across a row.
  final int detailLines;

  /// The category's picture, for when there is no photo.
  final String icon;
  final int inCart;

  /// How many can still be made, when the till can tell.
  final int? left;
  final bool low;
  final ImageProvider? photo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Height of everything under the photo: padding, two lines of name,
  /// [detailLines] of size line and the price, at the device's text size.
  static double textHeight(TextScaler scaler, {int detailLines = 1}) =>
      AbySpace.s2 * 3 + AbySpace.s1 + scaler.scale(21) * 2 + scaler.scale(18) * detailLines + scaler.scale(22);

  /// The text width under a tile's photo, for a tile [tileWidth] wide.
  static double textWidth(double tileWidth) => tileWidth - AbySpace.s2 * 2 - AbySpace.s1 * 2 - 3;

  /// How many lines the longest size line among [products] needs at
  /// [width] (1 to 3), so the grid keeps room for it and no more.
  static int detailLinesFor(BuildContext context, Iterable<Product> products, double width) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final scaler = MediaQuery.textScalerOf(context);
    var lines = 1;
    for (final p in products) {
      if (p.sizeLine.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: p.sizeLine, style: _Detail.style(c)),
        maxLines: _Detail.maxLines,
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: width);
      final n = painter.computeLineMetrics().length;
      painter.dispose();
      if (n > lines) lines = n;
      if (lines == _Detail.maxLines) break;
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final f = _Facts(context, product, left, low);
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      button: true,
      label: f.semantics(product, inCart),
      excludeSemantics: true,
      child: Material(
        color: c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: inCart > 0 ? c.primary : c.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AbySpace.s2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ProductPicture(tone: tone, icon: icon, photo: photo, dimmed: f.out, iconSize: 36),
                      ),
                      Positioned(
                        top: AbySpace.s2,
                        left: AbySpace.s2,
                        child: _RingedDot(tone: tone),
                      ),
                      if (inCart > 0) Positioned(top: 6, right: 6, child: CartCountBadge(count: inCart)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AbySpace.s1, AbySpace.s2, AbySpace.s1, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Two lines kept for every name, so prices line up across a row.
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: scaler.scale(21) * 2),
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _nameStyle.copyWith(color: f.out ? c.inkMuted : c.ink),
                        ),
                      ),
                      SizedBox(
                        height: scaler.scale(18) * detailLines,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: _Detail(product: product, facts: f),
                        ),
                      ),
                      const SizedBox(height: AbySpace.s1),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          f.price,
                          maxLines: 1,
                          style: AbyText.price.copyWith(color: f.out ? c.inkMuted : c.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// List view: the same product as a row, with the same tap behaviour. A
/// 56 px photo, the name with its category dot, the size or stock, the
/// price, and the cart count (a plus until it is in the cart).
class ProductListRow extends StatelessWidget {
  const ProductListRow({
    super.key,
    required this.product,
    required this.tone,
    required this.icon,
    required this.inCart,
    this.left,
    this.low = false,
    this.photo,
    required this.onTap,
    this.onLongPress,
  });

  final Product product;
  final CategoryTone tone;
  final String icon;
  final int inCart;
  final int? left;
  final bool low;
  final ImageProvider? photo;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final f = _Facts(context, product, left, low);
    return Semantics(
      button: true,
      label: f.semantics(product, inCart),
      excludeSemantics: true,
      child: Material(
        color: c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: inCart > 0 ? c.primary : c.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AbySpace.s2, AbySpace.s2, AbySpace.s3, AbySpace.s2),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: AbySize.thumbRow,
                    child: ProductPicture(tone: tone, icon: icon, photo: photo, dimmed: f.out, iconSize: 24),
                  ),
                  const SizedBox(width: AbySpace.s3),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CategoryDot(tone: tone, size: 8),
                            const SizedBox(width: AbySpace.s2),
                            Flexible(
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _nameStyle.copyWith(color: f.out ? c.inkMuted : c.ink),
                              ),
                            ),
                          ],
                        ),
                        _Detail(product: product, facts: f),
                      ],
                    ),
                  ),
                  const SizedBox(width: AbySpace.s3),
                  // The price gets up to two fifths of the room, and shrinks
                  // rather than being cut off.
                  Flexible(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          f.price,
                          maxLines: 1,
                          style: AbyText.price.copyWith(color: f.out ? c.inkMuted : c.ink),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AbySpace.s3),
                  if (inCart > 0)
                    CartCountBadge(count: inCart, size: 32)
                  else
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: c.lineStrong, width: 1.5),
                      ),
                      child: AbyIcon(AbyIcons.plus, size: 20, color: c.inkMuted),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The category dot on a photo, ringed so it reads on any picture.
class _RingedDot extends StatelessWidget {
  const _RingedDot({required this.tone});

  final CategoryTone tone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: toneColor(tone, c),
        shape: BoxShape.circle,
        border: Border.all(color: c.surfaceRaised, width: 2),
      ),
    );
  }
}
