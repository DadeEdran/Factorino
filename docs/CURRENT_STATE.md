# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-23**

---

## Phase

**Phase 0 — Environment and Setup · `IN_PROGRESS`**

All four owner decisions are now settled (D-010, D-014, D-015/D-016, D-019). Phase 0 is **not**
complete because two required verifications cannot run: **`pub.dev` is still returning HTTP 403 from
this machine**, and every remaining Phase 0 item depends on package resolution.

## The one thing blocking everything

`pub.dev` returned **403** when re-measured on 2026-08-23, from egress IP `195.74.93.35`. The VPN
chosen in D-014 is either not running, not routing this traffic, or exiting somewhere Google also
blocks.

Check before doing anything else:

```sh
curl -s -o /dev/null -w '%{http_code}\n' https://pub.dev/api/packages/drift   # want 200, currently 403
```

While that returns 403: no `flutter pub get`, no lockfile regeneration, no dependency probe, no
encryption proof, no Phase 1. `flutter doctor`'s `[✓] Network resources` line is **not** a valid
substitute for this check — it passed while pub.dev was blocked.

## Verification status

```
flutter analyze: PASS   (No issues found)          — as of 2026-08-22, template code only
flutter test:    PASS   (1/1 template smoke test)  — as of 2026-08-22, template code only
Android build:   PASS   (flutter build apk --debug) — template app, zero plugins, warm Gradle cache
Web build:       PASS   (flutter build web)
Windows build:   PASS   (flutter build windows --debug)

AndroidX plugin resolution:  NOT_TESTED  — blocked on pub.dev
Encryption end-to-end proof: NOT_TESTED  — blocked on pub.dev
```

The PASS lines above were produced through a mirror and describe the **template** app. They are not
evidence that Phase 1 dependencies resolve.

## What was completed this session (2026-08-23)

**Owner decisions recorded.** D-010, D-014, D-015, D-016 and D-019 moved from `PROPOSED` to
`ACCEPTED` in `DECISIONS.md`, each with the owner's reasoning. Three new entries added:

- **D-020** — `PRAGMA key` must be the first statement on every connection, with the two silent
  failure modes spelled out and the end-to-end verification requirement attached.
- **D-021** — گزارش‌ها omitted from Phase 1 navigation entirely; its route is not registered either.
- **D-022** — Vazirmatn standard variant, static TTFs, weights 400/500/700, and why not the
  Farsi-digit variant.

**The project spec reworded** (§2, §7, §16, §17, §19) from "SQLCipher / `sqlcipher_flutter_libs`" to
"encrypted SQLite (SQLite3 Multiple Ciphers via `package:sqlite3` build hooks)", per the owner's
D-010 override. §7 also gained the `PRAGMA key` ordering rule.

**Build-hook flag question answered.** `flutter config --list` reports `enable-native-assets:
(Not set)` and `flutter config` documents it as `(defaults to on)`. **No experimental flag is
required** on Flutter 3.47.1 stable.

**Flutter/Dart version question answered.** Raw output pasted in `docs/ENVIRONMENT.md`. Flutter
3.47.1 / Dart 3.13.1 is consistent with the established cadence of ~3 Flutter minors per Dart minor
(3.35→3.9, 3.38→3.10, 3.41→3.11, 3.44→3.12, 3.47→3.13). Not a mismatch.

**Git initialized.** Branch `main`, `core.autocrlf=false`, `core.hooksPath=.githooks`.
`.gitignore` hardened first (keystores, `*.jks`, `key.properties`, `.env*`, exported backups, local
`.db`/`.sqlite` files, build outputs). **Nothing committed yet** — see Next Action.

**Pre-commit hook written and proven to fire.** `.githooks/pre-commit` (versioned, so it survives a
clone) fails the commit on: a `pubspec.lock` host other than `pub.dev`; staged signing material,
secrets or local databases; and the template application ID. Run against the current tree it
correctly blocked on two of the three.

**Vazirmatn obtained.** Release `v33.003` from GitHub (reachable), standard variant static TTFs at
400/500/700 plus `OFL.txt`, in `assets/fonts/`. sha256 of every file recorded in
`docs/ENVIRONMENT.md`. Not yet declared in `pubspec.yaml` — that is Phase 1 task 8.

**`docs/ENVIRONMENT.md` created.** Toolchain, the network situation, the VPN verification procedure,
the Android-licence false positive, and font provenance.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | **pub.dev returns 403** — VPN not yet effective | **Blocking everything.** |
| 2 | Google Maven unreachable (404) | **High.** Phase 1 plugins need new AndroidX artifacts; only a warm Gradle cache is masking it. This is what the `flutter_secure_storage` probe exists to test. |
| 3 | `pubspec.lock` records the Tsinghua mirror | Must be **deleted and regenerated** against pub.dev, not edited. Pre-commit hook enforces this. |
| 4 | `flutter doctor` "Android license status unknown" | **Not a real failure — a stale check.** `--licenses` is removed from the new Android CLI; the canonical licence hash file is present and `flutter build apk` succeeds. No licence files were fabricated to silence it. Details in `ENVIRONMENT.md`. |
| 5 | Application ID still `com.example.factorino` | **Blocks the first commit.** Awaiting the owner's reverse-domain ID. |
| 6 | Release builds signed with debug keys | Template `TODO` in `android/app/build.gradle.kts`. Phase 15. |

## Important context for a future session

- **Do not hand-edit `pubspec.lock`.** D-014 requires deleting it and regenerating from pub.dev.
  Nothing real depends on it yet.
- **Do not fabricate Android licence-hash files** to make `flutter doctor` green. Issue #4 is a
  tooling false positive, documented as such.
- The `sqlite3mc` choice is an owner override of this project's earlier `sqlcipher` recommendation,
  and it is the better call — SQLCipher has no Web support, and Web is a target platform. Do not
  "correct" it back.
- Resolved Phase 1 versions (measured 2026-08-22 via mirror, to be re-confirmed against pub.dev):
  drift 2.34.3 · drift_dev 2.34.5 · sqlite3 3.5.2 · flutter_riverpod 3.4.2 · riverpod_annotation
  4.0.6 · riverpod_generator 4.0.8 · go_router 17.5.0 · flutter_secure_storage 11.0.0 ·
  shamsi_date 1.1.1 · path_provider 2.1.6 · intl 0.20.3 · uuid 4.6.0 · crypto 3.0.7 ·
  build_runner 2.16.0 · analyzer 13.3.0.
- Enable the hook after any fresh clone: `git config core.hooksPath .githooks`.

## Recently changed files

| File | Change |
|---|---|
| The project spec | §2/§7/§16/§17/§19 reworded for `sqlite3mc`; §7 gained the PRAGMA ordering rule |
| `docs/DECISIONS.md` | D-010/014/015/016/019 → ACCEPTED; D-020, D-021, D-022 appended |
| `docs/ENVIRONMENT.md` | **Created** |
| `docs/ARCHITECTURE.md` | §A refreshed; B.5 PRAGMA order; B.7 reports omission; B.11 cipher row |
| `docs/CURRENT_STATE.md` | Rewritten (this file) |
| `docs/ROADMAP.md` | Phase 0 remaining-items list updated |
| `.gitignore` | Security hardening block appended |
| `.githooks/pre-commit` | **Created** |
| `assets/fonts/` | **Created** — Vazirmatn 400/500/700 + OFL.txt |
| `.git/` | **Created** — `git init`, branch `main`, no commits yet |

No application code has been written. `lib/` and `test/` are untouched template files.

## Last completed action

Recorded all owner decisions, reworded the project spec for `sqlite3mc`, initialized git with a hardened
`.gitignore` and a working pre-commit gate, obtained the Vazirmatn fonts, and answered the
build-hook-flag and SDK-version questions. Attempted the two required proofs and found both blocked
by pub.dev still returning 403.

## Next action

**Bring the VPN up and confirm `curl -s -o /dev/null -w '%{http_code}' https://pub.dev/api/packages/drift`
returns `200`.** Then, in this order:

1. `rm pubspec.lock && flutter pub get` (with `PUB_HOSTED_URL` unset) — regenerate against pub.dev,
   then verify no non-pub.dev `url:` remains.
2. Replace `com.example.factorino` with the owner's reverse-domain ID (still needed), then make the
   first commit — scaffold + `docs/`, before any Phase 1 code.
3. Add `flutter_secure_storage` and run `flutter build apk --debug` — the AndroidX resolution probe
   that either confirms Android is viable or surfaces known issue #2.
4. Build the throwaway encryption proof: a real Flutter app opening an encrypted DB through Drift on
   **Android and Windows**, writing a row, closing, reopening without the key, and confirming
   rejection (D-020).

Report on 3 and 4 before starting Phase 1 implementation.
