# Roadmap

> Status values: `NOT_STARTED` · `IN_PROGRESS` · `BLOCKED` · `COMPLETED`
> Every phase carries a **security note**: what new data is stored, what new inputs
> are accepted, what new permissions or platform surfaces are touched, and whether the threat model
> changes.
>
> A phase is only `COMPLETED` when `flutter analyze` is clean and `flutter test` passes.

---

## Phase 0 — Environment and Setup

**Status:** `COMPLETED` — 2026-08-23. Toolchain established, all three platform scaffolds building,
`docs/` populated, and the **D-020 encryption proof passes end to end on both Android and Windows**.
Web remains the untested target and is addressed in Phase 12.

**Goal.** Establish the toolchain, verify every target platform builds, document the architecture and
seed `docs/`.

**Completed**

- Inspected the repository: a stock `flutter create` scaffold for android/web/windows, untouched
  except for the project spec.
- Recorded Flutter 3.47.1 (stable) / Dart 3.13.1; `flutter doctor` reviewed.
- Verified baseline build status on **all three** target platforms (see `CURRENT_STATE.md`).
- Verified SQLCipher availability empirically on Windows rather than assuming it — SQLite 3.53.4,
  `cipher_version 4.18.0 community`, encrypted file header confirmed, unkeyed reopen rejected.
- Resolved the full Phase 1 dependency set and pinned concrete versions (D-015).
- Discovered that `sqlcipher_flutter_libs` and `sqlite3_flutter_libs` are **end-of-life** and
  established the maintained replacement path (D-010).
- Discovered that pub.dev and Google-hosted infrastructure are unreachable from this machine, and
  identified working mirrors (D-014).
- Created `docs/` — `PROJECT.md`, `ROADMAP.md`, `CURRENT_STATE.md`, `ARCHITECTURE.md`,
  `DECISIONS.md`.

**Completed 2026-08-23**

- All four owner decisions settled and recorded: **D-014** (pub.dev only, VPN locally),
  **D-010** (encrypted SQLite via `package:sqlite3` build hooks, **`sqlite3mc`** by owner override —
  SQLCipher has no Web support and Web is a target), **D-015 / D-016** (drop `custom_lint`,
  `riverpod_lint`, `drift_flutter`), **D-019** (`git init` + commit policy).
- Three new decisions appended: **D-020** (`PRAGMA key` ordering), **D-021** (گزارش‌ها omitted from
  Phase 1 navigation), **D-022** (Vazirmatn standard variant, 400/500/700).
- The project spec reworded away from the SQLCipher brand to "encrypted SQLite".
- Git initialized on `main` with a hardened `.gitignore` and a versioned, verified pre-commit gate.
- Vazirmatn `v33.003` standard static TTFs (400/500/700) + `OFL.txt` committed to `assets/fonts/`,
  provenance and sha256 recorded in `docs/ENVIRONMENT.md`.
- `docs/ENVIRONMENT.md` created.
- **Build hooks need no experimental flag** on Flutter 3.47.1 — `enable-native-assets` defaults to on.
- Flutter 3.47.1 / Dart 3.13.1 pairing confirmed correct against the release cadence.

**Completed later on 2026-08-23**

- Mirrors configured user-globally (D-014 amendment); nothing mirror-related in the repository.
- `tools/sanitize_lockfile` written and verified; lockfile regenerated and canonical.
- Application ID set to `io.github.erysaw.factorino`.
- First three commits made; working tree clean.
- `.gitattributes` added after CRLF/LF churn was found corrupting diffs.
- **AndroidX resolution probe PASSED** — `flutter build apk --debug` succeeds with
  `flutter_secure_storage`; the APK carries `libdartjni.so`, so the native path is exercised.
  Required installing `android-35` and `cmake;3.22.1` by hand from the Tencent SDK mirror
  (SHA-1 verified), because `dl.google.com` is fully blocked.
- `compileSdk` pinned to 37 for `flutter_secure_storage`.
- `sqlite3mc` encryption verified on the Dart VM, and the D-020 ordering hazard **empirically
  confirmed** — a statement before `PRAGMA key` yields a plaintext file plus a misleading
  "file is not a database" error.

**Completed 2026-08-23 (the D-020 proof run)**

- **Both prerequisites cleared by the owner**: Windows Developer Mode is on
  (`AllowDevelopmentWithoutDevLicense = 1`), and a Redmi Note 8 Pro (Android 11, API 30, arm64) is
  attached over USB.
- **The stated ordering in D-020 was found to be wrong and was corrected.** A cross-open matrix
  showed `PRAGMA cipher = 'sqlcipher'` is **silently ignored when issued after `PRAGMA key`** — the
  earlier probe had been producing ChaCha20 files, not SQLCipher-format ones, with nothing to
  indicate it. The cipher pragmas must precede the key. D-010's "not locked in" reason depended on
  this and now carries the caveat.
- **Two further false witnesses named** in D-020: `PRAGMA cipher_version` returns empty under
  sqlite3mc, and `PRAGMA cipher` echoes back whatever the connection was configured with — it
  answers `sqlcipher` on an unkeyed in-memory database. The file header is the only evidence used.
- **Built the encryption slice**: `lib/data/database/encrypted_database.dart` (the single opener,
  the header classifier, the startup assertion) and `lib/core/security/database_encryption_key.dart`
  (256-bit key from `Random.secure()`, OS keystore, `resetOnError: false` — D-023).
- **Made the ordering structural rather than a matter of discipline**: 22 unit tests, including a
  guard that fails if any statement precedes the key, and a scan of `lib/` that fails if any file
  other than the sanctioned opener can open a database.
- **Windows proof PASSES 5/5** — encrypted header, no plaintext on disk, unkeyed and wrong-key
  reopens both rejected, keyed reopen intact, hazard reproduced and caught by the startup assertion,
  database under `%APPDATA%`.
- **Android proof PASSES 5/5** on a Redmi Note 8 Pro (Android 11, API 30, arm64) — same results as
  Windows, database under `/data/user/0/io.github.erysaw.factorino/files`, native library supplied
  by `lib/arm64-v8a/libsqlite3mc.so` (1.9 MB) packaged by the build hook with no manual native
  setup. Both traps and the ordering hazard reproduce identically on both platforms, so they are
  properties of sqlite3mc rather than of one platform's build.

**Remaining**

- Nothing blocking. Web is deliberately deferred: it has not been rebuilt since the plugins were
  added, and it gets no encryption at rest at all (D-012). Both belong to Phase 12.

**Known issues**

- MIUI refuses `adb`-driven installation until Developer options -> **Install via USB** is enabled.
  Worth knowing for any future device: the failure is `INSTALL_FAILED_USER_RESTRICTED` and it looks
  identical through `flutter test`, `adb install` and `pm install`.
- Drift's debug-only "database opened twice" warning appears in the proof run, because the test
  deliberately opens the same file several times in sequence to check rejection. Harmless here.
- Every `flutter pub get` re-contaminates `pubspec.lock` with the mirror host. `sanitize_lockfile`
  must be run after each resolve; the pre-commit hook is the backstop.
- `flutter doctor`'s "Android license status unknown" is a **stale check, not a failure**: the
  `--licenses` option is removed from the new Android CLI, the canonical licence hash file is
  present, and `flutter build apk --debug` succeeds. No licence files were fabricated to silence it.
- Web has not been rebuilt since plugins were added.

**Security note.** No user data is stored yet and no new inputs are accepted, but this phase now
ships the mechanism that protects all of it, so the threat model moved in four ways:

- **Encryption at rest is real and demonstrated on both Android and Windows**, not assumed: the file
  header is encrypted, a raw byte scan finds no plaintext, and both an unkeyed and a wrong-key
  reopen are rejected on each platform.
- **Three ways of "verifying" encryption were found to be false witnesses** and are now named traps
  in D-020. The dangerous one is `PRAGMA cipher_version`: it reads as "not encrypted" on a perfectly
  encrypted database, so anyone asserting on it would eventually "fix" the wrong thing.
- **The key-handling failure mode is now fail-loud rather than fail-silent** (D-023): the secure
  storage default would have deleted the database key on a read error, silently destroying every
  record. Disabled.
- **The single-opener rule is enforced by a test**, so a future call site that opens a database its
  own way — unkeyed, unencrypted, and entirely ordinary-looking in review — fails the build.

The three earlier items remain closed or bounded:

- The encryption package named in the project spec was end-of-life. Resolved by D-010 — encryption now
  comes from the maintained `package:sqlite3` build hooks, whose downloads are sha256-pinned and
  carry SLSA level 3 attestations from 3.5.2 onward.
- The dependency supply chain briefly routed through a third-party mirror — precisely the
  "dependency supply-chain drift" risk the project spec names. **Closed by D-014**: `pub.dev` is the
  only permitted host, the mirror-derived lockfile is to be destroyed rather than kept, and the
  pre-commit hook fails any commit that reintroduces another host.
- Repository hygiene now precedes the first commit rather than following it: the hardened
  `.gitignore` and the pre-commit secrets gate exist before any secret, keystore or local database
  could plausibly be created (D-019).

---

## Phase 1 — Foundation and Architecture

**Status:** `IN_PROGRESS` — increments (a) through (f1) complete, (a)–(f1) **accepted**; (f) was
split in two after the owner pulled the create/edit forms forward (D-036). (f2) is complete and
**awaiting review**; it is the last increment of the phase. See `CURRENT_STATE.md`.

Phase 1 is being delivered in six reviewable increments (owner, 2026-08-23), each reported and
stopped for review rather than landing as one pile. Nothing built here rebuilds the proven
connection layer (D-020, D-023); it is built on.

| # | Increment | Status |
|---|---|---|
| a | Drift schema, migration setup, soft-delete helper | `COMPLETED` 2026-08-23 |
| b | `core/money/` engine + unit tests (§4) | `COMPLETED` 2026-08-23 |
| c | Jalali date layer and digit normalization + tests | `COMPLETED` 2026-08-24 |
| d | Repositories and domain models | `COMPLETED` 2026-08-24 |
| e | Theme, localization, routing, responsive shell | `COMPLETED` 2026-08-24 |
| f1 | Logging wrapper, Customers and Products on real data | `COMPLETED` 2026-08-24 |
| f2 | Invoices list and Dashboard, on real data | `COMPLETED` 2026-08-24 |

(a) and (b) come before any UI work: everything else reads from the schema and the money engine, and
both are far cheaper to correct now than after screens depend on them.

**Increment (a) — completed 2026-08-23**

- Six tables: `customers`, `products`, `invoices`, `invoice_items`, `payments`, `settings`, each
  mixing in `SyncColumns` so the six D-011 columns cannot be omitted by construction.
- Foreign keys with the intended asymmetry: `invoice_items` and `payments` cascade from `invoices`;
  `invoices.customer_id` uses SQLite's default `NO ACTION`, so hard-deleting a referenced customer
  fails loudly instead of orphaning invoices (D-003).
- Indexes on every column that gets queried: soft-delete on all six, plus invoice issue date,
  customer, status, number year, and a unique index on the invoice number (§13).
- `soft_delete.dart` — `selectAlive` / `countAlive`, the single expression of `deleted_at IS NULL`,
  with `soft_delete_usage_test.dart` failing the build on an unexplained raw `select(` in `lib/`.
- `schemaVersion = 1`, migration strategy in place, `drift_schemas/drift_schema_v1.json` exported as
  the baseline future migration tests diff against. `beforeOpen` verifies foreign keys are actually
  on rather than assuming the opener's pragma took effect.
- The settings row is seeded in `onCreate` and kept single by a `CHECK (singleton = 1)` constraint,
  so no read path anywhere has to handle "configuration missing".
- `main.dart` now bootstraps: key → keyed open → migrate → **`assertDatabaseFileIsEncrypted`**. It
  renders an empty `Scaffold`; a temporary English placeholder would violate §1 on its way to being
  deleted, and Persian strings belong to the localization increment.
- Verified on both platforms, not only in unit tests: `integration_test/startup_test.dart` creates
  the six tables through the keyed connection on the Redmi and on Windows, confirms the file is
  encrypted, and reopens it with the key from the OS keystore.
- Three decisions recorded: **D-024** (UUID in-repo, no `package:uuid`), **D-025** (denormalized
  `search_name`), and an implementation note on **D-013** (numbering stored as year + sequence; the
  unique index covers soft-deleted rows).

**Increment (b) — completed 2026-08-23**

- `core/money/` in four pure-Dart files: `money.dart` (the `Money` value type and the
  `kMaxAmountRial` ceiling), `rounding.dart` (half-up arithmetic and the overflow-checked multiply),
  `discount_allocation.dart` (largest-remainder distribution), `invoice_calculator.dart` (§4 in
  order).
- **The reconciliation invariant is a test, not a comment** — and also a runtime check: the engine
  computes the grand total twice, from the lines and from
  `subtotal − invoiceDiscount + totalTax`, and throws `InvoiceReconciliationError` if they differ.
  The alternative to crashing on an inconsistent invoice is persisting one.
- **The ceiling rejects rather than truncates**, identically on every platform. Checked against
  2^53 rather than the 64-bit range, so the Dart VM and the Web refuse the same inputs: a
  calculation that succeeds on Android and silently drops digits on the Web would be worse than one
  that fails on both (D-002).
- 70 tests covering the §4 cases: zero quantity, fractional quantity, an item discount exceeding the
  line total, allocation remainders that do not divide evenly, mixed per-item tax rates, rounding
  boundaries, the ceiling, and a deterministic sweep of 450 input combinations all asserting the
  invariant.
- `no_flutter_imports_test.dart` enforces §3's zero-Flutter rule **transitively** through
  project-relative imports, so pulling in a helper that itself imports Flutter cannot slip past it.
- Decision recorded: **D-026** (tax-rate resolution treats `0` as a real rate, never as absent).

**Owner ruling on known issue #3 — carried out 2026-08-24 (D-027)**

- §4 step 9 now reports the **effective** discount, not the amount as entered. The project spec was amended: the wording was wrong, not the implementation of it.
- A clamped discount at either level is **surfaced to the caller as data** on
  `CalculatedInvoice.warnings` — an over-large discount is nearly always a data-entry error, and
  absorbing it silently is how a wrong figure reaches a document nobody questions. Not an exception:
  the totals are correct, the input is what is questionable, so the engine reports and the UI asks.
- The invoice-level clamp is unchanged in behaviour, as ruled; only its visibility is new.

**Increment (c) — completed 2026-08-24**

- `core/formatting/persian_text.dart` — **one** normalizer. `searchKey` produces both the stored
  `search_name` and the term queried against it (D-025, D-029), and folds digits, the Arabic letter
  variants, diacritics, tatweel, bidi controls and all whitespace to one opaque key.
- **The single path is enforced structurally, not by convention** —
  `single_normalizer_path_test.dart` fails the build if anything in `lib/` outside `core/formatting/`
  open-codes a character fold, or touches `searchName` without calling `searchKey`. The same
  treatment as the database opener, for the same reason: two call sites that normalize almost the
  same way produce no error at all, just a customer who cannot be found.
- **Round-tripped through the real encrypted database**, not only unit-tested
  (`search_name_roundtrip_test.dart`): written with `searchKey`, searched with a parameterized
  `LIKE`, across both letter variants, ZWNJ, and all three digit sets in one string. The normalizer
  can be perfect and the search still fail if the two sides disagree — that is the failure being
  tested for.
- `core/date/` — Jalali reporting periods as half-open UTC instant ranges (D-006). Periods are
  computed in the Jalali calendar and only then converted, and every boundary is tested against
  independently known Nowruz dates rather than against the implementation's own output. Esfand's
  length is never computed: a month ends where the next begins.
- **`InstantRange` is half-open** so adjacent periods tile the timeline exactly; an inclusive end
  would drop a payment recorded in the period's last millisecond.
- Nothing in `core/date/` reads the clock or the device timezone: the Iran offset is a named constant
  passed as a parameter (D-028), so a device in another timezone still gets Iranian boundaries.
- Iranian mobile normalization (`0`, `+98`, `0098`, and the bare country code, with any digit set and
  any separators) and the national-ID checksum, with the field remaining optional.
- Numeric input parsing that never routes a quantity through a `double`, and rejects more precision
  than `quantity_milli` can hold rather than silently truncating it.
- 140 new tests; 279 pass in total. Three decisions recorded: **D-027**, **D-028**, **D-029**.

**Increment (d) — completed 2026-08-24**

- **Domain models in `data/models/`, and the boundary made structural** (D-031). Interfaces live in
  `repositories/`, implementations one directory down in `repositories/drift/`, and neither the
  models nor the interfaces import drift at all — so a signature *cannot* name a row class.
  `domain_boundary_test.dart` fails the build if an import appears.
- Row classes renamed `*Row` via `@DataClassName`, which removes the collision between drift's
  generated `Customer` and the domain `Customer`. Dart-level only: the schema dump is byte-identical
  and **no migration is needed**.
- The four enums moved to `data/models/` so the dependency runs schema → domain, never the reverse.
- **`CustomerRepository` first**, as the first real call site of `searchKey`. `search_name` is
  written through the one normalizer on create **and on update** — the update path is the one that
  gets missed, and its failure is the quiet kind: the row is still found, by the name the user no
  longer typed.
- **Invoice number allocation inside the write transaction** (D-013), against the **Jalali** year of
  the issue date. Ten concurrent creates produce ten distinct numbers with no gaps; moving the
  allocation outside the transaction makes that test fail on the unique index, which was verified by
  doing it.
- **Payment writes recompute and persist the derived status in the same transaction** (§6), in both
  directions — recording a payment moves the status forward, removing one moves it back. `draft` and
  `cancelled` are never derived.
- Only a draft may be edited or deleted; anything else raises `InvoiceNotEditable`. Cancellation
  keeps the number, because a spent number stays spent.
- Editing a draft **soft-deletes** the replaced lines rather than removing them (D-003): a hard
  delete cannot be propagated, so the replaced line would resurrect on the first sync.
- The soft-delete guard now covers `selectOnly`, with `selectOnlyAlive` added beside `selectAlive`.
  Aggregates were the uncovered half and the worse one — a `sum` that forgets the filter just
  returns a larger number on a dashboard.
- **Riverpod composition root** (D-032, implementing D-007): every repository exposed as its
  interface, `appDatabaseProvider` synchronous and overridden from `main()`. Adding it re-resolved
  121 packages and drift/sqlite3/analyzer were unchanged — D-015 re-verified rather than assumed.
- 81 new tests; 360 pass in total. Decisions recorded: **D-030**, **D-031**, **D-032**.

**Increment (e) — completed 2026-08-24**

- **Design tokens** in `core/theme/`: one Persian-turquoise accent, warm neutrals, six semantic
  status pairs, a type scale with a dedicated prominent financial numeral style, and spacing /
  radius / border / elevation / motion scales (D-033). Light and dark are built **separately**, not
  derived from each other.
- **Tokens are enforced, not offered.** `theme_tokens_only_test.dart` fails the build on a literal
  colour, size, radius, spacing, font size or duration outside the three token files — verified to
  bite by introducing both kinds of violation.
- **Persian localization** through ARB and generated `AppStrings`, locale pinned to `fa`, RTL set
  once at the root (D-034). `no_hardcoded_strings_test.dart` fails the build on any Arabic-script
  character in code outside `core/localization/`, and additionally checks D-030's national-ID copy
  mechanically.
- **The platform manifests were user-facing English** and now carry the Persian name — Windows
  window title, Android label, web title and manifest. The Windows one is written as unicode escapes
  because MSVC read the source in the system codepage and produced mojibake from a pasted literal;
  found by screenshotting the running build.
- **go_router** with a `StatefulShellRoute`, so each destination keeps its own stack and scroll
  position. Only routes whose screens exist are registered: detail and create routes arrive with
  the screens they open. گزارش‌ها remains absent from both navigation and the router (D-021).
- **Three genuinely different layouts** (§10) in `core/responsive/`: bottom `NavigationBar` on
  mobile, compact rail on tablet, extended 232 px rail with a header on desktop, with the content
  column capped at a readable measure rather than stretched.
- Shared components in `core/widgets/`: card, section header, status badge, empty state, page frame,
  and `AmountText`, which holds the rule that money is never a bare number.
- Display formatting (`core/formatting/number_display.dart`): Persian grouping, percentages and
  milli-quantities, out of the widgets and into the formatting layer where §3 puts them.
- **Verified on the real Windows build**, not only in tests: three tiers captured in light, and the
  settings screen — the one screen with real data — captured in both themes. Two defects were found
  that no test would have caught: the longest destination label overflowed the compact rail at
  exactly one breakpoint, and the window title was mojibake.
- 25 new tests; 378 pass in total. Decisions recorded: **D-033**, **D-034**.

**Increment (f1) — completed 2026-08-24**

- **The logging wrapper** (D-035), built first because it is what makes every screen after it safe.
  One sink, closure messages so a release build never even forms the string, everything stripped in
  release, a shape-based scrubber as a backstop, and a `lib/`-scanning guard that fails the build on
  a `print` or on a sensitive field name inside an `AppLog` call. **Verified to bite** by introducing
  both violations and watching it fail on the exact lines, including across a formatter-wrapped
  multi-line call.
- **`platformDispatcher.onError` returns false**, and the entry in D-035 records why: returning
  `true` swallowed a startup failure, `runApp` was never reached, and the Windows runner — which
  shows its window only after the first frame — left a process running forever with no window and no
  message. Fail-loud restored.
- **Customers and Products, end to end on real data**: search (debounced, normalization-insensitive
  through the one `searchKey`), query-level paging (D-038), skeleton loaders shaped like the rows
  they replace, two distinct empty states, soft delete behind Persian copy that explains what
  survives, and create/edit forms (D-036).
- **Three genuinely different layouts** held: cards on mobile and tablet, a **virtualized** table on
  desktop (D-037) — asserted by a test that a full page of rows does not build a full page of
  widgets.
- **D-030 now has a live call site.** The national-ID field calls a failing checksum invalid plainly
  and shows **no affirmative message at all** on success; `customer_form_screen_test.dart` asserts
  the absence of the "format is valid" string and of any tick or verified icon.
- **`core/errors/`** arrives: one `describeFailure` that can only return ARB copy, and an
  `AsyncErrorView` that logs the real error exactly once in `initState` rather than on every rebuild.
- **Jalali display formatting** (`core/formatting/jalali_display.dart`) with bidi isolation for
  dates, phone numbers and identifiers, and the twelve month names passed in from the ARB so no
  Persian literal enters the formatting layer.
- 54 new tests; **432 pass in total**. Decisions recorded: **D-035**, **D-036**, **D-037**, **D-038**.

**Three defects found by running the Windows build, none of which a test would have caught**

1. **The money column was aligned the wrong way in RTL.** `alignEnd` resolves to the *left* edge in
   RTL, and numbers render left-to-right regardless — so the figures lined up by their first digit
   and the units digits were ragged, which is precisely what tabular numerals exist to prevent.
   Fixed by leading alignment in a fixed-width column, and the trap is documented on the flag.
2. **The floating label of the autofocused field was clipped.** An outlined field's label floats
   *outside* the field's box, the first field sits flush against the top of a scroll viewport, and a
   viewport clips its children. In Persian the failure is nastier than in Latin: the letter bodies
   survive and only the ascenders and the dots above them vanish, so it reads as a subtly misspelled
   word rather than as a layout fault. Fixed with room above the first field. Two wrong hypotheses
   (line height, then content padding) were tried and reverted before the real cause was found.
3. **The mobile floating action button covered the last row of every list.** Found by a widget test
   whose tap on the load-more control landed on the button instead — the same thing that happens to a
   user, with no warning printed. Fixed with a clearance token on the scrolling lists.

**Increment (f2) — completed 2026-08-24 · the last increment of Phase 1**

- **The Invoices list, end to end on real data.** Cards on mobile and tablet, a **virtualized**
  table on desktop reusing `AppTable*` (D-037), query-level paging from the first commit (D-038),
  skeletons shaped like the rows they replace, and a designed empty state that offers **no** create
  action — because the invoice form is Phase 4 and an affordance leading nowhere is worse than its
  absence (D-021, one level down).
- **The customer name is resolved by the same query as the invoice** (D-040), through a new
  `InvoiceListItem` domain model. Not a lookup per row: an N+1 read issued from a widget is
  invisible at ten invoices and ruinous at five thousand.
- **The Dashboard, on real SQL aggregates over Jalali periods.** Four tiles — sales, issued count,
  outstanding balance, customers — plus the five most recent invoices in the same row widgets the
  invoice list uses. Every figure is a `SUM` or a `COUNT` executed in SQLite; nothing is folded in
  Dart (§13). The two period tiles carry the Jalali month as a caption, so the user can see which
  month the app meant rather than trusting "این ماه".
- **All five reads are live** (`watchCount`, `watchIssuedCountInPeriod`, `watchOutstandingRial`,
  `watchTotalIssuedRial`, `watchList`), and they arrive as **one** `DashboardSummary` rather than as
  four providers — so the page cannot show a sales total from before a write beside a count from
  after it. Known issue 7 from (f1) is closed.
- **The outstanding balance is one statement**, not two subtracted in Dart: a correlated subquery
  sums each invoice's payments inside the aggregate. A join to `payments` would have multiplied each
  invoice's grand total by its number of payment rows — a defect invisible until an invoice takes its
  second instalment, and one that then overstates the figure the user trusts most. A repository test
  records two instalments against one invoice specifically to pin it.
- **`overdue` is derived, never stored** (D-041), from a single clock reading shared by the whole
  frame, and compared on **whole Jalali days**: an invoice due today is not overdue until today is
  over. Red is reserved for it alone.
- **The UI cannot recompute `paid`/`partiallyPaid`, structurally**: `InvoiceListItem` carries no
  payment information at all, so there is nothing to recompute from. The stored answer — written by
  `PaymentRepository` inside the payment's own transaction — is the only one that reaches the badge.
- 51 new tests; **483 pass in total**. Decisions recorded: **D-039**, **D-040**, **D-041**.

**Two defects corrected in the data layer, both found while building on it**

1. **`totalIssuedRial` counted drafts as revenue** (D-039). The name said "issued"; the query
   excluded only cancellations. Nothing depended on it until the dashboard existed — at which point
   "فروش این ماه" would have climbed as the user typed an invoice they had not issued. A test had
   asserted the old behaviour; it now asserts the corrected one, including that two drafts total zero.
2. **An invoice became unopenable when its customer was soft-deleted.** `findDetail` filtered the
   customer read with `selectAlive` and returned `null` when it found nothing — while the delete
   dialog promises the user in Persian that invoices already issued to that customer stay untouched.
   The invoice list would have dropped those invoices entirely. Both reads now take the customer row
   without the alive filter, marked `// soft-delete-exempt:` with the reason, and a repository test
   soft-deletes a customer and asserts the invoice still lists and still opens (D-040).

**Two layout defects found by the new widget tests, both RTL- or magnitude-specific**

1. **The amount column was too narrow for an invoice total.** `tablePriceWidth` was sized in (f1)
   against product *unit prices*; an invoice *grand total* is a different magnitude and overflowed
   it. Widened, with the reason recorded on the token so it is not trimmed back.
2. **The number-and-date line on the mobile card overflowed at 400 logical pixels.** Both runs are
   fixed-width and neither may be truncated — an ellipsised invoice number is not an invoice number
   — so the row became a `Wrap`. It costs eighteen pixels of height on the narrowest phones and
   cannot fail.

**Verified on the real Windows build**, not only in tests: dashboard and invoice list captured at
desktop and mobile widths and in dark mode, against twelve invoices covering all five stored statuses
plus a derived overdue. **Every tile was reconciled by hand against the seeded rows** — sales
excludes the draft, the cancellation and the invoice issued in the previous Jalali month; outstanding
came to exactly double the figure from a half-sized data set. The rows were written through the real
repositories by a throwaway script (the money engine computed every total, `_allocateNumber`
allocated every number), since Phase 1 has no way to *create* an invoice; the script was deleted
after use.

**Deferred out of (f2), deliberately**

- **Search and filtering on the invoice list.** Customers and products have a search field; invoices
  do not. Filtering by status, customer and date range is Phase 5 work (Invoice Management), and
  adding a half-version here would have to be replaced there.
- **Tapping an invoice.** `/invoices/:id` is **not registered**, and rows are not tappable — asserted
  by a test, so the absence is deliberate rather than forgotten. The detail screen is Phase 5.
- **Creating or editing an invoice.** Phase 4. The invoice list's empty state explains and stops
  rather than offering a button.
- **Report period selection.** The dashboard covers the current Jalali month only; choosing a period
  belongs with گزارش‌ها in Phase 8, which is still absent from navigation entirely (D-021).

**Security note (increment f2).** No new data is stored and no new input is accepted — every write
path in this increment already existed and was reviewed in (d). What changes is what is *displayed*:

- **Monetary totals and customer names now appear on two more screens.** Both go through the
  existing paths — `AmountText` for money, the ARB for every word — and neither is logged. The only
  log lines these screens can produce come from `AsyncErrorView`, which logs a provider failure once
  and carries no value.
- **No new permission, platform surface or dependency.** No package was added; the four new
  aggregate queries run on the same encrypted connection through the same Drift API, all
  parameterized, with no `customStatement` anywhere.
- **The threat model is unchanged.** The Android manifest hardening (§7) and the web CSP remain
  Phase 9 and Phase 12 work and are still **not** done.

**Remaining in Phase 1**

- Nothing. (f2) was the last increment; the phase is complete pending the owner's review of it.
  What was deliberately **not** built in Phase 1, and where it goes, is listed under (f2) above.

**Known issues**

- `onUpgrade` throws by design: there is no v1→v2 path yet. The first schema change must add both a
  migration step and a migration test (§6, §14) — and note that a build is already installed on the
  device, so its database will need that migration rather than a reinstall.
- The database opens on the main isolate. Phase 13 moves it to a background isolate; until then the
  `setup` closure must stay isolate-sendable, which is now recorded in `ARCHITECTURE.md` §B.5.
- ~~`search_name` is empty~~ — **resolved**: the repositories fill it on every create and update as
  of (d), and the guard is no longer vacuous.
- ~~§4 step 9 reports discounts as entered~~ — **resolved** by the owner's ruling, D-027.
- The national-ID checksum cannot catch every transposition: the rule maps remainders 1 and 10 onto
  the same check digit, so `0079542311` and `0079542131` both validate. That is the official
  algorithm, not a defect here; it is recorded as a test so nobody later invents a stricter rule than
  the one numbers are issued under. The UI must not present a passing value as a verified identity.

**Security note (increment f1).** The increment that makes §7's logging rule load-bearing, and the
first that displays third-party personal data on screen:

- **The logging wrapper exists and is enforced** (D-035). Nothing in `lib/` can write output another
  way, no sensitive field name can appear inside a log call, and **no build that ships emits
  anything at all** — the release strip is a compile-time constant, so the calls are removed rather
  than silenced.
- **The framework's own error path is covered.** A layout overflow dumps the offending widget
  subtree, which on these screens holds customer names and amounts; it now goes through the scrubber
  and is stripped in release like everything else.
- **National IDs, economic IDs and phone numbers are now accepted from the user and rendered on
  screen.** They are validated at the form boundary, stored through the repositories into the
  encrypted database, and never logged. The one log line a save produces carries the row id and
  nothing else.
- **No raw error can reach the user.** `describeFailure` can only return ARB copy, and a widget test
  asserts that a failure carrying a SQL statement and a database path surfaces as Persian with
  neither visible.
- **D-030 is enforced against behaviour**, not only against the ARB.
- No new permissions, no network, no new platform surface. Android hardening (`allowBackup=false`,
  `usesCleartextTraffic=false`, `FLAG_SECURE`, R8) and the web CSP remain Phase 9 and Phase 12 and
  are **not** done.

**Security note (increment e).** The first increment with a user-facing surface, so the threat model
gains a presentation boundary:

- **No user data is displayed yet** — the only real values on screen are the application's own
  settings. The screens that show customer and invoice data arrive in (f).
- **Errors surface as friendly Persian messages, never as raw exceptions** (§7). The settings screen
  maps an `AsyncValue.error` to `errorGenericTitle`/`errorGenericBody`; a stack trace, SQL statement
  or file path cannot reach the user through it.
- **D-030's constraint is now enforced by a test**, not only recorded: the national-ID copy must name
  the format and must not contain any word claiming the identity is confirmed.
- **No new permissions, no network, no new platform surface.** The manifest changes are display
  names only. Android hardening (`allowBackup=false`, `usesCleartextTraffic=false`, `FLAG_SECURE`)
  and the web CSP remain Phase 9 and Phase 12 work and are **not** done.
- Note for (f): the screens that will show national IDs, phone numbers and amounts are the first
  place §7's logging rule becomes load-bearing. The logging wrapper does not exist yet.

**Security note (increment d).** The first code that **writes** third-party personal identifiers,
so the threat model gains a write path:

- **National IDs, economic IDs and phone numbers now reach the encrypted database through
  repositories.** None of the domain models carry a `toString` that dumps their fields — `Customer`
  deliberately prints only its id — because a model's `toString` is what eventually ends up
  interpolated into a log line or an error message (§7).
- **Every query is Drift's typed, parameterized API** (D-018). Search terms in particular are bound,
  never interpolated, which matters because they are user text containing Persian and apostrophes.
- **Validation stays at the form boundary, not in the repository.** An unrecognised mobile number is
  stored as typed rather than silently discarded — a foreign client's number is data the user
  deliberately entered, and dropping it would be data loss dressed as tidiness.
- **Domain exceptions carry ids and statuses, never amounts or identifiers**, so an unhandled one
  cannot leak personal data through a stack trace.
- No new permissions, no network, no new platform surface. The only file written is still the
  encrypted database.

**Security note (increment c).** No new stored data, no new permissions, no network, no new platform
surface — but this is the increment that builds the **input boundary**, so the threat model gains
its first validation layer:

- **Every numeric input now has one place to be normalized and parsed**, and it returns `null` rather
  than throwing, so malformed input is an ordinary form state rather than an error path that might
  surface a raw exception to the user (§7 forbids that).
- **The national-ID and mobile validators are the first code to touch the highest-sensitivity
  fields.** Neither logs, and neither appears in an error message — the validators return booleans
  and normalized values, never diagnostics containing the value itself.
- **Search terms reach SQL as bound parameters, never interpolated** (D-018), demonstrated in the
  round-trip test rather than only asserted.
- The normalizer is pure and total: it has no failure mode on hostile input, since every code point
  either folds, drops, or passes through. Field-level length limits remain enforced at the schema
  boundary, which is what bounds the size of what it can be handed.

**Security note (increment b).** No new data, inputs, permissions or platform surface: the money
engine is a pure function over integers. Its security relevance is integrity rather than
confidentiality — a silent overflow on the Web would corrupt financial records just as effectively
as a bug in the storage layer, which is why the ceiling rejects rather than truncates and does so
identically on every target.

**Security note (increment a).** The schema now defines what is stored, so the threat model gains
real content:

- **The database holds third-party personal identifiers** — national ID, economic ID, mobile numbers
  — as of this increment. They are protected by the encryption proven in Phase 0, and none of them
  may ever reach a log (§7). Field-level length limits are enforced at the schema boundary, not only
  in the UI, because the UI will not be the only writer once backup import (Phase 6) exists.
- **No new inputs are accepted yet** — there are no screens and no import path. Validation of the
  values themselves (national-ID checksum, phone normalization) lands with the increments that
  first accept user input.
- **No new platform surface, no new permissions, no network.** The only file written is the
  encrypted database, in per-user application storage on both platforms.
- The one new failure mode is a corrupt or foreign database file, which `openEncryptedDatabase`
  refuses to open rather than writing into.

**Goal.** The complete skeleton — structure, theme, localization, database, repositories, routing,
money engine, responsive shell, and four screens reading real data. No feature depth.

**Tasks**

1. Feature-based project structure under `lib/`.
2. Riverpod setup with code generation.
3. Drift database with encrypted SQLite (`sqlite3mc`, D-010), the D-020 PRAGMA ordering, and secure key management.
4. Initial tables carrying the sync-ready columns (D-011).
5. Repository layer exposing domain models, never Drift rows.
6. `go_router` configuration with real URLs on Web.
7. Theme system and design tokens, light and dark.
8. Persian localization, RTL, Vazirmatn, digit normalization utilities.
9. Money engine in `core/money/`, pure Dart, **with unit tests**.
10. Jalali date utilities including Jalali-period boundary helpers.
11. Responsive app shell (mobile / tablet / desktop).
12. Dashboard, Customers, Products, Invoices screens — real data, no mocks.
13. `docs/` fully populated and kept current.

**Explicitly out of scope.** Supabase, authentication, cloud sync, PDF generation, AI features,
payment gateways, subscriptions, push notifications, advanced analytics.

**Security note.** This is the phase where the threat model becomes real. New at rest: the encrypted
SQLite database and the encryption key in platform secure storage. New inputs: all customer and
product free-text fields, plus every numeric field — each requiring boundary validation, length and
character-class limits, and digit normalization. New platform surfaces: Android Keystore / Windows
DPAPI via `flutter_secure_storage`, filesystem access under `%APPDATA%` on Windows. Android manifest
hardening (`allowBackup=false`, `usesCleartextTraffic=false`) and the Web CSP land here, as does the
logging wrapper that keeps national IDs, phone numbers, names and amounts out of every log.

---

## Phase 2 — Customers

**Status:** `NOT_STARTED`

**Goal.** Full customer management: list with search, create, edit, soft delete, detail view.

Includes normalization-insensitive Persian search (ی/ي, ک/ك, ZWNJ), Iranian mobile validation with
`+98` / `0098` handling, and national-ID checksum validation.

**Security note.** First storage of third-party personal identifiers — national ID, economic ID,
phone numbers. These are the highest-sensitivity fields in the product and must never appear in any
log or error message. Field-level length and character-class limits are enforced at the boundary.

---

## Phase 3 — Products and Services

**Status:** `NOT_STARTED`

**Goal.** Product and service catalogue: list, create, edit, soft delete, units, pricing.

**Security note.** No new sensitive data classes; commercial pricing only. Numeric input validation
against the `kMaxAmountRial` ceiling begins here.

---

## Phase 4 — Invoice Creation

**Status:** `NOT_STARTED`

**Goal.** The core flow: build an invoice from customers and products, per-line and invoice-level
discounts, tax resolution, live totals, transactional invoice-number allocation.

This phase consumes the Phase 1 money engine; it must not reimplement any part of it. The money
engine unit tests from the project spec must all pass before this phase can be marked complete.

**Security note.** No new data classes; the risk here is correctness rather than confidentiality. The
invoice-number sequence allocation must be transactional to avoid a race.

---

## Phase 5 — Invoice Management and Payments

**Status:** `NOT_STARTED`

**Goal.** Invoice list with filters, detail view, status lifecycle, cancellation, and payment
recording with derived `partiallyPaid` / `paid` status recomputed on every payment write.

**Security note.** Payment records add amounts and dates but no new identifiers. Editing rules become
a data-integrity control: only `draft` invoices are editable or deletable.

---

## Phase 6 — Backup and Restore

**Status:** `NOT_STARTED` — required in the MVP.

**Goal.** Encrypted export to a user-chosen location (Android SAF, Windows native dialog, Web
download), transactional import with version compatibility checking, and a last-backup reminder in
settings.

Deferred to later: scheduled backups, CSV export, cloud backup.

**Security note.** The highest-risk phase in the MVP. A backup file is the entire customer and
invoice database in one portable artifact. It must be encrypted with a user-supplied password via a
KDF (never the raw password as a key), carry a format version and an HMAC integrity check so a
tampered or corrupted file is rejected rather than partially applied, and import must be
all-or-nothing. The UI must state in Persian that losing the password means losing the backup.
Exported files must be covered by `.gitignore`.

---

## Phase 7 — PDF Generation

**Status:** `NOT_STARTED` — interface only in Phase 1.

**Goal.** Implement `InvoiceDocumentGenerator` with Persian shaping, RTL layout, Jalali dates,
Toman/Rial and a professional invoice layout. The renderer receives a fully computed, already
formatted view model and never recomputes totals.

**Security note.** Generated PDFs contain full customer and financial data and are written to
user-accessible storage. Temporary files must be cleaned up, and any share/print intent on Android is
a new outbound data surface.

---

## Phase 8 — Dashboard and Reports

**Status:** `NOT_STARTED`

**Goal.** Real aggregates over Jalali periods, computed in SQL rather than Dart loops.

**This is where "گزارش‌ها" enters the product.** Per D-021 it is omitted from navigation entirely
until this phase — no disabled item, no coming-soon placeholder, and no registered route. Adding the
destination here also means adding it to the navigation shell and the router for the first time.

**Security note.** No new data. Aggregation queries must remain parameterized (D-018) and must not
leak amounts into logs.

---

## Phase 9 — Security Hardening and Audit

**Status:** `NOT_STARTED`

**Goal.** App lock (PIN + biometric via `local_auth`), idle auto-lock and lock on resume, PIN stored
only as a salted KDF hash, `FLAG_SECURE` on financial screens, R8 and resource shrinking, release
signing from a gitignored properties file, and a full pass over the §7 checklist.

**Security note.** Adds the biometric permission and a new authentication surface. Revisit the Web
in-memory-key question deferred in D-012.

---

## Phase 10 — Authentication · Phase 11 — Supabase Cloud Sync

**Status:** `NOT_STARTED`

Sync is where D-013 (invoice-number collisions across devices) must finally be solved, and where the
`sync_status` columns shipped in Phase 1 come into use.

**Security note.** The first outbound network surface in the product. Only the anon key ships in the
client; Row Level Security is enabled on every table from the first migration. The threat model gains
a server and a transport.

---

## Phase 12 — Web and Windows Optimization · Phase 13 — Performance · Phase 14 — Testing · Phase 15 — Release

**Status:** `NOT_STARTED`

Phase 12 includes the Drift-on-Web setup (`sqlite3.wasm` + worker in `web/`) and the Persian font
preload/subset work. Phase 13 covers query indexing and startup time against realistic data volumes.
Phase 14 broadens coverage to repository and widget tests. Phase 15 covers store metadata, signing,
and the release checklist.

**Security note.** Phase 15 is the last point at which the §7 checklist can be verified end to end
before real user financial data exists on real devices.
