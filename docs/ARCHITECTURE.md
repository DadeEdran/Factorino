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
  tools/sanitize_lockfile  # run after ANY command that resolves deps, incl. build_runner
  assets/fonts/          # Vazirmatn 400/500/700 + OFL.txt (D-022) - not yet declared in pubspec
  drift_schemas/         # drift_schema_v1.json - the baseline for migration tests
  lib/
    core/
      money/                                      # pure Dart, zero Flutter imports (§3)
        money.dart                                #   Money value type + kMaxAmountRial ceiling
        rounding.dart                             #   half-up + overflow-checked multiply
        discount_allocation.dart                  #   largest-remainder distribution
        invoice_calculator.dart                   #   §4, step for step + clamp warnings (D-027)
      date/                                       # Jalali periods as UTC instant ranges (D-006)
        jalali_instant.dart                       #   instant <-> Jalali, offset as a parameter
        jalali_period.dart                        #   InstantRange + day/month/year boundaries
      formatting/                                 # the input boundary (§9)
        persian_text.dart                         #   THE normalizer: searchKey (D-025, D-029)
        number_input.dart                         #   digit folding + exact scaled parsing
        iranian_phone.dart                        #   09xxxxxxxxx, from +98 / 0098 / bare
        national_id.dart                          #   checksum; the field stays optional
        jalali_display.dart                       #   Jalali dates, phones, ids + bidi isolation
      security/                                   # (§7)
        database_encryption_key.dart              #   key type + OS-keystore key store (D-023)
        app_log.dart                              #   THE logging wrapper (D-035)
      errors/failure_message.dart                 # exception -> Persian copy; ARB only (§7)
      utils/
        uuid.dart                                 #   wrapper over package:uuid (D-024)
        list_query.dart                           #   the paging window (D-038)
    data/
      database/
        encrypted_database.dart                   # THE single database opener (D-020)
        database_bootstrap.dart                   # key -> open -> migrate -> assert encrypted
        app_database.dart (+ .g.dart)             # @DriftDatabase, schemaVersion 1, migration
        soft_delete.dart                          # selectAlive / selectOnlyAlive / countAlive
        tables/                                   # six tables + SyncColumns mixin
      models/                                     # domain entities -- NO drift import (D-031)
        customer.dart  product.dart  invoice.dart  invoice_item.dart
        payment.dart   invoice_detail.dart  invoice_draft.dart
        app_settings.dart  invoice_number.dart
        sync_status.dart  product_type.dart  invoice_status.dart  payment_method.dart
      repositories/                               # interfaces -- NO drift import (D-031)
        customer_repository.dart  product_repository.dart
        invoice_repository.dart   payment_repository.dart
        settings_repository.dart
        drift/                                    # implementations; drift lives here
          mappers.dart                            #   THE row -> domain boundary
          drift_customer_repository.dart  drift_product_repository.dart
          drift_invoice_repository.dart   drift_payment_repository.dart
          drift_settings_repository.dart
      providers.dart (+ .g.dart)                  # composition root (D-032)
    core/
      theme/                                      # THE only place a colour or size is named
        app_colors.dart      app_dimensions.dart
        app_typography.dart  app_theme.dart
      localization/                               # THE only place Persian text lives (D-034)
        arb/app_fa.arb                            #   the source of every user-facing string
        generated/app_strings*.dart               #   gen-l10n output, committed
      router/  destinations.dart  app_router.dart # go_router; reports unregistered (D-021)
      responsive/  breakpoints.dart  adaptive_scaffold.dart
      widgets/                                    # shared design-system components
        app_card.dart  status_badge.dart  empty_state.dart
        amount_text.dart  page_body.dart
        app_table.dart                            #   virtualized desktop table (D-037)
        skeleton.dart  search_field.dart  load_more_footer.dart
        form_scaffold.dart  async_error_view.dart
    features/<feature>/
      presentation/                               # screens and forms
      application/                                # feature providers + the write-path controller
                                                  #   settings, customers, products
    app.dart             # MaterialApp.router: themes, locale, RTL, router
    main.dart            # opens the database, overrides the provider, runs the app
  test/
    core/security/logging_path_test.dart            # scans lib/ for output outside AppLog (D-035)
    core/utils/list_query_test.dart                 # the paging window (D-038)
    core/formatting/jalali_display_test.dart        # dates, phones, ids, bidi isolation
    features/screen_harness.dart                    # locale + RTL + tier + router, as the app gives them
    features/customers/customers_screen_test.dart   # four states, two layouts, paging reaches SQL
    features/customers/customer_form_screen_test.dart # D-030 against behaviour, not only the ARB
    core/theme/theme_tokens_only_test.dart          # scans lib/ for literal colours and sizes
    core/localization/no_hardcoded_strings_test.dart # scans lib/ for Persian in code; checks D-030
    core/money/                                     # §4 cases, the invariant, D-027 clamps
    core/date/jalali_period_test.dart               # boundaries vs known Nowruz dates
    core/formatting/                                # normalizer, numbers, phone, national ID
      single_normalizer_path_test.dart              #   scans lib/ for a second normalizer
    core/utils/uuid_test.dart
    data/database/connection_setup_order_test.dart  # pragma-ordering guard
    data/database/database_file_state_test.dart     # header classifier + startup assertion
    data/database/single_open_path_test.dart        # scans lib/ for bypass routes
    data/database/soft_delete_usage_test.dart       # scans lib/ for unguarded reads
    data/database/schema_shape_test.dart            # D-011 columns on every table
    data/database/app_database_test.dart            # schema behaviour, real encrypted file
    data/database/search_name_roundtrip_test.dart   # write -> LIKE, through the real file
    data/providers_test.dart                        # the override seam
    data/repositories/
      domain_boundary_test.dart                     # scans for drift imports across the boundary
      repository_harness.dart                       # real encrypted file, wired as the app wires it
      customer_repository_test.dart  invoice_repository_test.dart
      payment_repository_test.dart   product_and_settings_test.dart
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

- **State management:** Riverpod is wired (D-032). `lib/data/providers.dart` is the composition
  root: `appDatabaseProvider` is synchronous and its default throws, `main.dart` opens the database
  and overrides it, and every repository is exposed as its **interface**. Feature providers live in
  each feature's `application/` folder; `appSettingsProvider` is the first and, so far, only one.
- **Money:** the §4 engine exists, is pure, and is now **called** — `DriftInvoiceRepository` runs it
  over a draft and persists the result as snapshots (D-004). A caller cannot supply a total, so a
  stored total cannot disagree with its lines. As of D-027 it also
  **reports** clamped inputs on `CalculatedInvoice.warnings` rather than absorbing them.
- **Persistence:** connection layer, schema v1, **and the full repository layer**. Five repositories
  behind drift-free interfaces (D-031), returning domain models. Invoice creation allocates its
  number inside the write transaction (D-013); payment writes recompute the derived invoice status in
  the same transaction (§6).
- **Routing:** `go_router` with a `StatefulShellRoute` over five destinations, each keeping its own
  stack and scroll position. Only routes whose screens exist are registered — as of (f1) that
  includes `/customers/new`, `/customers/:id/edit`, `/products/new` and `/products/:id/edit`, each
  a child of its destination so the URL reads as a hierarchy and the shell keeps the right item
  selected. گزارش‌ها is absent from navigation *and* from the router (D-021).
- **Screens:** Customers and Products read real data end to end — search, query-level paging,
  skeletons, two empty states, soft delete and create/edit forms. Dashboard and Invoices are still
  the unconditional empty states from (e) and arrive in (f2).
- **Localization:** both halves exist. The **input boundary** in `core/formatting/` -- digit folding,
  the letter folds, the single `searchKey` normalizer, phone normalization, the national-ID checksum,
  and display formatting for grouped numbers, percentages and quantities. The **presentation side**
  in `core/localization/` -- ARB, generated `AppStrings`, Vazirmatn declared at 400/500/700 with a
  per-platform fallback, locale pinned to `fa`, RTL set once at the root (D-034). No Arabic-script
  character may appear in code outside that directory, and a test enforces it.
- **Responsive:** three tiers in `core/responsive/` -- bottom `NavigationBar` on mobile, compact rail
  on tablet, extended 232 px rail with a header on desktop -- with the content column capped at a
  readable measure rather than stretched. Shared components live in `core/widgets/`.
- **Dates:** `core/date/` converts between stored UTC instants and Jalali civil dates, and computes
  Jalali reporting periods as half-open `InstantRange`s (D-006, D-028). Nothing reads the clock or
  the device timezone; the Iran offset is a parameter.
- **Theme:** a designed light and a separately designed dark theme, built from tokens in
  `core/theme/` (D-033). One Persian-turquoise accent, warm neutrals, six semantic status pairs as a
  `StatusPalette` theme extension, and a type scale whose largest style is the financial numeral
  style. Enforced: a literal colour or dimension outside the token files fails the build.
- **Logging:** one wrapper, `core/security/app_log.dart` (D-035). Closure messages, everything
  stripped from release builds by a compile-time constant, a shape-based scrubber, and the
  framework's own error path routed through it. A `lib/` scan fails the build on any other output
  path or on a sensitive field name inside a log call.
- **Security:** encryption at rest is implemented and proven on Android and Windows, and the startup
  assertion runs from `main.dart`. Errors reaching the UI are mapped to friendly Persian messages;
  no stack trace, SQL statement or path can surface (§7). Manifest hardening, app lock, CSP and
  secure logging are **not** built -- Phases 9 and 12. Repository hygiene is in place (hardened
  `.gitignore`, pre-commit gate).
- **Version control:** `main`, application ID `io.github.erysaw.factorino`, Persian display name in
  every platform manifest.

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

## B.3 State management — **built** (increment d)

Riverpod, code-generation flavor (D-007), wired in `lib/data/providers.dart` (D-032).

`appDatabaseProvider` is synchronous and throws by default; `main()` opens the database and overrides
it. Opening is a fail-loud, must-succeed step (D-020), so the alternative — an async provider — would
wrap every dependent value in an `AsyncValue` for a database that is never legitimately absent, and
would render a partial UI while a failed open resolved. The override is also the test seam: one line
swaps the entire data layer onto a temporary encrypted file.

Repository providers are typed as their **interfaces**, so nothing watching one can reach a drift
type through it.

Feature-level providers live in each feature's `application/` folder and watch the repository
providers, never a repository or a database directly. `appSettingsProvider` is the first of them.

> **Riverpod 3 wraps an error thrown inside a provider in a `ProviderException`.** A test — or an
> error handler — that matches on the inner type directly will not match; assert on the message, or
> unwrap first. Recorded because the symptom is a test that fails while the code is correct, and the
> obvious reading of the failure is the wrong one.

- Providers are scoped and `autoDispose` by default; global mutable state is avoided.
- Widgets watch the **narrowest possible selector** so one changed field does not rebuild a screen.
- The database and repositories are exposed as providers, which makes them overridable in tests
  against an in-memory database.

## B.4 Data flow — **built** (increment d), minus the widget half

Reads are reactive: drift query streams surface through repositories as streams of **domain models**
(`watchAll`, `watchSearch`, `watchInPeriod`, `watchDetail`). They will reach widgets as `AsyncValue`
once there are widgets.

Writes own their transaction boundary, and two of them are the reason the boundary is there:

* **Invoice creation** resolves the tax chain against settings, runs the money engine, allocates the
  next sequence for the issue date's **Jalali** year, and writes the invoice with its lines — all in
  one transaction (D-013). Ten concurrent creates produce ten distinct numbers; moving the allocation
  outside makes that fail on the unique index, which was verified rather than assumed.
* **Payment recording** inserts the payment and recomputes the derived invoice status in the *same*
  transaction (§6). Splitting them would leave a window in which a paid invoice reads as unpaid, and
  a crash inside that window would make it permanent.

Reporting queries take an `InstantRange` from `core/date/` rather than a month number, which keeps
the Jalali decision in one place instead of in every query, and aggregate in SQL (§13).

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

**Soft-delete discipline:** a single shared helper applies `deleted_at IS NULL` -- `selectAlive` for
rows, `selectOnlyAlive` for aggregates, `countAlive` for counts -- so it cannot be forgotten at an
individual call site (D-003). A test scans `lib/` and fails on a raw `select` / `selectOnly` /
`customSelect` that carries no `// soft-delete-exempt:` reason. Exactly one exemption exists:
invoice-number allocation reads the maximum sequence **including** deleted rows, because a spent
number stays spent (D-013).

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
| `invoice_calculator.dart` | §4 in order: gross → line discount → net → allocation → tax → totals → optional rounding, plus the clamp warnings (D-027) |

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

**Clamped inputs are reported, never absorbed** (D-027). `totalDiscount` is the sum of the discounts
*actually given*, and any discount capped on the way there appears on `CalculatedInvoice.warnings`
with both figures. Not an exception: the totals are correct and the invoice is usable — what is
questionable is the input, so the engine reports and the UI asks. The warning carries no message,
because user-facing text is Persian and this file may not reach the localization layer.

Money is a value type in the engine's API; the schema stores plain `int` Rial. The repository layer
(increment d) is the boundary that converts, in one place.

## B.6.1 The date and formatting layers — **built** (increment c)

Both pure Dart, both in `core/`, both tested against fixed known values rather than against their own
output.

`core/date/` (D-006, D-028). Reporting periods are computed **in the Jalali calendar first** and only
then converted to UTC instants, because the two calendars' month boundaries never coincide — a
Gregorian month applied to a dashboard tile produces a figure that matches nothing the user
recognises, and does so without looking wrong. Periods are half-open `InstantRange`s, so adjacent
periods tile the timeline exactly and nothing falls into the gap at a boundary. Nothing here reads
the clock or the device timezone: the Iran offset is a named constant taken as a parameter, so the
same input gives the same answer on a phone in Tehran and a laptop in Berlin.

`core/formatting/` (§9, D-025, D-029). The **input boundary**: every numeric field is normalized
before parsing, and every stored `search_name` and every search term is produced by one function,
`searchKey`. That single path is the load-bearing part — two call sites that normalize almost the
same way produce no error, just a customer who cannot be found — so it is enforced by a test that
scans `lib/`, exactly as the single database opener is (D-020), and verified end to end through the
real encrypted database rather than only as a unit.

## B.7 Navigation — **built** (increment e)

`go_router` (D-009), with routes for dashboard, customers, customer detail, products, product
detail, invoices, invoice detail, create/edit invoice, reports and settings. Web URLs are real and
shareable; deep links restore on Windows and Android.

Full navigation label set: داشبورد / فاکتورها / مشتریان / محصولات و خدمات / گزارش‌ها / تنظیمات.

Routes are registered only where the screen exists: the five destinations do, and the detail and
create routes arrive with the screens they open. A registered route resolving to nothing is the same
failure D-021 rejects, one level down.

**In Phase 1, گزارش‌ها is omitted entirely** — not disabled, not a coming-soon placeholder, and its
route is not registered either, so no deep link or typed Web URL can reach a screen that does not
exist. It arrives in Phase 8 (D-021). Phase 1 navigation is therefore:
داشبورد · فاکتورها · مشتریان · محصولات و خدمات · تنظیمات.

## B.8 Localization and RTL — **built** (increment e)

`Directionality` is set once at the app root rather than fought per widget. Every user-facing string
goes through the localization layer from day one; no Persian literal is hardcoded inside a widget,
even though Persian is currently the only locale.

`core/formatting/` owns digit normalization (Persian `۰-۹` and Arabic-Indic `٠-٩` to ASCII), the
`ي`→`ی` / `ك`→`ک` mapping, and ZWNJ handling — applied at every numeric input boundary and to every
search term, so a customer saved as "علي" is found by typing "علی". **This half is built** as of
increment (c); see §B.6.1. What remains planned here is the presentation side: ARB files, RTL,
Vazirmatn, and the Persian strings themselves.

Numbers display with Persian digits and thousands separators. Invoice numbers, phone numbers and
national IDs get explicit bidi isolation so they do not visually scramble inside RTL text. Amounts
always carry a unit label; Toman is primary.

Icon mirroring is selective: directional navigation icons mirror; logos, media controls, checkmarks,
charts and numerals do not.

## B.9 Responsive strategy — **built** (increment e)

Three tiers with genuinely different layouts, built on primitives in `core/responsive/` rather than
scattered `MediaQuery` checks.

| Tier | Navigation | Layout |
|---|---|---|
| Mobile | `NavigationBar` | Single column; invoice lists are **cards**, not squeezed tables |
| Tablet | Adaptive | Two-pane where useful, higher density |
| Desktop / Windows / Web | `NavigationRail` / `NavigationDrawer` | Multi-column, real data tables, master-detail, sticky invoice summary |

## B.10 Theme — **built** (increment e)

All visual values are tokens in `core/theme/`; no hardcoded colors, sizes, radii or spacing inside
widgets. Tokens cover a neutral foundation plus one accent, semantic status colors (paid / unpaid /
draft / cancelled / overdue), a type scale including a dedicated prominent financial numeral style,
and spacing / radius / elevation scales favouring subtle borders over heavy shadows.

Dark mode is designed, not inverted: real surface hierarchy, muted secondary text, retuned status
colors. The concrete palette, the type scale and the reasoning behind each choice are in D-033;
the short version is one Persian-turquoise accent, warm neutrals in light and slightly cool ones in
dark, borders instead of shadows, and colour reserved for status so that money can be the most
prominent thing on a card without competing with it.

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
