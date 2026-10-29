# Aby brand guide

**Sell anyway.** · Version 2 · October 2026

The living version of this guide is the Aby design system. When the two differ, the design system wins.

## Contents

1. [The idea](#01-the-idea)
2. [Logo](#02-logo)
3. [Colour](#03-colour)
4. [Typography](#04-typography)
5. [Layout, touch and shape](#05-layout-touch-and-shape)
6. [Product photos](#06-product-photos)
7. [Iconography](#07-iconography)
8. [Components](#08-components)
9. [Screen patterns](#09-screen-patterns)
10. [Messages](#10-messages)

## 01 The idea

Aby is a point-of-sale system for small shops: ice cream shops first, then retail and restaurants. It keeps selling when the light goes off and the network drops, and catches up when the connection returns. The brand is built on that one idea: **the waiting dot**, a sale saved on the device, waiting to sync.

**Tagline:** Sell anyway.

### Brand essence

- **Dependable.** Aby works offline, through power cuts, on a cheap tablet. Every design choice favours "works every time" over "looks clever".
- **Quietly smart.** It saves, syncs and counts in the background, and only speaks up when the shop owner needs to act.
- **Plain-spoken.** Shop owners are busy and cashiers are standing. Short words, big numbers.

### Voice

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

## 02 Logo

The mark is a lowercase **a** drawn as a loop with a gap. In the gap sits a **lime dot**: the sale saved on the device, waiting to rejoin. When it syncs, the letter is complete.

- Use `aby-lockup.svg` (mark + "aby" wordmark) for the landing page, signs and documents; `aby-mark.svg` alone for app headers and favicons; `aby-app-icon.svg` for the Play Store and home screen.
- On `midnight` use the reversed files (`aby-mark-reversed.svg`, `aby-lockup-reversed.svg`).
- On receipts, stamps and one-colour print use `aby-mark-mono.svg` (pure black; the dot stays, in black).
- The dot is always lime in colour versions. Never recolour it, move it, enlarge it or remove it.
- The wordmark is always lowercase "aby", drawn as outlines; never retype it. It is currently set in Figtree ExtraBold and will be redrawn in King Extra Bold Rounded once that font is licensed.
- Clear space: a quarter of the mark's width on every side. Minimum size: 16px for the mark, 64px wide for the lockup.
- Don't add shadows, outlines or gradients, or place the colour mark on photos.

**Files:** `aby-lockup.svg`, `aby-lockup-reversed.svg`, `aby-lockup-dark.svg`, `aby-mark.svg`, `aby-mark-reversed.svg`, `aby-mark-mono.svg`, `aby-wordmark.svg`, `aby-app-icon.svg` (in the brand kit under `logos/`).

## 03 Colour

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

### Brand colours

| Colour | Hex | Role |
| --- | --- | --- |
| **Midnight** | `#101322` | The brand's dark: logo, app icon, total bar |
| **Volt lime** | `#C8F560` | The waiting dot: Pay, cart counts, the Sale complete check |
| **Chalk** | `#F6F7F2` | The ground every screen sits on |
| **Signal blue** | `#3446E0` | Links, selection, info, focus |
| **Alert coral** | `#FF6B4A` | Alerts, as a fill only |

### All colour tokens

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `surface` | `#f6f7f2` | `#0b0d17` | Page and till background: chalk by day, near-black midnight in dark mode. |
| `surface-raised` | `#ffffff` | `#161929` | Product tiles, cards, the cart panel and sheets. |
| `surface-sunken` | `#ecede6` | `#06070e` | Wells behind grouped controls, the receipt backdrop, empty states. |
| `line` | `#dfe1d8` | `#262a3d` | Hairlines, dividers and resting tile borders. |
| `line-strong` | `#878a7f` | `#6a6f86` | Input and control borders that must hold 3:1 on surface and surface-raised. |
| `ink` | `#101322` | `#f1f3ea` | Primary text and prices, on surface, surface-raised and surface-sunken. |
| `ink-muted` | `#5a5e6b` | `#9ea2b3` | Secondary text, units and metadata, on surface, surface-raised and surface-sunken. |
| `midnight` | `#101322` | `#101322` | The brand's dark: the logo, the app icon ground, the checkout total bar and marketing panels. The same in both themes. |
| `on-midnight` | `#f6f7f2` | `#f1f3ea` | Text on midnight. |
| `lime` | `#c8f560` | `#c8f560` | Volt lime, the waiting dot: the Pay button, the cart count, the unsynced dot, highlights. A fill only; never text on light surfaces. |
| `on-lime` | `#101322` | `#101322` | Text on a lime fill (the Pay button label). Always midnight. |
| `lime-soft` | `#ecfbc9` | `#1f2a0a` | Tinted fills behind lime-ink text: sale complete, synced, offers. |
| `lime-ink` | `#3f5a00` | `#c8f560` | Lime as text and icons, on surface, surface-raised and lime-soft. |
| `primary` | `#101322` | `#f1f3ea` | Primary buttons and the selected tile border: midnight by day, chalk at night. |
| `on-primary` | `#f6f7f2` | `#101322` | Text on a primary fill. |
| `blue` | `#3446e0` | `#9aa5ff` | Signal blue: links, the selected payment chip, info. As text, on surface, surface-raised and blue-soft. |
| `blue-soft` | `#e6e9ff` | `#1b2152` | Selected rows and chips, info notices. |
| `success` | `#3f5a00` | `#c8f560` | Sale complete, synced, in stock: an alias of lime-ink, on the surfaces and lime-soft. Always with a word or check. (alias of `lime-ink`) |
| `success-soft` | `#ecfbc9` | `#1f2a0a` | Background of the sale-complete banner and synced badges. (alias of `lime-soft`) |
| `warning` | `#8a5300` | `#f5b950` | Offline, low stock, waiting to sync. As text, on the surfaces and warning-soft. |
| `warning-soft` | `#fdf0d7` | `#3a2a0b` | Background of offline and low-stock notices. |
| `coral` | `#ff6b4a` | `#ff8a70` | Alert coral as a fill: badges and the void button's icon. Not for text on light surfaces. |
| `danger` | `#c2361b` | `#ff8a70` | Voids, refunds, errors and overdue credit. As text, on the surfaces and danger-soft. Always with a word. |
| `danger-soft` | `#ffe6df` | `#3b1510` | Background of error notices and the void confirmation. |
| `link` | `#3446e0` | `#9aa5ff` | Links: an alias of blue. (alias of `blue`) |
| `receipt-paper` | `#ffffff` | `#f4f4ef` | Thermal receipt previews stay paper-white in both themes. |
| `receipt-ink` | `#111111` | `#111111` | Text on receipt-paper; thermal printers print one ink. |

## 04 Typography

Two families, both open-source (SIL OFL) and bundled in `fonts/`, so the app never needs the internet for fonts.

- **Figtree** for everything on screen. Headlines, titles and totals use it at 800–900 weight and tight tracking (`display`, `title`, `total`); the interface uses `heading`, `tile`, `price`, `body`, `label`, `caption`. Prices use tabular figures.
- **JetBrains Mono** for receipts, reference numbers and MoMo IDs (`receipt`, `receipt-strong`).
- The checkout total is always the largest number on screen, in `total`.
- **King** (Dareco Studio, paid) is planned for the wordmark only, as outlines. Its desktop licence covers logos and print; don't embed it in the app or website without its app or webfont licence.

### Type scale

| Style | Family | Size / line | Weight | Tracking | Sample | Use |
| --- | --- | --- | --- | --- | --- | --- |
| `display` | Figtree | 56px / 56px | 900 | -0.035em | Sell anyway. | Marketing headlines and the landing page hero. |
| `title` | Figtree | 32px / 36px | 800 | -0.02em | Today's sales | Screen titles in the app and back office. |
| `total` | Figtree | 44px / 48px | 900 | -0.03em | GH₵ 2,340.00 | The checkout total and the day's takings: the biggest number on screen. |
| `heading` | Figtree | 20px / 28px | 700 | 0 | Ice cream | Section and category headings, sheet titles. |
| `tile` | Figtree | 17px / 22px | 600 | 0 | Vanilla cone | Product names on quick-tap tiles and cart lines. |
| `price` | Figtree | 17px / 22px | 800 | 0 | GH₵ 15.00 | Prices on tiles and cart lines; use tabular figures. |
| `body` | Figtree | 16px / 24px | 400 | 0 | Add toppings or tap Pay to finish the sale. | Everything else. |
| `label` | Figtree | 13px / 16px | 700 | 0.05em | MOBILE MONEY | Small uppercase labels, badges and table headers. |
| `caption` | Figtree | 13px / 18px | 400 | 0 | Synced 2 minutes ago | Metadata, timestamps and helper text. |
| `receipt` | JetBrains Mono | 12px / 16px | 400 | 0 | 2 x Vanilla cone     30.00 | Receipt lines, reference numbers, MoMo transaction IDs. |
| `receipt-strong` | JetBrains Mono | 14px / 18px | 700 | 0 | TOTAL GH₵ 45.00 | The receipt total and shop name. |

## 05 Layout, touch and shape

- Design for a 10-inch Android tablet held at a counter first, then a phone, then a Windows till.
- Nothing tappable is smaller than `tap-min` (48px); POS buttons and payment chips are `tap-pos` (56px); product tiles are at least `tile-min` (112px).
- Spacing steps are `space-1` to `space-8` on a 4px base. Tile grids use `space-3` gaps; screens use `space-6` gutters.
- Shapes are round, like the mark: `radius-md` for buttons and tiles, `radius-lg` for sheets and cards, `radius-full` for chips and every dot.
- Mostly flat: `shadow-sm` for tiles at rest, `shadow-lg` only for things that float.
- Focus uses `focus-ring` (a page-colour gap, then solid blue). Barcode-scanner focus uses the same ring.

### Spacing, radius and size tokens

| Token | Value | Use |
| --- | --- | --- |
| `space-1` | 4px | Icon-to-label gap. |
| `space-2` | 8px | Inside badges and chips. |
| `space-3` | 12px | Between tiles in the quick-tap grid; between related rows. |
| `space-4` | 16px | Tile and card padding. |
| `space-6` | 24px | Between sections; screen gutters on tablets. |
| `space-8` | 32px | Large separations on marketing pages. |
| `radius-sm` | 8px | Badges, inputs. |
| `radius-md` | 14px | Buttons and product tiles. |
| `radius-lg` | 24px | Sheets, cards, the app icon. |
| `radius-full` | 9999px | Payment chips, pills and dots. |
| `tap-min` | 48px | The smallest thing a finger may hit. |
| `tap-pos` | 56px | Height of POS buttons and payment chips. |
| `tile-min` | 140px | Minimum width of a product tile in the grid view (fits a 4:3 photo, the name and the price). |
| `dot` | 10px | The waiting dot as a UI signal: unsynced sales, new orders, unread. |
| `thumb-row` | 56px | Product photo size in the list view. |
| `icon` | 24px | Icons in the till; 20px in the back office and inside buttons, 16px inline with small text. |

### The dot as a system

The waiting dot is the brand's one repeatable detail. Use it, at `dot` size (10px), wherever something is waiting: unsynced sales (`SyncBadge`), a new order, an unread message, a category marker on product tiles. In marketing it becomes a pattern of discs with a single lime dot among them. Don't use it as decoration where nothing is waiting.

## 06 Product photos

Every product can have a photo; it's what a cashier finds first on a busy till.

- Square photos, at least 400 × 400 px, the product alone and centred on a plain light background (a white plate or the shop counter wiped clean), shot in daylight. Tiles crop them to 4:3, so keep the product in the middle.
- Real products from the shop, never stock photos or pictures off the internet.
- The owner can take the photo with the tablet's camera from the product screen; Aby crops it square and compresses it to WebP under 60 KB.
- Photos are stored on the till, so they show offline. They sync as files when the till is online.
- No photo yet: the tile shows the category's icon on its tint (`ProductTile`), so a new menu still looks finished. Never show a broken image or a grey box.
- The images in the Samples group are drawn stand-ins for these pages and demo data only. Replace them with the shop's own photos.

## 07 Iconography

Aby uses **Lucide** outline icons (ISC licence): 70 of them, chosen for selling, payment, sync, status, navigation, the back office and product categories. See the `Icon` component for the full set and the Icons group for the SVG files.

- 24px grid, 2px stroke, round caps and joins, matching the round strokes of the mark. Never fill them, change the stroke or mix in another icon set.
- Sizes (`icon` token): 24px in the till, 20px in the back office and inside buttons, 16px inline with small text.
- Colour: `ink` for actions, `ink-muted` for supporting icons, a state colour only inside its own state.
- Pair icons with words. Icon-only controls are allowed only for search, close, back, more, plus, minus and the grid/list switch, and each has an accessible label.
- Payment methods always have their icon: `banknote` for cash, `smartphone` for mobile money, `book-open` for the credit book, `credit-card` for card.
- Category icons stand in for missing product photos; every category has one.
- The waiting dot is not an icon. Sync status always uses `SyncBadge`, never a cloud icon on its own.
- No emoji in the interface.

### The icon set

| Group | Icons |
| --- | --- |
| Selling | `shopping-basket`, `plus`, `minus`, `trash`, `pause`, `tag`, `percent`, `search`, `scan-barcode`, `layout-grid`, `list`, `image`, `camera` |
| Payment | `banknote`, `smartphone`, `book-open`, `credit-card`, `wallet`, `hand-coins`, `receipt-text`, `printer`, `send`, `message-circle` |
| Sync | `cloud-check`, `cloud-upload`, `cloud-off`, `refresh-cw` |
| Status | `circle-check`, `info`, `triangle-alert`, `circle-alert`, `undo-2`, `rotate-ccw`, `package`, `package-x`, `bell` |
| Navigation | `chevron-left`, `chevron-right`, `x`, `check`, `ellipsis`, `settings`, `sliders-horizontal`, `log-out`, `lock` |
| Back office | `store`, `tablet-smartphone`, `user`, `users`, `chart-column`, `calendar`, `clock`, `file-text` |
| Categories | `ice-cream-cone`, `ice-cream-bowl`, `cup-soda`, `milk`, `coffee`, `cookie`, `croissant`, `cake-slice`, `candy`, `sandwich`, `pizza`, `utensils`, `apple`, `egg`, `wheat`, `beer`, `shopping-bag` |

## 08 Components

The building blocks of the till and back office. Each one is in the Aby design system with live previews, and in the brand kit for Flutter.

### Product tile (grid view) (`ProductTile`)

The quick-tap tile for the grid view: one tap adds one item to the cart. A 4:3 product photo on top, then name, size (or stock), and price. The category dot sits on the photo's corner; a lime count shows how many are in the cart.

- Provide `name`, `price` (cedis), optional `detail` (size or flavour), `count`, `tone`, `image` (photo URL) and `icon`.
- No photo yet: the tile shows the category's icon on its tint, so a new menu still looks finished. `icon` overrides the default per tone (`ice-cream-cone`, `candy`, `cup-soda`, `cookie`).
- Tone by category, the same everywhere in a shop: `midnight` for cones and cups, `lime` for toppings and extras, `blue` for drinks, `coral` for snacks. The owner picks; four categories at most get a colour.
- Tiles sit in a grid at least `tile-min` (140px) wide with `space-3` gaps. Never shrink them to fit more; scroll the category, or switch to the list view.
- Names stay short (two lines at most); put sizes in `detail`, not the name.
- Low stock: pass `left`. The tile shows "3 left" in `warning` in place of the size; at 0 it reads "Out of stock", the photo greys out, and the tile stays tappable.

### Product row (list view) (`ProductRow`)

The same product as a `ProductTile`, laid out as a row for the list view: 56px photo, name with category dot, size or stock, price, and a lime count once it's in the cart (a plus until then). One tap adds one item, exactly like the tile.

- Takes the same props as `ProductTile`: `name`, `price`, `detail`, `left`, `count`, `tone`, `image`, `icon`.
- Use the list view on phones, for long menus (a supermarket's hundreds of items) and for cashiers who find things by name. Rows sit `space-2` apart.

### Grid and list switch (`ViewToggle`)

Switches the product area between the grid (`ProductTile`) and the list (`ProductRow`). It sits at the right end of the category header.

- `value`: `grid` or `list`; `onChange` gets the new value.
- Default to grid on tablets and Windows tills, list on phones. Remember each device's choice; it's a cashier preference, not a shop setting.
- Both views show the same products in the same order with the same tap behaviour, so switching never changes how a sale is rung up.

### Buttons (`Button`)

Big, plain buttons for a counter, not a desk. Default height is `tap-pos` (56px); use `size="md"` only in the back office.

- `pay` (volt lime, midnight label) appears once per screen, for finishing the sale: "Pay GH₵ 45.00". Lime is reserved for this and the waiting dot, so it always means "money moves now".
- `primary` (midnight by day, chalk at night) for the main action everywhere else: "Add to cart", "Save product".
- `quiet` for secondary actions: "Hold sale", "Discount".
- `danger` for voids and refunds; it always asks for confirmation and logs the cashier.

Labels are verb first, sentence case, no exclamation marks. The consumer provides the label and `onClick`.
- `icon` adds a leading icon (20px, 18px at `md`): `plus` for Add, `pause` for Hold, `undo-2` for Void, `printer` for Print. The Pay button has no icon; the amount is its label.

### Icon (`Icon`)

Aby's icons: 70 Lucide icons (ISC licence) chosen for selling, payment, sync, status, navigation, the back office and product categories. Outline, 24px grid, 2px stroke, round caps and joins, which echo the round strokes of the mark.

- `name` is the Lucide name shown under each icon. `size`: 24 in the till, 20 in the back office and inside buttons, 16 inline with small text.
- Colour follows CSS `color`: `ink` for actions, `ink-muted` for supporting icons, a state colour only inside its own state (a warning icon in a warning banner).
- Icons are decorative by default. Give a `label` when the icon is the only thing on the control.
- Pair icons with words. Icon-only controls are allowed for search, close, back, more, the grid/list switch, plus and minus; everything else gets a label.
- Use the icon set below rather than drawing new ones. Need one that isn't here? Take it from Lucide at the same stroke, and add it to this set.

### Payment chips (`PaymentChip`)

Choose how the customer pays. Show all three in a row on the checkout sheet, as a radio group; one is always selected (Cash by default). The selected chip is signal blue, so it never competes with the lime Pay button.

- `cash`, `momo` (mobile money: MTN MoMo, Telecel Cash, AT Money) and `credit` (the shop's credit book).
- Choosing `momo` offline asks the cashier for the transaction reference; choosing `credit` asks for the customer.
- Never colour the MoMo chip in a network's brand colour; Aby is neutral between networks.
- Each method carries its icon (`banknote`, `smartphone`, `book-open`, `credit-card`); the selected chip swaps it for a blue check. `card` is available for shops with a card machine.

### Sync badge (`SyncBadge`)

The logo's waiting dot, working: it sits in the till header and says whether every sale has reached the cloud.

- `waiting` = number of sales saved on the device but not yet synced; `offline` = no connection right now.
- With nothing waiting it reads "All synced" on lime-soft. With sales waiting it turns midnight with a pulsing lime dot: "3 sales saved on this device". The pulse stops for people who prefer reduced motion.
- Offline is normal, not an error: never show it in danger colours. Tapping it opens the sync screen.

### Banners (`Banner`)

A notice across the top of a screen or panel, for things the cashier or owner should know but that don't stop the sale. Full rules: Screen patterns.

- `tone`: `offline` (quiet, lime dot; for long sync gaps only, never for normal offline), `info`, `success`, `warning` (low stock), `danger` (money or data at risk, an action that didn't happen).
- Provide the text as children, an optional bold `title`, an optional `action` + `onAction` (one verb, like "Try again"), and `onDismiss` for notices that can be closed.
- Write what happened, what Aby already did, then what to do. Never error codes, never "failed" for being offline.

### Empty states (`EmptyState`)

What a screen or panel shows when it has nothing in it: a title saying what's empty, one line on what to do, at most one action.

- Provide `title`, the line as children, and optionally `action` + `onAction`.
- Set `full` on full-screen empty states only; it adds the mono mark above the title.
- No illustrations, jokes, "Oops" or "Nothing to see here". See Screen patterns for the wording of each empty state.
- `icon` names what's empty in a circle above the title (`shopping-basket` for the cart, `receipt-text` for sales); use it on panels. Full-screen empty states use `full` (the mono mark) instead.

### Confirm sheet (`ConfirmSheet`)

The bottom sheet that asks before anything that moves money or can't be undone: void, refund, delete a product, close the day, unpair a till. Everything else just happens, with an Undo toast.

- `title` is the question naming the thing ("Void sale #00142?"); children are one line on the consequence.
- `confirm` is the danger verb ("Void sale"); `cancel` is the safe way out ("Keep sale"), filled and on the right. Never Yes/No.
- `askReason` adds reason chips (Wrong item, Customer changed mind, Duplicate, Other); the danger button stays disabled until one is picked. Voids and refunds also ask for the cashier's PIN after this sheet.

### Sale complete (`SaleComplete`)

The midnight panel shown the moment a sale is saved. The lime check draws once; nothing else moves.

- Provide `total`, `method` and, for cash, `change` (cedis). Change due is the largest thing on screen, because it's what the cashier acts on.
- "New sale" is the primary action; Print receipt and Send receipt sit below it. Return to the till on your own after 6 seconds if nothing is tapped.
- The check appears without drawing for people who prefer reduced motion.

### 58 mm receipt (`Receipt`)

The 58mm thermal receipt exactly as it prints: one ink, JetBrains Mono, dashed rules. The same layout is sent as an SMS or WhatsApp receipt when there is no printer.

- Provide `shop`, `lines` (`qty`, `name`, `price`), and optionally `address`, `phone`, `date`, `number`, `method`, `reference` and `footer`.
- Keep line names under 18 characters so prices stay in their column; abbreviate sizes ("Choc cup M").
- The shop's name leads; Aby signs off at the bottom with the mono mark and "Powered by Aby", the product's free advertising.

### Message previews (`MessagePreview`)

A preview of a message Aby sends outside the app, for the back office (template settings, "send receipt" confirmations) and for this guide. Full templates and rules: Messages.

- `channel`: `sms` (shows a character count against 160), `whatsapp` (supports `*bold*`, adds the "Sent with Aby" footer) or `push` (with a `title`).
- `from` is the sender shown in the header: the shop's SMS sender ID for customer messages, "Aby" for owner messages.
- SMS bodies use GHS, never GH₵, and plain characters only.

### Mark (`Mark`)

The waiting-dot a as a component, for app headers, the receipt and loading states. It draws with tokens, so it follows the theme.

- `tone="brand"`: `ink` body with the `lime` dot, on surface or surface-raised (midnight by day, chalk at night).
- `tone="reversed"`: chalk body with the lime dot, on `midnight`.
- `tone="mono"`: one ink from CSS `color`, for receipts, stamps and one-colour print.
- The dot is always lime in colour versions; never recolour it, move it, or drop it.
- Never below 16px; give it clear space of a quarter of its width on every side.

## 09 Screen patterns

How Aby's screens behave when something happens: nothing to show, waiting, offline, low stock, errors, confirmations and the finished sale. The rule behind all of them: **never stop a sale**. The till keeps working; the screen tells the cashier only what they need to act on.

### Offline and sync

Offline is the normal state of a shop, not an error.

| Situation | What the screen shows | Component |
| --- | --- | --- |
| Online, everything synced | "All synced" in the header | `SyncBadge` |
| Offline or sales waiting | "3 sales saved on this device", with the pulsing lime dot | `SyncBadge` |
| Not synced for 24 hours | A quiet `Banner` (tone `offline`) at the top of the till: "This till hasn't synced since yesterday, 4:10 pm. Sales are safe here. Connect to the internet when you can." | `Banner` |
| An action needs the internet (pairing, MoMo prompt, sending a WhatsApp receipt) | Say so on that action only: "Pairing needs the internet. Connect, then try again." Queue it if it can wait ("WhatsApp receipt will send when you're online"). | Inline text or `Banner` |

- Never use danger colours, error icons or the word "failed" for being offline.
- Never block the till behind a sync. A sync never shows a full-screen spinner.

### Empty states

Built with `EmptyState`: one line that says what's empty, one line on what to do, and at most one action.

| Where | Title | Line | Action |
| --- | --- | --- | --- |
| Cart | Cart is empty | Tap a product to add it. | none |
| Till, no products yet | No products yet | Add your menu in the back office, or start from the ice cream template. | Use template |
| Category with nothing in it | Nothing in Drinks | Add drinks in the back office. | none |
| Today, no sales | No sales yet today | Your first sale will show here. | none |
| Search, no match | No match for "vanila" | Check the spelling, or search by category. | Clear search |
| Credit book | No one owes you | Sales on credit show here with each customer's balance. | none |

- No illustrations, mascots or jokes. The mark (mono, `ink-muted`) at 40px may sit above the title on full-screen empty states only.
- Never say "Oops", "Uh-oh" or "Nothing to see here".

### Loading

- Local reads (products, cart, today's sales) are instant. Don't show a loader for them; if a list takes longer than 300 ms, show tile-shaped placeholders in `surface-sunken`, never a spinner over the grid.
- Network actions (pairing, MoMo check, back-office reports) show a spinner inside the button that started them, with the label changed to what's happening: "Pairing…", "Checking MoMo…". Keep the rest of the screen usable.
- After 15 seconds, replace the spinner with a plain message and a retry: "This is taking longer than usual. Try again."

### Low stock

- Show it on the product tile, not in a pop-up: a `warning` label "3 left" replaces the size detail. At zero, the tile reads "Out of stock" and stays tappable (the cashier may know there's more in the freezer); adding it shows a one-line note in the cart, never a block.
- The owner gets the low-stock alert (see Messages). The cashier is never interrupted mid-sale.
- "Low" is set per product in the back office; the default is 2 days of the product's usual sales.

### Product views

The product area has two views with the same products, the same order and the same tap behaviour. `ViewToggle` at the right of the category header switches between them.

| View | Component | Best for |
| --- | --- | --- |
| Grid | `ProductTile`: 4:3 photo, name, size, price | Tablets and Windows tills, short menus where photos help (ice cream, café, restaurant) |
| List | `ProductRow`: 56px photo, name, size, price on one line | Phones, long menus (a supermarket's hundreds of items), cashiers who find things by name |

- Default to grid on tablets and tills, list on phones. Remember the choice per device: it's the cashier's preference, not a shop setting.
- Both views keep the category tabs and search above them. A tap always adds one item; a product with sizes or toppings opens the same sheet in either view.
- Don't add a third view or let cashiers resize tiles; two well-made views are easier to learn.

### Errors

Say what happened, what Aby already did, and what to do next, in that order. Use `Banner` with tone `danger` only when money or data is at risk or an action really didn't happen.

| Instead of | Write |
| --- | --- |
| Error 500: Internal server error | We couldn't reach Aby's servers. Your sales are saved on this till. |
| Invalid input | Enter the MoMo reference from the customer's message. |
| Printer error | The printer isn't answering. Check it's on and has paper, then tap Print again. You can send the receipt by SMS instead. |
| Payment failed | MoMo didn't confirm this payment. Ask the customer to check their phone, or take another payment method. |

- Field errors sit under the field in `danger`, in the words above; never only a red border.
- Never show error codes to cashiers. Log them for support instead.

### Confirmations

Ask only before things that move money or can't be undone: void, refund, delete a product, close the day, unpair a till. Everything else just happens, with a short toast and Undo where possible ("Removed Sprinkles. Undo").

Built with `ConfirmSheet`, a bottom sheet:

- The title is the question, naming the thing: "Void sale #00142?"
- One line on the consequence: "GH₵ 58.00 comes off today's takings. Your name and reason go in the log."
- Voids and refunds also ask for a reason (chips: Wrong item, Customer changed mind, Duplicate, Other) and the cashier's PIN.
- The buttons are verbs, never Yes/No: the `danger` action ("Void sale") and a `quiet` way out ("Keep sale"). The safe option is on the right, where the thumb rests.

### Sale complete

Built with `SaleComplete`. Shown on a midnight panel the moment the sale is saved:

- A lime check in a circle, "Sale complete" and the total.
- For cash: **Change GH₵ 12.00** is the largest thing on screen, because it's what the cashier has to act on.
- Actions: **New sale** (the primary action, a chalk button: lime stays for paying), then Print receipt and Send receipt (SMS/WhatsApp). The panel returns to the till on its own after 6 seconds unless the cashier taps something.
- The check draws once in 300 ms; nothing else animates. With reduced motion it appears without drawing.

### Toasts

- For confirmations that need no action: "Product saved", "Receipt sent", "Removed Sprinkles. Undo".
- Bottom centre, midnight with `on-midnight` text, 3 seconds (6 with Undo), one at a time.
- Never use a toast for an error the cashier must fix; use a `Banner` or inline text.

### Cash entry

- The tendered-amount screen shows quick amounts above the keypad: Exact, then the next notes up (for a GH₵ 38.00 sale: Exact, 40, 50, 100, 200).
- Change due updates as the cashier types; if the amount is short, the Complete button stays disabled and the line reads "GH₵ 5.00 more needed".

### First run (owner onboarding)

Three steps, each on one screen, each skippable except the first:

1. **Your shop:** name, business type (Ice cream and café, Retail, Restaurant), phone.
2. **Your products:** start from the business-type template (the ice cream menu), import a list, or add later.
3. **Your till:** pair this device, or open the back office on another device to get a code.

End on the till with the template products loaded, not on a dashboard. Don't show tours or tooltips; the empty states and labels do that work.

### Motion

- Fast and functional: 150–200 ms ease-out for sheets and panels, 100 ms for a tile press (scale to 0.98).
- Only two things animate on their own: the sync dot's pulse while sales wait, and the check on Sale complete.
- Respect reduced motion everywhere: drop the pulse and the draw, keep fades under 150 ms.

## 10 Messages

Every message Aby sends outside the app: receipts and credit reminders to customers, summaries and alerts to shop owners, and account emails. Preview them with the `MessagePreview` component.

### Who the message is from

- **To a shop's customers, the shop speaks.** Receipts, credit reminders and payment confirmations go out in the shop's name and SMS sender ID (up to 11 characters, for example `ScoopsTML`). Aby appears only as the small "Sent with Aby" footer on WhatsApp.
- **To the shop owner, Aby speaks.** Summaries and alerts start with "Aby:" in SMS and come from the Aby WhatsApp number.
- Customers get a message only when they asked for it: a receipt when they give their number for that sale, reminders only if they agreed when they were added to the credit book. Keep that consent on record (Ghana's Data Protection Act, 2012, Act 843). Never send marketing to customers through Aby.

### Channel rules

| Channel | Use for | Rules |
| --- | --- | --- |
| SMS | Receipts, credit reminders, owner alerts when WhatsApp isn't set up | One message of up to 160 characters. Use the GSM-7 character set only: write **GHS**, never GH₵ (the ₵ sign switches the whole SMS to Unicode, cutting it to 70 characters and multiplying the cost). No curly quotes, em dashes or emoji. |
| WhatsApp | Receipts with item lines, the owner's daily summary, alerts | Every message Aby starts is a Meta-approved **utility** template with numbered variables (`{{1}}`). GH₵ is fine. Bold with `*asterisks*` for the total only. Footer "Sent with Aby". |
| Push notification | Owner alerts on the Aby app | Title up to 40 characters, body up to 100. The title names the shop when the owner has more than one. |
| Email | Account only: welcome, pairing, subscription, password | From "Aby". Plain layout: the mark, one heading, short paragraphs, one midnight button. |

### Writing rules

- Same voice as the app: plain, short, number first. Sentence case, no exclamation marks.
- Money: `GH₵ 58.00` on WhatsApp, push and email; `GHS 58.00` in SMS. Always two decimals.
- Dates as `22 Oct`, times as `2:32 pm` (12-hour, lowercase am/pm). Add the weekday in the daily summary: `Thu 22 Oct`.
- Use the customer's first name only. Never put a balance, debt or purchase in a message to anyone but that customer.
- Credit reminders are polite and factual: no "overdue", "final notice" or threats. At most one reminder a week per customer, and only when the owner has turned reminders on.
- Links: every receipt link opens a web receipt (domain to be decided). Budget 25 characters for a link in SMS.

### Templates

Variables are in `{curly_braces}`. Examples use the demo shop.

#### Receipt to customer

**SMS** (127 characters)

```
{shop}: GHS {total} paid by {method}, ref {reference}. Sale #{number}, {date} {time}. Thank you. Receipt: {link}
```

> Scoops Tamale: GHS 58.00 paid by MoMo, ref MP261022.1432. Sale #00142, 22 Oct 2:32 pm. Thank you. Receipt: aby.example/r/7K2Q9X

Drop the `ref` part for cash sales.

**WhatsApp** (template `receipt_v1`, utility)

```
Thank you for buying from {{1}}.

{{2}}
*Total: GH₵ {{3}}*
Paid by {{4}} · Sale #{{5}} · {{6}}

Your receipt: {{7}}
```

> Thank you for buying from Scoops Tamale.
>
> 2 × Vanilla cone — GH₵ 30.00
> 1 × Chocolate cup (M) — GH₵ 25.00
> 1 × Sprinkles — GH₵ 3.00
> **Total: GH₵ 58.00**
> Paid by MoMo · Sale #00142 · 22 Oct, 2:32 pm
>
> Your receipt: aby.example/r/7K2Q9X

`{{2}}` holds the item lines, one per line, at most 10; after that, "and 4 more items".

#### Credit book reminder to customer

**SMS** (144 characters)

```
Hello {first_name}, this is {shop}. Your credit book balance is GHS {balance} (since {date}). Pay at the shop or by MoMo to {momo_number}. Thank you.
```

> Hello Amina, this is Scoops Tamale. Your credit book balance is GHS 45.00 (since 15 Oct). Pay at the shop or by MoMo to 024 000 0000. Thank you.

#### Credit payment received, to customer

**SMS** (106 characters)

```
{shop}: we received GHS {amount} from you. Your credit book balance is now GHS {balance}. Thank you, {first_name}.
```

> Scoops Tamale: we received GHS 45.00 from you. Your credit book balance is now GHS 0.00. Thank you, Amina.

#### Daily summary to owner

Sent at the shop's closing time (set in the back office), or at 9 pm.

**WhatsApp** (template `daily_summary_v1`)

```
*{{1}}* · {{2}}
You sold *GH₵ {{3}}* in {{4}} sales.

Cash GH₵ {{5}} · MoMo GH₵ {{6}} · Credit GH₵ {{7}}
Best seller: {{8}}
Running low: {{9}}
{{10}}

See the day: {{11}}
```

> **Scoops Tamale** · Thu 22 Oct
> You sold **GH₵ 2,340.00** in 96 sales.
>
> Cash GH₵ 1,410.00 · MoMo GH₵ 820.00 · Credit GH₵ 110.00
> Best seller: Vanilla cone (41)
> Running low: Vanilla tub (2), Cones (18)
> 2 sales are still on Till 2, waiting to sync.
>
> See the day: aby.example/d/22oct

`{{10}}` is empty when every till has synced. Leave out the "Running low" line when nothing is low.

**SMS** (138 characters)

```
Aby: {shop}, {date}. GHS {total} from {count} sales. Cash {cash}, MoMo {momo}, Credit {credit}. Best seller: {top_item}. {low_count} items low.
```

> Aby: Scoops Tamale, 22 Oct. GHS 2,340.00 from 96 sales. Cash 1,410.00, MoMo 820.00, Credit 110.00. Best seller: Vanilla cone. 2 items low.

#### Alerts to owner

Each alert is sent once per event, never repeated within the hour. The owner chooses which ones they get.

| Alert | Push title | Message (SMS form) |
| --- | --- | --- |
| Low stock | Running low | Aby: only 2 Vanilla tubs left at Scoops Tamale. You usually sell 6 a day. |
| Till not syncing (over 2 hours) | Till 2 hasn't synced | Aby: Till 2 at Scoops Tamale has not synced since 10:15 am. Its sales are safe on the device. Check its internet or power. |
| Sale voided | Sale voided | Aby: Ama voided sale #00142 (GHS 58.00) at 2:40 pm at Scoops Tamale. Reason: wrong flavour. |
| Cash short at close | Cash count is short | Aby: Scoops Tamale closed GHS 20.00 short. Expected GHS 1,410.00, counted GHS 1,390.00 by Ama. |

The till-not-syncing alert always says the sales are safe. Offline is normal; the owner only needs to act on the connection.

#### Account messages

**Pairing code (SMS)**

> Your Aby pairing code is 482913. It works for 10 minutes. Do not share it with anyone.

**Welcome email**

- Subject: Your shop is ready on Aby
- Body: "Hi {first_name}, {shop} is set up. Pair your first till: open Aby on the tablet, tap **Pair this device**, and enter the code from your back office. It takes about a minute. Your sales stay on the till even when the internet is off, and come to your back office when it's back."
- Button: Open back office

**Subscription renewal email**

- Subject: Your Aby plan renews on {date}
- Body: "Your {plan} plan for {shop} renews on {date} for GH₵ {amount}. Pay by MoMo or card before then to keep syncing. If it lapses, your tills keep selling offline; syncing and reports pause until you renew."

Never threaten to lock a shop out of its own till: Aby keeps selling offline whatever the account state.

## Credits and licences

Figtree (Erik Kennedy) and JetBrains Mono (JetBrains) are used under the SIL Open Font License 1.1. Icons are from Lucide (ISC licence, © Lucide Icons and contributors).

The wordmark is set in Figtree ExtraBold as a stand-in, to be redrawn in King Extra Bold Rounded once licensed.
