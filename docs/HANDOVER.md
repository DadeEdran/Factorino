# Handover

**Factorino** — an offline-first invoicing application for Iranian freelancers and small businesses.
Flutter, Persian-only, RTL, Android + Windows.

This document assumes you know nothing about the project. Read it, then `docs/CURRENT_STATE.md`.
Written 2026-09-02; updated 2026-09-03 after the owner's twelve changes.

---

## 1. What it does

A user can:

* **Keep customers** — full name, company, mobile, نشانی, کد ملی (checksum-validated), کد اقتصادی.
  Search finds them regardless of which Persian or Arabic digits and letter forms were typed:
  a customer saved as «علي» is found by typing «علی».
* **Keep products and services** — name, type, unit, price.
* **Write an invoice** — pick a customer, add lines with fractional quantities, a tax rate, notes, a
  Jalali issue date and due date. A line taken from the catalogue asks only how many; its title and
  price are the product record's (D-097). A free line — «سطر آزاد» — collects everything, because no
  record stands behind it.
* **Discount it** — per line, or across the whole invoice, from one «تخفیف» screen reached beside the
  commit actions (D-098). Either level takes an amount or a percentage, the payable figure is shown
  before and after, and a discount larger than what it applies to is stated with both figures rather
  than silently clamped. Save it as a draft,
  then **issue** it, which allocates its number (`INV-1405-0001`, the prefix being configurable) and snapshots the customer's
  details onto it.
* **Record payments** against it, in part or in full. Status (`paid` / `partiallyPaid` / `unpaid`)
  is derived from the payments and persisted.
* **Issue a saved draft** from its detail page, or **edit** it — change a line, a price, the
  customer — and save it back. Only drafts are editable (§6).
* **Cancel** an issued invoice — never edit it. Cancelling keeps its recorded payments and says so.
* **Delete a draft** — the only kind of invoice that can be deleted.
* **Save a PDF** of any invoice — from a named button on the invoice page, not a menu — in Persian,
  RTL, with both parties, a lines table, and totals that reconcile by hand. The confirmation offers
  to open the file that was just saved. The document states where it stands: a draft and a cancelled invoice each carry
  an unmissable band, and an issued one prints «وضعیت پرداخت» under its payable total.
* **Back up and restore** the whole database to a single encrypted file under a passphrase.
* **Configure** the VAT rate, invoice prefix, payment term, rounding unit, their own business
  details (which appear on the printed invoice), and **whether the application is light, dark, or
  follows the device**.
* **See a dashboard** of the current Jalali month — sales, outstanding, recent invoices.

Everything is local. There is no account, no network call, and no cloud.

---

## 2. What it deliberately does not do

None of these are bugs. All were scoped out and recorded (D-068).

* **No reports section.** «گزارش‌ها» is absent from navigation entirely rather than being a dead
  item — there is no period selection and no sales-by-customer or sales-by-product breakdown. The
  dashboard covers the current Jalali month only.
* **No cloud sync, no accounts, no multi-device.** The database schema is nevertheless sync-ready
  from day one — UUID keys, soft deletes, `updated_at`, `sync_status` — so adding it later does not
  require migrating live data.
* **No PDF preview, share sheet or print dialog.** You save a file; you do not see it first — though
  since 2026-09-03 the confirmation offers to open what was saved, with the device's own viewer
  (D-091). Still no share intent.
* **No scheduled or automatic backups, no CSV export, no cloud backup.** Backup is manual, both ways.
* **An issued invoice cannot be edited.** By design (§6): it is corrected by cancelling and issuing a
  replacement, because a silently edited document is one the customer's copy no longer matches.
* **Web is not supported.** It builds in principle but has not been retested since plugins were
  added, and Web gets **no encryption at rest** (D-012).

---

## 3. What is known broken

Full list with detail in `docs/CURRENT_STATE.md` under *Known issues*. Ordered by **whether a real
user hits it**, which is not the same as severity.

### A user will hit these

| # | What | Impact |
|---|---|---|
| — | **Two Android behaviours have never run on a device.** The system back gesture (D-095) and the intent behind «باز کردن» on a saved PDF (D-091). | Not known-broken — **unverified**, which is a different and more honest word. Both were built and tested as far as a Windows machine and a widget test can go; no phone was connected. They are step 1 of the Next Action, and the first thing to try on the profile APK. |
| **26** | Crushed Persian at two width bands: the `/invoices/:id` title at 328–376 px, and «پیش‌فرض فاکتور» in the invoice editor at 616–688 px. | Text laid out narrower than its longest word renders one glyph per row. **616–688 is a reachable desktop window**, so this is not hypothetical. Both strings and bands are pinned; the reproduction is two lines. |
| **25** | An invoice long enough to span a page loses its lines-table header on page 2. | Only bites on a long invoice — but when it does, it is on the customer's copy. Untested in both directions: no fixture has ever actually spanned. Fix the fixture first, then the flag. |

### A user will not notice, but you should

| # | What | Impact |
|---|---|---|
| **28** | **There is no app lock.** No PIN, no biometric, no idle timeout, no `FLAG_SECURE`. | **The most consequential gap in the product**, and invisible in normal use — which is exactly why it is listed here. Encryption at rest protects the *file*, not a running app on an unlocked device: anyone holding an unlocked phone can read every customer's کد ملی and export a backup. `docs/ARCHITECTURE.md` §B.11 states this honestly; **do not let anyone read the threat model as covering "lost or stolen device"**. |
| **29b** | A saved draft can be edited; an **issued** invoice cannot. | Not a gap — §6. An issued invoice is corrected by cancelling it and issuing a replacement, because a silently edited document no longer matches the customer's copy. Listed so nobody "fixes" it. |
| 13 | R8/minification not enabled for release. | Binary size only. |
| 14 | Web untested, and gets **no encryption at rest**. | Phase 12, deferred. Treat Web as the least-trusted target if it is ever revived. |

### Resolved during the final sessions, listed so the history reads straight

27 (a draft could not be deleted), 29 (a draft could not be edited), and the issuing gap — all three
were the same shape: **a repository method with no call site.** See §6b.

**30 (2026-09-03), and it took four attempts — three of which were fixes to the symptom.**
«افزودن از فهرست» left the widget tree once the details section was opened, ~400 px away, and a
first-time user never found how to add a line at all. Folding the details (D-054), withdrawing
«صدور» from the pinned bar (D-086) and putting the lines above the fields (D-093) each measured
something real and each moved the control somewhere better **inside the scroll** — where the next
thing added above it moves it again.

**Three fixes to one symptom is the signal that the symptom was not the fault.** The fault was that
the screen was arranged by what the data model calls things: one of the two acts that create an
invoice was a control at the foot of a scrolling section, and the other — the customer — was a field
inside a collapsed section called «جزئیات فاکتور». D-096 pins both above the scroll. Worth reading
before rearranging any screen in this application by moving one control.

**Nothing known is wrong with any figure.** The money engine, the tax and discount allocation, the
Jalali period boundaries and the invoice numbering are the most heavily tested parts of the codebase
and none of the open issues touch them.

---

## 4. What to do first

**In this order. Item 2 is the only irreversible one** — it used to be first, and the profile APK
built on 2026-09-03 is what lets the two device checks come before it without committing to a
signing key.

1. **Install the profile APK and check the two Android-only behaviours** —
   `build/app/outputs/flutter-apk/app-profile.apk`, built 2026-09-03. The back gesture (D-095) and
   «باز کردن» on a saved PDF (D-091) are the only two things in the build that no test and no
   Windows run could reach. A profile build needs no keystore, which is why one exists.
2. **Create a release keystore and sign a build.** `docs/RELEASE.md` has the exact commands. The
   release build currently *fails* without `android/key.properties`, deliberately — a debug-signed
   APK cannot be distributed and cannot later be replaced by a properly signed one without every
   user uninstalling first. Do this before anyone installs anything they intend to keep.
3. **Use that build once, end to end.** Create a customer, write an invoice, issue it, record a
   payment, save the PDF, take a backup. That path touches the encrypted database, the money engine,
   the Jalali dates, the renderer and the file gateway in one pass. **This is how seven of eight
   defects were found in one afternoon, and twelve more the next day** — none of them by the suite.
4. **Then decide about the app lock (issue 28).** It is the difference between "the data is
   encrypted" and "the data is safe on a lost phone", and it is the one gap a user would be
   surprised by.

After that, issues 26 and 25, in that order.

---

## 5. How the code is arranged

```
lib/
  core/      theme · router · localization · formatting · money · pdf · security · widgets · responsive
  data/      database (Drift tables, DAOs, migrations) · models · repositories · backup
  features/  dashboard · customers · products · invoices · payments · settings
```

Each feature has `presentation/` (screens, widgets), `application/` (Riverpod providers and
controllers), and `domain/` where it needs one.

**The rules that are actually enforced, by tests that fail the build:**

* **Widgets never touch the database.** Widgets → providers → repositories → DAOs.
* **`core/money/` is the only calculator.** Pure Dart, no Flutter imports. Money is integer **Rial**
  in an `int`; never a `double`, never a `num`. Percentages are basis points, quantities are
  thousandths. `single_calculation_path_test.dart` fails the build if a second calculation appears —
  including inside the PDF renderer, which receives an already-computed, already-formatted view.
* **Every user-facing string comes from the ARB.** A Persian literal in a widget fails a test.
* **Every timestamp is stored UTC and displayed Jalali.** Business periods are Jalali months, not
  Gregorian ones.
* **Every table has `id` (UUID), `created_at`, `updated_at`, `deleted_at`, `sync_status`.** Deletes
  are soft. Queries filter `deleted_at IS NULL` through one helper.
* **Invoice items snapshot their title, unit and price.** Changing a product's price never changes
  an existing invoice.

---

## 6. Things that will waste your time if you do not know them

* **`docs/CURRENT_STATE.md` is the continuity file.** It is long, and it is the first thing to read.
  `docs/DECISIONS.md` (D-001 … D-081) records why every non-obvious choice was made; check it before
  reversing anything.
* **Run `dart run build_runner build` from PowerShell**, not through a POSIX shell wrapper — it hangs
  indefinitely through the latter.
* **`adb` is not on `PATH`.** It is at
  `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`, and Git Bash mangles
  device-side paths without `MSYS_NO_PATHCONV=1`.
* **MIUI intermittently refuses `flutter test -d <device>`** with `INSTALL_FAILED_USER_RESTRICTED`.
  Remedy: `flutter build apk --debug`, then `adb install -r` by hand once, then retry. Retrying is
  part of the remedy, not a sign it failed.
* **A feature can sit untested behind a working test session.** The owner tested the export on a
  phone, the save worked, and the auto-open path never ran once — because the empty-seller exception
  (D-100) fired first and takes a different branch. The session looked like coverage of the export
  and covered half of it. When a feature has an exception branch that is also the **default state**,
  assume the exception is what was exercised.

* **`nowProvider` is frozen for the life of the process, and that is deliberate.** It exists so
  every *figure on screen* answers against one instant — a dashboard cannot straddle midnight
  mid-frame. It is therefore the wrong clock for anything that needs to be *different* on a second
  reading: the invoice document's file name reads `DateTime.now()` instead, because with the frozen
  one every export in a session would propose the same name (D-099). This was nearly shipped the
  wrong way. A correct decision one call site over is exactly how it becomes a defect.

* **`flutter clean` is a one-way door onto a network you may not have.** `PUB_HOSTED_URL` points
  at the Tsinghua mirror, and on 2026-09-03 that mirror accepted the connection and then hung —
  `flutter pub get` sat at zero CPU for twenty minutes with nothing written to the cache, after
  `clean` had already deleted `.dart_tool`. The way out, and it is not obvious: **`pubspec.lock`
  records every one of the 144 packages against `https://pub.dev`, and that is where they are
  cached** — so the mirror is only used for *fetching*, and clearing the variable makes the local
  cache resolvable:

  ```powershell
  $env:PUB_HOSTED_URL = $null      # the cache is under hosted/pub.dev, not the mirror directory
  flutter pub get --offline
  ```

  With the variable still set, `--offline` looks in `hosted/mirrors.tuna...%47dart-pub%47`, finds
  nothing, and reports *"could not find package pdf in cache"* — which reads like a corrupt cache and
  is not one. Clean only when a size figure or a distributable artifact actually needs it.

* **The Windows dev database holds twelve demo invoices at small amounts.** Never judge a money
  layout against it — that is exactly the trap D-057 exists for. Use the written ladder in
  `test/support/money_magnitudes.dart`.
* **To look at a rendered PDF**, use `tools/pdf_raster/` (Windows-only, no install required). Read
  the pixels, not the source — that method has caught something every single time it was used, and
  three separate claims in D-076 turned out to have been "verified" by looking at a page where the
  thing being checked never actually occurred.

---

## 6b. Audit for repository methods with no caller, before trusting the suite

**Three separate features were missing this way, and 1,230 tests could not see any of them.** In one
afternoon of using the app on a phone the owner found that a draft could not be deleted, could not be
issued, and could not be edited. In all three cases the repository method existed, was correct, and
was covered by its own tests — `softDeleteDraft`, `issue`, `updateDraft` — and **nothing in the
interface called it**.

That is the shape of gap this codebase's tests cannot report. They verify that things work; they have
no way to say that nothing uses them. A widget test asserts what a screen does, not what it fails to
offer, and an untouched repository method looks exactly like a well-tested one.

**So before trusting the suite's coverage, grep for it.** For each public method on a repository,
check there is a call site outside `test/` and `integration_test/`:

```sh
grep -rn "methodName" lib/ --include=*.dart | grep -v "\.g\.dart"
```

A method that appears only in its own interface, its implementation and its tests is a feature that
was built and never wired up. Three of them were sitting there at handover.

## 6c. Before trusting a check, ask what state it runs in

**Three checks in three days reported success about conditions no user is ever in.** They were not
wrong; they were measuring somewhere else, and each looked exactly like coverage.

| The check | The state it ran in | The state that mattered |
|---|---|---|
| `AppTableHeader`'s D-065 table-minimum guard | inside `assert`, so **debug builds only** | release, where it is compiled out — four screens would have shipped Persian at one glyph per row (D-081) |
| The release-signing refusal | Gradle **configuration**, which runs for every build type | it fired on `assembleDebug` too, breaking `flutter run` and every device suite (D-083) |
| `invoice_form_device_test`'s `fits unscrolled: true` | a **pristine** form: no customer, details folded | after picking a customer and opening the details — where the control leaves the widget tree entirely (D-086) |

**The class, stated once:** *a check is only as good as the conditions it actually runs in.* Before
trusting one, ask two questions — **what state does this run in, and is a user ever in it?** All
three were invisible to reading and immediate on running; none would have been caught by a careful
diff review, and each was caught within minutes of putting the thing in front of a person or a phone.

This sits beside §6b's point rather than repeating it. §6b is about checks that **do not exist**
(a repository method nothing calls); this is about checks that **exist and watch the wrong thing**.

### Falsifiability, per D-072

Every measurement guard in this codebase is supposed to be **verified to bite** — proved to fail when
handed the defect it exists for — because a guard that cannot fail is worse than none: it reports
clean and looks like coverage. `test/core/widgets/guard_controls_test.dart` is the standing home for
these controls and its header records the audit.

Established as falsifiable: the crushed-text detector (its own negative control), the sheet-keyboard
rule (a deliberately-wrong sheet, plus the `AppSpacing.lg` slack floor, which fails on five of six
sheets at twice the floor), `app_table_test` (one pixel either side of its threshold), the contrast
probe (proved accurate against a known 2.68:1), the source-scanning guards (each carries a matcher
self-test), the gateway boundary, the width sweep (four screens fail at the old 1024 breakpoint, one
at 1280), and the release-signing refusal (both directions: debug builds, release refuses).

**Newly established (2026-09-03):** `transient_message_scope_test.dart`, proved the deliberate way —
the `clearSnackBars` call was commented out, three of its six checks failed, and it was restored
(D-101). And `navigation_bar_test.dart`, which failed against the first
attempt at D-088 — a `DefaultTextStyle` placed outside the `NavigationBar`, which Material's own
`Material` resets — measuring 36 logical pixels against the other four destinations' 18, and passed
against the second. It was not written as a negative control; it simply caught the fix that did not
work, which is the same evidence.

**Not established, and listed rather than assumed:** the money-magnitude ladder sweeps
(`money_layout_test`) have no negative control — they are believed to bite because D-058 and D-065
were both found by them, which is evidence but not a standing proof. If you touch the layout
primitives they watch, add one.

## 6d. A value can be computed correctly and thrown away by its caller

**The most valuable finding of 2026-09-03, and it was found while building something else.**

`invoices.issue_date` has been a UTC **instant** since Phase 1. The Jalali date picker returns
`startOfJalaliDayUtc` — a **day**, which is exactly right for what it is asked. `setIssueDate`
assigned that return value whole.

So every invoice whose date was ever corrected in the form had its time of day silently replaced
with local midnight. Not a missing value — a **specific claim, and a false one**, on the field a
printed document dates itself by.

**Nothing could see it.** The picker was right and is tested. The instant helpers were right and are
tested against known Nowruz anchors. The column was right. The repository round-trip was right. The
defect lived entirely in one assignment between two correct things — and it was **invisible for as
long as the time was never displayed**, which was its whole life until the owner asked for the time
to be shown beside the date.

### The shape, stated once

This is the same family as §6b and §6c, and the third member of it:

| | The gap | Why the suite cannot see it |
|---|---|---|
| §6b | a repository method with **no call site** | a test asserts what a screen does, never what it fails to offer |
| §6c | a check that runs in a **state no user is in** | it reports success, truthfully, about somewhere else |
| **§6d** | a value **computed right and discarded** by its caller | both sides are tested; the assignment between them is not, and nothing renders the loss |

The unifying property is that **each is a fault in wiring rather than in logic**, and a suite built
from unit tests over correct components is structurally unable to report any of them. All four
instances so far were found by a person using the application, or by someone asking it for something
new.

### What to do about it

When a stored value is about to be **displayed for the first time**, do not assume it holds what its
type says it holds. Read what actually reaches the column on the paths that write it — the form, the
importer, a migration backfill — before trusting the value enough to print it. A field nobody has
looked at is a field nobody has checked, however well tested the code around it is.

The remedy here is `jalaliDayWithTimeOf` (D-092): changing the *day* changes only the day, and the
invariant that the result never leaves the picked Jalali day is what keeps the Jalali reporting
periods correct. `jalali_day_with_time_test.dart` checks both edges of the clock against a month end,
a year end and a leap-year Esfand 30.

---

## 7. The gate

```sh
flutter analyze     # must be clean
flutter test        # 1295 tests, must all pass
```

Both were clean at handover. Beyond that, a phase is not closed until its layout has been checked at
**all three tiers** over the **written ladder of amounts** (D-057) — a pass at one tier is a pass at
one tier, and small test data hides money-layout defects.

Device suites live in `integration_test/` and run against a real encrypted database on a real target:

```sh
flutter test integration_test/invoice_detail_device_test.dart -d <device>
# ... and the same with -d windows
```

Two lessons the project paid for, worth keeping:

* **A widget tested only at its own full width has not been tested at the width it is composed
  into** — and by extension, testing at the three named tier sizes is not testing the widths
  *between* them, which is where a real window spends most of its time.
  `test/features/width_sweep_test.dart` now covers that.
* **Guards inside `assert` do not exist in release builds.** A debug run is not a check on the
  artifact users receive. What makes a guard count is a test that runs it.

---

## 8. Where things stand

Phases 0–7 are `COMPLETED`, plus one unplanned block of work after them: **the owner's twelve
changes of 2026-09-03** (`ROADMAP.md`, *After Phase 7*), which closed known issue 30 and reversed or
narrowed several Phase 7 decisions — most visibly, the PDF export moved out of the overflow menu
because testers never opened it. Phases 8–15 are `DEFERRED_INDEFINITELY` (D-068), which is a scope
decision taken when the timeline shortened, not an assessment that they do not matter.

The application is feature-complete for its intended job and its data handling is sound. What stands
between it and someone else's hands is the keystore in step 1 — and, before it is trusted with real
customer records on a phone that leaves the house, the app lock in step 3.
