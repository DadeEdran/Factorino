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

**Status:** `COMPLETED` 2026-08-24 — all seven increments delivered and **accepted** by the owner.
(f) was split in two after the owner pulled the create/edit forms forward (D-036); (f2) was the last.

Note for anyone planning Phase 2 or Phase 3: **(f1) delivered most of what those phases originally
named.** Both entries were re-scoped accordingly (D-042) — read their "already delivered" lists
before planning, and do not rebuild the customer or product screens.

Phase 1 was delivered in reviewable increments (owner, 2026-08-23) -- six planned, seven delivered
after (f) was split -- each reported and stopped for review rather than landing as one pile. Nothing built here rebuilds the proven
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

All seven increments are **accepted**. Phase 1 is closed.

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

**Status:** `COMPLETED` 2026-08-25. Both items D-042 re-scoped this phase down to are delivered:
the customer detail screen, and the field-level limits at the form boundary.

**Already delivered in Phase 1 (f1), accepted, and not rebuilt:** the customer list at all three
tiers with query-level paging, normalization-insensitive Persian search through the one `searchKey`,
create and edit forms with Iranian mobile and national-ID validation (D-030), soft delete behind
Persian copy that explains what survives, two distinct empty states and a Persian-only error path.

**Completed**

- **The customer detail screen at `/customers/:id`** (D-044), registered **with** the screen (D-021)
  and after `/customers/new` in the router, because `:id` would otherwise swallow the literal `new`.
  - The full record, with the national ID, economic ID and mobile rendered through the
    bidi-isolating formatters so they cannot reorder inside Persian text (§9).
  - **That customer's invoices, through `InvoiceRepository.watchForCustomer`** — the method built in
    (d) that had no call site until now. Reused rather than replaced, and the customer name on each
    row is the one already loaded rather than a lookup per row.
  - **Per-customer totals as one SQL statement**, not a fold over the invoice list: billed and
    outstanding as two `FILTER`ed aggregates over different populations, with the outstanding side
    using the same correlated subquery `watchOutstandingRial` does. Billed excludes drafts and
    cancellations (D-039) and the caption on the tile says so, so the figure reconciles against the
    rows beneath it.
  - `InvoiceCard` / `InvoiceTableRow` reused, with `showCustomer: false` — the name would be
    identical on every row of that customer's own page (D-044).
  - **Invoice rows stay non-tappable**, asserted by a test, until `/invoices/:id` exists in Phase 5.
  - A designed empty state for a customer with no invoices, offering **no** create action: the
    invoice form is Phase 4.
  - Two genuinely different layouts: a sticky record panel beside a virtualized table on desktop; on
    a phone, one sliver-backed scroll with the record **collapsed by default**, so a record whose
    height has no upper bound cannot push the invoice list off the page.
  - `StatTile` and `TileGrid` moved to `core/widgets/`, now that two features use them.
- **Field-level limits at the form boundary** (D-043), the §7 requirement that was named in Phase 1
  and not built.
  - One source of truth, `data/models/field_limits.dart`, read by every form field.
  - `AppTextField` with a **required** `maxLength`, so half the rule is the compiler's.
  - `field_limit_path_test.dart` fails the build on a raw `TextFormField`/`TextField` in `lib/`, or
    on a `maxLength` written as a number rather than a shared constant.
  - `field_limits_test.dart` asks each generated column where it actually begins refusing values and
    fails if that disagrees with the constant — which is what stands in for the sharing that drift
    cannot express (see below).
  - Character class where one is meaningful: the national ID, economic ID and price fields accept
    digits only, in whichever of the three sets the user types.
  - A length validator in drift's own unit (`String.length`), because `maxLength` counts grapheme
    clusters and the two differ for Persian carrying combining marks.
- **Applied to the product form too**, which is all that remained of Phase 3.

**A finding worth carrying forward.** The obvious way to share the limits — referencing the constant
from `withLength(max:)` — **compiles and silently produces a column with no length constraint at
all**, because `drift_dev` reads that argument with `readIntLiteral`. Verified by doing it and
diffing the generated code; `build_runner` reported nothing. Full detail in D-043.

**A defect corrected on the way through.** Deleting a customer or product **from a list row** threw
`UnmountedRefException`: the auto-disposed editor controller was collected during the await, so the
state write after it failed — after the delete had already happened. It shipped in (f1) because the
only exercised call site was the form, which watches the controller and therefore keeps it alive.
Fixed with a scoped `ref.keepAlive()` link around each write (D-045), and both list delete paths now
have tests.

**Decided, not deferred.** D-042's third item asked whether an invoice row should link to its
customer once this screen existed. **It should not** — an invoice row's primary target must be the
invoice, which arrives in Phase 5, and putting the customer there would be an affordance that has to
be taken away again (D-044).

**Verified**

```
flutter analyze : PASS (No issues found)
flutter test: PASS (529, was 483)
Windows build: PASS  built, and the screen exercised against the real encrypted database at
                  1400x900 and 400x800, in light and dark, with both figures reconciled by hand
Android build: PASS  flutter build apk --debug
```

**Security note.** No new data is stored and no new sensitive class is introduced, but two things in
the threat model genuinely move:

- **§7's field-level limits are now enforced**, which is the requirement this phase existed to
  close. Length and character class are applied at the form boundary, from the same constants the
  columns carry, and a new field cannot be added without a limit. The boundary is no longer "the
  database will refuse it eventually, with a message the user cannot act on".
- **The whole customer record appears on one screen for the first time** — name, company, mobile,
  national ID, economic ID, address, notes. That makes it the likeliest place for an innocuous debug
  line to violate §7's logging rule, so the guard was **verified to cover it**: a plausible
  `AppLog.debug` interpolating `fullName`, `nationalId` and `mobile`, wrapped across lines as the
  formatter would leave it, was introduced and `logging_path_test.dart` failed on all three
  accessors by name. The screen makes no log call of its own; the only line it can produce comes
  from `AsyncErrorView`, which logs a provider failure once and carries no value.
- **No new permission, platform surface or dependency.** The new aggregate runs on the same
  encrypted connection through the same parameterized Drift API, with no `customStatement`. Android
  manifest hardening (§7) and the web CSP remain Phase 9 and Phase 12 and are still **not** done.

---

## Phase 3 — Products and Services

**Status:** `COMPLETED` 2026-08-25. The one item D-042 left in this phase is delivered.

**Already delivered in Phase 1 (f1), accepted, and not rebuilt:** the catalogue list at all three
tiers, normalization-insensitive search, create and edit forms, product/service type, free-text
units, pricing with the `kMaxAmountRial` ceiling enforced in Persian (D-002), and soft delete behind
Persian copy that explains the price snapshot (D-004).

**Completed**

- **Field-level limits on the product form**, using the same `AppTextField` and the same shared
  constants Phase 2 built (D-043). Name, unit and description take their column's limit; the price
  field takes `AmountLimits.tomanDigits`, which is the width of the largest amount that can exist
  rather than a column length — money is stored as an integer (D-002) — and the ceiling validator
  that was already there still refuses anything past `kMaxAmountRial`.
- The product form's first tests: the limits read off the widget rather than compared against a
  number copied into the test, the truncation at the boundary, the digits-only price field, and the
  ceiling still refusing in Persian.

**Deliberately not in this phase.** A product detail screen. §11 lists the route, but the edit form
already shows every field a product has, and the only question a detail screen could answer that the
form cannot — "where has this been sold, and at what price" — is a **report**. It belongs to Phase 8,
and `/products/:id` gets registered there, with the screen, per D-021 (D-042).

**Security note.** No new sensitive data classes; commercial pricing only. The amount ceiling was
already enforced. What this phase adds is the length and character-class boundary described in Phase
2's note, applied to the one remaining form.

---

## Phase 4 — Invoice Creation

**Status:** `COMPLETED` 2026-08-27 — every increment delivered; (d) awaits the owner's manual pass on
the phone. The largest and most consequential phase in the project, split into four increments at the
owner's instruction and grown to seven, each reported and stopped for review rather than landing
whole.

| # | Increment | Status |
|---|---|---|
| a | The draft state model and its wiring to `core/money/` — no UI, fully tested | `COMPLETED` 2026-08-25, **accepted** 2026-08-26 |
| a2 | **Numbering on issue, and the project's first migration** (D-048) | `COMPLETED` 2026-08-26 — device proof **passed** |
| a3 | **The table-rebuild guard** (D-049) — the cascade defect made structural | `COMPLETED` 2026-08-26, **accepted** |
| b | Line item entry: product picker, free-text lines, quantity, per-line discount and tax | `COMPLETED` 2026-08-26, **accepted** |
| c | Invoice-level fields: customer, dates, discount, tax, notes, **and the save** | `COMPLETED` 2026-08-26, **accepted** |
| c2 | **The party snapshot and the payment term** (D-051, D-052) — `schemaVersion = 3` | `COMPLETED` 2026-08-27, **accepted** |
| d | **The assembled screen** at all three tiers, on real data (D-053) | `COMPLETED` 2026-08-27 — device pass **passed** |

Increment (a2) was not in the owner's original four-way split. It was pulled out of (c) and placed
**before (b)** on the owner's instruction when D-048 was approved: it is the project's first schema
migration and a build is already installed on a real device, so it deserved its own reviewable step
rather than arriving folded into a screen.

**Goal.** The core flow: build an invoice from customers and products, per-line and invoice-level
discounts, tax resolution, live totals, transactional invoice-number allocation. This phase
**consumes** the Phase 1 money engine and must not reimplement any part of it.

**Increment (a) — completed 2026-08-25**

- **`InvoiceEditorState`** (`features/invoices/domain/`): an immutable value holding the invoice
  being edited — customer, dates, lines, invoice-level discount and tax override, notes — and
  exposing `totals`, the `CalculatedInvoice` the engine produced for it. It computes nothing itself;
  every edit produces a new state whose constructor re-runs `calculateInvoice`, so a figure on screen
  can never belong to an earlier version of the lines (D-046).
- **`InvoiceLineEntry`**: one line, in parsed typed values only — `Money`, an integer
  `quantityMilli`, basis points. Title, unit and unit price are carried as **snapshots** even when a
  product is chosen (D-004).
- **The engine is the only calculator, structurally.**
  `test/core/money/single_calculation_path_test.dart` fails the build if anything in `lib/` outside
  `core/money/` calls `calculateInvoice` other than the state model and the repository. **Verified to
  bite** with a plausible `previewTotal()` helper on the invoice list screen.
- **The preview and the write are pinned against each other.**
  `invoice_preview_matches_write_test.dart` builds a state, writes its draft through the **real
  encrypted database**, and asserts every stored figure equals the previewed one — totals, warnings,
  and each line's effective discount, resolved tax rate, net, tax and total. This is the test that
  makes "the number the user agreed to is the number that was stored" a checked property rather than
  a hope.
- **`CalculatedInvoice.grossTotal` added to the engine** (D-047), with a second runtime invariant:
  `grossTotal − totalDiscount + totalTax + roundingAdjustment == grandTotal`. §4's invariant proves
  the engine self-consistent; this one proves the **printed summary** adds up by hand, which is a
  different claim and the only one a customer actually makes. A subtotal-based summary is short by
  exactly the line discounts, and a test states that trap explicitly.
- **D-027's warnings finally have a consumer.** `invoiceWarningMessage` maps an `InvoiceWarning` to
  Persian from the ARB, always naming **both** figures — requested and applied, in Toman, with the
  1-based line number. A message saying "some discount was ignored" would leave the user to find
  which line and by how much using the arithmetic they opened the screen to avoid.
- **`InvoiceEditor` controller**: every intent (`addLine`, `updateLine`, `removeLine`, `moveLine`,
  the invoice-level setters) funnels through one `_update`, so "no path mutates the state without
  recomputing the totals" is a property of one method. It **watches** `appSettingsProvider` rather
  than capturing it, and carries the entries across the rebuild, so changing the VAT rate mid-edit
  updates the preview instead of leaving it describing a rule that no longer applies.
- **A percentage and an amount are alternatives**, enforced in the controller: the engine lets a
  percentage win over an absolute amount (§4 step 2), so a stale percentage would silently override
  the figure the user had just typed.
- **`copyWith` carries explicit `clear` flags** for `taxRateBp`, `discountPercentBp` and `productId`,
  where `null` is a meaningful value. Without them "inherit" would be unreachable once a rate had
  been chosen — D-026's distinction lost at the UI boundary rather than in the engine.
- 55 new tests; **584 pass in total** (was 529). Decisions recorded: **D-046**, **D-047**, and
  **D-048** as a proposal.

**Increment (a2) — completed 2026-08-26 · the project's first schema migration**

The defect measured in (a) is fixed, and D-048 is `ACCEPTED`. A draft carries **no** number;
`issue()` allocates one inside its own transaction. `schemaVersion = 2`.

- **`invoices.number`, `number_year` and `number_sequence` are nullable.** NULLs are distinct in a
  SQLite unique index, which is what lets two numberless drafts coexist; an empty-string sentinel
  would have collided between them. A test asserts both halves — two numberless drafts coexist, and
  a duplicate real number is still refused.
- **`onUpgrade` no longer throws.** It is a ladder (`if (from < 2)`), so a database can arrive from
  any older version, with a fail-loud default for a pair the ladder does not cover. Known issue 1 is
  closed.
- **The migration is a 12-step table rebuild, and its hazard is `ON DELETE CASCADE`.** Step 6 is
  `DROP TABLE invoices`; with foreign keys on, that deletes every `invoice_items` and `payments` row
  in the database. `Migrator.alterTable` guards it by turning foreign keys off *outside* its own
  transaction — which works only because drift invokes `onUpgrade` outside one.
- **Verified to bite.** Wrapping the `alterTable` call in `db.transaction` — which reads as a
  *safety* improvement — leaves `invoice_items` at **zero rows**, because SQLite silently ignores
  `PRAGMA foreign_keys` inside a transaction. The schema-comparison test still passed and so did the
  numbers test; one test of six caught it. The call now carries a comment saying why it must not be
  wrapped.
- **Two migration tests, checking different claims.** `SchemaVerifier` proves the migrated shape
  equals the declared v2 schema (drift's own generated machinery, §6/§14, on an in-memory database).
  A second suite proves the *data* survives, through the **real production path** — a real encrypted
  file opened by `openAppDatabase` with foreign keys on. `SchemaVerifier.testWithDataIntegrity` is
  deliberately **not** used: it documents that it disables foreign keys, which is exactly the
  condition under which the cascade does not reproduce.
- **`integration_test/invoice_number_migration_proof_test.dart`** repeats the data proof on the real
  target, for the reason D-020's proof exists: the native library is what handles
  `PRAGMA foreign_keys`, and a VM test skips the packaging path entirely. **Passes on Windows;
  not yet run on the Redmi.**
- **Run against the real Windows dev database**, not only against fixtures: the file that has been
  accumulating rows since Phase 1 went `user_version 1 -> 2` with 12 customers, 12 invoices, 12
  invoice lines, 4 payments and all 12 numbers intact, foreign keys still on.
- **Numbers already spent are not reclaimed.** A draft migrated from v1 keeps the number v1 gave it;
  `issue` allocates only when the column is null. A test covers that path.
- **Ordering gained a decision the old schema never posed.** `watchList` is now
  `issueDate DESC, numberSequence DESC NULLS FIRST, createdAt DESC, id DESC` — a draft sorts above
  the invoices of its own date, and the last two keys make the order total, because `created_at` is
  milliseconds and two drafts can be written inside one.
- **One Persian string, three call sites.** «بدون شماره», behind `invoiceNumberLabel`, which owns
  the wording *and* the bidi rule: a real number is isolated, the Persian placeholder is not.
- 16 new tests; **600 pass in total** (was 584).

**Security note (increment a2).** No new data class, no new input, no new permission, no new
dependency, no new platform surface. Two things in the threat model move, both about integrity:

- **The first migration of real user data exists**, and it rewrites the invoices table wholesale.
  The failure mode it could have shipped is silent, total loss of every invoice line and payment —
  not a crash, not a visible error, just empty child tables behind intact-looking invoices. That is
  now covered by a test that was verified to fail when the mistake is made, and by a proof that runs
  on the real target.
- **Encryption survives the rebuild**, asserted rather than assumed: the proof re-checks the file
  header after the migration has rewritten the file, because `openAppDatabase`'s startup assertion
  and a full table rebuild had never met before.

**The defect (a2) fixed — recorded as measured**

`create()` allocated an invoice number for a **draft**. Verified against the real database: a draft
took `INV-1405-0001`, was abandoned, and the next draft took `INV-1405-0002`. The number was gone
permanently, because the unique index deliberately covers soft-deleted rows (D-013). A user who
opened a form and changed their mind had silently consumed an invoice number.

Fixed in (a2), and now a regression test: `an abandoned draft does not consume a number`.

**Increment (a3) — completed 2026-08-26 · the cascade defect made structural**

The owner's response to (a2)'s foreign-key finding: a comment and one test out of six are not an
adequate defence for a change that reads as a safety improvement and silently empties every child
table. Full reasoning in **D-049**.

- `assertForeignKeysCanBeDisabled(db)` runs before `alterTable` and aborts the migration if the
  connection cannot really turn foreign keys off. It observes the property rather than guessing at
  the cause: ask for the pragma off, read it back, and see whether SQLite honoured it. Inside a
  transaction it does not, and says nothing — which is the entire bug.
- **Verified to bite.** Wrapping the real migration in `db.transaction` now fails at the guard with
  a message naming the cascade, where it used to pass five of six tests with an emptied
  `invoice_items`.
- The warning now lives **at the call site**, opening `DO NOT WRAP THIS FUNCTION, OR THE CALL BELOW,
  IN A TRANSACTION`, with the consequence stated in rows lost rather than in SQLite mechanics.
- Four new tests, including one that **performs the data loss and measures it**, and one that pins
  the SQLite premise the guard depends on. **604 pass in total** (was 600).
- A `lib/`-scanning guard was considered and rejected as fragile in both directions; the reasoning
  is recorded rather than the rejection alone (D-049).

**Security note (increment a3).** No new data, input, permission, dependency or platform surface.
It is purely an integrity control, and it converts the phase's worst silent failure — total loss of
every invoice line and every payment, behind intact-looking invoices — from a documented hazard into
one the code refuses to perform.

**Increment (b) — completed 2026-08-26 · line item entry**

Three widgets and a limits constant. No screen, no route and no `save`: the lines section is
composed into a form in (d), and persistence belongs to (c). Decisions in **D-050**.

- The product picker returns a `Product` and nothing else, so the D-004 copy happens at exactly one
  site. Picking opens the line sheet pre-filled rather than adding a line outright — a picked
  product still needs a quantity, and the sheet is where the user sees what was copied.
- The per-line tax control is a mode plus a value, keeping `0` and *inherit* distinct from the
  widget down (D-026). Under inherit it displays the rate the **engine** resolved.
- Quantity parses through `tryParseScaledInput(scale: 1000)` — no `double` anywhere — and a fourth
  decimal place is refused with its own message rather than truncated. Percent fields use the same
  parser at `scale: 100`, which is basis points exactly.
- Every figure on a row comes from `CalculatedInvoice`, including the discount **applied** rather
  than the one entered, with D-027's warnings beneath naming both.
- `InvoiceLimits` added to `field_limits.dart`, with a test asserting that every product limit is at
  or below its line counterpart so a copy can never overflow.
- Cards on mobile and tablet, a real table on desktop (§10). 13 new tests; **619 pass** (was 604).
  They caught one real defect — the warnings heading overflowed its row at the phone width.

**Security note (increment b).** New **input** but no new stored data class, permission, dependency
or platform surface — nothing here writes, and the invoice form has no route yet. What changes:

- Free-text fields now accept invoice line titles and units, and they carry the same limits their
  columns do from the first keystroke (`InvoiceLimits`, D-043) rather than failing at the database.
- Every numeric field folds Persian and Arabic-Indic digits through the one normalizer (§9) and
  parses without floating point. The integrity property this phase is about is unchanged: the
  arithmetic path stays narrowed, and the build-failing scan still permits no widget to calculate.

**Increment (c) — completed 2026-08-26 · the invoice-level fields, and the save**

The first write of a whole invoice from the editor. Still no route — (d) assembles the screen.
Decisions and the two gaps in **D-051**.

- **The preview/write pin was extended past the lines**: customer, both dates, the invoice tax rate,
  the entered discount percentage and notes now round-trip alongside every figure. 14 tests, was 8.
- **`save()` writes a draft (no number, D-048); `issue()` allocates one**, each in the repository's
  own transaction. A failure between them leaves a recoverable numberless draft rather than a number
  spent on nothing.
- **Only drafts are editable, proven at the repository.** A test calls it directly — as a deep link
  or a future sync path would — and asserts `updateDraft` and `softDeleteDraft` refuse in every
  non-draft status, each reached by its own route, **and that the refusal left nothing behind**.
  A second test refuses a double-issue, which would spend two numbers on one document.
- **Customer selection reuses `watchSearch`**, the normalization-insensitive path (D-025, D-029),
  asserted by checking the raw term reaches the repository unfolded by the widget.
- **A Jalali date picker, built on `shamsi_date` — no new dependency.** The week starts on Saturday;
  a test pins that day 1 lands under its `Jalali.weekDay` column and not where `DateTime.weekday`
  would put it. Both dates leave as `startOfJalaliDayUtc` instants (D-005), and the due-date picker
  refuses days before the issue date by making them unselectable.
- **A derived due date follows the issue date; a chosen one does not**, told apart by
  `dueDateFollowsIssueDate`.
- 31 new tests; **650 pass** (was 619).

**Security note (increment c).** The first **write** path from the invoice editor, and the first new
input classes since Phase 2. What moves:

- **Invoice notes** are new free text, bounded at the form by `InvoiceLimits.notes` matching the
  column, so an over-long value is refused at the field rather than by drift (D-043).
- **Repository-enforced editability is now tested as a boundary control, not a UI affordance.** That
  is the property that matters if a deep link, a second screen or a future sync path ever reaches
  the repository without passing a greyed-out button.
- **No raw failure reaches the user**: the controller turns a write exception into a null and a
  scrubbed log line through the wrapper (§7), and the screen renders Persian copy.
- No new dependency, permission or platform surface. The date picker was built from a dependency
  already present rather than adding a calendar package.

**Remaining**

- (d) the assembled screen and the `/invoices/new` route.
- **(c2)** the customer snapshot on issue — `schemaVersion = 3`, its own reviewable step (D-051).
- **The payment term is a constant, not a setting** — a `settings` column, deferred with (c2).
- **Nothing from (b) or (c) has been exercised on a device**, because no route reaches it until (d).
  Two numeric-heavy sheets, a calendar grid and two picker sheets. (d) must run on the Redmi.

**Security note (increment a).** No new data is stored, no new input is accepted, and no screen
exists yet — this increment is a value type, a controller and their tests. Three things are worth
recording anyway:

- **The arithmetic path is narrowed rather than widened.** There are now exactly two callers of the
  money engine and a build-failing scan that keeps a third from appearing. Integrity, not
  confidentiality, is the security property this phase is about (as increment (b)'s note said): a
  wrong total is the product-killing defect, and the preview/write agreement test is the control.
- **Nothing here logs.** The state model and the controller make no `AppLog` call at all, which
  matters because an invoice draft holds a customer id and every amount on the document —
  `grandTotal`, `subtotal` and `unitPrice` are all on `logging_path_test.dart`'s banned list.
- **No new permission, platform surface or dependency.** The engine extension is pure integer
  arithmetic with the same overflow guards; `grossTotal` is constructed through `Money`, so it is
  subject to the same `kMaxAmountRial` ceiling as every other amount (D-002).

**Increment (c2) — completed 2026-08-27 · the party snapshot, `schemaVersion = 3`**

D-051 is implemented and **D-052** records what building it settled. Five nullable
`customer_*_snapshot` columns on `invoices` and `payment_term_days` on `settings`, in one migration.

- **The snapshot is taken at `issue()`**, inside the transaction that allocates the number — not at
  draft creation. A draft is not a document and should pick up a correction to the customer's
  details; an issued invoice must not. `create(status: unpaid)` takes one too, being a second route
  to a document.
- **Name, company, کد ملی, کد اقتصادی and address.** The two tax identifiers are the fields with
  legal weight on an Iranian invoice and the ones a correction changes, so a snapshot of the name
  alone would have protected the least consequential field. **The mobile is excluded** — contact
  detail, not document content — and still resolves live.
- **Each snapshot column's length equals its source column**, not merely exceeds it. Narrower would
  make a customer with a long address impossible to issue an invoice to, failing inside `issue()`
  and only for the users whose records are fullest. Asserted in `field_limits_test.dart`.
- **The fallback lives in one place.** `Invoice.party(live)` and `Invoice.partyName(liveName)` are
  the only two sites that write `snapshot ?? live`; `InvoiceDetail.party` and
  `InvoiceListItem.customerName` are getters over them. `InvoiceListItem.customerName` became a
  **getter** and its constructor argument was renamed `liveCustomerName`, so the two construction
  sites cannot apply — or forget — the rule.
- **Existing issued invoices display the live customer, deliberately.** The migration writes nothing
  into the new columns. Backfilling from today's customer rows would look like a snapshot while being
  exactly the live join it replaces, frozen at a moment that corresponds to no document. Pinned by
  two tests, one on the migration and one on the read path. The consequence stated plainly: for those
  invoices the defect D-051 names is still present and cannot be fixed.
- **`assertForeignKeysCanBeDisabled` is not called, and that is a decision.** The guard checks that
  `PRAGMA foreign_keys = OFF` takes effect; a rebuild needs that because it drops the parent table,
  and six `ADD COLUMN`s do not. Calling it anyway would teach the next reader that it is a ritual
  rather than a precondition check. The claim is checked instead: the step is run **inside a
  transaction** with foreign keys on and children present — the exact condition that empties
  `invoice_items` and `payments` under the v1 → v2 rebuild — and the rows are counted afterwards.
- **A real defect found by writing the v1 → v3 test.** `Migrator.alterTable` builds its replacement
  table from the **current** declaration and copies every one of those columns out of the old one —
  so declaring the v3 columns broke the shipped v1 → v2 rebuild with `no such column:
  customer_name_snapshot`, on open, for every user who had not updated since the first release and
  for nobody else. Fixed structurally, not per-column: the rebuild computes its
  `TableMigration.newColumns` by asking the old table what it actually has, so it needs no edit for
  any future column; and the v2 → v3 step adds each column only if absent, because a v1 database
  arrives with them already present.
- **The ladder's shape test now targets `db.schemaVersion`.** The v2 shape stopped being
  independently observable at v3, and pointing the test at the newest version is what makes it the
  test that catches the next column added without the rebuild being told. Ladder steps are also
  bounded above by `to`; no production path changes, since `to` is always `schemaVersion` there.
- **The payment term is a setting.** `kDefaultPaymentTermDays` moves to `data/models/app_settings.dart`
  and names the seed default; the term in force is read from the row. `defaultDueDate` takes it, and a
  **derived** due date now follows a change to the term as well as to the issue date — by (c)'s own
  argument, that a derived date is a statement about the term rather than a commitment to a day. A
  date the user chose is moved by neither. The settings screen shows it, in Persian digits, with «روز».
- **A pre-existing layout defect fixed on the way.** The settings screen had no test until this
  increment; its first one found `_SettingRow` overflowing by **132 logical pixels** at phone width,
  because the backup row renders a *sentence* in the prominent figure style and that group took its
  natural width before the label beside it. Now a `Wrap`, which is identical while both halves fit
  and drops the value onto its own line when they do not. It predates the payment-term row.
- **24 new tests; 676 pass in total** (was 650). Three device proofs re-run on the Redmi Note 8 Pro.
  Decision recorded: **D-052**.

**Security note (increment c2).** New data is stored and the threat model is unchanged, but the
change is not neutral and is worth stating:

- **The `invoices` table now holds third-party personal identifiers** — کد ملی, کد اقتصادی, name and
  address — where before it held only a `customer_id`. They were already in the database, in
  `customers`, under the same encryption at rest on the same connection (D-010, D-020); what changes
  is that they are duplicated onto a second table. No new class of data enters the app.
- **The logging guard was extended to the new accessors and verified to bite.** The scan anchors on
  `.<name>`, so `.nationalId` does not cover `.customerNationalIdSnapshot`. All five snapshot
  accessors and `liveCustomerName` were added to `sensitiveAccessors`; a plausible `AppLog.debug`
  interpolating the snapshot name and national ID was introduced, the scan failed on both by name,
  and it was reverted.
- **No new input is accepted.** Every value written is copied from a `customers` row that already
  passed the form's validation and the column's own limits; the snapshot columns match those limits
  exactly, so nothing can be stored here that could not be stored there.
- **No new dependency, permission or platform surface.** The migration is six `ALTER TABLE ... ADD
  COLUMN`s through drift's typed API; the one interpolated string is a `PRAGMA table_info(...)`,
  which SQLite cannot parameterize, and it takes only compile-time table names from generated code.
- **Backup and export (Phase 6) inherit this.** An exported backup will now carry the identifiers
  twice. That does not change what §8 requires — the export is encrypted with a user-supplied
  password either way — but it is worth knowing when that phase is built.

**Increment (d) — completed 2026-08-27 · the assembled screen, and the route**

**Phase 4 closes here.** `/invoices/new` exists, the invoice list has a create button, and a user can
build an invoice from customers and products, see the totals move, save it as a draft or issue it.

```
lib/features/invoices/presentation/invoice_editor_screen.dart          NEW  the screen
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart NEW  the breakdown
lib/core/router/{app_router,destinations}.dart      + /invoices/new, declared before any :id
lib/features/invoices/presentation/invoices_screen.dart  + the create button, the FAB, the
                                                    empty state's call to action
lib/features/invoices/presentation/widgets/invoice_lines_section.dart
                                                    money columns fixed-width and leading-aligned
```

- **Three layouts, and the desktop one was decided by a measurement** (D-053). A 320-pixel summary
  panel down the side of the desktop form leaves 616 logical pixels for a four-column table with two
  money columns in it, and the amounts overflowed by 58. The width goes to the table; the summary
  splits by purpose — the **breakdown** beside the fields, the **decision** (grand total and both
  actions) pinned. Mobile is one column with a pinned bar; tablet is two panes with the fields on the
  leading side and the lines on the other.
- **Two deviations in (b)'s table, corrected.** Its money columns were `flex` and `alignEnd`, against
  D-037 on both counts. Invisible while that table had a page to itself, which is the general lesson:
  **a widget tested only at its own full width has not been tested at the width it is composed into.**
- **Every figure is the engine's.** The panel is the reconciliation equation rendered — it starts
  from `grossTotal`, not `subtotal` (D-047), so the summary adds up by hand; a subtotal-based one is
  short by exactly the line discounts. The screen calls no arithmetic;
  `single_calculation_path_test.dart` still fails the build if it tries.
- **A designed empty state for the summary**, not a column of zeros. An invoice with no lines has
  totals, all zero, and rendering them would be honest and useless — it reads as a fault. Until there
  is a line the panel says what will appear there.
- **Draft and issue are visibly different actions.** Tonal versus filled, a one-line note under the
  draft saying what it does *not* do, and a confirmation for issue whose Persian copy names both
  irreversible consequences — the number allocated and the end of editability — and restates the
  amount. A test asserts the copy contains both «شماره» and «ویرایش», so it cannot decay into "are
  you sure". Declining writes **nothing**, not even the draft `issue()` would otherwise have saved
  first.
- **Leaving asks, when there is something to lose.** The editor is auto-disposed, so back discards a
  typed invoice. `PopScope` confirms — but only when a customer or a line has been entered, never for
  the dates a fresh form already has. Not in the brief; recorded in D-053 as a judgement call.
- **The blocked reason is stated, not just the disabled button.** «برای ذخیره، مشتری را انتخاب کنید»
  or «…دست‌کم یک سطر اضافه کنید», whichever half is missing.
- **17 new tests; 693 pass in total** (was 676). Decision recorded: **D-053**.

**The device pass — the debt (b) and (c) left, paid**

`integration_test/invoice_form_device_test.dart` drives the whole form through the **real sheets** on
the real phone, and collects every layout overflow raised anywhere in the run rather than letting
Flutter print a red band and carry on. On the **Redmi Note 8 Pro**, 2026-08-27:

```
logical size: 392.7 x 803.6      pixel ratio 2.75      16sp renders at 16.0
customer: picked through the sheet's search, typed «مريم» with the Arabic ي
add-line at: 400 px down        <- the finding below
line: added at quantity ۲٫۵ through the numeric sheet
issue date: picked from the Jalali grid
issued: INV-1405-0001      party snapshot written
grand total: 34,375,000 rial    = 31,250,000 + 10%, reconciled by hand
layout errors : 0
```

**One finding, measured rather than felt: the buttons that add a line are 400 logical pixels down.**
The invoice-level fields fill the first viewport of a 393 × 804 phone, so the first thing a user
wants to do on an invoice form — say what is being billed — is below the fold. Not a defect and not
changed unilaterally: the field order (customer, then dates, then lines) is the order the document
reads in. Recorded for the owner's judgement.

**What this pass cannot do**, and why the manual one still stands: synthetic taps never miss, never
hesitate, and never try the thing nobody designed for. It proves the flow works and the layout holds
at real metrics in Vazirmatn; it does not prove the form is pleasant to use with a thumb.

**Security note (increment d).** No new data is stored and no new input is accepted — every field on
this screen was built and reviewed in (b) and (c), and every write goes through `InvoiceEditor`, whose
paths were reviewed in (c). What is new:

- **A route.** `/invoices/new` takes no parameters, so there is no input from the URL to validate, and
  it is declared before any future `/invoices/:id` so a typed URL cannot resolve to the wrong screen.
- **Nothing on this screen logs.** The screen makes no `AppLog` call at all; the one failure path
  returns null from the controller, which logs through the wrapper without the amount or the party.
  `logging_path_test.dart` covers the new file like every other.
- **A repository exception still never reaches the user** (§7): a failed write becomes «ذخیره فاکتور
  ممکن نشد…» and the screen stays put, with the invoice still in the form to retry from.
- **No new dependency, permission or platform surface.**

---

## Phase 5 — Invoice Management and Payments

**Status:** `IN_PROGRESS` — the split is agreed and the first boundary is delivered.

| # | Increment | Status |
|---|---|---|
| — | (d)'s two carry-overs: The project spec amended, the phone fold (D-054) | `COMPLETED` 2026-08-27 |
| a | **The D-047 ruling** (D-055): store the gross, and two per-line figures | `COMPLETED` 2026-08-27 — decision only, awaiting review |
| a2 | **`schemaVersion = 4`** — the three columns and their backfill (D-055, D-056) | `COMPLETED` 2026-08-27 |
| b | `/invoices/:id`, the detail screen; rows become tappable | `NOT_STARTED` |
| c | Payments: record and delete, both recomputing derived status in the same transaction (§6) | `NOT_STARTED` |
| d | Cancellation, and the Persian copy that says what it does and does not do | `NOT_STARTED` |
| e | List filters over status, customer and Jalali period, at the query level; paging `watchForCustomer` | `NOT_STARTED` |
| f | The device pass, and the phase close | `NOT_STARTED` |

(a2) is a migration and therefore its own reviewable step, on (a2)-of-Phase-4's and (c2)'s precedent.
It comes before the detail screen because the detail screen is the first consumer of what it stores.

**Goal.** Invoice list with filters, detail view, status lifecycle, cancellation, and payment
recording with derived `partiallyPaid` / `paid` status recomputed on every payment write.

**Partly delivered already, and not to be rebuilt.** The invoice **list** landed in Phase 1 (f2) —
both layouts, query-level paging, status badges and the derived `overdue`. The whole write side
landed in (d): `issue`, `cancel`, `softDeleteDraft`, `PaymentRepository.record` and the derived-status
recomputation inside the payment's own transaction all exist and are tested. What remains here is the
**detail screen** at `/invoices/:id` (registered with the screen, per D-021 — the list's rows are
deliberately non-tappable until it exists, asserted by a test), the **filters** over status, customer
and date range, and the **UI** for recording a payment and for cancelling an invoice.

**Increment — (d)'s carry-overs, completed 2026-08-27**

- **The project spec amended.** The desktop requirement read "a sticky invoice summary panel", and a
  panel down the side does not fit beside the invoice table at any window size (D-053). It now states
  the **constraint** — the figure being agreed to must not scroll away — and records the measurement
  that beat the layout, plus the composition rule (d) surfaced: *a widget tested only at its own full
  width has not been tested at the width it is composed into.*
- **The invoice-level fields fold on a phone, and start folded** (D-054), at the owner's ruling. The
  field order is unchanged. The heading states the customer folded or not, because it is the one field
  a save cannot do without. **Measured on the Redmi rather than decided in the abstract:** folded, the
  add-line buttons sit at 586 px with the pinned bar starting at 670 — on the first screen with 59 px
  to spare; unfolded they are 400 px of scrolling away. The wider tiers do not fold.
- 3 new tests; **696 pass** (was 693). Decision recorded: **D-054**.

**Increment (a) — the D-047 ruling, completed 2026-08-27 · decision only, no code**

**D-055: store the gross, and two per-line figures with it** — `invoices.gross_total_rial`,
`invoice_items.line_gross_rial` and `invoice_items.allocated_invoice_discount_rial`.

- **Decided with both consumers in view**, as the owner directed. An Iranian invoice line prints
  مبلغ کل and مبلغ پس از تخفیف; the schema stores neither the line's gross nor its share of the
  invoice discount, and `line_net_rial` is net *after* a deduction the header prints again. A document
  laid out from what is stored today reconciles nowhere.
- **Recomputation was rejected on three grounds**: it re-runs §4 step 1 outside the engine where
  D-046's scan cannot see it; step 1 carries a rounding rule, so a recomputed gross is today's rule
  applied to yesterday's document; and §12 requires the renderer to be handed a view model it does not
  have to compute.
- **These columns are backfilled, unlike D-052's snapshot**, and the difference is recorded because
  the two look alike: a party snapshot would be fabricated history, while these are arithmetic over
  columns the row already carries under a rounding rule that has not changed. Where a row cannot be
  reconciled to the Rial the migration leaves them **null** rather than writing a figure that does not
  add up — `NOT NULL DEFAULT 0` is refused, because zero is a number a document would print.
- It is `schemaVersion = 4` and lands as **(a2)**, its own reviewable step.

**Increment (a2) — `schemaVersion = 4`, completed 2026-08-27**

The project's **third migration**, and the first that backfills. Three nullable columns —
`invoices.gross_total_rial`, `invoice_items.line_gross_rial`,
`invoice_items.allocated_invoice_discount_rial` — three `ADD COLUMN`s guarded by
`_addColumnIfAbsent`, a backfill, and a `foreign_key_check`.

- **The backfill runs the money engine rather than re-deriving anything** (D-056). It rebuilds an
  `InvoiceInput` from the row's own stored columns, calls `calculateInvoice`, and **writes nothing
  unless the output reproduces every figure already on the row** — each line's discount, net, tax and
  total, and the invoice's subtotal, total discount, total tax and grand total less its stored
  rounding adjustment. It is the third sanctioned caller in `single_calculation_path_test.dart`,
  listed with its reason rather than exempted. Open-coding §4 step 1 and the largest-remainder
  allocation in the data layer was the alternative, and it is the second implementation D-046 exists
  to prevent.
- **Which converts D-055's weakest assumption into a per-invoice check.** D-055 argues the backfill is
  honest because the rounding rule has not changed since v1; the migration verifies that on every row
  instead of relying on it. Where anything disagrees, the invoice keeps its nulls.
- **Refusal is per invoice, never per line**, and it does not disturb the invoices beside it. An
  invoice with no lines gets a real **zero** — the one place "nothing" and "unknown" have to be told
  apart, which is what the nullable column is for.
- **The v1 → v4 asymmetry is observed, not assumed.** The v1 rebuild recreates `invoices` from
  today's declaration, so a database that has never been updated arrives at the v4 step with
  `gross_total_rial` already present and both `invoice_items` columns absent, while a v3 database has
  none of the three. `migrateV1ToV2` was made public (on `migrateV2ToV3`'s precedent) so the test can
  run the ladder one step at a time and read `PRAGMA table_info` between them.
- **`assertForeignKeysCanBeDisabled` is deliberately not called** (D-052's reasoning): `ADD COLUMN`
  drops nothing and neither does an `UPDATE`. The step is instead run inside a transaction with
  children present and the rows counted, which is the equivalent check for a step of this shape.
- **The read path says «ثبت‌نشده»**, never a blank cell and never a zero, with a sentence beneath the
  panel explaining that the payable amount is unaffected. `InvoiceSummaryFigures` carries the absence
  in the type and is what the detail screen (b) and the Phase 7 renderer will both be handed;
  `InvoiceTotalsSummary` now takes it, so the form and the detail screen render one panel.
- **Device proof, both ladders**: `integration_test/invoice_figures_migration_proof_test.dart`
  passes on **Windows and on the Redmi** (2026-08-27), backfilling one invoice and refusing another
  on each.
- **41 new tests; 726 pass** (was 696), across
  `invoice_figures_migration_test.dart` (11), `invoice_figures_backfill_test.dart` (12),
  `invoice_summary_figures_test.dart` (7) and extensions to
  `invoice_preview_matches_write_test.dart`. Decisions recorded: **D-056**; D-054 gained the owner's
  ruling that the lines empty state keeps its 250 px.

**Known issue found and not fixed here.** The desktop summary panel's grand total
(`AmountSize.large` at `AppLayout.detailPanelWidth` = 320) **overflows at any amount from
1,000,000 تومان upward** — 30 px at 1,000,000 and 58 px at 10,000,000, measured in a widget test.
Every realistic Iranian invoice is above that threshold. The dense variant used by the phone bar does
not overflow at any magnitude, which is why (d)'s Redmi pass reported no layout errors: it only
exercised the phone tier. It belongs to **(b)**, which builds the desktop detail screen and is where
this panel next renders a stored invoice. Measured with test-font metrics rather than Vazirmatn, so
the exact threshold is indicative; that it is magnitude-dependent and desktop-only is not.

**Security note (increment a2).** No new data class and no new input. Three integer-Rial columns join
five that already exist, on rows that already hold the same kind of figure. The backfill reads and
writes only within the user's own encrypted database and **logs nothing** — its counts are returned as
`InvoiceFiguresBackfillReport` rather than printed, because §7 forbids logging monetary amounts and a
migration is exactly where a helpful debug line would be added. No new permission or platform surface;
the threat model is unchanged.

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

**Entry gate — take the size and startup baseline BEFORE adding the PDF dependency.**

The PDF library is the heaviest thing this application will ever add. Measured only afterwards, the
figures are unattributable: whatever the binary weighs and however long it takes to start, there is
no way to say how much of it is the renderer and how much is everything else that accumulated since
Phase 1. The baseline is worth almost nothing to take and cannot be recovered later.

Take it on the commit **immediately before** the `pubspec.yaml` entry, record the commit hash, and
re-take it on the commit immediately after the renderer works. Both sets go in `DECISIONS.md` as part
of the dependency justification §2 already requires.

What to measure — release builds only; a debug build's size and startup time mean nothing:

| Measurement | How |
|---|---|
| Android APK, arm64 | `flutter build apk --release --split-per-abi`, record the byte size of the `arm64-v8a` APK |
| Windows bundle | `flutter build windows --release`, record the total byte size of the Release directory |
| Android cold start | `adb shell am start -W -n <package>/.MainActivity`, record `TotalTime` over five cold starts, taken after `adb shell am force-stop` each time |

Deferred, deliberately: taking it **now**. The application is close to empty, so today's numbers
would describe a shell rather than a product, and a baseline nobody trusts is worse than none — it
invites attributing later growth to whatever happened to be measured. This gate is the right place
for it (owner, 2026-08-24).


**Security note.** Generated PDFs contain full customer and financial data and are written to
user-accessible storage. Temporary files must be cleaned up, and any share/print intent on Android is
a new outbound data surface.

---

## Phase 8 — Dashboard and Reports

**Status:** `NOT_STARTED`

**Goal.** Real aggregates over Jalali periods, computed in SQL rather than Dart loops.

**Partly delivered already.** The **dashboard** landed in Phase 1 (f2): four live SQL aggregates over
Jalali month boundaries, composed into one `DashboardSummary`, plus a recent-invoices list. This
phase is now about **گزارش‌ها** — the reports destination — rather than the dashboard, and the two
things it must add that the dashboard deliberately does not have are **period selection** (the
dashboard covers the current Jalali month only) and **per-entity breakdowns**: sales by customer, and
**sales by product**, which is where the product-usage question moved when Phase 3 was re-scoped
(D-042). Registering `/products/:id` belongs here too, if that breakdown wants a per-product page.

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
