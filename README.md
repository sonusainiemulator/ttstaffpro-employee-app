# Project Information

**Current Project Path:** `c:\Users\erson\Downloads\tt\ttstaffpro-mobile-app\mobile-app-version-5.0.1\open_core_employee_app`

## Build Information (2026-01-18)

### Signed App Bundle
The Global Open Core Employee App Signed Bundle build is complete!

**Actions Performed:**
1.  **Created Checklist**: A `build_checklist.md` file has been created to track the process.
2.  **Generated Signed Key**: A new keystore `upload-keystore.jks` was generated in `android/app/`.
    *   **Alias**: `upload`
    *   **Password**: `android`
    *   **Key Password**: `android`
3.  **Configured Signing**: created `android/key.properties` with the keystore credentials.
4.  **Built Optimized App Bundle**: Ran the build command with obfuscation and split-debug-info.
    *   **Command**: `flutter build appbundle --release --obfuscate --split-debug-info=./coverage/html`
    *   **Output Location**: `build\app\outputs\bundle\release\app-release.aab`
    *   **Size**: ~85.9MB

### Important Artifacts
*   **Keystore**: `android/app/upload-keystore.jks` (Keep this safe! You need it to sign future updates)
*   **Key Properties**: `android/key.properties` (Contains passwords, do not share publicly)
*   **App Bundle**: `build/app/outputs/bundle/release/app-release.aab`
