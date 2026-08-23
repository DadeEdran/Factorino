# Current State

> The continuity file. A fresh session reads this first and continues from the Next Action.
> Last updated: **2026-08-23**

---

## Phase

**Phase 0 — Environment and Setup · `IN_PROGRESS`**

All decisions settled. The AndroidX resolution probe **passed**. The D-020 encryption proof is
**blocked on two items that need the owner**, both requiring administrator rights or hardware:

1. **Windows: Developer Mode is off.** `flutter build windows` fails with *"Building with plugins
   requires symlink support"*. Enabling it needs an administrator
   (`start ms-settings:developers`, or the `AppModelUnlock` registry key). No plugin-using Windows
   build is possible until then.
2. **Android: no device and no emulator.** `flutter devices` lists only Windows, Chrome and Edge;
   `flutter emulators` reports none. A physical device over USB, or an emulator system image
   (fetchable from the Tencent SDK mirror), is required.

## Verification status

```
flutter analyze:            PASS   (No issues found)
flutter test:               PASS   (1/1 template smoke test)
Android build (plugins):    PASS   flutter build apk --debug with flutter_secure_storage
Web build:                  NOT_RETESTED since the plugin was added
Windows build (plugins):    BLOCKED  Developer Mode off - symlink support
AndroidX plugin resolution: PASS   <- the D-014 probe; this was the open risk
sqlite3mc encryption:       PASS on the Dart VM (Windows) - NOT the D-020 proof
D-020 end-to-end proof:     BLOCKED  needs Windows Developer Mode + an Android target
```

## What was completed this session (2026-08-23)

**Git history — three commits, working tree clean.**

```
b480aa1  Add flutter_secure_storage and pin compileSdk 37; Android plugin build verified
0f163c8  Normalize line endings to LF and add .gitattributes
bebb414  Initial commit: Flutter scaffold, project docs, and repository guardrails
```

**Mirrors configured, user-global, nothing in the repository** (D-014 amendment):
`PUB_HOSTED_URL` and `FLUTTER_STORAGE_BASE_URL` via `setx`; Google Maven via
`~/.gradle/init.d/cn-google-maven-mirror.gradle`. Only blocked hosts are mirrored — Maven Central
and the Gradle plugin portal both return 200 and are untouched.

**`tools/sanitize_lockfile`** written, committed, and proven: 24 URLs rewritten, all 24 `sha256`
lines byte-identical, idempotent. **Finding: every `flutter pub get` re-contaminates the lockfile**,
so this is a mandatory post-step, not a one-time cleanup.

**Application ID** set to `io.github.erysaw.factorino` across the Gradle namespace/applicationId,
the Kotlin package path, and the Windows `Runner.rc` identifiers.

**AndroidX resolution probe PASSED** — the open risk from D-014 is closed. Three environment
problems were found and fixed outside the repository along the way:

- Google Maven unreachable → mirrored via the init script.
- `jni` (pulled in by **`path_provider_android`**, not by `flutter_secure_storage`) compiles against
  `android-35`, which was absent and undownloadable because `dl.google.com` is fully blocked.
  Installed from the Tencent SDK mirror, SHA-1 verified against the SDK manifest.
- The same plugin needs CMake 3.22.1, absent entirely. Installed the same way, SHA-1 verified.

The built APK contains `libdartjni.so`, so the CMake/NDK native path is exercised, not just JVM
dependency resolution.

**`compileSdk` pinned to 37** (above `flutter.compileSdkVersion` 36) because
`flutter_secure_storage` requires it, with `android.suppressUnsupportedCompileSdk=37` for AGP 9.1.0.
`targetSdk` and `minSdk` untouched.

**`.gitattributes` added** after discovering that script edits were flipping CRLF to LF and turning
a five-line change into a 183-line diff. Normalization was committed separately from content.

**Encryption de-risked on the Dart VM** (`sqlite3` 3.5.2 + `sqlite3mc`, Windows): encrypted header,
sentinel absent from the raw file, unkeyed reopen rejected, keyed reopen returns the row.
**The D-020 ordering hazard is now empirically confirmed** — a statement before `PRAGMA key`
produces a file whose header reads `SQLite format 3` (plaintext) *and* an exception that says
"file is not a database", pointing the developer at corruption rather than at the real cause.
**`PRAGMA cipher_version` returns empty under `sqlite3mc`** and must not be used as the runtime
assertion that encryption is on; assert on the file header instead.

## Known issues

| # | Issue | Impact |
|---|---|---|
| 1 | **Windows Developer Mode off** | **Blocking the D-020 proof and all Windows plugin builds.** Needs an administrator. |
| 2 | **No Android device or emulator** | **Blocking the Android half of the D-020 proof.** Needs a USB device or an emulator system image. |
| 3 | `pub.dev` 403; `dl.google.com` fully blocked | Worked around by mirrors (D-014 amendment). SDK packages must be installed by hand from the Tencent mirror with SHA-1 verification. |
| 4 | Every `flutter pub get` re-contaminates `pubspec.lock` | Run `sh tools/sanitize_lockfile` after **every** resolve. The pre-commit hook is the backstop. |
| 5 | `flutter doctor` "Android license status unknown" | **Not a real failure — a stale check.** `--licenses` is removed from the new Android CLI; the canonical licence hash file is present and `flutter build apk` succeeds. No licence files were fabricated to silence it. Details in `ENVIRONMENT.md`. |
| 6 | Release builds signed with debug keys | Template `TODO` in `android/app/build.gradle.kts`. Phase 15. |
| 7 | Web build not retested since plugins were added | Low. `flutter_secure_storage` has a web implementation; re-verify during Phase 1. |

## Important context for a future session

- **`sh tools/sanitize_lockfile` after every `flutter pub get`.** Not optional, not one-time — pub
  rewrites the mirror host back into the lockfile on every resolve.
- **Do not fabricate Android licence-hash files** to make `flutter doctor` green (issue #5).
- **Do not assert encryption with `PRAGMA cipher_version`** — it returns *empty* under `sqlite3mc`
  even on a correctly encrypted database. Assert on the file header instead.
- **`PRAGMA key` must be the first statement on the connection.** This is now empirically confirmed,
  not theoretical: a statement before it yields a plaintext file *and* a misleading
  "file is not a database" exception. See D-020.
- The `sqlite3mc` choice is an owner override of this project's earlier `sqlcipher` recommendation,
  and it is the better call — SQLCipher has no Web support, and Web is a target platform. Do not
  "correct" it back.
- Mirror configuration is **user-global only** and must never enter the repository. The tree must
  build unmodified where pub.dev is reachable.
- SDK packages installed by hand (not via `sdkmanager`, which cannot reach Google):
  `platforms/android-35` and `cmake/3.22.1`, both SHA-1 verified against the SDK manifest served by
  `https://mirrors.cloud.tencent.com/AndroidSDK/repository2-1.xml`.

## Recently changed files

Committed in `b480aa1`, `0f163c8`, `bebb414`. Working tree clean. Uncommitted doc updates from this
report are the only pending change.

Outside the repository (deliberately not committed):

| Path | Purpose |
|---|---|
| `~/.gradle/init.d/cn-google-maven-mirror.gradle` | Rewrites Google Maven to the Aliyun mirror |
| user env `PUB_HOSTED_URL`, `FLUTTER_STORAGE_BASE_URL` | Package and engine-artifact mirrors |
| `%LOCALAPPDATA%/Android/Sdk/platforms/android-35` | Required by the `jni` plugin |
| `%LOCALAPPDATA%/Android/Sdk/cmake/3.22.1` | Required by the `jni` plugin native build |

No application code has been written. `lib/` and `test/` are untouched template files.

## Last completed action

Configured mirrors, regenerated and sanitized the lockfile, set the application ID, made the first
three commits, and **passed the AndroidX resolution probe** — `flutter build apk --debug` succeeds
with `flutter_secure_storage`. Confirmed `sqlite3mc` encryption works on the Dart VM and that the
D-020 ordering hazard is real. Found the D-020 end-to-end proof blocked on Windows Developer Mode
and on the absence of any Android target.

## Next action

**Unblock the two D-020 prerequisites, then run the proof.**

1. Enable Windows Developer Mode (administrator): `start ms-settings:developers`, or set
   `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock\AllowDevelopmentWithoutDevLicense = 1`.
   Verify with `flutter build windows --debug`.
2. Provide an Android target — a device over USB with debugging enabled, or an emulator system
   image from the Tencent SDK mirror plus an AVD.

Then build the throwaway Flutter app that opens an encrypted database through Drift, writes a row,
closes, reopens **without** the key, and confirms rejection — on **both** Windows and Android — and
report before starting Phase 1 implementation.
