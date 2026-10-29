// Aby ThemeData for Flutter (Material 3). Light and dark.
import 'package:flutter/material.dart';
import 'aby_colors.dart';

abstract final class AbySpace {
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s6 = 24.0, s8 = 32.0;
}

abstract final class AbyRadius {
  static const sm = 8.0, md = 14.0, lg = 24.0;
}

abstract final class AbySize {
  static const tapMin = 48.0; // smallest tappable thing
  static const tapPos = 56.0; // POS buttons and payment chips
  static const tileMin = 112.0; // quick-tap product tiles
  static const dot = 10.0; // the waiting dot as a status signal
}

/// Text styles from the brand's type scale. Height = line height / font size.
abstract final class AbyText {
  static const family = 'Figtree';
  static const mono = 'JetBrains Mono';
  static const display = TextStyle(fontFamily: family, fontSize: 56, height: 1.0, fontWeight: FontWeight.w900, letterSpacing: -1.96);
  static const title = TextStyle(fontFamily: family, fontSize: 32, height: 36 / 32, fontWeight: FontWeight.w800, letterSpacing: -0.64);
  /// [title] on phones, where 32 crowds out the actions beside it.
  static const titleCompact = TextStyle(fontFamily: family, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w800, letterSpacing: -0.48);
  static const total = TextStyle(fontFamily: family, fontSize: 44, height: 48 / 44, fontWeight: FontWeight.w900, letterSpacing: -1.32, fontFeatures: [FontFeature.tabularFigures()]);
  static const heading = TextStyle(fontFamily: family, fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w700);
  static const tile = TextStyle(fontFamily: family, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600);
  static const price = TextStyle(fontFamily: family, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]);
  static const body = TextStyle(fontFamily: family, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400);
  static const label = TextStyle(fontFamily: family, fontSize: 13, height: 16 / 13, fontWeight: FontWeight.w700, letterSpacing: 0.65);
  static const caption = TextStyle(fontFamily: family, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400);
  static const receipt = TextStyle(fontFamily: mono, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w400);
  static const receiptStrong = TextStyle(fontFamily: mono, fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w700);
}

/// Money is always "GH₵ 1,234.00".
String abyMoney(num value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return 'GH₵ $whole.${parts[1]}';
}

abstract final class AbyTheme {
  static ThemeData get light => _build(AbyColors.light, Brightness.light);
  static ThemeData get dark => _build(AbyColors.dark, Brightness.dark);

  static ThemeData _build(AbyColors c, Brightness b) {
    final scheme = ColorScheme(
      brightness: b,
      primary: c.primary,
      onPrimary: c.onPrimary,
      secondary: c.lime,
      onSecondary: c.onLime,
      secondaryContainer: c.limeSoft,
      onSecondaryContainer: c.limeInk,
      tertiary: c.blue,
      onTertiary: c.onPrimary,
      tertiaryContainer: c.blueSoft,
      onTertiaryContainer: c.ink,
      error: c.danger,
      onError: b == Brightness.light ? Colors.white : AbyBrand.midnight,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceSunken,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.lineStrong,
      outlineVariant: c.line,
      inverseSurface: AbyBrand.midnight,
      onInverseSurface: c.onMidnight,
      inversePrimary: c.lime,
      shadow: Colors.black,
      scrim: Colors.black,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AbyRadius.md));
    const buttonText = TextStyle(fontFamily: AbyText.family, fontSize: 17, fontWeight: FontWeight.w800);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.surface,
      fontFamily: AbyText.family,
      extensions: [c],
      textTheme: TextTheme(
        displayLarge: AbyText.display,
        displayMedium: AbyText.total,
        headlineMedium: AbyText.title,
        titleLarge: AbyText.heading,
        titleMedium: AbyText.tile,
        bodyLarge: AbyText.body,
        bodyMedium: AbyText.body,
        bodySmall: AbyText.caption,
        labelLarge: AbyText.label,
        labelMedium: AbyText.caption,
      ).apply(bodyColor: c.ink, displayColor: c.ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size(120, AbySize.tapPos),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          backgroundColor: c.surfaceRaised,
          side: BorderSide(color: c.lineStrong, width: 1.5),
          minimumSize: const Size(120, AbySize.tapPos),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.blue, minimumSize: const Size(AbySize.tapMin, AbySize.tapMin)),
      ),
      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: c.line, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AbyRadius.sm), borderSide: BorderSide(color: c.lineStrong)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AbyRadius.sm), borderSide: BorderSide(color: c.lineStrong)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AbyRadius.sm), borderSide: BorderSide(color: c.blue, width: 2)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        selectedColor: c.blueSoft,
        side: BorderSide(color: c.lineStrong, width: 1.5),
        // Without a colour the label paints white on the light chip.
        labelStyle: TextStyle(fontFamily: AbyText.family, fontSize: 16, fontWeight: FontWeight.w700, color: c.ink),
      ),
      // 13 wraps "Dashboard" in a fifth of a small phone.
      navigationBarTheme: const NavigationBarThemeData(
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontFamily: AbyText.family, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      // Material's 40-pixel side inset leaves a small phone 240 pixels of dialog.
      dialogTheme: const DialogThemeData(
        insetPadding: EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s6),
      ),
    );
  }
}

/// The lime Pay button: once per screen, for finishing the sale.
class AbyPayButton extends StatelessWidget {
  const AbyPayButton({super.key, required this.amount, required this.onPressed});
  final num amount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: c.lime,
        foregroundColor: c.onLime,
        minimumSize: const Size.fromHeight(AbySize.tapPos),
        textStyle: const TextStyle(fontFamily: AbyText.family, fontSize: 19, fontWeight: FontWeight.w800),
      ),
      onPressed: onPressed,
      child: Text('Pay ${abyMoney(amount)}'),
    );
  }
}

/// The waiting dot, working: shows whether every sale has synced.
class AbySyncBadge extends StatelessWidget {
  const AbySyncBadge({super.key, required this.waiting, this.offline = false});
  final int waiting;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final isWaiting = waiting > 0;
    final text = isWaiting
        ? '${waiting == 1 ? '1 sale' : '$waiting sales'}${offline ? ' saved on this device' : ' syncing'}'
        : 'All synced';
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 10, right: 12),
        decoration: BoxDecoration(
          color: isWaiting ? AbyBrand.midnight : c.limeSoft,
          borderRadius: BorderRadius.circular(999),
          border: isWaiting ? Border.all(color: c.line) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: AbySize.dot,
            height: AbySize.dot,
            decoration: BoxDecoration(color: isWaiting ? c.lime : c.limeInk, shape: BoxShape.circle),
          ),
          const SizedBox(width: AbySpace.s2),
          Text(text,
              style: TextStyle(
                fontFamily: AbyText.family,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isWaiting ? c.onMidnight : c.limeInk,
              )),
        ]),
      ),
    );
  }
}
