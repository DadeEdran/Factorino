# Architecture

> **Two sections, deliberately separated.**
> §A describes what **actually exists** in the repository right now.
> §B describes the **planned** Phase 1 architecture — it is not built yet and must not be read as if
> it were. As Phase 1 lands, content moves from §B to §A.
>
> The project spec: *never document architecture that does not exist.*

---

# §A — What exists today (2026-08-23)

A stock `flutter create` scaffold. Nothing of the target architecture has been built.

```
Factorino/
  analysis_options.yaml  # flutter_lints 6.0.0 defaults, unmodified
  pubspec.yaml           # flutter + cupertino_icons + flutter_lints only
  pubspec.lock           # CONTAMINATED — mirror-hosted, awaiting regeneration (D-014)
.gitignore             # hardened 2026-08-23 (D-019)
.githooks/pre-commit   # lockfile-host / secrets / app-ID gate (D-019)
  assets/fonts/          # Vazirmatn 400/500/700 + OFL.txt (D-022) — not yet declared in pubspec
  lib/main.dart          # default counter app, 122 lines
  test/widget_test.dart  # default counter smoke test, 30 lines
  android/  web/  windows/
  docs/                  # created 2026-08-22; ENVIRONMENT.md added 2026-08-23
```

- **State management:** none (the template `setState` counter).
- **Persistence:** none.
- **Routing:** none (a single `MaterialApp` home).
- **Localization:** none — the template is English and LTR.
- **Theme:** the default Material 3 `ColorScheme.fromSeed`.
- **Security:** none of it in the app. No encryption, no key management, no manifest hardening, no
  CSP. Repository-level hygiene *is* in place: hardened `.gitignore` and a pre-commit gate (D-019).
- **Version control:** initialized 2026-08-23 — branch `main`, `core.autocrlf=false`,
  `core.hooksPath=.githooks`. **No commit yet**: the first commit is gated on replacing the template
  application ID (D-019).

Platform scaffolds exist for Android, Web and Windows, and all three build (see `CURRENT_STATE.md`).
Android is at `com.example.factorino` with the template `TODO` markers for the application ID and the
release signing config still in place.

---

# §B — Planned architecture (Phase 1 target)

## B.1 Layering

Strictly one direction. Nothing skips a layer.

```
Widget  ──watch──▶  Provider  ──calls──▶  Repository  ──uses──▶  DAO  ──▶  SQLite (encrypted)
        (presentation)      (application)          (data)        (Drift)
```

**Hard rules, restated because they are the ones that erode first:**

- No business logic in widgets — no calculation, no formatting decisions, no branching on raw data.
- No database access in widgets.
- Repositories return **domain models**, never Drift-generated row classes. The Drift row type stops
  at the repository boundary; mapping happens there.
- `core/money/` imports **nothing from Flutter**, so it is testable without a widget binding.

## B.2 Folder structure

```
lib/
  core/
    theme/          # design tokens, ThemeData (light + dark)
    router/         # go_router configuration
    localization/   # ARB files, Persian strings, RTL setup
    formatting/     # money, date, digit, phone formatters
    money/          # Money value type + calculation engine (pure Dart)
    security/       # encryption key management, app lock, secure logging
    widgets/        # shared design-system components
    responsive/     # breakpoints + adaptive shell
    errors/         # failure types, error mapping
    utils/
  data/
    database/       # Drift tables, DAOs, migrations, connection setup
    models/         # domain entities (not Drift rows)
    repositories/   # interfaces + implementations
  features/
    dashboard/  customers/  products/  invoices/  payments/  settings/
      presentation/   # screens, widgets
      application/    # providers, controllers
      domain/         # feature-specific logic
  main.dart
```

## B.3 State management

Riverpod, code-generation flavor (D-007).

- Providers are scoped and `autoDispose` by default; global mutable state is avoided.
- Widgets watch the **narrowest possible selector** so one changed field does not rebuild a screen.
- The database and repositories are exposed as providers, which makes them overridable in tests
  against an in-memory database.

## B.4 Data flow

Reads are reactive: Drift query streams surface through repositories as streams of domain models and
reach widgets as `AsyncValue`. Writes go through repository methods that own their transaction
boundary — notably invoice creation (item snapshotting plus number allocation) and payment recording
(which recomputes and persists derived invoice status).

## B.5 Database design

**Connection setup** (D-016): opened directly with `drift` + `sqlite3` + `path_provider`, with the
encrypted native library supplied by `package:sqlite3` build hooks configured for `sqlite3mc`
(D-010). On every open, in this **exact order** (D-020):

1. `PRAGMA key` from secure storage — **first statement on the connection, always**
2. `PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4;`
3. `PRAGMA foreign_keys = ON` (D-017)
4. only then anything Drift issues

Implemented in exactly one place (the Drift `LazyDatabase` setup callback) so no call site can open a
connection differently. Getting the order wrong silently produces an unencrypted database on a new
file, or an undiagnosable `file is not a database` on an existing one.

Windows stores the file under `%APPDATA%`, never beside the executable.

**Every user-data table carries** (D-011): `id TEXT` UUID v4 PK, `created_at INTEGER`,
`updated_at INTEGER`, `deleted_at INTEGER?`, `sync_status INTEGER`, `last_synced_at INTEGER?`.
All timestamps are UTC epoch milliseconds (D-005).

**Tables:** `customers`, `products`, `invoices`, `invoice_items`, `payments`, `settings` (single row).

**Integrity:** `invoice_items.invoice_id` and `payments.invoice_id` both reference `invoices.id`
`ON DELETE CASCADE`. Invoice deletion is a soft delete at the invoice level; the cascade exists for
hard cleanup only. Customers and products referenced by an invoice are soft-deleted only.

**Soft-delete discipline:** a single shared query helper applies `deleted_at IS NULL`, so it cannot
be forgotten at an individual call site (D-003).

**Snapshots:** `invoice_items` copies product title, unit, unit price and resolved tax rate at
creation time and never joins to the live product row for pricing (D-004).

**Indexes:** invoice issue date, customer reference, status, invoice number (unique), and
`deleted_at`.

**Migrations:** `schemaVersion` set from the first release; existing migrations are never mutated;
`drift_dev` schema dumps back generated migration tests. A migration without a test is not done.

## B.6 The money engine

Pure Dart in `core/money/`, integer Rial throughout (D-002). It implements exactly the calculation
order in the project spec — line gross, line discount, line net, proportional allocation of the
invoice-level discount by line net using the **largest-remainder method**, then tax on the
post-allocation net, then line total.

Tax rate resolution is item → invoice → settings default, first non-null wins, and the resolved rate
is snapshotted onto the item.

The invariant `grandTotal == subtotal − invoiceDiscount + totalTax` must hold and is unit-tested,
alongside zero quantity, fractional quantity, item discount exceeding line total, allocation
remainders, mixed tax rates and rounding boundaries.

## B.7 Navigation

`go_router` (D-009), with routes for dashboard, customers, customer detail, products, product
detail, invoices, invoice detail, create/edit invoice, reports and settings. Web URLs are real and
shareable; deep links restore on Windows and Android.

Full navigation label set: داشبورد / فاکتورها / مشتریان / محصولات و خدمات / گزارش‌ها / تنظیمات.

**In Phase 1, گزارش‌ها is omitted entirely** — not disabled, not a coming-soon placeholder, and its
route is not registered either, so no deep link or typed Web URL can reach a screen that does not
exist. It arrives in Phase 8 (D-021). Phase 1 navigation is therefore:
داشبورد · فاکتورها · مشتریان · محصولات و خدمات · تنظیمات.

## B.8 Localization and RTL

`Directionality` is set once at the app root rather than fought per widget. Every user-facing string
goes through the localization layer from day one; no Persian literal is hardcoded inside a widget,
even though Persian is currently the only locale.

`core/formatting/` owns digit normalization (Persian `۰-۹` and Arabic-Indic `٠-٩` to ASCII), the
`ي`→`ی` / `ك`→`ک` mapping, and ZWNJ handling — applied at every numeric input boundary and to every
search term, so a customer saved as "علي" is found by typing "علی".

Numbers display with Persian digits and thousands separators. Invoice numbers, phone numbers and
national IDs get explicit bidi isolation so they do not visually scramble inside RTL text. Amounts
always carry a unit label; Toman is primary.

Icon mirroring is selective: directional navigation icons mirror; logos, media controls, checkmarks,
charts and numerals do not.

## B.9 Responsive strategy

Three tiers with genuinely different layouts, built on primitives in `core/responsive/` rather than
scattered `MediaQuery` checks.

| Tier | Navigation | Layout |
|---|---|---|
| Mobile | `NavigationBar` | Single column; invoice lists are **cards**, not squeezed tables |
| Tablet | Adaptive | Two-pane where useful, higher density |
| Desktop / Windows / Web | `NavigationRail` / `NavigationDrawer` | Multi-column, real data tables, master-detail, sticky invoice summary |

## B.10 Theme

All visual values are tokens in `core/theme/`; no hardcoded colors, sizes, radii or spacing inside
widgets. Tokens cover a neutral foundation plus one accent, semantic status colors (paid / unpaid /
draft / cancelled / overdue), a type scale including a dedicated prominent financial numeral style,
and spacing / radius / elevation scales favouring subtle borders over heavy shadows.

Dark mode is designed, not inverted: real surface hierarchy, muted secondary text, retuned status
colors.

## B.11 Security model

| Concern | Approach |
|---|---|
| Data at rest (Android, Windows) | Encrypted SQLite — `sqlite3mc` via `package:sqlite3` build hooks, SQLCipher-compatible format (D-010, D-020) |
| Encryption key | Random, generated once, in `flutter_secure_storage` (Keystore / DPAPI) |
| Data at rest (Web) | **Not encrypted** — disclosed in Persian in-app (D-012) |
| App lock | PIN (salted KDF hash) + biometric, idle timeout — Phase 9 |
| Secrets | `--dart-define-from-file`, gitignored, with a committed `.example` |
| Injection | Drift typed parameterized queries only (D-018) |
| Logging | Single wrapper; never logs identifiers, names or amounts; stripped in release |
| Errors | Friendly Persian messages; never a stack trace, SQL, path or raw exception |

**Threat model — covered:** lost or stolen device, shared Windows machine, casual local access,
accidental secret leakage into the repository, dependency supply-chain drift.
**Not covered in v1, and documented as such:** a fully compromised OS with root/admin access, and
browser-based storage on Web.

## B.12 Offline-first and the planned sync strategy

v1 has no network dependency and no account. The schema is nevertheless sync-ready from the first
migration (D-011) so that adding sync later does not require migrating live user data.

Planned sync (Phase 11, not designed in detail yet): Supabase with Row Level Security on every table,
last-writer-wins by `updated_at` as the starting conflict policy, soft-delete tombstones propagating
deletions, and `sync_status` driving the pending/synced/conflict queue. The one problem sync must
solve that the current schema only reserves space for is invoice-number collision across devices
(D-013).

## B.13 PDF boundary

Phase 1 defines `InvoiceDocumentGenerator` as a platform-neutral interface with a single
implementation that **fails loudly** rather than silently producing nothing. The interface takes a
fully computed, already formatted view model, so the eventual renderer cannot recompute — and
therefore cannot disagree with — the invoice totals.
