# Factorino — Project Definition

> Stable, high-level description of the product. Rewrite rarely.
> Operational status lives in `CURRENT_STATE.md`; phase tracking lives in `ROADMAP.md`.

---

## 1. Purpose

Factorino is a professional **invoice and billing application for the Iranian market**.

It exists to let a small Iranian business issue correct, professional invoices and know exactly what
it is owed — without a subscription, without an internet connection, and without the visual and
usability compromises of traditional Iranian accounting software.

The product's single hardest requirement is **arithmetic correctness**. A wrong total is not a bug
to be fixed next release; it is a product-killing defect that destroys the user's trust in their own
financial records.

## 2. Users

- Iranian freelancers issuing invoices to clients
- Small businesses and workshops (کسب‌وکارهای کوچک، کارگاه‌ها)
- Service providers who bill by hour, unit, weight, or length

These users are assumed to be non-technical, to work primarily in Persian, and to keep their business
records **only** in this app. That last assumption is why backup and restore is a v1 requirement, not
a later nicety.

## 3. Platforms

| Platform | Role | Trust level |
|---|---|---|
| **Android** | Primary target | Encrypted at rest |
| **Windows** | Desktop / office use | Encrypted at rest |
| **Web** | Convenience / demo | **Least trusted** — see §7 |

## 4. Posture: offline-first

The application is fully functional with no network connection. All data lives locally. There is no
account, no login, and no server in v1.

Cloud sync (Supabase) is a **planned future phase**, not a current one. The database schema is built
sync-ready from day one (UUID keys, soft deletes, `updated_at`, sync status columns) so that adding
sync later does not require migrating live user data — but no sync code ships until that phase.

## 5. Technology

| Concern | Choice |
|---|---|
| Framework | Flutter + Dart (stable channel), Material 3 |
| State management | Riverpod (code-generation flavor) |
| Local persistence | Drift + SQLite |
| Encryption at rest | Encrypted SQLite — SQLite3 Multiple Ciphers via `package:sqlite3` build hooks (D-010) |
| Routing | go_router |
| Jalali calendar | shamsi_date |
| Key storage | flutter_secure_storage (Android Keystore / Windows DPAPI) |
| Cloud (future) | Supabase |

Concrete pinned versions live in `pubspec.yaml`; the rationale for each dependency lives in
`DECISIONS.md`.

## 6. Feature scope

**In scope for v1 (MVP):**

- Customers (مشتریان) — full name, mobile, company, address, national ID, economic ID, notes
- Products and services (محصولات و خدمات) — name, type, price, unit, description
- Invoices (فاکتورها) — line items, per-item and invoice-level discounts, configurable VAT,
  Jalali issue/due dates, status lifecycle
- Payments (پرداخت‌ها) — partial and full payments, derived payment status
- Dashboard (داشبورد) — real aggregates over real data, Jalali reporting periods
- Backup and restore — encrypted, password-protected, transactional import
- Full Persian RTL UI, light and dark themes, mobile/tablet/desktop layouts

**Explicitly deferred (documented, not built):**
authentication, Supabase cloud sync, PDF generation (interface only in Phase 1), AI features,
payment gateways, subscriptions, push notifications, advanced analytics, scheduled backups,
CSV export.

## 7. Localization requirements

Persian is not a translation layer bolted onto an English app. It is the only UI locale, and the app
is RTL-first.

- **Every** user-facing string is Persian and goes through the localization layer. Zero English
  user-facing text. Zero hardcoded Persian literals inside widgets.
- Code, identifiers, comments, commit messages and everything in `docs/` are **English**.
- Users type Persian (`۰-۹`) and Arabic-Indic (`٠-٩`) digits interchangeably; every numeric input is
  normalized before parsing.
- Search is normalization-insensitive: a customer saved as "علي" must be findable by typing "علی".
- Amounts are displayed in **Toman** by default (Rial where needed) and never as a bare number — the
  unit label is always shown.
- Dates are stored UTC, displayed Jalali. Business and reporting periods are **Jalali**, not
  Gregorian.
- Font: Vazirmatn (SIL OFL), bundled, with a fallback family for Latin and emoji glyphs.

## 8. Architectural principles

1. **Layered and testable.** Widgets → providers → repositories → DAOs. No business logic and no
   database access in widgets.
2. **The money engine is pure Dart.** `core/money/` has zero Flutter imports so it is unit-testable
   without a widget binding. Money is integer Rial; no floating point anywhere in the money path.
3. **Repositories expose domain models**, never Drift-generated row classes.
4. **Snapshots over joins for historical data.** Invoice items store the product title, unit and
   price as they were at issue time. Changing a product's price must never change an existing
   invoice.
5. **Soft deletes everywhere.** Hard deletes cannot be propagated to other devices later.
6. **Theme tokens only.** No hardcoded colors, sizes, radii or spacing inside widgets.
7. **Security is a first-class requirement**, not a later phase.

## 9. Product decisions of record

- Money is stored as integer Rial; percentages as basis points; quantities scaled by 1000.
- Invoice totals follow one authoritative calculation order, with invoice-level discount allocated
  proportionally by line net using the largest-remainder method.
- Only `draft` invoices are editable or deletable. Issued invoices are corrected by cancellation,
  never by silent edit.
- Payment status (`partiallyPaid` / `paid`) is derived from payments and persisted for fast querying;
  `draft` and `cancelled` are set manually.
- The VAT rate is configurable and snapshotted onto each invoice item; changing it must not alter
  existing invoices.
- Web is treated as the least-trusted target and says so, in Persian, in the app.

The full decision log with dates, reasons and alternatives is in `DECISIONS.md`.

## 10. Design intent

A modern, calm business tool: clean hierarchy, generous spacing, restrained color, excellent
readability. **Polished, not decorated** — where polish and restraint conflict, restraint wins. If a
visual element does not improve comprehension or speed, it is removed.

Financial amounts are the most visually salient element on any card or row.
