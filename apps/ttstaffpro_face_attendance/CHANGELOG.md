# Changelog
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
