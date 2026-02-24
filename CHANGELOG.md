# Changelog

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
