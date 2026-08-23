# Architecture

> **Two sections, deliberately separated.**
> §A describes what **actually exists** in the repository right now.
> §B describes the **planned** Phase 1 architecture — it is not built yet and must not be read as if
> it were. As Phase 1 lands, content moves from §B to §A.
>
> The project spec: *never document architecture that does not exist.*

---

# §A — What exists today (2026-08-23)

The scaffold plus **one real slice of the target architecture**: the encrypted database connection
and its key management. Nothing else of the application has been built.

```
Factorino/
  analysis_options.yaml  # flutter_lints 6.0.0 defaults, unmodified
  pubspec.yaml           # + drift, sqlite3 (hooks: source sqlite3mc), path_provider,
                         #   flutter_secure_storage, integration_test
  pubspec.lock           # canonical (pub.dev only) - re-sanitize after every resolve (D-014)
.gitattributes         # LF normalization (added after CRLF churn corrupted diffs)
.gitignore             # hardened 2026-08-23 (D-019)
.githooks/pre-commit   # lockfile-host / secrets / app-ID gate (D-019)
  tools/sanitize_lockfile
  assets/fonts/          # Vazirmatn 400/500/700 + OFL.txt (D-022) - not yet declared in pubspec
  drift_schemas/         # drift_schema_v1.json - the baseline for migration tests
  lib/
    core/
      money/                                      # pure Dart, zero Flutter imports (§3)
        money.dart                                #   Money value type + kMaxAmountRial ceiling
        rounding.dart                             #   half-up + overflow-checked multiply
        discount_allocation.dart                  #   largest-remainder distribution
        invoice_calculator.dart                   #   §4, step for step
      security/database_encryption_key.dart       # key type + OS-keystore key store (D-023)
      utils/uuid.dart                             # wrapper over package:uuid (D-024)
    data/database/
      encrypted_database.dart                     # THE single database opener (D-020)
      database_bootstrap.dart                     # key -> open -> migrate -> assert encrypted
      app_database.dart (+ .g.dart)               # @DriftDatabase, schemaVersion 1, migration
      soft_delete.dart                            # THE single `deleted_at IS NULL` helper
      tables/                                     # six tables + SyncColumns mixin
    main.dart            # bootstraps the database; renders nothing yet
  test/
    core/money/                                     # 70 tests: §4 cases + the invariant
    core/utils/uuid_test.dart
    data/database/connection_setup_order_test.dart  # pragma-ordering guard
    data/database/database_file_state_test.dart     # header classifier + startup assertion
    data/database/single_open_path_test.dart        # scans lib/ for bypass routes
    data/database/soft_delete_usage_test.dart       # scans lib/ for unguarded reads
    data/database/schema_shape_test.dart            # D-011 columns on every table
    data/database/app_database_test.dart            # schema behaviour, real encrypted file
  integration_test/
    d020_encryption_proof_test.dart                 # the end-to-end proof, per platform
    startup_test.dart                               # the real startup path, per platform
  android/  web/  windows/
  docs/
```

**The encryption slice, as built.** `openEncryptedDatabase` is the only function in `lib/` that may
open a database; a test fails the build if anything else does. It issues, in order,
`PRAGMA cipher = 'sqlcipher'` -> `PRAGMA legacy = 4` -> `PRAGMA key = "x'..'"` ->
`PRAGMA foreign_keys = ON` -> a forced read of `sqlite_master`, as Drift's `NativeDatabase(setup:)`
callback, which Drift invokes before any statement of its own. Ordering is checked at runtime by
`assertKeyPrecedesDatabaseAccess` and structurally by tests. Whether encryption is actually on is
decided by the file header, never by a pragma - see the three named traps in D-020. The key is a
256-bit random value from `Random.secure()`, held in the OS keystore with `resetOnError: false`
(D-023), and never logged.

- **State management:** none yet. `main.dart` opens the database, asserts it is encrypted, and
  renders an empty `Scaffold`; Riverpod and the real shell arrive in a later Phase 1 increment.
- **Money:** the §4 engine exists and is pure. It computes; the schema records. Nothing calls it
  yet — repositories (increment d) are what will feed it and persist its output.
- **Persistence:** connection layer **and schema v1** — six tables, the `SyncColumns` mixin, indexes,
  foreign keys with cascades, the seeded settings row, and the soft-delete helper. No DAOs and no
  repositories yet.
- **Routing:** none (a single `MaterialApp` home).
- **Localization:** none - the template is English and LTR.
- **Theme:** the default Material 3 `ColorScheme.fromSeed`.
- **Security:** encryption at rest is implemented and proven on Android and Windows; the startup
  assertion exists but is not yet called from `main.dart`. Manifest hardening, app lock, CSP and secure logging are not built. Repository hygiene is
  in place (hardened `.gitignore`, pre-commit gate).
- **Version control:** `main`, five commits, application ID `io.github.erysaw.factorino`.

**The schema, as built.** Every table mixes in `SyncColumns`, so the six D-011 columns cannot be
omitted by construction, and `schema_shape_test.dart` verifies it for every table rather than
trusting six copies to match. Reads go through `selectAlive`/`countAlive`, the single expression of
`deleted_at IS NULL`; `soft_delete_usage_test.dart` fails the build on a raw `select(` anywhere in
`lib/` unless the line carries a `// soft-delete-exempt:` comment giving a reason. Money is integer
Rial, rates are basis points and quantities are milli-units, checked mechanically by column-name
suffix. `drift_schemas/drift_schema_v1.json` is the dump future migration tests diff against.

**Generated files are committed on purpose — do not "clean them up".** `app_database.g.dart` and
any future `*.g.dart` are in version control because code generation on this machine needs network
access that is only available through the configured mirrors (D-014). A checkout that cannot run
`build_runner` must still analyze, test and build. Regenerate with
`dart run build_runner build` after touching any table, and commit the result.

Note also that `app_database.dart` imports `core/utils/uuid.dart` and `tables/sync_columns.dart`
without appearing to use them: the generated part file resolves `uuidV4`, `nowMillis` and the enums
through its parent library's imports. Removing those imports as "unused" breaks the build.

Platform scaffolds exist for Android, Web and Windows. Android and Windows both build with plugins
and native assets; Web has not been rebuilt since the plugins were added.

---

# §B — Planned architecture (Phase 1 target)

## B.1 Layering

Strictly one direction. Nothing skips a layer.

```
Widget  ──watch──▶  Provider  ──calls──▶  Repository  ──uses──▶  DAO  ──▶  SQLite (encrypted)
        (presentation)      (application)          (data)        (Drift)
```

**Hard rules, restated because they are the ones that erode first:**

- No business logic in widgets — no calculation, no formatting decisions, no branching on raw data.
- No database access in widgets.
- Repositories return **domain models**, never Drift-generated row classes. The Drift row type stops
  at the repository boundary; mapping happens there.
- `core/money/` imports **nothing from Flutter**, so it is testable without a widget binding.

## B.2 Folder structure

```
lib/
  core/
    theme/          # design tokens, ThemeData (light + dark)
    router/         # go_router configuration
    localization/   # ARB files, Persian strings, RTL setup
    formatting/     # money, date, digit, phone formatters
    money/          # Money value type + calculation engine (pure Dart)
    security/       # encryption key management, app lock, secure logging
    widgets/        # shared design-system components
    responsive/     # breakpoints + adaptive shell
    errors/         # failure types, error mapping
    utils/
  data/
    database/       # Drift tables, DAOs, migrations, connection setup
    models/         # domain entities (not Drift rows)
    repositories/   # interfaces + implementations
  features/
    dashboard/  customers/  products/  invoices/  payments/  settings/
      presentation/   # screens, widgets
      application/    # providers, controllers
      domain/         # feature-specific logic
  main.dart
```

## B.3 State management

Riverpod, code-generation flavor (D-007).

- Providers are scoped and `autoDispose` by default; global mutable state is avoided.
- Widgets watch the **narrowest possible selector** so one changed field does not rebuild a screen.
- The database and repositories are exposed as providers, which makes them overridable in tests
  against an in-memory database.

## B.4 Data flow

Reads are reactive: Drift query streams surface through repositories as streams of domain models and
reach widgets as `AsyncValue`. Writes go through repository methods that own their transaction
boundary — notably invoice creation (item snapshotting plus number allocation) and payment recording
(which recomputes and persists derived invoice status).

## B.5 Database design

**Connection setup** (D-016): opened directly with `drift` + `sqlite3` + `path_provider`, with the
encrypted native library supplied by `package:sqlite3` build hooks configured for `sqlite3mc`
(D-010). On every open, in this **exact order** (D-020):

1. `PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4;` — cipher selection, which must precede the key
   or it is silently ignored and the file gets the sqlite3mc default cipher instead
2. `PRAGMA key` from secure storage — **before any statement that touches the database**
3. `PRAGMA foreign_keys = ON` (D-017)
4. a forced `SELECT count(*) FROM sqlite_master`, so a wrong key fails here rather than later
5. only then anything Drift issues

Implemented in exactly one place — `openEncryptedDatabase`, the Drift `NativeDatabase(setup:)`
callback — so no call site can open a connection differently; `single_open_path_test.dart` fails the
build if one tries.

> **Keep the setup callback isolate-sendable.** The connection currently opens on the main isolate.
> Phase 13 moves it to `NativeDatabase.createInBackground`, which sends the `setup` closure to
> another isolate — so that closure must stay sendable: it may capture only the key string and
> plain data, never a `Ref`, a provider, a `BuildContext`, an open `File` handle, or anything
> holding a platform channel. Written down because the constraint is invisible until the day the
> move is attempted, and at that point a captured reference turns a one-line change into a rewrite
> of the opener.

 Getting the order wrong silently produces an unencrypted database on a new file,
or an undiagnosable `file is not a database` on an existing one. **Built and proven on both Android
and Windows as of 2026-08-23** (§A).

Windows stores the file under `%APPDATA%`, never beside the executable.

**Every user-data table carries** (D-011): `id TEXT` UUID v4 PK, `created_at INTEGER`,
`updated_at INTEGER`, `deleted_at INTEGER?`, `sync_status INTEGER`, `last_synced_at INTEGER?`.
All timestamps are UTC epoch milliseconds (D-005).

**Tables:** `customers`, `products`, `invoices`, `invoice_items`, `payments`, `settings` (single row).

**Integrity:** `invoice_items.invoice_id` and `payments.invoice_id` both reference `invoices.id`
`ON DELETE CASCADE`. Invoice deletion is a soft delete at the invoice level; the cascade exists for
hard cleanup only. Customers and products referenced by an invoice are soft-deleted only.

**Soft-delete discipline:** a single shared query helper applies `deleted_at IS NULL`, so it cannot
be forgotten at an individual call site (D-003).

**Snapshots:** `invoice_items` copies product title, unit, unit price and resolved tax rate at
creation time and never joins to the live product row for pricing (D-004).

**Indexes:** invoice issue date, customer reference, status, invoice number (unique), and
`deleted_at`.

**Migrations:** `schemaVersion` set from the first release; existing migrations are never mutated;
`drift_dev` schema dumps back generated migration tests. A migration without a test is not done.

## B.6 The money engine — **built** (increment b)

`core/money/`, pure Dart with zero Flutter imports, enforced transitively by
`no_flutter_imports_test.dart`.

| File | Responsibility |
|---|---|
| `money.dart` | The `Money` value type — integer Rial, never `double` (D-002) — and `kMaxAmountRial` |
| `rounding.dart` | Half-up division, basis-point application, rounding to a unit, and an overflow-checked multiply |
| `discount_allocation.dart` | Proportional allocation with largest-remainder distribution |
| `invoice_calculator.dart` | §4 in order: gross → line discount → net → allocation → tax → totals → optional rounding |

Three properties are worth knowing before touching it:

**The invariant is enforced at runtime, not just tested.** `calculateInvoice` computes the grand
total twice — by summing the lines, and as `subtotal − invoiceDiscount + totalTax` — and throws
`InvoiceReconciliationError` if they disagree. It should be unreachable; it is checked anyway
because the alternative to crashing on an inconsistent invoice is persisting one.

**Largest-remainder allocation is what makes the invariant hold.** Naive per-line rounding of an
invoice discount loses Rial (100 across three lines → 33+33+33 = 99), and a lost Rial is an invoice
whose lines do not sum to its total. Ties break toward the earlier line so the result is
deterministic — two devices must not disagree about an invoice after sync.

**The range check rejects, identically everywhere.** Products are checked against 2^53, not the
64-bit range, so the Dart VM and the Web refuse the same inputs (D-002's Web caveat). A `Money` is
constructed for every output, so no amount escapes the ceiling.

Money is a value type in the engine's API; the schema stores plain `int` Rial. The repository layer
(increment d) is the boundary that converts, in one place.

## B.7 Navigation

`go_router` (D-009), with routes for dashboard, customers, customer detail, products, product
detail, invoices, invoice detail, create/edit invoice, reports and settings. Web URLs are real and
shareable; deep links restore on Windows and Android.

Full navigation label set: داشبورد / فاکتورها / مشتریان / محصولات و خدمات / گزارش‌ها / تنظیمات.

**In Phase 1, گزارش‌ها is omitted entirely** — not disabled, not a coming-soon placeholder, and its
route is not registered either, so no deep link or typed Web URL can reach a screen that does not
exist. It arrives in Phase 8 (D-021). Phase 1 navigation is therefore:
داشبورد · فاکتورها · مشتریان · محصولات و خدمات · تنظیمات.

## B.8 Localization and RTL

`Directionality` is set once at the app root rather than fought per widget. Every user-facing string
goes through the localization layer from day one; no Persian literal is hardcoded inside a widget,
even though Persian is currently the only locale.

`core/formatting/` owns digit normalization (Persian `۰-۹` and Arabic-Indic `٠-٩` to ASCII), the
`ي`→`ی` / `ك`→`ک` mapping, and ZWNJ handling — applied at every numeric input boundary and to every
search term, so a customer saved as "علي" is found by typing "علی".

Numbers display with Persian digits and thousands separators. Invoice numbers, phone numbers and
national IDs get explicit bidi isolation so they do not visually scramble inside RTL text. Amounts
always carry a unit label; Toman is primary.

Icon mirroring is selective: directional navigation icons mirror; logos, media controls, checkmarks,
charts and numerals do not.

## B.9 Responsive strategy

Three tiers with genuinely different layouts, built on primitives in `core/responsive/` rather than
scattered `MediaQuery` checks.

| Tier | Navigation | Layout |
|---|---|---|
| Mobile | `NavigationBar` | Single column; invoice lists are **cards**, not squeezed tables |
| Tablet | Adaptive | Two-pane where useful, higher density |
| Desktop / Windows / Web | `NavigationRail` / `NavigationDrawer` | Multi-column, real data tables, master-detail, sticky invoice summary |

## B.10 Theme

All visual values are tokens in `core/theme/`; no hardcoded colors, sizes, radii or spacing inside
widgets. Tokens cover a neutral foundation plus one accent, semantic status colors (paid / unpaid /
draft / cancelled / overdue), a type scale including a dedicated prominent financial numeral style,
and spacing / radius / elevation scales favouring subtle borders over heavy shadows.

Dark mode is designed, not inverted: real surface hierarchy, muted secondary text, retuned status
colors.

## B.11 Security model

| Concern | Approach |
|---|---|
| Data at rest (Android, Windows) | Encrypted SQLite — `sqlite3mc` via `package:sqlite3` build hooks, SQLCipher-compatible format (D-010, D-020) |
| Encryption key | Random, generated once, in `flutter_secure_storage` (Keystore / DPAPI) |
| Data at rest (Web) | **Not encrypted** — disclosed in Persian in-app (D-012) |
| App lock | PIN (salted KDF hash) + biometric, idle timeout — Phase 9 |
| Secrets | `--dart-define-from-file`, gitignored, with a committed `.example` |
| Injection | Drift typed parameterized queries only (D-018) |
| Logging | Single wrapper; never logs identifiers, names or amounts; stripped in release |
| Errors | Friendly Persian messages; never a stack trace, SQL, path or raw exception |

**Threat model — covered:** lost or stolen device, shared Windows machine, casual local access,
accidental secret leakage into the repository, dependency supply-chain drift.
**Not covered in v1, and documented as such:** a fully compromised OS with root/admin access, and
browser-based storage on Web.

## B.12 Offline-first and the planned sync strategy

v1 has no network dependency and no account. The schema is nevertheless sync-ready from the first
migration (D-011) so that adding sync later does not require migrating live user data.

Planned sync (Phase 11, not designed in detail yet): Supabase with Row Level Security on every table,
last-writer-wins by `updated_at` as the starting conflict policy, soft-delete tombstones propagating
deletions, and `sync_status` driving the pending/synced/conflict queue. The one problem sync must
solve that the current schema only reserves space for is invoice-number collision across devices
(D-013).

## B.13 PDF boundary

Phase 1 defines `InvoiceDocumentGenerator` as a platform-neutral interface with a single
implementation that **fails loudly** rather than silently producing nothing. The interface takes a
fully computed, already formatted view model, so the eventual renderer cannot recompute — and
therefore cannot disagree with — the invoice totals.
