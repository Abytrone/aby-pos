# Aby POS: feature specification

Status: draft for review · Last updated: 23 October 2026

This document lists every feature planned for the Aby till app, how each one works, and the order to
build them in. Each feature has an ID (for example `SEL-04`) so phases, tickets and commits can refer
to it.

Tags:

- **[Standard]**: what shop owners expect from any serious POS.
- **[Beyond]**: what sets Aby apart. Usually it solves something specific to small Ghanaian shops
  (power cuts, MoMo, credit books, shared phones, no IT support).
- **[Built]**: already in the app, maybe in a basic form that this spec extends.

---

## 1. Principles

These apply to every feature below. When a feature conflicts with one of them, the principle wins.

1. **Complete without the internet.** Every feature, including all owner and manager tools, works
   on the device with no server. Aby Cloud (section 17) is an optional extra for backup, remote
   viewing and multi-branch. A shop must be able to run Aby for years without ever connecting.
2. **The device is the source of truth.** The local database is the record. Sync copies it; it
   never decides what happened.
3. **Nothing is lost, nothing is overwritten.** Money and stock are ledgers (append-only
   movements). Edits create new versions. Deletes are soft. Every sensitive action is in the audit
   log (`STF-06`).
4. **Survives power cuts.** Every write is a single transaction. Pulling the plug mid-sale leaves
   either a complete sale or no sale. The app reopens where it was (open cart, open shift).
5. **Fast at the counter.** A common sale takes three taps or fewer. Selling screens never wait
   on anything slower than the local database.
6. **The owner is in control.** Every rule (discount limits, who can refund, rounding, tax, receipt
   text) is a setting the owner can change on the device, not a code change.
7. **Plain words.** "Short by GH₵ 7.00", not "Variance: -700". No jargon, no emoji. Copy follows the
   brand voice.
8. **Money in pesewas, IDs as UUID v7, every syncable row has the sync columns.** (Already the
   case.)

---

## 2. App structure and design

The current app is a till plus a few screens. The new structure is two workspaces in one app, with
a shared shell.

### APP-01 Shell and navigation [Standard]

- **Two workspaces:**
  - **Sell**: till, open orders, checkout, refunds and the customer lookup a cashier needs.
  - **Manage**: everything else: dashboard, products, stock, customers, staff, cash, reports,
    settings.
- **Tablet and desktop (landscape, 840 px and wider):** a slim navigation rail on the left, with
  an icon and short label for each section. Sell is always the first item. The rail collapses to
  icons only on 10-inch tablets.
- **Phone:** a bottom bar with the top 4 sections plus "More".
- **Visibility follows the user's permissions.** A cashier with no Manage rights sees only Sell,
  Today and their own shift.
- **The header is the same everywhere:** shop name, a branch badge (when there is more than one
  branch), the sync/backup status (`DAT-05`), and the signed-in person with the lock button.
- **Layout pattern for every list screen:** list on the left and detail on the right on tablets;
  a pushed detail page on phones. The same filter bar everywhere (search, chips, date range).

### APP-02 Owner home dashboard [Standard]

The first screen of Manage, with live cards that update as sales happen on this device or hub:

- Sales today, compared with the same weekday last week.
- Number of sales and average sale value.
- Takings by payment method.
- Top 5 products today.
- An hour-by-hour sales strip.
- Shift status: open or closed, who is on, cash expected in the drawer.
- Alerts: low stock, credit payments due, backup not done, day not closed yesterday.
- Insight cards (`REP-08`).

Owners can reorder or hide cards. The layout is saved per user.

### APP-03 Universal search / command bar [Beyond]

- Opened by the search icon in the header, or `Ctrl+K` on Windows.
- One box searches products, customers, sales by number or MoMo reference, staff and settings.
- Results are grouped by type. Each one has a quick action:
  - Product: "Add to cart" or "Edit product".
  - Customer: "Add to sale" or "Record payment".
  - Sale: "Reprint" or "Refund".
- It also finds actions by name: "close day", "add expense", "receive stock".
- Results respect permissions: a cashier never sees "Edit product".

### APP-04 Business-type templates [Beyond]

- Setup (`SET-01`) starts by asking what kind of shop this is: ice cream / cold store, provision
  shop, chop bar / restaurant, pharmacy shop, salon / barber, phone and accessories, boutique,
  building materials, or other.
- Each template sets up:
  - Sample categories and modifiers.
  - Which features are switched on (feature flags).
  - Defaults such as order types, unit of measure and whether to track expiry dates.
- For example, a chop bar gets order types and kitchen tickets; a provision shop gets barcode
  scanning and expiry tracking; an ice cream shop gets modifier groups for sizes and toppings, and
  recipes.
- Every feature can still be switched on or off later in Settings → Features.

### APP-05 Training mode [Beyond]

- A switch (owner only, or on a staff member's profile) that puts the till in a sandbox.
- A yellow "Training" band shows on every screen.
- Sales, refunds and stock movements go to a separate training database, never to the real
  books, reports or sync.
- Used to train new cashiers on real products without polluting the numbers. "Reset training data"
  clears it.

### APP-06 Languages [Beyond]

- The interface is in English first. All strings live in translation files from day one.
- Planned languages: Twi, Ga, Ewe, Dagbani and Hausa. Dagbani and Hausa matter for Tamale.
- Each user chooses their language on their profile, so the till switches when a different
  cashier signs in.
- Receipts use the shop's chosen receipt language.

### APP-07 Accessibility and comfort [Standard]

- Large-text mode.
- High-contrast mode (the brand dark theme plus stronger lines).
- Left-handed till layout, with the cart on the left.
- Sound on tap and on scan (can be switched off).
- Haptic feedback on phones.
- Every control has a screen-reader label.
- Touch targets stay at 48 px or more (56 px for POS actions).

---

## 3. Selling (Sell workspace)

### SEL-01 Product grid [Built → extend]

What exists today: category tabs, quick-tap tiles, a size and topping sheet. This extends it with:

- **Favourites:** a first tab called "Quick" with the products each shop pins. Tiles can be
  reordered by drag-and-drop in edit mode.
- **Tile size options:** small, medium or large. Shown with the product photo, or a colour block
  and initials when there is no photo.
- **Stock on the tile:** a small "12 left" when stock is tracked. Out-of-stock tiles are dimmed but
  can still be sold if the setting allows it, with a warning.
- **Search inside the grid:** typing on a hardware keyboard filters straight away.
- **Recent items:** the last 8 products sold on this till, as a tab.

### SEL-02 Modifier groups [Standard]

These replace today's fixed "variants + toppings" with a general system.

- **A modifier group** has a name ("Size", "Toppings", "Sugar level", "Extra protein"), a list of
  options, each with a price change (+GH₵ 3, or +GH₵ 0), and rules:
  - Required or optional.
  - Pick exactly one (for example, size).
  - Pick between a minimum and a maximum (for example, up to 3 toppings).
  - Allow the same option more than once (for example, a double topping).
- **A product** has any number of groups, in order. One group can be marked "price-setting": its
  option sets the base price (a cone is GH₵ 15 single, GH₵ 22 double).
- **The picker sheet** shows the groups in order and checks the rules as you go. The "Add"
  button shows the running price and stays disabled until every required group is answered.
- **Defaults:** each group can preselect an option. Products where every group has a default are
  added with one tap; a long press opens the picker.
- **Sold lines** store the chosen options as a snapshot (name and price), as they do today.

### SEL-03 Barcode and code entry [Standard]

- **Scanners:** USB or Bluetooth scanners that act as a keyboard are detected, and a scan adds
  the product. The camera can scan on phones and tablets (a "Scan" button).
- **Codes:** each product or variant can have several barcodes (EAN-13, UPC, Code 128 or the
  shop's own).
- **Unknown barcode:** opens "New product with this barcode" (if the user has permission) or
  shows "Not found".
- **Price-embedded barcodes** (weighed goods from a scale): the prefix and format are set in
  Settings. The weight or price is read from the code.
- **PLU / quick codes:** typing a short code (for example "12") then Enter adds that product.

### SEL-04 Quantity, weight and open price [Standard]

- **Quantity keypad:** type `3` then tap a product to add 3. Or tap a line in the cart to set its
  quantity.
- **Sold by weight or volume:** units are piece, kg, g, litre or ml. A weight entry dialog
  appears, or the weight is read from a connected scale (`HW-04`). Prices are per unit and line
  totals round to the pesewa.
- **Open-price products:** the price is entered at sale ("Miscellaneous", "Repairs"). There's an
  optional minimum and maximum, and permission controls who can use it.

### SEL-05 Cart actions [Standard]

On each line:

- Quantity stepper.
- Remove.
- Note (for example "no nuts"), printed on order tickets.
- Line discount (`SEL-06`).
- Price override (needs permission and is recorded in the audit log).
- Swap modifier options.

On the whole cart:

- Order discount.
- Attach a customer.
- Order type (takeaway / eat-in / delivery), if switched on.
- Order note.
- Clear the cart (asks for confirmation when there are more than 3 lines).

The cart survives a crash or power cut: it's saved to the database as you build it.

### SEL-06 Discounts and promotions [Standard + Beyond]

- **Manual discounts:** a percentage or an amount, on a line or the whole order. Each needs a
  reason picked from a list the owner manages ("Staff", "Damaged", "Regular customer").
- **Limits by role:** for example, a cashier can give up to 10%. Anything above asks for an owner
  or manager PIN (`STF-03`).
- **Saved discounts:** named, reusable ones ("Student 10%", "Staff meal GH₵ 5 off").
- **Automatic promotions [Beyond]**, which apply themselves when their conditions are met:
  - Buy X get Y ("Buy 2 cups, get sprinkles free").
  - Bundle price ("Cone + milkshake GH₵ 32").
  - Time-based ("Happy hour 2–4 pm: 15% off cups"), with days of the week.
  - Quantity breaks ("6 or more tubs: GH₵ 55 each").
  - Spend threshold ("Spend GH₵ 100, get a free waffle").
  - Each promotion has a start and end date, branches, and whether it can stack with others.
- **The best deal is applied automatically** when several promotions could apply. The cart shows
  the promotion name on the line ("Happy hour −GH₵ 3.75") so the cashier can explain it.
- **Reporting:** every discount is stored on the line with its source (manual, promotion ID,
  coupon), so reports show what discounts cost.

### SEL-07 Hold, park and open orders [Standard]

- **Park:** saves the cart under a name or number ("Blue shirt", "Table 4") and starts a new one.
  Parked orders show as tabs above the cart with a count.
- **Open orders:** the same thing for restaurants. An order can be added to over time and paid at
  the end. Orders can be moved between tables and merged.
- **Other tills:** parked orders are stored in the database, so they show on any till connected to
  the same hub (`MDV-01`).
- **Old orders:** parked orders older than a set time show a warning at close day.

### SEL-08 Payments [Built → extend]

What exists today is one payment per sale: cash, MoMo or credit. This extends it with:

- **Split payments:** any mix, for example GH₵ 20 cash + GH₵ 30 MoMo + the rest on credit. The
  remaining balance updates after each payment.
- **Payment methods the owner can configure:** cash, MTN MoMo, Telecel Cash, AT Money, bank
  transfer, card (external terminal), cheque, credit (customer account), store credit / wallet,
  gift voucher. Each one can be switched on or off, renamed, and have fields:
  - Required reference (MoMo).
  - Shop's merchant number shown to the customer.
  - Whether it counts as cash in the drawer.
- **MoMo flow:**
  - The screen shows the shop's MoMo number or merchant ID large, with a QR code, for the
    customer to pay.
  - The cashier enters the transaction ID from the SMS. The last 4 digits are enough when the
    "short reference" setting is on.
  - The reference must be unique: a duplicate is flagged ("This reference was already used on sale
    #00142"). This stops the same SMS being reused.
  - Later, an optional MoMo API confirms payment automatically (`INT-02`).
- **Cash:**
  - Quick note buttons in cedi denominations: exact, then GH₵ 5 / 10 / 20 / 50 / 100 / 200, rounded
    up.
  - **Cash rounding [Beyond]:** an optional rounding of cash totals to the nearest 10 pesewas, or
    to GH₵ 0.50 (the owner chooses). The rounding amount is recorded as its own line in reports.
- **Change can go to the customer's wallet:** "Keep GH₵ 3.00 change as credit" instead of
  handing out coins. Popular where coins are short.
- **Deposits / part payment:** a sale can be completed with a balance due on the customer's
  account (see `CUS-03`).

### SEL-09 Refunds, returns and exchanges [Standard]

- **Finding the sale:** by scanning the receipt QR code, typing the sale number, searching by
  customer, or opening Today.
- **What to return:** choose lines and quantities. Partial returns are fine. Modifiers are
  refunded with their line.
- **How to refund:** to the original method by default, or as store credit, or as cash with
  permission. MoMo refunds record the outgoing reference.
- **Stock:** returned items go back into stock (reason `return`), or are marked "damaged / do not
  restock" (reason `waste`).
- **Exchange:** return items and sell new ones in a single transaction. Only the difference is
  paid or refunded.
- **Records:** a refund is its own record linked to the original sale, with a reason (from a list)
  and who approved it. The original sale is never changed.
- **Refund without a receipt:** needs a manager PIN and is flagged in reports.

### SEL-10 Voids and no-sale [Built → extend]

- **Void a whole sale:** this exists, with owner approval and a closed-day lock. It will gain a
  reason list.
- **Void a line before payment:** recorded. A cashier removing lines after adding them is visible
  in the audit log. This catches "ring up, remove, pocket the cash".
- **No-sale (open drawer without a sale):** needs permission, asks for a reason, and is counted
  per cashier in the shift report.

### SEL-11 Order tickets and queue numbers [Beyond]

- **Order numbers:** each sale can get a short number (`A23`) that resets daily. It's printed
  large on the receipt and on a kitchen/prep ticket.
- **Prep display:** an optional screen (a cheap tablet or a second monitor) lists open orders by
  status: New → Preparing → Ready.
- **Customer display:** a "Now serving" display can show order numbers that are ready.
- **Fit for the shop:** the ice cream shop can use this for milkshakes and waffles at busy times.
  It's off by default.

### SEL-12 Customer-facing display [Beyond]

- A second screen (a Windows second monitor, or a tablet paired to the till) shows:
  - The cart lines as they're added.
  - The total.
  - The MoMo number and QR code at payment.
  - "Thank you" with change due at the end.
- When idle, it shows the shop logo and promotions (`SEL-06`) as a slideshow.

---

## 4. Customers, credit and loyalty

### CUS-01 Customer profiles [Standard]

- **Fields:** name, phone (validated as a Ghanaian number and stored as +233), optional second
  phone, location or landmark ("near the mosque, Lamashegu"), notes, birthday, tags ("Wholesale",
  "Staff").
- **Phone is the main lookup.** Typing 4 digits finds matches, and duplicate phone numbers are
  blocked.
- **Quick add during a sale:** just a name and phone.
- **Profile page:** shows lifetime spend, number of visits, last visit, favourite products, credit
  balance, wallet balance, loyalty status and purchase history.

### CUS-02 Credit book (customer accounts) [Standard, critical]

This replaces the paper credit book.

- **Limit:** each customer can have a credit limit. A sale over the limit is blocked, or asks for
  an owner PIN, depending on the setting.
- **The account is a ledger:** each sale on credit is a debit; each repayment is a credit. The
  balance is the sum. It is never stored as one number that gets overwritten.
- **Repayments:** recorded from the customer page or from search ("Record payment"). Part
  payments are fine. Payment can be by cash, MoMo (with reference) or any other method. A
  repayment can be applied to the oldest debt first (default) or to chosen sales.
- **Due dates:** an optional number of days per customer (for example 14 or 30). The account then
  shows current, 1–30 days overdue, 31–60 days, and 60+ days (credit aging).
- **Statements:** a statement for any date range, shareable as a PDF or image to WhatsApp, or
  printed (`PRN-01`).
- **Reminders:** a "Send reminder" button opens WhatsApp or SMS with a polite message already
  written (editable template). It goes through the phone's share sheet, so no internet API is
  needed. With Aby Cloud, SMS can be sent automatically (`INT-03`).
- **Write-off:** with owner permission, a reason, and a record in the audit log.

### CUS-03 Wallet / store credit [Beyond]

- **Money held for the customer:** from change kept, refunds as credit, or advance payments
  ("I'll pay GH₵ 100 now and collect over the week").
- **Spending it:** the wallet is a payment method at checkout. Its balance is a ledger, like credit.
- **Deposits / layaway:** "Reserve this item, pay GH₵ 50 now". The item is reserved (stock
  movement `reserved`) until it's collected or the reservation is cancelled.

### CUS-04 Loyalty [Beyond]

The owner picks one style per shop:

- **Stamp card** (best for the ice cream shop): "Buy 9 cones, get the 10th free". You choose
  which products earn stamps. The free item is added as a reward line at zero price. The stamp
  count shows on the receipt.
- **Points:** for example 1 point per GH₵ 1, and 100 points = GH₵ 5 off. Points can expire after a
  set number of days.
- **Tiers:** Regular / Gold, set by spend in the last 90 days, each with its own discount.

How it works for both styles:

- The customer is identified by phone number at checkout. No card is needed.
- Rewards apply automatically, and the cashier sees "Ama has a free cone" when she's attached to
  the sale.

### CUS-05 Gift vouchers [Beyond]

- **Issuing:** sell a voucher of any value. It gets a short code (`SCP-7KQ4`) and is printed or
  shared as an image with a QR code.
- **Redeeming:** the voucher is a payment method. Part use leaves a balance. It has an expiry date.
- **Records:** the voucher's balance is a ledger.

---

## 5. Products and catalogue (managed locally)

### CAT-01 Product management [Standard]

- **Create and edit products on the device** (Manage → Products): name, category, photo (camera
  or gallery, compressed and stored locally), description, price, cost price, barcode(s), unit,
  modifier groups, tax rate, "track stock", "available for sale", and which branches sell it.
- **Variants** for products that really are different stock items (shirt size M / L, or
  500 ml / 1 L): each has its own price, cost, barcode and stock. This is different from
  modifiers, which change the price of a made-to-order item.
- **Archive instead of delete.** Archived products stay in old sales and reports.
- **Duplicate product** speeds up adding similar items.
- **Edit history:** "Price changed from GH₵ 15 to GH₵ 16 by Kofi, 3 Oct". Old prices stay on old
  sales.

### CAT-02 Categories and menus [Standard]

- Nested categories, up to 2 levels ("Ice cream → Cones"), with colour tone, icon and sort order.
- **Menus [Beyond]:** a menu is a set of products and prices for a time or context. For example, a
  "Weekend menu", or a "Wholesale price list" used for customers tagged Wholesale. Each till or
  order type chooses which menu it shows.

### CAT-03 Pricing tools [Beyond]

- **Scheduled price changes:** "From 1 November, cones GH₵ 16". They apply automatically at the
  start of the day.
- **Bulk price update:** select products, then raise prices by a percentage or an amount, rounded
  to the nearest GH₵ 0.50. You see a preview before applying. Useful when suppliers raise prices.
- **Margin view:** price, cost, margin % and markup on every product. Products below a target
  margin (set by the owner) are flagged.
- **Customer price lists:** for wholesale or regular customers (via `CAT-02` menus).

### CAT-04 Combos and bundles [Standard]

- A combo product with fixed parts (cone + milkshake) or "pick one from each group"
  (any cone + any drink).
- It has a single combo price. Stock is taken from each component.
- Reports show both the combo and its components.

### CAT-05 Recipes / bill of materials [Beyond]

This is key for the ice cream shop.

- **Stock items vs. products:** a stock item is what you buy (vanilla ice cream in litres, cones in
  pieces, sprinkles in grams, cups). A product is what you sell.
- **A recipe links them:** "Vanilla cone, single = 1 cone + 0.08 L vanilla". Modifiers can have
  recipes too ("Sprinkles = 10 g sprinkles").
- **Selling uses up stock:** a sale deducts the recipe from the stock items, not the product.
- **Cost of goods:** the cost of each sale is worked out from recipe × stock item cost. This gives
  real profit per sale, not guesses.
- **Simple products** (a sealed tub) have a one-to-one recipe, and that's created automatically.

### CAT-06 Taxes [Standard]

- **Tax rates the owner configures,** inclusive or exclusive of the price, with several taxes per
  product where needed. Ghana presets cover standard VAT with its levies, the VAT flat rate scheme,
  and exempt items. The owner confirms rates with their accountant; Aby never hard-codes rates.
- **Shops not registered for tax:** tax is off, and receipts show no tax lines.
- **Tax summary** in reports (`REP-07`). GRA E-VAT invoice integration is planned (`INT-04`).

### CAT-07 Import and export [Standard]

- Export the catalogue to CSV or Excel. Import from CSV, with a column mapping screen and a dry-run
  preview showing "34 new, 12 updated, 2 errors".
- Lets a shop with 800 items set up from a spreadsheet instead of one by one.

### CAT-08 Labels and barcodes [Beyond]

- **Generate barcodes** for products that have none (internal Code 128).
- **Print shelf labels or price stickers** on a label printer or on A4 sheets: name, price and
  barcode.
- **Print the labels for a delivery** that's just been received (`INV-02`).

---

## 6. Inventory

### INV-01 Stock levels [Built → extend]

What exists today: an append-only stock ledger written by sales and voids. This extends it with:

- **Stock screen:** on-hand quantity per stock item and branch, with value at cost, low-stock
  badge, last movement and days of stock left (`REP-08`).
- **Movement history** per item, filterable by reason: sale, return, receive, transfer, count
  adjustment, waste, production, reserved.
- **Negative stock:** allowed or blocked, per setting. Negative stock is flagged in red so it gets
  fixed with a count.

### INV-02 Receiving stock [Standard]

- **Manage → Stock → Receive:** pick the supplier (optional), then scan or pick items, enter
  quantities and the cost per unit. Optionally add a batch or expiry date (`INV-07`).
- **Cost price** updates by weighted average cost (default) or last cost (setting).
- **Supplier invoice:** a photo of it can be attached.
- **Paying the supplier:** the delivery can be marked paid now (from the drawer, `CSH-03`, or by
  MoMo/bank) or left owed to the supplier (`INV-04`).

### INV-03 Purchase orders [Standard]

- **Create a purchase order** for a supplier. Suggested quantities come from the reorder points
  (`INV-05`).
- **Sending it:** the purchase order can be shared as a PDF or image to the supplier on WhatsApp.
- **Receiving against it:** you receive against the order, partly or fully. What's still
  outstanding is tracked.

### INV-04 Suppliers and payables [Standard]

- **Supplier profiles:** name, phone, what they supply and payment terms.
- **Supplier account ledger:** what we owe, what we've paid, and statements. It mirrors the
  customer credit book (`CUS-02`).

### INV-05 Low stock and reorder [Standard]

- Each stock item has a reorder point and reorder quantity.
- **Alerts:** below the reorder point, an alert appears on the dashboard and a local notification
  (`NTF-01`) is shown.
- **Smart reorder point [Beyond]:** "Suggest" works it out from average daily use over the last 28
  days × supplier lead time + a safety buffer.

### INV-06 Stock counts (stocktake) [Standard]

- **Full count or cycle count** (one category, or the items due this week).
- **Blind count option:** the counter doesn't see the expected quantity, which stops them just
  copying it.
- **Counting:** scan or type quantities. Several people can count on different devices; counts
  merge through the hub.
- **Review screen:** shows each difference with its value ("Cones: short 14, GH₵ 21.00"). The
  owner approves and the app posts adjustments to the ledger. Who counted and who approved are both
  recorded.
- **Selling during a count:** sales during a count are handled. Movements after the count started
  are applied on top.

### INV-07 Batches and expiry [Standard, per business type]

- **Recording:** batch number and expiry date when receiving.
- **Selling:** sales take from the earliest-expiring batch first (FEFO).
- **Expiry report:** what expires in the next 7 / 30 days, with an alert.
- **Dairy:** on by default for the ice cream template (ice cream base and milk).

### INV-08 Waste and spoilage [Beyond]

- **Quick "Log waste" action:** item, quantity and reason (melted / power cut, expired, dropped,
  staff meal, sample). Photo optional.
- **Power-cut loss report:** "During the outage on 12 Oct, GH₵ 340 of stock was lost". This is
  real money for cold stores.
- **Reporting:** waste shows in reports as its own cost line.

### INV-09 Production / batch prep [Beyond]

- For shops that make things (a batch of milkshake base, a waffle batter):
  1. Record a production run: "Made 5 L milkshake base".
  2. The ingredients are deducted from stock.
  3. The finished stock item increases by the amount made.
- Prep costs then flow into the product cost correctly.

### INV-10 Transfers between branches [Standard, multi-branch]

- **Sending:** send stock from Branch A to Branch B. The stock shows as in transit.
- **Receiving:** Branch B confirms receipt, with differences flagged.
- **Without the internet:** this works between branches through Aby Cloud, or through an export
  file when there's no internet at all.

---

## 7. Cash management

### CSH-01 Shifts (open and close the till) [Built → extend]

What exists today: close day with an opening float and the counted cash. This extends it with:

- **Opening a shift:** count the float by denomination (`CSH-02`). The shift belongs to the person
  who opens it, and other staff can join it.
- **Shift types:** one shift per day, or several per day (morning / evening). Several drawers are
  supported on one device or across devices.
- **During the shift:** the X report (a mid-shift snapshot) can be viewed at any time without
  closing.
- **Closing a shift:**
  1. Blind count by denomination. The cashier counts without seeing the expected amount (owner
     setting).
  2. The app then shows the expected amount and the difference.
  3. The cashier gives a reason when the difference is over a set threshold.
- **Z report:** the end-of-shift report. Covers sales, refunds, discounts, voids, no-sales,
  paid-ins and paid-outs, payments by method, the cash difference, and who.
- **Variance history per cashier [Beyond]:** "Ama: 3 shorts in the last 30 days, total GH₵ 26".
  It's shown to owners only.

### CSH-02 Denomination counting [Beyond]

- **A counting screen with a row per Ghana note and coin:** GH₵ 200, 100, 50, 20, 10, 5, 2, 1 and
  50p, 20p, 10p, 5p, 1p. Type the number of each; the total adds up live.
- **The breakdown is stored,** so a later "where did the GH₵ 50 go" question has an answer.

### CSH-03 Pay in / pay out [Standard]

- **Cash in or out of the drawer that isn't a sale,** for example "Bought ice from vendor
  GH₵ 20", "Owner took GH₵ 200", or "Added change GH₵ 50".
- **Each one has:** an amount, a category (from the expense list, `EXP-01`), a note and an
  optional photo of the receipt. Permission controls who can do it.
- **Effect on the shift:** the drawer's expected cash is adjusted, and it all shows on the Z report.

### CSH-04 Safe drops and banking [Standard]

- **Safe drop:** move excess cash from the drawer to the safe mid-shift. This keeps the drawer
  low, which is a security measure.
- **Safe balance:** a ledger of drops in and bank deposits out.
- **Bank deposit:** record the amount, bank and slip photo.

### CSH-05 MoMo reconciliation [Beyond]

- **End of day:** a list of every MoMo payment with its reference, amount and time.
- **Ticking off:** the owner ticks each one against the MoMo statement on their phone. Unmatched
  references are flagged.
- **Shown separately:** MoMo charges or e-levy deducted are shown on their own line.
- **Later:** a statement import from CSV, and the MoMo API (`INT-02`), do the matching
  automatically.

---

## 8. Expenses and simple accounts

### EXP-01 Expenses [Beyond]

- **Recording an expense:** the date, amount, category, how it was paid (drawer cash, MoMo, bank,
  owner's pocket), supplier (optional), note and a receipt photo.
- **Categories:** default categories include rent, electricity (ECG prepaid), water, generator
  fuel, transport, ice, staff wages, repairs, phone credit / data and packaging. The owner can edit
  them.
- **Recurring expenses:** for example "Rent GH₵ 800 on the 1st", which shows as a reminder to
  confirm.

### EXP-02 Profit and loss [Beyond]

- **A simple P&L for any period:**

  ```
  sales − refunds − discounts
  = net sales
  − cost of goods (from recipes and stock costs)
  = gross profit
  − expenses
  − waste
  = net profit
  ```

- **Display:** a single page in plain words, with a comparison to the previous period.
- **Not full accounting.** Export to an accountant (`REP-09`) for that.

### EXP-03 Owner drawings and capital [Beyond]

- Money the owner takes for personal use, or puts into the business, is recorded separately from
  expenses. Profit then isn't understated, and the owner sees what they really took home.

---

## 9. Staff, roles and security

### STF-01 Staff profiles [Built → extend]

- **Name, phone, photo, role(s), PIN** (this already exists), language, and which branches they
  can work at.
- **Optional badge login [Beyond]:** a printed QR or barcode badge, scanned to sign in, plus a
  PIN.
- **Status:** active or deactivated. History is kept forever.

### STF-02 Roles and permissions [Standard]

- **Built-in roles:** Owner, Manager, Cashier and Stock keeper.
- **Custom roles:** the owner can make their own.
- **Permissions are fine-grained switches,** grouped by area. Examples:
  - Sell: give discounts up to X%, override price, refund, refund without a receipt, void a sale,
    open the drawer without a sale.
  - Manage: edit products, change prices, receive stock, adjust stock, approve stock counts.
  - Customers: give credit, write off credit.
  - Cash: open or close a shift, pay out.
  - Reports and settings: see reports, see cost and profit, manage staff, change settings, export
    data.
- **Visibility:** a person sees only what their role allows (`APP-01`).

### STF-03 Approvals ("manager override") [Built → extend]

- **When the signed-in person lacks a permission,** the action asks for the PIN of someone who has
  it. Approval exists for voids today; this makes it general.
- **Records:** both people are recorded, the one who asked and the one who approved.
- **Lockout:** wrong PINs lock out after 5 tries, as they do today.
- **Remote approval [Beyond, needs a hub or cloud]:** the request goes to the owner's phone ("Ama
  wants to refund GH₵ 45. Approve?") when the owner isn't at the counter.

### STF-04 Clock in / clock out [Standard]

- **Clocking:** staff clock in and out with their PIN. Breaks are optional.
- **Timesheets:** per week, with hours, late arrivals and early leaves. They can be exported for
  wages.
- **Clocking and selling:** clocking in can be required before someone can sell (setting).

### STF-05 Auto-lock and quick switch [Standard]

- **Auto-lock:** the till locks after a set idle time (default 3 minutes). The cart is kept.
- **Quick switch:** tap the user chip to switch to another person without going back to the start.
- **Sales follow the signer:** each sale records who completed it.

### STF-06 Audit log [Beyond, important]

- **What's recorded:** every sensitive action, as an entry with who, when, which device, what
  changed (before and after) and who approved it. Actions include sign-in, a failed PIN, price
  change, discount over the limit, removing a line after it was added, void, refund, no-sale, pay
  out, stock adjustment, credit write-off, settings change, data export and restore.
- **Tamper-evident:** each entry stores a hash of the previous entry, like a chain. If someone
  edits the database file directly, Aby detects a broken chain and shows a warning on the owner
  dashboard.
- **Never shrinks:** the log can't be deleted from inside the app.
- **Owner screen:** a timeline with filters by person, action type and date.

### STF-07 Performance and commission [Beyond]

- **Per person:** sales, items, average sale, refunds, voids, discounts given, cash variance and
  hours.
- **Optional commission:** a percentage of sales, or per product, worked out per pay period.

---

## 10. Reports and insights

All reports share these behaviours:

- They work fully offline, from the local database.
- They have a date range picker, a branch filter (multi-branch) and a comparison to the previous
  period.
- They export to PDF, CSV or Excel, and can be shared through the share sheet (WhatsApp, email).
- Cost and profit columns only appear for people with the "see cost and profit" permission.

### REP-01 Sales summary [Standard]

Gross sales, refunds, discounts, net sales, tax, number of sales, average sale and items per sale.
Shown by day, week or month, with a chart.

### REP-02 Sales by time [Standard]

- **By hour of day and day of week** as a heatmap. The ice cream shop will see its afternoon and
  weekend peaks.
- **Use:** helps the owner plan staff and prep.

### REP-03 Products [Standard]

- Quantity sold, revenue, cost, profit and margin per product, category and modifier option.
- **ABC analysis:** which 20% of products bring 80% of revenue.
- **Slow movers:** products not sold in N days.

### REP-04 Payments [Standard]

Takings by method and day. MoMo references list. Cash rounding total.

### REP-05 Staff [Standard]

The staff performance figures (`STF-07`) and shift reports (`CSH-01`).

### REP-06 Customers and credit [Standard]

Top customers, new versus returning, credit outstanding and aging, wallet balances, and loyalty
rewards given.

### REP-07 Inventory and tax [Standard]

- **Inventory:** stock value, movement summary by reason, waste report, count differences and
  expiry report.
- **Tax:** a tax summary per rate.

### REP-08 Insights [Beyond]

Generated on the device by simple rules over the shop's own data. There's no cloud AI and no
internet. Insights show as dashboard cards with one action each. Examples:

- "Cones will run out in about 2 days at this week's pace." → *Create purchase order*
- "Saturday sales are 40% higher than weekdays. You've had one cashier on the last 3 Saturdays."
- "Milkshake margin fell from 52% to 38% since milk cost went up on 4 Oct." → *Review price*
- "5 customers owe more than 30 days: GH₵ 640 in total." → *Send reminders*
- "Cash was short 4 times this month on evening shifts."
- "Yesterday was not closed." → *Close day*

Owners can dismiss an insight, or turn a kind of insight off.

### REP-09 Export for the accountant [Standard]

A month-end pack covering sales, payments, expenses, purchases, tax and the stock valuation, as a
single zip of CSVs plus a PDF summary.

---

## 11. Receipts and printing

### PRN-01 Printers [Standard]

- **Printers:** ESC/POS thermal printers, 58 mm and 80 mm, over Bluetooth (the common cheap
  ones), USB (Windows and Android OTG) and network (Wi-Fi or Ethernet).
- **Setup:** a printer setup wizard with "Print test page".
- **Routing:** receipts to the counter printer, order tickets to the kitchen printer (`SEL-11`),
  labels to the label printer (`CAT-08`).
- **Print queue:** if the printer is off or out of paper, the job waits and retries, and the sale
  isn't blocked. "Reprint last" is always one tap.

### PRN-02 Receipt designer [Standard]

- **What the owner edits:** logo (printed as an image), header text, shop address and phone, MoMo
  number, footer ("Thank you. Come again!"), and which lines to show (cashier name, customer,
  loyalty stamps, tax breakdown, QR code).
- **Preview:** a live preview of how the receipt will look.
- **Copies:** set per payment method (for example, credit sales print a customer copy and a shop
  copy for signing).

### PRN-03 Digital receipts [Beyond]

- **"Send receipt"** creates a receipt image or PDF and opens WhatsApp or SMS for the customer's
  number. This works offline through the share sheet and is sent when the phone has signal.
- **No-paper option:** for shops without a printer.

### PRN-04 Receipt QR code [Beyond]

- **The code** contains the sale ID and a short check code.
- **Scanning it in Aby** opens the sale for a refund or reprint (`SEL-09`).
- **With Aby Cloud:** the customer can scan it to see the receipt online or leave feedback.

### PRN-05 Reports on paper [Standard]

X report, Z report, the shift close and customer statements, printed on the receipt printer.

---

## 12. Hardware

- **HW-01 Barcode scanners** [Standard]: keyboard-mode USB or Bluetooth scanners, and the
  camera. See `SEL-03`.
- **HW-02 Cash drawer** [Standard]: opens through the printer's kick port after a cash sale or a
  permitted no-sale.
- **HW-03 Customer display** [Beyond]: see `SEL-12`.
- **HW-04 Scales** [Standard, per business type]: a serial or USB scale on Windows, a Bluetooth
  scale on Android, or price-embedded labels from a label scale.
- **HW-05 Hardware profiles** [Standard]: each device remembers its own printer, drawer, scanner
  and display. Settings → This device.

---

## 13. Multi-device and multi-branch (works without internet)

### MDV-01 Local hub [Beyond, key differentiator]

Many shops have two or three devices (a till, the owner's phone, a kitchen tablet) and no reliable
internet, but they do have a Wi-Fi router or a phone hotspot.

- **The hub:** one device is the hub, usually the main till or a Windows PC. Other devices join it
  over the local network, with no internet needed.
- **Pairing:** the hub shows a QR code with a one-time pairing code. The new device scans it, and
  they exchange keys. After that, all traffic is encrypted.
- **Discovery:** devices find the hub automatically on the same network (mDNS).
- **What syncs:** sales, stock, customers, parked orders, shifts and settings, in near real time,
  using the same outbox and UUIDs as cloud sync.
- **Working through outages:** if the network drops, each device keeps working alone and catches up
  when it reconnects.
- **What owners get:**
  - The owner's phone shows live sales from the counter.
  - The kitchen tablet shows orders.
  - Stock counts can be split between two people on two devices.
  - Parked orders follow the customer between tills.
- **Conflicts:**
  - Ledgers (sales, stock, credit, cash) never conflict, because they only ever add rows.
  - For editable records (a product name, say), the last edit wins, and the losing version is kept
    in history.

### MDV-02 Multi-branch [Standard]

- **Branches:** a shop with several branches has a branch per location, with its own stock,
  prices (optional), staff access and devices.
- **Owner view:** owners see all branches combined, or one at a time.
- **Moving data between branches:** through Aby Cloud, or an offline transfer file (`DAT-03`)
  carried between branches when there's no internet at all.

### MDV-03 Device management [Standard]

- **The list:** every device with its name, type, last seen and app version.
- **Rename** a device, or set its role: till, kitchen display, customer display or owner.
- **Revoking a lost device:** it can no longer join the hub. Its data so far is kept.

---

## 14. Data safety and backup

### DAT-01 Automatic local backups [Beyond, urgent]

- **Daily automatic backup** of the database to the device's storage, plus one at every day close.
  The last 14 are kept.
- **Integrity check:** each backup is verified (SQLite integrity check and a test open) after it's
  written.

### DAT-02 Off-device backup [Beyond, urgent]

- **"Back up now"** creates an encrypted backup file, protected by a backup password the owner
  sets. It is shared to Google Drive, WhatsApp (to the owner's own number), email, a USB stick or an
  SD card.
- **Reminder:** "Last off-device backup: 9 days ago" shows on the dashboard until it's done.
- **With Aby Cloud:** continuous backup replaces this.

### DAT-03 Restore and move to a new device [Standard]

- **Restoring:** on a new or reset device, setup offers "Restore from backup". You pick the file,
  enter the password, and see a preview ("Scoops Tamale, 1,245 sales, last sale 22 Oct 18:04")
  before confirming.
- **Restore point:** restoring over existing data makes a backup of the current data first.
- **Moving data:** the same file format carries data between branches offline.

### DAT-04 Power-cut and crash safety [Standard]

- **Database safety:** SQLite in WAL mode, every business action in one transaction, and the cart
  and open forms saved as you go.
- **After a crash:** a startup check reports "Recovered your cart from before the restart".
- **Low battery (Android):** below 10% without charging, the app shows a prompt to save or close
  the shift.

### DAT-05 Status centre [Standard]

- **One place for all the "is everything safe" signals:** last backup, off-device backup age, hub
  connection, cloud sync (number waiting), printer status and storage space.
- **Header indicator:** shows the worst status (green / amber / red) and opens the status centre.

### DAT-06 Data export and privacy [Standard]

- **Export:** the owner can export everything (CSV / zip) at any time. It's the owner's data.
- **Customer data:** a customer can be anonymised on request, keeping sales totals but removing the
  name and phone, in line with Ghana's Data Protection Act.

---

## 15. Settings and onboarding

### SET-01 Setup wizard [Built → extend]

What exists today: create the owner. The setup wizard will be:

1. Language.
2. Business type (`APP-04`).
3. Shop name, phone, location and logo.
4. Tax registration (yes / no, and which scheme).
5. Payment methods and MoMo numbers.
6. The owner's account and PIN.
7. Add products:
   - Start from the template, or
   - Import a spreadsheet (`CAT-07`), or
   - Add them later.
8. Printer (optional).
9. Backup password (`DAT-02`).

It can be resumed if it's interrupted.

### SET-02 Settings structure [Standard]

Settings are grouped as follows, with search across all of them:

- **Shop:** profile, branches, opening hours.
- **Selling:** order types, cash rounding, negative stock, out-of-stock behaviour, receipts.
- **Payments:** methods and MoMo.
- **Tax.**
- **Staff and roles.**
- **Features:** feature flags.
- **This device:** hardware, display and language.
- **Data:** backup, export, restore and sync.
- **About.**

### SET-03 Opening hours and day boundaries [Beyond]

- **Business day:** a shop open until 1 am should count those sales on the previous business day.
  The owner sets a day start time (default 05:00), and Today, reports and close day all use the
  business day, not midnight.
- **Close-day reminder:** a reminder to close the day shows at closing time.

---

## 16. Notifications

### NTF-01 Local notifications [Standard]

On-device notifications, with no internet, for:

- Low stock and expiring stock.
- Credit due today.
- Day not closed by closing time.
- Backup overdue.
- A parked order older than 1 hour.
- An approval request (with a hub).

Each user can turn each kind off.

### NTF-02 Owner daily summary [Beyond]

At day close, the owner gets a summary card: sales, profit (if costs are set), cash difference, top
product and alerts.

- **Shareable** as an image to the owner's WhatsApp, for owners who aren't at the shop.
- **With Aby Cloud,** it arrives on the owner's phone automatically.

---

## 17. Aby Cloud and integrations (optional, online)

None of these are required. Each one adds value when the shop has internet.

- **INT-01 Cloud sync and the owner portal:**
  - The outbox syncs to the Laravel API.
  - The owner sees every branch from anywhere, through the web back office (Filament) and the app.
  - Continuous backup.
  - Remote device revoke and wipe.
- **INT-02 MoMo payment APIs:**
  - Request to pay: the customer approves on their phone and the sale completes automatically.
  - Automatic confirmation and reconciliation (`CSH-05`).
  - Each provider (MTN, Telecel, AT) is a plug-in behind one payments interface.
- **INT-03 SMS gateway** (a local Ghana provider): automatic receipts, credit reminders, loyalty
  messages and the owner's daily summary.
- **INT-04 GRA E-VAT:** submit invoices to the Ghana Revenue Authority E-VAT system and print the
  returned verification code and QR on receipts, for VAT-registered shops. Invoices made offline
  are queued and submitted when online. Check the legal requirements before building.
- **INT-05 Accounting export:** scheduled exports, and an API for accounting tools.
- **INT-06 Online ordering [later]:** a simple order page or WhatsApp catalogue. Orders arrive as
  parked orders on the till.

---

## 18. Architecture changes these features need

The current code is a good base: offline database, outbox, ledgers, GetX MVC. Growing it to this
scope needs some structure added before most features:

1. **Feature-module layout:** `lib/app/modules/<feature>/` stays, with three additions:
   - A **domain layer** of use cases (`CompleteSale`, `RefundSale`, `ReceiveStock`), so business
     rules live in one place, not in controllers or repositories.
   - **Feature flags** read from settings, which decide which modules and routes are registered.
   - A **shared design system package** (`lib/app/ui/`): list and detail scaffolds, filter bar,
     numeric keypad, money field, date range picker, empty states. Every screen is built from these,
     so screens look and behave the same.
2. **Permission service:** `can(Permission.x)` checks, plus `requireApproval(Permission.x)`, which
   shows the approval flow. These replace the ad-hoc `isOwner` checks.
3. **Domain events:** use cases emit events (`SaleCompleted`, `StockAdjusted`). Listeners write the
   audit log, the outbox, notifications and insights. One action, one transaction, every side effect
   included.
4. **Settings store:** typed, versioned settings per shop, branch and device, synced like data.
5. **Hardware abstraction:** `PrinterService`, `ScannerService`, `DrawerService`, `ScaleService`
   and `DisplayService` interfaces, with per-platform implementations. Tests use fakes.
6. **Sync transport abstraction:** the same outbox feeds the hub transport (LAN) and the cloud
   transport (HTTPS).
7. **Reporting queries:** move to SQL views and indexes built for reporting. Run heavy reports in a
   background isolate so the till never stutters.
8. **Localisation:** the Flutter `intl` / ARB setup from the next phase onward. No new hard-coded
   strings.

---

## 19. Phases

Each phase ends with a working, tested app that a real shop can use. The ordering rule is safety
first, then what the owner can't do without, then what makes Aby special.

### Phase 1: Foundation and structure

Restructure the app, keep the data safe, and give the owner control.

- `APP-01` shell and navigation (Sell / Manage), with the shared UI kit (section 18, item 1).
- `STF-02` roles and permissions, and `STF-03` general approvals.
- `STF-05` auto-lock and quick switch.
- `STF-06` audit log.
- `SET-02` settings structure, and `SET-03` business day.
- `DAT-01` automatic backups, `DAT-02` off-device backup, `DAT-03` restore, `DAT-05` status
  centre.
- `APP-06` localisation setup (English only, with the plumbing ready).

**Status (23 October 2026): built.** Schema version 3. What was left for later:

- The domain-events layer and use cases (section 18, items 1 and 3). Phase 1 writes audit entries
  inside each repository transaction instead. Use cases arrive with Phase 2, where the catalogue
  rules need them.
- English text on the older screens (till, checkout, close day). Every new screen uses the ARB
  file.
- From `SET-02`: only the groups that have settings today (Shop, Business day, Security, This
  device, Backup and restore, About). Selling, Payments, Tax and Features come with their phases.
- From `DAT-05`: storage space and printer status. Those come with hardware (phase 5).

### Phase 2: Catalogue and stock, managed locally

- `CAT-01` product management, `CAT-02` categories, `SEL-02` modifier groups (replacing the
  current variants and toppings, with a migration).
- `CAT-03` pricing tools, `CAT-06` taxes, `CAT-07` import / export.
- `INV-01` stock screen, `INV-02` receiving, `INV-04` suppliers, `INV-05` low stock,
  `INV-06` stock counts, `INV-08` waste.
- `CAT-05` recipes, for the ice cream shop's real costs.

**Status (23 October 2026): built** (2a and 2b). Schema version 5. Decisions made on the way:

- Sizes are variants, not a price-setting modifier group. Every product has at least one variant
  (a simple product has one unnamed variant); option groups are for add-ons only. The v5
  migration turned the old toppings into a "Toppings" group with the same IDs.
- Existing shops get no stock items or recipes from the migration (only new databases are
  seeded). Until the owner sets them up, sales simply do not use stock.
- Receiving updates the weighted average cost. If the till thought an item had run out (or gone
  negative), the delivery's cost replaces the old one.
- A delivery without a supplier must be paid in full; with one, the unpaid part goes on the
  supplier's account. Paying a supplier needs `payOut`.
- Counts can be blind (counters do not see what the till expects). Each counted line keeps what
  the till expected at that moment, so selling during a count is fine. Posting needs
  `approveStockCount`; items not counted do not change.
- Scheduled prices start at the beginning of the chosen business day; the app checks at start and
  every hour.
- CSV import only adds products and updates prices, costs, barcodes, tile line and "on till". It
  never removes variants, recipes, options or taxes, and a file with any problem imports nothing.

What was left for later:

- `INV-03` purchase orders (receiving works without them).
- Product photos are kept on the device only (not in the outbox): see TODO(sync).
- `CAT-03`: happy-hour and per-channel prices, which need SEL-06 promotions (phase 3/6).
- Stock import from CSV (stock export works).

### Phase 3: Selling power

- `SEL-01` grid extensions, `SEL-03` barcodes, `SEL-04` quantity, weight and open price,
  `SEL-05` cart actions.
- `SEL-06` discounts (manual and saved; automatic promotions are in phase 6).
- `SEL-07` park and open orders.
- `SEL-08` split payments, configurable methods, MoMo reference checks, cash rounding.
- `SEL-09` refunds and exchanges, `SEL-10` void reasons and no-sale.

**Status (23 October 2026): 3a built** (the cart and the till). Schema version 6. Built:

- `SEL-01`: Quick tab (pinned in the product editor, arranged from the till), Recent tab (last 8
  products sold on this till), tile sizes (small / medium / large, per device), photos or initials
  on tiles, search as you type, and out-of-stock warnings (or refusal, by setting).
- `SEL-03`: one "search, scan, or type a code" box. Keyboard-style scanners and hardware keyboards
  type into it from anywhere on the till. Short codes (PLU) are just barcodes. Scale barcodes
  (EAN-13 with the shop's prefix, weight or price). An unknown barcode offers "New product with
  this barcode" to people who may add products.
- `SEL-04`: type a quantity then tap; sold by weight or volume (price per kg or litre, recipes per
  kg or litre too); open-price products with optional limits.
- `SEL-05`: tap a line to change quantity, price, discount, note, or size and options, or remove
  it. Order discount, order note, order type (takeaway / eat in / delivery, by setting), clear
  (asks when more than 3 lines). The cart is saved on the device as it changes.
- `SEL-06` manual and saved discounts, with a reason from the owner's list. Each role's limit
  applies; above it someone whose limit covers it enters their PIN. The order discount is shared
  across lines (exactly, to the pesewa) and tax is worked out on what is left.
- `SEL-07`: park and resume (tabs above the cart), rename, merge into the current sale, throw away
  (needs `voidSale`, audited). Close day warns about old parked orders.
- `SEL-10` (part): taking lines or quantities off the cart, and clearing it, is in Activity.
- Reasons lists for discounts, voids, refunds and no-sales (Settings → Selling).

Decisions made on the way:

- PLU codes are barcodes: no separate field. Typing "12" and Enter looks it up; typing "3" and
  tapping a product adds three.
- Open prices need only `sell`, within the product's limits. Overriding a menu price needs
  `overridePrice` (or a PIN) and is audited with the sale, with who allowed it.
- Discounts and overrides are audited when the sale completes, not when typed, so an abandoned
  cart leaves no false entries. Removals are audited when they happen.
- Camera scanning moves to phase 5 with the other hardware.
- For price-printing scales the till works out the weight from the price per kg, so a line can
  differ from the label by a pesewa.

**3b next:** `SEL-08` split payments and configurable methods, MoMo reference checks, cash
rounding; `SEL-09` refunds and exchanges; `SEL-10` void reasons in the void flow and no-sale.

### Phase 4: Customers and money

- `CUS-01` customers, `CUS-02` credit book, `CUS-03` wallet.
- `CSH-01` shifts with X / Z reports, `CSH-02` denomination count, `CSH-03` pay in / out,
  `CSH-04` safe drops, `CSH-05` MoMo reconciliation.
- `EXP-01` expenses, `EXP-02` profit and loss, `EXP-03` drawings.

### Phase 5: Reports, printing and hardware

- `APP-02` owner dashboard, `REP-01` to `REP-07`, `REP-09`.
- `PRN-01` to `PRN-05` printers and receipts.
- `HW-01` to `HW-05` hardware.
- `NTF-01` notifications.

### Phase 6: Beyond standard

- `APP-03` command bar, `APP-04` business templates, `APP-05` training mode.
- `SEL-06` automatic promotions, `CUS-04` loyalty, `CUS-05` gift vouchers.
- `REP-08` insights, `NTF-02` owner daily summary.
- `INV-03` purchase orders, `INV-07` batches and expiry, `INV-09` production, `CAT-04` combos,
  `CAT-08` labels.
- `SEL-11` order tickets, `SEL-12` customer display.
- `STF-01` badge login, `STF-04` clock in / out, `STF-07` performance and commission.
- `APP-06` further languages.

### Phase 7: Many devices without internet

- `MDV-01` local hub, `MDV-03` device management.
- `MDV-02` multi-branch, with `INV-10` transfers.

### Phase 8: Aby Cloud and integrations

- `INT-01` cloud sync and owner portal.
- `INT-02` MoMo APIs, `INT-03` SMS, `INT-04` GRA E-VAT, `INT-05` accounting export.
- `INT-06` online ordering.

---

## 20. Open questions for the owner

1. **Hub scope:** is the local hub (`MDV-01`) needed before cloud sync, or will the first
   multi-device shops have internet? This decides the order of phases 7 and 8.
2. **Tax:** which tax registrations do the first customers have? This decides how much of `CAT-06`
   and `INT-04` is needed early.
3. **Languages:** which ones matter most for the first shops' staff?
4. **Hardware:** which printers and scanners are actually sold locally (brand and model)? Phase 5
   should be tested on those exact devices.
5. **Pricing:** should some features be paid tiers (hub, cloud, loyalty, insights)? Feature flags
   (`APP-04`) can enforce tiers if so.
