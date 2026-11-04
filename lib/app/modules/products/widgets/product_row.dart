import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/category_icons.dart';
import '../../../models/catalog.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/product_picture.dart';
import '../controllers/catalogue_controller.dart';

enum _RowAction { duplicate, archive }

class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    required this.category,
    required this.photo,
    required this.showCost,
    required this.targetMargin,
    required this.onTap,
    this.onDuplicate,
    this.onArchive,
  });

  final Product product;
  final Category? category;
  final Uint8List? photo;
  final bool showCost;
  final int targetMargin;
  final VoidCallback onTap;
  final VoidCallback? onDuplicate;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final prices = product.variants.map((v) => v.price).toList()..sort();
    final priceText = prices.first == prices.last
        ? formatMoney(prices.first)
        : '${formatMoney(prices.first)} – ${formatMoney(prices.last)}';
    final margins = <(int, int)>[];
    for (final variant in product.variants) {
      final cost = variant.cost;
      final percent = CatalogueController.marginOf(variant.price, cost);
      if (cost != null && percent != null) margins.add((percent, variant.price - cost));
    }
    final lowest = margins.isEmpty
        ? null
        : margins.reduce((a, b) => a.$1 < b.$1 || (a.$1 == b.$1 && a.$2 <= b.$2) ? a : b);
    final status = product.archived
        ? l.productsFilterArchived
        : !product.active
            ? l.productsFilterOffTill
            : null;
    final price = Text(priceText, style: AbyText.price.copyWith(color: c.ink));
    final margin = !showCost
        ? null
        : Text(
            lowest == null ? l.productsNoCost : '${l.productsMargin(lowest.$1)} · ${formatMoney(lowest.$2)}',
            style: AbyText.caption.copyWith(
              color: lowest == null
                  ? c.inkMuted
                  : lowest.$1 < targetMargin
                      ? c.danger
                      : c.success,
              fontWeight: FontWeight.w700,
            ),
          );
    // A price range beside the name leaves a phone no room for the name.
    final narrow = context.isNarrow;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
          child: Row(children: [
              SizedBox.square(
                dimension: 48,
                child: ProductPicture(
                  tone: category?.tone ?? CategoryTone.midnight,
                  icon: category?.picture ?? toneIcon(CategoryTone.midnight),
                  photo: photo == null ? null : MemoryImage(photo!),
                  iconSize: 22,
                ),
            ),
            const SizedBox(width: AbySpace.s3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name,
                    style: AbyText.body.copyWith(
                      color: status == null ? c.ink : c.inkMuted,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  [
                    ?category?.name,
                    if (product.variants.length > 1) l.productsVariantCount(product.variants.length),
                    if (product.groups.isNotEmpty) product.groups.map((g) => g.name).join(', '),
                    ?status,
                  ].join('  ·  '),
                  style: AbyText.caption.copyWith(color: c.inkMuted),
                ),
                if (narrow)
                  Wrap(spacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [price, ?margin]),
              ]),
            ),
            if (!narrow) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [price, ?margin]),
            if (onDuplicate != null || onArchive != null)
              PopupMenuButton<_RowAction>(
                tooltip: l.commonMore,
                onSelected: (a) => switch (a) {
                  _RowAction.duplicate => onDuplicate?.call(),
                  _RowAction.archive => onArchive?.call(),
                },
                itemBuilder: (_) => [
                  if (onDuplicate != null && !product.archived)
                    PopupMenuItem(value: _RowAction.duplicate, child: Text(l.productsDuplicate)),
                  if (onArchive != null)
                    PopupMenuItem(
                      value: _RowAction.archive,
                      child: Text(product.archived ? l.productsRestore : l.productsArchive),
                    ),
                ],
              )
            else
              const SizedBox(width: AbySpace.s3),
          ]),
        ),
      ),
    );
  }
}
