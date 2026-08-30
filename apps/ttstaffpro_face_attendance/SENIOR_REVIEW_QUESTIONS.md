# Face Attendance Kiosk — Senior Review Questions

Short questions to confirm scope/priority with the senior team.

## 1. Liveness / Anti-spoofing (biggest gap)
- Do we need real liveness (blink / head-movement check), or is the current static "eyes open" check enough for v1?
- Is a printed-photo / video attack in our threat model? Who owns the anti-spoof decision — app or server?
- The app currently sends `livenessStatus: pass` on every event — is that acceptable without on-device verification?

## 2. Audio feedback
- Should the kiosk play a sound (beep / voice) on check-in vs check-out and on errors?
- Any brand audio requirement, or is a simple system beep fine?

## 3. Unmatched-face fallback
- When a face isn't matched, do we allow manual clock-in (employee code / PIN), or must it be face-only?
- If manual fallback exists, who can do it from the kiosk — admin only?

## 4. Double clock-in protection
- What cooldown should we enforce between one employee's check-in and check-out (e.g. 60s)?
- Should anti-passback be enforced app-side or server-side?

## 5. Face profile refresh while running
- Should the kiosk auto-refresh enrolled faces periodically (e.g. every N min) instead of only on restart?
- How fast must a newly-registered face appear on the kiosk (SLA)?

## 6. Live status on home screen
- Does the home screen need a live "today present / absent" count for supervisors, or is the daily report enough?
- Do we need `/admin/dashboard` + `/admin/audit-log` on the server to review snapshots/audit from the kiosk?

## 7. Device health
- Should heartbeat report real battery level, or is a hardcoded value acceptable?
- Do we need remote device settings / revocation UI?
