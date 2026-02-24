# Attendance & Tracking Module Skill

This skill documents the logic and implementation details for the Attendance and Location Tracking module.

## 🕒 Attendance Flow

The attendance system supports multiple modes (Manual, QR, Face, Geofence).

### 1. Check-In / Check-Out
- **Service**: `ApiService.checkInOut(Map req)`.
- **Payload**: Includes `status` (In/Out), `latitude`, `longitude`, `address`, `device_uid`, and `image` (if face attendance).
- **Validation**:
  - `Geofence`: Checked via `ApiService.validateGeofence` before allowing check-in.
  - `IP Address`: Checked via `ApiService.validateIpAddress`.

### 2. QR Attendance
- **Static QR**: `ApiService.verifyQr(String code)`.
- **Dynamic QR**: `ApiService.verifyDynamicQr(String code)`. Uses TOTP-style expiring codes for security.

### 3. Face Attendance
- **Library**: Uses Google ML Kit for face detection.
- **Workflow**: 
  1. Capture image via camera.
  2. Verify face markers.
  3. Upload markers/image to `ApiService.addOrUpdateFaceData`.

## 📍 Location Tracking

- **Background Service**: Handles periodic location updates.
- **Interval**: Controlled by `deviceLocationUpdateInterval` in `app_constants.dart`.
- **Offline Tracking**: If the device loses connection, coordinates are saved to the `offlineTrackingBox` (Hive) and synced later via `bulkDeviceStatusUpdateURL`.

## 📊 State Management
- **Store**: `GlobalAttendanceStore`.
- **Key Observables**: `isCheckedIn`, `todayAttendance`, `locationTrackingEnabled`.

## 🚀 Pro-Tip: "Anti-Spoofing"
The app checks for mock location providers. When implementing new tracking features, always check `permissionService.isLocationEnabled()` and `isMockLocation()` if available.
