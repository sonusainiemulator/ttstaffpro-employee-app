# 📋 Daily Development Task Board — TT Staff Pro

Easy daily task tracking: **🆕 Todo → 🔨 In Progress → ⏳ Pending → 🧪 Testing → ✅ Done**.

**How to use (2 minute daily habit):**
1. Morning: add today's tasks under `🆕 Todo`.
2. During work: move a task to `🔨 In Progress` when you start, `🧪 Testing` when ready to test.
3. `⏳ Pending` = blocked / waiting on someone or something (note the blocker).
4. Evening: move finished items to `✅ Done`, then copy them into **Daily Log**.
5. Commit once at end of day: `chore: update task board (2026-08-30)`.

---

## 🗓️ Today — 2026-08-30

| 🆕 Todo | 🔨 In Progress | ⏳ Pending (blocked/waiting) | 🧪 Testing | ✅ Done |
|---|---|---|---|---|
| | | Real-device manual testing of kiosk release APK | | ✅ Create daily task board |
| | | | | ✅ Push kiosk app to GitHub + README |
| | | | | ✅ Push `ttstaffpro_attend` app to GitHub + README |
| | | | | ✅ Commit root repo face-attendance changes |
| | | | | ✅ Gitignore release APK binaries (kiosk repo) |
| | | | | ✅ Fix camera rotation on real devices (employee + kiosk) |
| | | | | ✅ App version footer on all kiosk screens + home design fix |

**Quick add for today:**
- [ ] _(add your tasks here with `- [ ] task (priority)`)_

---

## 📜 Daily Log

### 2026-08-30
**Completed:**
- Created this daily task board (`TASK_BOARD.md`) → pushed `docs: add daily development task board`.
- Pushed **Face Attendance Kiosk** app to GitHub as its own **private** repo `sonusainiemulator/ttstaffpro-face-attendance` (152 files) + rewrote README (badges, mermaid flow, API table).
- Pushed **TTStaffPro Attend** (QR attendance) app to GitHub as its own **private** repo `sonusainiemulator/ttstaffpro-attend` (37 files) + rewrote README.
- Committed + pushed root repo face-attendance integration: `feat: face attendance self/admin registration + kiosk profile fixes` (30 files) — version bumped to `1.1.2+20260830`; fixed `?year` syntax bug in `holiday_repository`; regenerated MobX `.g.dart`; `flutter analyze` 0 errors.
- Gitignored `*.apk` binaries in kiosk repo → `chore: gitignore release apk binaries` (all 3 repos now clean & up to date).
- Fixed **camera rotation** on real devices — preview/capture no longer hardcodes a 90° turn, now derives from device `sensorOrientation` (+ EXIF-baked captures): employee app `fix: correct face capture camera rotation` (v1.1.3) and kiosk `fix: derive camera preview rotation from sensor orientation` (v1.0.3, scan + register screens).
- Added **app version footer** (`vX.Y.Z`) on all 7 kiosk screens via `KioskVersionFooter` + fixed home action-card labels wrapping mid-word (scale-to-fit) — kiosk `feat: show app version footer on all screens + fix home card text wrap` (v1.0.4).

**Pending:**
- **Real-device manual testing of kiosk release APK** — the only open task. Needs: install `TTStaffPro-Kiosk-v1.0.2-release.apk` on a real Android tablet/phone, verify company match → admin login → face register → scan check-in/check-out → daily report.

**Notes:**

### 2026-08-29 — Face Attendance Kiosk
**Completed:**
- Kiosk UI/UX matched to employee app (design system `#696CFF`, Poppins, glassmorphism).
- White-screen startup fix (root cause: `nb_utils.initialize()` missing → `LateInitializationError`).
- "Face not registered" fix (snake_case parsing + image URL resolution; server `employeeName`/`imageUrl` added).
- Full **Dark + Light mode** (user-selectable, persisted).
- Master login → **tenant admin login** (Sanctum token) + new `kiosk/employees` + `kiosk/enroll` backend.
- Single face-scan screen for all tenant staff check-in/check-out.
- Camera scan screen full-page redesign (portrait default, rotating capture).
- Boot-disk full (99%) fixed → Gradle cache relocated to 1TB volume.
- Release APK `TTStaffPro-Kiosk-v1.0.1-release.apk` (~135MB) built.

**Pending:**
- Real-device manual testing of kiosk release APK.
- GitHub upload of `apps/ttstaffpro_attend` (attendance app).

**Notes:** All live API endpoints verified via curl. `flutter analyze` clean; tests green.

---

## 🏷️ Status column meanings

| Column | Meaning | Move here when... |
|---|---|---|
| 🆕 Todo | Backlog / not started | Task is planned, clear, ready to pick up. |
| 🔨 In Progress | Working on it now | You started coding this task. |
| ⏳ Pending | Blocked / waiting | Waiting on server, review, device, or another person — **write the blocker**. |
| 🧪 Testing | Ready to verify | Code done, needs `flutter test` / `flutter analyze` / device test. |
| ✅ Done | Finished & verified | Passed testing AND committed/pushed. |

## 📌 Priority tags

- `(P0)` 🔴 Blocker / must do today
- `(P1)` 🟠 Important / this week
- `(P2)` 🟡 Nice to have

## 🔁 End-of-day checklist

- [ ] All finished items moved to `✅ Done` + copied to **Daily Log**.
- [ ] `flutter analyze` clean for changed files.
- [ ] Version + `CHANGELOG.md` bumped if a feature/fix landed.
- [ ] Committed (`git add` only relevant files) and `git push origin main`.
