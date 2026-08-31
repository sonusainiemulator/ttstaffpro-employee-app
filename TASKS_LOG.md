# Tasks Log — Local Task History

Running log of completed tasks. **Newest entries go at the top.**

- Purpose: remember "last tasks history" locally per session, so context survives between conversations.
- Scope: covers both the root employee app (`open_core_hr`) and the sub-apps under `apps/` (face attendance kiosk, attend).
- Deep technical detail / gotchas for the kiosk live in the repo memory notes (`face-attendance.md`); link or summarize here.
- Versioned release notes belong in `CHANGELOG.md`; this file is the daily work log.

---

## 2026-08-31

- **MVP launch pain/gap analysis** → `docs/MVP_LAUNCH_ANALYSIS.md` (P0/P1/P2, launch-readiness sprints, product decisions). Root `1.2.3`, kiosk `1.0.16`.
- **Secure token storage**: new `lib/utils/token_storage.dart` (flutter_secure_storage, Keystore/Keychain) replaces plaintext `tokenPref` in SharedPreferences. Wired into LoginStore (4 write sites), `AuthInterceptor`, `network_utils.buildHeader`, `SharedHelper.logout/logoutAlt`, kiosk `activateMasterSession` + kiosk `main.dart` restore. Sync in-memory cache keeps header builders sync; legacy prefs migrate + get cleared; fallback keeps login safe. `test/token_storage_test.dart` (6 tests).
- **Kiosk heartbeat bug fixed**: `sendHeartbeat()` was never scheduled → now a 60s `Timer` on `kiosk_home_screen.dart` reports device health (admin Devices tab now shows live devices).
- **Gradle 8.13/8.12 → 8.14.1** wrapper bump (root + kiosk) — removes the "will be dropped" Flutter warning.
- Validated: root analyze 0 errors, root tests 37/37, kiosk analyze clean, kiosk tests 21/21, build_runner OK. Committed + pushed.

## 2026-08-30

- Built kiosk **debug APK**: `apps/ttstaffpro_face_attendance/build/app/outputs/flutter-apk/app-debug.apk` (~280 MB).
- Built kiosk **release APK**: `apps/ttstaffpro_face_attendance/build/app/outputs/flutter-apk/app-release.apk` (135.5 MB).
  - Note: each Flutter project builds to its OWN `build/` folder — kiosk output is under `apps/ttstaffpro_face_attendance/build/`, NOT the root repo `build/`.
  - Warning (non-blocking): Gradle 8.13.0 soon dropped by Flutter; upgrade to ≥ 8.14.0 (in `android/gradle/wrapper/gradle-wrapper.properties`).
- Set up this local task-history file (`TASKS_LOG.md`).

## 2026-08-29 (recap — see repo memory `face-attendance.md` for detail)

- Kiosk release build fixed: added `INTERNET` + `ACCESS_NETWORK_STATE` to kiosk `AndroidManifest.xml` (release APK lacked them → all API calls failed).
- Restyled kiosk UI to match employee app (`AppDesignSystem`, primary #696CFF, Poppins, white cards).
- Fixed kiosk white-screen startup hang: `await initialize()` (nb_utils) must run BEFORE any `setValue`/`getStringAsync`.
- Face registration/recognition fix: profile-package model now parses snake_case + camelCase; `employee_name`/`image_url` added server-side.
- Boot-disk exhaustion fixed: `~/.gradle` symlinked → `/Volumes/1TBNVME/gradle-home`.
- Implemented Dark + Light (user-selectable) mode for kiosk.
- Master login = tenant admin (email/password → Sanctum token); added kiosk face registration (`kiosk/employees` + `kiosk/enroll`).

---

## How to update

Append a new dated section at the top whenever you finish a task. Keep entries to 1–4 bullet lines: what changed, key command/path, and any gotcha worth remembering.
