import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../models/catalog.dart';
import '../../../models/enums.dart';
import '../../../routes/app_routes.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/barcode_scanner.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../controllers/till_controller.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_dot.dart';
import '../widgets/entry_dialog.dart';
import '../widgets/product_tile.dart';
import '../widgets/quick_arrange.dart';
import '../widgets/variant_sheet.dart';

/// Wide enough to show the cart beside the menu (a 10-inch tablet in
/// landscape, after the navigation rail).
const _sideBySideWidth = 760.0;
const _cartWidth = 380.0;

/// Tile width limit and height for each tile size setting.
(double, double) _tileExtent(String size) => switch (size) {
  'small' => (170.0, 124.0),
  'large' => (300.0, 196.0),
  _ => (230.0, 156.0),
};

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
        showMessage(l.tillCodeNotFound(code));
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
                prefixIcon: const Icon(Icons.qr_code_scanner),
                hintText: l.tillSearchHint,
                helperText: qty == null ? null : l.tillQuantityHint(qty),
                suffixIcon: controller.query.value.isEmpty
                    ? cameraScanButton((code) {
                        controller.search.text = code;
                        onSubmit();
                      })
                    : IconButton(
                        tooltip: l.commonClear,
                        icon: const Icon(Icons.close),
                        onPressed: controller.clearSearch,
                      ),
              ),
            );
          }),
        ),
        SizedBox(
          height: AbySize.tapPos + AbySpace.s6,
          child: Obx(() {
            final selected = controller.tab.value;
            final searching = controller.filterText.isNotEmpty;
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
              children: [
                if (controller.quickProducts.isNotEmpty || controller.canEditProducts)
                  _CategoryTab(
                    label: l.tillQuick,
                    icon: Icons.star_rounded,
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
                    icon: Icons.history,
                    selected: !searching && selected is RecentTab,
                    onTap: () => controller.selectTab(const RecentTab()),
                  ),
              ],
            );
          }),
        ),
        Expanded(
          child: Obx(() {
            final products = controller.visibleProducts;
            final onQuick = controller.tab.value is QuickTab && controller.filterText.isEmpty;
            final (maxWidth, height) = _tileExtent(Get.find<SettingsService>().get(AppSettings.tileSize));
            // Read eagerly: the grid builds lazily, outside this Obx.
            final inCart = {for (final p in products) p.id: controller.cart.countFor(p.id)};
            final left = {for (final p in products) p.id: controller.leftOf(p)};
            final photos = Map.of(controller.photos);
            if (products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AbySpace.s6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.filterText.isNotEmpty
                            ? l.tillNoMatch
                            : onQuick
                            ? l.tillQuickEmpty
                            : l.tillNothingHere,
                        textAlign: TextAlign.center,
                        style: AbyText.body.copyWith(color: c.inkMuted),
                      ),
                      if (onQuick && controller.canEditProducts) ...[
                        const SizedBox(height: AbySpace.s3),
                        OutlinedButton.icon(
                          onPressed: () => showQuickArrange(controller),
                          icon: const Icon(Icons.star_outline),
                          label: Text(l.quickArrange),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
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
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(l.quickArrange),
                      ),
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s4),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxWidth,
                      mainAxisExtent: height,
                      crossAxisSpacing: AbySpace.s3,
                      mainAxisSpacing: AbySpace.s3,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final Product p = products[i];
                      return ProductTile(
                        product: p,
                        tone: controller.categoryOf(p)?.tone ?? CategoryTone.midnight,
                        inCart: inCart[p.id] ?? 0,
                        left: left[p.id],
                        photo: photos[p.id],
                        large: height > 180,
                        onTap: () => onTapResult(controller.tapProduct(p)),
                        onLongPress: p.hasChoices && !p.needsEntry
                            ? () {
                                if (controller.longPressProduct(p)) onTapResult(TapResult.picker);
                              }
                            : null,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.selected, required this.onTap, this.tone, this.icon});

  final String label;
  final CategoryTone? tone;
  final IconData? icon;
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
                    Icon(icon, size: 20, color: selected ? c.onPrimary : c.ink),
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
