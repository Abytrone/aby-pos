import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_icons.dart';
import '../theme/aby_theme.dart';
import '../theme/category_palette.dart';

/// The asset for a Lucide icon by name ("ice-cream-cone").
String iconAsset(String name) => 'assets/icons/ui/$name.svg';

/// The tint behind a category's icon when a product has no photo.
Color toneTint(CategoryTone tone, AbyColors c) => tonePaint(tone, c).tint;

/// The category icon's colour on its tint.
Color toneIconColor(CategoryTone tone, AbyColors c) => tonePaint(tone, c).ink;

/// A product's picture: its photo, else its category's icon on the
/// category's tint, so a new menu still looks finished. Never a grey box.
class ProductPicture extends StatelessWidget {
  const ProductPicture({
    super.key,
    required this.tone,
    required this.icon,
    this.photo,
    this.iconSize = 32,
    this.dimmed = false,
    this.radius = AbyRadius.sm,
  });

  final CategoryTone tone;

  /// A Lucide icon name (see `Category.picture`).
  final String icon;
  final ImageProvider? photo;
  final double iconSize;

  /// Out of stock: the photo greys out.
  final bool dimmed;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final fallback = Center(
      child: AbyIcon(iconAsset(icon), size: iconSize, color: dimmed ? c.inkMuted : toneIconColor(tone, c)),
    );
    Widget child = fallback;
    if (photo != null) {
      child = Image(
        image: photo!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        // A photo that cannot be read shows the icon, never a broken image.
        errorBuilder: (_, _, _) => fallback,
      );
      if (dimmed) {
        child = Opacity(
          opacity: 0.6,
          child: ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscale), child: child),
        );
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: dimmed && photo == null ? c.surfaceSunken : toneTint(tone, c), child: child),
    );
  }
}

const List<double> _greyscale = [
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];

/// The lime count of how many are in the cart. A white ring keeps it
/// clear of the photo underneath.
class CartCountBadge extends StatelessWidget {
  const CartCountBadge({super.key, required this.count, this.size = 28});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.lime,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.surfaceRaised, width: 2),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: AbyText.family,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: c.onLime,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
