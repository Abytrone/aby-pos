import 'package:flutter/material.dart';

import '../../../models/catalog.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import 'category_dot.dart';

/// A quick-tap product tile (at least 112px tall).
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.product,
    required this.tone,
    required this.inCart,
    this.left,
    required this.onTap,
    this.onLongPress,
  });

  final Product product;
  final CategoryTone tone;
  final int inCart;

  /// How many can still be made, when the till can tell.
  final int? left;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final pricesDiffer = product.pricesDiffer;
    final l = context.l10n;
    final out = left != null && left! <= 0;
    return Semantics(
      button: true,
      label: '${product.name}, ${formatMoney(product.fromPrice)}'
          '${inCart > 0 ? ', $inCart in cart' : ''}',
      excludeSemantics: true,
      child: Material(
        color: out ? c.surfaceSunken : c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(
            color: inCart > 0 ? c.lineStrong : c.line,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AbySize.tileMin),
            child: Padding(
              padding: const EdgeInsets.all(AbySpace.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CategoryDot(tone: tone),
                      const Spacer(),
                      if (inCart > 0) _CountBadge(count: inCart),
                    ],
                  ),
                  const SizedBox(height: AbySpace.s2),
                  Text(
                    product.name,
                    style: AbyText.tile.copyWith(color: c.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.sizeLine.isNotEmpty)
                    Text(
                      product.sizeLine,
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Row(children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          pricesDiffer ? l.tileFrom(formatMoney(product.fromPrice)) : formatMoney(product.fromPrice),
                          style: AbyText.price.copyWith(color: out ? c.inkMuted : c.ink),
                          maxLines: 1,
                        ),
                      ),
                    ),
                    if (left != null)
                      Text(
                        out ? l.tileOut : l.tileLeft(left!),
                        style: AbyText.caption.copyWith(
                          color: out ? c.danger : c.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: AbySpace.s2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.lime,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: c.onLime,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
