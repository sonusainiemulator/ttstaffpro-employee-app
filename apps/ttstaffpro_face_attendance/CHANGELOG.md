# Changelog

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
