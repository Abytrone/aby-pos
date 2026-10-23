# Aby brand kit

Everything from the Aby design system, ready to drop into the code. Midnight `#101322`, volt lime `#c8f560`, chalk `#f6f7f2`; Figtree for the interface, JetBrains Mono for receipts. The full rules live in the Aby Brand design system; this kit is the code side of it.

```
aby-brand-kit/
├── logos/svg/      mark, reversed, mono, wordmark, lockups (light, dark, on-panel), app icon
├── logos/png/      the same at 256/512/1024 (marks) and 1200 wide (lockups)
├── icons/          app-icon-1024, Android adaptive foreground, Play Store 512, PWA 192/512,
│                   apple-touch-icon-180, favicon.ico / favicon.svg / favicon-32
├── fonts/          Figtree (400–900) and JetBrains Mono (400, 700) as static TTFs, plus the
│                   variable files and their SIL Open Font Licences
├── tokens/         aby-tokens.json (source of truth) and aby-tokens.css (CSS variables, light + dark)
├── web/            Tailwind v4 theme, Tailwind v3 preset, AbyMark.vue
├── laravel/        Filament panel snippet (logo, favicon, colours, font) and an optional theme CSS
└── flutter/        lib/theme/ (colours, ThemeData, Pay button, sync badge, mark widget),
                    pubspec snippet, flutter_launcher_icons config, main.dart example
```

## Laravel + Filament (back office)

1. Copy `logos/svg/*.svg` and `icons/favicon.ico` to `public/brand/`.
2. Merge `laravel/AdminPanelProvider-snippet.php` into your panel provider: brand logo (light and dark), favicon, Figtree, and the Aby colours (primary = midnight, info = blue, success = lime ink, warning, danger).
3. Optional: for chalk backgrounds and a lime Pay action, create a Filament theme and add `laravel/filament-theme.css` with `tokens/aby-tokens.css` next to it.

## Vue landing page (Tailwind)

1. Copy `tokens/` and `fonts/` into the project, keeping them side by side (the CSS loads fonts from `../fonts/`).
2. Tailwind v4: `@import "tailwindcss";` then `@import "./web/aby-tailwind-v4.css";` in your main CSS. Tailwind v3: add `web/aby-tailwind-preset.js` to `presets` and import `tokens/aby-tokens.css` once.
3. Use the colours as utilities: `bg-surface text-ink`, `bg-lime text-on-lime` (the Pay/CTA button), `bg-midnight text-on-midnight`, `text-ink-muted`, `border-line`, `rounded-md`, `text-total`.
4. Dark mode: put `data-theme="dark"` (or `class="dark"`) on `<html>`.
5. Logo: `<AbyMark :size="40" />` from `web/AbyMark.vue`, or `<img src="/brand/aby-lockup.svg">`. Favicon: `icons/favicon.svg` with `favicon.ico` as fallback.

## Flutter (POS app)

1. Copy `fonts/*.ttf` (static ones) to `fonts/`, `logos/svg/*.svg` to `assets/brand/`, `icons/*.png` to `assets/icons/`.
2. Merge `flutter/pubspec_snippet.yaml` into `pubspec.yaml` (fonts, assets, flutter_svg, flutter_launcher_icons).
3. Copy `flutter/lib/theme/` into `lib/theme/` and set `theme: AbyTheme.light, darkTheme: AbyTheme.dark` (see `main_example.dart`).
4. Brand colours not in Material's scheme: `Theme.of(context).extension<AbyColors>()!.lime`, `.limeInk`, `.warning` and so on.
5. Ready-made: `AbyPayButton(amount: 45, onPressed: ...)`, `AbySyncBadge(waiting: 3, offline: true)`, `AbyMark(size: 32)`, and `abyMoney(1234)` → `GH₵ 1,234.00`.
6. App icons: put `flutter/flutter_launcher_icons.yaml` next to `pubspec.yaml` and run `dart run flutter_launcher_icons -f flutter_launcher_icons.yaml`.

Requires Flutter 3.27 or later (Dart 3, `CardThemeData`).

## Rules that matter in code

- Lime is only for the Pay button, the waiting dot and cart counts. Text on lime is always midnight (`on-lime`).
- Money is always `GH₵ 15.00`. Use `abyMoney()` in Flutter.
- Touch targets: at least 48px; POS buttons and chips 56px; product tiles at least 112px.
- The wordmark is outlined SVG; never retype "aby" in a font. It will be replaced when it's redrawn in King.
