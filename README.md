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
    core/                   permissions and built-in roles, typed settings, business day
    theme/                  brand kit (copied as-is from brand/flutter/lib/theme)
    ui/                     shared design system: SectionPage, GroupCard, InfoTile, dialogs,
                            PinPad, OptionChip, approval prompt, status dot, labels, formatting
    data/database/          drift tables, AppDatabase, step-by-step migrations, seed
    data/repositories/      catalog, sale, stock, staff, role, day close, audit, settings, outbox:
                            the only code that touches drift
    services/               auth, permissions, session (auto-lock), settings, status, backup,
                            device, money, ids, PIN hashing, sync (stub)
    models/                 plain Dart domain classes and enums
    modules/                start, setup, sign_in, shell, till, checkout, today, close_day,
                            staff, activity, settings (each: controllers, views, widgets, bindings)
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
