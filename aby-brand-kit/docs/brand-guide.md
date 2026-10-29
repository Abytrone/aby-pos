Aby is a point-of-sale system for small shops: ice cream shops first, then retail and restaurants. It keeps selling when the light goes off and the network drops, and catches up when the connection returns. The brand is built on that one idea: **the waiting dot**, a sale saved on the device, waiting to sync.

**Tagline:** Sell anyway.

## Brand essence

- **Dependable.** Aby works offline, through power cuts, on a cheap tablet. Every design choice favours "works every time" over "looks clever".
- **Quietly smart.** It saves, syncs and counts in the background, and only speaks up when the shop owner needs to act.
- **Plain-spoken.** Shop owners are busy and cashiers are standing. Short words, big numbers.

## Voice

Write the way a trusted friend who runs a shop would explain things.

- Use "you" for the shop owner and cashier; never "the user" or "the merchant".
- Lead with the number or the action: "Today you sold GH₵ 2,340", not "Your revenue analytics are ready".
- Sentence case everywhere; no exclamation marks in the app (receipt footers may have one).
- Money is always `GH₵ 15.00`: the cedi sign, a space, two decimals, commas for thousands.
- Use the words shops use: "MoMo", "credit book", "light off".
- Offline is normal, not an error: "Saved on this device. Will sync when you're online."

| Instead of | Write |
| --- | --- |
| Transaction failed due to network error | Saved on this device. Will sync when you're online. |
| Insufficient inventory | Only 3 vanilla tubs left |
| Payment method: MTN Mobile Money | Paid by MoMo · Ref MP261022.1432 |
| Are you sure you want to void this transaction? | Void this sale? Your name goes in the log. |

## Logo

The mark is a lowercase **a** drawn as a loop with a gap. In the gap sits a **lime dot**: the sale saved on the device, waiting to rejoin. When it syncs, the letter is complete.

- Use `aby-lockup.svg` (mark + "aby" wordmark) for the landing page, signs and documents; `aby-mark.svg` alone for app headers and favicons; `aby-app-icon.svg` for the Play Store and home screen.
- On `midnight` use the reversed files (`aby-mark-reversed.svg`, `aby-lockup-reversed.svg`).
- On receipts, stamps and one-colour print use `aby-mark-mono.svg` (pure black; the dot stays, in black).
- The dot is always lime in colour versions. Never recolour it, move it, enlarge it or remove it.
- The wordmark is always lowercase "aby", drawn as outlines; never retype it. It is currently set in Figtree ExtraBold and will be redrawn in King Extra Bold Rounded once that font is licensed.
- Clear space: a quarter of the mark's width on every side. Minimum size: 16px for the mark, 64px wide for the lockup.
- Don't add shadows, outlines or gradients, or place the colour mark on photos.

## Colour

Midnight and volt lime carry the brand; chalk is the ground; signal blue does the quiet work.

- Pages sit on `surface` (chalk by day). Tiles and cards are `surface-raised`; grouped wells are `surface-sunken`.
- Text is `ink`; secondary text `ink-muted`. Both read on all three surfaces in both themes.
- `midnight` is the brand's dark in both themes: the logo, the app icon ground, the checkout total bar, marketing panels, with `on-midnight` text.
- `primary` is the main-action fill: midnight by day, chalk at night, with `on-primary` text.
- `lime` is reserved for the moments money moves: the Pay button, the waiting dot, the cart count and the check on Sale complete. It is a fill only; text on it is `on-lime` (always midnight). Lime as text is `lime-ink`.
- `blue` is for links, the selected payment chip, info and the focus ring. Text on `blue-soft` stays `ink`.
- States always pair colour with a word: `success` (an alias of `lime-ink`: sale complete, synced), `warning` (offline, low stock), `danger` (voids, errors, overdue credit), each with its `-soft` background. `coral` is the alert colour as a fill only.
- Never use a mobile network's colours (MTN yellow, Telecel red) anywhere; Aby is neutral between networks.
- Receipt previews always use `receipt-paper` and `receipt-ink`, whatever the theme.

## Typography

Two families, both open-source (SIL OFL) and bundled in `fonts/`, so the app never needs the internet for fonts.

- **Figtree** for everything on screen. Headlines, titles and totals use it at 800–900 weight and tight tracking (`display`, `title`, `total`); the interface uses `heading`, `tile`, `price`, `body`, `label`, `caption`. Prices use tabular figures.
- **JetBrains Mono** for receipts, reference numbers and MoMo IDs (`receipt`, `receipt-strong`).
- The checkout total is always the largest number on screen, in `total`.
- **King** (Dareco Studio, paid) is planned for the wordmark only, as outlines. Its desktop licence covers logos and print; don't embed it in the app or website without its app or webfont licence.

## Layout, touch and shape

- Design for a 10-inch Android tablet held at a counter first, then a phone, then a Windows till.
- Nothing tappable is smaller than `tap-min` (48px); POS buttons and payment chips are `tap-pos` (56px); product tiles are at least `tile-min` (112px).
- Spacing steps are `space-1` to `space-8` on a 4px base. Tile grids use `space-3` gaps; screens use `space-6` gutters.
- Shapes are round, like the mark: `radius-md` for buttons and tiles, `radius-lg` for sheets and cards, `radius-full` for chips and every dot.
- Mostly flat: `shadow-sm` for tiles at rest, `shadow-lg` only for things that float.
- Focus uses `focus-ring` (a page-colour gap, then solid blue). Barcode-scanner focus uses the same ring.

## The dot as a system

The waiting dot is the brand's one repeatable detail. Use it, at `dot` size (10px), wherever something is waiting: unsynced sales (`SyncBadge`), a new order, an unread message, a category marker on product tiles. In marketing it becomes a pattern of discs with a single lime dot among them. Don't use it as decoration where nothing is waiting.

## Product photos

Every product can have a photo; it's what a cashier finds first on a busy till.

- Square photos, at least 400 × 400 px, the product alone and centred on a plain light background (a white plate or the shop counter wiped clean), shot in daylight. Tiles crop them to 4:3, so keep the product in the middle.
- Real products from the shop, never stock photos or pictures off the internet.
- The owner can take the photo with the tablet's camera from the product screen; Aby crops it square and compresses it to WebP under 60 KB.
- Photos are stored on the till, so they show offline. They sync as files when the till is online.
- No photo yet: the tile shows the category's icon on its tint (`ProductTile`), so a new menu still looks finished. Never show a broken image or a grey box.
- The images in the Samples group are drawn stand-ins for these pages and demo data only. Replace them with the shop's own photos.

## Iconography

Aby uses **Lucide** outline icons (ISC licence): 70 of them, chosen for selling, payment, sync, status, navigation, the back office and product categories. See the `Icon` component for the full set and the Icons group for the SVG files.

- 24px grid, 2px stroke, round caps and joins, matching the round strokes of the mark. Never fill them, change the stroke or mix in another icon set.
- Sizes (`icon` token): 24px in the till, 20px in the back office and inside buttons, 16px inline with small text.
- Colour: `ink` for actions, `ink-muted` for supporting icons, a state colour only inside its own state.
- Pair icons with words. Icon-only controls are allowed only for search, close, back, more, plus, minus and the grid/list switch, and each has an accessible label.
- Payment methods always have their icon: `banknote` for cash, `smartphone` for mobile money, `book-open` for the credit book, `credit-card` for card.
- Category icons stand in for missing product photos; every category has one.
- The waiting dot is not an icon. Sync status always uses `SyncBadge`, never a cloud icon on its own.
- No emoji in the interface.
