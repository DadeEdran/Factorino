# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-23**

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `IN_PROGRESS`**

Phase 1 is being delivered in six reviewable increments at the owner's instruction, each reported
and **stopped for review** rather than landing as one pile:

| # | Increment | Status |
|---|---|---|
| a | Drift schema, migration setup, soft-delete helper | `COMPLETED` — **accepted** (`5522caf`) |
| b | `core/money/` engine + unit tests (§4) | `COMPLETED` — **accepted** (`aa0be65`) |
| c | Jalali date layer and digit normalization + tests | `NOT_STARTED` — **blocked**, see below |
| d | Repositories and domain models | `NOT_STARTED` |
| e | Theme, localization, routing, responsive shell | `NOT_STARTED` |
| f | The four screens, on real data | `NOT_STARTED` |

(a) and (b) precede all UI work: everything else reads from the schema and the money engine. Both
are reviewed, accepted and committed; the working tree is clean.

> ### ⛔ Do not start increment (c) yet
>
> The owner ended the last session with **review notes for (c) still pending**. They are to be
> delivered before work on (c) begins, and they may change its scope or approach.
>
> **If you are a fresh session:** do not open `core/date/` or `core/formatting/`. Ask the owner for
> the pending (c) notes, or wait for them. The scope sketched under *Next action* below is this
> project's own reading of §9 and D-006 — it is **not** the owner's instruction and must not be
> treated as approved. Everything else in this file is settled and needs no re-explanation.

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (139/139)
Android build (plugins):    PASS   debug APK carries lib/arm64-v8a/libsqlite3mc.so (1.9 MB)
Windows build (plugins):    PASS
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
Startup path - Windows:     PASS   six tables created through the keyed connection
Startup path - Android:     PASS   same, at /data/user/0/io.github.erysaw.factorino/files
```

## Increment (b) — the money engine

`core/money/`, pure Dart, four files, 70 tests. §4 implemented step for step.

**The invariant is enforced twice.** `calculateInvoice` computes the grand total by summing the
lines *and* as `subtotal − invoiceDiscount + totalTax`, and throws `InvoiceReconciliationError` if
they disagree — a runtime check, not only a test, because the alternative to crashing on an
inconsistent invoice is persisting one. The tests assert the same invariant across a deterministic
sweep of 450 input combinations.

**Largest-remainder allocation is what makes it hold.** 100 Rial across three equal lines is 33.33
each; three naive roundings give 99 and one Rial of the user's discount vanishes. Ties break toward
the earlier line, so two devices produce identical allocations for the same invoice — a
requirement, not a nicety, once sync exists.

**The ceiling rejects rather than truncates, identically on every platform.** Products are checked
against 2^53, not the 64-bit range, so the Dart VM and the Web refuse the same inputs. D-002's Web
caveat is that a value past 2^53 silently loses low digits; a calculation that succeeds on Android
and quietly drops digits on the Web is worse than one that fails on both.

**Two deliberate asymmetries, both documented in the code:**

- A **line** discount larger than its line clamps the line's net at zero but is still *reported* at
  the entered amount, because §4 step 9 defines `totalDiscount` as the sum of what was entered.
  Implemented literally — see Known issues #3.
- An **invoice** discount larger than the subtotal **is** clamped, because unlike the line figure it
  is part of the invariant; leaving it unclamped would produce a negative grand total.

**Guard test:** `no_flutter_imports_test.dart` enforces §3 transitively through project-relative
imports, so importing a helper that itself imports Flutter cannot slip past it.

**D-026 recorded:** a tax rate of `0` is a real rate, never "absent". Treating zero as unset would
apply the default VAT rate to a line the user marked exempt — a wrong total on a tax document that
looks correct to everyone except the tax authority.

**D-024 reversed by the owner:** `package:uuid` replaces the hand-rolled generator. The four
property tests were kept and pointed at the wrapper; all passed unchanged, which is the point of
keeping them across a dependency swap.

## What was completed earlier this session

**Phase 0 (earlier):** the D-020 encryption proof on both platforms, the corrected pragma ordering,
the three named sqlite3mc traps, and the encryption slice as production code. See `DECISIONS.md`
D-020 and D-023.

**Phase 1 increment (a) — the schema.**

Six tables, each mixing in `SyncColumns`, so the six D-011 columns (`id` UUID v4, `created_at`,
`updated_at`, `deleted_at`, `sync_status`, `last_synced_at`) **cannot be omitted by construction**
rather than by convention. `schema_shape_test.dart` verifies it per table, so the seventh table gets
the same treatment automatically.

| Guarantee | How it is held |
|---|---|
| Every table has the sync columns, keyed on a text UUID | `SyncColumns` mixin + `schema_shape_test.dart` |
| `deleted_at IS NULL` on every read | `selectAlive` / `countAlive`, with `soft_delete_usage_test.dart` failing the build on an unexplained raw `select(` in `lib/` |
| Invoice items and payments never outlive their invoice | `ON DELETE CASCADE`, tested |
| A customer with invoices cannot be hard-deleted | SQLite `NO ACTION` — the delete throws, tested |
| An issued invoice number is never reused | unique index that **covers soft-deleted rows**, tested |
| Money never becomes floating point | integer columns, checked by `_rial` / `_bp` / `_milli` suffix across the whole schema |
| Foreign keys are actually on | `beforeOpen` reads the pragma back and throws if it is not `1` |
| Configuration is never missing | settings row seeded in `onCreate`, kept single by `CHECK (singleton = 1)` |

**Startup is wired** (`main.dart` → `openAppDatabase`): key from the OS keystore → keyed open →
first statement, which runs the migration → **`assertDatabaseFileIsEncrypted`**. The assertion must
come last: before the first write the file may not exist, and "no file" must never read as
"encrypted". `main.dart` renders an empty `Scaffold` — a temporary English placeholder would violate
§1 on its way to being deleted, and Persian strings belong to increment (e).

**Verified on the real targets, not only in unit tests.** `integration_test/startup_test.dart`
creates the six tables through the keyed connection and reopens with the keystore key, on the Redmi
and on Windows both.

**Decisions recorded:** D-024 (UUID generated in-repo, no `package:uuid`), D-025 (denormalized
`search_name` for Persian-insensitive search), plus an implementation note on D-013 (numbering
stored as `number_year` + `number_sequence`, not parsed back out of the formatted string).

**Notable:** the encrypted `sqlite3mc` library loads under `flutter test` on the Dart VM, so schema
and repository tests run against a **real encrypted database file**, not an in-memory stand-in.
Referential integrity, cascades and CHECK constraints are properties of the real file.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change must add a migration step **and** a migration test (§6, §14). A build is already installed on the device, so its database needs migrating rather than reinstalling. |
| 2 | The database opens on the main isolate | Phase 13 moves it to `createInBackground`. Until then the `setup` closure must stay isolate-sendable — recorded in `ARCHITECTURE.md` §B.5. |
| 3 | §4 step 9 makes `totalDiscount` the sum of discounts **as entered** | An item discount larger than its line inflates that figure above what was actually given. Implemented literally rather than silently "corrected"; flagged for the owner. The invariant is unaffected — it is built from `subtotal`. |
| 4 | `search_name` is empty | Filled once the normalizer lands in (c) and repositories write it in (d). |
| 5 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand, then `flutter test -d <device>` works. Setting: Developer options → Install via USB. |
| 6 | `pub.dev` 403; `dl.google.com` blocked | Mirrors (D-014). Run `sh tools/sanitize_lockfile` after **every** resolve — 97 URLs this session. |
| 7 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 8 | Release builds signed with debug keys | Phase 15. |
| 9 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12 must supply a separate Web path. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`.** Reversing them is silent (D-020).
- **Never assert encryption with `PRAGMA cipher_version` or `PRAGMA cipher`** — both are false
  witnesses. Assert on the file header.
- **Do not open a database anywhere but `openEncryptedDatabase`**, and **do not read rows without
  `selectAlive`**. Both are enforced by tests that scan `lib/`; if one fails, route through the
  helper rather than relaxing the test. The soft-delete guard has a deliberate escape hatch:
  `// soft-delete-exempt: <reason>` on or above the line.
- **Nothing in `core/money/` may import Flutter**, directly or through a project-relative import.
- **`sh tools/sanitize_lockfile` after every `flutter pub get`.**
- **Run `dart run build_runner build` after touching any table**, or `app_database.g.dart` goes
  stale. The generated file resolves `uuidV4`, `nowMillis` and the enums through `app_database.dart`'s
  imports, which is why that file imports things it does not appear to use.
- Mirror configuration is **user-global only** and must never enter the repository.

## Recently changed files (increment b)

```
pubspec.yaml / pubspec.lock              + uuid 4.6.0 (D-024 reversal)
lib/core/utils/uuid.dart                 now a wrapper over package:uuid
lib/core/money/money.dart                NEW  Money value type + kMaxAmountRial
lib/core/money/rounding.dart             NEW  half-up + checked multiply
lib/core/money/discount_allocation.dart  NEW  largest-remainder distribution
lib/core/money/invoice_calculator.dart   NEW  §4, step for step
test/core/money/*.dart                   NEW  70 tests incl. the Flutter-import guard
docs/*                                   D-024 reversal, D-026, ROADMAP, ARCHITECTURE §B.6
```

## Recently changed files (increment a)

```
pubspec.yaml / pubspec.lock                       + drift_dev, build_runner (pinned)
lib/core/utils/uuid.dart                          NEW
lib/data/database/tables/*.dart                   NEW  six tables + SyncColumns mixin
lib/data/database/app_database.dart (+ .g.dart)   NEW  schemaVersion 1, migration, seeding
lib/data/database/soft_delete.dart                NEW  the single deleted_at helper
lib/data/database/database_bootstrap.dart         NEW  key -> open -> migrate -> assert
lib/main.dart                                     REWRITTEN  bootstraps; renders nothing yet
drift_schemas/drift_schema_v1.json                NEW  migration-test baseline
test/core/utils/uuid_test.dart                    NEW
test/data/database/schema_shape_test.dart         NEW
test/data/database/app_database_test.dart         NEW
test/data/database/soft_delete_usage_test.dart    NEW
test/data/database/single_open_path_test.dart     matcher fixed (false positive on @DriftDatabase)
test/widget_test.dart                             REMOVED  tested the deleted counter template
integration_test/startup_test.dart                NEW
docs/*                                            D-013 note, D-024, D-025; ROADMAP; ARCHITECTURE
```

## Last completed action

**Increments (a) and (b) were both reviewed by the owner and accepted.** Nothing from them is
outstanding: no rework was requested, no follow-up was deferred, and every item raised in review was
either resolved in the increment or recorded as a decision. The one owner override — D-024, from a
hand-rolled UUID generator to `package:uuid` — was carried out and is committed.

Delivered Phase 1 increment (b): the `core/money/` engine with 70 tests, the reconciliation
invariant enforced at runtime as well as tested, the `kMaxAmountRial` ceiling proven to reject
rather than truncate, and the zero-Flutter rule enforced transitively by a guard test. Also carried
out the owner's D-024 reversal to `package:uuid`. 139/139 tests pass, analyzer clean, Android
builds.

Before that, increment (a): the six-table schema behind the proven encrypted opener, migration
setup with the v1 schema dump, the soft-delete helper with build-failing enforcement, startup wired
through `assertDatabaseFileIsEncrypted`, and the startup path verified on Android and Windows.
69/69 tests pass, analyzer clean.

## Next action

**Wait for the owner's pending review notes on increment (c). Do not begin (c) before they arrive.**

There is no other outstanding work: (a) and (b) are accepted and committed, the tree is clean, and
all verification passes. If the owner asks to proceed and the notes have been given, (c) is the
Jalali date layer and digit normalization.

### Scope prepared for (c) — this project's reading, pending the owner's notes

Both parts are pure Dart in `core/`, so both get the same treatment as the money engine: tested
against fixed, known values rather than against whatever the implementation happens to produce.
`shamsi_date` is already the settled dependency choice but is **not yet in
`pubspec.yaml`** — adding it needs the D-014 workflow (`flutter pub get`, then
`sh tools/sanitize_lockfile`).

1. **Jalali dates** (`core/date/`). Store UTC epoch milliseconds, display Jalali (D-005). The
   load-bearing part is **D-006**: "این ماه" means the current *Jalali* month, so the period helpers
   must compute Jalali month/year boundaries, convert them to UTC instants, and return a range the
   schema can be queried on. Derive `Asia/Tehran` boundaries explicitly — Iran has no DST, but a
   fixed +03:30 offset must not be hardcoded in a way that breaks for a device in another timezone.
2. **Digit and text normalization** (`core/formatting/`). Persian `۰-۹` and Arabic-Indic `٠-٩`
   digits fold to ASCII before parsing; Arabic `ي`/`ك` fold to Persian `ی`/`ک`; ZWNJ is normalized
   for search. This is what fills `search_name` (D-025), so **the same normalizer must be used for
   writing and for querying**, or the index will not match what the user typed.
3. Also in scope, since the schema has the columns and neither has a validator: Iranian mobile
   normalization (`09xxxxxxxxx`, tolerating `+98` / `0098`) and the national-ID checksum.
4. Tests: Jalali↔Gregorian conversions including a leap year, month boundaries across the Nowruz
   year change, digit folding for both digit sets, ZWNJ handling, and the §9 search case — a
   customer saved as "علي" must be found by typing "علی".

**Guard test to carry forward.** `core/formatting/` will be imported by `core/money/`'s neighbours,
and `no_flutter_imports_test.dart` already follows project-relative imports transitively — so if a
formatting helper imports Flutter and the money engine later reaches for it, the build fails. That
is intended; do not loosen the guard to accommodate it.

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); never assert encryption with
  `PRAGMA cipher_version` or `PRAGMA cipher` — assert on the file header.
- **Open the database only through `openEncryptedDatabase`; read rows only through `selectAlive`.**
  Both are enforced by tests that scan `lib/`. If one fails, route through the helper — never
  weaken the test.
- **`sh tools/sanitize_lockfile` after every `flutter pub get`.** The pre-commit hook is the
  backstop and it does fire.
- **`dart run build_runner build` after touching any table**, and commit the regenerated
  `.g.dart` — generated files are committed deliberately (see `ARCHITECTURE.md` §A).
- **Nothing in `core/money/` may import Flutter**, directly or transitively.
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
