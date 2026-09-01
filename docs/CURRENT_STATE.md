# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-09-01** — end of the session that delivered (d), the device pass, known issue
> 21 and (e). Stopped by the owner before (f).

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `COMPLETED`** (2026-08-24, seven increments, all accepted)
**Phase 2 — Customers · `COMPLETED`** (2026-08-25)
**Phase 3 — Products and Services · `COMPLETED`** (2026-08-25)
**Phase 4 — Invoice Creation · `COMPLETED`** (2026-08-27) — every increment delivered and
**accepted**, including (d).
**Phase 5 — Invoice Management and Payments · `IN_PROGRESS`** — split agreed. Everything up to and
including **(a2), schema v4** is **accepted**, and **(d) has been accepted since**. Awaiting review:
**(b)** the detail screen with the tier rule and the money-width audit (D-057, D-058), **the
known-issue-19 fix** (D-059), **(c)** payments (D-060), **the device pass and the keyboard rule**
(D-062, known issue 21), and **(e)** filters and paging (D-063). **Only the phase close, (f),
remains.**

| # | Increment | Status |
|---|---|---|
| a | The draft state model and its wiring to `core/money/` — no UI, fully tested | `COMPLETED`, **accepted** |
| a2 | **Numbering on issue + `schemaVersion = 2`** (D-048) | `COMPLETED`, **accepted** |
| a3 | **The table-rebuild guard** (D-049) | `COMPLETED`, **accepted** |
| b | Line item entry | `COMPLETED`, **accepted** |
| c | Invoice-level fields, and the save | `COMPLETED`, **accepted** |
| c2 | **The party snapshot + the payment term** (D-051, D-052) — `schemaVersion = 3` | `COMPLETED`, **accepted** |
| d | **The assembled screen**, all three tiers, routed (D-053) | `COMPLETED`, **accepted** |

### Phase 5

| # | Increment | Status |
|---|---|---|
| — | (d)'s carry-overs: §10 amended, the phone fold (D-054) | `COMPLETED`, **accepted** |
| a | **The D-047 ruling** (D-055) — decision only, no code | `COMPLETED`, **accepted** |
| a2 | **`schemaVersion = 4`** — three columns and their backfill (D-056) | `COMPLETED` 2026-08-27, **accepted** |
| b | **`/invoices/:id`**, the detail screen; rows tappable; the money-width audit and the tier rule (D-057, D-058) | `COMPLETED` 2026-09-01, **awaiting review** |
| — | **Known issue 19**: exact allocation at every invoice size (D-059) | `COMPLETED` 2026-09-01, **awaiting review** |
| c | **Payments: record and delete**, derived status in the same transaction (D-060) | `COMPLETED` 2026-09-01, **awaiting review** |
| d | **Cancellation**, the copy that says what it does not do, and the ruling on the payments it keeps (D-061) | `COMPLETED` 2026-09-01, **accepted** |
| — | **The phone-tier device pass**, the keyboard rule and known issue 21 (D-062) | `COMPLETED` 2026-09-01, **awaiting review** |
| e | **List filters** (status, customer, Jalali period) at the query level; paging `watchForCustomer` (D-063) | `COMPLETED` 2026-09-01, **awaiting review** |
| f | The phase close, with a device pass over (e) under the keyboard rule | `NOT_STARTED` ← **next** |


## Where the project stands, in one paragraph

**An invoice can be created, read as a document, and paid off.** Eight screens work end to end on real
data — Dashboard, Invoices, the invoice **form**, the invoice **detail** page, Customers, Customer
detail, Products, Settings — inside a Persian, RTL, three-tier responsive shell over an encrypted
SQLite database at **schema v4**. «فاکتور جدید» opens `/invoices/new`; a row in the list opens
`/invoices/:id`; and from there a payment can be recorded and taken back off again, with the derived
status recomputed by the repository in the same transaction.

**Phase 4 is complete and accepted. Phase 5 is eight boundaries in**, with only the phase close left.

**Accepted:** the two carry-overs from Phase 4 (d) plus **the D-047 ruling** (D-055); **(a2),
`schemaVersion = 4`** (D-056); and **(d), cancellation** (D-061).

**Awaiting review, five of them:** **(b), the detail screen** (D-057, D-058); **the known-issue-19
fix** (D-059); **(c), payments** (D-060); **the device pass, the keyboard rule and known issue 21**
(D-062); and **(e), filters and paging** (D-063).

**An invoice can now be read as the document it is.** `/invoices/:id` lays a line out from storage
alone — شرح · تعداد · مبلغ واحد · **مبلغ کل** · تخفیف · **مبلغ پس از تخفیف** · مالیات · جمع, with no
read site multiplying or rounding anything — and the summary starts from the stored `grossTotal`. Where
a pre-v4 figure was refused the screen says «ثبت‌نشده» on the line as well as the panel, never a zero.
**Rows are tappable**, and the two tests asserting the route's absence were inverted rather than
deleted.

**The party a document states is finally distinguishable from the customer record.** Four cases, one of
them silence; a renamed or soft-deleted customer is said in Persian, and
`InvoiceDetail.customerIsDeleted` is new because the customer behind an invoice is read
soft-delete-exempt and nothing else could tell.

**Verification changed shape, which was the point.** A phase now closes only after its layout check has
run at **all three tiers** over a **written ladder of amounts** (D-057, and the project spec). The ladder
lives in `test/support/money_magnitudes.dart`. The audit it demanded found a second overflowing money
site — `tablePriceWidth`, wrong by exactly the cell padding it never accounted for — and cleared the
dashboard tiles, which scale rather than clip.

**An invoice can be paid off, and unpaid again.** (c) adds the way in to a write side that already
existed: a sheet that offers the outstanding balance and fills it, a payments list whose deletion says
what it does — including, only where it is true, that it takes the invoice out of «پرداخت شده» — and
the refusal tests that matter, called against the **repository** rather than through the screen, each
asserting what the refusal left behind.

**And D-057 paid for itself inside one increment.** Writing the device fixture at the ladder's top rung
surfaced known issue 19 — the money engine refused an invoice above roughly 30 million تومان carrying a
10% discount, because §4 step 4 was the only place multiplying **two amounts** together. **Fixed before
(c) at the owner's direction** (D-059): `mulDivFloor` computes that one intermediate in `BigInt` and
hands back quotient and remainder together. The guard is untouched, VM/Web parity is unchanged, and the
arithmetic is pinned share-for-share against a plain-`int` reference of the old algorithm wherever that
reference is still exact.

**An issued invoice can be corrected, and the correction says what it costs.** (d) makes
cancellation reachable — a menu item in the title row, behind a confirmation that names what stays: the
number, the record, and every payment already taken. **Known issue 20 is resolved by a ruling** rather
than by a code change (D-061): a cancelled invoice keeps its payments, because the money did change
hands, and the three places that were silent about it now say so. Only an issued invoice may be
cancelled, and that rule moved into the repository where a deep link cannot get round it.

**Every editing sheet now pins its commit action above the keyboard.** `EditorSheet` is D-053's
split-by-purpose made a primitive (D-062, known issue 21): fields scroll, the action does not. The
survey behind it is the part worth remembering — `FormScaffold` and the invoice line sheet were
**already** correct, the payment sheet was the one defect, and the two **picker** sheets take the
shape not at all because they commit by tapping a row. A rule stated in one file was not a rule.
**And no widget test could have caught it**: `pumpScreen` installs its own `MediaQueryData`, so every
screen test this project has run had no keyboard at all. The harness takes `viewInsets` now.

**The invoice list can be narrowed, and the narrowing happens in SQL.** (e) adds status, customer
and Jalali-period filters applied as `WHERE` clauses on the statement that already carries the
ordering and the `LIMIT` — never a `.where` over a loaded page, which would apply the limit to the
wrong set and report "no results" for data behind the first page. **Known issue 16 is closed**:
`watchForCustomer` is paged, safe because the totals beside it are one SQL aggregate rather than a sum
of the page. «سررسید گذشته» is deliberately **not** a filter (D-063): it is derived at display time,
and a SQL predicate would be a second implementation of a rule `invoiceStatusViewOf` owns.

**Working tree is clean and everything is committed.** `main`'s tip is this continuity update; the
increment it describes is **`4d604da`** "Phase 5 (e): invoice filters in SQL, and a paged customer
list". Behind it: **`7775e0b`** is the known-issue-21 fix and the keyboard rule; **`099a437`** is the
phone-tier device pass; `b90f642`/**`2c20f7c`** is (d), "cancellation, and what it does not do";
`bf5c78b`/`241f446`/**`2747b2d`** is (c), "payments, recorded and taken back"; `ca1bc53`/**`6675456`**
is the known-issue-19 fix; `435f8cb`/**`b901c37`** is (b), "the detail screen, and the layout check
that would have caught its predecessor"; `42bbaae` is the (a2) cold-resume note and `712c921` is (a2)
itself; `d087c2a` is the first Phase 5 boundary; `a068d63`/`eecd96b` is Phase 4 (c2), `ea4858c` its
(c), `3164b8f` its (b), `0e0cd37` its (a3), `7345ca2` its (a2), `bf4c02f` its (a); `d8682ee` is Phases
2 and 3.

**Nothing is half-finished.** All five unreviewed boundaries are complete, tested, documented and
committed. **The session ended here at the owner's instruction** — "stopping here", given after (e)
was reported and with an explicit "do not start (f)". There is no work in progress, nothing
uncommitted and no question waiting on an answer. A fresh session starts at the Next Action at the
bottom of this file and needs nothing re-explained.

**The device debt is cleared.** The Android phone-tier pass ran for (b), (c) and (d) together on the
Redmi Note 8 Pro, and the two proofs that known issue 10b blocked in the (a2) session — D-020 and
startup — were re-run with it. **The product had no defects on the phone tier**; what failed, twice,
was the device test itself, which had only ever run on Windows and had encoded the desktop layout as
if it were the layout. See D-062 and known issue 21.

**One gap is known and named, and it is (f)'s to close: `integration_test/` has no coverage of the
invoice *list*.** Both device suites are the invoice form and the invoice detail screen. Everything
(e) built — the filter control, the filter sheet and its chips, the filtered empty state — has been
checked at three tiers in widget tests and has never run on the target in Vazirmatn. That is the
device pass (f) owes, and it must run under the keyboard rule, because the filter sheet opens the
customer picker and the picker raises a real keyboard.

**Note the collision when reading older sections of this file:** Phase 4 and Phase 5 both have
increments lettered (a2), (b), (c) and (d). Every reference below names its phase; where one does not,
it belongs to the section it sits in.

## Verification status

```
flutter analyze:            PASS   (No issues found)                          as of (e)
flutter test:               PASS   (935/935, was 895)                         as of (e)
Android build:              PASS   debug APK built (2026-09-01, re-run for (e))
Layout, all 3 tiers x 4 amounts (D-057):
  widget sweep:             PASS   money_layout_test.dart + invoice_detail_screen_test.dart,
                                   including the cancellation confirmation at every rung
  device - Windows desktop: PASS   0 layout errors, 1264 x 681, Vazirmatn, all four rungs each with
                                   an invoice-level discount; a payment recorded and deleted through
                                   the real sheet; and a cancellation through the real menu and
                                   confirmation, with 705,833 rial still on record afterwards
                                   (2026-09-01)
  device - Android phone:   PASS   Redmi Note 8 Pro, 392.7 x 803.6, pixel ratio 2.75 (2026-09-01)
                                   0 layout errors, all four rungs; a payment recorded and deleted
                                   through the real sheet; a cancellation through the real menu with
                                   705,833 rial still on record; correction leaving it cancelled.
                                   Clears the debt for (b), (c) and (d) together.
Keyboard rule (D-062):
  widget sweep:             PASS   sheet_keyboard_test.dart, 255 px inset, verified to bite
  widget sweep, pickers:    PASS   the customer picker's search field stays above the keyboard --
                                   the check that found the EmptyState overflow (D-063 §7)
  device - Android phone:   PASS   both editor sheets: keyboard 254.9 of 803.6, action bottom 532.7,
                                   limit 548.7 (2026-09-01, re-run after (e)). Was 618.6 before.
D-020 proof - Android:      PASS   re-run on the Redmi (2026-09-01), unblocked by 10b clearing
Startup proof - Android:    PASS   re-run on the Redmi (2026-09-01)
D-055 proof - Windows:      PASS   both ladders: v3 -> v4 and v1 -> v4 (2026-08-27)
D-055 proof - Android:      PASS   both ladders, on the Redmi (2026-08-27)
D-052 proof - Windows:      PASS   both ladders: v2 -> v3 and v1 -> v3
D-052 proof - Android:      PASS   both ladders, on the Redmi (2026-08-27)
D-048 proof - Android:      PASS   re-run on the Redmi (2026-08-27)
D-020 proof - Windows:      PASS   5/5 (2026-08-23, not re-run)
Form on the Redmi:          PASS   the whole flow through the real sheets, 0 layout errors (d)
Windows run:                PASS   the app starts and renders at the desktop tier (d)
                                   -- kept for the record, and NOT a layout check: this is the
                                   line D-057 exists because of. Superseded by the device pass
                                   above.
Web build:                  NOT_RETESTED since plugins were added
```

**Test count is 895**, was 892 after (d) and the device pass, 837 after D-059, 794 at the end of (b) and 726 at the end of (a2).

## What Phase 5 increment (e) delivered — filters in SQL, and a paged customer list

**Status, customer and Jalali period, applied by the repository as `WHERE` clauses** — and known issue
16 closed. **D-063.**

```
lib/data/models/invoice_filter.dart                      NEW  the value handed to the query
lib/features/invoices/domain/invoice_query.dart          NEW  window + filter, as one value
lib/features/invoices/presentation/widgets/invoice_filter_sheet.dart  NEW  the sheet
lib/core/date/jalali_period.dart                         + jalaliMonthShifted
lib/core/widgets/empty_state.dart                        scrolls instead of overflowing
lib/data/repositories/invoice_repository.dart            watchList(filter:), watchForCustomer paged
lib/data/repositories/drift/drift_invoice_repository.dart  _applyFilter; the page reaches SQL
lib/features/invoices/application/invoices_providers.dart  InvoiceQuery; filter() / clearFilter()
lib/features/invoices/domain/invoice_status_view.dart    + invoiceStatusViewOfStored
lib/features/invoices/presentation/invoices_screen.dart  the control, the count, the filtered empty
lib/features/customers/application/customers_providers.dart  CustomerInvoicesQuery family
lib/features/customers/domain/customer_detail_view.dart  + hasMoreInvoices
lib/features/customers/presentation/customer_detail_screen.dart  load-more, both tiers
lib/core/localization/arb/app_fa.arb                     + 16 strings
test/data/database/soft_delete_usage_test.dart           the scanner narrowed, with its own test
```

- **The filter reaches SQL, and one test says exactly why that matters**: twelve invoices, a page of
  five, the single match sorting last. Filtering in Dart would apply the limit before the predicate and
  return nothing — reporting "no results" about data that is right there.
- **The window and the filter are one value.** Narrowing resets to the first page; widening keeps the
  predicate. Both pinned, because both are the kind of rule that quietly stops holding.
- **«سررسید گذشته» is deliberately absent from the filters.** Derived at display time from one clock
  instant (D-041); a SQL predicate would be its second implementation, and the visible form of their
  disagreement is a badge the filter does not return. An overdue invoice is still reachable under its
  stored status.
- **The control is in the title row on every tier**, costing no height — §10's unbounded-card rule for
  the second time since it was written — **and it shows a count**, because a control that looks
  identical filtered and unfiltered is how a user concludes the app lost their invoices.
- **A filtered empty list is its own state**, offering «پاک کردن همه» rather than "make an invoice".
- **`jalaliMonthShifted` is new**, because «ماه گذشته» may not be a subtraction: from the last day of
  a 31-day Jalali month, thirty days back is the same month. The helper shifts the month **number**;
  a test stands on that exact day and shows the naive form failing.
- **Known issue 16 closed**, and the property that makes it safe is now asserted: the totals are one
  SQL aggregate over every invoice, not a sum of the page.
- **40 new tests; 935 pass** (was 895).

### Two scanners fired, and only one of them was right

- **The token scanner was right.** `const Duration(milliseconds: 1)` in the filter sheet was calendar
  arithmetic that had leaked out of `core/date/`. Fixed by `jalaliMonthShifted`, not by an exemption.
- **The soft-delete scanner was wrong.** It flagged Riverpod's `provider.select((q) => q.filter)` as a
  raw database read — and it is the narrowing §13 asks for by name. It could not be excluded by the
  lookbehind, because drift's `_db.select(table)` is also preceded by a dot; what separates them is
  that a provider selector is handed a *function literal*. The scanner now excludes that one form and
  has a test pinning it in both directions. An `soft-delete-exempt:` comment was refused: it would
  have claimed a deliberate database read where there is no database read.

### And the keyboard rule found a real defect on its first outing

Adding the **picker** sheets to the keyboard sweep — exempt from `EditorSheet` by design, but the rule
still applies to them in its own form — failed immediately. The customer picker's empty state
**overflowed by 24 logical pixels** with the keyboard up: 238 pixels of room against the 262 it needs,
on a 400 × 800 phone, at exactly the moment a user is typing a search that matches nothing.

`EmptyState` scrolls now. Clipping was refused — the part cut off would be the sentence explaining the
state, and an empty state without its explanation is the blank screen the widget exists to prevent.

**That is D-062 paying for itself inside one increment**, the way D-057 did by surfacing known issue
19. The rule was written for sheets with commit actions; the first thing it caught had neither.

## What the phone-tier device pass found (2026-09-01) — D-062

**Three sessions of debt cleared in one sitting**, for (b), (c) and (d) together, plus the two proofs
known issue 10b had blocked. **The product had no defects on the phone tier.** What failed — twice —
was the check.

```
device: Redmi Note 8 Pro, android
logical size: 392.7 x 803.6, pixel ratio 2.75, 16sp renders at 16.0
all four rungs: rendered; «ثبت‌نشده» shown on the invoice whose backfill was refused
payment: 2117500 rial recorded, status paid
deletion: status unpaid
cancellation: status cancelled, 705833 rial still on record, number INV-1405-0001
correction: status cancelled          (payment deleted off the cancelled invoice)
layout errors : 0
D-020 proof: PASS      startup proof : PASS
```

**Finding 1 — from (b): the device test asserted on the party where only a desktop puts it.** On the
narrow tiers the party card is the *fourth* block — summary → lines → payments → party — which is §10's
unbounded-card rule doing its job. A `ListView` child past its cache extent is **not in the tree**, so
the finder reported absence rather than invisibility, and `ensureVisible` could not have rescued it:
that needs an element that already exists. Fixed with a `reach` helper that scrolls until the finder
matches and rewinds each list it searched.

**Finding 2 — from (c): the payment sheet's save button is below the fold on a phone, and the tap
missed it.** `autofocus: true` on the amount field raises the soft keyboard the moment the sheet opens.
Measured on the device: the keyboard takes **254.9 of 803.6** logical pixels, and «ذخیره» sits at 618.6
against a visible area ending at 548.7. The sheet scrolls, so it is reachable and it is not an
overflow — but a desktop-written tap lands on the sheet's Material. Fixed in the test with
`ensureVisible`; **the UX half is recorded as known issue 21 and left for the owner**, because the fix
is a design decision with a precedent (D-053's split by purpose) rather than a correction to smuggle
into a device pass.

**Both findings are the D-057 lesson one level up.** D-057 exists because a check run at one tier is
evidence about one tier. The device test *is* that check — and it was itself single-tier. That is now
a rule: **an integration test reaches what it asserts; it does not assume where it is** (D-062).

**What did not recur:** known issue 10, MIUI blocking the install on a fresh install — the APK
installed first try, three times.

## What Phase 5 increment (d) delivered — cancellation, and what it does not do

**The correction path §6 prescribes, finally reachable — and a ruling on the money it leaves behind.**
`InvoiceRepository.cancel` has existed since Phase 4 (d); (d) is the way in, the copy, the guard and
**D-061**, which resolves known issue 20.

```
lib/features/invoices/presentation/widgets/invoice_cancel_action.dart  NEW  the menu + confirmation
lib/features/invoices/application/invoice_cancellation.dart            NEW  the one write
lib/data/models/invoice.dart                             + Invoice.isCancellable
lib/data/repositories/invoice_repository.dart            + InvoiceNotCancellable; cancel() contract
lib/data/repositories/drift/drift_invoice_repository.dart  cancel() guards, in its own transaction
lib/data/repositories/drift/drift_payment_repository.dart  the early return names its ruling
lib/features/invoices/presentation/invoice_detail_screen.dart  the menu; the cancelled «مانده» note
lib/features/invoices/presentation/widgets/invoice_payments_section.dart
                                                         cancelled notice; cancelled delete wording
lib/core/localization/arb/app_fa.arb                     + 9 strings, 1 reworded
The project spec                                            the unbounded-card rule, three instances named
test/data/repositories/invoice_repository_test.dart      + 3 guard/ruling tests
test/features/invoices/invoice_detail_screen_test.dart   + 28 tests (16 + the 12-rung dialog sweep)
test/features/invoices/fake_invoice_repository.dart      cancel() implemented, ids recorded
integration_test/invoice_detail_device_test.dart         + cancellation on the real target
```

- **The ruling (D-061, known issue 20): a cancelled invoice keeps its payments.** The money changed
  hands. A cancellation is a statement about the **claim**, not about the **cash**, and deleting the
  payments with the invoice would falsify the financial record in the one direction it must never
  move — making received money disappear. That was already the behaviour, via an early return in
  `_recomputeStatus`; what was wrong is that it was decided by nobody and said to nobody.
- **So it is said in three places, each pinned by test.** In the confirmation *before* the
  commitment; on the page *after* it; and in the code, where the early return now names the ruling
  instead of looking like an oversight.
- **The confirmation names three consequences and, conditionally, a fourth.** The record is kept
  rather than removed, the number stays spent (D-013), editing is still not the way back — and, **only
  where the invoice carries payments**, that they are neither erased nor refunded, with the amount
  named rather than described. `invoiceCancelBody` is asserted to contain «حذف نمی‌شود», «شماره» and
  «ویرایش», exactly as the issue confirmation's copy is pinned, so it cannot decay into «مطمئن
  هستید؟».
- **Afterwards the page owes two more sentences, and gives them.** A cancelled invoice carrying
  payments says the payments below were really received — a void document showing a paid figure with
  no explanation reads as a bug rather than as a fact. And **«مانده» is explained, not hidden**: the
  figure is real, but on a void document it reads as money still owed. Removing the row was considered
  and refused, because a number that vanishes by status is harder to trust than one that explains
  itself.
- **Both payment operations on a cancelled invoice are now decided rather than inherited.** Recording
  stays **refused**, and the copy names the way forward — money genuinely received belongs on the
  replacement invoice, the correction path §6 already prescribes; a refusal that names no alternative
  leaves the user holding real money with nowhere to put it. Deleting stays **allowed**, because a
  mis-entered receipt is a fault in the money record and the record must be correctable either way —
  and it gets its own confirmation wording, since the ordinary one («مانده به همان اندازه افزایش
  می‌یابد») is *false* on a document where nothing is owed.
- **Only an issued invoice may be cancelled, and the rule is the repository's.** `cancel` accepted any
  status; it now throws `InvoiceNotCancellable` for a draft and for one already cancelled, **checked
  inside the same transaction as the write**, on (c)'s precedent. A draft is withdrawn by deletion —
  it has no number and nobody has seen it — and a second cancellation would change no fact while
  bumping `updated_at` into a sync-pending row. `InvoiceNotCancellable` is a separate type from
  `InvoiceNotEditable` because they are opposite refusals, and one exception could not tell the UI
  which of two contradictory things to advise.
- **The action went in the title row, and that is the §10 rule this increment wrote down.** A cancel
  card would have been the fourth thing to push the first invoice line off a 400 × 800 phone, after
  D-044's customer record card, (b)'s party card and (c)'s payments card. §10 now carries the rule with
  all three instances named, and (d) is the first thing it applied to: a `PopupMenuButton` in the page
  title costs no vertical space at any tier and matches the customer and product screens.
- **The page does not navigate away after cancelling**, unlike the customer screen's delete: the state
  just created is precisely the one that needs explaining.
- **31 new tests; 892 pass** (was 861). Decision recorded: **D-061**.

### The device pass cancels, as well as pays

On Windows, at the desktop tier in Vazirmatn: the **real** menu, the **real** confirmation with money
sitting on the invoice, the write through the real repository into the real encrypted database, and
every status read back **from the database** rather than from the screen.

```
payment: 2117500 rial recorded, status paid
deletion: status unpaid
cancellation: status cancelled, 705833 rial still on record, number INV-1405-0001
correction: status cancelled          (a payment deleted off the cancelled invoice)
layout errors : 0
```

**The Android phone tier is now owed for (b), (c) and (d).** No device has been attached in any of the
three sessions. Carried to (f).

## What Phase 5 increment (c) delivered — payments, recorded and taken back

**The write side already existed.** `PaymentRepository.record` and `softDelete` landed in Phase 4 (d),
both recomputing the derived status inside their own transaction (§6). (c) adds the way in, the guard
tests that matter, and the copy that says what a deletion does.

```
lib/features/invoices/presentation/widgets/payment_editor_sheet.dart      NEW  the sheet
lib/features/invoices/presentation/widgets/invoice_payments_section.dart  NEW  the list + both actions
lib/features/invoices/application/invoice_payments.dart                   NEW  record / delete
lib/features/invoices/domain/payment_method_label.dart                    NEW  the one Persian mapping
lib/data/models/field_limits.dart                        + PaymentLimits.note (500)
lib/features/invoices/presentation/invoice_detail_screen.dart  payments card; mobile FAB; reorder
lib/core/localization/arb/app_fa.arb                     + 24 strings
test/data/repositories/payment_repository_test.dart      + the refusal aftermath, both directions
test/features/invoices/invoice_detail_screen_test.dart   + 14 payment tests and a payment fake
integration_test/invoice_detail_device_test.dart         + record and delete on the real target
```

- **The rule is the repository's; the screen explains it.** A draft and a cancelled invoice cannot take
  a payment (`Invoice.acceptsPayments`, `PaymentNotAccepted`). The screen hides the control **and says
  why in Persian** rather than leaving a user to guess what changed — but hiding a control is not a
  guard, so the tests call the **repository directly**, on Phase 4 (c)'s precedent, and each asserts
  what the refusal *left behind*: status unmoved, total unmoved, no stray row. The hard case is in
  there deliberately — a cancelled invoice that already carries a payment, where a write-then-check
  implementation shows up as a changed total rather than only as an orphan.
- **Two refusals were missing entirely** and are covered now: deleting a payment that is not there, and
  deleting the same one twice — the double-tap and the stale second window.
- **The status moves in both directions, and both are pinned**: paid → partiallyPaid → unpaid, one
  deletion at a time; removing the only payment returns the invoice to unpaid; and deleting a payment
  on a **cancelled** invoice corrects the money record without resurrecting the invoice, because
  `cancelled` is set by hand and never derived (§6).
- **Deleting says what it does.** The confirmation names the amount, and **only where it is true** adds
  that this takes the invoice out of «پرداخت شده» — a warning shown every time is one nobody reads on
  the occasion that matters. That sentence is a claim about what the user is about to cause, not a
  second derivation of the status: the badge changes because `invoiceDetailProvider` is a live query
  and the row changed.
- **An overpayment is warned about as it is typed, never refused.** The repository accepts one and
  `amountDue` clamps at zero, so an overpayment is invisible in the balance by design — D-027's
  principle applied to an input. **The sheet computes nothing**: `amountDue` arrives already worked out
  and is used for the «مانده» line and the button that fills it.
- **The payments card went below the lines, measured rather than argued.** On a 400 × 800 phone it
  costs **182 logical pixels with nothing in it**, and between the summary and the lines it pushed the
  first line off the bottom — D-044's finding met for the third time. Narrow-tier order is now
  **summary → lines → payments → party → dates → notes**, the same order the desktop tier reads in.
- **On mobile the record action moved to the floating slot and the inline button is omitted there** —
  the invoice list's own rule, applied again: two controls saying the same thing is one too many. Each
  tier offers the action exactly once.
- **The phone-height test from (b) caught it**, which is the second time that deliberately awkward test
  has earned its keep, on a different card each time.
- **24 new tests; 861 pass** (was 837). Decision recorded: **D-060**.

### The device pass now writes, not just renders

On Windows, at the desktop tier in Vazirmatn: the **real** sheet opens, the balance is filled through
the sheet's own control, a method is picked, the write goes through the real repository into the real
encrypted database — and the status is read back **from the database rather than from the screen**,
because the screen believing it is not the claim. Then the payment is deleted, the status warning is
asserted to appear exactly where it should, and the status is read back again.

```
=== PHASE 5 (b)+(c) DETAIL SCREEN ON DEVICE ===
platform : windows    logical size : 1264.0 x 681.0    16sp renders at 16.0
payment: 2117500 rial recorded, status paid
deletion : status unpaid
layout errors : 0
```

**Android is still outstanding**, for (b) and now (c) both: no device has been attached in this
session. Carried to (f), per D-057.

## What the known-issue-19 fix delivered — exact allocation (D-059)

**Taken before (c), at the owner's direction, and it is a money-engine change rather than a screen
one.** §4 step 4 was the **only place in the engine that multiplies two amounts together** — an invoice
discount by a line's net — so the product is quadratic in the invoice total and passed 2⁵³ at:

```
 1% invoice discount   refused above roughly  95,000,000 تومان
 5%                    refused above roughly  42,000,000
10%                    refused above roughly  30,000,000
25%                    refused above roughly  19,000,000
```

Every other §4 step multiplies an amount by a **small factor** — a milli-quantity, a basis-point rate,
a rounding unit — so its product is linear in the invoice and stays inside 2⁵³ until the amount itself
approaches `kMaxAmountRial`. That is the test to apply to any future step: **if both operands scale
with the invoice, the intermediate has to be exact.**

### The guard was working, and the fix leaves it alone

The throw landed on the **preview**, as the user typed, because `InvoiceEditorState`'s constructor runs
the engine — the form was replaced by an error view. That reads as the worst place for it and is in
fact the right one: **the invoice was blocked and no wrong total ever reached a document.** Without
`checkedMultiply` the product would have lost its low digits on the Web and produced an allocation that
did not sum to the discount — lines disagreeing with their header, which is the failure §4 exists to
prevent.

So the **intermediate** goes, not the guard. `Money.rial` still refuses past `kMaxAmountRial`,
`checkedMultiply` still refuses a wide product everywhere else, and `mulDivFloor` refuses any operand
or result that could not survive a JS number. VM and Web still reject identically.

```
lib/core/money/rounding.dart              + mulDivFloor(a, b, c) -> (quotient, remainder)
lib/core/money/discount_allocation.dart     one call replaces both wide products
test/core/money/rounding_test.dart        + 8 tests over the primitive
test/core/money/discount_allocation_test.dart  + the ladder sweep, the boundary, the reference check
test/core/money/invoice_calculator_test.dart   + the ladder through the whole engine
test/features/invoices/invoice_editor_state_test.dart + the ladder through the live preview
integration_test/invoice_detail_device_test.dart  the top rung's discount special case removed
```

- **`BigInt` for the intermediate, and only the intermediate.** §4 forbids `double` and `num` because
  they *lose digits*; `BigInt` is an exact integer type that loses none, it is `dart:core` on every
  target, and nothing stores, returns or compares one. Both results are checked back into the
  exactly-representable range before they leave, so every value crossing the function's boundary is an
  `int`, as before.
- **The arithmetic is unchanged, and that is asserted rather than claimed.** Same proportions, same
  floor, same largest-remainder distribution, same tie-break toward the earlier line — the property two
  devices depend on to agree after sync. `discount_allocation_test.dart` runs a **plain-`int` reference
  implementation of the old algorithm** on every input where plain `int` is still exact and requires
  share-for-share agreement; `rounding_test.dart` does the same for the primitive.
- **Pinned at the magnitudes it broke at**, over the D-057 ladder rather than numbers chosen here:
  every rung × 1 / 5 / 10 / 25%, in the allocation, in `calculateInvoice`, and in `InvoiceEditorState`
  — the last because the preview is where a user actually met it. A separate test asserts the sweep
  **still reaches** a product the old code refused, so lowering the ladder is noticed rather than
  quietly turning the group into decoration. The boundary has its own case: **94906265 and 94906266**,
  the last invoice the old code could allocate and the first it could not, derived from 2⁵³.
- **Verified to bite**, as D-049's guard was. The old implementation was put back and the new tests run
  against it: **four fail** — the top rung at 5%, 10% and 25%, plus the boundary — while the
  plain-`int` equivalence tests stay green, which is the evidence they check agreement rather than
  accidentally catching the bug. Restored afterwards.
- **The device fixture's special case is gone.** `invoice_detail_device_test.dart` had to skip the
  invoice-level discount at the top rung to run at all; every rung now carries one, and the Windows
  pass issues and renders 100,000,000 تومان with a 5% discount, 0 layout errors.
- **43 new tests; 837 pass** (was 794). Decision recorded: **D-059**.

### How it was found, which is the part worth keeping

**It surfaced from writing the D-057 device fixture at the ladder's top rung — one increment after
D-057 was written.** Nothing in the codebase pointed at it and no test failed; the editor, the list and
the dashboard had run for two phases without anybody meeting it, because the demo data never went above
a few million Toman. It appeared because a rule was written down saying the amounts must be named in
the check rather than taken from whatever the dev database holds, and then that rule was followed once.

That is **D-057 paying for itself inside a single increment**, and it is the argument for the rule that
no amount of reasoning about the rule could have produced.

## What Phase 5 increment (b) delivered — `/invoices/:id`, and the money-width audit

**Two things, and the smaller one was the screen.** The owner's ruling on (a2) was that the desktop
overflow mattered more than the overflow: a defect firing on essentially every realistic Iranian
invoice passed a phase close, because the device pass ran on one tier at whatever amounts the flow
produced. So (b) carries a **process change** (D-057), an **audit of every fixed-width money site**,
and the detail screen itself (D-058).

### The process change — D-057

**A phase closes only after its layout check has run at all three tiers, over a written ladder of
amounts.** Both halves are load-bearing, and the ladder is named once so a check cannot quietly
exercise a friendlier one:

```
test/support/money_magnitudes.dart
  100,000 تومان    a small invoice; the rung everything already passed
1,000,000 تومان    where the summary panel first overflowed
10,000,000 تومان    an ordinary workshop or contractor invoice
100,000,000 تومان    a large project invoice, and a plausible lifetime total for one customer
```

The project spec now carries the rule; D-057 carries the reasoning and the alternatives refused. A
**measurement is not a check** — the panel's overflow was measurable for a whole increment before
anyone measured it — so the artifact is a widget test that renders the real composed thing and lets a
`RenderFlex` overflow fail on its own.

### The audit — two sites were wrong, not one

```
summary panel grand total   AmountSize.large needs 376; detailPanelWidth 320 leaves 288
                            -> over by 30 px at 1,000,000, 58 at 10,000,000, 86 at 100,000,000
tablePriceWidth = 232       a cell spends AppSpacing.md on the gap, so the amount had 220
                            -> over by 9 px at 100,000,000 تومان
StatTile (dashboard,        four `large` figures in 274 px tiles - checked, and FINE:
customer totals)            FittedBox scales rather than clips. Deliberate, and now tested.
```

- **The grand total steps down to `AmountSize.medium` on every tier.** Widening the panel and wrapping
  the unit onto a second line were both weighed and refused — the first takes width from the table
  D-053 already fought for, the second still overflows at the top rung *and* makes the panel jump under
  the figure the user is reading. `dense` now controls spacing only, which is what it was for.
- **`tablePriceWidth` is derived rather than chosen**: `amountWidthSmall + AppSpacing.md`. The old
  value carried a comment claiming a ten-digit Toman figure fit; it had never accounted for the cell's
  own padding, and the two cannot drift apart again.
- **New tokens `AppLayout.amountWidthSmall / Medium / Large`** — 232 / 276 / 376, the measured width
  each size needs at the ladder's ceiling. The rule they encode: **a container that cannot give an
  amount the width its size needs takes a smaller size, never a clipped figure.**

### The screen

```
lib/features/invoices/presentation/invoice_detail_screen.dart          NEW  the screen
lib/features/invoices/presentation/widgets/invoice_document_lines.dart NEW  the stored line, both layouts
lib/features/invoices/domain/invoice_party_view.dart                   NEW  InvoicePartyProvenance
lib/core/widgets/record_field.dart                                     NEW  promoted from customer detail
lib/core/theme/app_dimensions.dart                     + amountWidth*; tablePriceWidth derived
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart grand total -> medium
lib/features/invoices/application/invoices_providers.dart              + invoiceDetail(id)
lib/data/models/invoice_detail.dart                    + customerIsDeleted
lib/data/repositories/drift/drift_invoice_repository.dart              _detail sets it
lib/core/router/{destinations,app_router}.dart         + /invoices/:id, declared after `new`
lib/features/invoices/presentation/invoices_screen.dart                rows tappable, both tiers
lib/features/customers/presentation/customer_detail_screen.dart        rows tappable; uses RecordField
lib/core/localization/arb/app_fa.arb                   + 25 strings
test/support/money_magnitudes.dart                     NEW  the ladder (D-057)
test/core/widgets/money_layout_test.dart               NEW  the sweep
integration_test/invoice_detail_device_test.dart       NEW  the desktop device pass
```

- **Nothing on the screen computes.** Every figure on a line is a column on the row — since v4 that
  includes the gross and the allocated share. A read site that multiplied `unitPrice × quantity` would
  apply *today's* rounding rule to *yesterday's* document, where `single_calculation_path_test.dart`
  cannot see it, because it never calls the engine at all.
- **The party is `InvoiceDetail.party`, never `detail.customer`**, and the difference is finally
  visible. `InvoicePartyProvenance` has four cases and **one of them is silence** — the ordinary case
  says nothing, because a panel that explained itself on every invoice would train the user to skip the
  explanation on the one invoice where it matters. The comparison is over the **whole** snapshot, not
  the name: a corrected کد ملی moves a document as much as a rename, and it is the field an auditor
  reconciles against.
- **Soft deletion stacks with a rename**, which needed a new fact on the aggregate:
  `InvoiceDetail.customerIsDeleted`. The customer behind an invoice is read soft-delete-exempt (§6
  promises it is never hard-deleted), so `detail.customer` is a live record that may no longer be in the
  customer list. `Customer` still carries no delete state, deliberately.
- **Eight document columns do not fit, and the constraint is recorded rather than the layout squeezed.**
  Six money columns at `tablePriceWidth` is 1464 logical pixels against the 1144 a desktop content
  column has. Five columns carry the figures that vary independently — قیمت واحد, مبلغ کل, جمع سطر —
  and the deductions run under the description as labelled lines, the shape the editor's table and
  every card already use. **Every stored figure is on the row**; the eight-column layout is the
  renderer's problem (§12), on a page rather than in a viewport, and it now has everything it needs.
- **The party card sits *below* the lines on a narrow screen**, and the phone-height test is what found
  it: above them it pushed the first line off a 400 × 800 phone entirely. That is D-044's finding about
  the customer record card, rediscovered on the screen whose purpose is to show the lines. Every other
  test there uses a tall viewport so assertions are about the page rather than scroll position; **one**
  keeps the real phone height, so the ordering cannot regress silently.
- **Read-only, deliberately.** Payments are (c), cancellation is (d), and there is no control here
  pretending to do either (D-021). It does show `amountPaid` and `amountDue`, with the overpayment
  called out — `amountDue` clamps at zero because an invoice cannot owe money, so an overpayment is
  invisible in the figure while usually being a data-entry error.
- **The two absence tests were inverted, not deleted** — `invoices_screen_test.dart` and
  `customer_detail_screen_test.dart`. Deleting them would have left the tap untested at exactly the
  moment it started doing something.
- **68 new tests; 794 pass** (was 726): the money sweep (28), the detail screen (38), the party
  provenance rule (7), the two inverted tap assertions and the soft-deleted-customer repository test.
  Decisions recorded: **D-057**, **D-058**.

### The device pass, stated by tier

`integration_test/invoice_detail_device_test.dart` runs the whole ladder against the real screen on
whichever target it is given — on Windows that is the desktop tier and the layout that was never
checked — with a customer **renamed after issue** so D-052's notice renders, and an invoice whose gross
was **nulled** so «ثبت‌نشده» has to fit where the widest figure would have gone.

```
=== PHASE 5 (b) DETAIL SCREEN ON DEVICE ===
platform: windows          logical size : 1264.0 x 681.0    16sp renders at 16.0
100,000 تومان     rendered      1,000,000 تومان     rendered
10,000,000 تومان  rendered    100,000,000 تومان     rendered, «ثبت‌نشده» shown
layout errors : 0
```

**Android is outstanding: no device was attached this session** (`flutter devices` lists Windows, Chrome
and Edge; the emulator is offline). D-057 covers this case explicitly — the widget sweep covers all
three tiers and the device pass is recorded as outstanding rather than assumed. It belongs to (f).

### A new known issue, found by writing the device fixture

**The money engine refuses a large invoice that carries an invoice-level discount.** Largest-remainder
allocation computes `checkedMultiply(invoiceDiscount, lineNet)` before dividing, and that intermediate
is checked against 2⁵³ so the VM and the Web reject the same inputs (D-002). The ceiling is therefore
on a **product of two figures**, far below `kMaxAmountRial`:

```
5% invoice discount   refused above roughly  42,000,000 تومان
10% invoice discount  refused above roughly  30,000,000 تومان
```

That is inside the range a real project invoice reaches, and it surfaced only because the ladder went
to 100,000,000.

**It is worse than "cannot be issued", and the difference was checked rather than assumed.**
`InvoiceEditorState`'s constructor runs the engine, so the throw lands on the **preview** — verified
directly: `MoneyRangeError: product out of range: 100000000 x 1000000000`. `InvoiceEditor.build` fails,
and the screen renders `AsyncErrorView` in place of the form the user was filling in. The guard is doing
exactly its job and nothing is silently wrong; the invoice simply cannot be entered.

It is `core/money/`'s to answer, not a screen's, and it needs a ruling rather than a patch: allocate
without the wide intermediate, or state the limit and surface it **as data rather than as an
exception**, the way D-027's clamps already are. See known issue 19.

## What the first Phase 5 boundary delivered

### (d)'s two carry-overs

- **The project spec now states the constraint, not the layout.** The desktop requirement read "a
  sticky invoice summary panel"; that panel does not fit beside the invoice table at any window size
  (D-053). §10 now records what the requirement is *for* — the figure being agreed to must not scroll
  away — with the measurement that beat the original wording, and the composition rule (d) surfaced:
  **a widget tested only at its own full width has not been tested at the width it is composed into.**
- **The invoice-level fields fold on a phone and start folded** (D-054). Field order unchanged, per
  the owner's ruling. The heading states the customer folded or not — it is the one field a save
  cannot do without, and folding it away would leave the «مشتری را انتخاب کنید» notice pointing at
  something off screen.

**Measured on the Redmi, which is how the default was chosen:**

```
folded    add-line buttons at 586 px, bottom 611 ; pinned bar begins at 670  -> fits, 59 px spare
unfolded  add-line 400 px of scrolling away; issue date field at 245 px
```

The surprise worth keeping: folded, the add-line buttons are *still* 586 px down, because the lines
section renders its designed empty state above them. The fold saves 400 px; the empty state costs
about 250 of what is left. **The owner has ruled that the empty state stays** (2026-08-27, recorded in
D-054): an empty lines section that said nothing would be worse than one that costs scroll. **If a
later phase wants that space, that is where it went, and taking it back is a decision about the empty
state** — not about the fields.

### (a) — the D-047 ruling, decision only

**D-055: store the gross, and two per-line figures with it.** `invoices.gross_total_rial`,
`invoice_items.line_gross_rial`, `invoice_items.allocated_invoice_discount_rial`.

- Decided with the detail screen and the PDF renderer both in view, as directed. An Iranian invoice
  line prints مبلغ کل and مبلغ پس از تخفیف, and the schema stores neither the line's gross nor its
  share of the invoice discount — while `line_net_rial` is net *after* a deduction the header prints
  again. A document laid out from what is stored today reconciles nowhere.
- **Recomputation rejected** on three grounds: it re-runs §4 step 1 where D-046's scan cannot see it;
  step 1 carries a rounding rule, so a recomputed gross is today's rule applied to yesterday's
  document; and §12 requires the renderer to receive a view model it does not compute.
- **These are backfilled, unlike D-052's snapshot**, and the difference is recorded because the two
  look alike. A party snapshot would be fabricated history; these are arithmetic over columns the row
  already carries, under a rounding rule that has not changed. Where a row cannot be reconciled to the
  Rial, the migration leaves them **null** — `NOT NULL DEFAULT 0` is refused, because zero is a number
  a document would print.
- **No code yet.** It is `schemaVersion = 4` and lands as (a2).

## What Phase 5 increment (a2) delivered — schema v4, and the backfill that checks itself

**The project's third migration, and the first that backfills.** Three nullable columns, three
`ADD COLUMN`s guarded by `_addColumnIfAbsent`, a backfill, and a `foreign_key_check`.

```
lib/data/database/tables/invoices.dart              + gross_total_rial
lib/data/database/tables/invoice_items.dart         + line_gross_rial,
                                                      allocated_invoice_discount_rial
lib/data/database/app_database.dart                 schemaVersion 4; migrateV3ToV4;
                                                    _migrateV1ToV2 is now public migrateV1ToV2
lib/data/database/invoice_figures_backfill.dart NEW the backfill, and its report type
lib/core/money/money.dart                           + Money.rialOrNull
lib/data/models/invoice.dart                        + grossTotal (Money?), hasStoredGross
lib/data/models/invoice_item.dart                   + gross, allocatedInvoiceDiscount (Money?)
lib/data/repositories/drift/mappers.dart            read all three
lib/data/repositories/drift/drift_invoice_repository.dart  create/updateDraft/_writeItems write them
lib/features/invoices/domain/invoice_summary_figures.dart NEW the view model (b) and Phase 7 share
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart  takes the view model
lib/core/localization/arb/app_fa.arb                + invoiceFigureUnrecorded, ...GrossUnrecordedNote
drift_schemas/drift_schema_v4.json                  NEW  schema dump
test/data/database/generated/schema_v4.dart         NEW  drift_dev schema generate output
integration_test/invoice_figures_migration_proof_test.dart NEW  the device proof, both ladders
```

- **The backfill runs `calculateInvoice` rather than re-deriving anything** (D-056). It rebuilds an
  `InvoiceInput` from the row's own stored columns and **writes nothing unless the engine reproduces
  every figure already on the row** — each line's discount, net, tax and total, and the invoice's
  subtotal, total discount, total tax, and grand total less its stored rounding adjustment. Third
  sanctioned caller in `single_calculation_path_test.dart`, listed with its reason rather than
  exempted, because open-coding §4 step 1 and largest-remainder allocation in the data layer is the
  second implementation D-046 exists to prevent.
- **That turns D-055's weakest premise into a check.** D-055 argues backfilling is honest because the
  rounding rule has not changed since v1. The migration does not rely on the argument: it verifies it
  per invoice, and refuses the ones that disagree.
- **Refusal is per invoice, never per line.** An invoice with a gross on three lines and a null on the
  fourth reconciles nowhere and admits nothing. The invoices beside a refused one are unaffected.
- **An invoice with no lines gets a real zero**, not a null — the one place "nothing" and "unknown"
  have to be told apart, which is what the nullable column is for.
- **Only alive lines take part, in `position` order.** `updateDraft` soft-deletes the lines it
  replaces, so a real database has superseded lines beside the live ones; they took no part in the
  stored totals and belong to no document, so they are excluded and stay null. Order matters because
  largest-remainder breaks ties toward the earlier line.
- **Paged, 100 at a time**, and a test seeds **250 invoices** — a paging bug is invisible on a fixture
  of three and shows up only as the invoices past the first page keeping their nulls, on the largest
  installs.
- **The v1 → v4 asymmetry is observed, not assumed.** `migrateV1ToV2` was made public (on
  `migrateV2ToV3`'s precedent) so a test can run the ladder one step at a time and read
  `PRAGMA table_info` between them: a v1 database arrives at the v4 step with `gross_total_rial`
  **already present** — the rebuild brought it from today's declaration — and both `invoice_items`
  columns **absent**, while a v3 database has none of the three.
- **`assertForeignKeysCanBeDisabled` is deliberately not called**, on D-052's reasoning: `ADD COLUMN`
  drops nothing and neither does an `UPDATE`. The step is instead run inside a transaction with
  children present and the rows counted.
- **The read path says «ثبت‌نشده»** — not a blank cell (D-048's principle) and not a zero — with a
  sentence beneath the panel saying the payable amount is unaffected. `InvoiceSummaryFigures` carries
  the absence in the type (`Money? grossTotal`, `.ofCalculation` / `.ofStored`), and
  `InvoiceTotalsSummary` now takes it, so the form and the detail screen render **one** panel and the
  wording lives in one place.
- **Device proof, both ladders**, on Windows and on the Redmi (2026-08-27), each backfilling one
  invoice and refusing another:

```
=== D-055 MIGRATION PROOF (v3 -> v4) on android ===
user_version: 3 -> 4        foreign_keys : 1        file state : encrypted
gross (good): 4250000       gross (bad): <null>
line grosses: [2000000, 2250000]      allocations : [50, 50]

=== D-055 MIGRATION PROOF (v1 -> v4) on android ===
user_version: 1 -> 4        (identical results through the three-step ladder)
```

- **41 new tests; 726 pass** (was 696). Decision recorded: **D-056**.

### The finding (a2) turned up and did not fix

**The desktop summary panel's grand total overflows at any realistic invoice amount.**
`AmountSize.large` inside `AppLayout.detailPanelWidth` (320) overflows by **30 px at 1,000,000 تومان**
and **58 px at 10,000,000**; 100,000 تومان still fits. The `dense` variant the phone bar uses does not
overflow at any magnitude — which is why (d)'s Redmi pass reported zero layout errors: it exercised
only the phone tier, and the Windows check was "the app starts and renders".

It is exactly the class of defect D-053 and (d) surfaced, one tier over, and it belongs to **(b)**,
which builds the desktop detail screen and is where this panel next renders a stored invoice. Not
fixed here: it is a layout decision on a widget (d) delivered, and (a2) is a migration.

Measured in a widget test, so the metrics are the test font's rather than Vazirmatn's and the exact
threshold is indicative. That it is magnitude-dependent and desktop-only is not.

## What Phase 4 increment (d) delivered — the assembled screen

**Phase 4 closes here.** `/invoices/new` exists and the invoice list routes to it.

```
lib/features/invoices/presentation/invoice_editor_screen.dart          NEW  the screen
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart NEW  the breakdown
lib/core/router/{app_router,destinations}.dart      + /invoices/new, before any future :id
lib/features/invoices/presentation/invoices_screen.dart  + create button, FAB, empty-state action
lib/features/invoices/presentation/widgets/invoice_lines_section.dart
                                                    money columns fixed-width, leading-aligned
lib/features/settings/... (c2)                      unchanged in (d)
```

- **Three genuinely different layouts, and the desktop one was decided by a measurement** (D-053).
  §10 asks desktop for a sticky summary panel down the side; a 320-pixel panel leaves 616 logical
  pixels for a four-column table with two money columns, and the amounts overflowed by **58**. The
  width goes to the table, and the summary splits by purpose — **breakdown** beside the fields
  (scrolls), **decision** pinned (grand total + both actions). Mobile is one column with a pinned
  bar; tablet is two panes.
- **Two D-037 deviations in (b)'s table, corrected**: its money columns were `flex` and `alignEnd`.
  Invisible while that table had a page to itself. **The general lesson: a widget tested only at its
  own full width has not been tested at the width it is composed into.**
- **The summary is the reconciliation equation rendered**, starting from `grossTotal` (D-047) so it
  adds up by hand. The screen computes nothing.
- **An empty state for the summary**, not a column of zeros — those read as a fault.
- **Draft and issue are visibly different.** Tonal vs filled; a note under the draft saying what it
  does *not* do; a confirmation for issue naming **both** irreversible consequences (the number, and
  the end of editability) and restating the amount. A test asserts the copy contains «شماره» and
  «ویرایش». **Declining writes nothing at all** — not even the draft `issue()` saves first.
- **Leaving asks when there is something to lose** (`PopScope`), on a customer or a line, never on
  the dates a fresh form already has. Not in the brief; recorded in D-053 as a judgement call.
- **17 new tests; 693 pass.** Decision recorded: **D-053**.

### What the device pass showed, on the Redmi Note 8 Pro

`integration_test/invoice_form_device_test.dart` drives the whole form through the **real sheets** at
the device's own metrics, and **collects every layout overflow** rather than letting Flutter print a
red band and carry on.

```
logical size: 392.7 x 803.6   pixel ratio 2.75   16sp renders at 16.0
customer: picked through the sheet's search, typed «مريم» with the Arabic ي
add-line at: 400 px down     <- the finding
line: added at quantity ۲٫۵ through the numeric sheet
issue date: picked from the Jalali grid
issued: INV-1405-0001   party snapshot written
grand total: 34,375,000 rial = 31,250,000 + 10%, reconciled by hand
layout errors : 0
```

**The one finding: the buttons that add a line are 400 logical pixels down.** The invoice-level
fields fill the first viewport of a 393 × 804 phone, so the first thing a user wants to do — say what
is being billed — is below the fold. Not changed unilaterally: the field order is the order the
document reads in. **It is the owner's call.**

**What that pass cannot do:** synthetic taps never miss, never hesitate, and never try the thing
nobody designed for. It proves the flow works and the layout holds at real metrics in Vazirmatn. It
does not prove the form is pleasant to use with a thumb — which is why the owner's own pass is the
outstanding item.

## What Phase 4 increment (c2) delivered — the party snapshot, and schema v3

**The project's second migration.** Five nullable `customer_*_snapshot` columns on `invoices`, and
`payment_term_days` on `settings`, in one migration at the owner's direction.

```
lib/data/database/tables/invoices.dart        + 5 snapshot columns
lib/data/database/tables/settings.dart        + paymentTermDays
lib/data/database/app_database.dart           schemaVersion 3; migrateV2ToV3; _addColumnIfAbsent;
                                              the v1 rebuild now computes its newColumns
lib/data/models/customer_snapshot.dart        NEW  the value type
lib/data/models/invoice.dart                  + customerSnapshot, party(), partyName()
lib/data/models/invoice_list_item.dart        customerName is now a GETTER; liveCustomerName is the field
lib/data/models/invoice_detail.dart           + party
lib/data/models/app_settings.dart             + paymentTermDays, kDefaultPaymentTermDays
lib/data/repositories/drift/drift_invoice_repository.dart   issue() and create() write the snapshot
lib/features/invoices/domain/invoice_editor_state.dart      defaultDueDate takes the term
lib/features/invoices/application/invoice_editor.dart       a derived due date follows the term too
lib/features/settings/presentation/settings_screen.dart     + the term row; _SettingRow is a Wrap now
```

- **At `issue()`, not at draft creation**, inside the transaction that allocates the number. A draft
  is not a document and should pick up a correction; an issued invoice must not. `create(status:)`
  snapshots too, being a second route to a document.
- **Name, company, کد ملی, کد اقتصادی, address. Not the mobile** — contact detail, not document
  content, and it keeps resolving live.
- **The fallback is written in exactly one place.** `Invoice.party(live)` / `Invoice.partyName(name)`;
  `InvoiceDetail.party` and `InvoiceListItem.customerName` are getters over them.
  `InvoiceListItem`'s constructor argument was renamed `liveCustomerName` so the two construction
  sites cannot apply — or forget — the rule.
- **Invoices issued before v3 show the live customer, deliberately, and nothing is backfilled.**
  Backfilling from today's rows would look like a snapshot while being the live join it replaces,
  frozen at a moment matching no document. Two tests pin it. For those invoices the defect is still
  present and cannot be fixed; there is no history to recover.
- **`assertForeignKeysCanBeDisabled` is NOT called by this step, and that is deliberate** (D-052).
  It checks that `PRAGMA foreign_keys = OFF` takes effect, which a rebuild needs and six
  `ADD COLUMN`s do not. Calling it anyway would make it a ritual rather than a check. Instead the
  step is **run inside a transaction** with foreign keys on and children present — the exact
  condition that empties the children under the v1 → v2 rebuild — and the rows are counted.
- **Writing the v1 → v3 test found a real defect in the shipped v1 → v2 migration.**
  `Migrator.alterTable` builds from the **current** declaration and copies every one of those
  columns out of the old table, so declaring the v3 columns broke it with `no such column`, on open,
  for every user still on v1 and nobody else. Fixed structurally: the rebuild computes its
  `newColumns` by asking the old table what it has, so no future column needs an edit there; and the
  v2 → v3 step adds each column only if absent.
- **The payment term is a setting.** `defaultDueDate(issueDate, termDays)`; a **derived** due date now
  follows a change to the term as well as to the issue date. A chosen one is moved by neither.
- **A pre-existing settings-screen overflow, found and fixed.** Its first-ever widget test caught
  `_SettingRow` overflowing by **132 logical pixels** at phone width — the backup row renders a
  *sentence* in the figure style, and that group took its natural width before the label. Now a
  `Wrap`: identical while both halves fit, value on its own line when they do not.
- **24 new tests; 676 pass** (was 650). Decision recorded: **D-052**.

## What Phase 4 increment (c) delivered — the invoice-level fields, and the save

**The first write of a whole invoice from the editor.** Still no route: (d) assembles the screen.

```
lib/core/widgets/jalali_date_picker.dart                    NEW - the calendar and the field
lib/features/invoices/presentation/widgets/invoice_details_section.dart
lib/features/invoices/presentation/widgets/customer_picker_sheet.dart
lib/features/invoices/application/invoice_customer_picker.dart
lib/features/invoices/application/invoice_editor.dart       + save(), issue()
```

- **The preview/write pin now covers the invoice, not only the lines.**
  `invoice_preview_matches_write_test.dart` asserts customer, issue date, due date, invoice tax rate,
  the entered discount percentage and notes round-trip alongside every figure — 14 tests, was 8. A
  total that survives while the date it was issued on does not is still a wrong document.
- **`save()` writes a draft and `issue()` allocates the number**, in that order and in the
  repository's own transactions (D-013, D-048). A failure between them leaves a saved draft with no
  number, which is recoverable; the opposite arrangement would spend a number on nothing.
- **Only drafts are editable, and the test proves the rule is the repository's.** A new test calls
  the repository **directly** — as a deep link, a second screen or a future sync path would — and
  asserts `updateDraft` and `softDeleteDraft` refuse in **every** non-draft status: unpaid,
  partiallyPaid, paid and cancelled, each reached by its own route. It also asserts the refusal left
  nothing behind: same status, same total, same number, same line. A guard that throws after writing
  half the change is worse than no guard.
- **Customer selection is the repository's search**, not a parallel one. The picker's own list-query
  provider feeds `watchSearch`, which folds the term through `searchKey` (D-025, D-029) — «علي»
  finds «علی». A test asserts the raw term reaches the repository *unfolded by the widget*, which is
  what would break if someone filtered a loaded list here instead.
- **A Jalali date picker, built rather than added.** Material's is a Gregorian grid; localizing it
  gives Persian digits over Gregorian month boundaries. `shamsi_date` was already a dependency and
  what was missing was a grid, so **no new dependency**. The week starts on Saturday, and a test
  pins that day 1 lands under its `Jalali.weekDay` column and *not* where `DateTime.weekday` would
  have put it — the two disagree, and the wrong one still looks like a calendar.
- **Both dates leave as UTC instants** — `startOfJalaliDayUtc`, local midnight in Tehran (D-005) —
  and the due date's picker cannot select a day before the issue date at all, rather than validating
  after the fact.
- **A derived due date moves with the issue date; a chosen one does not.** `dueDateFollowsIssueDate`
  is what tells them apart, because a date thirty days out looks identical either way. Without it
  the editor has to pick one wrong behaviour: a document due before it was issued, or a date the
  user deliberately set being dragged.
- **`0` and inherit stay apart at the invoice level too** (D-026), in the same mode-plus-value shape
  the line sheet uses, with the settings default named rather than left implicit.
- **A failed write returns null, never an exception at the widget** (§7), logged through the wrapper.
- **31 new tests**; 650 pass, was 619.

**Two gaps recorded rather than papered over (D-051):**

1. **An issued invoice does not snapshot its customer.** It should — renaming a customer today
   silently rewrites the name on every invoice ever issued to them, which is D-004's failure applied
   to the party rather than the price. It needs five columns and `schemaVersion = 3`, so it is
   **increment (c2)**, on (a2)'s precedent that a migration is its own reviewable step.
2. **The payment term is a 30-day constant, not a setting.** It belongs in `settings` beside the VAT
   rate; that is the same kind of schema change. A gap, not a decision.

## What Phase 4 increment (b) delivered — line item entry

**Three widgets and a limits constant.** No screen, no route, no `save` — the lines section is
composed into a form in (d).

```
lib/features/invoices/presentation/widgets/product_picker_sheet.dart
lib/features/invoices/presentation/widgets/invoice_line_editor_sheet.dart
lib/features/invoices/presentation/widgets/invoice_lines_section.dart
lib/features/invoices/application/invoice_product_picker.dart
```

- **The picker returns a `Product` and nothing else.** Building the line from it happens in one
  place, so there is exactly one site performing the copy D-004 requires. A picker that returned a
  half-built line would be a second such site, and the two would eventually disagree about what a
  snapshot contains. Picking opens the line sheet pre-filled rather than adding a line directly —
  reasoning in D-050.
- **The per-line tax control is a mode plus a value**, so `0` and *inherit* stay different states
  all the way from the widget (D-026). Under *inherit* the sheet shows the rate the engine resolved,
  read off `CalculatedLine.resolvedTaxRateBp` — the widget resolves nothing, and where there is no
  calculated line to read it says nothing rather than guessing.
- **Quantity goes through `tryParseScaledInput(scale: 1000)`.** No `double` at any point. A fourth
  decimal place is **refused with its own message**, not truncated, because "invalid" would leave
  the user retyping the same value. The percent fields use the same parser at `scale: 100`, which
  *is* basis points: `9.5% → 950`, exactly.
- **Every figure on a row is the engine's**, including the discount — which is the one **applied**,
  `CalculatedLine.discount`, never the one entered (§4 step 9). Where the two differ, D-027's
  warnings render beneath, naming both.
- **`InvoiceLimits` in `field_limits.dart`** (title 200, unit 30), matching the columns. The
  relationship that matters is asserted rather than assumed: every `ProductLimits` value is at or
  below its line counterpart, so copying a product in can never overflow the line.
- **Cards on mobile and tablet, a real table on desktop** (§10), reusing `AppCard` and `AppTable`.
  Reordering is two buttons rather than a drag, disabled at the ends rather than hidden (D-050).
- **13 new tests**, over the real controller and engine with a faked repository, at both tiers.
  They found one real defect: the warnings heading overflowed its row at the phone width, which is
  why the harness pins a size.
- **(b) added no `save`** — deliberately, since the customer and the dates a save needs are entered
  in (c), which is where `save()` and `issue()` landed.

## What Phase 4 increment (a3) delivered — the cascade defect, made structural

**No UI, no schema change.** One guard, one comment, four tests. It exists because of the finding in
(a2): wrapping `alterTable` in a transaction destroys every invoice line and every payment in the
database, and five of the six tests over that migration stay green, because only the children die.
A comment and a minority of the test suite are not enough for a defect that shape (D-049).

- **`assertForeignKeysCanBeDisabled(db)`** runs before `alterTable` and aborts the migration if the
  connection cannot actually turn foreign keys off. **It is not a heuristic for "am I in a
  transaction".** It performs the exact operation `alterTable` depends on and reads the result back:
  outside a transaction the pragma takes effect and reads `0`; inside one SQLite ignores the write,
  raises nothing, and it still reads `1`. That difference *is* the bug, observed rather than
  inferred — so it catches an explicit `db.transaction`, a batch, and a future drift that starts
  running `onUpgrade` inside a transaction, none of which a source scan could see.
- **Verified to bite.** Wrapping the real migration in `db.transaction` now fails the data-survival
  test at the guard with a message naming the cascade, instead of passing five tests of six with an
  emptied `invoice_items`. The wrapper was removed afterwards.
- **The comment is at the call site, not only in `DECISIONS.md`**, because the person who would make
  that change is reading that line. It opens `DO NOT WRAP THIS FUNCTION, OR THE CALL BELOW, IN A
  TRANSACTION` and spells out the consequence in rows, not in mechanism.
- **Four tests** in `invoice_number_migration_test.dart`: the guard passes on a real connection and
  restores it unchanged; it throws inside a transaction; the **premise** is pinned (the pragma is
  silently ignored inside a transaction — if a future SQLite changes that, this is where the news
  arrives); and the **data loss itself is performed and measured**, a `DROP TABLE invoices` inside a
  transaction emptying `invoice_items` and `payments` with no error raised.
- **A source-scanning guard was considered and rejected**, though it would have matched the project's
  other nine. It would have to recognise "lexically inside a transaction block" from Dart source with
  a regex — blind to a transaction opened by a caller, and prone to misfire on an unrelated nearby
  `transaction(`. The runtime check is strictly stronger with no false positives. Reasoning in D-049.
- **It is named for what it checks, not for this migration, and it is public.** Every future
  migration that rebuilds a table with children must call it; public is what lets a test call it
  from inside a transaction and watch it refuse.

## What Phase 4 increment (a2) delivered — the first migration

**No UI.** A schema change, a behaviour change, and the tests that make both safe.

- **A draft has no number.** `create` allocates nothing for a draft; `issue()` allocates inside its
  own transaction, against the Jalali year of the **invoice's** issue date. `schemaVersion = 2`,
  with `number`, `number_year` and `number_sequence` nullable.
- **`onUpgrade` is a real ladder now**, not a throw — `if (from < 2)`, with a fail-loud default for
  an uncovered pair. Known issue 1 is closed and so is known issue 17.
- **The one thing to know before touching this migration.** It is a 12-step table rebuild whose step
  6 is `DROP TABLE invoices`. With foreign keys on, that cascades and deletes **every**
  `invoice_items` and `payments` row in the database. `Migrator.alterTable` prevents it by turning
  foreign keys off *outside* its own transaction, which only works because drift runs `onUpgrade`
  outside one. **Wrapping the `alterTable` call in `db.transaction` — which looks like a safety
  improvement — reproduces the data loss**, because SQLite silently ignores `PRAGMA foreign_keys`
  inside a transaction. Verified by doing it: `invoice_items` went to zero while the
  schema-comparison test and the numbers test both still passed.
- **Two test suites, two different claims.** `SchemaVerifier` proves the migrated *shape* matches
  the declared v2 schema; a second suite proves the *data* survives, through `openAppDatabase` on a
  real encrypted file with foreign keys on. `SchemaVerifier.testWithDataIntegrity` is deliberately
  not used — it disables foreign keys, which is the exact condition under which the bug hides.
- **A device proof exists and is repeatable**, on D-020's precedent:
  `integration_test/invoice_number_migration_proof_test.dart`. **Passes on Windows and on the
  Redmi** (2026-08-26).
- **Ordering is now total**: `issueDate DESC, numberSequence DESC NULLS FIRST, createdAt DESC,
  id DESC`. A draft sorts above the invoices of its own date; the last two keys exist because
  `created_at` is milliseconds and two drafts can be written inside one.
- **One Persian string in one place.** «بدون شماره» behind `invoiceNumberLabel`
  (`features/invoices/domain/`), used by all three sites that render a number. It owns the bidi rule
  too: a real number is isolated, the Persian placeholder is not.

## What Phase 4 increment (a) delivered

**No UI.** A value type, a controller, and the tests that pin them — the arithmetic spine the three
UI increments will hang off.

- **`InvoiceEditorState`** (`features/invoices/domain/`) holds the invoice being edited and exposes
  `totals`, the `CalculatedInvoice` the engine produced. It computes nothing; every edit builds a new
  state whose constructor re-runs `calculateInvoice`, so a figure on screen cannot belong to an
  earlier version of the lines (D-046).
- **The engine is the only calculator, structurally.** `single_calculation_path_test.dart` fails the
  build on any call to `calculateInvoice` in `lib/` outside `core/money/`, the state model and the
  repository. **Verified to bite.**
- **The preview and the write are pinned against each other.**
  `invoice_preview_matches_write_test.dart` writes a previewed draft through the **real encrypted
  database** and asserts every stored figure equals the previewed one, down to each line's effective
  discount, resolved rate, net, tax and total. This is what makes "the number the user agreed to is
  the number stored" a checked property.
- **`CalculatedInvoice.grossTotal` was added to the engine** (D-047) with a second runtime invariant,
  because the summary a document prints has to add up **by hand** — and a subtotal-based one does
  not, being short by exactly the line discounts.
- **D-027's warnings have their first consumer**: Persian copy naming both figures, requested and
  applied, with a 1-based line number.
- **`InvoiceEditor`** watches `appSettingsProvider` rather than capturing it, so the tax default and
  rounding unit follow a settings change mid-edit.

### The surface increment (b) builds on

Four files, all documented in place — read them rather than re-deriving the design:

```
lib/features/invoices/domain/invoice_editor_state.dart      InvoiceEditorState, InvoiceLineEntry
lib/features/invoices/domain/invoice_warning_message.dart   invoiceWarningMessage(s)
lib/features/invoices/application/invoice_editor.dart       InvoiceEditor (family, keyed by openedAt)
lib/core/money/invoice_calculator.dart                      the engine; grossTotal is new
```

The controller's intents: `selectCustomer`, `setIssueDate`, `setDueDate`, `setNotes`,
`setDiscountAmount`, `setDiscountPercent`, `setTaxRate`, and for lines `addLine`, `replaceLine`,
`updateLine`, `removeLine`, `moveLine`.

**`save()` and `issue()` were added in (c)** and are documented in that section above. They were
absent through (a) and (b) for a reason worth keeping: a `save` built on the old `create()` would
have allocated a number for every draft, which is the defect D-048 named. (a2) removed that blocker
by making `create()` safe to call for a draft.

## What Phase 2 and Phase 3 delivered

**The customer detail screen, `/customers/:id`** (D-044). The record, two per-customer totals, and
that customer's invoices, composed into **one** `CustomerDetailView` so the page has one loading
state, one error state and one moment — the same reason `DashboardSummary` is one value.

- **Both totals are one SQL statement**, using `FILTER` over two different populations: billed
  (issued only, D-039) and outstanding (`grandTotal − payments`, via the same correlated subquery
  `watchOutstandingRial` uses). `FILTER` needs SQLite 3.30; this ships 3.53.4, and it was exercised
  on the real Windows build, not only against a fake.
- **`watchForCustomer` is the call site it was built for** in increment (d). The customer name on
  each row is the one already loaded, not a lookup per row.
- **`InvoiceCard` / `InvoiceTableRow` gained `showCustomer`** (default true). False here: the name
  would be identical on every row of that customer's own page, and it was displacing the invoice
  number, which is what identifies the row.
- **The record card is collapsed by default on a phone** and open on desktop. Its height has no
  upper bound — notes run to 2000 characters — so open above the list it can push the invoice list
  off the page, and below the list it would be past however many invoices the customer has.
- Invoice rows **stay non-tappable**, asserted by a test, until `/invoices/:id` exists in Phase 5.
- Empty fields say «ثبت نشده» rather than being hidden; D-030 holds on display as well as on entry.

**Field-level limits at the form boundary** (D-043) — §7's requirement, named in Phase 1 and not
built. One source of truth in `data/models/field_limits.dart`; `AppTextField` with a **required**
`maxLength`; two guards; digits-only on the ID and price fields; and a length validator in drift's
own unit because `maxLength` counts grapheme clusters and drift counts UTF-16 code units.

## Three things found by building Phases 2 and 3, worth not rediscovering

1. **`withLength(max: SomeConstant)` silently produces a column with no length limit.** `drift_dev`
   reads that argument with `readIntLiteral`, which returns `null` for anything but an integer
   literal — so the obvious way to share the constant between the schema and the forms makes the
   schema *weaker*, with no error from `build_runner`. Verified by doing it and diffing the
   generated code. The tables therefore keep their literals and
   `test/data/database/field_limits_test.dart` asks each column where it actually starts refusing.
   **Confirmed to bite** (D-043).
2. **Deleting from a list row threw `UnmountedRefException`** — a defect that shipped in (f1).
   Nothing on a list screen watches the editor controller, so the auto-disposed provider was
   collected during the await and the state write after it failed, *after* the delete had happened.
   Only the form exercised that path, and the form watches the controller, which is why it survived.
   Fixed with a scoped `ref.keepAlive()` around each write; both list delete paths now have tests
   (D-045).
3. **The logging guard was verified to cover the new screen** rather than assumed to. A plausible
   `AppLog.debug` interpolating `fullName`, `nationalId` and `mobile`, wrapped across lines as the
   formatter leaves it, was introduced and `logging_path_test.dart` failed on all three accessors by
   name. Reverted.

## What the Windows run proved, beyond the tests

The detail screen was rendered on the real build against the real encrypted database, at desktop and
phone widths in both themes, and **the figures were reconciled by hand**: a customer with a
55,000,000 draft and a 21,230,000 partially-paid invoice showed مجموع فاکتورهای صادرشده =
۲۱٬۲۳۰٬۰۰۰ (the draft excluded, as the caption says) and مانده دریافتنی = ۱۵٬۲۳۰٬۰۰۰ (that invoice
less the 6,000,000 already paid). The throwaway probe used to do it was **deleted after use**, as
(f2)'s seeding script was — it depended on the Windows dev database holding the demo rows, which is
machine-specific state rather than a fixture.

## Commands that matter

```sh
# The gate. Both must be clean before any phase is marked COMPLETED.
flutter analyze
flutter test

# Regenerate after touching a table, an @riverpod provider, or the ARB.
# --offline when the pub mirror is down; sanitize LAST or the next resolve hangs.
dart pub get --offline
dart run build_runner build
flutter gen-l10n
sh tools/sanitize_lockfile

# The only reliable way to get a window on Windows (known issue 9).
flutter run -d windows --debug

# The encryption proof, on the real target.
flutter test integration_test/d020_encryption_proof_test.dart -d windows

# The device passes (D-057, D-062). They run on whichever target they are given;
# on Windows that is the desktop tier and there is no soft keyboard, so the
# keyboard assertions degrade to "the action is on screen". The phone run is
# the one that proves them.
flutter test integration_test/invoice_detail_device_test.dart -d dmbyayb6rombo7ci
flutter test integration_test/invoice_form_device_test.dart   -d dmbyayb6rombo7ci
flutter test integration_test/d020_encryption_proof_test.dart -d dmbyayb6rombo7ci
flutter test integration_test/startup_test.dart               -d dmbyayb6rombo7ci

# adb is NOT on PATH, and Git Bash mangles device-side paths without the prefix.
ADB=%LOCALAPPDATA%/Android/Sdk/platform-tools/adb.exe
"$ADB" devices -l
MSYS_NO_PATHCONV=1 "$ADB" -s dmbyayb6rombo7ci shell "df -h /data"

# Known issue 10, when `flutter test -d` is refused with
# INSTALL_FAILED_USER_RESTRICTED. It recurs intermittently -- twice on
# 2026-09-01, after three clean installs. Do this once, then retry the test.
flutter build apk --debug
MSYS_NO_PATHCONV=1 "$ADB" -s dmbyayb6rombo7ci install -r build/app/outputs/flutter-apk/app-debug.apk
```

**Run `dart run build_runner build` from PowerShell, not from a POSIX shell wrapper.** Learned in
Phase 5 (b): invoked through the agent's Bash tool it sat at ~0.2 s of CPU indefinitely, twice, and had
to be killed with `Stop-Process`; the same command from PowerShell in the project directory completed
in 40 s. If a build appears hung, check for orphaned `dart.exe` processes and remove
`.dart_tool/build/lock/build_runner.lock` before retrying.

**To see a screen with data in it:** the Windows dev database holds twelve demo invoices and twelve
customers, all at small amounts — which is exactly the trap D-057 exists for, so never judge a money
layout against it. Invoices can now be created through the UI, and a throwaway `integration_test/`
script through the **real repositories** is still the way to seed a specific case (never raw inserts,
or the totals and numbers would not be the ones the app produces). Such a script can also render a
screen to a PNG via `RepaintBoundary.toImage()`, which is how Phase 2 was looked at; delete it after
use. `integration_test/invoice_detail_device_test.dart` is a worked example of seeding through the
repositories and driving the real sheets.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | ~~`onUpgrade` throws by design~~ | **Resolved in (a2)**: `schemaVersion = 2` with a real ladder and two migration test suites. Append steps; never edit one that shipped. |
| 2 | The database opens on the main isolate | Phase 13. The `setup` closure must stay isolate-sendable — `ARCHITECTURE.md` §B.5. |
| 3 | The national-ID checksum cannot catch every transposition | Official algorithm, not a defect. Now enforced by test over the ARB, the form **and** the detail screen. |
| 4 | `watchDetail` re-reads on any invoice-table change | Correct but not minimal. Revisit in Phase 13. |
| 6 | Settings is read-only, and its last-backup row would render an epoch number | `formatJalaliDateLong` exists; wire it when settings becomes editable. Currently unreachable — `lastBackupAt` is always null. **When the screen becomes editable, `payment_term_days` needs a bound**: a negative term produces an invoice due before it was issued, and `AppSettings` deliberately does not clamp it (D-052). |
| 8 | `nowProvider` does not tick | Deliberate (D-041). A Jalali month boundary or a due date crossing midnight while the app sits open does not update until relaunch. |
| 9 | The Windows debug exe shows no window when launched **directly** | Under `flutter run -d windows` it is fine. Worth a look in Phase 12. |
| 10b | ~~The Redmi ran out of internal storage~~ | Seen 2026-08-27 after three integration runs: `Requested internal only, but not enough space`, and the follow-up uninstall failed `DELETE_FAILED_INTERNAL_ERROR`. The D-020 and startup proofs could not be re-run because of it. **Cleared 2026-09-01** — 4.9 GB free, three installs and both blocked proofs ran. Kept as history: it is currently absent rather than fixed. |
| 10 | MIUI re-blocks `flutter test`'s install with `INSTALL_FAILED_USER_RESTRICTED` | **Intermittent, not deterministic** — on 2026-09-01 it recurred **twice** after three clean installs in the same session, on an app already installed, so it is not only a *fresh*-install problem as previously recorded. Remedy: `flutter build apk --debug`, then `adb -s <id> install -r <apk>` **by hand** once, then retry. The second time even the manual install was refused and `flutter test -d <id>` went through on the next attempt — so **retrying is part of the remedy**, not a sign it has failed. It may also report `INSTALL_FAILED_INSUFFICIENT_STORAGE` and recover itself by uninstalling first; that is not a failure either. |
| 11 | **The pub mirror can go unreachable mid-session** | `dart pub get --offline` resolves from the local cache. Sanitize the lockfile **last** — every `pub get` rewrites all 123 `url:` entries to the Tsinghua mirror, and they must be put back to `https://pub.dev` before committing. (a2) also picked up a transitive `dart_style` 3.1.12 → 3.1.13 bump that way; it is committed deliberately, because pinning the lockfile to a version that is not installed would make it lie, and `dart format` output is unchanged under it. |
| 12 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 13 | Release builds signed with debug keys | Phase 15. |
| 14 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12. |
| 15 | Android manifest hardening not done | Phase 9. |
| 18 | ~~The desktop summary panel's grand total overflows at any realistic amount~~ | **Resolved in (b)** (D-058). The grand total is `AmountSize.medium` on every tier: `large` needs 376 logical pixels and `detailPanelWidth` leaves 288. The audit that came with it found `tablePriceWidth` wrong too, and `money_layout_test.dart` now sweeps every fixed-width money site over the whole ladder. |
| 16 | ~~The customer detail screen loads every one of a customer's invoices~~ | **Resolved in (e)** (D-063). `watchForCustomer` takes a page like every sibling, driven by a per-customer `ListQuery` family so a second customer's page does not inherit the first's scroll; `CustomerDetailView` carries `hasMoreInvoices` in the same value as the rows. Paging it is only safe because the totals above are one SQL aggregate over **every** invoice rather than a sum of the page (D-044) — which now has a test of its own. |
| 17 | ~~Creating a draft allocates an invoice number~~ | **Resolved in (a2)** per D-048. A draft carries no number; `issue()` allocates. Covered by the regression test `an abandoned draft does not consume a number`. |
| 19 | ~~A large invoice with an invoice-level percentage discount breaks the invoice form as it is typed~~ | **Resolved 2026-09-01** (D-059), before (c), at the owner's direction. §4 step 4 was the only place in the engine multiplying **two amounts** together — an invoice discount by a line's net — so the product was quadratic in the invoice total and passed 2⁵³ at roughly 30 million تومان with a 10% discount. `mulDivFloor` computes that one intermediate in `BigInt` and returns quotient and remainder together; the guard is untouched and VM/Web parity is unchanged. Pinned over the whole D-057 ladder in the allocation, the engine and the editor preview, plus the exact old boundary, and verified to bite against the old implementation. |
| 20 | ~~Cancelling an invoice leaves its recorded payments untouched, and nothing says so~~ | **Resolved in (d)** (D-061), by a ruling rather than a code change. A cancelled invoice **keeps** its payments: the money changed hands, and a cancellation is a statement about the claim rather than about the cash. What changed is that it is now said — in the confirmation before the commitment, on the page afterwards (both the payments card and «مانده»), and at the early return in `_recomputeStatus` that decides it. Recording against a cancelled invoice stays refused and the copy names the replacement invoice as the way forward; deleting stays allowed, with its own wording, because a mis-entered receipt must be correctable on a void document too. |
| 21 | ~~The payment sheet's «ذخیره» starts below the fold on a phone~~ | **Resolved 2026-09-01** at the owner's direction (D-062). The shape is now a primitive, `core/widgets/editor_sheet.dart`: fields scroll, the primary action is pinned above the keyboard — D-053's split-by-purpose applied to sheets. The line editor moved onto it unchanged; the **picker** sheets are deliberately outside it, since they commit by tapping a row. On the Redmi the action now sits at **532.7 against a limit of 548.7**, was 618.6. Guarded at both levels: `sheet_keyboard_test.dart` at the measured 255-pixel inset (verified to bite), and the device pass, which now raises the real keyboard and refuses a vacuous assertion on Android. |

(5 and 7 were resolved in (f2) and have been dropped.)

## Important context for a future session

- **A payment's rules are the repository's, and the screen only explains them.** `acceptsPayments` is
  false for a draft and a cancelled invoice and `PaymentNotAccepted` is what enforces it; the detail
  screen hides the control and says why. Any test of a refusal calls the **repository directly** and
  asserts what the refusal *left behind* — a guard that throws after writing half the change is worse
  than no guard (D-060, on Phase 4 (c)'s precedent).
- **Recording and deleting a payment both recompute the derived status in the same transaction** (§6),
  and the detail screen's badge follows the row through `invoiceDetailProvider`. **Nothing on a screen
  may derive a status at display time** — that is how a badge comes to contradict the payments listed
  under it. The deletion warning is a claim about what the user is about to cause, not a second
  derivation.
- **A card whose height has no upper bound does not belong above the thing the page exists to show.**
  D-044 found it on the customer record card, (b) on the party card, (c) on the payments card — which
  costs 182 logical pixels empty. On a phone the primary action moves to `PageBody.floatingAction` and
  the inline one is omitted, so each tier offers it exactly once. **This is now a rule in the project spec with all three instances named**, and (d) is the first increment it applied to: cancellation went
  into the title row's menu, which costs no height at any tier, instead of becoming the fourth
  instance. If it must be reachable without scrolling, put it where it costs no height — the title
  row, or the floating slot.
- **Cancelling an invoice keeps every payment recorded against it** (D-061), and the screen says so in
  the confirmation, on the payments card and beside «مانده». `_recomputeStatus`'s early return for
  `cancelled` is that ruling, not an oversight. **Recording** against a cancelled invoice is refused
  and the copy points at the replacement invoice; **deleting** stays allowed with its own wording,
  because a mis-entered receipt must be correctable whether or not the document still stands.
- **A list filter is a value the repository turns into SQL** (D-063). `InvoiceFilter` goes to
  `watchList`; nothing on the path may narrow a loaded list, because the `LIMIT` is applied first and
  the page would then be of the wrong set. The window and the filter are **one value**
  (`InvoiceQuery`), so narrowing resets the page and widening keeps the predicate.
- **«سررسید گذشته» is not a filter and must not become one** without making the SQL predicate and
  `invoiceStatusViewOf` agree by test. It is derived at display time from one clock instant (D-041);
  two implementations of it end with a badge the filter does not return. Overdue invoices are
  reachable under «پرداخت نشده» and «پرداخت جزئی».
- **Calendar arithmetic never happens at a call site.** `jalaliMonthShifted` is why «ماه گذشته» is
  right in every month: stepping back thirty days from the last day of a 31-day Jalali month lands in
  the same month. If a period helper is missing, add it to `core/date/` rather than doing it inline —
  the token scanner will catch the `Duration` literal, but only by accident.
- **Every editing sheet goes through `EditorSheet`** (D-062, known issue 21): fields scroll, the
  commit action is pinned above the keyboard. The **picker** sheets are exempt by design — they commit
  by tapping a row — but the rule still applies to them in its own form, and their search field is
  asserted to stay above the keyboard. `EmptyState` scrolls rather than overflowing, because the
  picker's did, by 24 pixels, with a keyboard up.
- **The widget-test harness erases the keyboard by default.** `pumpScreen` installs its own
  `MediaQueryData`; pass `viewInsets` to test a sheet in the state a phone opens it in. Every test in
  this project ran without a keyboard until (e)'s sweep.
- **Only an issued invoice may be cancelled** — `InvoiceNotCancellable`, checked in the same
  transaction as the write. A draft is withdrawn with `softDeleteDraft`; an invoice already cancelled
  has nothing left to cancel. The screen offers the menu only where `Invoice.isCancellable`, and never
  offers a draft two ways out of one state.
- **A phase closes only after its layout check has run at all three tiers, over the written ladder in
  `test/support/money_magnitudes.dart`** (D-057). Never take the amounts from whatever
  the dev database holds: a panel that fits at 100,000 تومان and breaks at 1,000,000 hides behind small
  test data, and that is exactly how known issue 18 survived a phase close. A **measurement is not a
  check** — write the widget test.
- **A money width is magnitude-dependent, and the widths are named.**
  `AppLayout.amountWidthSmall / Medium / Large` (232 / 276 / 376) are the measured widths each
  `AmountSize` needs at the ladder's ceiling; `tablePriceWidth` is **derived** from the small one plus
  the cell padding `AppTableRow` spends. **A container that cannot give an amount the width its size
  needs takes a smaller size, never a clipped figure.** `money_layout_test.dart` is where a new
  fixed-width money site joins the sweep. The one exception is `StatTile`, which scales in a
  `FittedBox` — a tile is a headline, not a column to align down.
- **The party on the detail screen is `InvoiceDetail.party`, and `InvoicePartyProvenance` decides what
  to say about it** (D-052, D-058). Four cases and **one of them is silence**: explaining on every
  invoice would train the user to skip the explanation on the one that matters. The comparison is over
  the whole snapshot, not the name. `InvoiceDetail.customerIsDeleted` is a separate, stacking fact,
  set by the repository because the customer behind an invoice is read soft-delete-exempt.
- **Nothing on a read path may compute a document figure.** The detail screen renders stored columns
  only — not `unitPrice × quantity`, not the sum of two deductions. A read site that multiplied would
  apply today's rounding rule to yesterday's document, somewhere `single_calculation_path_test.dart`
  cannot see, because it never calls the engine.
- **The eight-column document line does not fit on a screen** (D-058): six money columns at
  `tablePriceWidth` is 1464 logical pixels against the 1144 a desktop content column has. Five columns
  plus labelled detail lines is the shape; the eight-column layout is Phase 7's, on a page.
- **The cipher pragmas come BEFORE `pragma key`** (D-020). Never assert encryption with
  `PRAGMA cipher_version` or `PRAGMA cipher` — assert on the file header.
- **A drift `alterTable` migration must NOT be wrapped in a transaction.** It turns foreign keys off
  around its `DROP TABLE`, and SQLite silently ignores `PRAGMA foreign_keys` inside a transaction —
  so wrapping it cascade-deletes every `invoice_items` and `payments` row in the database, with no
  error. Measured, not reasoned about (D-048). The same applies to any future table rebuild.
- **`Migrator.alterTable` builds from the table as declared TODAY**, then copies every one of those
  columns out of the old table — so adding a column to `invoices` breaks the *shipped* v1 → v2
  rebuild with `no such column`, on open, for every user still on v1 and nobody else. It is handled
  structurally (the rebuild computes its `newColumns` from `PRAGMA table_info`), and the **v1 → v3
  test through the production path is what proves it**. Keep that test pointed at
  `db.schemaVersion`, never at a literal (D-052).
- **A migration made only of `ADD COLUMN` must NOT call `assertForeignKeysCanBeDisabled`.** The guard
  checks a precondition a rebuild has and `ADD COLUMN` does not; calling it anyway turns it into a
  ritual. The equivalent check for such a step is to run it inside a transaction with children
  present and count them, which `customer_snapshot_migration_test.dart` does (D-052).
- **The party on a document is `Invoice.party(live)` / `Invoice.partyName(name)`, never
  `detail.customer`.** `detail.customer` is the live record — contact detail and where a "go to
  customer" action leads. `InvoiceListItem.customerName` is a **getter**; the constructor argument is
  `liveCustomerName` (D-052).
- **Three money columns are nullable, and null means *unknown*, not zero** (D-055, D-056):
  `Invoice.grossTotal`, `InvoiceItem.gross`, `InvoiceItem.allocatedInvoiceDiscount`. A read path
  renders «ثبت‌نشده» — `invoiceFigureUnrecorded` — never `۰`. `InvoiceSummaryFigures` is the view
  model the summary panel, the detail screen and the Phase 7 renderer all take, and it is where the
  absence is handled once.
- **The v3 → v4 backfill calls `calculateInvoice` and is a sanctioned caller** of it. It is a
  *comparison*, not a producer: it writes only what the engine reproduces from the row's own stored
  inputs, and leaves nulls otherwise. Do not "simplify" it into an open-coded multiply — that is the
  second §4 implementation D-046 exists to prevent.
- **`migrateV1ToV2` is public now**, like `migrateV2ToV3`, so a test can run the ladder one step at a
  time and read `PRAGMA table_info` between them. That is how the v1 → v4 arriving-shape asymmetry is
  observed rather than assumed.
- **A v1 database arrives at each new step carrying the columns of every later version of
  `invoices`**, because the v1 rebuild recreates that table from today's declaration — while
  `invoice_items`, `payments`, `customers`, `products` and `settings` are rebuilt by nothing and
  arrive without them. Every future step that adds a column to `invoices` needs
  `_addColumnIfAbsent`; one that adds to any other table would not, but should use it anyway.
- **The schema dumps in `drift_schemas/` are the migration tests' baseline**, and
  `test/data/database/generated/` is `drift_dev schema generate` output for them. After a schema
  change: `dart run drift_dev schema dump lib/data/database/app_database.dart drift_schemas/` then
  `dart run drift_dev schema generate --data-classes --companions drift_schemas/
  test/data/database/generated/`. Both are committed.
- **`SchemaVerifier` opens an unencrypted in-memory database and sets no pragmas**, so it needs
  `setup: (raw) => raw.execute('PRAGMA foreign_keys = ON;')` or the production `beforeOpen`
  assertion refuses the migration. Its `testWithDataIntegrity` helper **disables foreign keys** and
  therefore cannot see a cascade — do not reach for it.
- **Nine rules are enforced by tests that scan `lib/`.** If one fails, route through the helper —
  never weaken the test. Each has a documented escape-hatch comment requiring a reason:
  1. open a database only through `openEncryptedDatabase` (D-020);
  2. read rows only through `selectAlive` / `selectOnlyAlive` / `countAlive` (D-003) —
     `// soft-delete-exempt:`;
  3. normalize text only through `core/formatting/` (D-029) — `// normalizer-exempt:`;
  4. no drift import in `data/models/` or the interfaces in `data/repositories/` (D-031);
  5. no literal colour or dimension outside `core/theme/` (D-033) — `// tokens-exempt:`;
  6. no Arabic-script character in code outside `core/localization/` (D-034) — `// l10n-exempt:`;
  7. no output outside `AppLog`, and no sensitive field name inside a log call (D-035) —
     `// logging-exempt:`;
  8. **no raw text field, and no `maxLength` that is not a `*Limits.` constant** (D-043) —
     `// field-limit-exempt:`. One exemption exists: the search field, which writes to no column.
  9. **no call to `calculateInvoice` outside the engine, the editor state and the repository**
     (D-046) — `// calculation-exempt:`. A third caller is a second answer to the same question, and
     nothing would compare it against the first.
- **A field limit cannot be shared with `withLength(max:)`** — see finding 1 above. This is the one
  place in the project where the guard is a behavioural test rather than a shared reference, and the
  reason is recorded on both the constants file and the table definitions.
- **There are exactly two soft-delete exemptions on read paths, and both are the same one:** the
  customer row behind an invoice, in `watchList` and in `findDetail`. Do not "fix" them back.
- **A widget never calls a repository.** Feature `application/` folders hold the providers.
- **A write must outlive the widget that started it** (D-045): a controller method that awaits and
  then writes `state` needs `ref.keepAlive()` for the duration, or it throws when the acting widget
  does not happen to watch it.
- **`AmountText` everywhere money appears**, and a money column in a table is **leading-aligned in a
  fixed-width column**, never `alignEnd` — see D-037's RTL note.
- **Money is never accent-coloured** (D-033). Colour means status; red means overdue and nothing else.
- **`Override` is not exported by `flutter_riverpod` in 3.4.2.** It lives in
  `package:flutter_riverpod/misc.dart`. The error — *"The name 'Override' isn't a type"* — does not
  hint at it. Hit again in Phase 2.
- **`AsyncValue.valueOrNull` is gone in Riverpod 3.4.2** — the nullable accessor is `.value`, and
  `requireValue` is the throwing one. Hit in Phase 4(a).
- **An auto-disposed provider read without a listener is disposed between reads**, and a
  `ProviderContainer` test that only calls `read` will fail with *"the provider was disposed during
  loading state"* from whatever it depends on. Add a `container.listen(..., (_, _) {})`; in the app
  the watching widget is what holds it. Related to D-045 and the same underlying rule.
- **The invoice editor is a family keyed by a `DateTime`.** The screen must read the clock **once**
  and pass the same instant down; a fresh `DateTime.now()` per build addresses a different provider
  every frame and discards the invoice as it is typed.
- **Riverpod 3 wraps a provider's error in `ProviderException`** — assert on the message.
- **Private `@riverpod` providers work**, and both the dashboard summary and the customer detail
  view use them so nothing outside can watch a single figure and reintroduce "tiles from different
  moments".
- **Widget tests render with a fallback font whose glyphs are much wider than Vazirmatn's.** A
  fixed-width column that passes a widget test has margin in the shipped layout.
- **Nothing in `core/money/`, `core/date/` or `core/formatting/` may import Flutter.** The
  digits-only input formatter therefore lives in `core/widgets/` and calls `keepDigitsOnly`.
- **Where the source encoding is not guaranteed, name characters by code point.** The analyzer also
  warns on a raw bidi isolate in a Dart literal — write `⁨`, not the character.
- **Sanitize the lockfile after anything that resolves — and sanitize it LAST.**
- **Run `dart run build_runner build` after touching a table or an `@riverpod`, and
  `flutter gen-l10n` after touching the ARB**, then commit the regenerated files.

## Recently changed files

### Phase 5 increment (e) — the newest work

```
lib/data/models/invoice_filter.dart                      NEW  the value handed to the query
lib/features/invoices/domain/invoice_query.dart          NEW  window + filter, one value
lib/features/invoices/presentation/widgets/invoice_filter_sheet.dart  NEW  the sheet
lib/core/date/jalali_period.dart                         + jalaliMonthShifted
lib/core/widgets/empty_state.dart                        scrolls instead of overflowing
lib/data/repositories/... (interface + drift)            watchList(filter:), watchForCustomer paged
lib/features/invoices/... (providers, screen, status)    InvoiceQuery, the control, the count
lib/features/customers/... (providers, view, screen)     per-customer paging + load-more
lib/core/localization/arb/app_fa.arb                     + 16 strings
test/data/database/soft_delete_usage_test.dart           scanner narrowed, with its own test
test/core/date/jalali_period_test.dart                   + 5 for jalaliMonthShifted
test/data/repositories/invoice_repository_test.dart      + 10 for filters and paging
test/features/invoices/invoices_screen_test.dart         + 18, incl. the per-tier sweep
test/features/customers/customer_detail_screen_test.dart + 4 for paging
test/core/widgets/sheet_keyboard_test.dart               + 2: the picker and the filter sheet
```

### Known issue 21 and the keyboard rule — the boundary before it

```
lib/core/widgets/editor_sheet.dart                 NEW  fields scroll, the action is pinned
lib/features/invoices/presentation/widgets/payment_editor_sheet.dart      onto EditorSheet (the fix)
lib/features/invoices/presentation/widgets/invoice_line_editor_sheet.dart onto EditorSheet (unchanged
                                                     behaviour; so the shape has one home)
integration_test/device_assertions.dart            NEW  reach(), raiseKeyboard(),
                                                     expectActionAboveKeyboard()
integration_test/invoice_detail_device_test.dart   asserts instead of measuring; no ensureVisible
integration_test/invoice_form_device_test.dart     raises the real keyboard on the line sheet
test/features/screen_harness.dart                  + viewInsets -- the harness had erased the
                                                     keyboard for every test ever run
test/core/widgets/sheet_keyboard_test.dart         NEW  3 tests, at the measured 255 px
```

### The phone-tier device pass — the boundary before it

```
integration_test/invoice_detail_device_test.dart   + reach(); tier-blind assertions fixed;
                                                     the keyboard measured and printed
```

### Phase 5 increment (d) — the boundary before it

```
lib/features/invoices/presentation/widgets/invoice_cancel_action.dart  NEW  menu + confirmation
lib/features/invoices/application/invoice_cancellation.dart            NEW  the one write
lib/data/models/invoice.dart                             + Invoice.isCancellable
lib/data/repositories/invoice_repository.dart            + InvoiceNotCancellable; cancel() contract
lib/data/repositories/drift/drift_invoice_repository.dart  cancel() guards, in its own transaction
lib/data/repositories/drift/drift_payment_repository.dart  the early return names its ruling
lib/features/invoices/presentation/invoice_detail_screen.dart  the menu; the cancelled «مانده» note
lib/features/invoices/presentation/widgets/invoice_payments_section.dart
                                               cancelled notice; cancelled delete wording
lib/core/localization/arb/app_fa.arb           + 9 strings, 1 reworded
The project spec                                  the unbounded-card rule, three instances named
test/data/repositories/invoice_repository_test.dart      + 3 guard/ruling tests
test/features/invoices/invoice_detail_screen_test.dart   + 28 tests, incl. the 12-rung dialog sweep
test/features/invoices/fake_invoice_repository.dart      cancel() implemented, ids recorded
integration_test/invoice_detail_device_test.dart         + cancellation on the real target
```

### Phase 5 increment (c) — the boundary before it

```
lib/features/invoices/presentation/widgets/payment_editor_sheet.dart      NEW  the sheet
lib/features/invoices/presentation/widgets/invoice_payments_section.dart  NEW  list + both actions
lib/features/invoices/application/invoice_payments.dart                   NEW  record / delete
lib/features/invoices/domain/payment_method_label.dart                    NEW  the Persian mapping
lib/data/models/field_limits.dart              + PaymentLimits.note (500)
lib/features/invoices/presentation/invoice_detail_screen.dart
                                               payments card; mobile FAB; narrow-tier reorder
lib/core/localization/arb/app_fa.arb           + 24 strings
test/data/repositories/payment_repository_test.dart      + refusal aftermath, both directions
test/features/invoices/invoice_detail_screen_test.dart   + 14 payment tests, _FakePaymentRepository
integration_test/invoice_detail_device_test.dart         + record and delete on the real target
```

### Known issue 19 — the fix before (c)

```
lib/core/money/rounding.dart                 + mulDivFloor -> (quotient, remainder)
lib/core/money/discount_allocation.dart        one call replaces both wide products
test/core/money/{rounding,discount_allocation,invoice_calculator}_test.dart  the ladder + boundary
test/features/invoices/invoice_editor_state_test.dart    the ladder through the live preview
```

### Phase 5 increment (b) — the newest work

```
lib/features/invoices/presentation/invoice_detail_screen.dart          NEW  the screen
lib/features/invoices/presentation/widgets/invoice_document_lines.dart NEW  the stored line
lib/features/invoices/domain/invoice_party_view.dart                   NEW  InvoicePartyProvenance
lib/core/widgets/record_field.dart                                     NEW  promoted from customer detail
lib/core/theme/app_dimensions.dart          + amountWidthSmall/Medium/Large;
                                              tablePriceWidth = amountWidthSmall + AppSpacing.md
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart grand total -> medium
lib/features/invoices/application/invoices_providers.dart              + invoiceDetail(id)
lib/data/models/invoice_detail.dart                    + customerIsDeleted
lib/data/repositories/drift/drift_invoice_repository.dart              _detail sets it
lib/core/router/destinations.dart           + invoiceDetail, invoiceDetailFor
lib/core/router/app_router.dart             + /invoices/:id, declared AFTER `new`
lib/features/invoices/presentation/invoices_screen.dart      rows tappable, card and table
lib/features/customers/presentation/customer_detail_screen.dart  rows tappable; uses RecordField
lib/core/localization/arb/app_fa.arb        + 25 strings
test/support/money_magnitudes.dart          NEW  the ladder (D-057)
test/core/widgets/money_layout_test.dart    NEW  the sweep, 28 tests
test/features/invoices/invoice_detail_screen_test.dart  NEW  38 tests
test/features/invoices/invoice_party_view_test.dart     NEW   7 tests
test/features/screen_harness.dart           + kTabletSize, kAllTierSizes, invoice route stubs
test/features/invoices/fake_invoice_repository.dart     + details map for watchDetail
integration_test/invoice_detail_device_test.dart        NEW  the desktop device pass
The project spec                               + the three-tier layout rule (D-057)
```

### Phase 5 increment (a2) — the newest work

```
lib/data/database/tables/invoices.dart        + gross_total_rial (nullable)
lib/data/database/tables/invoice_items.dart   + line_gross_rial,
                                                allocated_invoice_discount_rial (both nullable)
lib/data/database/app_database.dart           schemaVersion 4; migrateV3ToV4;
                                              _migrateV1ToV2 -> public migrateV1ToV2
lib/data/database/invoice_figures_backfill.dart   NEW  backfillInvoiceFigures + its report
lib/core/money/money.dart                     + Money.rialOrNull
lib/data/models/invoice.dart                  + grossTotal (Money?), hasStoredGross
lib/data/models/invoice_item.dart             + gross, allocatedInvoiceDiscount (Money?)
lib/data/repositories/drift/mappers.dart      read all three
lib/data/repositories/drift/drift_invoice_repository.dart
                                              create/updateDraft/_writeItems write all three
lib/features/invoices/domain/invoice_summary_figures.dart  NEW  the shared view model
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart
                                              takes InvoiceSummaryFigures; renders «ثبت‌نشده»
lib/features/invoices/presentation/invoice_editor_screen.dart  wraps its totals in the view model
lib/core/localization/arb/app_fa.arb          + invoiceFigureUnrecorded,
                                                invoiceSummaryGrossUnrecordedNote
drift_schemas/drift_schema_v4.json            NEW  schema dump
test/data/database/generated/schema_v4.dart   NEW  drift_dev schema generate output (+ schema.dart)
test/data/database/invoice_figures_migration_test.dart     NEW  11 tests
test/data/database/invoice_figures_backfill_test.dart      NEW  12 tests
test/features/invoices/invoice_summary_figures_test.dart   NEW   7 tests
test/features/invoices/invoice_preview_matches_write_test.dart  + the three figures
test/core/money/single_calculation_path_test.dart          + the backfill, sanctioned with reasons
test/data/database/customer_snapshot_migration_test.dart   version assertions read db.schemaVersion
integration_test/invoice_figures_migration_proof_test.dart NEW  the device proof, both ladders
docs/*                                        D-056; D-054 gains the empty-state ruling; ROADMAP;
                                              known issue 18
```

### Phase 5, first boundary

```
The project spec: the constraint, not the layout; the
                                              composition rule (d) surfaced
lib/features/invoices/presentation/widgets/invoice_details_section.dart
                                              + collapsible, _expanded, _DetailsHeader
lib/features/invoices/presentation/invoice_editor_screen.dart
                                              the mobile layout passes collapsible: true
lib/core/localization/arb/app_fa.arb           +2 strings
integration_test/invoice_form_device_test.dart + the fold measurement, both ways
test/features/invoices/invoice_editor_screen_test.dart  +3 for the fold
docs/*                                        D-054, D-055; D-047 marked settled; ROADMAP phase 5
```

### Phase 4 increment (d)

```
lib/features/invoices/presentation/invoice_editor_screen.dart   NEW  the screen; the layouts;
                                                    the issue confirmation; the discard guard
lib/features/invoices/presentation/widgets/invoice_totals_summary.dart  NEW  the breakdown
lib/features/invoices/presentation/widgets/invoice_lines_section.dart
                                                    money columns -> fixed width, leading-aligned
lib/features/invoices/presentation/invoices_screen.dart   + FilledButton, FAB, empty-state action
lib/core/router/app_router.dart                     + the /invoices/new child route
lib/core/router/destinations.dart                   + AppRoutes.invoiceCreate
lib/core/localization/arb/app_fa.arb                +18 strings (433 total)
test/features/invoices/invoice_editor_screen_test.dart    NEW  16 tests, four groups
test/features/invoices/fake_invoice_repository.dart       + recording create/issue, failWrites
test/features/invoices/invoices_screen_test.dart          the empty-state test, retargeted
integration_test/invoice_form_device_test.dart      NEW  the whole form on the phone
docs/*                                              D-053; ROADMAP phase 4 closed; ARCHITECTURE
```

### Phase 4 increment (c2)

```
lib/data/database/tables/invoices.dart        + 5 customer_*_snapshot columns
lib/data/database/tables/settings.dart        + paymentTermDays (literal 30, see D-043's trap)
lib/data/database/app_database.dart           schemaVersion 3; migrateV2ToV3 (public, for the
                                              in-transaction test); _addColumnIfAbsent; _columnNames;
                                              the v1 rebuild computes TableMigration.newColumns
lib/data/models/customer_snapshot.dart        NEW  the value type + CustomerSnapshot.of
lib/data/models/invoice.dart                  + customerSnapshot, party(live), partyName(liveName)
lib/data/models/invoice_list_item.dart        customerName -> getter; field is liveCustomerName
lib/data/models/invoice_detail.dart           + party; customer redocumented as the LIVE record
lib/data/models/app_settings.dart             + paymentTermDays, kDefaultPaymentTermDays (moved here)
lib/data/repositories/drift/mappers.dart      + customerSnapshotFromRow
lib/data/repositories/drift/drift_invoice_repository.dart
                                              issue() and create(status:) write the snapshot;
                                              _requireCustomer; watchList -> liveCustomerName
lib/data/repositories/drift/drift_settings_repository.dart   + paymentTermDays both ways
lib/features/customers/application/customers_providers.dart  -> liveCustomerName
lib/features/invoices/domain/invoice_editor_state.dart       defaultDueDate(issueDate, termDays)
lib/features/invoices/application/invoice_editor.dart        the term drives a derived due date;
                                              moveLine moved back beside the other line intents
lib/features/settings/presentation/settings_screen.dart      + the term row; _SettingRow is a Wrap
lib/core/localization/arb/app_fa.arb          +3 strings (418 total)
drift_schemas/drift_schema_v3.json            NEW  the v3 baseline
test/data/database/generated/schema_v3.dart   NEW  drift_dev schema generate output
test/data/database/customer_snapshot_migration_test.dart     NEW  9 tests, four claims
test/data/repositories/invoice_customer_snapshot_test.dart   NEW  10 tests
test/features/settings/settings_screen_test.dart             NEW  4 tests, the screen's first
test/data/database/field_limits_test.dart     +2: the snapshot widths, the column default
test/features/invoices/invoice_editor_test.dart              +3 for the payment term
test/core/security/logging_path_test.dart     +6 sensitive accessors, verified to bite
test/data/database/invoice_number_migration_test.dart        two assertions retargeted to
                                              db.schemaVersion, with the reason
integration_test/customer_snapshot_migration_proof_test.dart NEW  both ladders, on device
integration_test/invoice_number_migration_proof_test.dart    version assertion -> schemaVersion
docs/*                                        D-052; ROADMAP (c2); ARCHITECTURE B.5
```

### Phase 4 increment (c)

```
lib/core/widgets/jalali_date_picker.dart      NEW  the calendar dialog + JalaliDateField
lib/core/widgets/app_text_field.dart          + onChanged, for fields feeding a live preview
lib/features/invoices/application/invoice_editor.dart
                                              + save(), issue(), _guarded();
                                              setIssueDate now carries a derived due date
lib/features/invoices/application/invoice_customer_picker.dart   NEW  the picker's own window
lib/features/invoices/domain/invoice_editor_state.dart
                                              + dueDateFollowsIssueDate, defaultDueDate,
                                              kDefaultPaymentTermDays
lib/features/invoices/presentation/widgets/invoice_details_section.dart  NEW
lib/features/invoices/presentation/widgets/customer_picker_sheet.dart    NEW
lib/data/models/field_limits.dart             + InvoiceLimits.notes
lib/core/localization/arb/app_fa.arb          +37 strings (415 total)
test/core/widgets/jalali_date_picker_test.dart               NEW  6 widget tests
test/features/invoices/invoice_details_section_test.dart     NEW  10 widget tests
test/features/invoices/invoice_editor_save_test.dart         NEW  7, over the real database
test/features/invoices/invoice_preview_matches_write_test.dart  +6; now covers the invoice level
test/data/repositories/invoice_repository_test.dart          +2; the editability boundary
docs/*                                        D-051; ROADMAP phase 4 (c) and (c2)
```

### Phase 4 increment (b)

```
lib/features/invoices/presentation/widgets/invoice_lines_section.dart     NEW
lib/features/invoices/presentation/widgets/invoice_line_editor_sheet.dart NEW
lib/features/invoices/presentation/widgets/product_picker_sheet.dart      NEW
lib/features/invoices/application/invoice_product_picker.dart             NEW
lib/data/models/field_limits.dart             + InvoiceLimits (lineTitle 200, lineUnit 30)
test/features/invoices/invoice_lines_section_test.dart       NEW  13 widget tests
test/data/database/field_limits_test.dart     + the invoice-line columns and the fits-in check
docs/*                                        D-050
```

### Phase 4 increment (a3)

```
lib/data/database/app_database.dart           + assertForeignKeysCanBeDisabled, called before
                                              alterTable; the DO NOT WRAP comment at the call site
test/data/database/invoice_number_migration_test.dart  +4 for the guard, its premise, and the
                                              data loss it prevents
docs/*                                        D-049
```

### Phase 4 increment (a2)

```
lib/data/database/tables/invoices.dart        the three number columns -> nullable (D-048)
lib/data/database/app_database.dart           schemaVersion 2; onUpgrade ladder; _migrateV1ToV2
lib/data/models/invoice.dart                  number/year/sequence -> nullable; + hasNumber
lib/data/repositories/drift/drift_invoice_repository.dart
                                              create allocates nothing for a draft;
                                              issue allocates in its own transaction;
                                              watchList ordering made total
lib/features/invoices/domain/invoice_number_label.dart      NEW  THE wording + the bidi rule
lib/features/invoices/presentation/invoices_screen.dart     all three render sites
lib/core/localization/arb/app_fa.arb          + invoiceNumberPending (140 total)
drift_schemas/drift_schema_v2.json            NEW  the v2 baseline
test/data/database/generated/                 NEW  drift_dev schema generate output (v1 + v2)
test/data/database/invoice_number_migration_test.dart       NEW  6 tests, two different claims
integration_test/invoice_number_migration_proof_test.dart   NEW  the device proof
test/data/repositories/invoice_repository_test.dart         allocation group rewritten; +4
test/features/invoices/invoices_screen_test.dart            +4 for the no-number copy
test/features/customers/customer_detail_screen_test.dart    +1 for the card-heading site
docs/*                                        D-048 -> ACCEPTED + implementation note; ROADMAP (a2)
```

### Phase 4 increment (a)

```
lib/core/money/invoice_calculator.dart        + grossTotal and the summary invariant (D-047)
lib/features/invoices/domain/invoice_editor_state.dart      NEW  the state; totals from the engine
lib/features/invoices/domain/invoice_warning_message.dart   NEW  D-027's first consumer
lib/features/invoices/application/invoice_editor.dart       NEW  the controller
lib/core/localization/arb/app_fa.arb          +3 warning strings (139 total)
test/core/money/single_calculation_path_test.dart           NEW  the ninth lib/ guard
test/core/money/invoice_calculator_test.dart  +3 for the summary invariant
test/features/invoices/invoice_editor_state_test.dart       NEW  26 tests
test/features/invoices/invoice_preview_matches_write_test.dart  NEW  preview == stored, 8 tests
test/features/invoices/invoice_warning_message_test.dart    NEW  6 tests
test/features/invoices/invoice_editor_test.dart             NEW  9 tests
docs/*                                        D-046, D-047, D-048 (proposed); ROADMAP Phase 4
```

### Phases 2 and 3

```
lib/data/models/field_limits.dart             NEW  THE field lengths (D-043)
lib/data/models/customer_totals.dart          NEW  billed + outstanding, one query (D-044)
lib/core/widgets/app_text_field.dart          NEW  THE text field; maxLength required
lib/core/widgets/stat_tile.dart               MOVED from features/dashboard; + TileGrid
lib/core/formatting/persian_text.dart         + keepDigitsOnly, the digit character class
lib/core/widgets/page_body.dart               + onBack (a directional icon, which does mirror)
lib/core/widgets/search_field.dart            + the one field-limit exemption, with its reason
lib/core/theme/app_dimensions.dart            + detailPanelWidth
lib/core/router/{destinations,app_router}.dart  + /customers/:id, declared after 'new'
lib/data/repositories/invoice_repository.dart + watchCustomerTotals
lib/data/repositories/drift/drift_invoice_repository.dart  + the FILTERed two-aggregate query
lib/features/customers/domain/customer_detail_view.dart    NEW
lib/features/customers/presentation/customer_detail_screen.dart  NEW
lib/features/customers/presentation/customer_delete_dialog.dart  NEW  one shared delete promise
lib/features/customers/application/customers_providers.dart  + the detail composition; D-045
lib/features/products/application/products_providers.dart    D-045
lib/features/{customers,products}/presentation/*_form_screen.dart  every field -> AppTextField
lib/features/invoices/presentation/invoices_screen.dart      + showCustomer / includeCustomer
lib/core/localization/arb/app_fa.arb          +14 strings (136 total)
test/core/widgets/field_limit_path_test.dart  NEW  the lib/ scan
test/data/database/field_limits_test.dart     NEW  where each column actually refuses
test/features/customers/customer_detail_screen_test.dart  NEW  21 tests
test/features/customers/fake_customer_repository.dart     NEW  shared by both customer suites
test/features/products/product_form_screen_test.dart      NEW
test/features/customers/customers_screen_test.dart        + the delete path that was untested
test/data/repositories/invoice_repository_test.dart       +6 for watchCustomerTotals
docs/*                                        D-043..D-045; ROADMAP phases 2 and 3; ARCHITECTURE §A
```

## Last completed action

**Phase 5 increment (e) — filters in SQL, and a paged customer list (D-063).**

- **Status, customer and Jalali period reach the query** as `WHERE` clauses on the statement that
  already carries the ordering and the `LIMIT`. Nothing narrows a loaded list; the test that says why
  builds twelve invoices, asks for five, and requires the one match that sorts last.
- **The window and the filter are one value**, so narrowing resets the page and widening keeps the
  predicate.
- **«سررسید گذشته» is deliberately not a filter** — derived at display time, and a SQL predicate would
  be its second implementation.
- **Known issue 16 closed**: `watchForCustomer` is paged, and the totals beside it are an aggregate
  rather than a sum of the page.
- **`jalaliMonthShifted`** is new in `core/date/`, because «ماه گذشته» may not be a subtraction.
- **Two scanners fired**: the token scanner rightly (a `Duration` doing calendar arithmetic), the
  soft-delete scanner wrongly (Riverpod's `.select`), and the second was narrowed with a test rather
  than silenced.
- **The keyboard sweep found the customer picker's empty state overflowing by 24 pixels**;
  `EmptyState` scrolls now.
- **40 new tests; 935 pass.** Analyzer clean, Android debug APK builds, both device suites re-run
  green on the Redmi with 0 layout errors.

**The boundary before it — known issue 21 and the keyboard rule (D-062).**

`EditorSheet` is the D-053 shape as a primitive: fields scroll, the commit action is pinned above the
keyboard. The survey behind it is the useful part — `FormScaffold` and the invoice line sheet were
**already** correct (the line sheet having arrived there independently), the payment sheet was the one
defect, and the two **picker** sheets do not take the shape at all because they commit by tapping a
row. A rule stated in one file was not a rule; it is a primitive now.

**And the reason 892 tests missed it:** `pumpScreen` installs its own `MediaQueryData`, so every widget
test this project has run had `viewInsets: EdgeInsets.zero` — no test *could* raise a keyboard. The
harness now takes `viewInsets`; the sweep asserts at the measured 255 px and is verified to bite; the
device pass raises the **real** keyboard and, on Android, refuses to pass on a vacuous assertion.

**The boundary before it — the Android phone-tier device pass for (b), (c) and (d) (D-062).**

Ran on the Redmi Note 8 Pro at 392.7 × 803.6, clearing three sessions of debt, plus the D-020 and
startup proofs that known issue 10b had blocked. **The product had no defects on the phone tier** —
0 layout errors at all four rungs, and every (b), (c) and (d) behaviour correct with the statuses read
back from the encrypted database. **The device test failed twice and both were the test's fault**: it
had only ever run on Windows and assumed the desktop layout, and it tapped the payment sheet's save
button where a machine with no soft keyboard puts it. Known issue 21 raised for the owner: the sheet's
primary action starts ~70 px below the fold on a phone.

**The boundary before it — Phase 5 increment (d), cancellation (D-061).**

`InvoiceRepository.cancel` existed since Phase 4 (d); (d) added the way in, the guard, the copy, and
the ruling that resolves known issue 20:

- **A cancelled invoice keeps its payments**, because the money changed hands — a cancellation speaks
  about the claim, not about the cash. Already the behaviour, via an early return; now a decision, and
  said in three places: the confirmation before the commitment, the page after it, and the code.
- **The confirmation is pinned by test** — «حذف نمی‌شود», «شماره», «ویرایش» — and gains a second,
  conditional sentence naming the amount that stays on record where the invoice actually carries
  payments.
- **«مانده» is explained rather than hidden** on a void document, and the payments card says the
  payments below it were really received.
- **Recording against a cancelled invoice stays refused** with the replacement invoice named as the
  way forward; **deleting stays allowed** with its own wording, because a mis-entered receipt must be
  correctable either way and it does not resurrect the invoice.
- **Only an issued invoice may be cancelled** — `InvoiceNotCancellable`, guarded inside the write's own
  transaction, tested at the repository by what each refusal left behind.
- **The action went in the title row**, under the new §10 rule this increment wrote down, rather than
  becoming the fourth card to push the first invoice line off a phone.
- **31 new tests; 892 pass.** Analyzer clean, Android debug APK builds, Windows device pass green with
  0 layout errors.

**The previous boundary — Phase 5 increment (c), payments (D-060).**

The write side already existed from Phase 4 (d), both halves recomputing the derived status inside
their own transaction (§6). (c) added the way in and the guard tests that matter:

- **The refusal tests call the repository directly**, not through the screen, and each asserts what the
  refusal *left behind* — status unmoved, total unmoved, no stray row. Two refusals that were missing
  entirely are covered now: deleting a payment that is not there, and deleting the same one twice.
- **Both directions are pinned**: paid → partiallyPaid → unpaid one deletion at a time, the last
  payment returning an invoice to unpaid, and a deletion on a **cancelled** invoice correcting the
  money record without resurrecting the invoice.
- **The deletion confirmation names the amount** and, only where it is true, says the invoice leaves
  «پرداخت شده». **The overpayment warning fires as the amount is typed**, never as a refusal.
- **The payments card cost 182 pixels empty and pushed the first line off a phone**, so it moved below
  the lines and the mobile action moved to the floating slot — the phone-height test from (b) catching
  it for the second time, on a different card.
- **24 new tests; 861 pass.** Analyzer clean, Android debug APK builds.

**The device pass now writes rather than only rendering.** On Windows: the real sheet, the real
repository, the real encrypted database, and the status read back **from the database** — 2,117,500
rial recorded (status `paid`), then deleted (status `unpaid`), 0 layout errors.

**Four boundaries are now awaiting review together** — (b), the known-issue-19 fix, (c) and (d) — and
none of them has been through the owner's own pass. There is no work in progress, nothing uncommitted
and no open question: the next session starts cold at the Next Action below.

## Next action

**First, note what is awaiting the owner's review** — (b), the known-issue-19 fix, (c), the device
pass and keyboard rule (D-062), and (e) (D-063). (d) has been accepted. If the session opens with
review feedback, that comes first; otherwise proceed.

**Then do Phase 5 increment (f): the phase close.**

Everything the phase set out to build is built. (f) is the verification pass and the paperwork, and
the owner's instruction is explicit that it includes **a device pass over what (e) added, run under
the keyboard rule** (D-062).

1. **The device pass over (e)'s new surface.** `integration_test/` has no coverage of the invoice
   **list** at all — both device suites are the form and the detail screen. The filter control, the
   filter sheet and its chips, and the filtered empty state have been checked at three tiers in widget
   tests but never on the target in Vazirmatn. The picker opens from the filter sheet and raises a real
   keyboard, so `raiseKeyboard` + `expectActionAboveKeyboard` apply.
2. **Re-run the whole device set** on the Redmi: the detail suite, the form suite, the D-020 proof and
   the startup proof. Known issue 10 recurs intermittently — build the debug APK and `adb install -r`
   by hand once if `flutter test -d` is refused.
3. **The close itself**: mark Phase 5 `COMPLETED` in `ROADMAP.md` only after the layout check has run
   at all three tiers over the ladder (D-057) *and* the keyboard rule has run on the phone (D-062).
4. **Do not add scope.** Everything (f) needs already exists; a phase close that grows a feature is a
   phase that has not closed.

**Nothing is blocked and nothing is owed.** The device debt that carried through three sessions is
cleared, and known issues 16, 20 and 21 are all closed.

**Getting the Redmi back, because this cost real time on 2026-09-01 and the symptom is misleading.**
`flutter devices` listing only Windows/Chrome/Edge does **not** mean the cable is bad. Check what
Windows actually enumerated:

```
Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match 'VID_2717' }
```

A single **WPD** entry (`USB\VID_2717&PID_FF40`) means the phone is present but exposing MTP only —
USB debugging is off, and there is no second, composite ADB interface. Nothing on this machine can fix
that; it is four toggles on the device: Developer options → **USB debugging**, plus MIUI's **Install
via USB** and **USB debugging (Security settings)**, and the USB mode set to **File transfer**, not
charge-only. Then accept the "Allow USB debugging?" prompt on the phone.

`adb` is **not on PATH**. It lives at
`%LOCALAPPDATA%/Android/Sdk/platform-tools/adb.exe`, and under Git Bash any device-side
path needs `MSYS_NO_PATHCONV=1` or it is mangled into a Windows path
(`adb shell "df -h /data"` becomes `df 'C:/Program Files/Git/data'`).

### Standing constraints for the rest of Phase 5, from the owner

- **The detail screen shows the party snapshot for issued invoices and the live record for drafts**
  (D-052), and **says which** — done in (b) via `InvoicePartyProvenance` (D-058).
- **Payments recompute derived status in the same transaction** (§6). **Recording and deleting both,
  both directions**, tested at the repository — done in (c) (D-060).
- **Cancellation is the correction path** for an issued invoice and must not silently edit. The
  Persian copy states what cancelling does **and does not** do, *including that the number stays
  spent* (D-013) — done in (d) via `InvoiceCancelAction`, with the ruling on the payments it keeps
  (D-061).
- **List filters over status, customer and Jalali period, at the query level** — not in Dart over a
  loaded page. Done in (e) (D-063).
- **Paging `watchForCustomer`**, known issue 16 — done in (e).
- **A device pass before the phase is called done** — at **all three tiers**, over the written ladder
  (D-057), not on one tier at whatever amounts the flow produces. **Done for (b), (c) and (d)** on the
  Redmi, 2026-09-01. **And the device test must `reach` what it asserts rather than assume where it
  is** (D-062): the tiers order pages differently, so a position that holds on one is a coincidence on
  the others.
