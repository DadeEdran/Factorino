# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-24**

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
| c | Jalali date layer and digit normalization + tests | `COMPLETED` — **awaiting review** |
| d | Repositories and domain models | `NOT_STARTED` |
| e | Theme, localization, routing, responsive shell | `NOT_STARTED` |
| f | The four screens, on real data | `NOT_STARTED` |

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (279/279, was 139)
Android build:              PASS   flutter build apk --debug
Windows build (plugins):    PASS   (not re-run this session; no native change)
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
Startup path - Windows:     PASS   six tables created through the keyed connection
Startup path - Android:     PASS   same, at /data/user/0/io.github.erysaw.factorino/files
```

## What was completed this session

### The owner's ruling on known issue #3 — carried out (D-027)

§4 step 9 now reports the **effective** discount, not the amount as entered. The project spec were amended: the contract's wording was wrong, not the implementation of it. A line worth
1,000,000 with 1,500,000 entered against it now reports 1,000,000 — the only figure a customer could
arrive at by reconciling the document by hand.

**Clamped inputs are surfaced rather than absorbed.** `CalculatedInvoice.warnings` carries a typed
`InvoiceWarning` per clamp — kind, line index, requested and applied amounts — so the UI in (f) can
state the difference exactly instead of saying "some discount was ignored". Not an exception: the
totals are correct and the invoice is usable, so the engine reports and the UI asks. The warning
carries **no message**, because user-facing text is Persian and `core/money/` may not reach the
localization layer. Both figures are kept on the line (`discount`, `discountRequested`), so the
document can still show what was typed.

The invoice-level clamp is unchanged in behaviour, as ruled — a negative grand total is never a
valid document — and now gets the same visibility treatment.

### Increment (c) — the normalizer and the Jalali date layer

**One normalizer, and the single path is structural.** `searchKey` in
`core/formatting/persian_text.dart` produces both the stored `search_name` and the term queried
against it. `single_normalizer_path_test.dart` fails the build if anything in `lib/` outside
`core/formatting/` open-codes a character fold, or references `searchName` without calling
`searchKey`. That is the treatment the database opener gets, for the same reason: **the failure is
silent** — two call sites that normalize almost the same way produce no error, no crash, and no log
line, just a customer saved yesterday who cannot be found today. Neither side looks wrong in
isolation, which is why testing them separately would never catch it. The guard is vacuous today, on
purpose: the rule is in place before the first call site in (d).

**Round-tripped through the real encrypted database**, not only unit-tested. The normalizer can be
perfect and search still fail — if one side folds and the other does not, or if SQLite compares the
stored bytes differently from what Dart produced. `search_name_roundtrip_test.dart` writes with
`searchKey` and searches with a parameterized `LIKE`, covering both letter variants, ZWNJ, and all
three digit sets in one string, plus soft-deleted rows and non-matches.

**`searchKey` folds further than §9 enumerates** (D-029): alef maksura, the teh-marbuta and alef
variants, diacritics, tatweel, invisible bidi controls, and **all whitespace**. The whitespace call
is the load-bearing one: Persian compounds are written `علی‌رضا`, `علی رضا` and `علیرضا` by the same
person, and folding ZWNJ alone would still leave the spaced form unmatched. The result is an opaque
**key, never a display string**. `ئ` is deliberately *not* folded — it is a distinct Persian letter,
and merging `رئیس` with `رییس` would make search answer a question it was not asked.

**Jalali periods are computed in Jalali and only then converted** (D-006). Every boundary is tested
against independently established Nowruz dates — 1403 begins 2024-03-20, 1404 begins 2025-03-21,
1405 begins 2026-03-21 — rather than against the implementation's own output. Esfand's length is
never computed anywhere: a month's range ends where the next month's begins, so the 29/30-day leap
question cannot be got wrong. Tested at the first and last instant of a month, across the Farvardin 1
transition, and on a leap year's Esfand 30.

**`InstantRange` is half-open.** An inclusive end would have to be "the last millisecond of the
period", which drops a payment recorded in that millisecond from one period without adding it to the
next. Half-open, adjacent periods tile the timeline exactly.

**Nothing in `core/date/` reads the clock or the device timezone** (D-028). The Iran offset is a
named constant taken as a parameter, so a laptop in Berlin still computes Iranian business
boundaries — using device local time is precisely the bug D-006 names — and every boundary is
testable against fixed values.

**Also landed:** Iranian mobile normalization (`0`, `+98`, `0098` and the bare country code, any
digit set, any separators; a foreign number is rejected rather than reinterpreted), the national-ID
checksum with the field remaining optional, and numeric input parsing that never routes a quantity
through a `double` and rejects more precision than `quantity_milli` can hold rather than truncating
it.

**The (b) transitive Flutter guard was verified to bite, not assumed to.** A `package:flutter`
import was temporarily added to `persian_text.dart` and a relative import from `money.dart` to it;
`no_flutter_imports_test.dart` failed and named the chain
(`lib/core/formatting/persian_text.dart ... reached via lib/core/money/money.dart`). Both edits were
reverted; `money.dart` is byte-identical to its committed version.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change must add a migration step **and** a migration test (§6, §14). A build is already installed on the device, so its database needs migrating rather than reinstalling. |
| 2 | The database opens on the main isolate | Phase 13 moves it to `createInBackground`. Until then the `setup` closure must stay isolate-sendable — recorded in `ARCHITECTURE.md` §B.5. |
| 3 | ~~§4 step 9 reports discounts as entered~~ | **Resolved** by the owner's ruling, D-027. |
| 4 | `search_name` is still empty in the database | The normalizer exists as of (c); the repositories that must call it on every write arrive in (d). The guard test is already in place for them. |
| 5 | The national-ID checksum cannot catch every transposition | The official rule maps remainders 1 and 10 onto the same check digit, so `0079542311` and `0079542131` both validate. That is the algorithm, not a defect here — recorded as a test so nobody invents a stricter rule than the one numbers are issued under. **The UI must not present a passing value as a verified identity.** |
| 6 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand, then `flutter test -d <device>` works. Setting: Developer options → Install via USB. |
| 7 | `pub.dev` 403; `dl.google.com` blocked | Mirrors (D-014). Run `sh tools/sanitize_lockfile` after **every** resolve — 99 URLs this session. |
| 8 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 9 | Release builds signed with debug keys | Phase 15. |
| 10 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12 must supply a separate Web path. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`.** Reversing them is silent (D-020).
- **Never assert encryption with `PRAGMA cipher_version` or `PRAGMA cipher`** — both are false
  witnesses. Assert on the file header.
- **Do not open a database anywhere but `openEncryptedDatabase`**, **do not read rows without
  `selectAlive`**, and **do not normalize text anywhere but `core/formatting/`**. All three are
  enforced by tests that scan `lib/`; if one fails, route through the helper rather than relaxing the
  test. Each has a deliberate escape hatch comment (`// soft-delete-exempt:`,
  `// normalizer-exempt:`) requiring a reason.
- **`searchKey` writes and reads the same column.** Increment (d) must call it on both sides of
  every `search_name` write and query. It is the one function; there is no "close enough" variant.
- **Nothing in `core/money/`, `core/date/` or `core/formatting/` may import Flutter** — `core/money/`
  by rule (§3), the other two because the money engine's guard follows relative imports and would
  fail the moment money reaches for one of them. Note that a Persian digit `TextInputFormatter` is a
  legitimate future need in `core/formatting/` and *does* require Flutter; if that lands, it belongs
  in a separate file that the pure ones do not import.
- **`sh tools/sanitize_lockfile` after every `flutter pub get`.**
- **Run `dart run build_runner build` after touching any table**, or `app_database.g.dart` goes
  stale. The generated file resolves `uuidV4`, `nowMillis` and the enums through `app_database.dart`'s
  imports, which is why that file imports things it does not appear to use.
- Mirror configuration is **user-global only** and must never enter the repository.

## Recently changed files (increment c and the D-027 ruling)

```
The project spec amended; clamp-reporting rule added
pubspec.yaml / pubspec.lock                   + shamsi_date 1.1.1 (D-028); 99 URLs re-sanitized
lib/core/money/invoice_calculator.dart        D-027: effective discount, InvoiceWarning, requested
lib/core/formatting/persian_text.dart         NEW  THE normalizer: searchKey + digit/letter folds
lib/core/formatting/number_input.dart         NEW  exact scaled parsing, never via double
lib/core/formatting/iranian_phone.dart        NEW  09xxxxxxxxx from +98 / 0098 / bare / local
lib/core/formatting/national_id.dart          NEW  checksum; optional field rule in one place
lib/core/date/jalali_instant.dart             NEW  instant <-> Jalali, offset as a parameter
lib/core/date/jalali_period.dart              NEW  InstantRange + day/month/year boundaries
test/core/money/invoice_calculator_test.dart  D-027 cases incl. the exact §4 step 9 example
test/core/formatting/*.dart                   NEW  4 files incl. the single-normalizer guard
test/core/date/jalali_period_test.dart        NEW  boundaries vs known Nowruz dates
test/data/database/search_name_roundtrip_test.dart  NEW  write -> LIKE, real encrypted file
docs/*                                        D-027, D-028, D-029; ROADMAP; ARCHITECTURE §A/§B.6.1
```

## Last completed action

Delivered Phase 1 increment (c), and carried out the owner's ruling on known issue #3 first because
it changes the money engine's public contract and everything downstream reads it.

The ruling: §4 step 9 now reports the effective discount, the project spec was amended, D-027 records the
correction as originating from an ambiguity in the contract, and the exact case from the ruling is a
test. Clamps at both levels are surfaced as typed warnings for the UI in (f).

Increment (c): one normalizer with its single path enforced structurally and round-tripped through
the real encrypted database; Jalali period boundaries tested against independently known Nowruz
dates; Iranian mobile normalization; the national-ID checksum with its honest limitation recorded.
140 new tests, 279 passing in total, analyzer clean, Android builds.

## Next action

**Await the owner's review of increment (c).** Then begin increment **(d): repositories and domain
models** — the layer that turns the schema plus the money engine plus the normalizer into something
the UI can use.

Specifically, (d) is: domain entities in `data/models/` that are **not** Drift row classes,
repository interfaces and implementations in `data/repositories/` that map at the boundary, and
Riverpod providers exposing them. The first repository to write is `CustomerRepository`, because it
is what makes the `search_name` guard non-vacuous: it must call `searchKey` on write **and** on
query, and D-025 says that gets a test rather than a convention.

Two constraints carried into (d) from this increment:

- Repositories are the only writer of `search_name`, and must set it in the same statement as the
  display name so the two cannot diverge.
- Repositories are the boundary that converts `Money` to the schema's plain `int` Rial, in one place
  (`ARCHITECTURE.md` §B.6).

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); never assert encryption with
  `PRAGMA cipher_version` or `PRAGMA cipher` — assert on the file header.
- **Open the database only through `openEncryptedDatabase`; read rows only through `selectAlive`;
  normalize text only through `core/formatting/`.** All three are enforced by tests that scan `lib/`.
  If one fails, route through the helper — never weaken the test.
- **`sh tools/sanitize_lockfile` after every `flutter pub get`.** The pre-commit hook is the
  backstop and it does fire.
- **`dart run build_runner build` after touching any table**, and commit the regenerated
  `.g.dart` — generated files are committed deliberately (see `ARCHITECTURE.md` §A).
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
