# Handover

**Factorino** — an offline-first invoicing application for Iranian freelancers and small businesses.
Flutter, Persian-only, RTL, Android + Windows.

This document assumes you know nothing about the project. Read it, then `docs/CURRENT_STATE.md`.
Written 2026-09-02, at the point development access ended.

---

## 1. What it does

A user can:

* **Keep customers** — full name, company, mobile, نشانی, کد ملی (checksum-validated), کد اقتصادی.
  Search finds them regardless of which Persian or Arabic digits and letter forms were typed:
  a customer saved as «علي» is found by typing «علی».
* **Keep products and services** — name, type, unit, price.
* **Write an invoice** — pick a customer, add lines with fractional quantities, per-line and
  invoice-level discounts, a tax rate, notes, a Jalali issue date and due date. Save it as a draft,
  then **issue** it, which allocates its number (`INV-1405-0001`, the prefix being configurable) and snapshots the customer's
  details onto it.
* **Record payments** against it, in part or in full. Status (`paid` / `partiallyPaid` / `unpaid`)
  is derived from the payments and persisted.
* **Cancel** an issued invoice — never edit it. Cancelling keeps its recorded payments and says so.
* **Delete a draft** — the only kind of invoice that can be deleted.
* **Save a PDF** of any invoice, in Persian, RTL, with both parties, a lines table, and totals that
  reconcile by hand.
* **Back up and restore** the whole database to a single encrypted file under a passphrase.
* **Configure** the VAT rate, invoice prefix, payment term, rounding unit, and their own business
  details (which appear on the printed invoice).
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
* **No PDF preview, share sheet or print dialog.** You save a file; you do not see it first.
* **No scheduled or automatic backups, no CSV export, no cloud backup.** Backup is manual, both ways.
* **An issued invoice cannot be edited.** By design (§6): it is corrected by cancelling and issuing a
  replacement, because a silently edited document is one the customer's copy no longer matches.
* **Web is not supported.** It builds in principle but has not been retested since plugins were
  added, and Web gets **no encryption at rest** (D-012).

---

## 3. What is known broken

Full list with detail in `docs/CURRENT_STATE.md` under *Known issues*. The ones that matter:

| # | What | Impact |
|---|---|---|
| **28** | **There is no app lock.** No PIN, no biometric, no idle timeout, no `FLAG_SECURE`. | **The most significant gap.** Encryption at rest protects the *file*, not a running app on an unlocked device. Anyone holding an unlocked phone can read every customer's کد ملی and export a backup. `docs/ARCHITECTURE.md` §B.11 states this honestly; do not let anyone read the threat model as covering it. |
| **26** | Crushed Persian at two width bands: the `/invoices/:id` title at 328–376 px, and «پیش‌فرض فاکتور» in the invoice editor at 616–688 px. | Cosmetic but ugly — text laid out narrower than its longest word renders one glyph per row. The second band is a reachable desktop window. Both strings and both bands are pinned in the issue; the reproduction is two lines. |
| **30** | Adding a line on the new-invoice screen is not discoverable, and leaves the widget tree entirely once the details section is opened. | Measured, not fixed (D-086): 586–611 px of an 804 px viewport, 59 px above a pinned bar of two filled buttons. The fault is hierarchy, not geometry. The numbers and three candidate fixes are recorded. |
| **25** | An invoice long enough to span a page loses its lines-table header on page 2. | The header row is `repeat: false`, and no fixture has ever actually spanned, so it is untested in both directions. Fix the fixture first, then the flag. |
| 13 | R8/minification not enabled for release. | Binary size only. |
| 14 | Web untested, and unencrypted. | Phase 12, deferred. |

**Nothing known is wrong with any figure.** The money engine, the tax and discount allocation, the
Jalali period boundaries and the invoice numbering are the most heavily tested parts of the codebase
and none of the open issues touch them.

---

## 4. What to do first

**In this order. The first item is the only irreversible one.**

1. **Create a release keystore and sign a build.** `docs/RELEASE.md` has the exact commands. The
   release build currently *fails* without `android/key.properties`, deliberately — a debug-signed
   APK cannot be distributed and cannot later be replaced by a properly signed one without every
   user uninstalling first. Do this before anyone installs anything.
2. **Install that build on a real device and use it once, end to end.** Create a customer, write an
   invoice, issue it, record a payment, save the PDF, take a backup. That path touches the encrypted
   database, the money engine, the Jalali dates, the renderer and the file gateway in one pass.
3. **Then decide about the app lock (issue 28).** It is the difference between "the data is
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
* **The Windows dev database holds twelve demo invoices at small amounts.** Never judge a money
  layout against it — that is exactly the trap D-057 exists for. Use the written ladder in
  `test/support/money_magnitudes.dart`.
* **To look at a rendered PDF**, use `tools/pdf_raster/` (Windows-only, no install required). Read
  the pixels, not the source — that method has caught something every single time it was used, and
  three separate claims in D-076 turned out to have been "verified" by looking at a page where the
  thing being checked never actually occurred.

---

## 6b. Audit for repository methods with no caller, before trusting the suite

**Three separate features were missing this way, and 1,229 tests could not see any of them.** In one
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

## 7. The gate

```sh
flutter analyze     # must be clean
flutter test        # 1229 tests, must all pass
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

Phases 0–7 are `COMPLETED`. Phases 8–15 are `DEFERRED_INDEFINITELY` (D-068), which is a scope
decision taken when the timeline shortened, not an assessment that they do not matter.

The application is feature-complete for its intended job and its data handling is sound. What stands
between it and someone else's hands is the keystore in step 1 — and, before it is trusted with real
customer records on a phone that leaves the house, the app lock in step 3.
