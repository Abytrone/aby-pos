# Aby brand kit · version 2

Everything from the Aby design system, ready to drop into the code. Midnight `#101322`, volt lime `#c8f560`, chalk `#f6f7f2`; Figtree for the interface, JetBrains Mono for receipts; 70 Lucide icons. The living rules are in the Aby design system; `docs/` has them as a PDF and as markdown.

**New in version 2:** product photos with a category-icon fallback, grid and list views, the icon set, screen patterns, message templates, and Flutter versions of the new components. Product tiles are now at least 140 px wide (was 112).

```
aby-brand-kit/
├── docs/           Aby-brand-guide.pdf (28 pages, to share), and the same rules as markdown:
│                   brand-guide.md, screen-patterns.md, messages.md
├── logos/svg/      mark, reversed, mono, wordmark, lockups (light, dark, on-panel), app icon
├── logos/png/      the same at 256/512/1024 (marks) and 1200 wide (lockups)
├── icons/          app and store icons: app-icon-1024, Android adaptive foreground, Play Store 512,
│                   PWA 192/512, apple-touch-icon-180, favicon.ico / .svg / -32
├── ui-icons/       the 70 interface icons (Lucide, ISC licence), stroke = currentColor
├── samples/        drawn stand-in product photos (svg, and 400 px png) for demo data only
├── fonts/          Figtree (400–900) and JetBrains Mono (400, 700) as static TTFs, the variable
│                   files, and their SIL Open Font Licences
├── tokens/         aby-tokens.json (source of truth) and aby-tokens.css (CSS variables, light + dark)
├── web/            Tailwind v4 theme, Tailwind v3 preset, AbyMark.vue, AbyIcon.vue, aby-icons.json
├── laravel/        Filament panel snippet (logo, favicon, colours, font) and an optional theme CSS
└── flutter/        lib/theme/: colours, ThemeData, icons, widgets; pubspec snippet,
                    flutter_launcher_icons config, main.dart example
```

## Flutter (POS app)

1. Copy into the app:
   - `fonts/*.ttf` (the static ones, not `-Variable`) → `fonts/`
   - `logos/svg/*.svg` → `assets/brand/`
   - `ui-icons/*.svg` → `assets/icons/ui/`
   - `icons/*.png` → `assets/icons/`
   - `samples/png/*.png` → `assets/samples/` (demo shop only)
2. Merge `flutter/pubspec_snippet.yaml` into `pubspec.yaml` (fonts, the three asset folders, flutter_svg, flutter_launcher_icons).
3. Copy `flutter/lib/theme/` into your theme folder (`lib/app/theme/` in the GetX/MVC layout) and use `AbyTheme.light` / `AbyTheme.dark` in `GetMaterialApp`.
4. What's in `lib/theme/`:
   - `aby_theme.dart`: ThemeData, `AbySpace`, `AbyRadius`, `AbySize`, `AbyText`, `abyMoney()`, `AbyPayButton`, `AbySyncBadge`
   - `aby_colors.dart`: every brand colour as `Theme.of(context).extension<AbyColors>()!`
   - `aby_icons.dart`: `AbyIcons.banknote`, `AbyIcons.iceCreamCone` … and `AbyIcon(AbyIcons.plus, size: 20)`
   - `aby_widgets.dart`: `AbyProductTile` and `AbyProductRow` (photo via any `ImageProvider`, e.g. `FileImage` for photos saved on the device), `AbyViewToggle`, `AbyPaymentChip`, `AbyBanner`, `AbyEmptyState`, `showAbyConfirmSheet()`, `AbySaleComplete`
   - `aby_mark.dart`: the logo mark
5. App icons: put `flutter/flutter_launcher_icons.yaml` next to `pubspec.yaml` and run `dart run flutter_launcher_icons -f flutter_launcher_icons.yaml`.

Requires Flutter 3.27 or later. The Dart files were written to match the design system but haven't been compiled here; run `flutter analyze` once after copying them in.

## Laravel + Filament (back office)

1. Copy `logos/svg/*.svg` and `icons/favicon.ico` to `public/brand/`.
2. Merge `laravel/AdminPanelProvider-snippet.php` into each panel provider: logo (light and dark), favicon, Figtree and the Aby colours. Check the method names against your Filament version.
3. Optional: create a Filament theme and add `laravel/filament-theme.css` with `tokens/aby-tokens.css` next to it.
4. Filament's own icons are Heroicons; that's fine inside the back office. Use the `ui-icons/` SVGs wherever you draw your own Aby screens.

## Vue landing page (Tailwind)

1. Copy `tokens/` and `fonts/` into the project side by side (the CSS loads fonts from `../fonts/`).
2. Tailwind v4: `@import "tailwindcss";` then `@import "./web/aby-tailwind-v4.css";`. Tailwind v3: add `web/aby-tailwind-preset.js` to `presets` and import `tokens/aby-tokens.css` once.
3. Utilities: `bg-surface text-ink`, `bg-lime text-on-lime` (the main call to action), `bg-midnight text-on-midnight`, `border-line`, `rounded-md`, `text-total`, `min-w-tile`, `size-thumb`.
4. Logo: `<AbyMark :size="40" />`. Icons: `<AbyIcon name="banknote" />` (needs `aby-icons.json` beside it). Favicon: `icons/favicon.svg` with `favicon.ico` as fallback.
5. Dark mode: `data-theme="dark"` (or `class="dark"`) on `<html>`.

## Rules that matter in code

- Lime only where money moves: the Pay button, the waiting dot, cart counts, the Sale complete check. Text on lime is always midnight (`on-lime`).
- Money is `GH₵ 15.00` in the app and on WhatsApp, but `GHS 15.00` in SMS (the ₵ sign makes an SMS Unicode and cuts it to 70 characters). See `docs/messages.md`.
- Never stop a sale: offline is normal, low stock shows on the tile, errors never block the till. See `docs/screen-patterns.md`.
- Touch targets at least 48 px; POS buttons and chips 56 px; product tiles at least 140 px wide.
- Products without a photo show their category icon, never a broken image.
- The wordmark is outlined SVG; never retype "aby" in a font. It will be redrawn in King once that font is licensed.
