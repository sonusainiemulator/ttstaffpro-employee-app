# Changelog

## [1.1.2] - 2026-08-30

### Added
- Face Attendance integration: employee self-registration + admin approval screens (`FaceRegistrationScreen`, `FaceRegistrationAdminScreen`).
- Kiosk models + updated `FaceAttendanceRepository` (profile-package download, kiosk endpoints).
- Tests for face profile snake_case/camelCase parsing (`face_profile_parse_test.dart`).

### Changed
- Bumped `mobile_scanner` to `^7.2.0` and `google_mlkit_face_detection` to `^0.15.1`.
- Login store/screen, settings, home, splash & QR scanner updated for face-attendance entry points.
- `.gitignore` now excludes root `*.apk`/`*.aab`, `android/build/`, `ssh-config.ttstaffpro` and the standalone `/apps/` sub-apps (tracked in their own GitHub repos).

### Fixed
- Face profile parsing now handles snake_case API responses.

## [1.1.0] - 2026-04-22

### Changed
- Bumped app version to `1.1.0+0`.

## [5.0.4] - 2026-04-22

### Fixed
- **Payroll Module**: Corrected Salary Structure API route to use `payroll/salary-structure`, resolving `Resource not found` on Salary Structure screen.
- **Localization Compile Issue**: Fixed Vietnamese locale class closing-brace placement that could break debug build in recent changes.

### Changed
- Bumped app version to `5.0.4+7`.

## [5.0.3] - 2026-04-20

### Fixed
- **Actual Time Report**: Fixed overtime calculation bug where `lateCheckoutMinutes` and `actualBreakMinutes` were erroneously treated precisely as hours if provided via the API. Ensure standard conversion to hours when processing.

## [5.0.1] - 2026-04-02

### Added
- **Attendance Module**: Integrated V1 mobile-optimized API for Attendance.
- **Actual Time Report**: Added new `ActualTimeReportModel` and screen for detailed attendance reporting.
- **Release Assets**: Automatic build of signed APK and AAB for GitHub releases.

### Fixed
- **Payroll Module**: Corrected 404 errors by aligning with V1 API endpoints (Payroll Records, Payslip, Salary Structure).
- **Data Mapping**: Updated multiple screens to handle snake_case JSON from the new API.
- **UI/UX**: Refactored navigation bar and design system markers for better consistency.
- **App Store Fixes**: Addressed compilation and lint errors across Loan, Expense, and Leave modules.

### Changed
- Updated `pubspec.yaml` dependencies and configuration.
- Enhanced `android_beta.yml` workflow for better GitHub Release integration.


## [2026-01-18]

### Added
- **Signed App Bundle Build**: Successfully built signed Android App Bundle (`.aab`).
    - **Keystore**: Generated `android/app/upload-keystore.jks`.
        - Alias: `upload`
        - Passwords: `android`
    - **Configuration**: Created `android/key.properties` for signing credentials.
    - **Build Command**: `flutter build appbundle --release --obfuscate --split-debug-info=./coverage/html`
    - **Artifact**: `build/app/outputs/bundle/release/app-release.aab` (Size: ~85.9MB)
- **Documentation**: Added build checklist and project path to README.
- **Project Management**: Added `PROJECT_MANAGEMENT.md`, `CONTRIBUTING.md`, and GitHub issue templates.
- **Automation**: 
    - Configured **Dependabot** (`.github/dependabot.yml`) for weekly dependency updates.
    - Configured **CodeRabbit** (`.coderabbit.yaml`) for AI code reviews.
