import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../models/catalog.dart';
import '../../../models/enums.dart';
import '../../../routes/app_routes.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../domain/category_icons.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/barcode_scanner.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../controllers/till_controller.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_dot.dart';
import '../widgets/entry_dialog.dart';
import '../widgets/product_tile.dart';
import '../widgets/quick_arrange.dart';
import '../widgets/variant_sheet.dart';
import '../widgets/view_toggle.dart';

/// Wide enough to show the cart beside the menu (a 10-inch tablet in
/// landscape, after the navigation rail).
const _sideBySideWidth = 760.0;
const _cartWidth = 380.0;

class TillView extends GetView<TillController> {
  const TillView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return LayoutBuilder(
        builder: (context, constraints) {
          final menu = _Menu(
            controller: controller,
            onTapResult: (r) => _afterTap(context, r),
            onSubmit: () => submitCode(context, controller),
          );
          if (constraints.maxWidth >= _sideBySideWidth) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: menu),
                Container(
                  width: _cartWidth,
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    border: Border(left: BorderSide(color: c.line, width: 1.5)),
                  ),
                  child: CartPanel(onPay: controller.pay),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(child: menu),
              _CompactCartBar(controller: controller, onOpenCart: () => _showCart(context)),
            ],
          );
        },
      );
    });
  }

  void _afterTap(BuildContext context, TapResult result) {
    switch (result) {
      case TapResult.picker:
        showPicker(context, controller);
      case TapResult.entry:
        showEntryDialog(controller);
      case TapResult.added || TapResult.blocked:
        break;
    }
    flushTillMessage(controller);
  }

  void _showCart(BuildContext context) {
    Get.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: CartPanel(
          onPay: () {
            goBack<void>();
            controller.pay();
          },
        ),
      ),
      backgroundColor: Theme.of(context).extension<AbyColors>()!.surfaceRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AbyRadius.lg))),
    );
  }
}

void showPicker(BuildContext context, TillController controller) {
  Get.bottomSheet<void>(
    const VariantSheet(),
    backgroundColor: Theme.of(context).extension<AbyColors>()!.surfaceRaised,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AbyRadius.lg))),
  ).whenComplete(controller.closePicker);
}

void flushTillMessage(TillController controller) {
  final text = controller.message.value;
  if (text == null) return;
  controller.message.value = null;
  showMessage(text);
}

/// Enter in the search box (or a scan).
Future<void> submitCode(BuildContext context, TillController controller) async {
  final result = await controller.submitCode();
  if (!context.mounted) return;
  final l = context.l10n;
  switch (result) {
    case CodeAdded():
      break;
    case CodeNeedsInput(:final result):
      if (result == TapResult.picker) showPicker(context, controller);
      if (result == TapResult.entry) await showEntryDialog(controller);
    case CodeNotFound(:final code, :final canCreate):
      if (canCreate) {
        final create = await confirmDialog(
          title: l.tillCodeUnknownTitle(code),
          message: l.tillCodeUnknownBody,
          confirmLabel: l.tillCodeCreate,
        );
        if (create) controller.newProductWithBarcode(code);
      } else {
        showMessage(l.tillCodeNotFound(code), tone: MessageTone.error);
      }
    case CodeReceipt(:final saleId):
      await Get.toNamed<void>(Routes.refund, arguments: saleId);
    case CodeNothing():
      break;
  }
  flushTillMessage(controller);
}

class _Menu extends StatelessWidget {
  const _Menu({required this.controller, required this.onTapResult, required this.onSubmit});

  final TillController controller;
  final void Function(TapResult) onTapResult;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s3, AbySpace.s4, 0),
          child: Obx(() {
            final qty = controller.pendingQuantity;
            return TextField(
              controller: controller.search,
              focusNode: controller.searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(AbySpace.s3),
                  child: AbyIcon(AbyIcons.scanBarcode, size: 20, color: c.inkMuted),
                ),
                hintText: l.tillSearchHint,
                helperText: qty == null ? null : l.tillQuantityHint(qty),
                suffixIcon: controller.query.value.isEmpty
                    ? cameraScanButton((code) {
                        controller.search.text = code;
                        onSubmit();
                      })
                    : IconButton(
                        tooltip: l.commonClear,
                        icon: AbyIcon(AbyIcons.x, size: 20, color: c.inkMuted),
                        onPressed: controller.clearSearch,
                      ),
              ),
            );
          }),
        ),
        _MenuHeader(
          tabs: Obx(() {
            final selected = controller.tab.value;
            final searching = controller.filterText.isNotEmpty;
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s3, AbySpace.s2, AbySpace.s3),
              children: [
                if (controller.quickProducts.isNotEmpty || controller.canEditProducts)
                  _CategoryTab(
                    label: l.tillQuick,
                    icon: AbyIcons.star,
                    selected: !searching && selected is QuickTab,
                    onTap: () => controller.selectTab(const QuickTab()),
                  ),
                _CategoryTab(
                  label: l.tillAll,
                  selected: !searching && selected is AllTab,
                  onTap: () => controller.selectTab(const AllTab()),
                ),
                for (final cat in controller.topCategories)
                  _CategoryTab(
                    label: cat.name,
                    tone: cat.tone,
                    selected: !searching && selected == CategoryTab(cat.id),
                    onTap: () => controller.selectTab(CategoryTab(cat.id)),
                  ),
                if (controller.recentProducts.isNotEmpty)
                  _CategoryTab(
                    label: l.tillRecent,
                    icon: AbyIcons.history,
                    selected: !searching && selected is RecentTab,
                    onTap: () => controller.selectTab(const RecentTab()),
                  ),
              ],
            );
          }),
          toggle: Obx(
            () => ViewToggle(
              value: _viewFor(context, controller.productView),
              onChanged: (v) => controller.setProductView(v.name),
            ),
          ),
          count: Obx(
            () => Text(
              l.tillProductCount(controller.visibleProducts.length),
              style: AbyText.caption.copyWith(color: c.inkMuted),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final products = controller.visibleProducts;
            final onQuick = controller.tab.value is QuickTab && controller.filterText.isEmpty;
            final view = _viewFor(context, controller.productView);
            final target = _tileTarget(Get.find<SettingsService>().get(AppSettings.tileSize));
            // Read eagerly: the grid builds lazily, outside this Obx.
            final inCart = {for (final p in products) p.id: controller.cart.countFor(p.id)};
            final left = {for (final p in products) p.id: controller.leftOf(p)};
            final low = {for (final p in products) p.id: controller.isLowOf(p)};
            final photos = Map.of(controller.photos);
            if (products.isEmpty) {
              final query = controller.query.value.trim();
              if (controller.filterText.isNotEmpty) {
                return _TillEmpty(
                  icon: AbyIcons.search,
                  title: l.tillNoMatchTitle(query),
                  line: l.tillNoMatch,
                  action: l.tillClearSearch,
                  onAction: controller.clearSearch,
                );
              }
              return _TillEmpty(
                icon: onQuick ? AbyIcons.star : AbyIcons.package,
                title: onQuick ? l.tillQuickEmpty : l.tillNothingHere,
                action: onQuick && controller.canEditProducts ? l.quickArrange : null,
                onAction: () => showQuickArrange(controller),
              );
            }
            Widget item(Product p, {required bool grid, int detailLines = 1}) {
              final cat = controller.categoryOf(p);
              final tone = cat?.tone ?? CategoryTone.midnight;
              final icon = cat?.picture ?? toneIcon(tone);
              void tap() => onTapResult(controller.tapProduct(p));
              final longPress = p.hasChoices && !p.needsEntry
                  ? () {
                      final result = controller.longPressProduct(p);
                      if (result != null) onTapResult(result);
                    }
                  : null;
              return grid
                  ? ProductTile(
                      product: p,
                      tone: tone,
                      icon: icon,
                      inCart: inCart[p.id] ?? 0,
                      left: left[p.id],
                      low: low[p.id] ?? false,
                      photo: photos[p.id],
                      detailLines: detailLines,
                      onTap: tap,
                      onLongPress: longPress,
                    )
                  : ProductListRow(
                      product: p,
                      tone: tone,
                      icon: icon,
                      inCart: inCart[p.id] ?? 0,
                      left: left[p.id],
                      low: low[p.id] ?? false,
                      photo: photos[p.id],
                      onTap: tap,
                      onLongPress: longPress,
                    );
            }

            const pad = EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s4);
            final list = switch (view) {
              ProductView.list => ListView.separated(
                padding: pad,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: AbySpace.s2),
                itemBuilder: (_, i) => item(products[i], grid: false),
              ),
              ProductView.grid => LayoutBuilder(
                builder: (context, box) {
                  final width = box.maxWidth - pad.horizontal;
                  final (columns, tile) = gridColumns(width: width, target: target);
                  final detailLines = ProductTile.detailLinesFor(context, products, ProductTile.textWidth(tile));
                  final (_, extent) = gridShape(
                    width: width,
                    target: target,
                    textHeight: ProductTile.textHeight(MediaQuery.textScalerOf(context), detailLines: detailLines),
                  );
                  return GridView.builder(
                    padding: pad,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisExtent: extent,
                      crossAxisSpacing: AbySpace.s3,
                      mainAxisSpacing: AbySpace.s3,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => item(products[i], grid: true, detailLines: detailLines),
                  );
                },
              ),
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (onQuick && controller.canEditProducts)
                  Padding(
                    padding: const EdgeInsets.only(right: AbySpace.s4),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => showQuickArrange(controller),
                        icon: AbyIcon(AbyIcons.slidersHorizontal, size: 20, color: c.ink),
                        label: Text(l.quickArrange),
                      ),
                    ),
                  ),
                Expanded(child: list),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// The category tabs and the grid/list switch. Side by side on tablets;
/// on phones the tabs get the full width and the switch sits under them,
/// with how many products are showing.
class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.tabs, required this.toggle, required this.count});

  final Widget tabs;
  final Widget toggle;
  final Widget count;

  @override
  Widget build(BuildContext context) {
    final strip = SizedBox(height: AbySize.tapPos + AbySpace.s6, child: tabs);
    if (context.isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          strip,
          Padding(
            padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s3),
            child: Row(
              children: [
                Expanded(child: count),
                toggle,
              ],
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: strip),
        Padding(
          padding: const EdgeInsets.only(right: AbySpace.s4),
          child: toggle,
        ),
      ],
    );
  }
}

/// The view to show: the cashier's choice, else the grid on tablets and
/// tills and the list on phones.
ProductView _viewFor(BuildContext context, String setting) =>
    ProductView.values.asNameMap()[setting] ?? (context.isNarrow ? ProductView.list : ProductView.grid);

/// About how wide a tile should be, for each tile size setting.
double _tileTarget(String size) => switch (size) {
  'small' => 160.0,
  'large' => 250.0,
  _ => 200.0,
};

/// Columns and tile height for a grid [width] wide: tiles near [target]
/// wide but never under the brand's 140 px, each with a 4:3 photo and
/// [textHeight] of text under it.
(int, double) gridShape({required double width, required double target, required double textHeight}) {
  final (columns, tile) = gridColumns(width: width, target: target);
  // The tile's own padding (8 each side) and border sit around the photo.
  final photo = (tile - AbySpace.s2 * 2 - 3) * 3 / 4;
  return (columns, photo + textHeight + 3);
}

/// Columns for a grid [width] wide, and each tile's width: near [target]
/// but never under the brand's 140 px.
(int, double) gridColumns({required double width, required double target}) {
  const gap = AbySpace.s3;
  final fit = ((width + gap) / (AbySize.tileMin + gap)).floor();
  final columns = ((width + gap) / (target + gap)).round().clamp(1, fit < 1 ? 1 : fit);
  return (columns, (width - gap * (columns - 1)) / columns);
}

/// What the product area shows when there is nothing in it: what is
/// empty, one line on what to do, and at most one action.
class _TillEmpty extends StatelessWidget {
  const _TillEmpty({required this.icon, required this.title, this.line, this.action, this.onAction});

  final String icon;
  final String title;
  final String? line;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AbySpace.s6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
                child: AbyIcon(icon, size: 28, color: c.inkMuted),
              ),
              const SizedBox(height: AbySpace.s3),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AbyText.heading.copyWith(color: c.ink),
              ),
              if (line != null) ...[
                const SizedBox(height: AbySpace.s1),
                Text(
                  line!,
                  textAlign: TextAlign.center,
                  style: AbyText.body.copyWith(color: c.inkMuted),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: AbySpace.s3),
                OutlinedButton(onPressed: onAction, child: Text(action!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.selected, required this.onTap, this.tone, this.icon});

  final String label;
  final CategoryTone? tone;

  /// An [AbyIcons] asset.
  final String? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(right: AbySpace.s2),
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? c.primary : c.surfaceRaised,
          shape: StadiumBorder(side: BorderSide(color: selected ? c.primary : c.lineStrong, width: 1.5)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            canRequestFocus: false,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: AbySize.tapPos * 1.5),
              padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tone != null) ...[CategoryDot(tone: tone!), const SizedBox(width: AbySpace.s2)],
                  if (icon != null) ...[
                    AbyIcon(icon!, size: 18, color: selected ? c.onPrimary : c.ink),
                    const SizedBox(width: AbySpace.s1),
                  ],
                  Text(
                    label,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? c.onPrimary : c.ink),
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

/// Phones and portrait: a bar with the cart count and Pay.
class _CompactCartBar extends StatelessWidget {
  const _CompactCartBar({required this.controller, required this.onOpenCart});

  final TillController controller;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AbySpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.line, width: 1.5)),
      ),
      child: Obx(() {
        final cart = controller.cart;
        final parked = controller.parkedOrders.length;
        return Row(
          children: [
            OutlinedButton(
              onPressed: onOpenCart,
              child: Text(parked == 0 ? l.cartButton(cart.itemCount) : l.cartButtonParked(cart.itemCount, parked)),
            ),
            const SizedBox(width: AbySpace.s3),
            Expanded(
              child: AbyPayButton(
                amount: toCedisForDisplay(cart.total),
                onPressed: cart.isEmpty ? null : controller.pay,
              ),
            ),
          ],
        );
      }),
    );
  }
}
