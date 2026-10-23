import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/catalog.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../till/widgets/category_dot.dart';
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
    final margins = [for (final v in product.variants) CatalogueController.marginOf(v.price, v.cost)];
    final known = margins.whereType<int>().toList();
    final lowest = known.isEmpty ? null : known.reduce((a, b) => a < b ? a : b);
    final status = product.archived
        ? l.productsFilterArchived
        : !product.active
            ? l.productsFilterOffTill
            : null;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AbyRadius.sm),
              child: SizedBox.square(
                dimension: 48,
                child: photo != null
                    ? Image.memory(photo!, fit: BoxFit.cover, gaplessPlayback: true)
                    : ColoredBox(
                        color: c.surfaceSunken,
                        child: Center(
                          child: category == null ? null : CategoryDot(tone: category!.tone),
                        ),
                      ),
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
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(priceText, style: AbyText.price.copyWith(color: c.ink)),
              if (showCost)
                Text(
                  lowest == null ? l.productsNoCost : l.productsMargin(lowest),
                  style: AbyText.caption.copyWith(
                    color: lowest == null
                        ? c.inkMuted
                        : lowest < targetMargin
                            ? c.danger
                            : c.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ]),
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
