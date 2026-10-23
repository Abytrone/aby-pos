// Aby brand colours, generated from aby-tokens.json. Do not edit by hand.
import 'package:flutter/material.dart';

/// Brand-fixed colours (the same in light and dark).
abstract final class AbyBrand {
  static const midnight = Color(0xFF101322);
  static const lime = Color(0xFFC8F560);
  static const chalk = Color(0xFFF6F7F2);
  static const blue = Color(0xFF3446E0);
  static const coral = Color(0xFFFF6B4A);
}

/// Semantic colours per theme, available as Theme.of(context).extension<AbyColors>()!.
@immutable
class AbyColors extends ThemeExtension<AbyColors> {
  const AbyColors({required this.surface, required this.surfaceRaised, required this.surfaceSunken, required this.line, required this.lineStrong, required this.ink, required this.inkMuted, required this.midnight, required this.onMidnight, required this.lime, required this.onLime, required this.limeSoft, required this.limeInk, required this.primary, required this.onPrimary, required this.blue, required this.blueSoft, required this.success, required this.successSoft, required this.warning, required this.warningSoft, required this.coral, required this.danger, required this.dangerSoft, required this.receiptPaper, required this.receiptInk,});

  final Color surface;
  final Color surfaceRaised;
  final Color surfaceSunken;
  final Color line;
  final Color lineStrong;
  final Color ink;
  final Color inkMuted;
  final Color midnight;
  final Color onMidnight;
  final Color lime;
  final Color onLime;
  final Color limeSoft;
  final Color limeInk;
  final Color primary;
  final Color onPrimary;
  final Color blue;
  final Color blueSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color coral;
  final Color danger;
  final Color dangerSoft;
  final Color receiptPaper;
  final Color receiptInk;

  static const light = AbyColors(
    surface: Color(0xFFF6F7F2),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFECEDE6),
    line: Color(0xFFDFE1D8),
    lineStrong: Color(0xFF878A7F),
    ink: Color(0xFF101322),
    inkMuted: Color(0xFF5A5E6B),
    midnight: Color(0xFF101322),
    onMidnight: Color(0xFFF6F7F2),
    lime: Color(0xFFC8F560),
    onLime: Color(0xFF101322),
    limeSoft: Color(0xFFECFBC9),
    limeInk: Color(0xFF3F5A00),
    primary: Color(0xFF101322),
    onPrimary: Color(0xFFF6F7F2),
    blue: Color(0xFF3446E0),
    blueSoft: Color(0xFFE6E9FF),
    success: Color(0xFF3F5A00),
    successSoft: Color(0xFFECFBC9),
    warning: Color(0xFF8A5300),
    warningSoft: Color(0xFFFDF0D7),
    coral: Color(0xFFFF6B4A),
    danger: Color(0xFFC2361B),
    dangerSoft: Color(0xFFFFE6DF),
    receiptPaper: Color(0xFFFFFFFF),
    receiptInk: Color(0xFF111111),
  );

  static const dark = AbyColors(
    surface: Color(0xFF0B0D17),
    surfaceRaised: Color(0xFF161929),
    surfaceSunken: Color(0xFF06070E),
    line: Color(0xFF262A3D),
    lineStrong: Color(0xFF6A6F86),
    ink: Color(0xFFF1F3EA),
    inkMuted: Color(0xFF9EA2B3),
    midnight: Color(0xFF101322),
    onMidnight: Color(0xFFF1F3EA),
    lime: Color(0xFFC8F560),
    onLime: Color(0xFF101322),
    limeSoft: Color(0xFF1F2A0A),
    limeInk: Color(0xFFC8F560),
    primary: Color(0xFFF1F3EA),
    onPrimary: Color(0xFF101322),
    blue: Color(0xFF9AA5FF),
    blueSoft: Color(0xFF1B2152),
    success: Color(0xFFC8F560),
    successSoft: Color(0xFF1F2A0A),
    warning: Color(0xFFF5B950),
    warningSoft: Color(0xFF3A2A0B),
    coral: Color(0xFFFF8A70),
    danger: Color(0xFFFF8A70),
    dangerSoft: Color(0xFF3B1510),
    receiptPaper: Color(0xFFF4F4EF),
    receiptInk: Color(0xFF111111),
  );

  @override
  AbyColors copyWith({Color? surface, Color? surfaceRaised, Color? surfaceSunken, Color? line, Color? lineStrong, Color? ink, Color? inkMuted, Color? midnight, Color? onMidnight, Color? lime, Color? onLime, Color? limeSoft, Color? limeInk, Color? primary, Color? onPrimary, Color? blue, Color? blueSoft, Color? success, Color? successSoft, Color? warning, Color? warningSoft, Color? coral, Color? danger, Color? dangerSoft, Color? receiptPaper, Color? receiptInk,}) => AbyColors(
        surface: surface ?? this.surface,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        surfaceSunken: surfaceSunken ?? this.surfaceSunken,
        line: line ?? this.line,
        lineStrong: lineStrong ?? this.lineStrong,
        ink: ink ?? this.ink,
        inkMuted: inkMuted ?? this.inkMuted,
        midnight: midnight ?? this.midnight,
        onMidnight: onMidnight ?? this.onMidnight,
        lime: lime ?? this.lime,
        onLime: onLime ?? this.onLime,
        limeSoft: limeSoft ?? this.limeSoft,
        limeInk: limeInk ?? this.limeInk,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        blue: blue ?? this.blue,
        blueSoft: blueSoft ?? this.blueSoft,
        success: success ?? this.success,
        successSoft: successSoft ?? this.successSoft,
        warning: warning ?? this.warning,
        warningSoft: warningSoft ?? this.warningSoft,
        coral: coral ?? this.coral,
        danger: danger ?? this.danger,
        dangerSoft: dangerSoft ?? this.dangerSoft,
        receiptPaper: receiptPaper ?? this.receiptPaper,
        receiptInk: receiptInk ?? this.receiptInk,
      );

  @override
  AbyColors lerp(ThemeExtension<AbyColors>? other, double t) {
    if (other is! AbyColors) return this;
    return AbyColors(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      midnight: Color.lerp(midnight, other.midnight, t)!,
      onMidnight: Color.lerp(onMidnight, other.onMidnight, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      onLime: Color.lerp(onLime, other.onLime, t)!,
      limeSoft: Color.lerp(limeSoft, other.limeSoft, t)!,
      limeInk: Color.lerp(limeInk, other.limeInk, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      blueSoft: Color.lerp(blueSoft, other.blueSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerSoft: Color.lerp(dangerSoft, other.dangerSoft, t)!,
      receiptPaper: Color.lerp(receiptPaper, other.receiptPaper, t)!,
      receiptInk: Color.lerp(receiptInk, other.receiptInk, t)!,
    );
  }
}
