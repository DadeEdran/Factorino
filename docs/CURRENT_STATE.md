# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-24**

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `IN_PROGRESS`** — one increment remains.

| # | Increment | Status |
|---|---|---|
| a | Drift schema, migration setup, soft-delete helper | `COMPLETED` — **accepted** (`5522caf`) |
| b | `core/money/` engine + unit tests (§4) | `COMPLETED` — **accepted** (`aa0be65`) |
| c | Jalali date layer and digit normalization + tests | `COMPLETED` — **accepted** (`b70c1fc`) |
| d | Repositories and domain models | `COMPLETED` — **accepted** (`36493d3`) |
| e | Theme, localization, routing, responsive shell | `COMPLETED` — **accepted** (`ea3b7b0`) |
| f1 | Logging wrapper; Customers and Products on real data | `COMPLETED` — **awaiting review** |
| f2 | Invoices list and Dashboard, on real data | `NOT_STARTED` |

(f) was split in two after the owner pulled the create/edit forms forward into it (D-036).

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (432/432, was 378)
Android build:              PASS   (not re-run this session)
Windows build:              PASS   flutter build windows --debug, RUN and screenshotted
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
```

## What was completed this session — increment (f1)

**The logging wrapper first** (D-035), because it is what makes every screen after it safe. One
sink; **closure messages**, so a release build never even forms the string; **everything stripped in
release** by a compile-time constant, not merely silenced; a shape-based scrubber as a backstop; and
a `lib/`-scanning guard that fails the build on a `print` or on a sensitive field name inside an
`AppLog` call. Verified to bite by introducing both violations, including across a
formatter-wrapped multi-line call.

**The scrubber is honest about its limits.** It catches digit runs of ten or more, hex runs of 32 or
more, and the wrapped key form. It cannot catch a customer name — names have no shape. The static
guard is the control; the scrubber only catches what arrives inside something the guard cannot see
through, such as a database exception's message.

**`platformDispatcher.onError` returns false.** Returning `true` was tried and swallowed a startup
failure: `runApp` was never reached, and because the Windows runner shows its window only after the
first frame, the app ran forever with no window and no message. D-020's fail-loud startup restored.

**Customers and Products, end to end on real data.** Debounced normalization-insensitive search
through the one `searchKey`; **query-level paging** (D-038) where the limit reaches SQL; skeleton
loaders shaped like the rows they replace and honouring reduced motion; two distinct empty states
(no data vs. no match); soft delete behind Persian copy that explains what survives; and create/edit
forms (D-036).

**Three genuinely different layouts held.** Cards on mobile and tablet, a **virtualized** table on
desktop (D-037) — `DataTable` builds every row it is handed, so it is not used, and a test asserts
that a full page of rows does not build a full page of widgets.

**D-030 now has a live call site.** A failing national-ID checksum is called invalid plainly; a
passing one produces **no affirmative message at all**, and the form test asserts the absence of the
"format is valid" string and of any tick or verified icon.

## Three defects found by running the Windows build

None would have been caught by a test, and all three are Persian- or RTL-specific.

1. **The money column was aligned the wrong way in RTL.** `alignEnd` resolves to the *left* edge in
   RTL, and numbers render left-to-right regardless — so figures lined up by their first digit and
   the units digits were ragged, exactly what tabular numerals exist to prevent. Fixed with leading
   alignment in a fixed-width column; the trap is documented on the flag (D-037).
2. **The autofocused field's floating label was clipped.** An outlined field's label floats *outside*
   the field's box; the first field sits flush against the top of a scroll viewport; a viewport clips
   its children. In Persian only the ascenders and the dots vanish, so it reads as a misspelled word
   rather than a layout fault. Two wrong hypotheses (line height, content padding) were tried and
   reverted before the cause was found.
3. **The mobile FAB covered the last row of every list.** Found by a widget test whose tap on the
   load-more control landed on the button instead — the same thing that happens to a user, with no
   warning printed.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change needs a migration step **and** a test (§6, §14). |
| 2 | The database opens on the main isolate | Phase 13. The `setup` closure must stay isolate-sendable — `ARCHITECTURE.md` §B.5. |
| 3 | The national-ID checksum cannot catch every transposition | Official algorithm, not a defect. Enforced by test over the ARB **and** over the form's behaviour. |
| 4 | `watchDetail` re-reads on any invoice-table change | Correct but not minimal. Revisit in Phase 13. |
| 5 | Dashboard and Invoices still show their empty state unconditionally | That is increment (f2). |
| 6 | Settings is read-only, and its last-backup row would render an epoch number | `formatJalaliDateLong` now exists; wire it when settings becomes editable. Currently unreachable — `lastBackupAt` is always null. |
| 7 | No live `count()` on the repositories | (f2)'s dashboard needs one. A `Future` provider would go stale; add `watchCount()` to the repositories rather than working around it. |
| 8 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand. Developer options → Install via USB. |
| 9 | **The pub mirror went unreachable mid-session** | `dart pub get --offline` resolves from the local cache. See `ENVIRONMENT.md` — and sanitize the lockfile **last**, or it forces a network re-resolve. |
| 10 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 11 | Release builds signed with debug keys | Phase 15. |
| 12 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12. |
| 13 | Android manifest hardening not done | Phase 9. |

## Important context for a future session

- **The cipher pragmas come BEFORE `pragma key`** (D-020). Never assert encryption with
  `PRAGMA cipher_version` or `PRAGMA cipher` — assert on the file header.
- **Seven rules are enforced by tests that scan `lib/`.** If one fails, route through the helper —
  never weaken the test. Each has a documented escape-hatch comment requiring a reason:
  1. open a database only through `openEncryptedDatabase` (D-020);
  2. read rows only through `selectAlive` / `selectOnlyAlive` / `countAlive` (D-003) —
     `// soft-delete-exempt:`;
  3. normalize text only through `core/formatting/` (D-029) — `// normalizer-exempt:`;
  4. no drift import in `data/models/` or the interfaces in `data/repositories/` (D-031);
  5. no literal colour or dimension outside `core/theme/` (D-033) — `// tokens-exempt:`;
  6. no Arabic-script character in code outside `core/localization/` (D-034) — `// l10n-exempt:`;
  7. **no output outside `AppLog`, and no sensitive field name inside a log call** (D-035) —
     `// logging-exempt:`.
- **The D-020 scan reads comments too.** It fired on a doc comment in `app_log.dart` that merely
  mentioned the key pragma. The comment was reworded; the guard was not weakened.
- **A widget never calls a repository.** Feature `application/` folders hold an editor controller
  per feature (`CustomerEditor`, `ProductEditor`) that owns the write, the logging and the error
  handling; the screen only decides what the user is told.
- **`Override` is not exported by `flutter_riverpod` in 3.4.2.** It lives in
  `package:flutter_riverpod/misc.dart`. A test that types a list of overrides needs that import, and
  the error — *"The name 'Override' isn't a type"* — does not hint at it.
- **Riverpod 3 wraps a provider's error in `ProviderException`** — assert on the message, not the
  inner type (`ARCHITECTURE.md` §B.3).
- **Nothing in `core/money/`, `core/date/` or `core/formatting/` may import Flutter.**
- **Where the source encoding is not guaranteed, name characters by code point.** Bitten three times
  now: the fold tables, the Windows window title, and the bidi isolate constants.
- **Sanitize the lockfile after anything that resolves — and sanitize it LAST.** Sanitizing before
  `build_runner` makes pub re-resolve against the network, which is what hung this session.
- **Run `dart run build_runner build` after touching a table or an `@riverpod`, and
  `flutter gen-l10n` after touching the ARB**, then commit the regenerated files.

## Recently changed files (increment f1)

```
lib/core/security/app_log.dart          NEW  THE logging wrapper (D-035)
lib/core/errors/failure_message.dart    NEW  exception -> ARB copy, and nothing else
lib/core/utils/list_query.dart          NEW  the paging window (D-038)
lib/core/formatting/jalali_display.dart NEW  Jalali dates, phones, ids, bidi isolation
lib/core/widgets/app_table.dart         NEW  virtualized desktop table (D-037)
lib/core/widgets/{skeleton,search_field,load_more_footer,form_scaffold,async_error_view}.dart NEW
lib/core/widgets/page_body.dart         + floatingAction, for the mobile primary action
lib/core/theme/*                        + fieldLabel style, skeleton/table/FAB-clearance tokens
lib/core/router/*                       + AppRoutes, and the four form routes
lib/features/customers/**               NEW  providers, editor controller, list, form
lib/features/products/**                NEW  providers, editor controller, list, form
lib/main.dart                           framework + platform errors through AppLog; onError false
lib/core/localization/arb/app_fa.arb    +58 strings (120 total), incl. the twelve month names
test/core/security/logging_path_test.dart NEW  the two scans + the scrubber
test/features/**                        NEW  harness + customer list and form tests
docs/*                                  D-035..D-038; ROADMAP; ARCHITECTURE §A; ENVIRONMENT
```

## Last completed action

Delivered Phase 1 increment (f1): the §7 logging wrapper with its build-failing guard, and Customers
and Products working end to end on real data — search, query-level paging, skeletons, empty states,
soft delete with explanatory Persian copy, and create/edit forms.

Verified on the real Windows build, not only in tests: both tiers captured with real rows in the
encrypted database, the customer form captured, and dark mode captured. That is what surfaced the
three defects above, all three fixed.

432/432 tests pass, analyzer clean, Windows builds and runs.

## Next action

**Await the owner's review of increment (f1).** Then begin increment **(f2): the Invoices list and
the Dashboard, on real data** — the last increment of Phase 1.

Specifically, (f2) is:

- **Invoices list.** Cards on mobile, a virtualized table on desktop reusing `AppTableRow`. Columns:
  number, customer, date, status, amount. The status badge already exists; `overdue` is **derived at
  display time** from an unpaid invoice's due date and is never stored (`status_badge.dart`).
- **Dashboard.** Real aggregates over **Jalali** period boundaries (D-006) — use `jalaliMonthOf`,
  never a Gregorian boundary — computed in SQL, never as Dart loops. `totalIssuedRial(InstantRange)`
  already exists and already excludes cancelled invoices.

Constraints carried into (f2):

- **The repositories need a live `watchCount()`** before the dashboard can show a customer or
  product count. `count()` is a `Future` and a provider over it goes stale on the next write; add
  the stream to the repository rather than working around it in the feature layer (known issue 7).
- **Amounts go through `AmountText`**, which carries the unit label and Persian digits.
- **Money is never accent-coloured** (D-033). Prominence comes from the type scale; colour means
  status.
- **A money column in a table is leading-aligned, not `alignEnd`** — see D-037's RTL note.
- **Register `/invoices/:id` only with the screen that opens it** (D-021, one level down).
- Reuse `ListQuery`, `SkeletonList`, `SearchField`, `LoadMoreFooter`, `AsyncErrorView` and
  `AppTable*`; all five were built against two call sites in (f1) and need no new abstractions.

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); assert encryption on the file header.
- **The seven `lib/`-scanning guards** listed above are the project's memory of seven silent failure
  modes. Route through the helper; never weaken the test.
- **Sanitize the lockfile after any command that resolves dependencies, and do it last.** The
  pre-commit hook is the backstop and it does fire.
- **Regenerate and commit** after touching a table, a provider, or the ARB.
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
