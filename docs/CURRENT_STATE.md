# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
>
> **New reader with no context? Read `docs/HANDOVER.md` first** — what the app does, what it
> deliberately does not, what is known broken, and what to do first. Then come back here.
>
> **Last updated: 2026-09-03 (fourth pass) — discounting became a step of its own, saved documents
> get unique names, and a notification was argued down rather than built.**
>
> * **Discounting is a screen, not a field** (D-098). Per-line and invoice-level discounts now live
>   in one place behind a «تخفیف» action beside «صدور فاکتور» and «ذخیرهٔ پیش‌نویس» — they answer one
>   question and were being asked in two forms on two screens. It previews what the discount does to
>   the payable figure before it is committed, and **D-027's clamp warnings finally have somewhere to
>   be stated**: while typing, against the figure that caused them.
> * **A saved PDF's name is unique** (D-099): `INV-1405-0001_1405-06-02_10-00-00.pdf`. It was the
>   invoice number alone, so the second save was the platform's decision — Windows offering to
>   overwrite, SAF quietly writing `(1)`.
> * **The document opens itself after saving** (D-100), except when it is missing its seller block,
>   where the message that fixes that keeps the screen.
> * **No notification was added, deliberately.** It would cost a dependency, a channel and the
>   `POST_NOTIFICATIONS` permission — the first prompt this application would ever show — for a
>   message about a foreground action the user just tapped and is watching. The owner invited the
>   push-back; D-100 records the argument.
>
> **Two things were found while building, not designed.** The clamp warnings were below the fold on a
> phone until a test could not find them, which is how it became clear the user could not either —
> they are now pinned with the commit action. And the file-name timestamp was nearly read from
> `nowProvider`, which is **frozen for the life of the process** on purpose: every export in a session
> would have proposed the same name, and the whole change would have bought nothing.
>
> Earlier the same day: **the phone's invoice form was rebuilt (third pass) — the phone's invoice form was rebuilt around what the
> user has to do, and the catalogue line asks one question.** The owner tested the previous build
> and reported the new-invoice screen as still hard to use. It was: **known issue 30 had been closed
> and the problem had not.**
>
> Three separate fixes had aimed at the add-line control — fold the details (D-054), withdraw «صدور»
> from the bar (D-086), put the lines first (D-093) — and each measured something real, moved it
> somewhere better, and **left it inside the scroll**. Three fixes to one symptom is the signal that
> the symptom was not the fault. The fault was that the screen was arranged by what the data model
> calls things: one of the two acts that create an invoice was a control at the foot of a scrolling
> section, and the other was a **field inside a collapsed section called «جزئیات فاکتور»** — exactly
> where nobody would look for the one thing a save cannot do without.
>
> **The phone now pins what the user must do and scrolls what varies** (D-096): the customer picker
> and both add-line buttons above, the lines and the folded detail between, the payable figure and
> the two actions below. The arrangement was chosen by the owner from three drawn alternatives. What
> pays for the header is the breakdown leaving the bar for the scroll — D-053's ruling, applied to a
> second tier.
>
> **And a line picked from the catalogue now collects only the quantity** (D-097). D-090 made that
> true when *reopening* a line and stopped there, which was half a rule: the question is not whether
> the line is new but whether a product record stands behind it. The free line still collects
> everything, because nothing backs it. **One capability was removed and is recorded rather than
> discovered:** a per-line discount can no longer be set on a catalogued line.
>
> Both were seen working on the real application at phone width before the build was cut.
>
> Earlier the same day: **twelve changes from real use are delivered.** The
> owner returned from testing with a list of twelve; all twelve are done, `flutter analyze` is
> clean and **1,269 tests pass** (1,231 before, +38). Two artifacts were produced: a Windows release
> build and an **arm64 profile APK**.
>
> **What changed, in one line each.** Tab switching no longer flashes (D-089). An existing invoice
> line offers only its quantity (D-090). The invoice detail screen was redesigned as one change —
> issue date and time at the top, a visible PDF button, status colour on the blocks that report
> payment state, fine detail below the lines (D-092, D-093, D-094). The printed document carries the
> time too, **read off a rasterised page** rather than off the source. The navigation bar's five
> destinations are the same size (D-088). Back returns to the dashboard, and leaves only from there
> (D-095). Light/dark is a setting, stored in schema **v6** (D-087).
>
> **Known issue 30 is CLOSED** — D-086's candidate 1, taken: on the phone the lines section is now
> above the details section, so the add-line control cannot leave the first screen.
>
> **The most valuable thing in this session is a defect nobody asked for, found while building item
> 4.** `setIssueDate` assigned the date picker's return value whole — and the picker correctly
> returns a **day**, while `issue_date` is an **instant**. So every invoice whose date was ever
> corrected had its time of day silently replaced with local midnight: not a missing value but a
> false one, on the field a printed document dates itself by. It was invisible for as long as the
> time was never displayed, which was its whole life until the owner asked for it to be shown.
>
> **It is the same shape as the three uncalled repository methods**: correct code on both sides,
> wrong wiring between them, and no test able to see it — because a suite of unit tests over correct
> components cannot report a fault in the wiring. That is now written up as `HANDOVER.md` §6d,
> beside §6b (a method with no call site) and §6c (a check that runs in a state no user is in). All
> four instances were found by a person using the application, or by asking it for something new.
>
> **Two things are deliberately unverified, and both are Android-only.** The back **gesture** on
> hardware (D-095) and the intent that opens a saved PDF (D-091). No phone was connected; the Kotlin
> compiles and is in the built APK, and the Dart side is tested through the real dispatcher — what is
> untested is the device. They are the first two things to check on the APK.
>
> **One guard was proved to bite while being written.** `navigation_bar_test.dart` failed against the
> first attempt at D-088 (a `DefaultTextStyle` outside the `NavigationBar`, which Material's own
> `Material` resets) and passed against the second. That is D-072's falsifiability requirement met by
> accident, and it is recorded because most of the guards here have not had that.
>
> Earlier: **Phase 7 is COMPLETE and the app has been used on a phone.** Eight
> findings came out of that first real use, and **seven are fixed**: a draft can now be deleted,
> issued and edited; a settled invoice no longer offers a payment action it does not need; numeric
> fields select on focus; the printed document states its status; and the printed line-total column
> — the one figure a customer could not check by hand — is gone. The eighth is **known issue 30**,
> measured on the phone and partly fixed.
>
> **Three of the eight were one shape: a repository method with no call site.** `softDeleteDraft`,
> `issue` and `updateDraft` all existed, were correct, and were covered by their own tests, and
> nothing in the interface called any of them. 1,230 tests could not see it. `HANDOVER.md` §6b is
> the audit that finds this class; §6c is the related one — checks that run in states no user is
> ever in, of which three were found in three days.
>
> **Read `docs/HANDOVER.md` first if you are new.**
>
> Earlier: **Phase 7 is COMPLETE, and a resize defect the owner found is
> fixed (D-081).** The desktop breakpoint was 1024 and should have been 1312: between those widths
> four screens laid a table out narrower than its columns need. In debug that is the red error box
> the owner saw; **in release the guard is compiled out and it would have shipped as Persian at one
> glyph per row.** `width_sweep_test.dart` now renders every screen inside the real shell at every
> width from 328 to 1600.
>
> Earlier: **Phase 7 (d) is built. The invoice is reachable from
> the application, it saves through the D-071 gateway, and §7's question about where it lands is
> answered and tested on both targets (D-080).** Known issue 24 is fixed at the source with a
> wrapper rather than a reversed list (D-079), and the real size cost is finally measured:
> **+1.77 MB on arm64**, against D-074's +133 KB floor — thirteen times the estimate, which is what
> a floor resting on the import graph was warning about.
>
> Earlier the same evening: **the (d) cable session ran. Phase 7 (a), (b) and (c) are
> delivered; the three Android measurements the gate owed are now taken, and the session found a
> regression (c) had shipped into the settings device suite.**
>
> **Read `## What the (d) cable session found` before quoting any cold-start number.** The recorded
> 1,401 ms baseline **does not reproduce**: the same commit, on the same phone, measures **352 ms**
> today. The startup conclusion now rests on a **paired** measurement taken minutes apart rather
> than on a comparison against that figure.
>
> Earlier the same day:
> **(c) closed the D-076 gap at schema v5 (D-077):** four nullable `settings.seller_*` columns, the
> migration with both ladders proved on Windows, a seller section on the settings screen with its
> own sheet, and a فروشنده block beside the خریدار block on the page. Scope held exactly — no logo,
> no registration number, no customisation. **Both product questions are decided:** an empty seller
> prints **no block at all** rather than a heading over blanks, and it **blocks nothing** — not
> issuing, not printing — with the settings screen carrying the prompt that makes it impossible to
> be surprised by.
>
> **Reading the rendered page caught two defects nothing else did**, which is now three increments
> in a row for that method. Every party نشانی was **overflowing its block and being clipped
> mid-word**, with no overflow and no error — invisible while the buyer block had the full page
> width. And **`pw.Table` lays column 0 out at the LEFT even under `textDirection: rtl`**, which put
> the seller on the wrong side until it was corrected — and which means **D-076 was wrong to record
> that the lines table's RTL column order came out right.** It did not. That is **known issue 24**,
> left open on purpose because the lines table is an accepted increment and outside (c)'s scope, and
> it is the **first thing to settle in (d)**.
>
> **A correction the owner should see:** the "byte-identical APK" result is a **size** measurement,
> not a fingerprint. (c) reproduces 21,653,926 exactly — and a deliberate throwaway change to a
> reachable widget also reproduces it, while changing `libapp.so`'s content hash. The figure is
> quantised by page and zip alignment and does not distinguish changes of this magnitude. The floor
> claim still holds on the import graph; the number is weaker evidence than "byte-identical"
> implied. See D-077.
>
> **The Android leg of the v5 migration proof is no longer owed — it PASSED**, both ladders, on the
> Redmi, 2026-09-02 evening. So did all four phone-tier device suites and the cold-start
> measurement. See the cable-session section below.
>
> Earlier the same day: **Phase 7 (a) and (b)** — the `pdf` dependency, `core/pdf/`, the view model,
> the generator interface and the one template. The two (b) product questions are **decided**
> (D-075): a draft prints marked with an unmissable band, and a pre-snapshot invoice prints the live
> record with one factual line. **Nothing is generated from the app yet** — (d) makes it reachable,
> and the real size and cold-start measurements go with it.
>
> Earlier the same day: **the ZWNJ blocker was solved (D-073), and two earlier diagnoses of it
> were wrong.** It is not a missing glyph, not the subsetting, and not the control character:
> `TtfParser.readGlyph` never checks whether a glyph is empty, so U+200C draws the **next glyph in
> the font** — «à» in Vazirmatn — and every zero-width control is in the same hazard class. The
> remedy is to cut the run at the ZWNJ and send no control character at all; it is proven on
> rendered pages over all **68** ARB entries that contain one, and it **shipped** in (a) the same
> day. Rendering is local — `tools/pdf_raster/` — and no longer depends on a browser.
>
> Earlier: **2026-09-01** — Phase 5 is `COMPLETED` and accepted. Since the close, two visual
> defects reported off the Windows build have been fixed (D-065, D-066) with the checks that would
> have caught them, and widget tests now render in the real font (D-067).
>
> **THE PLAN HAS BEEN CUT (D-068).** Development access ends 2026-09-04. The remaining plan is
> **Phase 6 (Backup and Restore)** and **Phase 7 (PDF)**, and nothing else: Phases 8–15 are
> `DEFERRED_INDEFINITELY`. Both remaining phases run at **deliberately reduced standards** —
> phone tier only, one large realistic amount, data-correctness tests rather than exhaustive layout,
> one PDF template, export/import only. **Four things are not reduced**: `core/money/` is the only
> calculator, the renderer computes nothing, encryption and key handling are untouched, and Persian
> correctness in a customer-facing document is absolute. Read D-068 before reading any older section
> of this file that assumes the full ladder.

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `COMPLETED`** (2026-08-24, seven increments, all accepted)
**Phase 2 — Customers · `COMPLETED`** (2026-08-25)
**Phase 3 — Products and Services · `COMPLETED`** (2026-08-25)
**Phase 4 — Invoice Creation · `COMPLETED`** (2026-08-27) — every increment delivered and
**accepted**, including (d).
**Phase 5 — Invoice Management and Payments · `COMPLETED`** (2026-09-01) — **every increment
delivered, reviewed and accepted.** The owner accepted the five outstanding boundaries — (b) the
detail screen (D-057, D-058), the known-issue-19 fix (D-059), (c) payments (D-060), the device pass
and the keyboard rule (D-062, known issue 21), and (e) filters and paging (D-063) — and (f) closed
the phase. **Nothing is awaiting review.**

**Phase 6 — Backup and Restore · `COMPLETED`** (2026-09-01) — all four increments delivered at
D-068's reduced standards. **Nothing unfinished, nothing deferred out of it.**
**Phase 7 — PDF Generation · `IN_PROGRESS`** — the last phase in the plan.
**(a) delivered** 2026-09-02 (D-074): the dependency, `core/pdf/`, the guards, the entry-gate
measurement. **(b) delivered** 2026-09-02 (D-075, D-076): the view model, the generator interface
and the one template. **(c) delivered** 2026-09-02 (D-077): **schema v5**, the seller block, and the
two rulings about what an empty seller prints and what it blocks. **(d) is all that remains**:
save/share, the device pass, the two measurements the gate still owes, the Android leg of the v5
proof, and known issue 24.
**Phases 8–15 · `DEFERRED_INDEFINITELY`** (D-068). Not next, not later, not scheduled. Two items
inside them are called out in `ROADMAP.md` as minutes of work that gate distribution rather than
phase-sized work: the Android manifest's `allowBackup="false"` (known issue 15) and release
signing from a gitignored properties file (known issue 13).

**After the close, before Phase 6:** two visual defects reported off the Windows build, both fixed —
the invoice document table's crushed description column (**D-065**) and chip labels painted with no
colour (**D-066**) — together with the checks that would have caught them and the harness change that
made one of them checkable (**D-067**).

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
| b | **`/invoices/:id`**, the detail screen; rows tappable; the money-width audit and the tier rule (D-057, D-058) | `COMPLETED` 2026-09-01, **accepted** |
| — | **Known issue 19**: exact allocation at every invoice size (D-059) | `COMPLETED` 2026-09-01, **accepted** |
| c | **Payments: record and delete**, derived status in the same transaction (D-060) | `COMPLETED` 2026-09-01, **accepted** |
| d | **Cancellation**, the copy that says what it does not do, and the ruling on the payments it keeps (D-061) | `COMPLETED` 2026-09-01, **accepted** |
| — | **The phone-tier device pass**, the keyboard rule and known issue 21 (D-062) | `COMPLETED` 2026-09-01, **accepted** |
| e | **List filters** (status, customer, Jalali period) at the query level; paging `watchForCustomer` (D-063) | `COMPLETED` 2026-09-01, **accepted** |
| f | **The phase close** (D-064): the invoice list's first device coverage, both targets, and the tier fault it found in the form suite | `COMPLETED` 2026-09-01, **accepted** |


## Where the project stands, in one paragraph

**An invoice can be created, read as a document, paid off — and now printed.** Phase 7 (a) and (b)
are delivered: `pdf` 3.13.0 is a dependency, `core/pdf/` makes Persian safe to hand a renderer that
has two silent faults in it, and `features/invoices/document/` turns a stored invoice into an A4
Persian page with a header, a party block, a lines table and totals. **The one thing it cannot do is
be reached from the application** — nothing on any screen generates a document yet. That is (d),
and the two measurements the Phase 7 gate owes go with it.

**One decision is with the owner and blocks (c):** the schema holds **no business identity**, so the
document has a خریدار block and no فروشنده block. Nothing was invented to fill it. See the Next
Action.

**An invoice can be created, read as a document, and paid off.** Eight screens work end to end on real
data — Dashboard, Invoices, the invoice **form**, the invoice **detail** page, Customers, Customer
detail, Products, Settings — inside a Persian, RTL, three-tier responsive shell over an encrypted
SQLite database at **schema v4**. «فاکتور جدید» opens `/invoices/new`; a row in the list opens
`/invoices/:id`; and from there a payment can be recorded and taken back off again, with the derived
status recomputed by the repository in the same transaction.

**Phases 4 and 5 are both complete and accepted.** Every Phase 5 boundary — the carry-overs, the
D-047 ruling (D-055), (a2) schema v4 (D-056), (b) the detail screen (D-057, D-058), the
known-issue-19 fix (D-059), (c) payments (D-060), (d) cancellation (D-061), the device pass and the
keyboard rule (D-062), (e) filters and paging (D-063), and (f) the close (D-064) — is delivered,
reviewed and **accepted**. **Nothing is awaiting review and nothing is owed.**

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

**Phase 5 closed on evidence at two targets and three tiers.** (f) added the invoice list's first
`integration_test/` coverage — the filter control, the sheet, the chips, the filtered empty state and
the customer picker reached from inside the sheet, under the keyboard rule — and put the list into
the ladder sweep at all three tiers. **The interesting part was not the new suite**, which passed
first try on both targets: it was pointing the **existing** form suite at Windows, where it had never
run in two phases of existing, and watching it fail on its first measurement. Not a product defect —
the desktop layout is one lazy `ListView` whose lines section sits past the cache extent, so the
finder reported **absence, not invisibility**, which is D-062 §2 in the file next door to the one
D-062 was written about. **D-064** is the rule that follows: every device suite runs on every target,
and the phase close is what runs it there. No product defect was found anywhere in the close: 0
layout errors, two targets, four rungs.

**Working tree is clean and everything is committed.** `main`'s tip is **`9b9ae8b`** "Fix two visual
defects, and add the checks that would have caught them" (D-065, D-066, D-067). Behind it,
`01a6bbc`/**`0389f1e`** is the phase close, "Phase 5 (f):
the phase close, and the tier fault it found in an older check". Behind it: `7117a33`/`248537d` are
(e)'s continuity updates and **`4d604da`** "Phase 5 (e): invoice filters in SQL, and a paged customer
list". Behind it: **`7775e0b`** is the known-issue-21 fix and the keyboard rule; **`099a437`** is the
phone-tier device pass; `b90f642`/**`2c20f7c`** is (d), "cancellation, and what it does not do";
`bf5c78b`/`241f446`/**`2747b2d`** is (c), "payments, recorded and taken back"; `ca1bc53`/**`6675456`**
is the known-issue-19 fix; `435f8cb`/**`b901c37`** is (b), "the detail screen, and the layout check
that would have caught its predecessor"; `42bbaae` is the (a2) cold-resume note and `712c921` is (a2)
itself; `d087c2a` is the first Phase 5 boundary; `a068d63`/`eecd96b` is Phase 4 (c2), `ea4858c` its
(c), `3164b8f` its (b), `0e0cd37` its (a3), `7345ca2` its (a2), `bf4c02f` its (a); `d8682ee` is Phases
2 and 3.

**Nothing is half-finished and nothing is deferred out of Phase 5.** Everything the phase scoped —
the detail screen, payments both ways, cancellation, filters at the query level, paging — is built,
tested at two targets and accepted. What Phase 5 does **not** contain was never in it: PDF is Phase 7
(the `InvoiceDocumentGenerator` boundary is defined and fails loudly, per §12), reports are Phase 8
and stay off the navigation per D-021, and editable settings are Phase 6's neighbourhood. There is no
work in progress, nothing uncommitted and no question waiting on an answer.

**The device debt is cleared.** The Android phone-tier pass ran for (b), (c) and (d) together on the
Redmi Note 8 Pro, and the two proofs that known issue 10b blocked in the (a2) session — D-020 and
startup — were re-run with it. **The product had no defects on the phone tier**; what failed, twice,
was the device test itself, which had only ever run on Windows and had encoded the desktop layout as
if it were the layout. See D-062 and known issue 21.

**That gap is closed.** `integration_test/invoice_list_device_test.dart` covers the list on both
targets, and the picker it opens from inside the filter sheet is asserted under the keyboard rule
with the real keyboard up.

**Note the collision when reading older sections of this file:** Phase 4 and Phase 5 both have
increments lettered (a2), (b), (c) and (d). Every reference below names its phase; where one does not,
it belongs to the section it sits in.

## Verification status

```
flutter analyze:            PASS   (No issues found)                    as of 2026-09-03, twelve
Width sweep (D-081):        PASS   width_sweep_test.dart -- 10 screens x every width from 328 to
                                   1600, each inside the REAL AdaptiveScaffold, failing on any
                                   thrown exception. Verified to bite: 4 screens fail at the old
                                   1024 breakpoint, 1 at 1280. It is also the ONLY widget test the
                                   app shell appears in
Desktop tier device cover:  GAP    the Windows suites run at 1264, which is now the TABLET tier
                                   (invoice_form_device_test reports `tier : tablet`). The desktop
                                   tier is held by the widget sweep at 1400 and by the width sweep;
                                   a device run needs a window >= 1312. Stated, not implied
Export from the menu:       PASS   phone tier, Redmi (2026-09-02): the menu item on a CANCELLED
                                   invoice, tapped, the render driven through the real providers,
                                   and D-077's no-seller notice with its «تنظیمات» action shown.
                                   0 layout errors. Gateway faked -- SAF cannot be driven by adb
flutter test:               PASS   (1289/1289) as of 2026-09-03, after the discount screen and the
                                   document naming (D-098, D-099, D-100). Was 1272 after the phone's
                                   invoice form was rebuilt (D-096, D-097), 1269 after the twelve.
                                   Was 1230 after the eight phone findings, 1204 at the Phase 7
                                   close, 1194 after (d), 1189 after (c). The +38 are: the v6 theme
                                   migration (7), the back rule (8), the navigation bar (5), the
                                   time formatter and the day-with-time arithmetic (8), the
                                   redesigned invoice header at every tier and status (7), the
                                   document's date-and-time (3)
Owner's twelve, 2026-09-03: DONE   all twelve. 1 tab flash (D-089), 2 quantity-only line editing
                                   (D-090), 3 information hierarchy + known issue 30 (D-093),
                                   4 issue date and time at the top (D-092), 5 visible PDF button
                                   (D-094), 6 open-the-file action (D-091), 7 the time on the
                                   printed page (D-092), 8 status colour (D-093), 9 the navigation
                                   bar (D-088), 10 the back button (D-095), 11 light/dark (D-087),
                                   12 the coherence of 2/3/4/5/8, which is why they share D-092-094
Android-only, UNVERIFIED:   GAP    **two behaviours nothing here could check.** (a) the back
                                   GESTURE on hardware -- the Dart side is driven through the real
                                   BackButtonListener and the platform popRoute message, and
                                   SystemNavigator.pop is watched on the channel, but no device ran
                                   it. (b) the ACTION_VIEW intent behind «باز کردن» -- the Kotlin
                                   compiles and the channel string is present in the built APK
                                   (classes9.dex), and that is the whole of what is known. Both are
                                   step 1 of the Next Action, and neither is a Windows question
Rendered page, date+time:   PASS   read off PIXELS, not source, per HANDOVER §6. Rasterised at
                                   2400 px through tools/pdf_raster and cropped: the header reads
                                   «تاریخ صدور ۲ شهریور ۱۴۰۵، ساعت ۱۰:۰۰» -- digits in order, the
                                   bidi-neutral colon not reordered, the isolates stripped at the
                                   boundary without eating the final glyph (D-070 finding 1)
Discount screen, seen:      PASS   at 420 px, driven end to end: the «تخفیف» action beside the two
                                   commit actions; the sheet showing «مبلغ فعلی ۲٬۴۰۰٬۰۰۰» over
                                   «مبلغ پس از تخفیف»; a per-line amount of ۳٬۰۰۰٬۰۰۰ against a line
                                   worth ۲٬۴۰۰٬۰۰۰ driving the preview to ۰ and «۲٬۴۰۰٬۰۰۰ تومان
                                   کمتر از مبلغ فعلی»; and D-027's warning **pinned above** «اعمال
                                   تخفیف» naming both figures. That last one is the assertion the
                                   engine has been able to make since Phase 4 with nowhere to make it
Phone tier, seen not argued: PASS  the Windows window narrowed to 420 px -- under the 600 px
                                   tablet breakpoint, so the real mobile layout -- and driven:
                                   the pinned header carries the customer picker and both add
                                   buttons on one line; the lines, the breakdown and the folded
                                   details scroll under it; the disabled draft button and its
                                   reason sit in the pinned bar. Picking «پشتیبانی ماهانه» from the
                                   catalogue opened a sheet with «تعداد» focused and unit, price and
                                   tax stated beneath it. The five navigation destinations sit at
                                   one height with «محصولات و خ…» abbreviated, which is D-088 seen
                                   rather than measured
Windows, run not just built: PASS  built debug, LAUNCHED, and driven: the v5->v6 migration ran
                                   against the real dev database (12 demo invoices) and the app
                                   opened on it; the redesigned invoice screen, the status tint,
                                   the light/dark control and dark mode were all seen on screen.
                                   The dev database's theme was set back to «سیستم» afterwards
Guard verified to bite:     PASS   navigation_bar_test.dart failed against the FIRST attempt at
                                   D-088 -- a DefaultTextStyle outside the NavigationBar, which
                                   Material's own Material resets -- measuring 36 logical pixels
                                   against the other four destinations' 18, and passed against the
                                   second. D-072's requirement, met while the guard was written
Phone findings, 2026-09-03: FIXED  7 of 8. Draft delete (27), issue from the detail screen (D-082),
                                   draft edit (29, D-084), the unreconcilable printed line-total
                                   column removed (D-082), settled invoices withdraw the payment
                                   action and say so (D-084), numeric fields select on focus
                                   (D-084), the document states its status (D-085). The eighth is
                                   known issue 30, measured and partly fixed (D-086)
Fold, measured on the Redmi: TAKEN 392.7 x 803.6. add-line at 586-611; pinned bar top **670 before,
                                   726 after** removing «صدور» until a line exists -- the gap above
                                   add-line went 59 -> 115 px. With the details section UNFOLDED the
                                   control is out of the widget tree entirely, ~400 px away, and
                                   that half is still open. D-086
Invoice export - both:      PASS   re-run after the status work; 0 layout errors on the phone
                                   +5 for `rtl_table_test.dart`; the export suite is an
                                   integration test and is not in this count
Android build:              PASS   **arm64 PROFILE APK, rebuilt from the COMMITTED tree after a
                                   `flutter clean`**: 35,055,091 bytes. Profile, not release, so it
                                   needs no keystore -- the release refusal (D-083) is untouched and
                                   still fires. The engine, the app snapshot and sqlite3mc are
                                   arm64-only as asked; `libdartjni.so` also ships v7a and x86_64
                                   because the `jni` dependency does, which costs ~160 KB and
                                   affects nothing. Verified to be the right build: the
                                   `open_file` channel string is in classes9.dex.
                                   **Take the size from a cleaned build.** The same APK built over
                                   an uncleaned tree earlier the same day read 47,385,392 -- 12 MB
                                   of stale artifacts, the Android counterpart of the Windows
                                   kernel_blob.bin trap below.
                                   Earlier: release APKs 2026-09-02, arm64 21,653,926. NOT installed
                                   on a device since 2026-09-01
Windows build:              PASS   **release rebuilt from the COMMITTED tree after a
                                   `flutter clean`**: 35,050,954 over 19 files at
                                   build/windows/x64/runner/Release/ (data/app.so 9,896,840).
                                   Take a SIZE figure only after `flutter clean`: an uncleaned
                                   Release dir holds an 87 MB stale kernel_blob.bin and reads 120 MB
Artifacts delivered:        PASS   both replaced in `%USERPROFILE%\Desktop\Factorino-test\`,
                                   under the fixed names the owner links people to:
                                   `factorino-arm64.apk` (35,055,091) and
                                   `factorino-windows-x64.zip` (14,793,816, 21 entries, the bundle
                                   CONTENTS at the archive root so the README's "extract, enter the
                                   folder, double-click factorino.exe" is true). **The zip was
                                   extracted to a scratch directory and launched** -- the exact path
                                   a tester follows -- and opened its window. `README-fa.txt`
                                   rewritten for what a tester now sees: a new section 4 for the
                                   twelve changes, with the two unverified Android behaviours called
                                   out at the top of it and again under reporting priorities; the
                                   fixed add-line issue removed from the known-issues list; and a
                                   new known issue for pre-existing invoices that legitimately
                                   show ۰۰:۰۰ (see D-092 -- their real time was never stored)

Backup container proof:     PASS   5/5 on BOTH targets (D-069) -- encrypted on disk with the
                                   sentinel absent from the raw bytes, right passphrase reopens,
                                   wrong passphrase fails at open leaving the file intact, a
                                   flipped byte fails authentication, empty passphrase refused
                                   before a file exists
Backup export round trip:   PASS   every stored figure equal to the Rial, tombstones carried,
                                   the live settings row and not the seeded default (Phase 6 b)
Backup passphrase chars:    PASS   24 tests, each writing and reopening a real container:
                                   apostrophes, quote, backslash, Persian and Arabic-Indic digits,
                                   ZWNJ, spaces at both ends, injection-shaped, emoji, 200 chars.
                                   Plus 6 must-NOT-open cases pinning that spaces, ZWNJ and the
                                   two digit sets are never folded together
Backup gateway - Android:   PASS   opens ACTION_CREATE_DOCUMENT on the Redmi, verified in
                                   `dumpsys`; cancelling returns false; and a CONFIRMED save
                                   writes 4,096 bytes byte-identical to the source (D-071)
Backup gateway - Windows:   PASS   confirmed save through file_selector_windows, 4,096 bytes
                                   byte-identical. Interactive test, run deliberately, not in
                                   any suite -- MIUI refuses adb input injection
Phase 7 cold-start baseline: WITHDRAWN -- was "1,401 ms median of runs 2-5 (1,330-1,465), on
                                   60b5cd5". It does NOT reproduce: that same commit, rebuilt and
                                   measured on the same phone 2026-09-02, gives 352 ms. Do not
                                   quote it. Use the paired entry below. D-078
ZWNJ remedy (D-073/D-074):  SHIPPED in core/pdf/, 45 new tests. 68/68 ARB entries carrying
                                   U+200C are unsafe through a plain span and 0/68 through
                                   SafeText; the join break, the word order and the atom's
                                   baseline read off rendered pages at 4 sizes; no line break
                                   inside the word at 6 widths. Cause pinned byte-for-byte:
                                   readGlyph(322) == readGlyph(323). The derived unsafe set is
                                   11 runes, not the 4 every write-up had named
Phase 7 size, post-pdf:     TAKEN  arm64 21,653,926 (+133,402 on the 60b5cd5 baseline);
                                   Windows bundle 33,116,830 over 18 files (+240,224), from a
                                   CLEAN rebuild -- an uncleaned Release dir carries an 87 MB
                                   stale kernel_blob.bin and reads 120 MB.
                                   **A floor, and the floor claim rests on the IMPORT GRAPH --
                                   nothing reachable from main() imports core/pdf/ -- not on the
                                   number.** The number cannot carry it: it is quantised, and the
                                   entry below proves it does not distinguish changes of this
                                   magnitude. When step 1 of (d) lands, core/pdf/ becomes
                                   reachable and the figure means something for the first time
Phase 7 cold start, post:   TAKEN  HEAD (f71791c) 343 ms median of 10 steady-state runs
                                   (317-395), release arm64 on the Redmi, `am force-stop` before
                                   each. **Compare it only against the PAIRED control**, not
                                   against the 1,401 ms figure above: the baseline commit 60b5cd5,
                                   rebuilt and measured on the same phone in the same session,
                                   gives 352 ms median of 10 (345-366). 343 vs 352 -- the PDF work
                                   costs nothing measurable at startup. First launch after a fresh
                                   install is 2.5-9.0 s and is not part of either figure
Cold-start BASELINE RETIRED: PROVED The recorded 1,401 ms does NOT reproduce. 60b5cd5 is the commit
                                   it was taken on; rebuilt from a worktree at that exact commit
                                   and measured on the same Redmi it measures 352 ms, a 4x gap
                                   with the code held constant. The cause is not established --
                                   device conditions on 2026-09-01, not the application. Do not
                                   quote 1,401, and do not quote the "4x faster" that comparing
                                   against it would produce. D-078
Phase 7 size after (b):     TAKEN  arm64 21,653,926 -- same SIZE as (a). Read the correction
                                   below before quoting this as "byte-identical"
Phase 7 size after (c):     TAKEN  arm64 21,653,926 -- the same figure again, after schema v5, a
                                   new model, a new sheet, a new settings section and 30 tests
Size figure is QUANTISED:   PROVED A deliberate throwaway change to a reachable widget was built
                                   and measured: libapp.so content changed (sha256 a4c8c84f... ->
                                   e0256500...) while its size stayed 7,078,792 and the APK stayed
                                   21,653,926. So an equal figure does NOT establish equal content
                                   -- page padding in the AOT snapshot and zip alignment absorb
                                   changes of this magnitude. The floor claim still holds, on the
                                   IMPORT GRAPH (nothing from main() imports core/pdf/) rather than
                                   on the number. D-077
Seller migration - Windows: PASS   both ladders, v4 -> v5 AND v1 -> v5, through the real production
                                   path on an encrypted file with foreign keys on: user_version
                                   4->5 and 1->5, one settings row, four nulls, the user's own tax
                                   rate and prefix untouched, still encrypted, and the columns
                                   written and cleared back through the real repository (D-077)
Seller migration - Android: PASS   both ladders on the Redmi (2026-09-02 evening), through the real
                                   production path on an encrypted file with foreign keys on:
                                   user_version 4->5 and 1->5, one settings row, four nulls, the
                                   user's own tax rate (900bp), prefix (FCT) and payment term
                                   untouched, still encrypted, and the columns written and cleared
                                   back through the real repository. Matches Windows exactly
Backup gateway - Android:   PASS   RE-RUN 2026-09-02 evening on the current build. The picker is
                            (again) confirmed open from logcat -- ACTION_CREATE_DOCUMENT ->
                                   documentsui PickActivity, foreground -- and the confirmed save
                                   landed 4,096 bytes in Downloads, sha256 identical to the source.
                                   Still interactive: SAF cannot complete without a human, which is
                                   also what makes the result mean something
Invoice export - both:      PASS   `invoice_export_test.dart`, 3 tests on Windows AND Android
                                   (D-064). The REAL render from the REAL providers -- fonts out of
                                   rootBundle, seller out of the repository, view out of a stored
                                   invoice -- 18,398 bytes, `%PDF-`, named INV-1405-0001.pdf, and
                                   byte-identical on the two targets. Pins the §7 property in both
                                   directions: the file EXISTS when offered to the gateway and is
                                   GONE afterwards, on the confirmed path and on the cancelled one.
                                   An empty seller still prints, and the outcome says so (D-080)
Phase 7 size, REAL (d):     TAKEN  arm64 23,423,398, **+1,769,472 on (c)** -- the first figure that
                                   means anything, because step 1 of (d) is what made core/pdf/
                                   reachable from main(). armeabi-v7a 21,343,678 (+2,080,768);
                                   x86_64 24,976,002 (+1,638,400). **D-074's +133 KB floor
                                   understated the real cost 13x**, which is what "a floor, resting
                                   on the import graph rather than on the number" was warning
                                   about. No new assets -- both Vazirmatn faces were already
                                   bundled for the screen; the delta is the pdf package's own AOT
                                   code, which the tree-shaker had been discarding entirely. D-080
RTL table order (issue 24):  PASS  READ OFF THE RENDERED PAGE, both fixtures: ردیف at the far right
                                   through جمع سطر at the far left, فروشنده right and خریدار left.
                                   Fixed via `rtlTable`, a wrapper -- callers declare columns in
                                   reading order and nothing is written backwards (D-079)
Sheet keyboard slack floor: PASS   Both guards now assert the action clears the keyboard by at
                                   least `AppSpacing.lg`, the padding EditorSheet puts under it --
                                   not a literal. Verified to bite: at 2x the floor, 5 of 6 sheets
                                   fail and the picker (outside EditorSheet by design) passes,
                                   which is a floor behaving as a floor. D-079 corrects D-072:
                                   those 16 pixels were never margin
Invoice document rendered:  PASS   read off the pixels at the ladder ceiling, all 4 rungs, a
                                   draft, a pre-snapshot invoice, 28 lines over 2 pages, and -- new
                                   in (c) -- both party blocks at real Persian lengths and a page
                                   with no seller at all. The (c) read caught TWO defects: clipped
                                   نشانی lines and the reversed table direction (known issue 24).
                                   RTL column order, the ZWNJ atom at 16pt bold in the draft
                                   band, the repeated header, the 2/2 footer, and a summary that
                                   reconciles with a pencil

Persian content sweep:      PASS   11 screens x 3 tiers, strings at the length real data reaches,
                                   over the real repositories -- no crushed text anywhere (D-065)
Component contrast:         PASS   every chip variant, both themes, both states, measured off the
                                   painted pixels: 6.3:1 to 11.4:1 (D-066). Verified to bite
Table minimum guard:        PASS   app_table_test.dart, one pixel either side of the threshold
Document line ladder:       PASS   4 rungs plus every threshold minus one (D-065)

Layout, all 3 tiers x 4 amounts (D-057) -- the phase-close check:
  widget sweep:             PASS   money_layout_test.dart (every fixed-width money site, plus the
                                   invoice list composed at each tier's real width with all four
                                   rungs on screen at once -- new in (f)),
                                   invoice_detail_screen_test.dart, invoices_screen_test.dart
  device - Android phone:   PASS   Redmi Note 8 Pro, 392.7 x 803.6, ratio 2.75
                                   **RE-RUN 2026-09-02 evening, after Phase 7 (c)** -- list,
                                   detail, form and settings, 0 layout errors on all four. The
                                   settings suite FAILED first and had to be fixed; the seller
                                   sheet (c) added is now covered, and its write reaches the real
                                   encrypted database. See the cable-session section.
                                   Previously (2026-09-01, Phase 6
                                   close). 0 layout errors on all four. The settings suite raises
                                   the real keyboard on both new sheets and reads the written
                                   settings back out of the real encrypted database.
                                   **RE-RUN after the D-065/D-066 fixes (2026-09-01)** and still
                                   0 errors. As predicted: the phone tier renders line cards
                                   rather than the table D-065 fixed, so neither defect could
                                   appear there -- but predicted is not measured, and now it is
                                   measured (D-064).
  device - Windows desktop: PASS   1264 x 681 (2026-09-01)
                                   list, detail and form suites. 0 layout errors on all three,
                                   and no crushed text -- the detector runs there too now (D-065).
                                   Re-run after the D-065/D-066 fixes.
                                   The FORM suite's first desktop run ever -- see D-064
  tablet tier:              widget sweep only. There is no tablet device; stated rather than
                                   implied, because a pass on one tier is a pass on one tier

Keyboard rule (D-062):
  widget sweep:             PASS   sheet_keyboard_test.dart, 255 px inset, verified to bite
  device - Android phone:   PASS   payment sheet and line editor: keyboard 254.9 of 803.6,
                                   action bottom 532.7, limit 548.7
                                   seller sheet (new 2026-09-02): keyboard 211.6 of 803.6, action
                                   bottom 576.0, limit 592.0 -- **16.0 pixels of margin**, tying
                                   the backup password sheet for the tightest in the application.
                                   Two sheets now sit on that number; D-072 called it the one to
                                   watch and it has not moved
                                   customer picker opened FROM the filter sheet (new in (f)):
                                   field bottom 265.0, limit 548.7 -- a modal route over a modal
                                   route, with the real keyboard up
  device - Windows desktop: degrades to "the action is on screen", by design. Not accepted in
                                   place of the phone run

D-020 proof - Android:      PASS   re-run on the Redmi (2026-09-01)
D-020 proof - Windows:      PASS   re-run 2026-09-01 (was 2026-08-23)
Startup proof - Android:    PASS   re-run on the Redmi (2026-09-01)
Startup proof - Windows:    PASS   re-run 2026-09-01
D-055 proof - Win/Android:  PASS   both ladders, v3 -> v4 and v1 -> v4 (2026-08-27)
D-052 proof - Win/Android:  PASS   both ladders, v2 -> v3 and v1 -> v3 (2026-08-27)
D-048 proof - Android:      PASS   (2026-08-27)
Web build:                  NOT_RETESTED since plugins were added -- Phase 12, known issue 14
```

**Test count is 1189** (Phase 7 (c)), was 1159 after (b), 1137 after (a), 1092 after Phase 6, 1004 then; 938 after (f), 935 after (e), 892 after (d) and the device pass, 861 after (c), 837 after
D-059, 794 at the end of (b) and 726 at the end of (a2).

## What the (d) cable session found — 2026-09-02, evening

The session the owner asked for: the cold start, the phone-tier save pass, and the Android leg of
the v5 proof, with the Redmi awake and unlocked. All three are done. It also found a regression and
retired a number.

### 1. The Android leg of the v5 proof — PASS, and it matches Windows exactly

`flutter test integration_test/seller_migration_proof_test.dart -d dmbyayb6rombo7ci`. Both ladders,
`v4 -> v5` and `v1 -> v5`, on an encrypted file through the real production bootstrap with foreign
keys on: `user_version` 4→5 and 1→5, one settings row, four nulls, the user's own `900`bp rate and
`FCT` prefix untouched, `file state : encrypted`, and the four columns written and cleared back
through the real repository. D-077's Windows result now holds on both targets.

### 2. The phone-tier device pass — and (c) had broken it

All four suites pass. Three passed unchanged; **`settings_device_test` failed on its first run**,
and that is the finding worth keeping, because Phase 7 (c) shipped it broken and nothing noticed.

(c) put the seller section at the **top** of the settings screen — deliberately, and correctly
(D-077: it is the one section every existing user has something to do in). Two consequences, both
invisible to `flutter analyze` and to the whole widget suite:

1. **«تهیهٔ پشتیبان» went below the fold** on the 803.6-pixel phone. The suite tapped it with a
   bare `find.text`, so the finder reported **absence, not invisibility**, and the run died at the
   tap. The control is perfectly reachable by scrolling — this is a **suite** that assumed the
   screen it was written against, not a product defect.
2. **There are now two `Icons.edit_outlined` on the screen**, the seller section's and the
   invoicing section's, so `find.byIcon(Icons.edit_outlined)` matches both and cannot say which
   sheet it opened. Fixed by finding on the tooltips, which are already distinct because a screen
   reader needs them to be — the finder now names the section rather than the glyph.

**And `reach` alone was not enough.** The first fix used `reach` and the tap still silently missed:
`reach` drags until the widget is *laid out* — a `ListView` child past the cache extent is not in
the tree at all — but laid out is not the same as inside the viewport. `ensureVisible` after it is
what puts it on screen. Both are now used, and the comment in the file says why they are different
questions, because the next person will otherwise delete one of them.

**The generalisation, which is D-064 again from a new direction.** D-064 says a phase closes only
after the device suites have run. The gap this found is narrower and sharper: **a suite is coupled
to the screen's layout, so an increment that changes the screen invalidates the suite even when it
changes nothing the suite asserts about.** (c) added a section and broke a suite that tests backups.
Nothing in (c)'s own verification would ever have looked there.

### 3. The seller sheet had never met a real keyboard — now it has

The suite was extended rather than only repaired, because (c) shipped a **fourth sheet** onto this
screen and D-062 applies to it exactly as to the other three. Its address field is `maxLines: 3`,
the tallest field any sheet in the application puts above its pinned action.

```
seller editor sheet: keyboard 211.6 of 803.6, action bottom 576.0, limit 592.0
seller write: reached the database, isPrintable=true
```

**16.0 pixels of margin** — the same number D-072 flagged on the backup password sheet, now tied by
a second sheet. It passes, and it is the number to watch if the seller field copy ever grows.

The suite also now asserts the **D-077 prompt behaves as a prompt**: «فروشنده» carries the
consequence sentence while the name is empty, and the sentence **goes away** once the name is
filled. A notice that stayed put after the user did the thing it asked for would train them to
ignore it.

The seller values used are Persian at the length real data reaches (§14) — a full two-line نشانی,
not «تست» — because the address is the field that was clipping mid-word on the printed page until
(c) caught it.

### 4. The cold start — and the recorded baseline is retired (D-078)

**The measurement, first:** HEAD `f71791c`, release arm64, `am force-stop` before each,
10 steady-state runs → **343 ms median** (317–395).

That is **4x faster than the recorded 1,401 ms baseline**, which is not a credible result for a
change that only *added* code. So it was controlled rather than reported: commit `60b5cd5` — the
exact commit the baseline was taken on — was checked out into a worktree, rebuilt, installed on the
same phone in the same session, and measured the same way.

| Build | Median of 10 steady-state runs | Range |
|---|---|---|
| `f71791c` (HEAD, after the PDF work) | **343 ms** | 317–395 |
| `60b5cd5` (the baseline commit itself) | **352 ms** | 345–366 |
| `60b5cd5`, **as recorded 2026-09-01** | **1,401 ms** | 1,330–1,465 |

**The baseline does not reproduce.** With the code held exactly constant, the same phone gives
352 ms today against 1,401 ms recorded. The 4x is in the measurement conditions of 2026-09-01, not
in the application — and the cause is **not established**. Storage was 96% full then and is 96% full
now; the app is AOT-compiled in a release build so Android dexopt does not explain it; the phone is
on USB power in both sessions. Saying "device conditions" names the category, not the cause, and it
should be read as *unexplained* rather than as *explained away*.

**What the conclusion now rests on.** Not the comparison against 1,401 — that comparison would have
produced the flattering and false claim that startup got four times faster. It rests on the
**paired** measurement: 343 vs 352, taken minutes apart on one phone, with overlapping ranges.
**The PDF work (a)+(b)+(c) costs nothing measurable at cold start.** That is the same shape of
correction as the APK-size one in (c): the number that flattered the conclusion was tested against a
control and reported as the weaker evidence it is.

**First launch is excluded from both figures** and varies far too much to compare: 2,495 ms,
4,597 ms and 9,029 ms across three fresh installs this session, against 3,440 ms recorded. It
carries dex optimization, encryption-key generation and database creation, and it happens once.

### 5. What this session did NOT do, so nobody records it as done

* ~~**Known issue 24 is untouched.**~~ **Done later the same evening** — see the section below.
* **The post-renderer size figure is still a floor.** Nothing reachable from `main()` imports
  `core/pdf/` yet, so there was nothing new to measure. It becomes real when (d)'s provider lands.
* ~~**`backup_gateway_save_test.dart` was not re-run.**~~ **Re-run and PASS** on the current build:
  the picker open in logcat, and 4,096 bytes landed in Downloads sha256-identical to the source.
* **No PDF is reachable from the application.** Unchanged from (c). That is all still (d).

## What followed the cable session, the same evening — issue 24, and two corrections

### Known issue 24: fixed at the source, not by reversing the list (D-079)

The plan said to reverse `lineColumns` and the cell list together. **The owner overruled that**, and
the reason is the one that matters: a table that produces correct output because its columns were
handed over backwards is a trap for the next person who adds a column.

`pw.Table` places column 0 at the left and walks rightwards — `Table.layout` starts at `x = 0.0` —
and neither `Table` nor `TableRow` takes a `textDirection`; `Directionality` above them changes
nothing. That was **verified in `pdf` 3.13.0's own source**, not inferred from behaviour. So the
package genuinely cannot honour it, and the reversal has to live somewhere.

It now lives in **`rtlTable`** (`lib/core/pdf/rtl_table.dart`). Callers pass rows **and**
`columnWidths` in **reading order**; the wrapper reverses both. That last word is the point:
`columnWidths` is index-keyed, so a hand-reversed cell list needs a hand-reversed width map kept in
step with it — two reversals that must agree with nothing checking that they do, and a disagreement
**mislabels** every column instead of merely reordering them, which is worse than the original fault.
Ragged rows and partial width maps are **assertions**, for the same reason.

The party blocks moved onto it too. They carried the same trap in a milder form: correct output from
a source that read *"Buyer, gap, seller — left to right on the page"*.

**Read off the rendered page**, which is the whole point given D-076 recorded this order as verified
after looking at a page where every column was plausible where it sat:

```
ردیف · شرح · تعداد · قیمت واحد · مبلغ کل · جمع سطر     (right to left)
فروشنده on the right, خریدار on the left
```

### D-072's 16 pixels were never margin, and the number now governs every sheet

Four sheets report the same keyboard slack — payment, line editor, backup password, seller — all
exactly **16.0**. Four coincidences is not an explanation. `EditorSheet` pads below its action by
`AppSpacing.lg`, which is 16, inside a `SafeArea`.

So D-072's reading was wrong twice over: it is not margin, and **copy growth cannot eat it** — the
primitive caps the field area and scrolls it while the action stays pinned. The number moves only if
the primitive or the spacing token changes.

Both keyboard guards now assert the action clears the keyboard by **at least `AppSpacing.lg`**,
naming the primitive's constant rather than a literal — which is what "put the number where it
governs both" resolves to once you know what the number is. A floor rather than an equality, because
gesture navigation adds bottom safe area and more clearance is never the defect. **Verified to bite:**
at twice the floor, five of six sheets fail; the picker, outside `EditorSheet` by design, passes.

### And a new finding on the same page — known issue 25

`multipage.pdf` is the *"enough lines to need a second page"* fixture, and **all 28 rows fit on page
1**; page 2 carries only the totals. So the lines table has never spanned a page break in any
fixture, and its header is `repeat: false` — a table that did span would lose its headings.

D-076 recorded "the repeated header" as read off rendered pages. It appears once because the table
appears once. That is the same failure as the column order, on the same page, found the same way, and
it is worth saying plainly: **three separate claims in D-076 came from looking at one page and
finding it plausible.**

Left open deliberately. `repeat: true` is one word and untestable until a fixture actually spans, so
the fixture comes first and the two go together.

## What Phase 7 increment (c) delivered — schema v5, and the block that was not there

**Read `docs/DECISIONS.md` D-077 first.** An invoice with no seller is not an invoice: the user
cannot hand it to a customer, which made the whole phase undeliverable. The owner ruled that this
outweighed the risk of a schema change with two days left.

### The shape

```
settings.seller_name         TEXT(160) NULL     SellerLimits.name
settings.seller_economic_id  TEXT(20)  NULL     SellerLimits.economicId
settings.seller_address      TEXT(500) NULL     SellerLimits.address
settings.seller_phone        TEXT(20)  NULL     SellerLimits.phone
```

`SellerIdentity` (`data/models/`) carries them as one value; `AppSettings.seller` is **never null and
often empty**, so no read path has a "configuration missing" case. `migrateV4ToV5` is four
`_addColumnIfAbsent` calls and a `foreign_key_check` — **no backfill, no `withDefault`**.

### The two rulings, and where each lives

| | ruling | enforced by |
|---|---|---|
| empty seller, on the page | **no block at all** — never a heading over blanks, which reads as data that *failed* to print. The buyer block widens to the full page | `_seller()` returns null; `_parties()` falls back to the full-width buyer |
| empty seller, on issuing/printing | **blocks nothing.** The user's document, their call | nothing; `InvoiceDocumentView.seller` carries the fact so (d) can say something non-blocking |
| being surprised by it | **impossible** — the settings screen carries the seller section **first**, with one sentence naming the consequence, and the sentence goes away once the name is filled | `settingsSellerConsequence`, hung off the name row |
| details with no name | **not a block with a gap in it.** «فروشنده» over a کد اقتصادی alone identifies nobody | the form requires a name once anything else is filled — reported, never clamped; the builder re-checks `isPrintable` |

### `SellerIdentity` is a value object because `copyWith` cannot clear a field

The one thing here that is easy to miss. With `String? sellerName` on `AppSettings`,
`copyWith(sellerName: null)` is indistinguishable from *leave it alone* — so a user who emptied the
name would have the old one **written straight back, silently**, and would find out on the next
document they printed. Replacing the whole object makes clearing ordinary. Pinned at the column, on
the VM and on Windows.

### What the pixels caught, and no test did

Third increment running. Both looked fine in the source and in review.

1. **Every party نشانی overflowed its block and was clipped mid-word** — «...پلاک ۴۵۶، واح».
   `_field` was a `mainAxisSize: min` row with no flexible child, so the value took its intrinsic
   width and spilled: **no overflow, no error, no failing test**. Invisible while the buyer block
   had the full 531 pt; it appeared the instant the block had 261.5. Same class as D-065's
   21.6-point column. Fixed with a `fill` flag that puts the value in an `Expanded` — default off,
   because the header number and the meta dates sit beside a `Spacer` and must take their natural
   width.
2. **`pw.Table` lays column 0 out at the LEFT even under `textDirection: rtl`.** The first attempt
   declared the seller first, meaning the right-hand side, and printed it on the left — where it
   looks entirely deliberate. Now declared buyer-then-seller. **This is also why D-076's claim about
   the lines table is wrong**, and it is known issue 24.

### Two layout facts worth not rediscovering

* **`pw.Row` + two `Expanded` + `crossAxisAlignment: stretch` = an unbounded height**, and
  `MultiPage` refuses the page: *"Widget won't fit into the page as its height (Infinity) exceed a
  page height"*. `package:pdf` has **no `IntrinsicHeight`**. The pair is a one-row `pw.Table` with
  `TableCellVerticalAlignment.full` and fixed column widths.
* **The party block width is declared and asserted**, not left to `Expanded`: 261.5 pt, checked
  against a fourteen-digit کد اقتصادی beside its label. D-065's lesson is that a block laid out too
  narrow renders one glyph per line and reports nothing.

### The APK size correction

**Do not repeat "byte-identical".** (c) reproduces arm64 21,653,926 exactly — and so does a
deliberate throwaway change to a reachable widget, which changed `libapp.so`'s content hash
(`a4c8c84f…` → `e0256500…`) while leaving its size at 7,078,792. The figure is **quantised** by page
padding in the AOT snapshot and alignment padding in the zip. The floor claim holds on the **import
graph** — nothing reachable from `main()` imports `core/pdf/` — not on the number.

## What Phase 7 delivered so far — (a) and (b), 2026-09-02

**Read `docs/DECISIONS.md` D-073 through D-076 before touching any of this.** The two faults it
works around are silent and produce output that looks correct, so code that looks obviously fine is
the normal case here.

### The two faults, because everything in `core/pdf/` is shaped by them

| | the font fault (D-073) | the shaper fault (D-070 finding 1) |
|---|---|---|
| characters | U+200C ZWNJ and friends — **mapped, but the glyph is empty** | U+2068/U+2069 — **not in the `cmap` at all** |
| what happens | `TtfParser.readGlyph` never checks `loca[i] == loca[i+1]`, so it returns the **next glyph's** outline. U+200C draws a Latin **`à`**, at zero advance width, so nothing about the layout looks wrong | the run silently loses its **last character** — a ten-digit کد ملی prints nine and still looks like a کد ملی |
| the remedy | **cut** the run there; the character meant something | **delete** it; the document has no use for it |
| lives in | `core/pdf/safe_text.dart` | `core/pdf/document_text.dart` |

Neither remedy fixes the other's fault. Cutting at a U+2068 would break a join that must not break;
deleting a U+200C yields «پیشنویس», a misspelling.

### What exists

```
lib/core/pdf/
  font_glyph_safety.dart    pure Dart, no Flutter. Parses head/maxp/loca/cmap/hhea out of the
                            bundled font and DERIVES which runes select an empty glyph. Eleven of
                            them in Vazirmatn, not the four every write-up had named.
  document_text.dart        DocumentText + DocumentTextBoundary. The only way to obtain text the
                            renderer accepts -- SafeText takes nothing else.
  safe_text.dart            SafeText. Cuts at the join-breakers, emits the affected WORD as an
                            indivisible WidgetSpan atom so a line break cannot land inside it.
  document_typeface.dart    the two faces plus both safety layers, derived from the same bytes.

lib/features/invoices/document/
  invoice_document_view.dart          the view model: DocumentText and nothing else
  invoice_document_view_builder.dart  InvoiceDetail + AppStrings -> the view
  invoice_document_generator.dart     the interface §12 asks for, and its failure type
  pdf_invoice_document_generator.dart the one template
```

**The flow is one-way and every step drops something.** `InvoiceDetail` (models, `Money`,
`DateTime`) → builder (formats once; every decision made here) → `InvoiceDocumentView`
(`DocumentText` only) → generator (layout only). The renderer never sees a `Money`, so it **cannot**
recompute a total; never sees a raw `String`, so it **cannot** print an `à`. Both are type-level
rather than conventions.

### The guards, and what each is for

* `test/core/pdf/font_glyph_safety_test.dart` — the class guard, with **three** controls: it finds
  a non-empty set (a silent parse failure would clear every string), it agrees with `package:pdf`'s
  own parser on all **811** runes that parser maps, and it asserts **the bug still exists**, so a
  future `pdf` release that fixes `readGlyph` fails the suite rather than leaving a workaround
  nobody can explain.
* `test/core/pdf/arb_document_text_sweep_test.dart` — every ARB entry (**68 of 356** carry a
  control), both directions: that they really are unsafe as written, and that nothing but the
  control is lost.
* `test/core/pdf/document_text_test.dart` — drives the **real** §9 formatters
  (`formatIdentifierForDisplay`, `isolate`) rather than imitating their output.
* `test/features/invoices/document/invoice_document_view_test.dart` — the figures are the **stored**
  ones at every ladder rung, no value contains its own label, the declared table geometry.

### How to look at a page — do this, do not reason about layout

Rendering is local; no browser is involved and none is needed.

```bash
flutter test test/features/invoices/document/   # writes build/document_pages/*.pdf
dart run tool/render_document_text.dart         # writes build/document_text/*.pdf
```

```powershell
tools\pdf_raster\rasterize.ps1 -Pdf build\document_pages\issued_ceiling.pdf -Out out.png -Width 1700
tools\pdf_raster\inkcrop.ps1   -In out.png -Out crop.png      # crop to the ink, to read glyphs
tools\pdf_raster\region.ps1    -In out.png -Out band.png -X 0 -Y 0 -W 1700 -H 1250
tools\pdf_raster\pxdiff.ps1    -A before.png -B after.png     # what actually changed
```

`pdf_raster` uses `Windows.Data.Pdf`, which ships with Windows 10 — nothing to install. **Read the
pixels, not the content stream.** That rule has caught something every single time it was applied
in this phase, including twice where three readings of the source had missed it.

### What has been read off the pixels, and passed

Ladder ceiling (۱۰۰٬۰۰۰٬۰۰۰ تومان) and all four rungs · a draft with its band · a pre-snapshot
invoice with its one factual line · 28 lines over two pages, with the repeated header carrying the
invoice number and a `2 / 2` footer · RTL column order · the ZWNJ atom at 16 pt bold, which is the
largest type the document sets · a summary that reconciles with a pencil.

### Two things the pixels corrected that no test had caught

Recorded because both looked fine in code review:

1. The **`مبلغ کل` column printed bare digits** between two columns carrying «تومان» — a type error
   in the view model, not a layout bug. `gross` was a `DocumentText` because the «ثبت‌نشده» case
   made a bare string look reasonable while writing it.
2. The **demonstration invoice did not reconcile.** Nothing was wrong with the renderer, which is
   the problem: a page that cannot be checked with a pencil is one where a real reconciliation
   defect would look like more of the same.

### Environment notes that will otherwise cost a fresh session an hour

* **`flutter pub get` hangs.** This shell has `PUB_HOSTED_URL` pointing at a mirror whose cache does
  not hold `pdf`. Use `unset PUB_HOSTED_URL; flutter pub get --offline` — the packages are already
  in `~/AppData/Local/Pub/Cache/hosted/pub.dev/`. Then run `sh tools/sanitize_lockfile` (D-014).
* **A bundle size taken without `flutter clean` is not a measurement.** `flutter build` does not
  clean its output directory, and a stale `data/flutter_assets/kernel_blob.bin` from an earlier
  debug build is **87 MB** — it read 120 MB before the clean and 33 MB after.
* `flutter analyze <directory>` analyses only that directory and will report clean while the
  package does not compile. Run it bare.

## What the two post-close fixes delivered — D-065, D-066, D-067

**Two visual defects reported off the Windows build**, both invisible to every check the project had,
and both fixed where the rule lives rather than at the call site.

```
lib/core/widgets/app_table.dart              TableColumnSpec.fixed / .flexible; tableMinimumWidth;
                                             the header's guard
lib/core/theme/app_dimensions.dart           + tableMinTextWidth, tableMinValueWidth
lib/core/theme/app_theme.dart                the chip label/background pairs, state-resolved
lib/features/invoices/.../invoice_document_lines.dart  the degradation ladder
lib/features/{customers,products,invoices}/…  four tables declare their column floors
lib/core/localization/arb/app_fa.arb         + invoiceLineLabelUnitPrice
test/support/text_fit.dart                   NEW  expectNoCrushedText + PersianFixtures
test/features/persian_content_sweep_test.dart NEW  11 screens x 3 tiers, real Persian
test/core/theme/component_contrast_test.dart NEW  pixel-sampled WCAG contrast
test/core/widgets/app_table_test.dart        NEW  the guard, either side of the threshold
test/features/invoices/invoice_document_lines_test.dart NEW  the ladder, rung by rung
test/features/screen_harness.dart            loadPersianFont() -- every widget test, real font
integration_test/device_assertions.dart      + expectNoCrushedText
integration_test/*_device_test.dart          all three run it; the detail fixture got a long title
```

### The table: 21.6 pixels, and no error of any kind

The document table's description column was **21.6 logical pixels** at every desktop width — Persian
one glyph per row, vertically — because three fixed money columns take 732 of the 768 the table is
composed into beside the detail panel. **`Expanded` is a tight fit**, so the flexible column was handed
what was left, which was nothing, and laid out successfully. No overflow. No error. The device suite
for that exact screen reported 0 layout errors, truthfully.

D-058 had done exactly the right sum against exactly the wrong number: 1144, the *full* content
column, in a file whose own doc comment quotes §10's rule about composed width.

**Fixed structurally** (D-065): a flexible column cannot be declared without a `minWidth` — D-043's
required-parameter shape, for D-043's reason — the header asserts the total once per table, and the
document table **drops a money column into a labelled detail line** rather than crushing its prose.
Horizontal scrolling and row wrapping were both considered and refused, with reasons. Making the
parameter required immediately surfaced the other four tables, none of which was crushed and none of
which could have said so.

### The chips: not a wrong token, an absent one

`chipTheme.labelStyle` named no colour, and `RawChip` uses the theme's style *instead of* its
state-dependent default rather than merging over it — so labels were painted with the engine's
fallback white, at **1.12:1** on the light theme. Dark mode looked fine, which is why it survived; the
checkmark was correctly coloured, which is why it looked plausible.

**And `ChoiceChip` reads its selected label from `secondaryLabelStyle`**, so fixing `labelStyle` alone
left a selected chip in dark at **3.75:1**. Only the pixel check found that. One shared resolver feeds
both now; all ten combinations sit between 6.3:1 and 11.4:1.

### What was added, since nothing caught either

- **`expectNoCrushedText`** — a `RenderParagraph` narrower than its own `getMinIntrinsicWidth` cannot
  place its longest word, so it breaks *inside* the word. That is "renders vertically", stated so a
  machine can check it anywhere in any tree. In the widget harness **and** in the device suites.
- **The Persian content sweep** — every screen, every tier, strings at the length real data reaches,
  over the real repositories. The answer to "what else" is a check that looks everywhere rather than a
  list of places to go and look. **It found nothing further.**
- **The contrast test**, pixel-sampled, over every chip variant in both themes and both states.
- **Vazirmatn in widget tests** (D-067). Until now no widget test in this project had ever rendered in
  the real font, and the first crushed-text run reported three false positives from glyph metrics 40%
  too wide. Loading it broke none of the 940 tests that existed.

### Both new checks are verified to bite

Forcing the old table shape, the **Windows device run** reports the description at **9.6 px needing
62.7** and the quantity at **2.4 px** — from the suite that used to say "0 layout errors" about that
frame. Restoring the old `chipTheme` fails four of the ten contrast cases at 1.12:1 and 1.26:1.

**68 new tests; 1004 pass.**

## What Phase 5 increment (f) delivered — the phase close, and the fault it found in an old check

**No feature.** (f) is the verification pass and the paperwork; a phase close that grows a feature is
a phase that has not closed. **D-064.**

```
integration_test/invoice_list_device_test.dart   NEW  the list, its filters, and the picker they open
integration_test/invoice_form_device_test.dart   made tier-aware; the tap aims at the control
test/core/widgets/money_layout_test.dart         + the invoice list at three tiers, every rung
docs/                                            ROADMAP, DECISIONS (D-064, D-063 amended),
                                                 ARCHITECTURE, CURRENT_STATE
```

### The gap (e) named, closed

`integration_test/` had two suites — the invoice form and the invoice detail screen — and the
**list** had neither. Everything (e) built had been checked at three tiers in widget tests and had
never rendered in Vazirmatn on a phone. The new suite seeds through the real repositories into the
real encrypted database, so every assertion about what a filter returned is an assertion about what
came back from a `WHERE` clause:

- **The customer filter**, chosen through the real picker, narrows the list to one invoice and the
  other customer's five are **gone**, not further down the page.
- **The period filter** excludes an invoice issued a Jalali year earlier under «این ماه».
- **A narrowing that matches nothing** shows the filtered empty state, offering «پاک کردن همه» — and
  «هنوز فاکتوری ثبت نشده» is asserted **absent**, because it would be a lie told to a user with six
  invoices in the database.
- **The count on the control** is asserted through `formatGroupedPersian`, not as a written-out
  «۱ فیلتر فعال», so it keeps meaning something if the formatting changes.
- **The keyboard rule, in a sheet opened from a sheet.** The picker is a modal route over a modal
  route; `raiseKeyboard` raises the real keyboard and the search field is asserted inside what it
  leaves. Redmi: keyboard 254.9 of 803.6, field bottom **265.0**, limit 548.7.

It passed on the Redmi first try, and on Windows, with 0 layout errors on both.

### And the invoice list joined the ladder sweep

The list had a tier sweep that rendered **no money** ("what varies across tiers is where the control
sits") and money assertions at a **single** magnitude. Two half-checks: a card that fits at 1,200,000
تومان and breaks at 100,000,000 passes both. `money_layout_test.dart` now composes the whole screen at
each tier's real width with **every rung on it at once**, and asserts each rung was actually laid out
rather than merely handed to the repository.

### The part worth keeping: the old suite failed at a tier it had never seen

`invoice_form_device_test.dart` had run on the Redmi for two phases and **never on Windows**. Pointed
at the desktop tier it failed on its **first measurement**, and none of it was a product defect:

1. **`find.text(invoiceLineAddFromCatalogue)` matched nothing.** `_DesktopLayout` is a single
   `ListView` whose second child is the entire lines section; at a 1264 × 681 window that child sits
   past the cache extent and is **not in the tree**. Absence, not invisibility — D-062 §2 exactly, one
   file away from the suite D-062 was written about.
2. **It measured D-054's phone fold at every tier.** The wider tiers fold nothing, so it was about to
   print a fold measurement for a layout that has no fold — a device report about a screen that does
   not exist.
3. **A tap aimed at a floating label, not at the control.** `tap(find.text(invoiceFieldIssueDate))`
   warned "would not hit test on the specified widget" and opened the picker **anyway**, because the
   label sits inside the same `InkWell` as the `InputDecorator` under it. It worked by geometry, in
   green, for two phases — a hit-test warning does not fail a run.

All three corrected, plus a `_rewind` helper, because `_scrollTo` only ever searched **downwards** and
the desktop tier parks the page below the fields once a line is added. The suite passes on both
targets now, with the phone's D-054 numbers unchanged: 586 / 670 / fits, 245 unfolded.

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
# Every one of these runs on BOTH targets, and a phase closes only after it has (D-064).
flutter test integration_test/invoice_list_device_test.dart   -d dmbyayb6rombo7ci
flutter test integration_test/invoice_detail_device_test.dart -d dmbyayb6rombo7ci
flutter test integration_test/invoice_form_device_test.dart   -d dmbyayb6rombo7ci
flutter test integration_test/d020_encryption_proof_test.dart -d dmbyayb6rombo7ci
flutter test integration_test/startup_test.dart               -d dmbyayb6rombo7ci
# ... and the same five with `-d windows`, which is the desktop tier.

# adb is NOT on PATH, and Git Bash mangles device-side paths without the prefix.
ADB=%LOCALAPPDATA%/Android/Sdk/platform-tools/adb.exe
"$ADB" devices -l
# Empty list, but Get-PnpDevice shows an "ADB Interface" (MI_01)? Stale daemon,
# not the phone. Known issue 22:
"$ADB" kill-server; "$ADB" start-server; "$ADB" devices -l
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

| 23 | **Drift warns "you've created the database class AppDatabase multiple times" during an export** | Debug builds only. An export legitimately holds two `AppDatabase` instances — the live one and the container — and drift's warning is about two instances sharing **one `QueryExecutor`**, which these do not: they are two different encrypted files. Harmless, and deliberately not silenced with `dontWarnAboutMultipleDatabases`, because that flag is global and would hide a real instance of the problem elsewhere. |
| 22 | **`adb devices` can come up empty while the phone is plainly enumerated** | Seen 2026-09-01 at the start of (f). Windows had **both** interfaces present — `USB\VID_2717&PID_FF48&MI_00` (WPD) and `&MI_01` (**ADB Interface**) — and `adb devices` still listed nothing. `adb kill-server && adb start-server` fixed it in one go. **Do not read this as the MTP-only symptom** the Next Action section describes: that one shows a *single* WPD entry and no ADB interface, and no restart helps it. Check `Get-PnpDevice` for the `MI_01` ADB interface first; if it is there, restart the daemon rather than touching the phone. |

| 24 | ~~The printed lines table runs its columns in the wrong direction for an RTL reader~~ | **Resolved 2026-09-02 (D-079)**, and not by the one-line reversal the plan proposed — at the owner's direction. `pw.Table` places column 0 at the left and takes no `textDirection` (verified in `pdf` 3.13.0's source), so the reversal now lives in **`rtlTable`** (`lib/core/pdf/rtl_table.dart`) and every caller declares columns in **reading order**. Handing `pw.Table` a backwards list would have produced a correct page from a source that traps the next person to add a column — and `columnWidths` is index-keyed, so it would have been two hand-reversals that must agree with nothing checking they do, mislabelling every column when they drift. The party blocks moved onto it too, having carried the same trap. **Read off the rendered page**, not the source: ردیف · شرح · تعداد · قیمت واحد · مبلغ کل · جمع سطر, right to left. |
| 25 | **The lines table has never crossed a page break, and its header would not repeat if it did** | Found 2026-09-02 while reading the page for issue 24 (D-079). `multipage.pdf` is the *"enough lines to need a second page"* fixture and all **28 rows fit on page 1** — page 2 carries only the totals. So no fixture has ever spanned the table, and the header row is `repeat: false`, meaning a table that did span would lose its headings on the second page. **D-076 recorded "the repeated header" as read off rendered pages**; the header appears once because the table appears once, which cannot distinguish the two behaviours. Deliberately not fixed in passing: `repeat: true` is one word and untestable until a fixture actually spans, so the fixture comes first and the two go together. |

| 26 | **Crushed Persian text at two width bands, found by the width sweep and NOT fixed** | Found 2026-09-02 by adding `expectNoCrushedText` to `width_sweep_test.dart`. Both are the silent class D-065 exists for — laid out narrower than the longest word, no overflow, no error. **Exactly two strings, identified:** (a) the `/invoices/:id` page title **«فاکتور ⁨INV-1405-0001⁩»** at widths **328, 352, 376** — laid out at 115/139/163 px against 169.6 needed. The unbreakable token is the bidi-isolated invoice number; the title row's status chip and menu take the rest. Below any common phone (the Redmi is 392.7), so it is small phones and Android split-screen. (b) the invoice editor's **«پیش‌فرض فاکتور»** at **616–688** — 37.5–57.5 px against 59.9. «پیش‌فرض» carries a ZWNJ so it is one unbreakable token. That band is a reachable desktop window and a landscape phone, so **fix (b) first.** **Deliberately not fixed**: two layout changes on the last day with no time to check them on a device is the wrong trade against a defect that renders text badly rather than showing a wrong figure — and a permanently red test trains people to ignore red, so the check is not committed either. **To reproduce:** in the sweep's per-width block, when `caught.isEmpty`, call `expectNoCrushedText(tester, where: ...)` and import `../support/text_fit.dart`. |
| 27 | ~~A draft invoice cannot be deleted from the interface~~ | **Resolved 2026-09-02** (commit `dc537d6`), before the owner's device report and therefore not present in the build they tested. The menu item sits beside the export; the confirmation names the two things deleting does not cost. Five tests. |
| 28 | **There is no app lock** | the project spec specifies an optional PIN and biometric unlock with an idle timeout; `lib/core/security/` contains only the logger and the key manager, and `local_auth` is not a dependency. Encryption at rest protects the file, not a running app on an unlocked device — so of §7's two headline threats, "lost or stolen device" is only half covered. Nominally Phase 9/10, both `DEFERRED_INDEFINITELY` (D-068). Stated here because the threat model claims more than the build delivers, and §7 requires that gap to be written down rather than implied. |

| 29 | ~~A saved draft cannot be edited~~ | **Resolved 2026-09-03** (D-084). «ویرایش پیش‌نویس» in the draft's menu reopens it at `/invoices/:id/edit`; `save` calls `updateDraft` rather than `create`. The editing id is carried on `InvoiceEditorState` rather than in the provider's family key, so it survives the rebuild a settings change causes — which would otherwise have turned an edit into a second invoice silently. Four tests against the real database. Editing an *issued* invoice remains impossible, which is §6, not a gap. |

| ~~30~~ | **DONE 2026-09-03 — and re-opened and closed properly the same day (D-096).** The D-093 fix below was the third of three that moved this control without taking it out of the scroll; it is now pinned above the scroll and cannot move again. Historical record follows. **(D-093.)** Adding a line on the new-invoice screen competed with the pinned bar and left the widget tree once the details section was opened. D-086 took the smallest of its three candidates and measured the rest; **candidate 1 is now taken**: on the phone the lines section sits **above** the details section, which is §10's own rule (a variable-height block above the thing the page is for belongs below it) applied a fourth time. Above the fields, add-line cannot leave the first screen, because the section that grows is the one underneath it. The customer stays visible in the collapsed details heading, so «مشتری را انتخاب کنید» still points at something reachable. Kept in this table struck through rather than deleted, so the history of the three attempts reads straight. |

(5 and 7 were resolved in (f2) and have been dropped.)

**24 is resolved (D-079)** — the printed table now reads in the Iranian order, and the fix is a
wrapper rather than a reversed argument list, so adding a column is writing it where it reads.
**25 is new, from the same page**, and is the only open entry a user could notice: it costs nothing
today, because no invoice yet produced spans the table across a page.

Every other entry is either resolved (1, 10b, 16, 17, 18, 19, 20, 21), a deliberate design ruling
(3, 8), a development-environment condition invisible in a shipped build (10, 11, 12, 22, 23), or
scheduled work on a surface the phase plan already owns (2 and 4 → Phase 13; 9 → Phase 12; 13 →
Phase 15; 14 → Phase 12; 15 → Phase 9). **6 is resolved** — settings became editable in Phase 6 (d)
and the row renders a Jalali date, with a test.

## Important context for a future session

- **A flexible table column cannot be declared without a `minWidth`, and a table that cannot meet the
  total changes shape rather than crushing a column** (D-065). `Expanded` is a *tight* fit: a flexible
  column handed nothing is laid out successfully at nothing, with **no overflow and no error**, and
  Persian then renders one glyph per row. `AppTableHeader` asserts the total once per table;
  `InvoiceDocumentLines` drops a money column into a labelled detail line instead. **Never widen a
  minimum to make the assertion pass** — that is the defect with a bigger number on it.
- **A widget measured at its own full width has not been measured at the width it is composed into**
  — §10's rule, and D-058 broke it *in the file that quotes it* by checking against 1144 when the table
  gets 768 beside the detail panel. When a widget sits next to a fixed-width panel, do the subtraction.
- **A component's foreground and background are named together, as a pair** (D-066). A `TextStyle` in
  a component theme that names no colour does **not** inherit the framework's default — Material
  replaces its default with yours — so the label paints with the engine's fallback white. And
  `ChoiceChip` reads its *selected* label from `secondaryLabelStyle`, not `labelStyle`: fixing one and
  not the other leaves a state at 3.75:1 that reads fine in every token-level check.
- **`expectNoCrushedText` is the detector for this whole class** — text laid out narrower than its own
  longest word. It lives in `test/support/text_fit.dart` and is duplicated into
  `integration_test/device_assertions.dart` (which cannot import from `test/`). Add a new screen to
  `persian_content_sweep_test.dart` rather than writing a per-screen version.
- **Widget tests render in Vazirmatn now** (D-067) — `pumpScreen` loads the real font. The old caveat
  that "a fixed-width column passing a widget test has margin in the shipped layout" is retired: the
  measurements mean what they say. A *minimum*-width check was impossible before this, because the
  fallback font's glyphs are ~40% wider and the false positives are indistinguishable from real ones.
- **Test fixtures use Persian at the length real data reaches** (`PersianFixtures`). A four-character
  title fits anywhere and proves nothing — the same small-test-data mistake D-057 wrote the amount
  ladder about, in the other dimension.
- **Every device suite runs on every target, and the phase close is what runs it there** (D-064).
  `invoice_form_device_test.dart` ran on the Redmi for two phases and had never been pointed at
  Windows; the first time it was, it failed on its first measurement, because the desktop layout is
  one lazy `ListView` whose lines section is past the cache extent and therefore **not in the tree**.
  A suite that has only seen one target is evidence about one target — D-057's sentence with "tier"
  replaced by "target". Both targets, every suite, output in this file.
- **Where a measurement belongs to one tier, say so and skip it elsewhere.** D-054's fold is a phone
  ruling; printing a fold measurement for a layout with no fold is a device report about a screen
  that does not exist, and it reads as evidence.
- **A tap names the control, never its label.** `tap(find.text(invoiceFieldIssueDate))` opened the
  date picker by geometry — the floating label sits inside the same `InkWell` as the decoration — and
  warned "would not hit test on the specified widget" without failing anything. `JalaliDateField`
  carries the `onTap`, so it is what gets tapped. A hit-test warning is not a failure, so this kind
  of thing stays green until the decoration is restyled.
- **`_scrollTo` and `reach` only search downwards.** Anything needing a widget *above* where the last
  step left the page has to rewind first — on the desktop tier a field scrolled past is not merely off
  screen, past the cache extent it is out of the tree, and searching further down would never end
  anywhere useful.
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

### Phase 7 increment (c) — schema v5 and the seller block, the newest work

```
lib/data/models/seller_identity.dart                     NEW  the value object, and why it is one
lib/data/models/field_limits.dart                        MOD  SellerLimits
lib/data/models/app_settings.dart                        MOD  seller, non-null, often empty
lib/data/database/tables/settings.dart                   MOD  four nullable seller_* columns
lib/data/database/app_database.dart                      MOD  schemaVersion 5, migrateV4ToV5
lib/data/repositories/drift/drift_settings_repository.dart MOD  maps them; normalizes blanks to null

lib/features/settings/presentation/widgets/seller_editor_sheet.dart  NEW  the sheet, and the one rule
lib/features/settings/presentation/settings_screen.dart  MOD  the seller section, FIRST on the screen

lib/features/invoices/document/invoice_document_view.dart          MOD  seller, nullable
lib/features/invoices/document/invoice_document_view_builder.dart  MOD  _seller(); isPrintable decides
lib/features/invoices/document/pdf_invoice_document_generator.dart MOD  _parties(); _field(fill:)

lib/core/localization/arb/app_fa.arb                     MOD  +15 entries (13 settings, 2 document)
lib/core/localization/generated/                         GEN  flutter gen-l10n
drift_schemas/drift_schema_v5.json                       NEW  schema dump
test/data/database/generated/schema_v5.dart              NEW  drift_dev schema generate output

test/data/database/seller_identity_migration_test.dart   NEW  9 tests, both ladders + the absences
test/data/database/invoice_figures_migration_test.dart   MOD  asserts db.schemaVersion, not a literal
test/features/settings/settings_screen_test.dart         MOD  +5 seller tests; reach() for the fold
test/features/settings/settings_editing_test.dart        MOD  +6 seller-sheet tests; byTooltip
test/features/invoices/document/invoice_document_view_test.dart   MOD  +7 seller tests, +block width
test/features/invoices/document/invoice_document_render_test.dart MOD  +2 pages, the seller fixture
integration_test/seller_migration_proof_test.dart        NEW  the device proof; Windows PASS

The project spec                                                MOD  §14: the fixture-consistency rule
docs/DECISIONS.md                                        MOD  D-077
docs/ROADMAP.md                                          MOD  (c) COMPLETED, its security note
docs/CURRENT_STATE.md                                    MOD  this file; known issue 24
```

### The two post-close fixes — the newest work

```
lib/core/widgets/app_table.dart              two constructors; tableMinimumWidth; the guard
lib/core/theme/app_dimensions.dart           + tableMinTextWidth, tableMinValueWidth
lib/core/theme/app_theme.dart                chip label/background pairs, state-resolved
lib/features/invoices/presentation/widgets/invoice_document_lines.dart  the ladder
lib/features/customers/presentation/customers_screen.dart      column floors
lib/features/products/presentation/products_screen.dart        column floors
lib/features/invoices/presentation/invoices_screen.dart        column floors
lib/features/invoices/presentation/widgets/invoice_lines_section.dart   column floors
lib/core/localization/arb/app_fa.arb         + invoiceLineLabelUnitPrice
test/support/text_fit.dart                   NEW
test/features/persian_content_sweep_test.dart NEW
test/core/theme/component_contrast_test.dart NEW
test/core/widgets/app_table_test.dart        NEW
test/features/invoices/invoice_document_lines_test.dart NEW
test/features/screen_harness.dart            loadPersianFont()
test/core/widgets/money_layout_test.dart     TableColumnSpec.fixed
test/features/invoices/invoice_detail_screen_test.dart  the crushed-text group
integration_test/device_assertions.dart      + expectNoCrushedText
integration_test/invoice_{list,detail,form}_device_test.dart  run it
```

### Phase 5 increment (f) — the phase close, the boundary before it

```
integration_test/invoice_list_device_test.dart   NEW  the list, its filters, and the picker they
                                                      open under the keyboard rule
integration_test/invoice_form_device_test.dart   tier-aware; the tap aims at the control; + _rewind
test/core/widgets/money_layout_test.dart         + the invoice list at three tiers, every rung
docs/ROADMAP.md                                  Phase 5 COMPLETED; the (f) entry and its numbers
docs/DECISIONS.md                                + D-064; D-063 amended with the owner's ruling
docs/ARCHITECTURE.md                             the integration_test listing, which was stale
docs/CURRENT_STATE.md                            this file
```

### Phase 5 increment (e) — the boundary before it

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

**Two visual defects reported off the Windows build, fixed with the checks that would have caught
them (D-065, D-066, D-067).**

- **The invoice document table's description column was laid out at 21.6 logical pixels** on every
  desktop width, rendering Persian vertically — with **no overflow and no error**, which is why 935
  tests and a device suite reporting "0 layout errors" all missed it. Fixed in the primitive: a
  flexible column must declare a `minWidth`, the header asserts the total, and the document table
  drops a money column into a labelled detail line rather than crushing its prose.
- **Chip labels were painted with no colour at all**, falling through to the engine's white at
  **1.12:1** on the light theme. Fixed by pairing foreground and background as state-resolved tokens —
  in `secondaryLabelStyle` as well, because `ChoiceChip` reads its selected label from there and
  fixing only `labelStyle` left dark-selected at 3.75:1.
- **Four checks added and one harness change**: `expectNoCrushedText` (widget *and* device), the
  Persian content sweep over 11 screens x 3 tiers, a pixel-sampled contrast test over every chip
  variant, the ladder pinned rung by rung — and **Vazirmatn in widget tests** (D-067), without which
  the crushed-text detector produces three false positives for every real one.
- **Both new checks verified to bite.** The sweep found nothing further.
- **66 new tests; 1004 pass.** Analyzer clean; all three device suites re-run green on Windows.
- **Owed:** the Android phone run. The Redmi was physically disconnected before the fixes were
  finished.

**The boundary before it — Phase 5 increment (f), the phase close (D-064). Phase 5 is `COMPLETED`.**

- **The owner accepted all five outstanding boundaries** — (b), the known-issue-19 fix, (c), the
  device pass and keyboard rule (D-062), and (e) — so nothing is awaiting review.
- **The invoice list has device coverage for the first time**, on both targets, including the
  customer picker opened from inside the filter sheet with the real keyboard up (field bottom 265.0
  against a limit of 548.7 on the Redmi).
- **The list joined the ladder sweep at all three tiers**, composed at each tier's real width with
  every rung on screen at once — it previously had a tier sweep with no money in it and money
  assertions at one magnitude.
- **The form suite failed at the desktop tier, which it had never been run at**, on three counts,
  none of them a product defect: a finder reporting absence rather than invisibility past a lazy
  list's cache extent, a phone-only fold measurement taken at every tier, and a tap that hit its
  target by geometry. All three corrected; both targets green, phone numbers unchanged.
- **D-064 recorded**: every device suite runs on every target, and the phase close is what runs it
  there. **D-063 amended** with the owner's ruling that «سررسید گذشته» stays out of the filter set.
- **3 new tests; 938 pass.** Analyzer clean, Android debug APK builds, 0 layout errors on every
  device run at both tiers.

**The boundary before it — Phase 5 increment (e), filters in SQL and a paged customer list (D-063).**

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

**And the one before that — known issue 21 and the keyboard rule (D-062).**

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

**All of the above has since been reviewed and accepted by the owner** (2026-09-01), and (f) closed
the phase over it. There is no work in progress, nothing uncommitted and no open question: the next
session starts cold at the Next Action below.

## Next action

> **Nothing is half-finished and no question is waiting on an answer.** The owner's twelve-item list
> is delivered in full; the gate is clean at 1,269 tests and both artifacts are built.

**The single specific next action: install the profile APK on the phone and check the two
Android-only behaviours nothing here could verify.**

> **These two are the first things to check, and neither is assumed working.** They are not known
> broken; they are **unproven on hardware** — Dart-tested through the real dispatcher, Kotlin
> compiled and present in the built APK, and never once run on a device. Do not read a green suite
> as covering them. Everything else in the owner's twelve was seen working, either on Windows or in
> a rendered page.

The APK is `build/app/outputs/flutter-apk/app-profile.apk`, and a copy is at
`%USERPROFILE%\Desktop\Factorino-test\factorino-arm64.apk`. In this order, because the first
is the one that can make the whole application feel broken:

1. **The back gesture.** From the dashboard, one press should show «برای خروج، دوباره بازگشت را
   بزنید» and a second within 2.5 s should leave. From anywhere else it should return to the
   dashboard. From the invoice form with a customer or a line entered, it should ask before
   discarding. `back_policy_test.dart` drives the real `BackButtonListener` through the platform's
   own `popRoute` message, so the plumbing is tested — the **gesture** on hardware is not, and
   D-095 records why nested listeners were rejected in case the behaviour surprises.
2. **«باز کردن» on the PDF message.** Save an invoice, then tap the action on the confirmation. It
   goes through a method channel in this application's own `MainActivity` (D-091) — no package, no
   `FileProvider` — and issues `ACTION_VIEW` on the SAF URI with a read grant. If nothing happens,
   the Persian line «برنامه‌ای برای باز کردن فایل PDF پیدا نشد» is the expected answer on a phone
   with no PDF viewer; silence is not, and would mean the intent did not resolve.

Then, still on the phone, the three that were designed against measurements taken there but built
without one: the invoice form's new order (issue 30 / D-093), the navigation bar's five labels at
the real Persian widths (D-088), and whether the tab-switch flash is actually gone (D-089 diagnosed
it from the mechanism, not from a captured frame).

After that, the standing list is unchanged:

1. **Create a release keystore and sign a build** — `docs/RELEASE.md` has the exact commands. Still
   the only irreversible decision left, and still ahead of anyone installing anything they intend to
   keep. (A **profile** APK needs no keystore, which is why this session could produce one.)
2. **Decide about the app lock (known issue 28).** The difference between "the data is encrypted"
   and "the data is safe on a lost phone".
3. **Known issue 26** (crushed Persian at two width bands) and **25** (the lines-table header on a
   second page), in that order. Note that 26's first band — the `/invoices/:id` title at 328–376 —
   was **not made worse** by this session: D-094 deliberately put the PDF button in the header row
   rather than the title row for exactly that reason.

Read `docs/HANDOVER.md` before any of it.

*Historical — the previous next action, now done:*

**~~Run the phone-tier device pass over the export action.~~**
`invoice_export_test.dart` drives the *controller* on both targets; nothing has yet driven the
**menu item** on a phone — tapping «ذخیرهٔ نسخهٔ PDF» in the title row, and reading the snackbar and
its «تنظیمات» action against a real layout. That is the D-057/D-062 gap this increment opened, and
it is the same shape as the one (c) opened and (d)'s cable session found: **an increment that
changes a screen invalidates the suite for that screen.** `invoice_detail_device_test.dart` is the
file. Note the save dialog itself cannot be tapped by `adb` under MIUI, so the suite should stop at
the point the picker opens, exactly as `backup_gateway_probe_test.dart` does.

Then: known issue 25 (a fixture that actually spans a page, and `repeat: true` with it), and the
phase close.

*Historical — the previous next action, now done:*

**~~Phase 7 (d) step 1 — the provider.~~** A provider that loads the
Vazirmatn faces from `rootBundle` into a `DocumentTypeface`, builds the view from the
`invoiceDetailProvider` the detail screen already watches **and the `appSettingsProvider` seller**,
and renders. Note `buildInvoiceDocumentView` takes `seller:` and defaults it to
`SellerIdentity.none` — a call site that forgets it produces a document with no seller block and no
error, so wire it deliberately. **Take the real size figure immediately after this lands**: it is the
moment `core/pdf/` first becomes reachable from `main()`, and the first moment the number means
anything.

**The rest of Phase 7 (d) — make the document reachable.** In this order:

0. ~~**Known issue 24 first.**~~ **DONE 2026-09-02 (D-079).** The original wording is kept below
   for the record; it proposed the one-line reversal the owner rejected. What was built instead is
   `rtlTable`. Historical text follows: The
   printed lines table runs its columns in the reverse of the Iranian reading order — ردیف at the
   far left, جمع سطر at the far right — because **`pw.Table` lays column 0 out at the LEFT even
   under `textDirection: rtl`**. (c) hit the same mechanism on the party blocks and corrected it
   there; the lines table was left alone because it is an accepted increment and was outside (c)'s
   scope. The fix is to reverse `lineColumns` **and** the cell list in `_lines` **together** — one
   without the other silently mislabels every column, which is far worse than the current fault —
   and then **read the rendered page**, not the source. D-076's write-up claims this already came
   out right; it does not.
1. A provider that loads the Vazirmatn faces from `rootBundle` into a `DocumentTypeface`, builds the
   view from the `invoiceDetailProvider` the detail screen already watches **and the
   `appSettingsProvider` seller**, and renders. Note `buildInvoiceDocumentView` takes
   `seller:` and defaults it to `SellerIdentity.none` — a call site that forgets it produces a
   document with no seller block and no error, so wire it deliberately.
2. An action on `/invoices/:id` that saves the file — reusing the **D-071 backup gateway**, which
   already solves exactly this on both targets (`ACTION_CREATE_DOCUMENT` on Android,
   `file_selector_windows` on desktop) and is already proven with a confirmed save on each.
3. **The non-blocking notice for an empty seller.** D-077 ruled that printing is never blocked, and
   that the user must not be able to be *surprised*. The settings screen covers the user who goes
   looking; this is the other half — `InvoiceDocumentView.seller == null` is the fact to check, at
   the moment of printing, once, without stopping anything.
4. **The §7 question (d) owns and (b) deliberately did not touch:** a generated PDF holds full
   customer and financial data. Where it lands, whether a temporary copy exists, and who deletes it
   are this increment's decisions, and the ROADMAP security note for Phase 7 already names them.
5. **The cable work — THREE OF FOUR ITEMS ARE DONE (2026-09-02 evening).** Read
   `## What the (d) cable session found` for the detail. Status:
   - the **Android cold start** — **TAKEN**, 343 ms median on HEAD. And the recorded 1,401 ms
     baseline is **retired**: it does not reproduce on its own commit (D-078). Quote the paired
     343-vs-352 comparison, never the 1,401;
   - the **phone-tier device pass** — **DONE**, all four suites, 0 layout errors. It found and
     fixed a regression (c) had shipped into `settings_device_test`, and it now covers the seller
     sheet, which had never met a real keyboard;
   - the **Android leg of the v5 migration proof** — **PASS**, both ladders, matching Windows;
   - the **real size figure** — **still owed, and still cannot be taken.** D-074's +133 KB is a
     floor, and the floor claim holds on the **import graph** rather than on the number:
     21,653,926 is a *size*, it is quantised, and it does not distinguish changes of this
     magnitude. It becomes measurable the moment step 1 lands and `core/pdf/` is reachable from
     `main()` for the first time — so **take it right after the provider**, not before.

   One cable item is deliberately unexercised: `backup_gateway_save_test.dart` needs a human to tap
   the Android save dialog, since MIUI refuses `adb` input injection. It is PASS from D-071 and
   nothing this session touched the gateway.

### The commits this work sits on, newest first

| commit | what |
|---|---|
| **`35e581a`** | Phase 7 (d): the provider, the save action, the §7 artifact ruling and the real size figure (D-080) |
| `f5430ad` | Issue 24 fixed at the source — `rtlTable`; D-072's 16 pixels corrected; known issue 25 (D-079) |
| `a111fa6` | The (d) cable session: the three Android measurements, the settings-suite regression (c) shipped, and the retired cold-start baseline (D-078) |
| `cc5c639` | Phase 7 (c): schema v5 and the seller block; the two rulings; known issue 24 (D-077) |
| `0436094` | Phase 7 (b): the invoice prints — the view model, the generator interface, the one template (D-075, D-076) |
| `47beb6e` | Phase 7 (a): the `pdf` dependency and the text layer that makes it safe (D-074) |
| `b4465a7` | The ZWNJ cause found, and `tools/pdf_raster/` so the page is visible from the terminal (D-073) |
| `49f3812` | The superseded ZWNJ diagnosis — kept for the record, **wrong in its cause**; read D-073 |
| `75f7b7a` | The guard audit and its corollary (D-072) |

### What is deliberately NOT built, so nobody builds it twice

* **No document is reachable from the application.** No provider, no button, no file written. That
  is all (d).
* **No seller block**, pending the decision above. Not an oversight and not a `TODO`.
* **No `DocumentField` rendering helper beyond the one inside the template.** Rule 2's other half
  landed with the template rather than as a shared widget, because a field widget with no second
  document to sit in is the speculative abstraction §15 forbids.
* **No PDF preview screen, no share sheet, no print dialog.** Not in the reduced plan (D-068).

### The Phase 6 close, 2026-09-01

**All four device suites pass on the Redmi**, after (d):

| Suite | Result |
|---|---|
| `settings_device_test` (new) | **PASS** — 0 layout errors, real keyboard up, write reaching the real encrypted database |
| `invoice_form_device_test` | **PASS** — 0 layout errors |
| `invoice_list_device_test` | **PASS** — 0 layout errors |
| `invoice_detail_device_test` | **PASS** — 0 layout errors |

Re-run because (d) changed `AppTextField`, which every form in the application uses.

**And the close found two things in its own guard — D-072.**

1. **A password field raises a bigger keyboard than an ordinary one**: **284.0** logical pixels
   against 254.9, a different IME layout. The widget guard had been checking that sheet against the
   friendlier number. It passes either way — action at 503.6 against a limit of 519.6, **16 pixels of
   margin** — and that margin is the number to watch if the §8 warning copy ever grows.
2. **The inset was never what made the check bite.** Raising it does not fail the assertions: the
   backup password sheet passed against an invented 560-pixel keyboard, because `EditorSheet` puts
   the `viewInsets` padding inside its own height cap and lands the action on top of whatever
   keyboard exists **by construction**. So the file was measuring a property it could not fail, and
   every assertion in it would have gone on passing if `EditorSheet` itself regressed. It now carries
   a **negative control** — a sheet built the way the defect was, asserted to put its action below the
   fold — the same both-directions design as `gateway_boundary_test.dart`.

**Why that run is not optional here.** D-068 reduced this phase's device pass to the phone tier at one
large amount, and reduced nothing else — the **keyboard rule is explicitly not among the reductions**,
and a backup password field in a sheet is exactly what D-062 was written for. The Windows run below
reports `keyboard 0.0`, which is the degraded form D-062 refuses to accept in its place.

### What (d) delivered

**1092 tests, was 1068** (+24); analyze clean.

**Settings is editable, and that is a defect fix rather than a feature.** §4 requires the VAT rate to
be configurable and never hardcoded; it was hardcoded at whatever the database was seeded with. The
work belonged to no phase, which is how the scope cut would have made it permanent (D-068). The rate,
the invoice prefix and the payment term are editable, and **every bound is reported rather than
clamped** — `AppSettings` deliberately does not clamp (D-052), so the form is the only thing between a
mistyped digit and an invoice due before it was issued. Zero days is **allowed**: paid-on-delivery is a
real term, and a bound of "positive" would have refused most workshops.

**The rate is shown in the unit the user thinks in.** 900 basis points is «۹», not «۹۰۰» — and the
conversion back goes through `tryParseScaledInput(scale: 100)` rather than a `double` multiplication,
because a tax rate is on the money path and there is no floating point on it (§4).

**Backup is reachable, in both directions.** Export asks for the password **twice**; restore asks
once, because a typo there costs a second rather than a file that can never be opened. The §8 warning
sits **above** the fields rather than under them, so it reads as a condition of the task instead of
small print. The password is returned **exactly as typed** — not trimmed, since a trailing space is
part of it (pinned in both the widget test and the container test).

**The restore confirmation names what will be lost**, replace-not-merge first (D-069), and describes
**the file** — counts and creation date read out of a container already opened, its password accepted,
its version checked and its counts verified. `inspect` runs before the dialog for exactly that reason:
the numbers on screen are the file's, not a hope about it.

**`markBackedUp` runs only after the file is actually delivered**, not after it is written. A reminder
that reset itself when the user opened the save dialog and thought better of it would say a backup
exists when none does.

**Known issue 6's first half is closed**: the last-backup row goes through `formatJalaliDateLong` and
would otherwise have rendered «۱٬۷۵۶٬۰۰۰٬۰۰۰٬۰۰۰» the moment `lastBackupAt` stopped being null — which
until this increment nothing could make happen.

**Two shared pieces grew rather than being worked around.** `AppTextField` gained `obscureText`,
because `field_limit_path_test` forbids a raw `TextFormField` and is right to: a password field that
skipped the shared component would also skip the length validator, and would be the precedent for the
next field that skipped them. `formatJalaliDateForFileName` is new and is the one place a Jalali date
is written in **Latin** digits — a file name travels into file managers, cloud drives and Windows
dialogs, where Persian digits sort unpredictably and are awkward to type months later. The date is
still Jalali, which is the part the user recognises.

### Verification for (d)

| Check | Result |
|---|---|
| `flutter analyze` | PASS |
| `flutter test` | PASS 1092/1092 |
| Keyboard rule, widget sweep | PASS — both new sheets at the measured 255 px inset |
| Settings editing, widget | PASS 11 — bounds refused and **nothing written** on refusal |
| Backup flow copy, widget | PASS 11 — warning, ask-twice, mismatch, not-trimmed, replace-not-merge |
| Device — **Windows** | PASS — 0 layout errors, no crushed text, and the edit **reaches the real encrypted database**: term 60, rate 850bp read back out of it |
| Device — **Android phone** | **OWED.** Windows reports `keyboard 0.0`; D-062 does not accept that for the keyboard rule |

### What is deliberately not covered by an automated run

Taking a **real** backup end to end from the screen opens the system save dialog, which needs a tap no
automated run on this device can supply while MIUI refuses input injection. That link is proved
separately and byte-for-byte in `integration_test/backup_gateway_save_test.dart` (D-071), on both
targets. The device suite stops at the password sheet and says so.

### What (c) delivered — import, and what every refusal leaves behind

**1068 tests, was 1052** (+16); analyze clean.

**Two phases, and the boundary between them is the whole design.** `importFrom` opens the container,
identifies it, version-checks it and counts it — **before a single row of live data is removed**.
Only then does it read everything out of the container, and only then does the live transaction open.
Reading the container **before** the transaction is deliberate: interleaving two databases inside one
transaction would let a read failure on the backup abort a live transaction already half-way through
deleting the user's data.

**The rollback is tested by failing, not only by succeeding.** The container is made genuinely
invalid in a way that bites *part-way through* — two issued invoices sharing one number, which the
live unique index refuses — so by the time it fails, `customers` and `products` have already been
deleted and reinserted. The live database comes back **row-for-row identical**. Writing that test
turned up something reassuring: the container carries the same unique index, so it refused the
duplicate too, and the index had to be dropped **inside the container** first.

**Refusals, each asserting what it left behind** — the Phase 5 (c) pattern:

| Refusal | Problem | Live data |
|---|---|---|
| Wrong passphrase | `cannotOpen` | unchanged |
| Tampered byte | `cannotOpen` — **deliberately the same case** | unchanged |
| A keyed database that is not a backup | `notABackup` | unchanged |
| Newer app schema version | `fromNewerVersion` | unchanged |
| Newer container format version | `fromNewerVersion` — checked separately | unchanged |
| Counts disagreeing with contents | `countMismatch` | unchanged |
| Empty passphrase | `BackupPassphraseRejected` | unchanged |

A wrong password, a corrupt file and a tampered file are **one case on purpose**: SQLCipher
authenticates the page and cannot tell them apart, so splitting them would mean guessing, and the
guess would be a claim about the user's file that nothing supports. The Persian copy therefore names
both plausible remedies rather than one.

**Version compatibility both ways.** Downward through the **real ladder**: the container is opened as
an `AppDatabase`, so drift runs the same `onUpgrade` steps the application runs — tested by building
an actual v3 container with the generated `DatabaseAtV3` and restoring from it. Upward it is refused,
with copy that says *update the app* rather than failing generically.

**Every Persian body states that the existing data is untouched**, because that is the thing the user
most needs to know and cannot check for themselves.

**Also pinned:** a tombstone restores as a tombstone, settings restore without defaults being reseeded
over them, and an import **replaces rather than merges** — the behaviour the confirmation copy
promises.

**And a restore is a decrypt under one key and a re-encrypt under another**, now stated rather than
implied (D-069, owner's question). The backup is keyed by the **user's password**; the live database
by **this device's key** in `flutter_secure_storage`. So the password never becomes the database key,
and the device key is never written into a backup — which is what lets a backup be restored onto a
device that has never seen the original, and why there is deliberately no mechanism to move a device
key anywhere.

### The device session, 2026-09-01 — all five owed items cleared

The Redmi Note 8 Pro was connected and **every owed device item ran**. Nothing is owed on hardware
any more except the one thing no automated run can do, named at the end.

| # | Owed item | Result |
|---|---|---|
| 1 | `invoice_list` device suite, post-D-065/D-066 | **PASS**, 0 layout errors |
| 2 | `invoice_detail` device suite | **PASS**, 0 layout errors |
| 3 | `invoice_form` device suite | **PASS**, 0 layout errors |
| 4 | Backup container proof on Android (D-069) | **PASS 5/5**, sqlite3 3.53.4, same as Windows |
| 5 | Phase 7 cold-start baseline | **taken** — see below |

**The D-065/D-066 fixes changed nothing on the phone tier**, as predicted and now measured: the phone
renders invoice lines as cards rather than as the table D-065 fixed. The detail suite's ladder still
reports `100000000 تومان : unrecorded figures shown = true` at the top rung, which is the pre-v4
«ثبت‌نشده» path behaving correctly, not a regression.

**Known issue 10 recurred once**, on the second suite of the run: `INSTALL_FAILED_USER_RESTRICTED`
followed by `DELETE_FAILED_INTERNAL_ERROR` on the cleanup. Its documented remedy worked first time —
`adb install -r` by hand, then retry.

**Phase 7 cold-start baseline**, release build (`app-arm64-v8a-release.apk`, 21,520,524 bytes),
`am force-stop` before each, on commit `60b5cd5` — **before any PDF dependency**:

| Run | TotalTime |
|---|---|
| 1 | **3,440 ms** — first launch after install: dex optimization, encryption-key generation and database creation all land here |
| 2–5 | 1,401 · 1,465 · 1,363 · **1,330 ms** |

~~**Take 1,401 ms as the baseline**~~ — **WITHDRAWN 2026-09-02, D-078.** This figure does not
reproduce. The same commit, rebuilt from a worktree and measured on the same Redmi in the same
session as HEAD, gives **352 ms** median of ten. Nothing may be compared against the number above;
the reasoning about keeping run 1 separate still stands, and is applied to the paired measurement
that replaced it. See `## What the (d) cable session found`.

### The Android save dialog — the link the owner most wanted tested

**It opens, and it is the right intent.** Proved on hardware by reading it out of `dumpsys` while the
picker was in the foreground:

```
act=android.intent.action.CREATE_DOCUMENT cat=[android.intent.category.OPENABLE]
cmp=com.google.android.documentsui/com.android.documentsui.picker.PickActivity
```

SAF create-document, **not** a share intent — the exact property D-071 chose the package for,
demonstrated rather than argued. Cancelling returns `false`, so a cancellation reads as the ordinary
outcome it is rather than as a failed backup. `lib/data/backup/backup_file_gateway.dart` is the real
gateway, not a probe, so (d) inherits tested code.

**Two findings from doing it:**

1. **`adb shell input keyevent` is refused on this device** — *"Injecting to another application
   requires INJECT_EVENTS permission"*, because MIUI gates simulated input behind its **USB debugging
   (Security settings)** toggle. `am force-stop com.google.android.documentsui` cancels the picker
   just as well and changes no device setting.
2. **`flutter_file_dialog` has a stated expiry.** The build warns that it applies the Kotlin Gradle
   Plugin and that *"future versions of Flutter will fail to build"* apps using such plugins. It
   builds today. It is a **dated dependency**, which raises the value of the fallback D-071 already
   specified — app-external storage via `path_provider`, no dependency and no permission — and the
   gateway interface is what makes that a one-file change if it comes to it.

**The completed save is now proved too, on both targets** (2026-09-01, owner tapped through it).
`integration_test/backup_gateway_save_test.dart` is **interactive on purpose** and is not part of any
suite — MIUI refuses `adb` input injection, so no automated run can supply the tap.

| Target | Result |
|---|---|
| Android, Redmi | Saved to Downloads, pulled back: **4,096 bytes, byte-identical** |
| Windows | Saved via `file_selector_windows`: **4,096 bytes, byte-identical** |

Compared against a generated pattern (`(i * 7 + 13) % 256`), not zeroes, so a truncated or empty
write could not pass by looking plausible. **Nothing in the chain a user walks is now unexercised.**

**And the dated dependency has a review trigger and a guard**, not just a caveat (owner). The
trigger: **the first Flutter upgrade that warns more loudly or fails.** At that point, check whether
the author migrated to Built-in Kotlin; if not, take the fallback — app-external storage via
`path_provider`, no dependency, no permission, the user finding the file rather than choosing where
it lands. What makes that a one-file change is `test/data/backup/gateway_boundary_test.dart`, which
fails if anything in `lib/` outside the gateway imports `flutter_file_dialog` or `file_selector` —
and *also* fails if the gateway stops importing them, so it cannot pass vacuously after a rename.

### What (b) delivered — export in the data layer

`lib/data/backup/backup_service.dart`. **1050 tests, was 1015** (+35); analyze clean.

**The verification reopen is in the service, not in a test** (owner, 2026-09-01). `exportTo` writes
the container, closes it, **reopens it cold with the password the user typed**, and compares the
`backup_table_counts` rows against both what was written *and* a fresh `count(*)` over each table —
so a stale count row cannot agree with itself into a pass. Only then does it return a `BackupSummary`.
Any failure deletes the file: **a partial backup is worse than none, because it looks like a backup.**

**A backup carries tombstones.** `_copy` is marked `soft-delete-exempt` with the reason: a backup that
filtered `deleted_at is null` would resurrect every deleted customer and invoice on restore, and would
hand the future sync layer a device whose deletions never happened. Tested directly.

**The container is the app's own schema.** It is opened as an `AppDatabase`, so `onCreate` builds the
tables at `schemaVersion` and the migration ladder is available to it — which is what makes an older
backup migrate itself on open in (c). The seeded settings row is **cleared before the copy**, or a
restore would quietly reset the user's VAT rate to the default.

**Passphrase characters, end to end** —
`test/data/backup/backup_passphrase_characters_test.dart`, 24 tests. Every one writes a real container
and reopens it: apostrophe (one, several, and alone), double quote, backslash, backslash-before-quote,
Persian digits, Arabic-Indic digits, ZWNJ, Persian script with spaces, leading/trailing/both-end
spaces, `'; drop table customers; --`, `%` and `_`, emoji, and a 200-character passphrase. Plus six
**must-not-open** cases pinning that a trailing space, a leading space, a ZWNJ, Persian-vs-Latin digits
and Arabic-vs-Persian digits are **not** folded together — §9's digit normalization is mandatory for
numeric input and would be a **defect** applied to a password.

### Two guard tests fired, and both were right

- **`soft_delete_usage_test`** caught four raw reads. All four are legitimate — the container's own
  `backup_meta` and `backup_table_counts`, which have no `deleted_at`, plus a `select 1` that forces
  decryption — and each now carries its reason. The count query's reason matters: it **must** include
  tombstones, or verification would disagree with what was written and fail every export from a
  database that has ever had a row deleted.
- **`single_open_path_test`** flagged `backup_service.dart` for the key pragma's literal name, which
  appeared only in a **doc comment**. The comment was reworded rather than the scanner loosened, and
  the file says why: the guard is worth more strict than that sentence was worth verbatim.

### Deferred out of (b), deliberately

- **The Riverpod provider** for `BackupService` lands in (d) with the screen that needs it. Adding it
  here would have meant a `build_runner` pass for a provider nothing yet watches.
- **The gateway packages** likewise (D-071): they are chosen and they resolve, and nothing needs
  delivering until there is a screen.

See "What (a) delivered" below for the container proof and what it left owed.

### What (a) delivered

**The container works, and it is proved rather than asserted.**
`integration_test/backup_container_proof_test.dart`, **5/5 passing on Windows** (sqlite3 3.53.4):

| Question | Result |
|---|---|
| Is the file encrypted on disk? | **Yes** — 8,192 bytes, no plaintext SQLite header, and the sentinel national-ID stand-in is **absent from the raw bytes** |
| Does the right passphrase reopen it and return the data? | **Yes** |
| Does a passphrase differing by one character fail? | **Yes** — `SqliteException` **at open**, and the file is left byte-for-byte intact |
| Does a tampered byte fail authentication? | **Yes** — `SqliteException`, so the per-page HMAC D-069 relies on is doing what D-069 assumes |
| Is an empty passphrase refused before a file exists? | **Yes** (after a fix — see below) |

Plus `test/data/database/backup_container_setup_test.dart`, 11 unit tests over the statement list and
the quote escaping. **Test count is 1015**, was 1004.

**The passphrase-keyed opener lives in `encrypted_database.dart`, the same file as the live one.**
Exactly one file in `lib/` may open a database (`single_open_path_test.dart`), and putting the second
opener anywhere else would have meant loosening the check that makes D-020 structural rather than
remembered. It differs from the live opener in one way only: the key is a **passphrase**, so
sqlite3mc runs its SQLCipher KDF, where the live database passes `x'..'` raw because its key comes
from the platform keystore and must not be stretched.

**The proof caught a real defect on its first run, which is why it exists.** `NativeDatabase`'s
`setup` closure is **lazy** — it runs on first use of the connection, not at construction — so the
empty-passphrase guard, living inside `setup`, did not fire when the executor was built. A caller
could hold an apparently-valid executor for an empty passphrase, and the file would be created before
anything refused. An empty key produces an **unencrypted** database under SQLCipher semantics, so
this was the one outcome a backup may never have. The validation is now eager, before the executor is
constructed.

**`pragma key` cannot take a bound variable** — pragmas are not parameterizable in SQLite — so the
passphrase reaches SQL through `escapeSqlStringLiteral`, and that is the reviewed exception D-018
allows for. Getting it wrong would not be a syntax error but a **data-loss bug**: the file would be
keyed with a string other than the one the user typed and would refuse that password on restore. The
proof's passphrase carries an apostrophe deliberately. The standing mitigation, for (b): **an export
is not reported successful until the finished file has been reopened with the same passphrase.**

**The gateway is chosen — D-071.** Windows uses `file_selector` for both directions; Android uses
`file_selector` to open and **`flutter_file_dialog`** to save, because `file_selector_android`
implements only `openFile`, `openFiles` and `getDirectoryPath` — read from its source, not assumed.
`share_plus` was rejected for the save: a share intent is a new outbound data surface for the most
sensitive artifact the app produces. Both packages resolve here (`pub add --dry-run` against
`https://pub.dev` directly, since the mirror is flaky again — known issue 11). **The packages are not
yet added to `pubspec.yaml`**; that lands in (b), where something actually needs delivering.

### What (a) leaves owed

- **The Android container proof.** The suite has run on Windows only. D-064: a target with no run is
  a target with no evidence.
- **The Android save dialog**, never raised on real hardware.
- Both want the same cable as the three device suites owed since D-065/D-066 and the Phase 7
  cold-start baseline. **One session with the phone connected clears all five.**

### What (a) delivers, and nothing more

1. **The container proof**, `integration_test/`, on **both** targets, in the D-020 style: write a
   password-keyed sqlite3mc container, close it, then reopen it (i) with the right password —
   succeeds; (ii) with the **wrong** password — fails cleanly, not a crash, and before any data is
   touched; (iii) with **a byte flipped** — fails page authentication.
2. **The file gateway probe**, which is the real unknown. Windows has `getSaveLocation`.
   **`file_selector_android` does not implement it** — verified in its source at
   `flutter/packages`, where the Android class implements only `openFile`, `openFiles` and
   `getDirectoryPath`. The Android answer is one of, in this order of preference:
   `flutter_file_dialog`'s SAF create-document (keeps the file on the device), `share_plus` (a new
   outbound data surface the security note must then account for), or app-external storage via
   `path_provider` as the zero-dependency floor.
3. **A decision entry** recording which gateway won and why.

No UI, no repository wiring, no product code path in (a).

### DONE before (a): the Phase 7 entry gate and the shaping probe

Both were approved to happen ahead of Phase 6 and **both have run**.

**The baseline, on `60b5cd5`** — the commit before any PDF dependency:

| Measurement | Value |
|---|---|
| Android APK, arm64-v8a, release | **21,520,524 bytes** (armeabi-v7a 19,096,744; x86_64 23,138,664) |
| Windows release bundle, total | **32,876,606 bytes** over 17 files |
| Android cold start | **TAKEN 2026-09-02, and the stored baseline retired (D-078)** — HEAD 343 ms against the baseline commit's own 352 ms, measured paired |

**The shaping probe: Phase 7 is viable — D-070.** `pdf` 3.13.0 with `bidi` 2.0.13 over bundled
Vazirmatn shapes and joins Persian, lays out RTL, renders Persian digits and U+066C, and places a
Latin invoice number correctly inside an RTL sentence **with no isolation marks at all**. It ran in a
throwaway package in the scratchpad, so the dependency **never entered `pubspec.yaml`** and the
baseline above still sits on a PDF-free commit.

**Three findings, and the first one reaches back into code that already exists:**

1. **U+2068/U+2069 must never reach the renderer.** Absent from Vazirmatn's `cmap` (checked, not
   assumed), and the shaper **eats the last character of the isolated run** — a national ID printed
   nine of ten digits, silently, and plausibly. **This application already wraps invoice numbers,
   phones and national IDs in those controls for the Flutter UI**, where they are correct and
   required by §9. The PDF view-model boundary must strip them, with a test.
2. **A number containing spaces or a `+` scrambles** — `+98 912 123 4567` rendered as
   `۴۵۶۷ ۱۲۳ ۹۱۲ ۹۸+`. Needs an explicit LTR `Directionality`. An unbroken digit run needs nothing.
3. **ZWNJ draws a box**, and it is **not** the font: U+200C is in the `cmap` at glyph 322 and the join
   around it already breaks correctly. Deleting it is not the fix — that joins «پیشنویس» across a
   boundary that must not join. **The first thing Phase 7 fixes**, a correctness item under D-068.

**The owner reviewed the rendered pages and found the part that matters most:** the ZWNJ box appears
in the probe's **own section heading** — «نیم‌فاصله» printed «نیم▯فاصله». So it is in the
application's **own ARB strings**, not only in test data or customer input: «پیش‌نویس»,
«پرداخت‌نشده», «وب‌سایت» are all already shipped. A document with boxes through its own labels is not
deliverable, so this is the **highest-priority item in Phase 7, ahead of layout**. The remedy must
preserve the join break (verified on the rendered page, ش final and ن initial), must be tested over
**every** ARB entry containing U+200C rather than over examples, and must not be mistaken for a fix to
finding 2.

**And the print contract is settled, by measurement (probe 3).** The tempting default — "LTR
`Directionality` everywhere, no control characters" — is **wrong and destructive**. Thirteen field
shapes were rendered bare and wrapped: the wrapper is a **no-op** on every field a document actually
prints (invoice number, national ID, economic ID, phone in all three forms **including the spaced
`+۹۸` one**, Jalali date, amount, percent, negative amount, parenthesised number) and it **reverses
any Persian inside it** — «فاکتور» becomes «روتکاف», «تومان» becomes «ناموت».

The contract is two structural rules with no per-field special-casing: **(1) no control characters
reach the renderer**, stripped at the view-model boundary with a test; **(2) the label and the value
are separate widgets, never one string.** Rule 2 is what makes the phone-scrambling finding disappear
rather than need a remedy — probe 2 scrambled `+۹۸ ۹۱۲ ۱۲۳ ۴۵۶۷` only because the value shared one
`Text` with «تلفن: », and alone in its own cell it is correct.

### Still owed, from before the cut

**With the cable back in: re-run the three device suites on the Redmi.** They have not run on the
phone since the D-065/D-066 fixes. Neither defect is expected there — the phone tier renders invoice
lines as cards rather than as a table, and the chip fix is tier-independent — but "not expected" is
not a run (D-064). The five cold starts for the Phase 7 baseline can be taken in the same session.
`adb devices` empty with an ADB interface present means a stale daemon (known issue 22), not a bad
cable.

### What Phase 6 has to deliver, from §8, so the split is not re-derived

1. **Export** — a full backup file to a user-chosen location.
2. **Encrypted with a user-supplied password**, key derived through a KDF and never used raw. Met by
   the container's SQLCipher-compatible PBKDF2-HMAC-SHA512 at 256,000 iterations (D-069). The UI must
   say in Persian that losing the password loses the backup.
3. **A format version and an integrity check.** `backup_meta.format_version` plus the container's
   per-page HMAC-SHA512, with **row counts per table** as a separate logical completeness check.
   **No whole-file HMAC is added on top, and that is a decision, not an omission** — a second check
   over the same bytes can disagree with the first, and then import has to decide which to believe
   (D-069).
4. **Import is transactional**: it either fully succeeds or leaves the existing data untouched.
5. **A last-backup date in settings**, through `formatJalaliDateLong` (known issue 6).
6. **And settings becomes editable in (d)** — a defect fix, not a feature. §4 requires the VAT rate to
   be configurable and never hardcoded; it is hardcoded at the seeded default today, and a business on
   a different rate hits it on its first invoice with no recourse. Prefix and payment term come with
   it, the term **bounded** (D-052).

**Deferred by §8 and not to be built now:** scheduled backups, CSV export, cloud backup.

### The three constraints that apply from the first line of code (D-069)

- **Nothing about a backup is logged** — not the password, not the destination path, not a row count
  that implies how much business the user does.
- **The container is built in app-private storage and deleted on every exit path**, including the
  failing ones.
- **The import confirmation states in Persian that existing data is replaced, not merged.** A user
  who expects a merge and receives a replacement loses everything entered since the backup, and has
  no reason to expect it — "restore" implies addition to most people. Copy with the weight of a
  data-loss guard.

### The close-out standard for this phase, reduced on purpose

Phone tier, one large realistic amount (D-068) — **not** the D-057 three-tier four-rung sweep, and
**not** D-064's every-suite-every-target. Two things are not reduced: the **keyboard rule** (D-062),
and the **correctness tests**, which is where the budget went instead: a backup round-trips to the
Rial.

### After Phase 7, and scheduled unlike Phases 8–15

Release signing from a gitignored properties file (known issue 13) and the two manifest lines,
`allowBackup="false"` and `usesCleartextTraffic="false"` (known issue 15). About an hour. **If time
runs short, something else is cut instead** (owner).

### Standing constraints carried out of Phase 5, from the owner

All of these were met inside Phase 5; they are kept because they are the rules the next phase
inherits, not a checklist still to work through.

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
  (D-057), not on one tier at whatever amounts the flow produces. **And the device test must `reach`
  what it asserts rather than assume where it is** (D-062): the tiers order pages differently, so a
  position that holds on one is a coincidence on the others. Done for the whole phase in (f), on
  **both** targets — which is D-064, the rule (f) added: a suite that has only ever run on one target
  is evidence about one target, and the close is what runs it elsewhere.
