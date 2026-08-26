# Decision Log

> Append-only. Each entry records the date, the decision, the reason, and the alternatives
> considered. Do not reverse an established decision without a clear reason and a new appended entry.
>
> **Status legend**
> - `ACCEPTED` — settled; established in the project spec or confirmed by the project owner.
> - `PROPOSED` — recommended by the current session, **awaiting owner confirmation**.
> - `AMENDED` — an accepted decision whose *implementation* changed; the intent still stands.

---

## D-001 — UUID v4 primary keys, never AUTOINCREMENT

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Every user-data table uses a `TEXT` UUID v4 primary key.

**Reason.** The app is offline-first today and cloud-synced later. Auto-increment integer IDs
allocated independently on two devices collide the moment those devices sync. UUIDs are
collision-free without coordination, so records created offline on a phone and on a desktop can merge
safely.

**Alternatives considered.** Integer autoincrement (rejected: collides across devices);
device-prefixed integers (rejected: still requires coordination and leaks device identity into keys);
ULID (viable and sortable, but adds a dependency for a benefit — index locality — that is not a
measured problem at this scale).

**Cost accepted.** UUID text keys are larger and slightly slower to index than integers. At the
designed scale (thousands of records) this is not material.

---

## D-002 — Money is integer Rial; no floating point in the money path

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** All monetary values are stored as integer Rial in a Dart `int` (64-bit). Percentages
(tax, percent discounts) are stored as basis points (`int`, 10% = `1000`). Quantities are stored
scaled by 1000 (`quantity_milli`, 1.5 becomes `1500`). `double` and `num` are forbidden anywhere in
the money path. Rounding is half-up at the Rial.

**Reason.** Binary floating point cannot represent decimal currency exactly. Accumulated
representation error produces invoices whose lines do not sum to their total — the single most
damaging class of bug this product can ship. Integer arithmetic is exact.

**Alternatives considered.** `double` (rejected outright); a `Decimal` package (rejected: adds a
dependency and allocation overhead to solve a problem that integer Rial already solves exactly,
because Rial has no sub-unit in practice).

**Web caveat.** On the web, Dart `int` compiles to a JS number, exact only to about 9.0e15. This is
far above any realistic invoice amount in Rial, but the money engine must still guard against values
beyond a defined `kMaxAmountRial` ceiling and reject them rather than silently lose precision.

---

## D-003 — Soft deletes on all user data

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Every user-data table carries `deleted_at INTEGER?`. Deletion sets the timestamp. All
queries filter `deleted_at IS NULL` through a single shared query helper so it cannot be forgotten
per call site.

**Reason.** A hard delete cannot be propagated to another device — the other device has no way to
distinguish "this row was deleted" from "this row has not reached me yet", so the row resurrects on
the next sync. Soft deletes also make accidental deletion recoverable, which matters for financial
records.

**Alternatives considered.** Hard delete plus a tombstone table (rejected: same effect, more schema
and more join complexity).

**Consequence.** Customers and products referenced by any invoice are soft-deleted only, never hard
deleted. The UI must explain this in Persian rather than failing silently.

---

## D-004 — Invoice items snapshot title, unit and price

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** `invoice_items` stores a copy of the product title, unit, unit price (Rial) and the
resolved tax rate at the moment the invoice is created. Invoice pricing is **never** resolved by
joining to the live `products` row at read time.

**Reason.** An invoice is a historical financial document. If a product price changes next month,
every invoice already issued must still show — and total — exactly what it showed when issued.
Joining to live data would silently rewrite financial history.

**Alternatives considered.** Product price-history tables with validity ranges (rejected: correct but
substantially more complex to query and migrate, for no additional benefit here).

**Cost accepted.** The schema looks redundant. That redundancy is the feature.

---

## D-005 — Timestamps stored UTC, displayed Jalali

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Every timestamp is stored as UTC epoch milliseconds (`INTEGER`). Display converts to
the Jalali (Shamsi) calendar with Persian formatting. A localized Persian date string is **never**
the source of truth.

**Reason.** A stored display string cannot be compared, sorted, ranged, or re-localized, and it bakes
one device timezone into the data permanently. Storing an absolute instant keeps queries correct and
keeps the door open for sync across devices in different timezones.

**Alternatives considered.** Storing Jalali Y/M/D integers (rejected: cannot express an instant,
breaks range queries across month boundaries); storing local time (rejected: ambiguous without an
offset).

---

## D-006 — Business and reporting periods are Jalali

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** "فروش این ماه" means the current **Jalali** month. Period boundaries are computed in
Jalali, converted to UTC instants, and then used as query bounds. Business-day boundaries assume
`Asia/Tehran`, derived explicitly rather than hardcoded as a fixed offset.

**Reason.** The user mental model, their tax year, and their business month are all Jalali. Reporting
on Gregorian month boundaries would produce numbers that do not match anything the user recognises.
This is a correctness requirement, not a nicety.

**Alternatives considered.** Gregorian periods with Jalali labels (rejected: actively misleading).

**Note.** Iran does not currently observe DST, but the implementation must not hardcode +03:30 in a
way that breaks for a user whose device is set to another timezone.

---

## D-007 — Riverpod for state management

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Riverpod, code-generation flavor (`riverpod_annotation` + `riverpod_generator`).

**Reason.** Compile-time safe dependency injection, no `BuildContext` needed to read state, testable
providers with overridable dependencies, and first-class async and auto-dispose semantics — which
suits a repository-backed, database-driven app.

**Alternatives considered.** `provider` (less type-safe, `BuildContext`-bound); BLoC (more ceremony
per feature than this app size justifies); `setState` only (unworkable at this scale).

**If it becomes unmaintained.** Riverpod provider boundaries are ordinary Dart classes; migration
would be mechanical but wide. Risk accepted given its maturity and adoption.

---

## D-008 — Drift for persistence

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Drift, with typed table definitions, generated DAOs, and generated migrations.

**Reason.** Compile-time checked SQL, typed row classes, transaction support, reactive query streams,
and — critically — a real migration and schema-dump testing story. Raw SQL string building is
forbidden (see D-018), and the Drift typed API is what makes that practical.

**Alternatives considered.** `sqflite` (no compile-time query checking, weaker migration tooling, no
desktop support without extra packages); raw `sqlite3` FFI (no type safety, hand-written migrations);
Isar/Hive (rejected: not relational — invoices are inherently relational, and a future
Supabase/Postgres sync target is relational).

---

## D-009 — go_router for routing

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** go_router for all navigation.

**Reason.** Real, shareable URLs on Web and working deep links on Windows and Android — both of which
are explicit product requirements. Declarative route definitions also keep navigation out of widget
logic.

**Alternatives considered.** Navigator 1.0 (no URL story on Web); auto_route (comparable, but adds a
second code generator for no benefit Drift and Riverpod generation do not already justify).

---

## D-010 — Encryption at rest via `package:sqlite3` build hooks, using SQLite3 Multiple Ciphers

**Date:** 2026-08-22 · **Amended and confirmed:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** The database is encrypted at rest with SQLCipher on Android and Windows. The encryption
key is a securely generated random key held in `flutter_secure_storage` (Android Keystore / Windows
DPAPI), generated once on first launch, never hardcoded, never logged, never committed.

**Amendment.** the project spec names `sqlcipher_flutter_libs` as the mechanism. **That package was
declared end-of-life on 2026-02-15**, together with `sqlite3_flutter_libs`; both now publish only a
`+eol` version whose description reads *"Not used anymore, update to version 3.x of package:sqlite3
instead."* The native libraries were folded into `package:sqlite3` itself, which since 3.x builds and
bundles them through Dart build hooks.

The equivalent, maintained configuration is a `pubspec.yaml` user-define:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlcipher   # 'sqlite3mc' (SQLite3 Multiple Ciphers) is the alternative
```

**Verified on this machine, 2026-08-22** (Windows, standalone probe): SQLite 3.53.4 with
`cipher_version = 4.18.0 community`; the resulting database file does not begin with the
`SQLite format 3` header, and reopening it without the key is rejected. Encryption at rest is real,
not assumed.

**Sub-decision — `sqlcipher` vs `sqlite3mc`: resolved as `sqlite3mc`.** Both are offered by the same
build hook. This session recommended `sqlcipher` for fidelity to the wording in the project spec. **The
project owner overrode that on 2026-08-23 in favour of `sqlite3mc`**, and the override is better
reasoned than the recommendation it replaced:

1. **Web.** SQLCipher is not available on Web, and Web is a stated target platform. `sqlite3mc`
   works there. The recommendation had silently accepted a target-platform gap.
2. **OpenSSL.** The `sqlcipher` prebuilt links OpenSSL on Windows, Linux and Android — a licensing
   and binary-size cost — and may lag the default SQLite version. `sqlite3mc` needs neither and
   tracks a newer SQLite.
3. **Not locked in.** `sqlite3mc` is SQLCipher-format-compatible via
   `PRAGMA cipher = 'sqlcipher'; PRAGMA legacy = 4;`, so choosing it does not foreclose reading or
   producing SQLCipher-format databases later.
   **This reason holds only if those two pragmas are issued *before* `PRAGMA key`.** Issued
   afterwards they are silently ignored and the file is written with the sqlite3mc default cipher
   (ChaCha20), which SQLCipher cannot read - the escape hatch would exist on paper only. Proven by
   cross-open matrix on 2026-08-23; see D-020.

The governing requirement is **encryption at rest, not the SQLCipher brand**. The project spec
were reworded accordingly on 2026-08-23 to say "encrypted SQLite (SQLite3 Multiple Ciphers via
`package:sqlite3` build hooks)".

**How reason 1 interacts with D-012 — read both before changing either.** D-012 says Web data is
*not* meaningfully encrypted at rest, because any key the page can reach an attacker with the browser
profile can also reach. That remains true and is unchanged by this decision. The Web benefit of
`sqlite3mc` is therefore **not** a security claim: it is that one cipher implementation and one code
path cover all three targets, instead of an encrypted build for Android/Windows and a structurally
different unencrypted build for Web. Fewer divergent paths through the connection-open logic — the
exact place where D-020's silent failure modes live. Do not read this entry as softening D-012, and
do not let the Web build claim encryption at rest.

Configuration:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

**Supply-chain note.** The build hook downloads prebuilt binaries from the package GitHub releases,
verified against sha256 hashes shipped inside the pub package, with SLSA level 3 attestations from
version 3.5.2 onward. `github.com` is reachable from this machine (see D-014). Building from source
is available as a fallback if downloading is unacceptable.

**Alternatives considered.** Pinning the EOL packages (rejected: unmaintained from day one, and it
forces `sqlite3` back to 2.x, which in turn forces Drift down to 2.31 — see D-015); application-level
field encryption (rejected: leaves indexes, table structure and query patterns in the clear, and
breaks `LIKE` and `ORDER BY`); no encryption (rejected: violates the threat model).

---

## D-011 — Offline-first, with a sync-ready schema from day one

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** v1 ships with no network dependency and no account. Every user-data table nevertheless
carries `id` (UUID), `created_at`, `updated_at`, `deleted_at`, `sync_status` and `last_synced_at`
from the first migration, even though nothing reads `sync_status` in Phase 1.

**Reason.** These columns are cheap to add now and expensive to add later: retrofitting them means
migrating live financial data on real user devices. Shipping the columns unused is the low-risk order
of operations.

**Alternatives considered.** Adding sync columns when sync is built (rejected for the reason above).

---

## D-012 — Web is the least-trusted target and must say so

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** The Web build does **not** claim encryption at rest. It shows a clear Persian notice
explaining that data stored in the browser is readable by anyone with access to that browser profile.
No sensitive data goes in `localStorage` or `sessionStorage`; a restrictive CSP ships in
`web/index.html`.

**Reason.** Browser storage (IndexedDB) cannot be meaningfully encrypted at rest against someone who
already has the browser profile — any key the page can reach, an attacker with profile access can
also reach. Simulating security we do not have is worse than disclosing the gap, because the user
would make storage decisions based on a false premise.

**Alternatives considered.** Deriving a key from a user password held only in memory (rejected for
v1: meaningfully better, but it forces a password prompt on every load and still exposes plaintext in
memory and in the WASM heap; revisit in the security-hardening phase); dropping the Web target
(rejected: it is a stated platform).

---

## D-013 — Invoice numbering, and the known multi-device collision risk

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** Invoice numbers follow `{prefix}-{jalaliYear}-{sequence:0000}` (for example
`INV-1405-0001`) with a configurable prefix, a unique index on the full number, and sequence
allocation inside a transaction to prevent a local race.

**Known limitation, deliberately not solved now.** Two devices working offline will both allocate the
same next sequence and collide when cloud sync arrives. This is documented rather than pretended
away. A `device_prefix` concept is reserved in the schema as the intended mitigation.

**Reason for deferring.** The correct fix (per-device ranges, or server-side allocation) depends on
the sync design, which does not exist yet. Building a speculative solution now would likely be the
wrong one.

**Implementation note (2026-08-23, schema v1).** `invoices` stores the formatted `number` *and* the
`number_year` / `number_sequence` it was built from. Allocation is then
`MAX(number_sequence) WHERE number_year = ?` inside a transaction, rather than parsing formatted
strings back apart — a parser that would have to keep working after the prefix is reconfigured.

The unique index on `number` deliberately **covers soft-deleted rows**: an issued number is spent,
and a gap in the sequence is a far better outcome than two different documents sharing one identity.
`settings.device_prefix` is the reserved column named above; it is nullable and unused in Phase 1.

---

## D-014 — pub.dev is the only host named in the lockfile; resolution goes through a mirror

**Date:** 2026-08-22 · **Decided:** 2026-08-23 · **Amended:** 2026-08-23 · **Status:** ACCEPTED (option 2 — see the amendment at the end of this entry; option 1 proved unreachable)

**Context.** Measured on this machine on 2026-08-22:

| Host | Result |
|---|---|
| `pub.dev` | **HTTP 403** |
| `storage.googleapis.com` (Flutter releases) | **HTTP 403** |
| `dl.google.com` / `maven.google.com` (Google Maven) | **HTTP 404** for valid artifact paths |
| `repo.maven.apache.org` | 200 |
| `services.gradle.org` | 200 |
| `github.com` / `api.github.com` | 200 |
| `mirrors.tuna.tsinghua.edu.cn/dart-pub` | 200 |
| `maven.aliyun.com/repository/google` | 200 |

`flutter pub get` fails outright against pub.dev with *"Insufficient permissions to the resource at
the https://pub.dev package repository"* — a geo-block presenting as an authorization error, not a
missing credential. Adding a pub token would not fix it.

**Decision (owner, 2026-08-23): option 1 — a VPN on the developer machine.** `pub.dev` is the
**only** canonical package host. Reachability is a local problem and is solved locally, so that
`pubspec.lock` stays canonical and portable and no other environment inherits this machine's
constraints.

Options as originally presented, for the record:

1. **A VPN or proxy on the developer machine**, leaving `pubspec.lock` pointing at `pub.dev`.
   Cleanest and most portable; keeps the lockfile canonical. ← **chosen**
2. **Environment-scoped mirror** — `PUB_HOSTED_URL` exported in the developer shell profile, plus a
   Gradle `repositories` mirror for `maven.google.com`. Documented in the README, never committed
   into `pubspec.lock` for release builds.
3. **Committed mirror configuration.** Rejected: it pins the project to a third-party mirror
   and makes the lockfile non-portable.

**Consequences, enforced rather than merely documented.**

- The contaminated `pubspec.lock` is **not** to be hand-edited or rewritten. With the VPN up it is
  deleted outright and regenerated by a fresh `flutter pub get` against `pub.dev`. Nothing real
  depends on it yet, so there is no reason to preserve a mirror-derived resolution.
- `pubspec.lock` must contain no `url:` other than `https://pub.dev`. This is enforced by
  `.githooks/pre-commit`, enabled per clone with `git config core.hooksPath .githooks`.
- Mirror configuration is **never** committed — not in `pubspec.yaml`, `pubspec.lock`, Gradle files,
  or CI. The local network situation is documented in `docs/ENVIRONMENT.md` instead.
- `package:sqlite3` build hooks are unaffected: they download prebuilt binaries from GitHub
  releases, which returns 200 from this machine. The hook's `url_pattern` user-define is the
  fallback if that ever changes.

**Superseded.** The VPN never carried this traffic — see the amendment at the end of this entry.
`pub.dev` returned `403` (Google GFE block page) from egress IP `195.74.93.35` throughout, while
`flutter doctor`'s `[✓] Network resources` line passed the whole time and is not a useful signal
for this.

**Current state of the working tree.** The existing `pubspec.lock` was *not* a valid pub lockfile —
it was a 54-line JSON fragment listing five packages as `direct main`, which pub does not produce. It
has been replaced by a valid lockfile generated through the Tsinghua mirror, which is what allowed
`flutter analyze`, `flutter test` and all three platform builds to be verified today. **The mirror
URL is currently written into `pubspec.lock` and must be regenerated once this decision is made.**
The original file is preserved at the session scratchpad as `pubspec.lock.orig`.

**Android-specific risk.** The Android build succeeds today only because a roughly 1 GB Gradle module
cache is already populated locally. Phase 1 adds native plugins (`flutter_secure_storage`, and later
`local_auth`) that pull **new** AndroidX artifacts. With Google Maven unreachable those resolutions
will fail. This must be validated at the very start of Phase 1, before any application code depends
on it.


### Amendment, 2026-08-23 — the VPN is not viable; mirror fallback with guardrails

**Status:** ACCEPTED · supersedes the option-1 choice recorded above, which was never reachable.

**Why option 1 failed.** The owner's VPN routes **per-application** through Proxifier, and `flutter`
and `dart` are not among the routed applications. `flutter pub get` continued to fail with
*"Insufficient permissions to the resource at the https://pub.dev package repository"*, and terminal
egress still showed the original Iranian IP. The option was sound in principle and simply does not
match how this machine's tunnel works.

**Decision: option 2 — the environment-scoped mirror — with guardrails.**

| Concern | Mirror | Verified |
|---|---|---|
| Dart packages | `PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub` | 301→200 |
| Google Maven | `https://maven.aliyun.com/repository/google` | 200 |
| Flutter engine artifacts | `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` | 200 |

**Scope is deliberately narrow — only what is actually blocked gets mirrored.** Measured
2026-08-23: `plugins.gradle.org` 200, `repo.maven.apache.org` 200. Neither is mirrored. Redirecting
traffic that is not blocked would enlarge the supply-chain surface for no benefit, which is the
opposite of the point.

**Where the configuration lives — and one correction to the instruction.** All of it is user-global
and outside the repository:

- `PUB_HOSTED_URL` and `FLUTTER_STORAGE_BASE_URL` as **user environment variables** (`setx`), which
  is the Windows equivalent of a shell-profile export and additionally covers IDEs and Android
  Studio, not just an interactive shell.
- The Google Maven mirror in **`~/.gradle/init.d/cn-google-maven-mirror.gradle`**, *not*
  `~/.gradle/gradle.properties` as originally specified. `gradle.properties` holds properties and
  JVM/proxy settings; it has no syntax for substituting a repository. An init script in
  `~/.gradle/init.d/` is the mechanism Gradle actually provides for user-global repository
  policy, and it is applied automatically to every build by this user.
- The init script **rewrites the URL of Google-Maven repositories in place** rather than clearing
  and rebuilding the repository list. Flutter injects its own engine-artifact repository into every
  Android project; clearing the list would silently delete it and produce a confusing failure.

**Nothing goes into the project.** No mirror or proxy setting in `android/gradle.properties`,
`build.gradle.kts`, `settings.gradle.kts`, `pubspec.yaml`, or CI. The governing requirement is that
**this repository must build unmodified on a machine with normal pub.dev access** — so the committed
tree must contain no trace of this machine's network constraints.

**The lockfile rewrite, and a finding that makes it mandatory rather than tidy.**

`pub` writes the mirror host into every hosted entry of `pubspec.lock`. `tools/sanitize_lockfile`
rewrites those `url:` fields back to `https://pub.dev`. This is safe because integrity does not live
in the URL: each hosted entry carries a `sha256` of the package archive, a mirror serves
byte-identical archives, and pub verifies that hash on download whatever the host. Measured on the
first run: 24 URLs rewritten, **all 24 `sha256` lines byte-identical**, file length unchanged, and
a second run reports "already canonical" — the script is idempotent.

**Finding: `flutter pub get` undoes the sanitization every single time.** Running `pub get` against
a sanitized lockfile does not accept it — pub treats a pub.dev-hosted entry as a different source
from a mirror-hosted one, re-resolves, reports *"Changed 24 dependencies"* and writes the mirror
host back. So sanitizing is **not** a one-time cleanup performed before the first commit; it is a
mandatory post-step on every single `pub get` for as long as this machine resolves through a mirror:

```sh
flutter pub get && sh tools/sanitize_lockfile
```

The script only rewrites `url:` fields inside a description block whose `source:` is `hosted`. A
`source: git` entry also carries a `url:`, but a git URL is a real code location rather than a
redistribution host, and rewriting one would point the build at the wrong repository.

**Backstop.** `.githooks/pre-commit` fails any commit whose `pubspec.lock` names a host other than
`pub.dev`. Given the finding above — that the contamination returns automatically on every `pub
get` — this hook is not belt-and-braces. It is the control that actually holds the guarantee, and
the sanitize script is what makes satisfying it a single reproducible command.

**Residual risk, stated plainly.** Packages are now fetched from a third-party mirror rather than
from pub.dev. The mitigation is the `sha256` recorded per package in `pubspec.lock`: a mirror
serving modified content fails verification. That protects against tampering in transit and at the
mirror, but it does not protect against a compromised *upstream* package, and it means the first
resolution of any newly added dependency establishes its hash from mirror-served content. When the
dependency set changes materially, re-resolving once from a machine with genuine pub.dev access and
diffing `pubspec.lock` is the cheap way to confirm the hashes agree.

**`package:sqlite3` is unaffected.** Its build hooks download prebuilt native binaries from GitHub
releases (200 from this machine), sha256-pinned inside the pub package, with SLSA level 3
attestations from 3.5.2 onward. The encryption path never touches the mirror. If GitHub becomes
unreachable, the `url_pattern` user-define is the fallback.

---

## D-015 — Omit `custom_lint` / `riverpod_lint` so the modern Drift and sqlite3 stack resolves

**Date:** 2026-08-22 · **Confirmed:** 2026-08-23 · **Status:** ACCEPTED

**Owner ruling (2026-08-23).** Approved. *"Lint tooling must never dictate the native stack."*

**Context.** Measured by dependency-resolution probe on 2026-08-22:

- Including `custom_lint` + `riverpod_lint` pins `analyzer` to 8.x, which forces `drift_dev` down to
  **2.31.0**, which forces `sqlite3` to **2.x**, which requires the **end-of-life**
  `sqlite3_flutter_libs` / `sqlcipher_flutter_libs` packages (see D-010).
- Omitting them resolves cleanly to `analyzer` 13.3.0, **drift 2.34.3 / drift_dev 2.34.5**,
  **sqlite3 3.5.2**, `flutter_riverpod` 3.4.2, `riverpod_generator` 4.0.8, `go_router` 17.5.0,
  `flutter_secure_storage` 11.0.0, `shamsi_date` 1.1.1.

**Decision proposed.** Ship Phase 1 without `custom_lint` and `riverpod_lint`, and revisit once
`custom_lint` supports analyzer 13.

**Reason.** The cost is a set of Riverpod-specific lint hints. The benefit is not depending on two
end-of-life packages for the app **encryption layer** — the one dependency where being unmaintained
is least acceptable. This is not a close call.

**Alternatives considered.** Keeping the lints and accepting drift 2.31 plus the EOL native libs
(rejected for the reason above); keeping the lints in a separate analysis-only package workspace
(viable, but adds workspace complexity for a linting convenience — reconsider later).

---

## D-016 — `drift_flutter` is not used

**Date:** 2026-08-22 · **Confirmed:** 2026-08-23 · **Status:** ACCEPTED

**Owner ruling (2026-08-23).** Approved, together with D-015.

**Decision.** Open the database directly with `drift` + `sqlite3` + `path_provider` rather than using
the `drift_flutter` convenience package.

**Reason.** Two reasons, both concrete. First, `drift_flutter` 0.3.1 still depends on the end-of-life
`sqlite3_flutter_libs` and `sqlcipher_flutter_libs` (see D-010), which would reintroduce exactly what
D-015 avoids. Second, the app needs explicit control over the database path (`%APPDATA%` on Windows
per the security requirements), over the order in which `PRAGMA key` is applied, and over
`PRAGMA foreign_keys = ON` — all of which `drift_flutter` abstracts away. The convenience it offers is
roughly thirty lines of setup we want to own anyway.

---

## D-017 — Foreign keys enforced explicitly

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** `PRAGMA foreign_keys = ON` is set on every connection open. `invoice_items.invoice_id`
and `payments.invoice_id` cascade on delete.

**Reason.** SQLite does not enable foreign key enforcement by default, and the setting is per
connection. Without it the constraints in the schema are documentation, not integrity — and an
orphaned invoice item is a silently wrong invoice total.

---

## D-018 — No raw SQL built by string interpolation

**Date:** 2026-08-22 · **Status:** ACCEPTED

**Decision.** All queries use the Drift typed, parameterized API. Where `customStatement` is genuinely
unavoidable it must use bound variables and be reviewed.

**Reason.** Free-text fields in this app include customer names and notes, which will contain
apostrophes and Persian text; interpolating them into SQL is both an injection vector and a
correctness bug waiting to happen.

---

## D-019 — Git initialization and commit policy

**Date:** 2026-08-22 · **Decided:** 2026-08-23 · **Status:** ACCEPTED

**Context.** `git status` reports *"not a git repository"*. There is no version control on this
project at all, and the project spec assumes there is.

**Decision.** `git init` was run on 2026-08-23. The default branch is **`main`**, and
`core.autocrlf` is set to `false` so that line endings are not rewritten on this Windows checkout.
`.gitignore` was hardened **before** initialization, and the first commit captures the scaffold plus
`docs/` before any Phase 1 code — so that Phase 1 is reviewable as a diff rather than as an
undifferentiated pile of new files.

**Commit policy (owner, 2026-08-23).**

- Commit at the **end of each phase** and at meaningful milestones.
- Commit messages in **English**.
- Show `git diff --stat` and the proposed message, then commit. **No per-commit approval needed.**
- **Never** force-push, amend, rebase, or `reset --hard`.
- No remote configured yet.

**Gitignore hardening.** Beyond the `flutter create` defaults, `.gitignore` now covers signing
material (`*.jks`, `*.keystore`, `*.p12`, `*.pfx`, `key.properties`), local secrets (`.env*`,
`dart_define.json`, `config/*.json` — each with an `*.example` escape hatch), exported backups
(`*.factorino-backup`, `backups/`, `exports/`), and local database files (`*.db`, `*.sqlite`, and
the `-wal`/`-shm`/`-journal` siblings). A backup is the entire customer and invoice database in one
portable artifact, and a local `.db` is real user financial data; neither may ever be committed.

**Pre-commit hook.** `.githooks/pre-commit` is versioned in the repository (not `.git/hooks/`, which
does not survive a clone) and is enabled with `git config core.hooksPath .githooks`. It fails the
commit on three conditions: a `pubspec.lock` referencing any host other than `pub.dev` (D-014);
staged signing material, secrets or local databases; and the template application ID
`com.example.factorino` still present in `android/app/build.gradle.kts`.

---

## D-020 — The keyed open sequence, its single choke point, and its named traps

**Date:** 2026-08-23 · **Amended:** 2026-08-23 (proof run) · **Status:** ACCEPTED

**Decision.** On every database connection open, in this exact order:

1. `PRAGMA cipher = 'sqlcipher'` and `PRAGMA legacy = 4` - select the SQLCipher-compatible on-disk
   format (D-010). These are connection configuration; they do not touch the database.
2. `PRAGMA key = "x'<64 hex chars>'"` - the raw 256-bit key from secure storage.
3. `PRAGMA foreign_keys = ON` (D-017).
4. `SELECT count(*) FROM sqlite_master` - forces page 1 to be decrypted **now**, so a wrong key or a
   broken order fails at open rather than at some arbitrary later query.
5. Only then may Drift issue any statement of its own.

This lives in exactly one function, `openEncryptedDatabase` in
`lib/data/database/encrypted_database.dart`, passed as Drift's `NativeDatabase(setup:)` callback.
Verified in the Drift source (`lib/src/sqlite3/database.dart:111`): `_setup?.call(database)` runs
after `useNativeFunctions()` - which registers Dart callbacks and issues no SQL - and before the
version delegate's `PRAGMA user_version`. It is a genuine choke point, not merely the first thing we
happen to call.

### Amendment: "key first, unconditionally" was wrong, and wrong in a way that fails silently

The original entry required `PRAGMA key` to be the *first* statement, with the cipher pragmas after
it. That is what the first Dart-VM probe did, and it appeared to work: the file was encrypted, the
unkeyed reopen was rejected. **It was not producing a SQLCipher-format database.** A second probe
created the same database three ways and cross-opened every combination:

| File created with | opened by `key -> cipher` | by `cipher -> key` | by `key` alone |
|---|---|---|---|
| A: `key -> cipher` | yes | **no** | **yes** |
| B: `cipher -> key` | no | yes | no |
| C: `key` alone (sqlite3mc default cipher) | yes | no | yes |

A and C are interchangeable; B is readable only by itself. `PRAGMA cipher` issued *after* the key is
**silently ignored for the on-disk format** - file A was written with the sqlite3mc default cipher
(ChaCha20), not SQLCipher. Nothing reports this: the file is genuinely encrypted, the key works, the
sentinel is absent from the raw bytes. Only a cross-open reveals it.

The consequence is narrow but real. Encryption at rest - the governing requirement - held either
way. What did not hold is D-010's reason 3, that choosing `sqlite3mc` does not lock the project into
one implementation: a ChaCha20 file cannot be read by SQLCipher, so the escape hatch D-010 relies on
would have quietly not existed. **The cipher pragmas must precede the key**, and the rule is
restated accordingly:

> No statement that reads or writes the database may precede `PRAGMA key`. The only statements
> permitted before it are the cipher-configuration pragmas on the allowlist
> (`kPragmasAllowedBeforeKey`).

The original hazard is unchanged and still confirmed, on the Dart VM and on a real Windows build
alike: a *database* statement before the key produces a plaintext file **and** an exception reading
`file is not a database`, which blames corruption and invites deleting the user's records.

### The named traps

Each of these reads as evidence of encryption and is not. All three were observed, not reasoned
about.

**Trap 1 - `PRAGMA cipher_version` returns empty under sqlite3mc.** Under SQLCipher proper it
reports e.g. `4.18.0 community`. Under sqlite3mc it returns an empty result set on a correctly
encrypted database. Code asserting on it concludes "not encrypted" when encryption is fine - and
would just as happily conclude nothing at all on a plaintext file. **Never use it as the runtime
assertion.**

**Trap 2 - `PRAGMA cipher` echoes the configured value, not the file's actual cipher.** Querying it
returns `sqlcipher` on a connection that was told `sqlcipher`, including an **in-memory database
with no key at all**. It reports what was requested, never what is on disk.

**Trap 3 - a cipher pragma issued after the key is accepted and ignored.** No error, no warning; the
setting simply does not apply to the file format. See the matrix above.

**What to assert instead: the file header.** An unencrypted SQLite database begins with the 16 ASCII
bytes `SQLite format 3\0`. An encrypted one does not. This is implementation-independent, cheap, and
cannot be fooled by connection state. `inspectDatabaseFile` and `assertDatabaseFileIsEncrypted`
implement it.

### Enforcement - not developer discipline

The ordering is a property of the codebase, checked by tests that fail on violation:

| Guarantee | Enforced by |
|---|---|
| Nothing precedes the key but allowlisted cipher pragmas | `assertKeyPrecedesDatabaseAccess`, called **in production** inside `applyConnectionSetup` before the first statement is executed, and asserted directly in `test/data/database/connection_setup_order_test.dart` |
| The cipher pragmas precede the key | same test file - the ordering is asserted against the very list the app executes, not a copy of it |
| Only one code path opens a database | `test/data/database/single_open_path_test.dart` scans `lib/` and fails if any file other than the sanctioned opener mentions `NativeDatabase(`, `sqlite3.open(`, `driftDatabase(` or `pragma key` |
| The on-disk file is never a plaintext SQLite database | `assertDatabaseFileIsEncrypted` at startup; `openEncryptedDatabase` additionally refuses to open an existing `SQLite format 3` file rather than writing more data into it |

The startup assertion is deliberately unforgiving: `absent` and `tooShortToJudge` also throw, so
"no file yet" can never be mistaken for "encrypted". There is no Persian user-facing message and no
recovery path, because the only alternative to failing is writing financial records and third-party
national IDs in the clear.

### Verification - the end-to-end proof

The proof is an integration test, `integration_test/d020_encryption_proof_test.dart`, rather than a
throwaway app: it runs on the real target, is repeatable, and cannot silently rot. A Dart-VM test
cannot substitute for it - the open question is whether the native library is found through
Flutter's own packaging path at runtime, which is exactly what a VM probe skips.

**Windows - PASS, 2026-08-23**, `flutter test integration_test/... -d windows`, 5/5:

```
sqlite3 library : 3.53.4 (package:sqlite3 build hooks, source: sqlite3mc)
database dir: C:\Users\...\AppData\Roaming\io.github.erysaw\factorino   (%APPDATA%, per §7)
keystore: DPAPI returns a stable 256-bit key across calls
header bytes: c1 51 85 73 60 bd 92 8e bd 32 39 d6 72 34 49 00   -> encrypted
sentinel on disk: absent from a raw byte scan
foreign_keys: 1 (on, for the connection Drift actually uses)
unkeyed reopen: REJECTED  SqliteException(26): file is not a database
wrong-key reopen: REJECTED
keyed reopen: 1 row, value intact
out-of-order: plaintext file produced + "file is not a database" - hazard reproduced
startup assert: caught the plaintext database and refused to open it
cipher_version: (empty)                                        <- Trap 1 reproduced
cipher echo: 'sqlcipher' on an unkeyed in-memory database   <- Trap 2 reproduced
```

**Android - PASS, 2026-08-23**, Redmi Note 8 Pro, Android 11 (API 30, arm64-v8a),
`flutter test integration_test/... -d dmbyayb6rombo7ci`, 5/5:

```
sqlite3 library : 3.53.4, from lib/arm64-v8a/libsqlite3mc.so (1.9 MB) packaged in the APK
database dir: /data/user/0/io.github.erysaw.factorino/files   (app-private, per §7)
keystore: Android Keystore returns a stable 256-bit key across calls
header bytes: c4 93 43 23 a6 f7 67 27 8a 9a ee af 90 12 49 75   -> encrypted
sentinel on disk: absent from a raw byte scan
unkeyed reopen: REJECTED  SqliteException(26): file is not a database
wrong-key reopen: REJECTED
keyed reopen: 1 row, value intact
out-of-order: plaintext file produced + "file is not a database" - hazard reproduced
startup assert: caught the plaintext database and refused to open it
cipher_version: (empty)                                        <- Trap 1 reproduced
cipher echo: 'sqlcipher' on an unkeyed in-memory database   <- Trap 2 reproduced
```

Both traps and the ordering hazard behave identically on Android and Windows, so they are properties
of sqlite3mc rather than of one platform's build.

The build hook produces and packages the native library for Android with no manual native setup -
the main technical risk this proof existed to settle. Note that the header bytes differ on every
run: the salt is random, as it should be.

**Installation note.** The first attempt was refused by MIUI with
`INSTALL_FAILED_USER_RESTRICTED: Install canceled by user`, identically via `flutter test`,
`adb install` and `adb shell pm install`. That is the device's "Install via USB" developer setting,
not a project defect; once enabled, installation and the run both succeed.

**Alternatives considered.** Asserting on `cipher_version` (rejected: Trap 1 - it is empty under
sqlite3mc, so the assertion would be permanently wrong in the unsafe direction). Documenting the
ordering in a comment and relying on review (rejected: this is the reason the entry exists - the
failure is invisible in behaviour, so review is the only thing that could catch it). A throwaway
proof app (rejected: it verifies once, then rots).

---

## D-021 — "گزارش‌ها" is omitted from navigation entirely in Phase 1

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** The reports destination does not appear in the navigation shell in Phase 1. It is not
present as a disabled item and not present as a coming-soon placeholder. It arrives in Phase 8, when
it does something.

**Reason.** the project spec permits either omission or a designed coming-soon state, and explicitly
forbids a dead nav item. Omission is the stronger of the two permitted options: a placeholder still
occupies a navigation slot, still has to be designed, localized and tested, and still teaches the
user that a destination exists which does not. Adding the destination in Phase 8 is a smaller change
than maintaining a placeholder through seven phases.

**Consequence.** Phase 1 navigation is: داشبورد · فاکتورها · مشتریان · محصولات و خدمات · تنظیمات.
The route itself is also not registered, so no deep link or typed Web URL can reach a screen that
does not exist.

---

## D-022 — Vazirmatn standard variant, static TTFs, weights 400/500/700

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** Bundle the **standard** Vazirmatn static TTFs at weights 400, 500 and 700 from the
official GitHub release `v33.003`, with `OFL.txt` committed alongside them in `assets/fonts/`.
The Farsi-digit (`FD`) variants are **not** used.

**Reason for the standard variant.** The FD variants substitute Persian digit glyphs at the font
level for ASCII digit codepoints. That moves a display decision into a binary asset where it is
invisible to code review, impossible to unit-test, and impossible to override for the cases that must
render Latin digits. Digit rendering belongs to `core/formatting/`, where it is one
normalizer and one formatter, testable and switchable in a single place.

**Reason for static over variable.** Three fixed weights cover the type scale in the project spec
(body, medium, prominent financial numerals). The variable font carries the full weight axis for a
larger download, and variable-font support in Flutter's text stack is less predictable across the
Android/Windows/Web matrix than static faces.

**Reason for three weights.** 400 body, 500 section titles and emphasis, 700 page titles and the
prominent financial numeral style. Each additional weight is roughly 120 KB per platform bundle for
a distinction the design system does not currently make.

**Licence.** SIL Open Font License 1.1. `OFL.txt` ships in `assets/fonts/` and must remain there;
the licence requires the copyright and licence notice to be distributed with the font.

**Provenance.** Recorded with sha256 hashes in `docs/ENVIRONMENT.md`, because the fonts were fetched
out-of-band from GitHub rather than resolved through a package.

---

## D-023 — `flutter_secure_storage` runs with `resetOnError: false`

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** The `FlutterSecureStorage` instance holding the database key is configured with
`AndroidOptions(resetOnError: false)`. The package default is `true`.

**Reason.** With `resetOnError: true`, a read failure causes the package to **delete the stored
entry** and return null. For an ordinary session token that is a harmless forced re-login. Here the
entry is the only key that can decrypt the user's database: discarding it converts a transient
keystore error - an OS upgrade, a restore onto a new device, a Keystore hiccup - into permanent,
silent loss of every invoice the business has ever issued, and the app would then cheerfully
generate a fresh key and create an empty database on top of the unreadable one.

Failing loudly is correct. The recovery path is the encrypted backup file, which is
why backup is in the MVP rather than a later phase.

**Note.** `encryptedSharedPreferences: true`, named in older guidance, does not exist in
`flutter_secure_storage` 11: AES-GCM with RSA-OAEP key wrapping is now the default and the AndroidX
`EncryptedSharedPreferences` path is gone.

**Alternatives considered.** Accepting the default (rejected: silent total data loss). Catching the
error and re-deriving the key from something stable (rejected: there is nothing stable to derive
from that an attacker holding the device would not also have - that is key-hardcoding with extra
steps).

---

---

## D-024 — UUID v4 comes from `package:uuid`

**Date:** 2026-08-23 · **Reversed the same day by the project owner** · **Status:** ACCEPTED
(supersedes the original entry below)

**Decision.** `lib/core/utils/uuid.dart` is a one-line wrapper over `package:uuid` 4.6.0.

**Reason (owner, overruling this session's original decision).** The original reasoning — that
The project spec asks whether Dart already provides what a dependency would, and `Random.secure()`
does — was sound but landed wrong:

1. **The failure is rare and expensive.** This session's own test notes that a version- or
   variant-masking bug surfaces in roughly one run in sixteen. That is a rare, hard-to-diagnose
   failure on the **primary key of every row in the database**.
2. **It poisons future debugging.** Once sync exists, any strange conflict would put our own ID
   generator first in the suspect list, spending investigation time on something that should be
   settled.
3. **§2 is about gratuitous dependencies.** Unique ID generation for records that must merge across
   devices is not gratuitous — it is exactly the kind of thing worth taking from a maintained,
   widely-audited package.

**How the swap was made.** The generator's property tests were kept and pointed at the wrapper
rather than deleted: format, version and variant bits under all-zero and all-`0xff` random material,
10,000 values checked for collisions, and leading-byte entropy. All four passed against
`package:uuid` unchanged. A dependency swap is precisely when the old guarantees should be
re-checked rather than assumed, and keeping the tests is what made the reversal cheap — the wrapper
means one file changed, because the schema references the tear-off as a column default.

**Original decision, for the record (superseded).** *UUID v4 generated in-repo from
`Random.secure()`, on the grounds that it is a dozen lines, directly unit-testable, and avoids a
supply-chain surface and a version to track for one function.* Rejected for the reasons above.

**Alternatives considered.** Keeping the hand-rolled generator (rejected: see above); a
database-side `randomblob(16)` default (rejected: pushes an identity decision into SQL where it
cannot be unit-tested and would differ on the Web target); timestamp-plus-counter ids (rejected:
predictable, and leaks creation order into a primary key).

---

## D-025 — Denormalized `search_name` columns for Persian-insensitive search

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** `customers` and `products` each carry a `search_name` column holding a normalized copy
of the display name, written by the repository layer and indexed. Search queries match against it.

**Reason.** the project spec requires that a customer saved as "علي" be found by typing "علی" — Arabic
`ي`/`ك` folded to Persian `ی`/`ک`, ZWNJ handled, digits normalized. Normalizing at query time
(`WHERE normalize(full_name) LIKE ?`) would mean a user-defined function applied to every row of
every search, which cannot use an index and degrades to a full scan — against §13's requirement to
design for thousands of records.

**Consequence, stated plainly.** A denormalized column can drift out of sync with its source. The
mitigation is that the repository is the only writer and sets both in the same statement; the risk
is that a future direct DAO write bypasses it. When repositories land, that gets the same treatment
as the soft-delete helper: a test, not a convention.

**Why the column exists before the normalizer.** Schema is the expensive thing to change once a
build with real data is installed; the normalizer is a pure function that can be written and tested
independently. The column defaults to an empty string until the normalizer increment fills it, and
no user data exists yet.

**Alternatives considered.** SQLite FTS5 (rejected for now: a second index structure to keep in sync
and a larger file, for prefix search over a few thousand short names); normalizing only in Dart after
loading all rows (rejected: that is the O(n) UI-thread work §13 forbids).

---

## D-026 — A tax rate of `0` is a real rate, never "absent"

**Date:** 2026-08-23 · **Status:** ACCEPTED

**Decision.** In the §4 resolution order item → invoice → settings default, the engine takes the
first **non-null** value. A rate of `0` stops the search; only `null` continues it.

**Reason.** A tax-exempt line is expressed as `0`, and the obvious shortcut — treating a falsy or
zero rate as "not set" and falling through — would apply the default VAT rate to a line the user
deliberately marked exempt. That is a wrong total on a tax document, and it would look correct to
everyone except the tax authority.

The distinction is carried in the type: `int?` rather than `int` for the item and invoice
overrides, with `null` meaning "inherit" and `0` meaning "zero percent". The settings default is
non-nullable, because the chain has to terminate.

**Consequence.** The resolved rate is snapshotted onto each invoice item (D-004), so an invoice
issued at 0% stays at 0% no matter what the settings default becomes later.

**Alternatives considered.** A sentinel such as `-1` for "inherit" (rejected: it invites arithmetic
on a value that is not a rate, and `-1` reaching the schema would be silently stored); a separate
`isTaxExempt` boolean (rejected: two fields that can contradict each other, and the exemption is
already expressible as a rate).

---

## D-027 — `totalDiscount` reports the discount actually given, and clamps are surfaced

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Origin:** an ambiguity in the project spec, corrected
by the project owner. Supersedes the literal reading implemented in increment (b).

**Decision.** §4 step 9 becomes
`totalDiscount = Σ effectiveLineDiscount + effectiveInvoiceDiscount`, where the *effective* discount
is the amount actually deducted after clamping — never the amount as entered. The project spec was amended to say so.

Additionally: a clamped discount, at either level, is **reported to the caller as data** on
`CalculatedInvoice.warnings` — not absorbed, and not thrown.

**Reason.** The contract's original wording defined the figure as the sum of what was entered.
Implemented literally in increment (b), that made an item discount larger than its line inflate the
reported total above what was actually given — a line worth 1,000,000 with 1,500,000 entered against
it reported 1,500,000 while deducting 1,000,000. The owner's ruling:

> *"The number printed on an invoice must be the discount actually given, or the customer cannot
> reconcile the document by hand — and 'total discount 150' on a line that only ever gave 100 is a
> defect a user will find before we do."*

The wording was wrong, not the implementation of it. Both figures are kept on the line
(`discountRequested` and `discount`), so the document can still show what was typed and the
difference stays auditable.

**Why the clamp is surfaced rather than absorbed.** An over-large line discount is almost always a
data-entry slip rather than an intent. Absorbing it silently is how a wrong figure reaches a document
nobody questions. It is not an exception, because the totals are correct and the invoice is usable —
what is questionable is the input, and only the user can settle that. So the engine reports and the
UI asks. `InvoiceWarning` carries the kind, the line index, and both amounts, so the UI can state the
difference exactly rather than saying "some discount was ignored". It deliberately carries **no
message**: user-facing text is Persian and belongs to the localization layer (§1), which
`core/money/` may not reach.

**The two clamps are kept, for different reasons.** A *line* discount is capped because a line
cannot give away more than it is worth. An *invoice* discount is capped because it is part of the
reconciliation invariant, and an uncapped one produces a negative grand total, which is never a valid
document. The owner confirmed the invoice-level behaviour is unchanged; only its visibility is new.

**Consequence.** `CalculatedLine.discount` changed meaning — it is now the effective amount, so any
future reader of it gets the figure that belongs on the document. The reconciliation invariant is
untouched: it is built from `subtotal`, never from `totalDiscount`.

**Alternatives considered.** Reporting the entered amount and letting the UI derive the effective one
(rejected: two places would compute the same figure, and the document layer must not recompute —
§12 and D-004 both require the renderer to receive already-computed values). Throwing on an
over-large discount (rejected: the invoice is computable and correct, and refusing to compute would
block a user mid-entry over what may be a deliberate write-off of an entire line). Silently rewriting
the user's input down to the line total (rejected: it discards what they typed with no way to
notice).

---

## D-028 — Iran Standard Time is an explicit parameter, not a timezone database

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** `core/date/` derives Iranian business-day boundaries from a named constant,
`kIranStandardOffset = Duration(hours: 3, minutes: 30)`, which every period function takes as a
**parameter defaulting to that value**. Nothing in `core/date/` reads `DateTime.now()` or the device
timezone. `package:timezone` is not added.

**Reason.** D-006 requires that boundaries be "derived explicitly rather than hardcoded as a fixed
offset" in a way that "would break for a user whose device is set to another timezone". The failure
that requirement guards against is using **device local time** — a laptop in Berlin would then
compute German day boundaries and mis-file every evening sale. Passing the offset explicitly avoids
it completely: the answer does not depend on the device at all, which is also what makes every
boundary testable against fixed values.

Iran abolished daylight saving in 2022, so `Asia/Tehran` has no transitions in any range this
application will handle; a timezone database would add a dependency and a runtime initialization step
to return the same number. The parameter is the seam: if Iran restores DST there is one constant to
replace and one parameter through which a date-dependent rule can be supplied, rather than a search
for `3.5` across the codebase.

**Dependency added: `shamsi_date` 1.1.1** (the project spec names it; this is the phase that needed
it). *What it does:* Jalali↔Gregorian conversion and Jalali calendar arithmetic. *Why it is needed:*
the conversion is on the correctness path for every dashboard figure (D-006), not merely on the
formatting path. *If it becomes unmaintained:* the algorithm is fixed, published arithmetic over a
calendar whose leap rule does not change, and `core/date/` wraps it behind this project's own types
— so a replacement is a single-file swap, and the boundary tests (Nowruz anchors, leap years, month
tiling) are what would confirm it.

**Alternatives considered.** `package:timezone` (rejected for now: correct in general, unnecessary
for a fixed-offset zone, and it requires an initialization step a pure library should not have —
revisit if the app ever serves a second timezone). Reading `DateTime.now().timeZoneOffset`
(rejected: that *is* the bug D-006 names). Hardcoding `+03:30` inline at each call site (rejected:
nothing to change when the assumption changes, and nothing to override in a test).

---

## D-029 — `searchKey` produces an opaque key, and folds further than §9 enumerates

**Date:** 2026-08-24 · **Status:** ACCEPTED · Extends D-025.

**Decision.** One function, `searchKey`, produces both the value stored in `search_name` and the term
queried against it. It folds more aggressively than the project spec lists:

| Fold | Named by §9 | Reason for the extras |
|---|---|---|
| Persian and Arabic-Indic digits → ASCII | yes | |
| `ي`/`ك` → `ی`/`ک` | yes | |
| ZWNJ handled | yes | |
| `ى` (alef maksura) → `ی` | no | the same yeh again, from a third keyboard layout |
| `ة`/`ۀ` → `ه` | no | borrowed names are written both ways by the same person |
| `آ`/`أ`/`إ`/`ٱ` → `ا` | no | the hamza and madda marks are typed inconsistently |
| diacritics, tatweel, bidi controls dropped | no | invisible to the user, so a mismatch caused by one is undiagnosable |
| **all whitespace removed** | no | see below |
| Latin lowercased | no | |

**The result is a key, not a display string.** It is stripped of spacing and case and must never be
shown to the user. The display name is stored separately, exactly as typed.

**Why whitespace is removed.** Persian compounds are written three ways by the same person —
`علی‌رضا` (ZWNJ), `علی رضا` (space), `علیرضا` (joined). Folding ZWNJ alone would still leave the
spaced form unmatched. Removing spacing entirely reduces all three to one key, and a substring `LIKE`
search over a space-free key still matches each individual word of a multi-word name, so nothing is
lost. Tested.

**What is deliberately *not* folded.** `ئ` (U+0626, yeh with hamza above) is a distinct Persian
letter, not a variant: `رئیس` and `رییس` are different spellings, and merging them would make search
answer a question it was not asked. The rule applied is *the same letter written differently*, never
*letters that look similar*.

**Enforced structurally, not by convention.** `test/core/formatting/single_normalizer_path_test.dart`
fails the build if anything in `lib/` outside `core/formatting/` open-codes a character fold, or
references `searchName` without calling `searchKey`. This is the treatment the database opener gets
(D-020), for the same reason: **the failure is silent.** Two call sites that normalize almost the
same way produce no error and no crash — the write succeeds, the index builds, the query runs, and a
customer saved yesterday simply cannot be found. Neither side looks wrong in isolation.

The guard scans code only, not comments: naming کد ملی in a doc comment describes a field, and a
comment cannot execute a fold. It carries a `// normalizer-exempt: <reason>` escape hatch, so the raw
form is a visible, justified choice rather than a forbidden one.

**Verified end to end, not only as a unit.**
`test/data/database/search_name_roundtrip_test.dart` writes through the real encrypted database and
searches with a parameterized `LIKE`, because the normalizer can be perfect and the search still fail
— if one side folds and the other does not, or if SQLite compares the stored bytes differently from
what Dart produced.

**Alternatives considered.** Normalizing at query time with a user-defined function (rejected in
D-025: it cannot use an index and degrades to a full scan). Folding only what §9 enumerates
(rejected: it would leave `علی رضا` unmatchable against `علی‌رضا` — the same failure §9 exists to
prevent, one character over). Unicode NFKC normalization (rejected: it does not fold the
Arabic/Persian letter pairs at all, since they are distinct code points with distinct meanings in
Arabic, and it would fold things this app has no reason to touch).

---

## D-030 — The national-ID checksum validates a format, never an identity

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Owner ruling**, arising from a finding in increment
(c).

**The finding.** The official Iranian national-ID (کد ملی) checksum cannot distinguish every pair of
distinct numbers. The rule takes the weighted sum of the first nine digits modulo 11 and requires the
check digit to be `r` when `r < 2` and `11 − r` otherwise — so remainders **1 and 10 both produce the
check digit 1**. Any data-entry error that moves the weighted sum between those two remainders is
invisible to the check. `0079542311` and `0079542131` differ by a transposition and **both validate**,
under this implementation and under any correct implementation of the published algorithm.

This is a property of the algorithm, not a defect in `core/formatting/national_id.dart`. It is
recorded as a passing test (`national_id_test.dart`, *"a transposition can survive, and that is the
algorithm, not a bug"*) so that nobody later "fixes" it by inventing a stricter rule than the one the
government issues numbers under.

**Decision — a UI constraint that binds increment (f) and every screen after it.**

The Persian copy for this field says that the **format** is valid. It must never say, imply, or be
translated as *confirmed*, *correct*, *verified*, *authenticated*, or *identity established*.

| Acceptable | Not acceptable |
|---|---|
| «فرمت کد ملی معتبر است» — the format is valid | «کد ملی تأیید شد» — the national ID is confirmed |
| «کد ملی نامعتبر است» — invalid, on failure | «کد ملی صحیح است» — the national ID is correct |
| No affirmative message at all on success | Any green "verified" badge or check-mark treated as identity |

**Reason.** A passing checksum narrows the space of typos; it does not close it, and it says nothing
whatever about whether the number belongs to the person named on the invoice. A user told their entry
is "verified" will stop checking it — which is exactly when a transposed digit that happens to
checksum survives onto a tax document. The wording is the only thing standing between a probabilistic
check and a false assurance, and it costs nothing to get right.

Failure messages are unaffected: a value that fails the checksum is genuinely invalid and may be
called so plainly.

**Consequence.** Increment (f), and Phase 2 (Customers), must satisfy this in the ARB strings
themselves, not in a code comment. A reviewer should be able to check compliance by reading the
Persian copy alone.

**Scope.** The same reasoning applies to any future validator that is a checksum rather than a
lookup — the economic ID and IBAN/Sheba being the likely candidates. State the format, never the
identity.

---

## D-031 — The domain boundary is a directory split, not a naming convention

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** the project spec's *"repositories expose domain models, never Drift-generated row
classes"* is enforced by making the drift types **unreachable** from the boundary, rather than by
asking reviewers to notice:

```
lib/data/models/                    domain entities + enums   -- no drift import
lib/data/repositories/*.dart        interfaces                -- no drift import
lib/data/repositories/drift/*.dart  implementations + mapping -- drift lives here
lib/data/providers.dart             composition root          -- sees both
```

A signature cannot name a type its library does not import, so an interface in
`repositories/` **cannot** return a row class. `domain_boundary_test.dart` fails the build if
`package:drift/`, `app_database.dart`, `database/tables/` or a `.g.dart` import appears in either
drift-free directory, and checks that every interface has a `drift_*.dart` implementation beside it.

**Reason.** The rule as written is a code-review rule, and code review is exactly what misses it:
returning `CustomerRow` instead of `Customer` compiles, runs, and reads as ordinary code at the call
site. Nothing goes wrong until row types are threaded through providers and widgets, at which point
the layering is gone and the fix is a refactor rather than an edit. Every other rule in this project
that fails silently is enforced by a test that scans `lib/` — the single database opener (D-020), the
soft-delete filter (D-003), the single normalizer (D-029). This is the same treatment.

**Three supporting changes.**

1. **Row classes are named `*Row`** via `@DataClassName` on every table (`CustomerRow`,
   `ProductRow`, `InvoiceRow`, `InvoiceItemRow`, `PaymentRow`; `SettingsRow` already was). Drift
   otherwise names the row class for `Customers` **`Customer`** — colliding with the domain model of
   the same name, and forcing every file that touches both to disambiguate with an import alias.
   The suffix also makes a leak legible on sight. This is a Dart-level rename only: the generated
   SQL is unchanged, `drift_schemas/drift_schema_v1.json` is byte-identical, and **no migration is
   required**.

2. **The enums moved to `data/models/`** — `SyncStatus`, `ProductType`, `InvoiceStatus`,
   `PaymentMethod`. They were declared beside the tables that store them, which meant a domain model
   carrying one would have had to import a file that imports drift. The tables import the enums now;
   the dependency runs schema → domain, never the reverse.

3. **The soft-delete guard was extended to `selectOnly`**, and `selectOnlyAlive` added beside
   `selectAlive`/`countAlive`. Aggregates were an uncovered gap and the worse half of it: a `select`
   that forgets the filter returns visibly deleted rows, while a `sum` that forgets it just returns a
   larger number on a dashboard, with nothing to compare it against.

**Consequence.** One deliberate exemption exists so far: invoice-number allocation reads
`MAX(number_sequence)` **including** soft-deleted invoices, because a spent number stays spent
(D-013). It carries `// soft-delete-exempt:` and a reason, which is the escape hatch working as
intended rather than being worked around.

**Alternatives considered.** A lint rule (rejected: `custom_lint` is the package D-015 excludes for
dragging the analyzer, and with it drift and sqlite3, backwards). Scanning repository signatures for
`Row` types with a regex (rejected: fragile against generics, typedefs and inference, and it would
police the symptom rather than remove the possibility). Trusting the convention (rejected: that is
what the rule already was).

---

## D-032 — Riverpod composition root, with a synchronous overridden database provider

**Date:** 2026-08-24 · **Status:** ACCEPTED · implements D-007.

**Decision.** `lib/data/providers.dart` is the data layer's composition root. `appDatabaseProvider`
is **synchronous** and its default implementation **throws**; `main()` opens the database and
overrides it with the result. Every repository provider is typed as its **interface**.

**Dependencies added** (the project spec requires each to be justified):

| Package | Version | What it does | If unmaintained |
|---|---|---|---|
| `flutter_riverpod` | 3.4.2 | state management and DI (D-007) | provider boundaries are ordinary Dart classes; migration is mechanical but wide |
| `riverpod_annotation` | 4.0.6 | the annotations for the generator | removed with the generator |
| `riverpod_generator` | 4.0.8 | generates the provider boilerplate | the generated providers can be hand-written; it is boilerplate, not behaviour |

**D-015 was re-verified rather than assumed.** Adding these re-resolved 121 packages, and drift
2.34.3 / drift_dev 2.34.5 / sqlite3 3.5.2 / analyzer 13.3.0 are **unchanged** — the modern native
stack held, because `riverpod_lint` and `custom_lint` are still deliberately absent (D-015). Had they
been included, the analyzer pin would have dragged sqlite3 back to 2.x and reintroduced the
end-of-life native packages D-010 exists to avoid.

**Reason for a synchronous provider with an override.** Opening the database is a fail-loud,
must-succeed step: it derives the key from the OS keystore, opens with the cipher pragmas in the one
correct order, migrates, and asserts against the bytes on disk that the file is really encrypted
(D-020). If any of that fails, the application has no business rendering a partially-working UI while
a `FutureProvider` resolves — and every dependent provider would be `AsyncValue`-wrapped forever
after, for a value that is never legitimately absent.

So `main()` does it first and overrides. The consequences are all in the right direction: dependent
providers are plainly synchronous, the failure is a crash at startup rather than an error state
threaded through the UI, and **the override is the test seam** — `providers_test.dart` swaps the
whole data layer onto a temporary encrypted file in one line, which is exactly what a screen in
increment (f) will need.

**The default throws rather than opening a database itself.** A convenient fallback would give every
call site a way around `openEncryptedDatabase`, which is the single choke point D-020 depends on. The
message names `main()` and the decision, because the developer who hits it is the one who needs it.

**Note for a future session.** Riverpod 3 wraps an error thrown inside a provider in a
`ProviderException`; a test asserting on the inner type directly will not match. Assert on the
message.

**Alternatives considered.** An async `FutureProvider<AppDatabase>` (rejected for the reasons above).
Passing repositories down the widget tree by constructor (rejected: D-007 settled Riverpod, and this
would reintroduce the prop-drilling it exists to avoid). Instantiating repositories inside widgets
(rejected: it is the layering violation §3 forbids, and it would make the data layer untestable
without a widget binding).

---

## D-033 — The design language, and tokens enforced rather than offered

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** The visual language, settled in `core/theme/` and enforced by
`theme_tokens_only_test.dart`.

### One accent: Persian turquoise

`#11726B` in light, `#5ED2C5` in dark. The colour of Isfahan tile work, deepened until it behaves
like a business colour. Chosen over Material blue because a tool for Iranian businesses should not
look like a generic dashboard, and over a saturated turquoise because at full strength that is a
craft-fair colour, not something to look at for eight hours while reconciling invoices.

It appears sparingly: primary actions, the selected navigation destination, focus rings.

### Colour means status, and nothing else means anything

Six semantic pairs — draft, unpaid, partiallyPaid, paid, cancelled, overdue — each a foreground and
a container, exposed as a `StatusPalette` theme extension.

**Money is deliberately *not* accent-coloured.** It is rendered in the strongest neutral. The moment
colour is also used for emphasis, colour stops being legible as meaning: a green amount beside a
green badge is two signals competing, and the badge loses. Prominence for money comes from the type
scale instead, which is what §10 actually asks for.

Individual choices worth defending: unpaid is **amber, not red** — an invoice inside its terms is
the normal state of business, not a problem; red is reserved for overdue, so red in a list means one
thing only. Draft is the quietest of the six, a plain neutral, because a draft should not compete
with a real invoice. Cancelled is a muted mauve-grey: recognisably not the draft neutral, and
without the urgency of red, because a cancelled invoice needs no action.

### Warm neutrals, and dark designed separately

Light neutrals are warm (`#FAFAF8` page, `#FFFFFF` cards): a pure-grey business tool reads as
clinical, and the warmth also stops the turquoise turning green against it. Dark neutrals go the
other way, very slightly cool (`#0F1211` page, `#161A19` surface) — a warm dark surface reads brown
next to a turquoise accent.

Dark is **not an inversion** (§10). Every value is picked for its own background: the accent is
lifted and desaturated so it does not glow, body text is `#E6E9E7` rather than pure white (which is
the usual cause of what people call dark-mode eye strain), the page is not black (halation against a
bright accent, and shimmering scroll edges on OLED), and the six status colours are re-picked at
dark-background contrast rather than lightened mechanically.

### Borders, not shadows

Structure comes from a hairline border plus a surface step. The reason is dark mode: a shadow is
nearly invisible on a dark surface, so a shadow-based hierarchy looks correct in light and collapses
in dark. Elevation is kept for genuine overlays — menus and dialogs — where a shadow is the only cue
that separates layers.

### The type scale

Vazirmatn 400/500/700 (D-022), with a per-platform fallback list for emoji and any glyph it lacks.

| Token | Size / line | Weight | Use |
|---|---|---|---|
| `pageTitle` | 24 / 1.45 | 700 | one per screen |
| `sectionTitle` | 17 / 1.5 | 500 | card and section headings |
| `body` / `bodyStrong` | 15 / 1.65 | 400 / 500 | prose; emphasised values |
| `caption` | 13 / 1.6 | 400 | secondary information |
| `label` | 12 / 1.5 | 500 | field labels, table headers, badges |
| **`amountLarge`** | **28 / 1.35** | **700** | **the prominent financial numeral style (§10)** |
| `amountMedium` | 19 / 1.4 | 700 | the amount in a list row |
| `amountSmall` | 15 / 1.5 | 500 | a table cell or secondary total |
| `identifier` | 14 / 1.5 | 400 | invoice numbers, national IDs, phone numbers |

Two Persian-specific choices. **Line heights are taller than a Latin scale would use** — the script
has deep descenders and stacked diacritics, and at 1.2 the descenders of one line touch the ascenders
of the next, which is the commonest way Persian typography is got wrong in an app built to Latin
defaults. And **every numeral style enables `tnum`**: without tabular figures a column of amounts
jitters by a few pixels per row, which makes a financial table feel unreliable without the reader
being able to say why.

### Enforcement

`theme_tokens_only_test.dart` fails the build on a literal colour (`Color(0x…)`, `Colors.…`) or a
literal size, radius, spacing, font size or duration anywhere outside the three token files.
Verified to bite by introducing both kinds of violation and watching it fail.

This is the rule most likely to erode quietly. Nothing breaks when someone writes
`EdgeInsets.all(14)` — it compiles, it looks fine in the one place they were looking, and the next
person copies it. A hundred screens later the layout is subtly irregular in a way nobody can point
at, and the design system is a folder of constants nothing reads. `// tokens-exempt: <reason>` is
the escape hatch, so an exception is visible and justified rather than forbidden.

**Alternatives considered.** A generated Material colour scheme from a seed (`ColorScheme.fromSeed`)
— rejected: it produces a competent palette nobody chose, and it derives dark from light, which is
exactly what §10 forbids. Shadow-based elevation (rejected above). Enforcing tokens by review
(rejected: that is what the rule already was).

---

## D-034 — Every user-facing string through the ARB, including the ones outside Dart

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** Persian is the only locale, pinned rather than inherited from the device; every
user-facing string comes from `lib/core/localization/arb/app_fa.arb` through the generated
`AppStrings`; and **no Arabic-script character may appear in code anywhere in `lib/`**, enforced by
`no_hardcoded_strings_test.dart`.

**The locale is pinned, not detected.** `supportedLocales` has one entry and `locale` fixes it, so a
user whose phone is in English still gets a Persian invoicing application — because that is what the
product is (§1), not a preference to negotiate.

**RTL is set once at the root.** The Persian locale already gives every descendant
`TextDirection.rtl`; the explicit `Directionality` in the app builder covers what renders outside
that subtree — overlays, dialogs, route transitions built from the navigator — so no widget ever has
to fight direction locally (§9). The navigation rail lands on the right with no positioning code at
all, because `Row` resolves against the ambient direction.

**Why the guard, when the strings are already Persian.** Hardcoding a Persian string in a widget is
not a bug: it renders correctly, in the right language, and looks finished. It becomes a problem
later and all at once — the day a second locale is added, or a wording rule has to be applied
consistently, or someone needs to check every user-facing string against a constraint like D-030's.
By then the strings are scattered across fifty widgets and the localization layer is a fiction. The
guard makes that impossible on the first line rather than expensive on the thousandth.

Comments are exempt — naming کد ملی in a doc comment is documentation, not copy — and
`// l10n-exempt: <reason>` covers the real exceptions. Three exist so far, all in
`core/formatting/number_display.dart`: the thousands separator, the decimal separator and the
percent sign. Those are **numeric punctuation, not copy** — properties of how Persian writes numbers
rather than phrases anyone would translate — and putting them in the ARB would invite someone
editing text to "correct" the separator to a comma.

**D-030 is checked mechanically now.** The same test asserts that `nationalIdFormatValid` names the
format and contains none of تأیید / تایید / صحیح / احراز. The constraint the owner set is no longer
only in a decision log; it fails the build if the copy drifts.

### Strings the ARB cannot reach

The platform manifests are user-facing and are not Dart: the Windows window title, the Android
`android:label`, and the web `<title>` and manifest. All four said `factorino` and now say
`فاکتورینو`, matching `appTitle`.

**The Windows one is written as `\u` escapes, not as glyphs.** MSVC reads the source with the system
ANSI codepage unless told otherwise, and a pasted Persian literal in `L"…"` compiled cleanly and
produced mojibake in the title bar — found by screenshotting the running build, not by any test. The
escapes carry no encoding assumption. This is the same lesson as the fold tables in
`persian_text.dart`: where the encoding of the source is not guaranteed, name the character by code
point.

**Alternatives considered.** Leaving the platform titles in English as a brand name (rejected: the
app already renders its own name in Persian, so the title bar would be the one place it did not).
`intl_utils` or another string-management package (rejected: `gen-l10n` ships with Flutter and does
this, and §2 asks whether the framework already provides it).

---

## D-035 — One logging wrapper: closure messages, nothing in release, and a guard that is the real control

**Date:** 2026-08-24 · **Status:** ACCEPTED · implements the project spec.

**Decision.** All logging goes through `AppLog` in `lib/core/security/app_log.dart`.
`test/core/security/logging_path_test.dart` fails the build if anything in `lib/` writes output
another way, or if a sensitive field name appears inside an `AppLog` call.

**Four properties, in the order they matter.**

1. **Nothing is emitted in a release build — not even an error.** The guard is `kReleaseMode`, a
   `const bool`, so the body is removed by the compiler rather than skipped at runtime. This is
   deliberately stronger than §7's "debug logging is stripped": in a release build the only
   destinations are logcat on Android and stdout on Windows, and both are readable by exactly the
   person the threat model is worried about. A line the developer cannot read but the holder of the
   device can is worse than no line.

2. **The message is a closure.** `AppLog.debug(() => '...')`, not `AppLog.debug('...')`. With an
   eager argument the interpolation runs at the call site *before* the call, so a sensitive value is
   materialized into a string in a release build even though nothing prints it. The closure is never
   invoked when the release guard returns first.

3. **The static guard is the control, not the scrubber.** `logging_path_test.dart` scans every
   `AppLog` call — following it across line breaks by balancing parentheses, because the formatter
   wraps these calls and a line-at-a-time scan would see `AppLog.debug(` on one line and
   `customer.fullName` on the next and match neither. The banned accessors are the §7 list:
   `nationalId`, `economicId`, `mobile`, `fullName`, `companyName`, `address`, `notes`,
   `grandTotal`, `subtotal`, `unitPrice`, `hex`, and their neighbours.

4. **The runtime scrubber is a backstop for shapes only, and says so.** `scrubForLogging` replaces
   runs of ten or more digits (national ID, economic ID, mobile, large amounts), runs of 32 or more
   hex characters (key material), and the wrapped key form the opener builds. It **cannot** catch a
   customer name, a company name, an address, or an amount below ten digits — those have no shape,
   and the entry says so rather than implying coverage it does not have. What it does catch is the
   value that arrives inside something the guard could not see through: a database exception's
   message, most plausibly.

**Two supporting decisions.**

*The framework's own error path is routed through it.* `FlutterError.onError` and
`platformDispatcher.onError` are set in `main()`. This is not hypothetical: a layout overflow dumps
the offending widget subtree, and in this application that subtree contains `Text` widgets holding
customer names and amounts. On the default path it reaches logcat verbatim, on any build.

*`platformDispatcher.onError` returns **false**.* It logs and then lets the platform terminate.
Returning `true` was tried and is recorded here as the mistake it was: a failure inside
`openAppDatabase` was swallowed, `runApp` was never reached, and because the Windows runner shows
its window only after the first frame, the result was a process running forever with no window and
no message anywhere — the exact silent degradation D-020's fail-loud startup exists to prevent.
Found by building and running it.

**Where the guard fired first.** On its own author: a doc comment in `app_log.dart` mentioning
`PRAGMA key` tripped `single_open_path_test.dart`, which scans comments as well as code. The comment
was reworded. The older guard was right to be broad and was not weakened.

**Alternatives considered.** `package:logging` (rejected: §2 asks whether the framework already
provides it, and `dart:developer` does — plus a package would have to be wrapped anyway to hold the
release strip and the scrubber). Relying on review (rejected: the failure is silent by construction —
a logged phone number produces no error, no crash and no visible defect).

---

## D-036 — The create/edit forms move into Phase 1 increment (f)

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Owner ruling.**

**Decision.** Minimal create/edit forms for customers and for products ship in increment (f), rather
than waiting for Phase 2 and Phase 3.

**Reason.** Two requirements already in force could not be met without them, and the conflict was
put to the owner rather than resolved by quietly dropping one:

- **§10 requires every empty state to carry a clear call to action**, and §15 forbids fake
  functionality. A "افزودن مشتری" button that opened nothing would violate the second to satisfy the
  first; omitting it would violate the first. Only a real form satisfies both.
- **D-030 requires the national-ID copy to state the format and never the identity.** That
  constraint was enforced against the ARB by `no_hardcoded_strings_test.dart`, which cannot tell
  whether the copy is *used* correctly — an ARB entry that says the right thing is worthless beside
  a green "verified" tick. The form is the call site that makes the rule checkable against
  behaviour, and `customer_form_screen_test.dart` now checks it there.

There is also a plain practical reason: with no way to enter data, the four screens could only ever
be reviewed empty.

**Scope kept deliberately small.** Required-field validation, Iranian mobile validation accepting
`0`/`+98`/`0098` and any digit set, the national-ID checksum, and Toman-entry money parsing that
never touches a `double`. Detail views, filters, sorting, bulk actions and the rest of Phases 2 and
3 are untouched.

**Consequence for the ROADMAP.** Phases 2 and 3 keep their entries and lose only the form slice.
They are not complete and must not be marked so.

---

## D-037 — The desktop data table is a virtualized list, not `DataTable`

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** `core/widgets/app_table.dart` provides `AppTableHeader` + `AppTableRow`, laid out from
one shared list of `TableColumnSpec`s and rendered over a `ListView.builder`. Material's `DataTable`
and `PaginatedDataTable` are not used.

**Reason.** `DataTable` builds every row it is handed. A list of five thousand invoices would build
five thousand rows of widgets to show twenty — the O(n) UI-thread work §13 forbids, invisible at
fifty rows and fatal at five thousand, which is the definition of a defect shipped rather than
discovered. A header plus a builder-backed list is a real table that is also virtualized, and
`customers_screen_test.dart` asserts that a full page of rows does not build a full page of widgets.

Sharing one column list between the header and every row is the second half: a hand-built table
whose header drifts out of alignment with its columns looks like a data error rather than a layout
one.

**An RTL finding, recorded because it is counter-intuitive.** The amount column must **not** be
end-aligned. `AlignmentDirectional.centerEnd` resolves to the *left* edge in RTL, and numbers render
left-to-right whatever the surrounding direction — so pushing an amount to the trailing edge lines
figures up by their *first* digit and leaves the units digit ragged, which is exactly what tabular
numerals (D-033) exist to prevent. Leading alignment in RTL puts the digits' right edge on a common
line. The flag is documented on `TableColumnSpec.alignEnd` as the trap it is. Found by looking at
the running build; no test would have caught it.

**Alternatives considered.** `DataTable` with pagination controls (rejected: it solves the build
cost by refusing to scroll, and a paged table is a worse reading experience than a scrolling one for
a list the user is scanning). `TwoDimensionalScrollView` (rejected: the extra axis is not needed —
these tables scroll vertically only).

---

## D-038 — Lists page at the query level, through one widening window

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** Every list screen drives its query from a `ListQuery` (`core/utils/list_query.dart`)
carrying the search term and a row limit. The limit reaches SQL. "Load more" widens the window by
one page; **starting a search resets it to one page.**

**Reason.** §13 requires lists to work at thousands of rows. Virtualized rendering alone does not
achieve that: a `ListView.builder` over ten thousand rows builds only the visible widgets, but the
query behind it still loaded ten thousand rows, mapped them all to domain models and holds them in
memory. The limit has to reach the database, and `ListQuery` is what carries it there.

**Why one value rather than two providers.** The term and the limit change together or they are
wrong together: a user who scrolled through two thousand rows and then typed three letters must not
have the app ask for two thousand matches of those letters. Held as two providers they could differ
for a frame, and the symptom would be a needlessly enormous query rather than an error.

**Why a widening window rather than an offset.** The underlying read is a live query. A stream per
offset page would have to be merged and re-merged on every write, with rows able to shift between
pages in between. One widening window over one stream stays consistent with itself.

**Why an explicit control rather than infinite scroll.** A list that keeps loading as you scroll
gives no way to tell a long list from a slow one, and no way to reach the end of anything. On a
financial record, "is that all of them?" is a real question.

---

## D-039 — "Issued" excludes drafts, so a sales figure does not move while the user types

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Corrects (d)**

**Decision.** `InvoiceRepository.totalIssuedRial` and `watchIssuedCountInPeriod` count only invoices
in `unpaid`, `partiallyPaid` or `paid`. Drafts and cancellations are both excluded. The set is named
once, as `kIssuedInvoiceStatuses` in `data/models/invoice_status.dart`.

**What it corrects.** As delivered in increment (d), `totalIssuedRial` excluded only cancelled
invoices, and a test asserted that behaviour explicitly. So a draft counted as revenue. Nothing on
screen depended on it until (f2), which is why it survived review — but the moment the dashboard
existed, "فروش این ماه" would have climbed as the user typed an invoice they had not issued, and
dropped again when they cleared it. A sales figure that moves while nothing has been sold is the
kind of wrong number that gets believed, because it moves for a reason the user can half-explain.

**Reason.** The method already promised this in its name: a draft is by definition not issued. The
codebase says so elsewhere too — `PaymentRepository.record` refuses money against a draft on the
grounds that it is "not yet a claim on anyone". Revenue recognised on a document that is not a claim
on anyone is not revenue.

**Why a positive list rather than "not draft and not cancelled".** The two read identically today and
fail differently tomorrow. If a status is ever appended to the enum, a negation folds it silently
into every revenue figure, while the list silently leaves it out. Of two silent outcomes, an
understated total someone questions beats an overstated one nobody does.

**Consequence for the dashboard.** The count tile counts exactly the population the sales tile sums,
which is why its label is "فاکتورهای صادرشده" and not "فاکتورهای این ماه" — the caption underneath
already names the month, and a count over one population beside a total over another is a pair of
numbers the user cannot reconcile. Reconciling is the only thing a dashboard is for.

**Alternatives considered.** Leave it and filter in the feature layer — rejected: the same wrong
figure would then be one call site away from returning, and the repository would still be answering
a question wrongly. Rename the method to `totalRial` — rejected: the name was right and the
behaviour was wrong.

---

## D-040 — The invoice list resolves its customer name in the query, as `InvoiceListItem`

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** `InvoiceRepository.watchList` returns `InvoiceListItem` — an `Invoice` plus the
customer's name — produced by one joined query. `Invoice` itself is unchanged and still carries only
`customerId`.

**Reason.** A list of invoices showing customer ids is useless, and a list that resolves each id
separately is an N+1 read issued from the presentation layer: invisible at ten invoices, ruinous at
five thousand, and forbidden by §13 and by §3's rule that widgets do not reach the data layer. One
join, one query, one stream.

**Why a new model rather than a field on `Invoice`.** `Invoice` is the header as stored. A customer
name is not stored on it and must not appear to be — the detail aggregate already resolves the
customer separately, and D-004's snapshot rule turns on being able to say precisely which fields are
historical and which are live. A separate list-shaped model keeps that line visible.

**What it deliberately does not carry: payments.** Nothing on `InvoiceListItem` would let a widget
compare payments against a total and decide for itself whether an invoice is paid. That
determination is made in `PaymentRepository` inside the same transaction as the payment write and
persisted (§6); a second, independent answer computed at display time is exactly how a badge comes to
contradict the payments listed beneath it. The UI cannot recompute it because the UI is not given the
inputs — design by impossibility rather than by convention.

**The customer side of the join is not filtered by `deleted_at`.** This is the one place a read
deliberately bypasses D-003, and it corrects a defect found while building (f2): `findDetail` used
`selectAlive` on the customer and returned `null` when the customer had been soft-deleted, so an
invoice became unopenable the moment its customer was removed — and the invoice list would have
dropped it entirely. Meanwhile the delete dialog promises the user, in Persian, that invoices already
issued to that customer "stay untouched and their amounts do not change". §6 guarantees such a
customer is soft-deleted only and never removed, so the row is always there to read. Both call sites
now read it, and a repository test covers the case.

---

## D-041 — One clock reading per frame, and overdue compared on Jalali days

**Date:** 2026-08-24 · **Status:** ACCEPTED

**Decision.** "Now" is a Riverpod provider (`core/utils/clock.dart`), read once and passed down.
`overdue` is derived from it at display time by `invoiceStatusViewOf`, and an invoice is overdue only
once the **Jalali day** of its due date has ended in Tehran.

**Why a provider rather than `DateTime.now()` at each site.** Two readings inside one frame can
straddle midnight. The dashboard resolves a Jalali month from now and the invoice list ages invoices
from now; with separate readings a tile could report Shahrivar while the list beneath it aged an
invoice into Mehr. One value keeps everything on screen internally consistent — and makes both
testable against a fixed date, which is what lets the Jalali-boundary tests assert anything at all.

**It does not tick, and that is deliberate.** Resolved once and kept, so a month boundary or a due
date crossing midnight while the app sits open does not update until the next launch. A clock that
rebuilt every screen showing a date would be a timer running for the life of the process to correct a
figure nobody is looking at. A later phase can invalidate the provider on resume — one call, in one
place, precisely because the reading is not scattered.

**Why whole days rather than instants.** `now.isAfter(dueDate)` marks an invoice due at
midnight-Tehran as overdue for the entire day it is actually due. That is a red badge on a document
nobody is late on, and the cost is not cosmetic: it teaches the user that red does not mean anything.
The end of the due date's Jalali day is the first instant at which the invoice genuinely is late, and
`jalaliDayOf(due).end` computes it in the same calendar and the same offset as everything else
(D-006, D-028). The off-by-one is subtle enough to be worth a test at the minute: a due instant of
`2026-08-24T00:00Z` is 03:30 on 2 Shahrivar in Tehran, so its day ends at `2026-08-24T20:30Z` — the
same UTC date, which is exactly what an instant comparison gets wrong.

**Overdue is still never stored** (as `status_badge.dart` already said): a stored `overdue` would be
wrong the moment the clock passed midnight and nothing wrote to the row. And it applies only to
`unpaid` and `partiallyPaid` — a paid or cancelled invoice past its due date is paid or cancelled,
because nobody is late on it.

---

## D-042 — Phases 2 and 3 are re-scoped to what Phase 1 did not already deliver

**Date:** 2026-08-24 · **Status:** ACCEPTED · **Owner's ruling**

**Decision.** `ROADMAP.md`'s entries for **Phase 2 — Customers** and **Phase 3 — Products and
Services** are rewritten to name only the work that genuinely remains. Each now opens with an
explicit "already delivered in Phase 1, and not to be rebuilt" list. Phase 5 and Phase 8 get the same
treatment in one paragraph each, for the same reason.

**Reason.** Increment (f1) built the customer and product screens end to end — list,
normalization-insensitive search, create and edit forms, soft delete with its Persian explanation,
mobile validation, national-ID checksum — because the owner pulled the create/edit forms forward
into Phase 1 (D-036). Phase 2 and Phase 3 were written before that happened and still described all
of it as future work.

A roadmap entry that describes finished work is not merely stale. The project spec tells a fresh
session to read the roadmap and continue from it, and §15 forbids recreating existing architecture —
so an entry saying "build the customer list with search" is an instruction to rebuild a screen that
exists, issued to the one reader least able to tell. The cost is not a wasted afternoon; it is a
second implementation of a screen, diverging from the first, with the guard tests passing on both.

**What actually remains, and why each item is real rather than invented.**

- **The customer detail screen** (`/customers/:id`). The only substantial piece missing. The strongest
  evidence it is real: `InvoiceRepository.watchForCustomer` was built in (d) and **has no call site**
  — it was designed for exactly this screen and nothing else has needed it since.
- **Field-level limits at the form boundary** (§7). Not a formality. The schema carries `withLength`
  on every text column and the forms carry nothing, so an over-long name is accepted by the form,
  rejected by drift, and reported to the user as the generic "خطایی رخ داد" — the failure is real,
  the message is useless, and the user is not told which field. The limits must come from one place
  shared with the table definition, because a schema limit and a form limit that disagree silently is
  the failure worth designing out rather than fixing twice.

**What was removed from Phase 3, and where it went.** Phase 3's original entry is otherwise complete,
including the one requirement in its security note — the `kMaxAmountRial` ceiling is already enforced
on the price field. §11 lists a product-detail route, but the edit form already shows every field a
product has; the only question a detail screen could answer that the form cannot is "where has this
been sold, and at what price", which is a **report**. It moves to Phase 8 with the other reports, and
`/products/:id` gets registered there, with the screen, per D-021. Building a detail page here to
satisfy a route list would produce a page that duplicates the form — fake functionality in the
precise sense §15 prohibits, because it would look finished.

**Alternatives considered.** Leave the entries and rely on `CURRENT_STATE.md` to warn the next
session — rejected: `CURRENT_STATE` is about the current increment and turns over every session,
while the roadmap is the durable record; the warning would be gone in two sessions and the wrong
entry would still be there. Merge Phase 3 into Phase 2, since one item remains — rejected: the phase
numbering is referenced from the project spec and from a dozen cross-references, and renumbering to
save one heading trades a real cost for a cosmetic gain. A phase that is honestly small is better
recorded as small than dissolved.

---

## D-043 — Field limits are named once, and drift cannot be told about it

**Date:** 2026-08-25 · **Status:** ACCEPTED · implements the project spec's field-level limits.

**Decision.** Every free-text field's maximum length is named once, in
`lib/data/models/field_limits.dart`, and read from there by the forms. Every text field in `lib/`
goes through `AppTextField`, whose `maxLength` is a **required** parameter.
`test/core/widgets/field_limit_path_test.dart` fails the build on a raw `TextFormField`/`TextField`
or on a `maxLength` that is a bare number rather than a `*Limits.` reference.
`test/data/database/field_limits_test.dart` asks each generated column where it actually starts
rejecting values and fails if that disagrees with the constant.

**The gap this closes.** The schema has carried `withLength` on every text column since increment
(a); the forms carried nothing. So an over-long name was accepted by the form, sent to the
repository, and refused by drift with an `InvalidDataException` that `describeFailure` does not
recognise — surfacing as the generic «خطایی رخ داد». The user was told something went wrong, not
which field or why, and the value they had typed was still on screen looking perfectly reasonable
(D-042 named this; this entry is its implementation).

### The obvious way to share the constant does not work, and fails silently

The natural design is `withLength(max: CustomerLimits.fullName)`. **It compiles, generates, and
produces a column with no length constraint at all.** `drift_dev` reads that argument with
`readIntLiteral`, which accepts an `IntegerLiteral` and returns `null` for anything else
(`drift_dev-2.34.5/lib/src/analysis/resolver/dart/helper.dart:206`).

This was verified rather than inferred. Changing the one column and regenerating produced:

```
-    additionalChecks: GeneratedColumn.checkTextLength(
-      minTextLength: 1,
-      maxTextLength: 120,
-    ),
+    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
```

`build_runner` reported no error and no warning. Sharing the constant would therefore have left the
schema **weaker** than before the sharing was introduced — the exact shape of failure this project
keeps writing guards against.

**So the tables keep their integer literals, and a test closes the loop instead.** It is the
stronger of the two checks: asking `isAcceptableValue` where the column starts refusing proves the
constraint exists *and* where it bites, rather than proving two source files contain the same token.
Confirmed to bite — with the constant reference in place it failed naming `full_name` and the exact
cause.

### Why a required parameter rather than a lint or a convention

A wrapper whose limit is optional is a wrapper someone omits on the field that needed it. Making
`maxLength` required moves half the rule to the compiler: a new field cannot exist without a limit.
The scan covers the other half — a field that bypasses the wrapper, and a limit written as a number.
Same treatment as the single database opener (D-020), the single normalizer (D-029) and the logging
wrapper (D-035), for the same reason: **the failure is silent**, and review is what missed it for all
of Phase 1.

**One exemption exists**: the search field (`core/widgets/search_field.dart`). A search term is never
stored, so there is no column whose limit it could disagree with; it reaches SQL as a bound parameter
through `searchKey` (D-018, D-029), and a length limit would only decide how much of their own query
the user can see. Marked `// field-limit-exempt:` with that reason, which is the escape hatch working
as intended.

### Three details that are easy to get subtly wrong

**The validator measures what drift measures.** `maxLength` stops the *user* at the limit counting
grapheme clusters; `GeneratedColumn.checkTextLength` counts `String.length`, UTF-16 code units. For
Persian carrying combining marks those differ, so a name of 120 clusters can be 130 code units and
still be refused by the column. `AppTextField`'s validator uses `String.length`, closing the gap in
the column's own unit, and says which field and what the limit is.

**Digits are filtered, not folded.** `digitsOnly` keeps digits in whichever of the three sets the
user typed rather than normalizing under the cursor — a caret that jumps because the text beneath it
changed length is a worse failure than the one being prevented. Folding still happens at parse time,
in `normalizePersianDigits`. The filter itself is `keepDigitsOnly` in `core/formatting/`, because
that is the only directory permitted to know what a digit is (D-029).

**The counter appears only near the limit**, and never on a field shorter than 40 characters. A
permanent «۰/۲۰۰۰» under every field is decoration, which §10 removes; a field that silently stops
accepting keystrokes is worse. A ten-digit کد ملی stops at ten because that is what a کد ملی is, and
counting toward it would be counting something the user is not worried about.

**Alternatives considered.** Referencing the constant from `withLength` (rejected: it silently drops
the constraint — see above). Duplicating the numbers and adding a test that compares the two source
files (rejected: it proves the tokens match, not that the constraint is applied). A lint rule
(rejected: `custom_lint` is the package D-015 excludes for dragging the analyzer, and with it drift
and sqlite3, backwards). Truncating silently with no validator (rejected: the grapheme/code-unit gap
would still reach the database).

---

## D-044 — The customer detail screen composes one view, and shows the record differently per tier

**Date:** 2026-08-25 · **Status:** ACCEPTED

**Decision.** `/customers/:id` renders a single `CustomerDetailView` — the customer, one
`CustomerTotals`, and that customer's invoices — assembled in `customerDetailProvider` and rendered
as one loading state, one error state, one moment.

**Why one value.** The same reason `DashboardSummary` is one value: the totals and the invoice list
sit on the same page and the user reads them together to reconcile. Settled independently they would
occasionally show a balance from before a payment beside the list from after it — a pair that never
existed, which is worse than either figure being late.

**The totals are one SQL statement, using `FILTER`.** Billed and outstanding cover *different*
populations — issued invoices (D-039) and outstanding ones — so they are two aggregates with two
predicates:

```sql
SELECT SUM(grand_total_rial) FILTER (WHERE status IN (issued)),
       SUM(grand_total_rial - COALESCE((SELECT SUM(amount_rial) FROM payments
                                        WHERE deleted_at IS NULL
                                          AND invoice_id = invoices.id), 0))
         FILTER (WHERE status IN (unpaid, partiallyPaid))
FROM invoices WHERE deleted_at IS NULL AND customer_id = ?
```

`FILTER` needs SQLite 3.30; this application ships 3.53.4, and the clause was exercised on the real
Windows build rather than only in tests. The correlated subquery is the one `watchOutstandingRial`
already uses, for the reason recorded there: a join to `payments` multiplies an invoice's grand total
by its number of payment rows, which is invisible until the second instalment.

**Billed excludes drafts and cancellations, and the caption says so.** Without the caption the figure
does not match the rows beneath it — the demo customer's page shows a 55,000,000 draft in the list
and 21,230,000 billed — and a figure the user cannot reconcile is one they learn to distrust (D-039).

**`watchForCustomer` is reused rather than replaced.** It was built in increment (d) and had no call
site until now. The customer's name for each row is the one already loaded above, not a per-row
lookup: this is the one screen where the join `watchList` performs is genuinely unnecessary, because
there is exactly one name and it is in hand.

**`InvoiceCard`/`InvoiceTableRow` gain `showCustomer`, defaulting to true.** On a customer's own page
the name is identical on every row — repetition of something the reader already knows, pushing the
invoice number, which is what identifies the row, into second place. §10 removes what does not aid
comprehension. The widget is otherwise unchanged: same shape, same order, same emphasis, so an
invoice still looks like an invoice wherever it is seen; the heading slot takes the number instead.

**The record card is collapsible on mobile and open on desktop.** Its height has no upper bound the
layout can be designed around — notes run to two thousand characters — so above the invoice list it
can push that list arbitrarily far down the page, on the one screen whose purpose is to show it.
Below the list it would be just as unreachable, past however many invoices the customer has.
Collapsing keeps both answers in reach; desktop has room for a panel and keeps it open.

**Empty fields say «ثبت نشده» rather than being hidden.** A record that omits what is missing looks
complete, and the user cannot tell "no company recorded" from "companies are not shown here" — which
matters when the missing field is the one an invoice needs.

**D-030 binds here too.** This screen *displays* a stored national ID. A passing checksum was never
an identity, so there is no tick, no badge and no affirmative word anywhere near the value, and the
screen test asserts the absence of both the copy and the iconography.

**Invoice rows stay non-tappable**, asserted by a test, until `/invoices/:id` exists in Phase 5
(D-021, one level down).

**On linking an invoice to its customer** — the third item in D-042's Phase 2 scope, left as a design
call for when the screen existed. **Decided: no link.** An invoice row's primary target must be the
invoice, which arrives in Phase 5; making the row open the customer instead would put the wrong
destination on the obvious affordance and then have to be taken away. The customer list is one
navigation click away, and it searches.

---

## D-045 — A write outlives the widget that started it

**Date:** 2026-08-25 · **Status:** ACCEPTED · **Corrects (f1)**

**Decision.** `CustomerEditor` and `ProductEditor` take a `ref.keepAlive()` link for the duration of
`save` and `delete`, and close it in a `finally`.

**What it corrects.** Soft-deleting a customer or a product from a list row threw
`UnmountedRefException`. Nothing on a list screen watches the editor provider — the row reads the
notifier and awaits it — so the auto-disposed controller was collected during the await, and the
`state = ...` write after it threw. **The delete had already happened**: the row left the list on the
next stream emission, but the user was shown no confirmation for something that did occur, and an
unhandled exception reached the zone.

**Why it survived (f1).** The one call site that was exercised was the form, which watches the
controller for its in-flight flag and therefore keeps it alive. The list's delete path shipped
untested; it was found by writing the equivalent test for the detail screen and then, once the cause
was understood, for the list where it originally shipped. Both are now covered.

**Why a scoped link rather than `keepAlive: true` on the provider.** the project spec prefers scoped,
auto-disposed providers. The link expresses exactly what is true — this controller must survive for
as long as its write is in flight, and no longer — rather than keeping a controller alive for the
life of the process to fix a window of a few milliseconds.

**Alternatives considered.** Having every acting widget `ref.watch` the editor (rejected: it is
per-call-site discipline, which is what failed here, and it rebuilds a list row on every state
change). Checking `ref.mounted` after the await and skipping the state write (rejected: it silences
the symptom and still loses the error state that a failed write needs to report). Making the provider
`keepAlive` (rejected above).

---

## D-046 — The invoice editor previews through the engine, and nothing else may calculate

**Date:** 2026-08-25 · **Status:** ACCEPTED · Phase 4 increment (a).

**Decision.** `InvoiceEditorState` (`features/invoices/domain/`) holds an invoice being edited and
exposes `totals`, the `CalculatedInvoice` the money engine produced for it. Every figure a screen
displays comes from there. `test/core/money/single_calculation_path_test.dart` fails the build if
anything in `lib/` outside `core/money/` calls `calculateInvoice` other than that state model and
`DriftInvoiceRepository`.

**Why two callers, and why exactly two.** They exist for different reasons and both are necessary:
the editor computes the **preview** on every edit, and the repository computes the totals again
**inside the write transaction**, because a caller must not be able to supply a total (D-004). The
hazard is that they could be fed slightly different inputs — a preview that passes the invoice
discount but forgets the rounding unit, say. Each answer would look entirely reasonable on its own,
and the user would agree to one number and receive another with nothing in either path looking wrong.

So the two are pinned against each other by
`test/features/invoices/invoice_preview_matches_write_test.dart`, which builds a state, writes its
draft through the **real encrypted database**, and asserts that every stored figure equals the one
the preview showed — the invoice totals, the warnings, and each line's effective discount, resolved
tax rate, net, tax and total. The scan exists because a *third* caller would not be covered by that
test. Verified to bite: a plausible `previewTotal()` helper added to the invoice list screen failed
it naming the file and line.

**The state computes nothing, and is recomputed rather than mutated.** It is immutable; every edit
produces a new state whose constructor runs the engine. Caching the totals would be an optimisation
over a pure integer pass across a handful of lines, with a staleness bug attached.

**Settings are watched, not captured.** `defaultTaxRateBp` and `roundingUnitRial` are the last step
of §4's chain and they live in settings, so the controller watches `appSettingsProvider` and carries
the entries across the rebuild. A preview that captured the rate at open time would keep describing
a rule that no longer applied, and the repository — which re-reads settings inside the transaction —
would then store something the user was never shown.

**`copyWith` needs explicit `clear` flags.** For `taxRateBp`, `discountPercentBp` and `productId`,
`null` is a *meaningful value*: inherit, absolute-not-percentage, freehand. The usual "null means
unchanged" convention would let a caller set those but never unset them, so "inherit" would be
unreachable the moment anything had been chosen — which is D-026's distinction quietly lost at the
UI boundary rather than in the engine.

**A percentage and an amount are alternatives, enforced in the controller.** The engine lets a
percentage win over an absolute amount (§4 step 2), so `setDiscountAmount` clears the percentage and
`setDiscountPercent` zeroes the amount. Left alone, a stale percentage would silently override the
figure the user had just typed.

**Alternatives considered.** Letting the screen hold a mutable list and call the engine itself
(rejected: it is the third caller this decision forbids, and §3 forbids calculation in widgets).
Having the state hold raw text and parse lazily (rejected: parsing belongs at the field boundary
through `core/formatting/`, and a model holding unparsed text makes every reader wonder whether a
value is trustworthy). Computing totals in the repository only and having the screen show nothing
until save (rejected: a user cannot agree to a figure they were never shown).

---

## D-047 — `CalculatedInvoice.grossTotal`, so the printed summary reconciles by hand

**Date:** 2026-08-25 · **Status:** ACCEPTED · extends increment (b)'s engine.

**Decision.** The engine gained `grossTotal` — `Σ lineGross`, before any discount and before tax —
and a second runtime invariant beside the §4 one:

```
grossTotal − totalDiscount + totalTax + roundingAdjustment == grandTotal
```

**The problem it solves.** §4's invariant is `grandTotal == subtotal − invoiceDiscount + totalTax`.
That proves the engine is *self-consistent*. It does not give a document a set of figures a customer
can check with a pencil, because `subtotal` is already net of the **line** discounts while
`totalDiscount` (D-027) is the sum of the line discounts *and* the invoice discount. A summary
printing subtotal, total discount, tax and total therefore does not add up — the line discounts are
subtracted twice by anyone reconciling it. On a worked example: gross 2,500,000, line discounts
350,000, invoice discount 100,000, tax 184,500 — the subtotal-based arithmetic lands 350,000 short of
the printed total.

Starting from the gross adds up exactly, which is what the new invariant states.

**Why the engine rather than the screen.** The alternative was to sum the line grosses in the summary
widget. That is a second implementation of part of §4 living in a widget, which §3 forbids and which
D-046's scan exists to prevent one level up. The instruction that produced this entry is worth
recording as the general rule: *if a figure is needed that the engine does not produce, extend the
engine.*

**Checked at runtime, not only in tests**, exactly like the §4 invariant and for the same reason: the
alternative to crashing on a summary that does not reconcile is printing one. The engine's own suite
asserts it on every case including the 450-combination sweep, and one test states the trap
explicitly by showing the subtotal-based arithmetic being short.

**Not stored.** `invoices` has no `gross_total_rial` column and does not need one yet — nothing reads
a stored invoice's summary until the invoice detail screen (Phase 5) and the PDF (Phase 7). Both will
need it, and per-line gross is **not** recoverable from what is stored today: `invoice_items` keeps
`unit_price_rial`, `quantity_milli`, the effective `discount_rial` and `line_net_rial`, where
`line_net_rial` is the net *after* the allocated invoice discount. Recomputing gross from price ×
quantity would re-run §4 step 1 outside the engine, which is the thing D-046 forbids. **Phase 5 must
decide** whether to store the gross or to widen what the engine returns for a stored invoice; it is
recorded here rather than solved now because the right answer depends on what the detail screen and
the renderer actually need.

---

## D-048 — Invoice numbers are allocated on issue, not on draft creation

**Date:** 2026-08-25 · **Approved by the owner and implemented:** 2026-08-26 · **Status:** ACCEPTED

The owner approved this on 2026-08-26 and directed that it land as **its own reviewable step before
Phase 4 increment (b)**, rather than inside (c): it is the project's first migration and a build is
already installed on a real device. See the implementation note at the end of this entry.

**The defect, measured.** `DriftInvoiceRepository.create` calls `_allocateNumber` unconditionally,
including for a draft. Verified against the real database rather than inferred:

```
draft #1 number = INV-1405-0001
draft #1 abandoned (softDeleteDraft)
draft #2 number = INV-1405-0002
```

`INV-1405-0001` is gone permanently. The unique index deliberately covers soft-deleted rows, because
a spent number stays spent (D-013) — which is right for an *issued* invoice and wrong for a draft
nobody ever saw. A user who opens a form, changes their mind and closes it has silently consumed an
invoice number, and a business whose numbering has gaps has a conversation to have with an auditor.

**Decision.** A draft carries **no** number. Allocation happens in `issue()`, inside its transaction,
against the Jalali year of the issue date (D-013 unchanged in every other respect).

**What it costs, stated plainly: the first schema migration.** `invoices.number`, `number_year` and
`number_sequence` are all non-null today. They must become nullable, because:

* an empty-string sentinel does not work — SQLite's unique index treats `''` as equal to `''`, so a
  second numberless draft would collide, while **NULLs are distinct in a unique index**, which is
  exactly the behaviour needed;
* the alternative, a separate drafts table, would duplicate every column and every query.

That makes this `schemaVersion = 2`, the first migration in the project, and per §6 and §14 a
migration without a test is not done. Known issue 1 has been waiting for this since increment (a),
and a build is already installed on a real device, so the migration has to run rather than being
skipped by a reinstall.

**Why it is proposed rather than done.** The owner's split puts numbering in increment (c), and this
is a schema change touching a table every other feature reads — it deserves its own reviewable step
rather than being folded into the state model. Recorded now so (c) starts from a measured defect and
a decided shape.

**Consequences to carry into (c).**

* `InvoiceListItem`, the invoice list and the customer detail screen all render `invoice.number`. A
  draft's number becomes null and every one of those needs Persian copy for it — not an empty cell.
* `watchList` orders by `issueDate` then `numberSequence`; a null sequence needs a defined position.
* The status badge already distinguishes پیش‌نویس, so "this document has no number yet" is
  consistent with what the user is already told.

### Implementation note (2026-08-26) — what the migration actually cost

Delivered as its own step at the owner's direction. `schemaVersion = 2`; the three columns are
nullable; `create` allocates nothing for a draft and `issue` allocates inside its own transaction.

**The migration is a 12-step table rebuild, and its real hazard is the cascade.** SQLite cannot
relax `NOT NULL` in place, so `Migrator.alterTable` creates a new table, copies, drops the old one
and renames. **Step 6 is `DROP TABLE invoices`** — and with foreign keys enabled that runs an
implicit delete which cascades into `invoice_items` and `payments`. Drift guards against it by
issuing `PRAGMA foreign_keys = OFF` *before* opening its own transaction and restoring it after,
which works only because drift invokes `onUpgrade` outside a transaction.

**That guard was verified to bite rather than assumed.** Wrapping the `alterTable` call in
`db.transaction` — which reads as a *safety* improvement, and is the obvious "tidy-up" a later
session would make — leaves `invoice_items` at **zero rows**, because SQLite silently ignores
`PRAGMA foreign_keys` inside a transaction. Every line and every payment in the database, gone. The
schema-comparison test still passed, and so did the test asserting the numbers were preserved: the
*invoices* survive, only their children are destroyed. One test out of six noticed.

This is why the data test does not use `SchemaVerifier.testWithDataIntegrity`, which documents that
it disables foreign keys — precisely the condition under which the bug does not reproduce — and why
it runs through `openAppDatabase` against a real encrypted file rather than the verifier's
in-memory one. A `// Deliberately NOT wrapped in a transaction` comment now sits on the call.

The migration also runs `PRAGMA foreign_key_check` afterwards, which is step 9 of SQLite's procedure
and which drift's `alterTable` states in its source that it skips.

**Numbers already spent are not reclaimed.** A draft migrated from v1 keeps the number v1 gave it,
and `issue` allocates only when the column is null. The gap is in the past; rewriting a document's
identity is worse than a gap (D-013).

**Ordering needed a decision the old schema never posed.** `watchList` ordered by `issueDate DESC,
numberSequence DESC`, and a null sequence has no defined position. It is now
`issueDate DESC, numberSequence DESC NULLS FIRST, createdAt DESC, id DESC`: a draft sorts above the
invoices of its own date (nothing was issued after it, because it has not been issued), and the last
two keys make the order **total** — `created_at` is milliseconds and two drafts can be written
inside one, so the unique id is what guarantees the same answer on every read rather than a list
that reshuffles.

**One string, three call sites.** «بدون شماره» — deliberately not a repeat of «پیش‌نویس», which the
status badge already says beside it in all three layouts, and deliberately not blank, because an
empty cell reads as data that failed to load. The wording and the bidi rule live together in
`invoiceNumberLabel` (`features/invoices/domain/`): a real number is isolated because it mixes a
Latin prefix with digits (§9), and the Persian placeholder is not, because there is nothing to
protect and the isolate marks would only be invisible characters in a string tests and screen
readers have to handle.

---

## D-049 — The table rebuild refuses to run where the foreign-key pragma is ignored

**Date:** 2026-08-26
**Status:** ACCEPTED
**Supersedes:** nothing. Extends D-048.

**Decision.** `_migrateV1ToV2` calls `assertForeignKeysCanBeDisabled(db)` before
`Migrator.alterTable`, and the migration aborts with a `StateError` naming the consequence if the
check fails. The call site carries a comment that begins `DO NOT WRAP THIS FUNCTION, OR THE CALL
BELOW, IN A TRANSACTION`, and four tests in `invoice_number_migration_test.dart` pin the guard, its
premise, and the data loss it prevents.

**Reason.** D-048 identified the defect but defended it only with a comment and one test out of six.
That is not enough for this shape of bug. Wrapping the `alterTable` call in `db.transaction` reads
as a safety improvement, is the change a careful reviewer would suggest, and silently deletes every
`invoice_items` row and every `payments` row in the user's database — every line of every invoice
and the whole payment history — while producing exactly the correct schema and leaving five of six
tests green, because only the child rows die. A defect that survives review, survives the type
system and survives most of its own test suite is one that ships.

**How the guard works, and why it is not a heuristic.** It does not try to answer "am I inside a
transaction". It performs the one operation `alterTable` depends on and reads the result back: issue
`PRAGMA foreign_keys = OFF`, then ask what the pragma says. Outside a transaction it reads `0`;
inside one SQLite ignores the write, reports no error, and it still reads `1`. That difference is
the whole bug, observed directly rather than inferred, so the guard catches every route to the
condition — an explicit `db.transaction`, a batch, or a future drift release that begins running
`onUpgrade` inside a transaction — and not merely the one spelling a source scan could match. It
costs two pragmas, it runs before anything destructive, and it restores the connection's prior
state whether or not it passes.

**Verified to bite, by doing it.** Wrapping the real migration in `db.transaction` now fails the
data-survival test at the guard, with the message naming the cascade, instead of passing five of six
tests with an emptied `invoice_items`. The wrapper was then removed.

**Alternatives considered.**

- *A `lib/`-scanning source guard*, in the style of the project's other nine. Rejected: it would
  have to recognise "this call is lexically inside a transaction block" from Dart source with a
  regex, which is fragile in both directions — it cannot see a transaction opened by a caller two
  frames up, and it would misfire on an unrelated nearby `transaction(`. The runtime check is
  strictly stronger and has no false positives.
- *`sqlite3_get_autocommit()`*, the C API's direct answer. Rejected: not reachable through drift's
  `QueryExecutor`, and it would answer a narrower question than the one that matters.
- *Leaving the comment and the test as the only defence*, as D-048 did. Rejected for the reason
  above: the comment is advisory and the test that catches it is outnumbered five to one.

**Where it applies next.** Any future migration that rebuilds a table with children must call it.
The function is named for what it checks rather than for this migration, and it is public so a test
can call it from inside a transaction and watch it refuse.
