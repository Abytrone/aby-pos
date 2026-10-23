# Aby POS

Offline-first point of sale for small shops in Ghana. Flutter, GetX (MVC), drift (SQLite).
The local database is the source of truth; a Laravel API will sync with it later.

## Run

```sh
flutter pub get
dart run build_runner build      # regenerates lib/app/data/database/app_database.g.dart
flutter run -d <android-device>  # or: flutter run -d windows
flutter analyze
flutter test
```

Windows builds need Visual Studio 2022 with the "Desktop development with C++" workload.
On Windows, turn on Developer Mode (`start ms-settings:developers`) so plugins can be symlinked.

App icons: `dart run flutter_launcher_icons -f flutter_launcher_icons.yaml`.

## Changing the database

Installed tills keep their data, so every table change needs a migration:

1. Edit `lib/app/data/database/tables.dart`, bump `schemaVersion` in `app_database.dart` and add
   the step to `onUpgrade`.
2. `dart run build_runner build`
3. `dart run drift_dev schema dump lib/app/data/database/app_database.dart drift_schemas/drift_schema_vN.json`
4. `dart run drift_dev schema generate --data-classes --companions drift_schemas test/generated_migrations`
5. Add a case to `test/data/migration_test.dart`.

## Staff and closing the day

- First start asks for the owner's name and a 4-digit PIN. After that the app opens on
  "Who's on the till?". Sign-in is in memory only; restarting the app signs everyone out.
- Five wrong PINs lock that person (or owner approval) for 30 seconds.
- Sales record who rang them up. Voids need an owner: a cashier's void asks for an owner PIN, and
  the approving owner is recorded.
- Owners manage staff from Today → Staff.
- Today → Close day counts the drawer: opening float + cash takings = expected; the count shows over
  or short. A close covers every sale on this device since the previous close (by sale number), and
  those sales can no longer be voided.

## Layout

```
lib/
  main.dart                 GetMaterialApp, Aby themes, InitialBinding
  app/
    routes/                 route names and GetPage list (one Binding per page)
    bindings/               InitialBinding: database, device, repositories, sync, cart
    theme/                  brand kit (copied as-is from brand/flutter/lib/theme)
    data/database/          drift tables, AppDatabase, seed (Scoops Tamale)
    data/repositories/      catalog, sale, stock, staff, day close, outbox: the only code that touches drift
    services/               money (pesewas), ids (UUID v7), device, auth + PIN hashing, sync (stub)
    models/                 plain Dart domain classes and enums
    widgets/                shared UI (OptionChip)
    modules/                start, setup, sign_in, till, checkout, today, close_day, staff
                            (each: controllers, views, widgets, bindings)
```

## Rules in the code

- Money is integer pesewas everywhere. `formatMoney()` shows it as `GH₵ 1,234.00`.
- Every syncable row has `id` (UUID v7), `createdAt`, `updatedAt`, `deletedAt`, `syncedAt`, `deviceId`.
- Writes to syncable tables go through `AppDatabase.insertTracked` / `updateTracked`, which add an
  outbox row in the same transaction.
- Stock is an append-only ledger (`stock_movements`); stock on hand is a sum.
- Controllers call repositories, never drift. Views call controllers, nothing else.
- Lime is only for the Pay button, the waiting dot and cart counts.

Plug-in points for later work are marked `TODO(sync)`, `TODO(print)` and `TODO(auth)`.
