import 'package:flutter/painting.dart';

import '../models/enums.dart';
import 'aby_colors.dart';

/// How one category colour is drawn: the [dot] (tabs, tiles, lists), the
/// [tint] behind a product's icon when it has no photo, and the [ink] the
/// icon is drawn in on that tint.
typedef TonePaint = ({Color dot, Color tint, Color ink});

/// Category colours. The first five are brand tokens; the rest extend the
/// set for shops with more categories, at the same weight (the ink holds
/// 4.5:1 on its tint in both themes). Lime stays lime ink: the lime fill is
/// kept for Pay, the waiting dot and cart counts.
TonePaint tonePaint(CategoryTone tone, AbyColors c) {
  final dark = c.surface.computeLuminance() < 0.2;
  Color pick(int light, int night) => Color(dark ? night : light);
  return switch (tone) {
    CategoryTone.midnight => (dot: c.primary, tint: c.surfaceSunken, ink: c.inkMuted),
    CategoryTone.lime => (dot: c.limeInk, tint: c.limeSoft, ink: c.limeInk),
    CategoryTone.blue => (dot: c.blue, tint: c.blueSoft, ink: c.blue),
    CategoryTone.coral => (dot: c.coral, tint: c.dangerSoft, ink: c.danger),
    CategoryTone.amber => (dot: c.warning, tint: c.warningSoft, ink: c.warning),
    CategoryTone.teal => (
        dot: pick(0xFF0F8A7E, 0xFF4FD1C1),
        tint: pick(0xFFD9F3EF, 0xFF0D2E2B),
        ink: pick(0xFF0B6B62, 0xFF4FD1C1),
      ),
    CategoryTone.violet => (
        dot: pick(0xFF7A4FD6, 0xFFB69CFF),
        tint: pick(0xFFECE4FB, 0xFF241A3D),
        ink: pick(0xFF5B34B3, 0xFFB69CFF),
      ),
    CategoryTone.rose => (
        dot: pick(0xFFD6336C, 0xFFFF8FB3),
        tint: pick(0xFFFDE4EC, 0xFF3A1422),
        ink: pick(0xFFB02A5A, 0xFFFF8FB3),
      ),
  };
}
