import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/tax.dart';
import '../../../models/catalog.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/query_field.dart';
import '../../../ui/layout.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/product_picture.dart';
import '../../../ui/section_page.dart';
import '../../till/widgets/variant_sheet.dart' show groupRule;
import '../controllers/catalogue_controller.dart';
import '../widgets/from_stock_dialog.dart';
import '../widgets/labels_dialog.dart';
import '../widgets/category_editor.dart';
import '../widgets/option_group_editor.dart';
import '../widgets/pricing_tools.dart';
import '../widgets/product_row.dart';
import '../widgets/tax_editor.dart';

/// Manage → Products.
class ProductsView extends GetView<CatalogueController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 4,
      child: Builder(builder: (context) {
        final tabs = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabs,
          builder: (context, _) => SectionPage(
            title: l.navProducts,
            actions: [
              if (tabs.index == 0)
                PopupMenuButton<int>(
                  tooltip: l.productsTools,
                  onSelected: (v) => switch (v) {
                    0 => showBulkPrices(controller),
                    1 => runImport(controller),
                    3 => showLabels(),
                    4 => showProductsFromStock(context),
                    _ => controller.exportProducts(),
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 0, child: Text(l.bulkTitle)),
                    if (controller.canEdit) PopupMenuItem(value: 1, child: Text(l.importTitle)),
                    if (controller.canEdit) PopupMenuItem(value: 4, child: Text(l.fromStockTitle)),
                    PopupMenuItem(value: 2, child: Text(l.exportButton)),
                    PopupMenuItem(value: 3, child: Text(l.labelsTitle)),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s3),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.build_outlined),
                      const SizedBox(width: AbySpace.s2),
                      Text(l.productsTools),
                    ]),
                  ),
                ),
              if (controller.canEdit)
                FilledButton.icon(
                  onPressed: () => switch (tabs.index) {
                    0 => controller.openEditor(),
                    1 => showCategoryEditor(controller),
                    2 => showOptionGroupEditor(controller),
                    _ => showTaxEditor(controller),
                  },
                  icon: const Icon(Icons.add),
                  label: Text(switch (tabs.index) {
                    0 => l.productsNew,
                    1 => l.categoriesNew,
                    2 => l.optionsNew,
                    _ => l.taxNew,
                  }),
                ),
            ],
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: l.productsTab),
                Tab(text: l.categoriesTab),
                Tab(text: l.optionsTab),
                Tab(text: l.taxTab),
              ],
            ),
            child: Obx(() {
              if (controller.loading.value) return const Center(child: CircularProgressIndicator());
              _flush(controller.message);
              return const TabBarView(children: [_Products(), _Categories(), _Groups(), _Taxes()]);
            }),
          ),
        );
      }),
    );
  }
}

/// Shows a pending message once.
void _flush(RxnString message) {
  final text = message.value;
  if (text == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (message.value == null) return;
    message.value = null;
    showMessage(text);
  });
}

class _Products extends GetView<CatalogueController> {
  const _Products();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String filterLabel(ProductFilter f) => switch (f) {
          ProductFilter.all => l.productsFilterAll,
          ProductFilter.onTill => l.productsFilterOnTill,
          ProductFilter.offTill => l.productsFilterOffTill,
          ProductFilter.belowMargin => l.productsFilterLowMargin,
          ProductFilter.archived => l.productsFilterArchived,
        };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s3, AbySpace.s4, AbySpace.s2),
        child: Obx(() => Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: context.isNarrow ? double.infinity : 260,
                  child: QueryField(query: controller.query, hint: l.productsSearch),
                ),
                for (final f in ProductFilter.values)
                  if (f != ProductFilter.belowMargin || controller.canSeeCost)
                    ChoiceChip(
                      label: Text(filterLabel(f)),
                      selected: controller.filter.value == f,
                      onSelected: (_) => controller.filter.value = f,
                    ),
                DropdownButton<String?>(
                  value: controller.categoryId.value,
                  hint: Text(l.productsAllCategories),
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l.productsAllCategories)),
                    for (final c in controller.categories.where((c) => c.parentId == null))
                      DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => controller.categoryId.value = v,
                ),
              ],
            )),
      ),
      Expanded(
        child: Obx(() {
          final products = controller.visibleProducts;
          if (products.isEmpty) {
              final none = controller.catalogue.value?.products.isEmpty ?? false;
              return EmptyState(icon: Icons.sell_outlined, message: none ? l.productsNoneYet : l.productsNone,
                action: none && controller.canEdit ? l.productsImportCta : null,
                onAction: () => runImport(controller),
              );
            }
            final photos = Map.of(controller.photos);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s8),
            itemCount: products.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => ProductRow(
              product: products[i],
              category: controller.categoryOf(products[i].categoryId),
              photo: photos[products[i].id],
              showCost: controller.canSeeCost,
              targetMargin: controller.targetMargin,
              onTap: () => controller.openEditor(products[i]),
              onDuplicate: controller.canEdit ? () => controller.duplicate(products[i]) : null,
              onArchive: controller.canEdit
                  ? () async {
                      final p = products[i];
                      if (!p.archived &&
                          !await confirmDialog(
                            title: l.productsArchiveTitle(p.name),
                            message: l.productsArchiveBody,
                            confirmLabel: l.productsArchive,
                          )) {
                        return;
                      }
                      await controller.setArchived(p, !p.archived);
                    }
                  : null,
            ),
          );
        }),
      ),
    ]);
  }
}

class _Categories extends GetView<CatalogueController> {
  const _Categories();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final all = controller.categories;
      final tops = all.where((x) => x.parentId == null).toList();
      if (all.isEmpty) return EmptyState(icon: Icons.category_outlined, message: l.categoriesNone);
      final rows = <(Category, bool)>[
        for (final t in tops) ...[(t, false), for (final s in all.where((x) => x.parentId == t.id)) (s, true)],
      ];
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final (cat, child) = rows[i];
          return InkWell(
            onTap: controller.canEdit ? () => showCategoryEditor(controller, cat) : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AbySize.tapPos),
              child: Row(children: [
                SizedBox(width: child ? AbySpace.s8 : 0),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                    child: SizedBox.square(
                      dimension: child ? 32 : 40,
                      child: Opacity(
                        opacity: cat.active ? 1 : 0.5,
                        child: ProductPicture(tone: cat.tone, icon: cat.picture, iconSize: child ? 18 : 22),
                      ),
                    ),
                  ),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: Text(cat.name,
                      style: AbyText.body.copyWith(
                        color: cat.active ? c.ink : c.inkMuted,
                        fontWeight: child ? FontWeight.w400 : FontWeight.w700,
                      )),
                ),
                if (!cat.active) Text(l.categoriesHidden, style: AbyText.caption.copyWith(color: c.inkMuted)),
                if (controller.canEdit)
                  Switch(
                    value: cat.active,
                    onChanged: (v) => controller.setCategoryActive(cat, v),
                  ),
              ]),
            ),
          );
        },
      );
    });
  }
}

class _Groups extends GetView<CatalogueController> {
  const _Groups();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final groups = controller.groups;
      if (groups.isEmpty) return EmptyState(icon: Icons.tune, message: l.optionsNone);
      return ListView.separated(
        padding: const EdgeInsets.all(AbySpace.s4),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final g = groups[i];
          final users = controller.productsUsing(g);
          return InkWell(
            onTap: controller.canEdit ? () => showOptionGroupEditor(controller, g) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AbySpace.s3),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${g.name}  ·  ${groupRule(l, g)}',
                        style: AbyText.body.copyWith(color: g.active ? c.ink : c.inkMuted, fontWeight: FontWeight.w700)),
                    Text(
                      g.options.map((o) => o.priceDelta == 0 ? o.name : '${o.name} +${formatMoney(o.priceDelta)}').join(', '),
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                    ),
                    Text(
                      users.isEmpty ? l.optionsUnused : l.optionsUsedBy(users.join(', ')),
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ]),
                ),
                if (controller.canEdit) Switch(value: g.active, onChanged: (v) => controller.setGroupActive(g, v)),
              ]),
            ),
          );
        },
      );
    });
  }
}

class _Taxes extends GetView<CatalogueController> {
  const _Taxes();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    String modeLabel(TaxMode m) => switch (m) {
          TaxMode.off => l.taxModeOff,
          TaxMode.inclusive => l.taxModeInclusive,
          TaxMode.exclusive => l.taxModeExclusive,
        };
    return Obx(() {
      final mode = controller.taxMode;
      final rates = controller.taxRates;
      final active = rates.where((r) => r.active).toList();
      return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
        Text(l.taxModeTitle.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s2),
        Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
          for (final m in TaxMode.values)
            OptionChip(label: modeLabel(m), selected: mode == m, onTap: () => controller.setTaxMode(m)),
        ]),
        const SizedBox(height: AbySpace.s2),
        Text(l.taxModeHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s6),
        GroupCard(
          title: l.taxRates,
          footer: active.isEmpty ? null : controller.taxExample(active),
          children: [
            if (rates.isEmpty) InfoTile(title: l.taxNone),
            for (final r in rates)
              InfoTile(
                title: '${r.name}  ${r.percent}',
                subtitle: r.compound ? l.taxCompound : null,
                onTap: controller.canEdit ? () => showTaxEditor(controller, r) : null,
                trailing: Switch(value: r.active, onChanged: (v) => controller.setTaxActive(r, v)),
              ),
          ],
        ),
        Text(l.taxAccountant, style: AbyText.caption.copyWith(color: c.inkMuted)),
      ]);
    });
  }
}
