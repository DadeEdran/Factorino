# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-27**

---

## Phase

**Phase 0 — Environment and Setup · `COMPLETED`**
**Phase 1 — Foundation and Architecture · `COMPLETED`** (2026-08-24, seven increments, all accepted)
**Phase 2 — Customers · `COMPLETED`** (2026-08-25)
**Phase 3 — Products and Services · `COMPLETED`** (2026-08-25)
**Phase 4 — Invoice Creation · `IN_PROGRESS`** — (a), (a2), (a3), (b) and (c) are all **accepted**;
(c2) was delivered 2026-08-27 and is **awaiting review**. **(d) is the only increment left.**

| # | Increment | Status |
|---|---|---|
| a | The draft state model and its wiring to `core/money/` — no UI, fully tested | `COMPLETED`, **accepted** |
| a2 | **Numbering on issue + `schemaVersion = 2`** (D-048) | `COMPLETED` — device proof passed 2026-08-26 |
| a3 | **The table-rebuild guard** (D-049) — the cascade defect made structural | `COMPLETED`, **accepted** |
| b | Line item entry: product picker, free-text lines, quantity, per-line discount and tax | `COMPLETED`, **accepted** |
| c | Invoice-level fields: customer, dates, discount, tax, notes, **and the save** | `COMPLETED`, **accepted** |
| c2 | **The party snapshot + the payment term** (D-051, D-052) — `schemaVersion = 3` | `COMPLETED` 2026-08-27 — device proof passed |
| d | The assembled screen at all three tiers, on real data | `NOT_STARTED` |

(a2) was not in the original four-way split. The owner approved D-048 on 2026-08-26 and directed
that it land as its own reviewable step **before (b)** — it is the project's first migration and a
build is already installed on a real device. (c2) is the second migration, scheduled by the owner
on 2026-08-27 on the same precedent.

Phases 2 and 3 were re-scoped by D-042 to what increment (f1) had not already delivered. Both of
those items are built, so both phases are closed.

## Where the project stands, in one paragraph

**Phase 4 increment (c2) is delivered and awaiting review; nothing else is in progress.** Six screens
work end to end on real data — Dashboard, Invoices, Customers, Customer detail, Products, Settings —
inside a Persian, RTL, three-tier responsive shell, over an encrypted SQLite database. The database
is at **schema v3**, and both migration ladders (v2 → v3 and v1 → v3) are proved on Windows and on
the Redmi.

**Every piece of the invoice form exists except the screen that holds them.** (a) built the
arithmetic spine, (a2) fixed the numbering underneath it, (a3) made its worst failure mode
structural, (b) built line entry, (c) built the invoice-level fields and the save, and (c2) made an
issued invoice keep the party it was issued to. **(d) is the only increment left** — it composes what
(b) and (c) built into one form and gives it a route. Until it lands there is still no way for a user
to create an invoice, because nothing routes to these widgets.

**The device debt — the one thing a fresh session must not lose.** No widget from (b) or (c) has been
touched by a person, because no route reaches them until (d). That is **two numeric-heavy sheets, a
calendar grid and two picker sheets**, verified by widget tests and the APK build only. The owner's
instruction, twice and verbatim in substance: *"a numeric-heavy sheet on a phone is exactly where
tests and reality diverge"*, and for (d) — **"the device debt is the first item, not the last."**
Running the assembled form on the Redmi is the **first** task inside (d), not a follow-up to it.

## Verification status

```
flutter analyze:            PASS   (No issues found)                          as of (c2)
flutter test:               PASS   (676/676, was 650)                         as of (c2)
Android build:              PASS   flutter build apk --debug                  (c2)
Windows run:                PASS   the app opened the REAL dev database and migrated it v2 -> v3
D-052 proof - Windows:      PASS   both ladders: v2 -> v3 and v1 -> v3
D-052 proof - Android:      PASS   both ladders, on the Redmi Note 8 Pro (2026-08-27)
D-048 proof - Windows:      PASS   integration_test/invoice_number_migration_proof_test.dart
D-048 proof - Android:      PASS   re-run on the Redmi 2026-08-27 (v1 -> 3 now, not v1 -> 2)
D-020 proof - Windows:      PASS   5/5 (2026-08-23, not re-run)
D-020 proof - Android:      PASS   5/5 (2026-08-23). Could NOT be re-run 2026-08-27 -- see below.
Web build:                  NOT_RETESTED since plugins were added
(b)+(c) widgets on device:  NOT_RUN  no route reaches them until (d). THE OPEN DEBT.
```

**The D-020 and startup proofs could not be re-run on the Redmi**, and it is a device condition
rather than a code one: the phone reported `Requested internal only, but not enough space` on the
install, and the follow-up uninstall failed with `DELETE_FAILED_INTERNAL_ERROR`. The three proofs
that (c2) needed had already installed and passed on the same session. Free space on the device
before the next device run.

**The real Windows dev database was migrated v2 → v3**, opened by the running app rather than by a
fixture: the file that has been accumulating rows since Phase 1 was rewritten at 03:22 and the app
ran against it with no exception logged. A pre-migration copy is in this session's scratchpad as
`factorino.db.v2backup`.

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
```

**To see a screen with data in it:** the Windows dev database holds twelve demo invoices and twelve
customers. There is still no invoice-creation UI, so new invoices must be written by a throwaway
`integration_test/` script through the **real repositories** — never by raw inserts, or the totals
and numbers would not be the ones the app produces. Such a script can also render a screen to a PNG
via `RepaintBoundary.toImage()`, which is how Phase 2 was looked at; delete it after use.

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
| 10b | **The Redmi ran out of internal storage** | Seen 2026-08-27 after three integration runs: `Requested internal only, but not enough space`, and the follow-up uninstall failed `DELETE_FAILED_INTERNAL_ERROR`. The D-020 and startup proofs could not be re-run because of it. Free space on the device before the next device session. |
| 10 | MIUI re-blocks `flutter test`'s install on a *fresh* install | Seen again 2026-08-26 as `INSTALL_FAILED_USER_RESTRICTED`. Fix that worked: `flutter build apk --debug`, then `adb -s <id> install -r <apk>` **by hand** once — after that `flutter test -d <id>` installs on its own. It may then report `INSTALL_FAILED_INSUFFICIENT_STORAGE` and recover itself by uninstalling first; that is not a failure. |
| 11 | **The pub mirror can go unreachable mid-session** | `dart pub get --offline` resolves from the local cache. Sanitize the lockfile **last**. |
| 12 | `flutter doctor` "Android license status unknown" | Stale check, not a failure. See `ENVIRONMENT.md`. |
| 13 | Release builds signed with debug keys | Phase 15. |
| 14 | Web not retested; Web gets **no** encryption at rest (D-012) | Phase 12. |
| 15 | Android manifest hardening not done | Phase 9. |
| 16 | The customer detail screen loads every one of a customer's invoices | `watchForCustomer` caps at 1000 and does not page. The rendering is virtualized, so this is a query cost rather than a layout one, and it is invisible below a few hundred. Give it a `ListQuery` when the invoice list gets its filters in Phase 5. |
| 17 | ~~Creating a draft allocates an invoice number~~ | **Resolved in (a2)** per D-048. A draft carries no number; `issue()` allocates. Covered by the regression test `an abandoned draft does not consume a number`. |

(5 and 7 were resolved in (f2) and have been dropped.)

## Important context for a future session

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

### Phase 4 increment (c2) — the newest work

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

**Phase 4 increment (c2)** — the party snapshot and the payment term, `schemaVersion = 3` (D-052).
676 tests pass, analyzer clean, `flutter build apk --debug` passes, and **both migration ladders are
proved on the Redmi**. The owner accepted (c) in the same message that scheduled (c2).

## Next action

**Build Phase 4 increment (d), the assembled invoice screen — and start with the device.** The owner
authorised (d) as the increment after (c2) and was explicit about its order: *"the device debt is the
first item, not the last: two numeric sheets, a calendar grid and two pickers that no person has
touched."* So put a route on what already exists and run it on the Redmi **before** building the
desktop layout, not after.

### What (d) is

Compose `InvoiceDetailsSection` and `InvoiceLinesSection` into one form with a totals summary, add
the `/invoices/new` route, and lay it out at all three tiers — a sticky summary panel and a
multi-column layout on desktop (§10), a single column on a phone. It is also where the save and
issue actions get their buttons and their Persian confirmations: **the strings already exist** —
`invoiceActionSaveDraft`, `invoiceActionIssue`, `invoiceSaveDraftSuccess`, `invoiceIssueSuccess`,
`invoiceSaveFailed`, `invoiceIncompleteCustomer`, `invoiceIncompleteLines` — added in (c) with no
screen to put them on. `InvoiceEditor.save()` and `.issue()` are built and tested; (d) wires them to
buttons and renders the result.

Specifics that are already decided and should not be re-derived:

- **The `openedAt` family key must be read once**, in `initState` or equivalent, and passed down to
  both sections. A fresh `DateTime.now()` in `build` addresses a new, empty editor every frame and
  discards the invoice as it is typed. Both sections take it as a parameter for this reason.
- **Nothing in the screen may call `calculateInvoice`** — read every figure from
  `InvoiceEditorState.totals`. `single_calculation_path_test.dart` fails the build otherwise.
- **The totals summary should use `CalculatedInvoice.grossTotal`** (D-047), not the subtotal, so the
  printed summary reconciles by hand.
- **`isComplete` is what gates the buttons**: a customer, at least one line, and every line named
  and united. The two "incomplete" strings above say which is missing.

### (d) must pay the device debt — as a task inside it, not after

Nothing from (b) or (c) has been touched by a person. Run the assembled form on the **Redmi**
(`dmbyayb6rombo7ci`) before reporting (d): enter a line by hand, pick a product, pick both dates in
the Jalali calendar, and save and issue one invoice. Known issue 10 has the MIUI install sequence
that works.

**Still open for Phase 5, deliberately (owner, 2026-08-26):** D-047's `grossTotal` is computed but
not stored, and per-line gross is not recoverable from what `invoice_items` keeps. **Do not store it
now** — decide it in Phase 5 with the invoice detail screen and the PDF renderer both in view, since
they are the two consumers and storing the wrong shape costs another migration.

**Increment (b) — line item entry** — **delivered and accepted.** Kept below as the historical
brief it was built against, not as live instructions:

1. A product picker that **copies** title, unit and price in as snapshots (D-004), plus a free-text
   line for anything not in the catalogue.
2. Quantity as `quantity_milli` through `tryParseScaledInput(scale: 1000)` — never a `double`, and
   more precision than milli can hold is refused rather than truncated.
3. Per-line discount (amount or percentage) and the per-line tax override, with `0` kept distinct
   from "inherit" all the way from the widget (D-026).
4. Every field an `AppTextField` (D-043) — **add `InvoiceLimits` to `field_limits.dart`** for the
   line title (200) and unit (30), matching `invoice_items`, and let the schema test cover them.
5. The warnings rendered from `invoiceWarningMessage`, already written and tested in (a).
6. Nothing in the widget may call `calculateInvoice`; read the figures from `InvoiceEditorState`.
   The guard will fail the build if that slips.
7. **`InvoiceEditor` still has no `save`, and (b) still must not add one** — but the reason has
   changed. It was blocked on D-048; D-048 has landed, so a `save` is now *possible* and belongs in
   (c) with the rest of the invoice-level fields, where the customer and the dates it needs are.
   *(Since satisfied: (c) added `save()` and `issue()`.)*

### Standing rules that outlive this handoff

- **The cipher pragmas come before `pragma key`** (D-020); assert encryption on the file header.
- **A migration that rebuilds a table must never run inside a transaction** (D-049). SQLite ignores
  `PRAGMA foreign_keys` in one, so the rebuild's `DROP TABLE` cascades and empties every child
  table while the schema still compares as correct. `assertForeignKeysCanBeDisabled` now refuses
  rather than allowing it, and the call site says so — do not remove either to make a wrapper work.
- **The nine `lib/`-scanning guards** listed above are the project's memory of nine silent failure
  modes. Route through the helper; never weaken the test. `single_calculation_path_test.dart` is the
  one Phase 4 keeps tripping over: **no widget may call `calculateInvoice`** — read figures from
  `InvoiceEditorState.totals`.
- **Sanitize the lockfile after any command that resolves dependencies, and do it last.**
- **Regenerate and commit** after touching a table, a provider, or the ARB.
- **A widget test must pin a size** (`kMobileSize` / `kDesktopSize` in `screen_harness.dart`). The
  phone width is where Persian headings overflow their rows; (b) shipped one such defect and the
  test at 400dp is what caught it.
- Commit policy (D-019): commit at meaningful milestones, show `git diff --stat` and the message,
  no per-commit approval needed. Never force-push, amend, rebase or reset --hard.
