# Changelog
## [1.0.22] - 2026-09-01

### Added
- **Audio & Haptic Feedback on Scan**: Instant system click sound and medium haptic confirmation on verified face match, with warning haptic alerts on invalid / multiple / unrecognized faces.
- **Camera Flashlight / Torch Toggle**: Dedicated torch button in the scanner top bar allowing operators and students to scan easily in dark corridors, entry gates, or low-light evening shifts.
- **Employee Code / Student Roll No Display**: Success verification card now displays the person's Employee ID / Student Roll No for unequivocal visual confirmation.
- **Fast-Line 3-Second Re-arm**: Reduced result hold time from 20s to 3s with a live countdown and an immediate "Tap to skip" trigger, enabling high throughput (15–20 scans/min) during shift and morning school rushes.
- **Kiosk Home Live Attendance Summary**: Added a live real-time status card on the dashboard showing today's total scanned count and the last scanned employee/student.

### Fixed
- **App Lock BiometricPrompt Host**: Changed `MainActivity` to extend `FlutterFragmentActivity`, resolving biometric/pattern lock prompt initialization failures on Android.

## [1.0.21] - 2026-09-01

### Changed
- **Executive App Header Redesign**: Redesigned the top header with a sleek glass-surface gradient card, refined brand logo badge with glowing border, live terminal online status indicator, and styled micro-card action buttons for App Lock, Theme Selector, and Logout.
- **Home Actions List View**: Converted action cards into a modern vertical list view with prominent gradient icon badges, clear typography, and navigation indicators.

## [1.0.20] - 2026-09-01

### Changed
- Redesigned the daily attendance report with a responsive date header, compact refresh action, visual attendance metrics, and clearer employee check-in/check-out cards that stay readable on narrow kiosk displays.

## [1.0.19] - 2026-09-01

### Added
- **App Lock** — protect the kiosk with the phone's own native lock (fingerprint, face, pattern or PIN) instead of a separate in-app password. Enable it from the new lock icon on the home screen, choose "Phone lock" (any lock the device already has) or "Biometric only" (fingerprint / face), and test the unlock right from settings.
- The lock screen appears on cold start (when enabled) and automatically re-locks the kiosk whenever it returns from the background, so a put-down tablet can't be picked up and used without unlocking.
- Nothing is stored inside the app — the existing device lock (already set up in the phone's own Settings) is the only credential used.

## [1.0.18] - 2026-09-01

### Changed
- **Face scan screen redesigned to match the product poster** — the camera is no longer shown full-screen. It now sits inside a framed, rounded “device screen” on the themed branded background: brand header on top, face guide + live status pill inside the camera, and the green “Face Verified / Attendance Marked / time / Welcome {name}!” result card overlaid at the bottom of the framed view.

## [1.0.17] - 2026-09-01

### Fixed
- **Register Face no longer shows a generic “Server error” when an employee already has a face registered.** Selecting an already-registered employee now shows a clear “Face already registered” confirmation (Cancel / Re-register), and a failed re-registration is reported as “Duplicate face — this employee is already registered” instead of a server error.
- Backend: re-enrolling a face no longer throws a 500 due to a profile-version collision — concurrent/duplicate enrolls now retry with a fresh version, and a genuine duplicate returns a clear 422 “Face already registered for this employee.”

## [1.0.16] - 2026-08-31

### Fixed
- Kiosk now reports device health to the backend every 60s from the home screen (heartbeats were implemented but never scheduled, so the admin Devices screen always showed the kiosk as offline/stale).
- The master login token is now stored in platform-secure storage (shared `TokenStorage`) and restored on startup, so a rebooted kiosk keeps its authenticated session.

## [1.0.15] - 2026-08-31

### Fixed
- **Face recognition no longer accepts every face.** The local matcher compared only five facial-proportion ratios with a permissive distance threshold (0.32), so virtually any scanned face was matched to a registered employee (impostor accept rate ≈ 100 %).
- The matcher now uses a richer 12-feature normalized signature with a calibrated, strict distance threshold plus a nearest-neighbour margin: a scan is accepted only when the closest enrolled face is far closer than the second-closest, so an ambiguous or random face is rejected instead of guessed.
- Scans must now be frontal (yaw/pitch/roll within limits) and live (both eyes open) before any event is recorded; side profiles and closed eyes are rejected with a clear on-screen hint.
- The scan screen now requires exactly one face in frame (multiple faces are rejected) and unknown/ambiguous faces are logged for admin review instead of being accepted as an employee.
- Enrolled profile images are only loaded into the on-device gallery when they contain the key landmarks and are frontal, so a noisy enrolled photo can no longer poison matching.

## [1.0.14] - 2026-08-31

### Added
- TT Staff Pro branded footer ("TT STAFF PRO | ttstaffpro.in" + app version) now shows on every kiosk screen.
- Face-scan success now shows the full branding result card: green check, "Face Verified", "Attendance Marked", the live time (e.g. 09:12 AM) and "Welcome <Name>!" — matching the product poster.
- Scan screen top bar now shows the TT Staff Pro logo + wordmark.

## [1.0.13] - 2026-08-31

### Fixed
- Daily attendance report now shows check-in/check-out date & time in Asia/Kolkata, so a scan just after midnight is not shown as the previous day.
- After a successful scan the kiosk now holds the result for 20 seconds (with a live countdown) before re-arming, so the same face is not captured again immediately.
- Added server-side 20s cooldown so lingering faces cannot flip check-in/check-out state within seconds.

## [1.0.12] - 2026-08-31

### Fixed
- Register Face list no longer shows every employee as "Unregistered" after enrollment.
- The backend's admin-profiles payload (Laravel paginator + snake_case keys) is now parsed correctly, so freshly registered faces show "Registered" on the picker.
- After a successful registration the picker reloads automatically and the employee's status updates to "Registered" right away.

## [1.0.11] - 2026-08-31

### Fixed
- Fixed the live camera preview appearing rotated 90° so an upright face no longer shows sideways during a scan.
- The same employee is no longer scanned twice in a row within 20 seconds, preventing an accidental check-in from being flipped into a check-out.
- Recognition results now read the backend's snake_case response (`attendance_action`/`attendance_id`), so the screen shows the real "Check-in recorded" / "Check-out recorded" action instead of a generic message.

## [1.0.10] - 2026-08-31

### Added
- Register Face employee list now shows a status caption under every staff member: green “Face Registered” when they already have an approved face profile, and “Unregistered” otherwise.
- Registration status is cross-checked against the approved admin profiles so it stays correct even when the employees endpoint omits the flag.

## [1.0.9] - 2026-08-31

### Fixed
- Fixed kiosk daily attendance parsing for server payloads that use snake_case field names such as `employee_name`, `check_in`, `check_out`, and `marked_at`.
- Attendance rows now display the staff name plus exact date & time for every record so operators can see who marked attendance and when.
- Added a regression test to keep the kiosk report resilient to backend key naming mismatches.

## [1.0.8] - 2026-08-31

### Fixed
- Locked the kiosk face-scan and face-registration screens to the device's natural portrait orientation so the preview stays upright and does not rotate unexpectedly.
- Removed rotation logic that was causing distorted previews and repeated capture failures during face enrollment/check-in.
- Prevented the app from re-triggering the camera flow in a rotated state that could contribute to session/token instability.

## [1.0.7] - 2026-08-30

### Fixed
- Kiosk home screen no longer triggers heavy profile/sync work during the first paint,
  reducing startup lag and keeping the dashboard responsive.
- Scan loop now guards against stale widget lifecycle state and re-arming race conditions,
  making the face-check-in/out flow smoother and more robust on wall-mounted tablets.
- Flutter analyzer warnings on the kiosk scan screen were cleaned up without changing app behavior.

## [1.0.6] - 2026-08-30

### Fixed
- Camera preview stays upright in portrait mode for face registration.
- After a successful registration, the app returns to the staff list instead of
  leaving the operator stuck on the capture screen.
- Register Face employee picker now shows the real error reason instead of a
  generic "Check connectivity" message (e.g. session expired vs. no network).
- Added "Log in again" action on the Register Face screen when the kiosk
  master session has expired (401) so a wall-mounted tablet can recover
  without a manual app reset.
- Registration failure messages now surface the underlying server reason.

## [1.0.5] - 2026-08-30

### Fixed
- Register Face employee picker now shows the real error reason instead of a
  generic "Check connectivity" message (e.g. session expired vs. no network).
- Added "Log in again" action on the Register Face screen when the kiosk
  master session has expired (401) so a wall-mounted tablet can recover
  without a manual app reset.
- Registration failure messages now surface the underlying server reason.

## [1.0.4] - 2026-08-30

### Added
- App version label ("v1.0.4") pinned to the bottom of every kiosk screen
  (splash, company login, admin login, home, scan, register face, report).

### Fixed
- Home action-card titles no longer wrap mid-word on narrow screens — labels
  scale to fit on one line; sync-status text no longer truncates.

## [1.0.3] - 2026-08-30

### Fixed
- Camera preview rotation now derives from the device's sensor orientation
  instead of a fixed 3-quarter turn, so face scan & face registration previews
  stay upright on all devices (kiosk_scan_screen, kiosk_register_face_screen).

## [1.0.2] - 2026-08-30

### Fixed
- Camera scan screen now keeps the device's default rotation — portrait stays
  portrait, landscape stays landscape (no longer forces portrait).

## [1.0.1] - 2026-08-29

### Added
- Initial standalone kiosk release: admin login, face scan (check-in/check-out),
  face registration, daily report, offline event queue.
