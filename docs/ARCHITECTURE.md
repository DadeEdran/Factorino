# Architecture

> **Two sections, deliberately separated.**
> §A describes what **actually exists** in the repository right now.
> §B describes the **planned** Phase 1 architecture — it is not built yet and must not be read as if
> it were. As Phase 1 lands, content moves from §B to §A.
>
> The project spec: *never document architecture that does not exist.*

---

# §A — What exists today (2026-08-26)

The whole of Phase 1 plus Phases 2 and 3: the encrypted connection and its key management, the money
and date engines, the schema and repository layer, the design system and Persian shell, and six
screens on real data — Dashboard, Invoices, Customers, Customer detail, Products, Settings. What does
not exist yet is invoice **creation** (Phase 4), invoice **detail** and payment entry (Phase 5), and
everything from Phase 6 on.

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
  drift_schemas/         # drift_schema_v1..v4.json - the migration tests' baselines
  lib/
    core/
      money/                                      # pure Dart, zero Flutter imports (§3)
        money.dart                                #   Money value type + kMaxAmountRial ceiling
        rounding.dart                             #   half-up + overflow-checked multiply
        discount_allocation.dart                  #   largest-remainder distribution
        invoice_calculator.dart                   #   §4, step for step + clamp warnings (D-027)
                                                  #   + grossTotal, 2nd invariant (D-047)
      date/                                       # Jalali periods as UTC instant ranges (D-006)
        jalali_instant.dart                       #   instant <-> Jalali, offset as a parameter
        jalali_period.dart                        #   InstantRange + day/month/year boundaries
      formatting/                                 # the input boundary (§9)
        persian_text.dart                         #   THE normalizer: searchKey (D-025, D-029)
                                                  #   + keepDigitsOnly, the digit character class
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
        app_database.dart (+ .g.dart)             # @DriftDatabase, schemaVersion 4, migrations
        invoice_figures_backfill.dart             #   the v3 -> v4 backfill (D-056)
        soft_delete.dart                          # selectAlive / selectOnlyAlive / countAlive
        tables/                                   # six tables + SyncColumns mixin
      models/                                     # domain entities -- NO drift import (D-031)
        field_limits.dart                         # THE field lengths, shared with the forms (D-043)
        customer_totals.dart                      # billed + outstanding, from one query (D-044)
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
        app_text_field.dart                       #   THE text field; maxLength required (D-043)
        stat_tile.dart                            #   StatTile + TileGrid, shared by two features
        skeleton.dart  search_field.dart  load_more_footer.dart
        form_scaffold.dart                        #   screen forms: fields scroll, actions pinned
        editor_sheet.dart                         #   the same, for sheets (D-062, known issue 21)
        async_error_view.dart
    features/<feature>/
      presentation/                               # screens and forms
      application/                                # feature providers + the write-path controller
                                                  #   settings, customers, products
      domain/                                     # feature-shaped values assembled from models
                                                  #   dashboard_summary, customer_detail_view,
                                                  #   invoice_status_view, invoice_editor_state,
                                                  #   invoice_number_label (D-048),
                                                  #   invoice_summary_figures (D-056) - the summary
                                                  #     the form, the detail screen and the future
                                                  #     document renderer all take
    app.dart             # MaterialApp.router: themes, locale, RTL, router
    main.dart            # opens the database, overrides the provider, runs the app
  test/
    core/security/logging_path_test.dart            # scans lib/ for output outside AppLog (D-035)
    core/utils/list_query_test.dart                 # the paging window (D-038)
    core/formatting/jalali_display_test.dart        # dates, phones, ids, bidi isolation
    features/screen_harness.dart                    # locale + RTL + tier + router, as the app gives them
    features/customers/customers_screen_test.dart   # four states, two layouts, paging reaches SQL
    features/customers/customer_form_screen_test.dart # D-030 + the field limits, against behaviour
    features/customers/customer_detail_screen_test.dart # the record, the totals, the empty states
    features/customers/fake_customer_repository.dart  # shared by both customer screen suites
    features/products/product_form_screen_test.dart   # the limits on the remaining form
    features/invoices/invoice_editor_state_test.dart  # the draft model, wired to the engine
    features/invoices/invoice_preview_matches_write_test.dart # preview == stored, through the DB
    features/invoices/invoice_summary_figures_test.dart # an unrecorded gross, in the type and on screen
    data/database/invoice_figures_migration_test.dart   # v3 -> v4, both ladders, the arriving shape
    data/database/invoice_figures_backfill_test.dart    # what the backfill writes and refuses
    core/theme/theme_tokens_only_test.dart          # scans lib/ for literal colours and sizes
    core/widgets/field_limit_path_test.dart         # scans lib/ for raw text fields, literal limits
    core/money/single_calculation_path_test.dart    # only the preview and the write calculate (D-046)
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
    data/database/field_limits_test.dart            # where each column ACTUALLY refuses (D-043)
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
  stack and scroll position. Only routes whose screens exist are registered: `/customers/new`,
  `/customers/:id/edit`, `/customers/:id`, `/products/new`, `/products/:id/edit` and
  **`/invoices/new`**, each a child of its destination so the URL reads as a hierarchy and the shell
  keeps the right item selected.
  **`:id` is declared after the literal `new`**, or it would swallow it. گزارش‌ها is absent from
  navigation *and* from the router (D-021), and so are `/invoices/:id` and `/products/:id`.
- **Screens:** six, all on real data. Customers and Products list, search, page, create, edit and
  soft delete; the Dashboard and the Invoice list read live SQL aggregates over Jalali periods; the
  **customer detail** screen shows one customer's record, two per-customer aggregates and their
  invoices (D-044). Every text field goes through `AppTextField`, whose `maxLength` is required and
  comes from the same constants the columns carry (D-043).
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
- **Editing surfaces pin their commit action.** `FormScaffold` for screens and `EditorSheet` for
  bottom sheets both put the fields in the scrolling region and the primary action outside it, above
  the soft keyboard (D-053's split-by-purpose, D-062). A sheet built through `EditorSheet` cannot put
  its action among its fields, because it does not supply the layout. The **picker** sheets are
  deliberately outside this: they commit by tapping a row, so their list is their action.
- **Form input:** one text field, `core/widgets/app_text_field.dart`, with a **required**
  `maxLength` drawn from `data/models/field_limits.dart` — the same numbers the columns carry
  (D-043). A `lib/` scan fails the build on a raw `TextFormField`/`TextField` or on a limit written
  as a number, and a schema test asks each generated column where it actually starts refusing
  values. That second test exists because the obvious sharing — referencing the constant from
  `withLength(max:)` — silently produces a column with **no** length constraint at all.
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
suffix. `drift_schemas/` holds a dump per schema version, which is what the migration tests diff
against; `test/data/database/generated/` is the `drift_dev schema generate` output over them.

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
    utils/          # uuid, ListQuery paging window, the clock provider
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

## B.4 Data flow — **built** (increments d and f)

Reads are reactive: drift query streams surface through repositories as streams of **domain models**
(`watchAll`, `watchSearch`, `watchInPeriod`, `watchDetail`, `watchList`), and reach widgets as
`AsyncValue` through a feature provider. A widget never holds a repository.

**Aggregates are live too, and that is not a detail.** `watchCount`, `watchTotalIssuedRial`,
`watchIssuedCountInPeriod` and `watchOutstandingRial` are streams rather than futures because a
`Future` behind a provider answers once and is then quietly wrong: the next write does not invalidate
it, so a dashboard tile keeps showing a number that was true a minute ago. A count on a dashboard is
either live or it is a plausible lie, which is worse than no tile at all.

The dashboard composes them into a single `DashboardSummary` by awaiting each stream provider's
`.future`, so the whole page has one loading state, one error state, and one moment: it cannot show a
sales total from before a write beside a count from after it.

Writes own their transaction boundary, and two of them are the reason the boundary is there:

* **Invoice creation** resolves the tax chain against settings, runs the money engine, and writes
  the invoice with its lines in one transaction. A draft is written with **no number** (D-048).
* **Issuing** allocates the next sequence for the invoice's own **Jalali** issue-date year and
  writes it with the status change, in one transaction (D-013). Ten concurrent issues produce ten
  distinct numbers; moving the allocation outside makes that fail on the unique index, which was
  verified rather than assumed. A draft migrated from schema v1 already carries a number and keeps
  it — a spent number stays spent.
* **Payment recording** inserts the payment and recomputes the derived invoice status in the *same*
  transaction (§6). Splitting them would leave a window in which a paid invoice reads as unpaid, and
  a crash inside that window would make it permanent.

Reporting queries take an `InstantRange` from `core/date/` rather than a month number, which keeps
the Jalali decision in one place instead of in every query, and aggregate in SQL (§13). The dashboard
gets its range from `dashboardPeriodProvider`, which is `jalaliMonthOf(now)` and nothing else — the
only place in the application that decides what "این ماه" means.

**One reading of the clock.** "Now" is `nowProvider` (`core/utils/clock.dart`), read once per frame
and passed down (D-041). Two independent `DateTime.now()` calls inside one frame can straddle
midnight, and the visible result would be a tile reporting one Jalali month while the list beneath it
ages an invoice into the next.

**What the presentation layer is not given.** `InvoiceListItem` carries the invoice and the
customer's name — and no payment information. The `paid`/`partiallyPaid` determination is made in
`PaymentRepository` inside the payment's own transaction and persisted (§6); the UI cannot arrive at
a second, contradicting answer because it is not handed the inputs. The one thing it *does* derive is
`overdue`, which is not a stored status and must not be.

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

**Every figure a document prints is stored, from schema v4** (D-055). `invoices.gross_total_rial`
and, per line, `line_gross_rial` and `allocated_invoice_discount_rial` join the totals that were
already there, so an invoice can be laid out — header summary and line table alike — with **no read
site multiplying or rounding anything**. Every step between the printed columns is an addition or a
subtraction of stored figures. §4 step 1 carries a rounding rule, so a gross re-derived at render
time would be today's rule applied to yesterday's document: D-004's failure applied to arithmetic
rather than to price. The three are **nullable**, and null means *unknown* rather than zero — see the
migration note below.

**Snapshots:** `invoice_items` copies product title, unit, unit price and resolved tax rate at
creation time and never joins to the live product row for pricing (D-004). `invoices` copies the
**party** the same way from schema v3 — name, company, کد ملی, کد اقتصادی and address — written by
`issue()` inside the transaction that allocates the number, so a correction to a customer record
cannot rewrite a document that has been sent (D-052). The mobile is deliberately not part of it and
still resolves live. A draft has no snapshot, and neither has anything issued before v3; both read
through to the live customer, and `Invoice.party` / `Invoice.partyName` are the only two places that
fallback is written.

**Indexes:** invoice issue date, customer reference, status, invoice number (unique), and
`deleted_at`.

**Migrations:** `schemaVersion` set from the first release; existing migrations are never mutated;
`drift_dev` schema dumps back generated migration tests. A migration without a test is not done.

`onUpgrade` is a **ladder** (`if (from < n)`) rather than a switch on the version pair, because a
database can arrive from any older version, and it ends in a fail-loud default for a pair it does
not cover. Each step is bounded above by `to` as well as below by `from`, so a test can migrate to an
intermediate version and stop there; in the application `to` is always `schemaVersion`.

**v1 → v2** (D-048) makes the three invoice-number columns nullable so a draft carries no number
until it is issued. **v2 → v3** (D-052) adds the five party-snapshot columns to `invoices` and
`payment_term_days` to `settings`. **v3 → v4** (D-055, D-056) adds the three printed-figure columns
and, unlike either step before it, **backfills** them.

> **The backfill runs the money engine; it does not re-derive.** `backfillInvoiceFigures` rebuilds an
> `InvoiceInput` from each pre-v4 row's own stored columns, calls `calculateInvoice`, and writes the
> three new figures **only if the engine reproduces every figure already on the row** — each line's
> discount, net, tax and total, and the invoice's subtotal, total discount, total tax and grand total
> less its stored rounding adjustment. Otherwise that invoice's columns stay **null**, per invoice
> and never per line, and the read path says «ثبت‌نشده» rather than printing a zero. It is the third
> sanctioned caller in `single_calculation_path_test.dart`, listed rather than exempted: it is a
> *comparison* against storage, not a second producer of figures, and open-coding §4 step 1 in the
> data layer is exactly what D-046 exists to prevent.

> **A later version's columns reach back into an earlier step.** `Migrator.alterTable` builds its
> replacement table from the table **as currently declared** and copies every one of those columns
> out of the old one — so the moment v3 was declared, the shipped v1 → v2 rebuild began failing with
> `no such column`, on open, for every user who had not updated since the first release. The rebuild
> therefore computes its `TableMigration.newColumns` by asking the old table what it actually has,
> rather than from a list someone has to remember to extend; and the v2 → v3 step adds each column
> only if absent, because a v1 database arrives with them already present. Both are pinned by a
> v1 → v3 test through the production path.
>
> The same asymmetry reaches v4, and the shape is now **observed** rather than reasoned about: a v1
> database arrives at the v3 → v4 step with `gross_total_rial` already present (the rebuild brought
> it) and both `invoice_items` columns absent (that table is rebuilt by nothing), while a v3 database
> has none of the three. `migrateV1ToV2` is public alongside `migrateV2ToV3` so
> `invoice_figures_migration_test.dart` can run the ladder one step at a time and read
> `PRAGMA table_info` between them.

> **A table rebuild must not be wrapped in a transaction.** Relaxing `NOT NULL` needs SQLite's
> 12-step rebuild, whose step 6 is `DROP TABLE` — and with foreign keys enabled that cascades into
> every child row. `Migrator.alterTable` guards it by issuing `PRAGMA foreign_keys = OFF` *outside*
> its own transaction, which works only because drift invokes `onUpgrade` outside one. Wrapping the
> call in `db.transaction` makes SQLite silently ignore the pragma and deletes every `invoice_items`
> and `payments` row, with no error and with the schema still verifying as correct. Measured, and
> recorded on the call site.

`assertForeignKeysCanBeDisabled` (D-049) is called by a **rebuild** and by nothing else. It observes
one property — that `PRAGMA foreign_keys = OFF` takes effect here — and a step made only of
`ALTER TABLE ... ADD COLUMN` has no such precondition, so v2 → v3 does not call it. That is a
decision rather than an omission (D-052): a guard performed as a ritual stops being read. The claim
is checked instead, by running that step inside a transaction with children present and counting
them.

Two suites cover a migration, because they check different things: `SchemaVerifier` compares the
migrated **shape** against the version's dump, and a second suite migrates a database holding real
rows through `openAppDatabase` — a real encrypted file, foreign keys on — and counts them
afterwards. `SchemaVerifier.testWithDataIntegrity` is not used: it disables foreign keys, which is
the one condition under which the cascade cannot reproduce.
`integration_test/invoice_number_migration_proof_test.dart` and
`integration_test/customer_snapshot_migration_proof_test.dart` repeat the data proofs on the real
target, for the reason D-020's proof exists. The second runs **both** ladders — v2 → v3 and
v1 → v3 — because they are different code paths and only one of them rebuilds a table.

### The invoice form's three layouts (D-053)

The one screen where the tiers are three different arrangements rather than three widths, and the one
where the arrangement was decided by a measurement:

| Tier | Fields | Lines | Summary |
|---|---|---|---|
| Mobile | one column, one per row | cards, below the fields | breakdown **and** actions in a bar pinned to the bottom |
| Tablet | left pane | right pane, independently scrolling | breakdown and actions in a bar across both |
| Desktop | beside the breakdown | a real table, **full width** | breakdown scrolls with the fields; grand total and actions pinned |

**Why desktop is not a panel down the side, which is what §10 asks for.** `PageBody` caps content at
1240 for readability; a 320-pixel panel leaves 616 for a four-column table with two money columns, and
the amounts overflowed by 58. Money columns are fixed-width by rule (D-037), so they cannot absorb it.
The width goes to the table and the summary splits by purpose: the breakdown scrolls, the decision
stays. Full reasoning in D-053.

## B.6 The money engine — **built** (increment b)

`core/money/`, pure Dart with zero Flutter imports, enforced transitively by
`no_flutter_imports_test.dart`.

| File | Responsibility |
|---|---|
| `money.dart` | The `Money` value type — integer Rial, never `double` (D-002) — and `kMaxAmountRial` |
| `rounding.dart` | Half-up division, basis-point application, rounding to a unit, and an overflow-checked multiply |
| `discount_allocation.dart` | Proportional allocation with largest-remainder distribution |
| `invoice_calculator.dart` | §4 in order: gross → line discount → net → allocation → tax → totals → optional rounding, plus the clamp warnings (D-027) and `grossTotal` (D-047) |

Three properties are worth knowing before touching it:

**Two invariants are enforced at runtime, not just tested.** §4's proves the engine self-consistent;
the second proves the *printed summary* adds up by hand —
`grossTotal − totalDiscount + totalTax + roundingAdjustment == grandTotal` — which is a different
claim and the only one a customer actually makes (D-047).

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
