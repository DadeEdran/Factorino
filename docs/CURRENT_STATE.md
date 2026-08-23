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
| c | Jalali date layer and digit normalization + tests | `COMPLETED` — **accepted** (`b70c1fc`) |
| d | Repositories and domain models | `COMPLETED` — **awaiting review** |
| e | Theme, localization, routing, responsive shell | `NOT_STARTED` |
| f | The four screens, on real data | `NOT_STARTED` |

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (360/360, was 279)
Android build:              PASS   flutter build apk --debug
Windows build (plugins):    PASS   (not re-run this session; no native change)
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
Startup path - Windows:     PASS   six tables created through the keyed connection
Startup path - Android:     PASS   same, at /data/user/0/io.github.erysaw.factorino/files
```

## What was completed this session

### D-030 — the national-ID UI constraint, on the owner's instruction

No existing `DECISIONS.md` entry covered the national ID, so this was recorded as a **new entry**
rather than an amendment to an existing one. It states the finding (the official checksum maps
remainders 1 and 10 to the same check digit, so `0079542311` and `0079542131` both validate) and
then the constraint it implies, in a form the screens can be checked against:

> The Persian copy says the **format** is valid. It must never say, imply, or be translated as
> *confirmed*, *correct*, *verified*, or *identity established*.

With an acceptable/not-acceptable table of Persian strings, so a reviewer can check compliance by
reading the copy alone. It binds increment (f) and Phase 2, and extends to any future checksum
validator — economic ID, IBAN.

### Increment (d) — the repository layer

**The domain boundary is a directory split, not a convention** (D-031). `data/models/` and the
interfaces in `data/repositories/` import drift **nowhere**; implementations live one directory down
in `data/repositories/drift/`. A signature cannot name a type its library has no access to, so an
interface *cannot* return a row class. `domain_boundary_test.dart` fails the build if an import
appears, and checks every interface has a `drift_*.dart` beside it.

Three supporting changes: row classes are named `*Row` via `@DataClassName` (drift otherwise names
the row for `Customers` **`Customer`**, colliding with the domain model); the four enums moved to
`data/models/` so the dependency runs schema → domain; and the soft-delete guard was extended to
`selectOnly`, with `selectOnlyAlive` added beside `selectAlive`. **The schema dump is byte-identical
and no migration is required** — the rename is Dart-level only.

**`CustomerRepository` first, and the guard is no longer vacuous.** `search_name` is written through
`searchKey` on create *and* on update. The update path is the one that gets missed, and its failure
is the quiet kind: the row is still found, by the name the user no longer typed, and the list looks
populated rather than broken. Tested directly — rename a customer, assert the old name stops
matching.

**Invoice numbering is allocated inside the write transaction** (D-013), against the **Jalali** year
of the issue date. Two invoices ten days apart in Gregorian March get `INV-1404-0001` and
`INV-1405-0001`. Ten concurrent creates produce ten distinct numbers with no gaps — and that test
was verified to have teeth: moving the allocation outside the transaction makes it fail with
`UNIQUE constraint failed: invoices.number`. A spent number is never reissued, including after a
soft delete and after cancellation.

**Payment writes recompute and persist the derived status in the same transaction** (§6), in both
directions: recording moves the status forward, removing a payment moves it back. `draft` and
`cancelled` are never derived, and both refuse payments. A refused payment leaves nothing behind.

**Totals come from the money engine, never the caller.** The draft carries only what the user chose;
every derived figure is computed in the repository and stored as a snapshot (D-004), so a stored
total cannot disagree with its lines — asserted on the *persisted* values, not just the computed
ones. Engine warnings (D-027) are returned from the write path too, so a clamped discount reaches
the UI even when it was not previewed.

**Riverpod is wired** (D-032, implementing D-007). `appDatabaseProvider` is synchronous and throws
by default; `main()` opens the database and overrides it. Opening is a fail-loud must-succeed step
(D-020), so an async provider would wrap every dependent value in an `AsyncValue` for something that
is never legitimately absent — and would render a partial UI while a failed open resolved. The
override is the test seam.

**D-015 was re-verified, not assumed.** Adding Riverpod re-resolved 121 packages; drift 2.34.3,
drift_dev 2.34.5, sqlite3 3.5.2 and analyzer 13.3.0 are **unchanged**. The modern native stack held
because `riverpod_lint`/`custom_lint` are still deliberately absent.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change must add a migration step **and** a migration test (§6, §14). Note the `@DataClassName` rename in (d) did **not** change the schema — `drift_schema_v1.json` is byte-identical. |
| 2 | The database opens on the main isolate | Phase 13 moves it to `createInBackground`. Until then the `setup` closure must stay isolate-sendable — `ARCHITECTURE.md` §B.5. |
| 3 | The national-ID checksum cannot catch every transposition | Official algorithm, not a defect. **The UI must never call a passing value verified** — D-030 states the constraint and the acceptable Persian copy. |
| 4 | `watchDetail` re-reads on any invoice-table change | Correct but not minimal: it rebuilds the aggregate rather than diffing. Fine at Phase 1 volumes; revisit in Phase 13 if a detail screen shows lag. |
| 5 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand, then `flutter test -d <device>` works. Developer options → Install via USB. |
| 6 | `pub.dev` 403; `dl.google.com` blocked | Mirrors (D-014). Run `sh tools/sanitize_lockfile` after **every** resolve — and note `dart run build_runner` triggers a resolve too, so it re-contaminates the lockfile. 121 URLs now. |
| 7 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 8 | Release builds signed with debug keys | Phase 15. |
| 9 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12 must supply a separate Web path. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`.** Reversing them is silent (D-020).
- **Never assert encryption with `PRAGMA cipher_version` or `PRAGMA cipher`** — both are false
  witnesses. Assert on the file header.
- **Four rules are enforced by tests that scan `lib/`.** If one fails, route through the helper —
  never weaken the test:
  1. open a database only through `openEncryptedDatabase` (D-020);
  2. read rows only through `selectAlive` / `selectOnlyAlive` / `countAlive` (D-003) —
     `// soft-delete-exempt: <reason>` is the escape hatch;
  3. normalize text only through `core/formatting/` (D-029) — `// normalizer-exempt: <reason>`;
  4. no drift import in `data/models/` or in the interfaces in `data/repositories/` (D-031) — put
     the implementation in `data/repositories/drift/` instead.
- **`searchKey` writes and reads the same column.** Both repositories that own a `search_name` call
  it on create *and* update. Any new searchable table must do the same.
- **Nothing in `core/money/`, `core/date/` or `core/formatting/` may import Flutter.** A Persian
  digit `TextInputFormatter` is a legitimate future need in `core/formatting/` and *does* require
  Flutter; it belongs in a separate file the pure ones do not import.
- **Riverpod 3 wraps a provider's error in `ProviderException`** — a test asserting on the inner
  type will not match. Assert on the message.
- **`sh tools/sanitize_lockfile` after every `flutter pub get` *and* after `build_runner`.**
- **Run `dart run build_runner build` after touching any table or any `@riverpod`**, and commit the
  regenerated `.g.dart`.
- Mirror configuration is **user-global only** and must never enter the repository.

## Recently changed files (increment d)

```
pubspec.yaml / pubspec.lock                    + flutter_riverpod 3.4.2, riverpod_annotation 4.0.6,
                                                 riverpod_generator 4.0.8 (D-032)
lib/data/models/*.dart                         NEW  13 files: entities, drafts, enums, InvoiceNumber
lib/data/repositories/*.dart                   NEW  5 drift-free interfaces (D-031)
lib/data/repositories/drift/*.dart             NEW  5 implementations + mappers.dart
lib/data/providers.dart (+ .g.dart)            NEW  composition root (D-032)
lib/data/database/tables/*.dart                @DataClassName('*Row'); enums moved out
lib/data/database/app_database.(dart|g.dart)   imports follow the moved enums; regenerated
lib/data/database/soft_delete.dart             + selectOnlyAlive
lib/core/formatting/persian_text.dart          + searchKeyOf, kSearchFieldSeparator
lib/main.dart                                  ProviderScope + appDatabaseProvider override
test/data/repositories/*.dart                  NEW  harness + 4 suites + the boundary guard
test/data/providers_test.dart                  NEW  the override seam
test/data/database/soft_delete_usage_test.dart guard extended to selectOnly
docs/*                                         D-030, D-031, D-032; ROADMAP; ARCHITECTURE §A/B.3/B.4
```

## Last completed action

Recorded **D-030** on the owner's instruction — the national-ID checksum limitation and, more
importantly, the UI copy constraint it implies, with the acceptable and unacceptable Persian
phrasings written out so it survives into the screens rather than living in a test comment. No
existing entry covered the national ID, so this is a new one.

Delivered Phase 1 increment (d): domain models and five repositories behind a boundary that is
structural rather than conventional; `CustomerRepository` first, making the `search_name` guard fire
on real code; invoice numbering allocated inside the transaction against the Jalali year, with the
concurrency test proven to have teeth; payment writes recomputing the derived status in the same
transaction, both directions; and the Riverpod composition root, whose one-line override swaps the
whole data layer. 81 new tests, 360 passing, analyzer clean, Android builds.

## Next action

**Await the owner's review of increment (d).** Then begin increment **(e): theme, localization,
routing, and the responsive shell** — the first increment with any user-facing surface.

Specifically, (e) is: design tokens and `ThemeData` (light and dark) in `core/theme/`; the
localization layer in `core/localization/` with ARB files, RTL, and Vazirmatn wired as the font
family; `go_router` in `core/router/`; and the adaptive shell in `core/responsive/`. `main.dart`
stops rendering an empty `Scaffold` and starts rendering the shell.

Constraints carried into (e) from earlier increments and decisions:

- **Navigation is داشبورد · فاکتورها · مشتریان · محصولات و خدمات · تنظیمات.** گزارش‌ها is omitted
  entirely — not disabled, not a placeholder, and **its route is not registered either** (D-021).
- **No hardcoded colors, sizes, radii or spacing inside widgets** (§10). Tokens only.
- **Zero English user-facing text, and no Persian literal inside a widget** (§1). Every string goes
  through the localization layer from the first screen.
- Vazirmatn 400/500/700 is committed in `assets/fonts/` with `OFL.txt` but is **not yet declared in
  `pubspec.yaml`** (D-022) — declaring it is part of (e).
- The prominent financial numeral style is a required part of the type scale (§10), and amounts
  always carry a unit label, never a bare number (§9).
- Persian digits are rendered by `toPersianDigits` in `core/formatting/`, never by a font variant
  (D-022).

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); never assert encryption with
  `PRAGMA cipher_version` or `PRAGMA cipher` — assert on the file header.
- **The four `lib/`-scanning guards** listed under *Important context* are the project's memory of
  four silent failure modes. Route through the helper; never weaken the test.
- **`sh tools/sanitize_lockfile` after every resolve**, including the one `build_runner` triggers.
  The pre-commit hook is the backstop and it does fire.
- **`dart run build_runner build` after touching any table or `@riverpod` provider**, and commit the
  regenerated `.g.dart` — generated files are committed deliberately (`ARCHITECTURE.md` §A).
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
