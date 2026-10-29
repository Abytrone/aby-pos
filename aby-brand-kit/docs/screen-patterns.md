# Screen patterns

How Aby's screens behave when something happens: nothing to show, waiting, offline, low stock, errors, confirmations and the finished sale. The rule behind all of them: **never stop a sale**. The till keeps working; the screen tells the cashier only what they need to act on.

## Offline and sync

Offline is the normal state of a shop, not an error.

| Situation | What the screen shows | Component |
| --- | --- | --- |
| Online, everything synced | "All synced" in the header | `SyncBadge` |
| Offline or sales waiting | "3 sales saved on this device", with the pulsing lime dot | `SyncBadge` |
| Not synced for 24 hours | A quiet `Banner` (tone `offline`) at the top of the till: "This till hasn't synced since yesterday, 4:10 pm. Sales are safe here. Connect to the internet when you can." | `Banner` |
| An action needs the internet (pairing, MoMo prompt, sending a WhatsApp receipt) | Say so on that action only: "Pairing needs the internet. Connect, then try again." Queue it if it can wait ("WhatsApp receipt will send when you're online"). | Inline text or `Banner` |

- Never use danger colours, error icons or the word "failed" for being offline.
- Never block the till behind a sync. A sync never shows a full-screen spinner.

## Empty states

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

## Loading

- Local reads (products, cart, today's sales) are instant. Don't show a loader for them; if a list takes longer than 300 ms, show tile-shaped placeholders in `surface-sunken`, never a spinner over the grid.
- Network actions (pairing, MoMo check, back-office reports) show a spinner inside the button that started them, with the label changed to what's happening: "Pairing…", "Checking MoMo…". Keep the rest of the screen usable.
- After 15 seconds, replace the spinner with a plain message and a retry: "This is taking longer than usual. Try again."

## Low stock

- Show it on the product tile, not in a pop-up: a `warning` label "3 left" replaces the size detail. At zero, the tile reads "Out of stock" and stays tappable (the cashier may know there's more in the freezer); adding it shows a one-line note in the cart, never a block.
- The owner gets the low-stock alert (see Messages). The cashier is never interrupted mid-sale.
- "Low" is set per product in the back office; the default is 2 days of the product's usual sales.

## Product views

The product area has two views with the same products, the same order and the same tap behaviour. `ViewToggle` at the right of the category header switches between them.

| View | Component | Best for |
| --- | --- | --- |
| Grid | `ProductTile`: 4:3 photo, name, size, price | Tablets and Windows tills, short menus where photos help (ice cream, café, restaurant) |
| List | `ProductRow`: 56px photo, name, size, price on one line | Phones, long menus (a supermarket's hundreds of items), cashiers who find things by name |

- Default to grid on tablets and tills, list on phones. Remember the choice per device: it's the cashier's preference, not a shop setting.
- Both views keep the category tabs and search above them. A tap always adds one item; a product with sizes or toppings opens the same sheet in either view.
- Don't add a third view or let cashiers resize tiles; two well-made views are easier to learn.

## Errors

Say what happened, what Aby already did, and what to do next, in that order. Use `Banner` with tone `danger` only when money or data is at risk or an action really didn't happen.

| Instead of | Write |
| --- | --- |
| Error 500: Internal server error | We couldn't reach Aby's servers. Your sales are saved on this till. |
| Invalid input | Enter the MoMo reference from the customer's message. |
| Printer error | The printer isn't answering. Check it's on and has paper, then tap Print again. You can send the receipt by SMS instead. |
| Payment failed | MoMo didn't confirm this payment. Ask the customer to check their phone, or take another payment method. |

- Field errors sit under the field in `danger`, in the words above; never only a red border.
- Never show error codes to cashiers. Log them for support instead.

## Confirmations

Ask only before things that move money or can't be undone: void, refund, delete a product, close the day, unpair a till. Everything else just happens, with a short toast and Undo where possible ("Removed Sprinkles. Undo").

Built with `ConfirmSheet`, a bottom sheet:

- The title is the question, naming the thing: "Void sale #00142?"
- One line on the consequence: "GH₵ 58.00 comes off today's takings. Your name and reason go in the log."
- Voids and refunds also ask for a reason (chips: Wrong item, Customer changed mind, Duplicate, Other) and the cashier's PIN.
- The buttons are verbs, never Yes/No: the `danger` action ("Void sale") and a `quiet` way out ("Keep sale"). The safe option is on the right, where the thumb rests.

## Sale complete

Built with `SaleComplete`. Shown on a midnight panel the moment the sale is saved:

- A lime check in a circle, "Sale complete" and the total.
- For cash: **Change GH₵ 12.00** is the largest thing on screen, because it's what the cashier has to act on.
- Actions: **New sale** (the primary action, a chalk button: lime stays for paying), then Print receipt and Send receipt (SMS/WhatsApp). The panel returns to the till on its own after 6 seconds unless the cashier taps something.
- The check draws once in 300 ms; nothing else animates. With reduced motion it appears without drawing.

## Toasts

- For confirmations that need no action: "Product saved", "Receipt sent", "Removed Sprinkles. Undo".
- Bottom centre, midnight with `on-midnight` text, 3 seconds (6 with Undo), one at a time.
- Never use a toast for an error the cashier must fix; use a `Banner` or inline text.

## Cash entry

- The tendered-amount screen shows quick amounts above the keypad: Exact, then the next notes up (for a GH₵ 38.00 sale: Exact, 40, 50, 100, 200).
- Change due updates as the cashier types; if the amount is short, the Complete button stays disabled and the line reads "GH₵ 5.00 more needed".

## First run (owner onboarding)

Three steps, each on one screen, each skippable except the first:

1. **Your shop:** name, business type (Ice cream and café, Retail, Restaurant), phone.
2. **Your products:** start from the business-type template (the ice cream menu), import a list, or add later.
3. **Your till:** pair this device, or open the back office on another device to get a code.

End on the till with the template products loaded, not on a dashboard. Don't show tours or tooltips; the empty states and labels do that work.

## Motion

- Fast and functional: 150–200 ms ease-out for sheets and panels, 100 ms for a tile press (scale to 0.98).
- Only two things animate on their own: the sync dot's pulse while sales wait, and the check on Sale complete.
- Respect reduced motion everywhere: drop the pulse and the draw, keep fades under 150 ms.
