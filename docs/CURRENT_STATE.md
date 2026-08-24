# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-24**

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `COMPLETED`** — all seven increments accepted by the owner
(2026-08-24).
**Phase 2 — Customers · `NOT_STARTED`** — re-scoped (D-042); awaiting the owner's go-ahead.

| # | Increment | Status |
|---|---|---|
| a | Drift schema, migration setup, soft-delete helper | `COMPLETED` — **accepted** (`5522caf`) |
| b | `core/money/` engine + unit tests (§4) | `COMPLETED` — **accepted** (`aa0be65`) |
| c | Jalali date layer and digit normalization + tests | `COMPLETED` — **accepted** (`b70c1fc`) |
| d | Repositories and domain models | `COMPLETED` — **accepted** (`36493d3`) |
| e | Theme, localization, routing, responsive shell | `COMPLETED` — **accepted** (`ea3b7b0`) |
| f1 | Logging wrapper; Customers and Products on real data | `COMPLETED` — **accepted** (`30e53a3`) |
| f2 | Invoices list and Dashboard, on real data | `COMPLETED` — **accepted** (`0287dc2`) |

(f) was split in two after the owner pulled the create/edit forms forward into it (D-036).

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (483/483, was 432)
Android build:              PASS   (not re-run this session)
Windows build:              PASS   flutter build windows --debug, RUN and screenshotted
Web build:                  NOT_RETESTED since plugins were added
D-020 proof - Windows:      PASS   5/5
D-020 proof - Android:      PASS   5/5 on a Redmi Note 8 Pro, Android 11 (API 30, arm64)
```

## What was completed this session — increment (f2)

**Five live aggregate reads, all computed in SQL.** `watchCount` on all three repositories,
`watchTotalIssuedRial`, `watchIssuedCountInPeriod`, `watchOutstandingRial` and `watchList`. Streams
rather than futures, because a `Future` behind a provider answers once and is then quietly wrong —
known issue 7 from (f1) is closed. Nothing is summed or counted in Dart.

**The outstanding balance is one statement.** A correlated subquery sums each invoice's payments
*inside* the aggregate. A join to `payments` would multiply each invoice's grand total by its number
of payment rows — invisible until an invoice takes its second instalment, and then overstating the
figure the user trusts most. A repository test records two instalments on one invoice to pin it.

**The Invoices list, on real data.** Cards on mobile and tablet, a virtualized table on desktop
(D-037), query-level paging from the first commit (D-038), a designed empty state with **no** create
action. The customer name is resolved by the same query as the invoice (D-040) through a new
`InvoiceListItem` — never a lookup per row.

**The Dashboard, on real Jalali aggregates.** Four tiles plus the five most recent invoices in the
same row widgets the list uses. Both period tiles carry the Jalali month as a caption, so the user
can see which month the app meant. The figures arrive as **one** `DashboardSummary`, so the page
cannot show a sales total from before a write beside a count from after it.

**`overdue` is derived from one clock reading, compared on whole Jalali days** (D-041). An invoice
due today is not overdue until today is over — comparing instants would put a red badge on a document
nobody is late on, which teaches the user that red means nothing. Red stays reserved for it.

**The UI cannot recompute `paid`/`partiallyPaid`, structurally.** `InvoiceListItem` carries no
payment information, so there is nothing to recompute *from*. The stored answer, written inside the
payment's own transaction, is the only one that reaches a badge.

## Two data-layer defects corrected

1. **`totalIssuedRial` counted drafts as revenue** (D-039). The name said "issued"; the query
   excluded only cancellations. Nothing depended on it until the dashboard existed — at which point
   "فروش این ماه" would have climbed while the user typed an invoice they had not issued, and dropped
   when they cleared it. A test had asserted the old behaviour; it asserts the corrected one now.
2. **An invoice became unopenable when its customer was soft-deleted.** `findDetail` filtered the
   customer read with `selectAlive` and returned `null` — while the delete dialog promises the user,
   in Persian, that invoices already issued to that customer stay untouched. The list would have
   dropped them entirely. Both reads now take the customer row without the alive filter, marked
   `// soft-delete-exempt:` with the reason (D-040).

## Two layout defects found by the new widget tests

1. **The amount column was too narrow for an invoice total.** `tablePriceWidth` was sized in (f1)
   against product *unit prices*; a grand total is a different magnitude and overflowed it. Widened,
   with the measurement recorded on the token so it is not trimmed back.
2. **The number-and-date line on the mobile card overflowed at 400 logical pixels.** Both runs are
   fixed-width and neither may be truncated — an ellipsised invoice number is not an invoice number —
   so the row became a `Wrap`.

## What the Windows run proved, beyond the tests

Twelve invoices covering all five stored statuses plus a derived overdue, captured at desktop and
mobile widths and in dark mode. **Every tile was reconciled by hand against the rows:**

- Sales came to ۴۷٬۷۴۰٬۰۰۰ تومان — the sum of the three invoices *issued* in Shahrivar, excluding the
  draft, the cancellation, and the one issued in Mordad. D-039 and D-006 both visible in one figure.
- Outstanding came to exactly double the figure from a half-sized data set, which is what an
  aggregate that is neither double-counting nor dropping rows should do.

The rows were written through the **real repositories** by a throwaway integration script — the money
engine computed every total, `_allocateNumber` allocated every number, `PaymentRepository` derived
every status — because Phase 1 has no way to *create* an invoice. **The script was deleted after
use.** The Windows dev database therefore holds twelve demo invoices and twelve customers; if a
future session needs to reproduce it, write the equivalent again rather than reaching for a
committed fixture.

## Deferred out of (f2), deliberately

- **Search and filtering on the invoice list.** Customers and products have a search field; invoices
  do not. Filtering by status, customer and date range is Phase 5, and a half-version here would have
  to be replaced there.
- **Tapping an invoice.** `/invoices/:id` is **not registered** and rows are not tappable — asserted
  by a test, so the absence is deliberate rather than forgotten. Detail is Phase 5.
- **Creating or editing an invoice.** Phase 4. The empty state explains and stops.
- **Report period selection.** The dashboard covers the current Jalali month only; choosing a period
  belongs with گزارش‌ها in Phase 8, still absent from navigation entirely (D-021).

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | `onUpgrade` throws by design — no v1→v2 path exists | The first schema change needs a migration step **and** a test (§6, §14). |
| 2 | The database opens on the main isolate | Phase 13. The `setup` closure must stay isolate-sendable — `ARCHITECTURE.md` §B.5. |
| 3 | The national-ID checksum cannot catch every transposition | Official algorithm, not a defect. Enforced by test over the ARB **and** over the form's behaviour. |
| 4 | `watchDetail` re-reads on any invoice-table change | Correct but not minimal. Revisit in Phase 13. |
| 5 | ~~Dashboard and Invoices show their empty state unconditionally~~ | **Resolved in (f2).** |
| 6 | Settings is read-only, and its last-backup row would render an epoch number | `formatJalaliDateLong` exists; wire it when settings becomes editable. Currently unreachable — `lastBackupAt` is always null. |
| 7 | ~~No live `count()` on the repositories~~ | **Resolved in (f2)**: `watchCount` on customers, products and invoices. |
| 8 | `nowProvider` does not tick | Deliberate (D-041). A Jalali month boundary or a due date crossing midnight while the app sits open does not update until relaunch. One `invalidate` on resume fixes it if a later phase needs it. |
| 9 | The Windows debug exe shows no window when launched **directly** | Observed this session: the process starts and the VM service listens, but no window is presented. Under `flutter run -d windows` it is fine. Not caused by (f2) — screenshot via `flutter run`. Worth a look in Phase 12. |
| 10 | MIUI re-blocks `flutter test`'s install on a *fresh* install | `adb install -r` once by hand. Developer options → Install via USB. |
| 11 | **The pub mirror can go unreachable mid-session** | `dart pub get --offline` resolves from the local cache. Sanitize the lockfile **last** — the rule now lives in `tools/sanitize_lockfile`'s own header, where the mistake happens. |
| 12 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 13 | Release builds signed with debug keys | Phase 15. |
| 14 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12. |
| 15 | Android manifest hardening not done | Phase 9. |

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
  7. no output outside `AppLog`, and no sensitive field name inside a log call (D-035) —
     `// logging-exempt:`.
- **There are now exactly two soft-delete exemptions on read paths, and both are the same one:** the
  customer row behind an invoice, in `watchList` and in `findDetail`. §6 guarantees that row survives,
  and the Persian delete copy promises the invoice does. Do not "fix" them back.
- **A widget never calls a repository.** Feature `application/` folders hold the providers; the
  screen only decides what the user is told.
- **`AmountText` everywhere money appears**, and a money column in a table is **leading-aligned in a
  fixed-width column**, never `alignEnd` — see D-037's RTL note. `AmountText` is the only widget that
  renders a monetary figure.
- **Money is never accent-coloured** (D-033). Prominence comes from the type scale; colour means
  status, and red means overdue and nothing else.
- **`Override` is not exported by `flutter_riverpod` in 3.4.2.** It lives in
  `package:flutter_riverpod/misc.dart`. The error — *"The name 'Override' isn't a type"* — does not
  hint at it.
- **Riverpod 3 wraps a provider's error in `ProviderException`** — assert on the message, not the
  inner type (`ARCHITECTURE.md` §B.3).
- **Private `@riverpod` providers work.** The five underlying dashboard queries are private
  (`_outstandingRial` and friends) so nothing outside the summary can watch a single figure and
  reintroduce the "tiles from different moments" problem.
- **Widget tests render with a fallback font whose glyphs are much wider than Vazirmatn's.** A
  fixed-width column that passes a widget test has margin in the shipped layout, not the other way
  round — which is why `tablePriceWidth` is sized against the test, deliberately.
- **Nothing in `core/money/`, `core/date/` or `core/formatting/` may import Flutter.**
- **Where the source encoding is not guaranteed, name characters by code point.** Bitten three times:
  the fold tables, the Windows window title, and the bidi isolate constants.
- **Sanitize the lockfile after anything that resolves — and sanitize it LAST.** Sanitizing before
  `build_runner` makes pub re-resolve against the network, which hung this session too. The rule is
  now documented in `tools/sanitize_lockfile` itself as well as in `ENVIRONMENT.md`.
- **Run `dart run build_runner build` after touching a table or an `@riverpod`, and
  `flutter gen-l10n` after touching the ARB**, then commit the regenerated files.

## Recently changed files (increment f2)

```
lib/core/utils/clock.dart                     NEW  nowProvider, read once per frame (D-041)
lib/core/localization/month_names.dart        NEW  ARB -> the twelve names jalali_display wants
lib/data/models/invoice_list_item.dart        NEW  invoice + customer name, and no payments (D-040)
lib/data/models/invoice_status.dart           + kIssuedInvoiceStatuses / kOutstandingInvoiceStatuses
lib/data/repositories/*_repository.dart       + watchCount; invoice: watchList, watch* aggregates
lib/data/repositories/drift/drift_invoice_repository.dart
                                              + the join, the correlated-subquery outstanding sum,
                                                D-039's issued filter, and the findDetail fix
lib/data/repositories/drift/drift_{customer,product}_repository.dart  + watchCount
lib/features/invoices/domain/invoice_status_view.dart      NEW  the one stored -> displayed mapping
lib/features/invoices/application/invoices_providers.dart  NEW
lib/features/invoices/presentation/invoices_screen.dart    rewritten on real data
lib/features/dashboard/domain/dashboard_summary.dart       NEW  every figure, from one moment
lib/features/dashboard/application/dashboard_providers.dart NEW
lib/features/dashboard/presentation/{dashboard_screen,stat_tile}.dart  rewritten / NEW
lib/core/theme/app_dimensions.dart            + tableDateWidth, tableStatusWidth; tablePriceWidth 232
lib/core/localization/arb/app_fa.arb          +2 strings, 1 reworded (122 total)
test/features/invoices/{invoices_screen,invoice_status_view}_test.dart  NEW
test/features/invoices/fake_invoice_repository.dart        NEW  shared by both screen suites
test/features/dashboard/dashboard_screen_test.dart         NEW
test/data/repositories/invoice_repository_test.dart        +13 tests, 1 corrected (D-039)
tools/sanitize_lockfile                       + the ordering rule, where the mistake happens
docs/*                                        D-039..D-041; ROADMAP; ARCHITECTURE §B.2, §B.4
```

## Last completed action

Increment (f2) was accepted and **Phase 1 is complete**. Then, on the owner's instruction, re-scoped
**Phase 2** and **Phase 3** in `ROADMAP.md` to what increment (f1) did not already deliver, recorded
the re-scope as **D-042**, and added the size/startup baseline to `ROADMAP.md` as an **entry gate on
Phase 7** — to be taken on the commit immediately before the PDF dependency is added, because
afterwards the figures cannot be attributed. Phases 5 and 8 got the same "already delivered"
paragraph, since both also describe work that partly landed in (f2).

No code changed. 483/483 tests pass, analyzer clean.

## Next action

**Await the owner's confirmation before starting Phase 2 proper.** The re-scope is reported and
recorded; the owner said they would confirm before work begins.

When confirmed, Phase 2 is exactly two things — see `ROADMAP.md` and D-042, and **read the
"already delivered" list there first**:

1. **The customer detail screen at `/customers/:id`.** Start from
   `InvoiceRepository.watchForCustomer`, which already exists and has no call site — it was built in
   (d) for this screen. Reuse `InvoiceCard` / `InvoiceTableRow`; per-customer totals are SQL
   aggregates, needing one new repository read. Register the route **with** the screen (D-021), and
   keep the invoice rows non-tappable until `/invoices/:id` exists in Phase 5 — asserting that
   absence with a test, as (f2) does.
2. **Field-level limits at the form boundary** (§7), shared from one place with the table
   definitions, and applied to the product form too (which is all that remains of Phase 3).

**Do not rebuild the customer list, its search, its forms or its soft delete.** They shipped in (f1)
and were accepted. This is the specific mistake D-042 exists to prevent.

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); assert encryption on the file header.
- **The seven `lib/`-scanning guards** listed above are the project's memory of seven silent failure
  modes. Route through the helper; never weaken the test.
- **Sanitize the lockfile after any command that resolves dependencies, and do it last.** The
  pre-commit hook is the backstop and it does fire.
- **Regenerate and commit** after touching a table, a provider, or the ARB.
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
