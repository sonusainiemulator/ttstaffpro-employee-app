# Tasks Log — Local Task History

Running log of completed tasks. **Newest entries go at the top.**

- Purpose: remember "last tasks history" locally per session, so context survives between conversations.
- Scope: covers both the root employee app (`open_core_hr`) and the sub-apps under `apps/` (face attendance kiosk, attend).
- Deep technical detail / gotchas for the kiosk live in the repo memory notes (`face-attendance.md`); link or summarize here.
- Versioned release notes belong in `CHANGELOG.md`; this file is the daily work log.

---

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
