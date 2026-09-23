# Face Attendance — Implementation Plan & API Contract

> Scope: wall-mounted tablet kiosk for single-point face attendance, staff face registration in the employee app, and sync of check-in/check-out into the existing attendance module.

Applies to:

- Kiosk app — `apps/ttstaffpro_face_attendance`
- Employee app — `open_core_hr`
- Backend — Laravel `ttstaffpro.in/api/V1`

---

## 1. Requirements → Implementation mapping

| # | Requirement | Where | Status |
|---|-------------|-------|--------|
| 1 | Match company name on login | Kiosk company login | ✅ implemented |
| 2 | Add your face staff registration | Employee app face registration | ✅ implemented |
| 3 | List of done / pending face registrations | Employee app admin review | ✅ implemented |
| 4 | Done registrations sync to staff login | Backend links face profiles to employee | ✅ implemented |
| 5 | Master login for single tablet + always-on scan | Kiosk master login + wakelock | ✅ implemented |
| 6 | Face scan → check-in / check-out | Kiosk event upload | ✅ implemented |
| 7 | Staff-wise attendance report synced to employee app | Server persists attendance | ✅ implemented |
| 8 | Late check-in / early check-out auto-computed | Main attendance engine | ✅ implemented |

---

## 2. Kiosk app flow

1. company login
2. master login
3. device registration / heartbeat
4. kiosk home / scan screen
5. face recognition or presence validation
6. upload attendance event
7. sync pending queue if offline
8. daily report and admin review

Key behaviours:

- always-on attendance screen
- screen stay awake using wakelock and immersive mode
- offline-first queue with retry
- device token + UUID-based sync identifier

---

## 3. Backend API contract (Laravel, prefix `face-attendance`)

### Existing (already used by repo)

| Method | Route | Purpose |
|--------|-------|---------|
| GET | `/admin/profiles` | List profiles, `status` filter |
| POST | `/admin/profiles/{id}/approve|reject|reset|re-enroll` | Admin actions |
| GET | `/self/eligibility` | Can current user register |
| POST | `/self/register` | Multipart `images[]` |
| GET | `/self/profile` | Own profile status |
| POST | `/device/register` | Returns device token |
| POST | `/device/heartbeat` | Keep alive |
| POST | `/device/events` | Upload attendance event |
| POST | `/device/sync-batch` | Offline event batch |
| GET | `/admin/dashboard` | Admin dashboard |
| GET | `/admin/audit-log` | Audit log |

### New / required by this plan

| Method | Route | Purpose |
|--------|-------|---------|
| POST | `/kiosk/company-match` | company match by name |
| POST | `/kiosk/login` | kiosk operator login |
| POST | `/kiosk/device-token` | issue device token |
| GET | `/kiosk/report` | date-wise report |

### Sync into existing attendance module
When `/device/events` is processed, the server should create or update the same attendance record used by the employee and sales apps so late/early logic applies automatically.

---

## 4. Data model additions

### Client-side local persistence

- `KioskSettings` with company info, master token, device UUID, device token, heartbeat
- `PendingFaceEvent` in local queue with event UUID, eventType, employeeId, snapshotPath, timestamp, status

---

## 5. Deliverables

- face attendance kiosk app in `apps/ttstaffpro_face_attendance`
- employee app face registration screens
- admin review screens for registrations
- repository and API route integration
- daily kiosk report view
- offline queue and sync support

---

## 6. Build & deploy notes

- Kiosk APK: `cd apps/ttstaffpro_face_attendance && flutter build apk --release`
- install on a wall-mounted tablet
- grant camera permission and login with company + master credentials
- keep app active using wake lock and immersive mode

---

## 7. Success criteria

- employee can register face attendance with low friction
- kiosk can accept repeated scans without manual re-entry
- attendance records sync into the core attendance engine
- admins can approve or reject registrations
- daily staff report reflects late / early / in / out states
