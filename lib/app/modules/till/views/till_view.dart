import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/catalog.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../controllers/till_controller.dart';
import '../widgets/cart_panel.dart';
import '../widgets/category_dot.dart';
import '../widgets/product_tile.dart';
import '../widgets/variant_sheet.dart';

/// Wide enough to show the cart beside the menu (a 10-inch tablet in landscape).
const _sideBySideWidth = 840.0;
const _cartWidth = 380.0;

class TillView extends GetView<TillController> {
  const TillView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(controller: controller),
            const Divider(height: 1),
            Expanded(
              child: Obx(() {
                if (controller.loading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return LayoutBuilder(builder: (context, constraints) {
                  final menu = _Menu(
                    controller: controller,
                    onPickerOpened: () => _showPicker(context),
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
                      _CompactCartBar(
                        controller: controller,
                        onOpenCart: () => _showCart(context),
                      ),
                    ],
                  );
                });
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    Get.bottomSheet<void>(
      const VariantSheet(),
      backgroundColor: Theme.of(context).extension<AbyColors>()!.surfaceRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AbyRadius.lg)),
      ),
    ).whenComplete(controller.closePicker);
  }

  void _showCart(BuildContext context) {
    Get.bottomSheet<void>(
      SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: CartPanel(onPay: () {
          Get.back<void>();
          controller.pay();
        }),
      ),
      backgroundColor: Theme.of(context).extension<AbyColors>()!.surfaceRaised,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AbyRadius.lg)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final TillController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final badge = Obx(() => AbySyncBadge(
          waiting: controller.sync.waitingSales.value,
          offline: !controller.sync.online.value,
        ));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s2),
      child: LayoutBuilder(builder: (context, constraints) {
        // Phones: no shop name, the badge shrinks to fit, lock is icon-only.
        final narrow = constraints.maxWidth < 600;
        return Row(
          children: [
            const AbyMark(size: 36),
            const SizedBox(width: AbySpace.s3),
            if (narrow)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: badge,
                ),
              )
            else ...[
              Expanded(
                child: Obx(() => Text(
                      controller.shopName.value,
                      style: AbyText.heading.copyWith(color: c.ink),
                      overflow: TextOverflow.ellipsis,
                    )),
              ),
              badge,
            ],
            const SizedBox(width: AbySpace.s2),
            TextButton(
              onPressed: controller.openToday,
              style: TextButton.styleFrom(minimumSize: const Size(AbySize.tapPos, AbySize.tapPos)),
              child: const Text('Today'),
            ),
            Obx(() {
              final name = controller.auth.currentUser.value?.name ?? '';
              final style = TextButton.styleFrom(
                foregroundColor: c.ink,
                minimumSize: const Size(AbySize.tapPos, AbySize.tapPos),
              );
              return narrow
                  ? IconButton(
                      tooltip: 'Lock ($name)',
                      onPressed: controller.lock,
                      style: style,
                      icon: const Icon(Icons.lock_outline),
                    )
                  : TextButton.icon(
                      onPressed: controller.lock,
                      style: style,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(name),
                    );
            }),
          ],
        );
      }),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.controller, required this.onPickerOpened});

  final TillController controller;
  final VoidCallback onPickerOpened;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AbySize.tapPos + AbySpace.s6,
          child: Obx(() {
            final selected = controller.selectedCategoryId.value;
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AbySpace.s4, vertical: AbySpace.s3),
              children: [
                _CategoryTab(
                  label: 'All',
                  selected: selected == null,
                  onTap: () => controller.selectCategory(null),
                ),
                for (final cat in controller.categories)
                  _CategoryTab(
                    label: cat.name,
                    tone: cat.tone,
                    selected: selected == cat.id,
                    onTap: () => controller.selectCategory(cat.id),
                  ),
              ],
            );
          }),
        ),
        Expanded(
          child: Obx(() {
            final products = controller.visibleProducts;
            // Read eagerly: the grid builds lazily, outside this Obx.
            final inCart = {
              for (final p in products) p.id: controller.cart.countFor(p.id),
            };
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                  AbySpace.s4, 0, AbySpace.s4, AbySpace.s4),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                // Fits a two-line name, the size line and the price.
                mainAxisExtent: 152,
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
                  onTap: () {
                    if (controller.tapProduct(p)) onPickerOpened();
                  },
                  onLongPress: p.hasOptions
                      ? () {
                          if (controller.longPressProduct(p)) onPickerOpened();
                        }
                      : null,
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tone,
  });

  final String label;
  final CategoryTone? tone;
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
          shape: StadiumBorder(
            side: BorderSide(color: selected ? c.primary : c.lineStrong, width: 1.5),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minWidth: AbySize.tapPos * 1.5),
              padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tone != null) ...[
                    CategoryDot(tone: tone!),
                    const SizedBox(width: AbySpace.s2),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selected ? c.onPrimary : c.ink,
                    ),
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
    return Container(
      padding: const EdgeInsets.all(AbySpace.s3),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(top: BorderSide(color: c.line, width: 1.5)),
      ),
      child: Obx(() {
        final cart = controller.cart;
        return Row(
          children: [
            OutlinedButton(
              onPressed: onOpenCart,
              child: Text('Cart (${cart.itemCount})'),
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
