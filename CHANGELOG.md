# Changelog

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
