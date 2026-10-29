// Aby icons: 70 Lucide icons (ISC licence). Generated from aby-brand-kit/ui-icons. Do not edit by hand.
// Needs flutter_svg and the SVGs copied to assets/icons/ui/.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icon names, grouped as in the brand guide. Use with [AbyIcon].
abstract final class AbyIcons {
  // Selling
  static const shoppingBasket = 'assets/icons/ui/shopping-basket.svg';
  static const plus = 'assets/icons/ui/plus.svg';
  static const minus = 'assets/icons/ui/minus.svg';
  static const trash = 'assets/icons/ui/trash.svg';
  static const pause = 'assets/icons/ui/pause.svg';
  static const tag = 'assets/icons/ui/tag.svg';
  static const percent = 'assets/icons/ui/percent.svg';
  static const search = 'assets/icons/ui/search.svg';
  static const scanBarcode = 'assets/icons/ui/scan-barcode.svg';
  static const layoutGrid = 'assets/icons/ui/layout-grid.svg';
  static const list = 'assets/icons/ui/list.svg';
  static const image = 'assets/icons/ui/image.svg';
  static const camera = 'assets/icons/ui/camera.svg';
  // Payment
  static const banknote = 'assets/icons/ui/banknote.svg';
  static const smartphone = 'assets/icons/ui/smartphone.svg';
  static const bookOpen = 'assets/icons/ui/book-open.svg';
  static const creditCard = 'assets/icons/ui/credit-card.svg';
  static const wallet = 'assets/icons/ui/wallet.svg';
  static const handCoins = 'assets/icons/ui/hand-coins.svg';
  static const receiptText = 'assets/icons/ui/receipt-text.svg';
  static const printer = 'assets/icons/ui/printer.svg';
  static const send = 'assets/icons/ui/send.svg';
  static const messageCircle = 'assets/icons/ui/message-circle.svg';
  // Sync
  static const cloudCheck = 'assets/icons/ui/cloud-check.svg';
  static const cloudUpload = 'assets/icons/ui/cloud-upload.svg';
  static const cloudOff = 'assets/icons/ui/cloud-off.svg';
  static const refreshCw = 'assets/icons/ui/refresh-cw.svg';
  // Status
  static const circleCheck = 'assets/icons/ui/circle-check.svg';
  static const info = 'assets/icons/ui/info.svg';
  static const triangleAlert = 'assets/icons/ui/triangle-alert.svg';
  static const circleAlert = 'assets/icons/ui/circle-alert.svg';
  static const undo2 = 'assets/icons/ui/undo-2.svg';
  static const rotateCcw = 'assets/icons/ui/rotate-ccw.svg';
  static const package = 'assets/icons/ui/package.svg';
  static const packageX = 'assets/icons/ui/package-x.svg';
  static const bell = 'assets/icons/ui/bell.svg';
  // Navigation
  static const chevronLeft = 'assets/icons/ui/chevron-left.svg';
  static const chevronRight = 'assets/icons/ui/chevron-right.svg';
  static const x = 'assets/icons/ui/x.svg';
  static const check = 'assets/icons/ui/check.svg';
  static const ellipsis = 'assets/icons/ui/ellipsis.svg';
  static const settings = 'assets/icons/ui/settings.svg';
  static const slidersHorizontal = 'assets/icons/ui/sliders-horizontal.svg';
  static const logOut = 'assets/icons/ui/log-out.svg';
  static const lock = 'assets/icons/ui/lock.svg';
  // Back office
  static const store = 'assets/icons/ui/store.svg';
  static const tabletSmartphone = 'assets/icons/ui/tablet-smartphone.svg';
  static const user = 'assets/icons/ui/user.svg';
  static const users = 'assets/icons/ui/users.svg';
  static const chartColumn = 'assets/icons/ui/chart-column.svg';
  static const calendar = 'assets/icons/ui/calendar.svg';
  static const clock = 'assets/icons/ui/clock.svg';
  static const fileText = 'assets/icons/ui/file-text.svg';
  // Categories
  static const iceCreamCone = 'assets/icons/ui/ice-cream-cone.svg';
  static const iceCreamBowl = 'assets/icons/ui/ice-cream-bowl.svg';
  static const cupSoda = 'assets/icons/ui/cup-soda.svg';
  static const milk = 'assets/icons/ui/milk.svg';
  static const coffee = 'assets/icons/ui/coffee.svg';
  static const cookie = 'assets/icons/ui/cookie.svg';
  static const croissant = 'assets/icons/ui/croissant.svg';
  static const cakeSlice = 'assets/icons/ui/cake-slice.svg';
  static const candy = 'assets/icons/ui/candy.svg';
  static const sandwich = 'assets/icons/ui/sandwich.svg';
  static const pizza = 'assets/icons/ui/pizza.svg';
  static const utensils = 'assets/icons/ui/utensils.svg';
  static const apple = 'assets/icons/ui/apple.svg';
  static const egg = 'assets/icons/ui/egg.svg';
  static const wheat = 'assets/icons/ui/wheat.svg';
  static const beer = 'assets/icons/ui/beer.svg';
  static const shoppingBag = 'assets/icons/ui/shopping-bag.svg';
}

/// A Lucide icon at the brand's stroke. Colour follows [color], else the current icon theme.
class AbyIcon extends StatelessWidget {
  const AbyIcon(this.asset, {super.key, this.size = 24, this.color, this.semanticLabel});
  final String asset;
  final double size;
  final Color? color;
  /// Give a label only when the icon is the only thing on a control.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final icon = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      excludeFromSemantics: semanticLabel == null,
      semanticsLabel: semanticLabel,
    );
    return icon;
  }
}
