# Aby POS

Offline-first point of sale for small shops in Ghana. Flutter, GetX (MVC), drift (SQLite).
The local database is the source of truth and every feature works without the internet; a Laravel
API will sync with it later. The full feature plan is in [docs/FEATURES.md](docs/FEATURES.md).

## Run

```sh
flutter pub get
dart run build_runner build      # regenerates lib/app/data/database/app_database.g.dart
flutter run -d <android-device>  # or: flutter run -d windows
flutter analyze
flutter test
```

Windows builds need Visual Studio with the "Desktop development with C++" workload, and Windows
Developer Mode (`start ms-settings:developers`) so plugins can be symlinked.

App icons: `dart run flutter_launcher_icons -f flutter_launcher_icons.yaml`.

## Using the app

- **First start** asks for the shop name and the owner's name and 4-digit PIN, or offers
  *Restore from a backup* (moving to a new device). After that the app opens on "Who's on the till?".
- **Sell / Manage:** a navigation rail on tablets and desktops (bottom bar on phones). Sell and Today
  are the selling side; Staff, Activity and Settings are Manage. Each person only sees what their
  role allows.
- **Roles and approvals:** Owner, Manager, Cashier and Stock keeper are built in; owners can add
  roles with their own permissions (Staff → Roles). When someone lacks a permission (for example a
  cashier voiding a sale), anyone who has it approves with their PIN, and both are recorded.
- **Auto-lock:** after 3 idle minutes by default (Settings → Security). The cart is kept. The user
  menu in the header has *Switch user* and *Lock*.
- **Activity:** every sensitive action, who did it and who approved it. Entries are hash-chained;
  editing the database file outside Aby shows a warning here and in the status centre.
- **Backups:** an automatic daily copy on the device (the last 14 are kept), *Back up now*, and
  *Send a backup off this device*: an encrypted `.abybak` file (AES-256-GCM, protected by the backup
  password) shared to WhatsApp, Drive or email, or saved to a folder or USB stick. *Restore* keeps a
  safety copy of the current data first, then restarts the app.
- **Status centre:** the dot in the header. Green when backups are recent and the activity log is
  intact; amber or red with a fix button when not.
- **Selling:** the till has a Quick tab, All, categories and Recent. The box at the top searches,
  takes scans (and hardware keyboards) and short codes; type a number then tap a product to add
  that many. Weighed products and open prices ask for the amount. Tap a cart line to change it,
  give a discount (with a reason; above the role's limit someone approves with their PIN) or add
  a note. *Park* puts a sale aside under a name; parked sales show as tabs above the cart. The
  cart survives a crash or power cut.
- **Payments:** split a sale across cash, MoMo, card and the rest (Settings → Payments sets the
  methods, the shop's MoMo number and whether a transaction ID is needed). A transaction ID can
  only be used once. Cash totals can be rounded to 10 or 50 pesewas. *Open the drawer (no sale)*
  is in the cart menu and asks for a reason.
- **Customers:** Manage → Customers, or *Add a customer* on the cart (search by 4 digits of the
  phone). Credit sales go on their account with an optional limit and days to pay; record
  payments, see what is overdue, write off (owner), share a PDF statement or a WhatsApp
  reminder. The wallet holds money paid in ahead, kept change and refunds, and pays at the till.
- **Refunds and exchanges:** Today → *Refund* on a sale (or *Find a sale* by number, or *Refund
  without a receipt*). Choose what comes back, whether it goes back into stock, a reason and how
  the money goes back; or *Exchange instead* to put its value towards new items on the till.
  Voids ask for a reason.
- **Products:** prices per size (variants), option groups such as Toppings (with min, max and
  repeats), recipes that use stock, taxes (off, inclusive or exclusive), barcodes and a photo.
  *Tools* has bulk price changes, CSV export and CSV import (preview first; nothing is removed).
  A price can be scheduled for a later day from the product editor.
- **Stock:** stock items in pieces, grams or millilitres, with average cost, history, corrections
  and waste. *Deliveries* receives stock (cost, supplier, paid now or owed), *Counts* is the
  stocktake (blind or open), and *Suppliers* shows what is owed and records payments. Each item
  shows daily use, how long it lasts and a suggested low level.
- **Business day:** starts at 05:00 by default, so late-night sales count on the evening's day.
- **Close day:** Today → Close day counts the drawer (opening float + cash takings = expected) and
  locks those sales against voids.

## Layout

```
lib/
  main.dart                 runs AbyApp
  l10n/                     app_en.arb (all new UI text) and the generated AppLocalizations
  app/
    app.dart                GetMaterialApp, themes, locale, activity listener, AppRestarter
    bindings/               InitialBinding: the composition root for services and repositories
    routes/                 route names, GetPage list, AuthMiddleware
    core/                   permissions and built-in roles, typed settings, business day, tax,
                            units, validators, CSV
    domain/                 catalogue rules, inventory arithmetic, catalogue import/export
    theme/                  brand kit (copied as-is from brand/flutter/lib/theme)
    ui/                     shared design system: SectionPage, GroupCard, InfoTile, dialogs,
                            PinPad, OptionChip, approval prompt, status dot, labels, formatting
    data/database/          drift tables, AppDatabase, step-by-step migrations, seed
    data/repositories/      catalog, sale, refund, customer, payment methods, cash events, discounts,
                            parked orders, stock, supplier, receiving, stock count, staff, role,
                            day close, audit, settings, outbox:
                            the only code that touches drift
    services/               auth, permissions, session (auto-lock), settings, status, backup,
                            device, money, ids, PIN hashing, price scheduler, sync (stub)
    models/                 plain Dart domain classes and enums
    modules/                start, setup, sign_in, shell, till, checkout, today, close_day,
                            refund, customers, customer, products, product_editor, stock, stock_item, receive,
                            stock_count, supplier, staff, activity, settings
                            (each: controllers, views, widgets, bindings)
```

## Rules in the code

- Money is integer pesewas everywhere. `formatMoney()` shows it as `GH₵ 1,234.00`.
- Every syncable row has `id` (UUID v7), `createdAt`, `updatedAt`, `deletedAt`, `syncedAt`, `deviceId`.
- Writes to syncable tables go through `AppDatabase.insertTracked` / `updateTracked`, which add an
  outbox row in the same transaction. Sensitive actions also write `AuditRepository.record` in that
  transaction.
- Permission checks go through `PermissionService.authorize()`, which runs the approval prompt when
  needed. Never check roles by name.
- Stock is an append-only ledger (`stock_movements`); stock on hand is a sum.
- Controllers call repositories and services, never drift. Views call controllers.
- New UI text goes in `lib/l10n/app_en.arb` (`context.l10n.key`, or `appL10n()` in controllers).
  The older selling screens still have English literals; they move over as they are reworked.
- Lime is only for the Pay button, the waiting dot and cart counts.

Plug-in points for later work are marked `TODO(sync)`, `TODO(print)` and `TODO(storage)`.

## Changing the database

Installed tills keep their data, so every table change needs a migration:

1. Edit `lib/app/data/database/tables.dart` and bump `schemaVersion` in `app_database.dart`.
2. `dart run build_runner build`
3. `dart run drift_dev schema dump lib/app/data/database/app_database.dart drift_schemas/drift_schema_vN.json`
4. `dart run drift_dev schema steps drift_schemas lib/app/data/database/schema_versions.dart`
5. Add the `fromXToY` step to `stepByStep(...)` in `app_database.dart`.
6. `dart run drift_dev schema generate --data-classes --companions drift_schemas test/generated_migrations`
7. Add cases to `test/data/migration_test.dart`.
