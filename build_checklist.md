# Build Signed App Bundle Checklist

This checklist guides you through the process of creating a signed Android App Bundle (AAB) for release.

## Prerequisites
- [ ] Ensure `keytool` is installed (part of Java JDK).
- [ ] Ensure Flutter is installed and configured.

## Steps

### 1. Generate a Upload Keystore
Create a new keystore to sign your app. **Keep this file secure!** If you lose it, you won't be able to update your app on the Play Store.

### 2. Create `key.properties`
Create a file named `key.properties` in the `android/` directory. This file will contain your keystore credentials and should **NOT** be committed to version control.

### 3. Configure `build.gradle`
Modify `android/app/build.gradle` to read the signing config from `key.properties`.

### 4. Build the App Bundle
Run the build command to generate the signed AAB.
```bash
flutter build appbundle --release
```

## Output
The signed app bundle will be located at:
`build/app/outputs/bundle/release/app-release.aab`
