# Messages

Every message Aby sends outside the app: receipts and credit reminders to customers, summaries and alerts to shop owners, and account emails. Preview them with the `MessagePreview` component.

## Who the message is from

- **To a shop's customers, the shop speaks.** Receipts, credit reminders and payment confirmations go out in the shop's name and SMS sender ID (up to 11 characters, for example `ScoopsTML`). Aby appears only as the small "Sent with Aby" footer on WhatsApp.
- **To the shop owner, Aby speaks.** Summaries and alerts start with "Aby:" in SMS and come from the Aby WhatsApp number.
- Customers get a message only when they asked for it: a receipt when they give their number for that sale, reminders only if they agreed when they were added to the credit book. Keep that consent on record (Ghana's Data Protection Act, 2012, Act 843). Never send marketing to customers through Aby.

## Channel rules

| Channel | Use for | Rules |
| --- | --- | --- |
| SMS | Receipts, credit reminders, owner alerts when WhatsApp isn't set up | One message of up to 160 characters. Use the GSM-7 character set only: write **GHS**, never GH₵ (the ₵ sign switches the whole SMS to Unicode, cutting it to 70 characters and multiplying the cost). No curly quotes, em dashes or emoji. |
| WhatsApp | Receipts with item lines, the owner's daily summary, alerts | Every message Aby starts is a Meta-approved **utility** template with numbered variables (`{{1}}`). GH₵ is fine. Bold with `*asterisks*` for the total only. Footer "Sent with Aby". |
| Push notification | Owner alerts on the Aby app | Title up to 40 characters, body up to 100. The title names the shop when the owner has more than one. |
| Email | Account only: welcome, pairing, subscription, password | From "Aby". Plain layout: the mark, one heading, short paragraphs, one midnight button. |

## Writing rules

- Same voice as the app: plain, short, number first. Sentence case, no exclamation marks.
- Money: `GH₵ 58.00` on WhatsApp, push and email; `GHS 58.00` in SMS. Always two decimals.
- Dates as `22 Oct`, times as `2:32 pm` (12-hour, lowercase am/pm). Add the weekday in the daily summary: `Thu 22 Oct`.
- Use the customer's first name only. Never put a balance, debt or purchase in a message to anyone but that customer.
- Credit reminders are polite and factual: no "overdue", "final notice" or threats. At most one reminder a week per customer, and only when the owner has turned reminders on.
- Links: every receipt link opens a web receipt (domain to be decided). Budget 25 characters for a link in SMS.

## Templates

Variables are in `{curly_braces}`. Examples use the demo shop.

### Receipt to customer

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

### Credit book reminder to customer

**SMS** (144 characters)

```
Hello {first_name}, this is {shop}. Your credit book balance is GHS {balance} (since {date}). Pay at the shop or by MoMo to {momo_number}. Thank you.
```

> Hello Amina, this is Scoops Tamale. Your credit book balance is GHS 45.00 (since 15 Oct). Pay at the shop or by MoMo to 024 000 0000. Thank you.

### Credit payment received, to customer

**SMS** (106 characters)

```
{shop}: we received GHS {amount} from you. Your credit book balance is now GHS {balance}. Thank you, {first_name}.
```

> Scoops Tamale: we received GHS 45.00 from you. Your credit book balance is now GHS 0.00. Thank you, Amina.

### Daily summary to owner

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

### Alerts to owner

Each alert is sent once per event, never repeated within the hour. The owner chooses which ones they get.

| Alert | Push title | Message (SMS form) |
| --- | --- | --- |
| Low stock | Running low | Aby: only 2 Vanilla tubs left at Scoops Tamale. You usually sell 6 a day. |
| Till not syncing (over 2 hours) | Till 2 hasn't synced | Aby: Till 2 at Scoops Tamale has not synced since 10:15 am. Its sales are safe on the device. Check its internet or power. |
| Sale voided | Sale voided | Aby: Ama voided sale #00142 (GHS 58.00) at 2:40 pm at Scoops Tamale. Reason: wrong flavour. |
| Cash short at close | Cash count is short | Aby: Scoops Tamale closed GHS 20.00 short. Expected GHS 1,410.00, counted GHS 1,390.00 by Ama. |

The till-not-syncing alert always says the sales are safe. Offline is normal; the owner only needs to act on the connection.

### Account messages

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
