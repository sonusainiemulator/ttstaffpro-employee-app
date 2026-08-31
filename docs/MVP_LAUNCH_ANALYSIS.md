# TT Staff Pro — Market-Launch MVP: Pain & Gap Analysis

> Prepared: 2026-08-31 · Scope: employee HRMS app (`open_core_hr`) + Face Attendance Kiosk (`apps/ttstaffpro_face_attendance`)
> Goal: turn the current build into a **market-launch-ready MVP**.

---

## 1. Executive summary

The app already has a **very broad feature set** (attendance, payroll, leave, expense, asset, documents, notice, chat, notifications, face attendance kiosk + QR app). Breadth is not the launch problem — **trust, verification, and release hygiene** are. The top launch risks are:

1. **No end-to-end test on a real device has ever been completed** (open since 2026-08-29). Nothing matters until the full flow is verified on real hardware.
2. **Both apps ship debug-signed releases** — they cannot be published to the Play Store as-is.
3. **Auth tokens were stored in plaintext SharedPreferences** (HRMS with payroll data) — **FIXED this session** (secure storage).
4. **Face attendance accepted every face** — **FIXED this session** (strict matcher, released as kiosk v1.0.15). The underlying matcher is still landmark-geometry (weak); an embedding upgrade is the long-term fix, and a product decision is needed about "face = identity vs face = presence" (see §5.6).
5. **Kiosk device-health heartbeats were never scheduled** — **FIXED this session** (devices now report online).

Recommended posture: **a launch-readiness sprint (P0s first), not more features.** The feature surface is already larger than most launch MVPs; the differentiator now is reliability and compliance.

---

## 2. Current state (what already works)

- **Employee app**: login/SaaS tenant selection, attendance (check-in/out, history, regularization), payroll + payslips, leave, expenses, documents, assets, notices, holidays, calendar, chat, notification history, dark/light theme, multi-language, module feature-flag gating, Firebase push + Crashlytics.
- **Face Attendance Kiosk** (`v1.0.15`): company match → admin login → device register → face enroll → face scan check-in/out → daily report; offline event queue; Hive persistence; light/dark; branded UI. Strict recognition matcher + tests now in place.
- **Backend** (Laravel, multi-tenant, `ttstaffpro.in`): attendance engine, payroll, leave, modules, face-attendance V1 API, kiosk/device APIs, admin console for face attendance.
- **CI/release**: kiosk APK CI in the root repo (manual `workflow_dispatch`); release artifacts published to GitHub Releases (v1.0.15 with APK).

---

## 3. Pain points & gaps (prioritized by launch risk)

Legend: 🔴 **P0** = launch blocker · 🟠 **P1** = must be done before broad rollout · 🟡 **P2** = growth/competitive.

### 🔴 P0 — Launch blockers

| # | Gap | Evidence | Action |
|---|-----|----------|--------|
| 1 | **No real-device E2E pass** | `TASK_BOARD.md` "Real-device manual testing of kiosk release APK" open since 2026-08-29 | Install v1.0.15 on a tablet/phone; verify: company match → admin login → device register → face enroll → scan check-in/out → daily report → offline sync → device appears online in admin console. Log results; fix whatever surfaces. |
| 2 | **Release APKs are debug-signed** | `android/app/build.gradle(.kts)`: `release { signingConfig = signingConfigs.debug }`; no `key.properties` | Create a keystore + `key.properties` (gitignored), wire signing config, produce a **signed** release AAB/APK. For Play, use Play App Signing (upload key). Do NOT commit the keystore or passwords. |
| 3 | **Auth token in plaintext** | Tokens were `setValue(tokenPref, …)` (SharedPreferences) | ✅ **FIXED this session** — `TokenStorage` (flutter_secure_storage, Keystore/Keychain) + migration + tests. Still verify on a real device that sessions survive restart + logout. |
| 4 | **Face recognition accepted every face** | kiosk matcher threshold 0.32 → impostor rate ≈ 100% | ✅ **FIXED + released (v1.0.15)** — strict 12-feature matcher + margin + frontal/liveness gates. Remaining: calibrate thresholds on real device photos; consider embedding upgrade (P2). |
| 5 | **Intermittent `Unknown column 'late_minutes'`** | Seen in tenant attendance queries; source not yet located (memory notes 2026-08-31) | Root-cause on the server (all tenant DBs). If it can still fire, attendance recording is at risk. Do not ignore — reproduce with a stack trace and fix the query/model. |
| 6 | **Privacy/consent for face data** | Kiosk uploads snapshots + recognition events; enrolled profile images stored on the server | Publish a privacy policy + data-retention config. The Presence-Attendance PRD explicitly says "no biometric retention" — **decide and document** the face-data stance before selling to customers. |

### 🟠 P1 — Before broad rollout

| # | Gap | Evidence | Action |
|---|-----|----------|--------|
| 7 | **Kiosk never sent heartbeats** | `sendHeartbeat()` existed but nothing scheduled it → admin device-health always stale | ✅ **FIXED this session** — periodic 60s heartbeat on the kiosk home screen. Verify in the admin Devices tab. |
| 8 | **APK ~136 MB** | kiosk release build | Build with `--split-per-abi` (→ ~50–70 MB per ABI) and `--obfuscate --split-debug-info`; add ABI splits in gradle or use CLI flags. |
| 9 | **Gradle deprecation** | Flutter warns Gradle 8.13 will be dropped | ✅ **FIXED this session** — bumped wrapper to 8.14.1 (root + kiosk). Confirm both apps build. |
| 10 | **Play Store listing assets** | no feature graphic/screenshots/privacy URL/data-safety form | Create: 512×512 icon (have), 1024×500 feature graphic, phone screenshots, privacy policy URL, data-safety form (token storage, face data, location). |
| 11 | **Notification completeness** | FCM infra exists; backlog wants attendance alerts (check-in/out, late, missed) | For MVP: verify FCM token registration, foreground/background push, in-app list + tap-to-open. Defer WhatsApp alerting to post-launch. |
| 12 | **Kiosk offline-queue + sync validation** | offline queue exists; only curl-tested | Real-device test: scan offline → reconnect → events sync (idempotent, no duplicates). |
| 13 | **Crash/ANR + analytics** | Crashlytics wired; ANR tracking not confirmed | Enable ANR + native crash reporting; smoke-test that a forced crash appears in the dashboard. |

### 🟡 P2 — Growth / competitive (post-launch)

- **Embedding-based face recognition** (MobileFaceNet/TFLite + cosine sim) for real biometric accuracy (replaces the landmark stop-gap).
- **Admin exception dashboard**: late/early/missed-checkout/absent lists, approval queue, summary cards (backlog Phase 3).
- **Attendance notifications**: check-in/out confirmations, late/early/missed alerts via FCM (+ WhatsApp later), dedupe + quiet-hours (backlog Phase 1/4).
- **APK: App Bundle + Play App Signing**, per-ABI test/release tracks.
- **Localization depth** and accessibility pass on both apps.
- **Offline-first employee app** (currently Hive for some modules; full offline payroll/leave view is a differentiator).

---

## 4. Things already fixed in recent history (so we don't re-do them)

- Kiosk camera preview rotation (sideways scan) · double-scan → check-in/check-out flip (20s cooldown) · white-screen startup (nb_utils `initialize`) · "Face not registered"/"Unregistered" (snake_case + paginator parsing) · INTERNET permission missing in release builds · release APK builds (boot-disk exhausted → Gradle cache on NVMe) · admin 404s on approve/reject/reset (route-model binding) · tenant-impersonation 419 · face-attendance web 403s (permission seeder) · registration approval status visibility · strict face recognition (v1.0.15) · secure token storage (this session) · kiosk heartbeats (this session) · Gradle 8.14.1 (this session).

---

## 5. Product decisions to make before launch

1. **Identity model**: The Presence-Attendance MVP PRD states identity = **authenticated account + signed credential**, camera = **face-presence only** (never identity). The face-attendance kiosk currently does **on-device identity matching**. These two stances conflict. Decide:
   - (a) Kiosk = identity verification (current) → needs embedding-grade accuracy + biometric consent + privacy policy; or
   - (b) Kiosk = presence confirmation + account/token identity (PRD-aligned) → no biometric data retention, simpler compliance.
   Either is launchable; mixing them without a policy is not.
2. **Face data retention**: how long are profile images + scan snapshots kept? Configurable per tenant? Exposed to admins?
3. **Release target**: Play Store (needs signed AAB + listing) vs direct APK distribution (GitHub/Telegram/WhatsApp) for the first customers. The kiosk is a **tablet app** — Play Private Apps / managed distribution may fit better than public listing.
4. **Pricing/packaging**: modules are flag-gated per tenant — define the base package vs paid modules (attendance vs face-attendance vs payroll, etc.).

---

## 6. Recommended next 2 sprints (launch-readiness)

### Sprint A — "Ship it" (P0, 1–2 days)
- [ ] Real-device E2E of kiosk v1.0.15 (install, register, enroll, scan, report, offline sync, heartbeat online).
- [ ] Create keystore + `key.properties` (gitignored) + signed release build for **both** apps; verify signing (`apksigner verify`).
- [ ] Publish privacy policy + set data-retention defaults; make the face-data stance explicit.
- [ ] Server: reproduce & fix `late_minutes` intermittent error on all tenant DBs.

### Sprint B — "Store-ready" (P1, 2–3 days)
- [ ] Split-per-ABI + obfuscated release builds (~50–70 MB).
- [ ] Play Store listing assets + data-safety form (or documented managed-distribution path for tablets).
- [ ] Notification smoke test (FCM register → push → in-app list → tap).
- [ ] Kiosk offline-queue real-device test (no duplicates, auto-sync).
- [ ] ANR/native crash reporting enabled; verify in Crashlytics.

### After launch (P2)
- Embedding face recognition · admin exception dashboard · attendance notification rules · localization/accessibility pass.

---

## 7. What changed in this session

- **Secure token storage** (`lib/utils/token_storage.dart` + `flutter_secure_storage`): auth tokens moved out of plaintext SharedPreferences into Android Keystore / iOS Keychain, with a sync in-memory cache (no async ripple in header builders), automatic migration of existing prefs tokens, and a safe fallback so login can never break. Wired into login, the Dio + legacy header paths, and logout; kiosk master token also secured. +6 unit tests.
- **Kiosk heartbeats**: the home screen now sends a device-health heartbeat every 60s (was never scheduled → devices showed offline in admin).
- **Gradle**: wrapper upgraded to 8.14.1 for the employee app and kiosk (removes the "will be dropped" warning).
- **MVP analysis**: this document.

## 8. Open items that need a human/owner

- Real-device E2E execution + log of results.
- Keystore creation + secure storage of its password (a secret — must not be committed or sent through chat).
- Product decision on face-identity vs face-presence and data-retention policy.
- Server-side `late_minutes` root-cause (needs the tenant DB stack trace).
