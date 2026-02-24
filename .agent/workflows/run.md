---
description: How to run the Open Core HR application locally on an emulator or device.
---

### Prerequisites
- Flutter SDK installed and in PATH.
- Android Studio or VS Code with Flutter extension.
- An Android emulator or physical device connected.

### Steps

1. **Clean and Get Dependencies**
   Run these commands to ensure everything is fresh.
   ```powershell
   flutter clean
   flutter pub get
   ```

2. **Check Connected Devices**
   ```powershell
   flutter devices
   ```

3. **Run the App**
   Replace `<device-id>` with the ID from the previous step.
   ```powershell
   flutter run -d <device-id>
   ```

4. **Troubleshooting**
   - If you see "StandardFileSystem only supports file:* and data:* URIs", check for broken imports or non-standard characters in file paths.
   - If imports are failing, ensure `pubspec.yaml` name is set to `open_core_hr`.
