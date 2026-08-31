import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/api_routes.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'package:open_core_hr/models/face_attendance/face_device_model.dart';
import 'package:open_core_hr/models/face_attendance/face_event_model.dart';
import 'package:open_core_hr/models/face_attendance/face_profile_model.dart';
import 'package:open_core_hr/models/face_attendance/kiosk_model.dart';
import 'package:open_core_hr/utils/app_constants.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'face_matcher.dart';
import 'kiosk_settings.dart';
import 'offline_store.dart';

/// Orchestrates the kiosk backend interactions:
/// device registration, profile-package loading (for on-device matching),
/// event upload, offline sync and heartbeat.
class KioskService {
  // Created lazily: instantiating the repository eagerly at app startup would
  // touch SharedPreferences/Dio before the Flutter binding is ready and can
  // cause a white screen on launch.
  FaceAttendanceRepository? _repoInstance;
  FaceAttendanceRepository get _repo =>
      _repoInstance ??= FaceAttendanceRepository();

  final KioskSettings settings;
  final OfflineStore offlineStore;
  final FaceMatcher matcher = FaceMatcher();

  /// Enrolled staff signatures keyed by employeeId.
  final Map<int, FaceSignature> enrolledSignatures = {};
  final Map<int, String> employeeNames = {};
  bool profilesLoaded = false;
  int _profileVersion = 0;

  KioskService({required this.settings, required this.offlineStore});

  // ---------------------------------------------------------------------------
  // Login (company match + master login)
  // ---------------------------------------------------------------------------

  /// Requirement 1: match the typed company name against the backend.
  ///
  /// On success it persists the company + tenant context so the shared
  /// AuthInterceptor sends the `X-Tenant-ID` header on subsequent calls.
  Future<KioskCompanyMatchResult> matchCompany(String companyName) async {
    final result = await _repo.kioskCompanyMatch(companyName);
    if (result.ok && result.company != null) {
      final company = result.company!;
      await settings.saveCompany(
        id: (company.id ?? 0).toString(),
        name: company.name ?? companyName,
        logoUrl: company.logoUrl,
        tenantId: company.tenantId,
      );
      await activateTenantContext();
    }
    return result;
  }

  /// Requirement 5: master login for the single-point tablet.
  ///
  /// On success it persists the master token so the shared AuthInterceptor
  /// sends it as the `Authorization: Bearer` header.
  Future<KioskLoginResult> masterLogin({
    required String companyId,
    required String username,
    required String password,
  }) async {
    final result = await _repo.kioskLogin(
      companyId: companyId,
      username: username,
      password: password,
    );
    if (result.ok && result.masterToken != null) {
      await settings.saveMasterSession(result.masterToken!);
      await activateMasterSession();
    }
    return result;
  }

  /// Persists the tenant context for the shared AuthInterceptor.
  Future<void> activateTenantContext() async {
    final tenantId = settings.tenantId;
    if (tenantId == null || tenantId.isEmpty) return;
    await setValue(isSaaSModePref, true);
    await setValue(tenantPref, tenantId);
  }

  /// Persists the master token for the shared AuthInterceptor.
  Future<void> activateMasterSession() async {
    final token = settings.masterToken;
    if (token == null || token.isEmpty) return;
    await setValue(tokenPref, token);
  }

  /// Requirement 6: date-wise staff attendance report.
  Future<KioskDailyReport> getDailyReport(String date) {
    return _repo.getKioskDailyReport(date);
  }

  /// List the tenant's active employees (for kiosk face registration).
  Future<List<KioskEmployee>> getEmployees() {
    return _repo.kioskEmployees();
  }

  /// List employees enriched with face-registration status.
  ///
  /// The `/kiosk/employees` payload may not include a registration flag, so we
  /// cross-reference the approved admin profiles and mark each employee as
  /// registered / unregistered for the picker. If the profiles call fails we
  /// still return the employee list (with whatever the endpoint itself said)
  /// so the operator is never blocked.
  Future<List<KioskEmployee>> getEmployeesWithFaceStatus() async {
    final employees = await getEmployees();
    try {
      // The server's admin-profiles endpoint filters on the profile `status`
      // column (`active`/`pending`/`inactive`), not on approval — query active
      // profiles and keep only the approved ones so a freshly enrolled face is
      // correctly reported as "Registered".
      final profiles = await _repo.getAdminProfiles(status: 'active');
      final registeredIds = profiles
          .where((p) =>
              p.employeeId != null &&
              (p.approvalStatus == null || p.approvalStatus == 'approved'))
          .map((p) => p.employeeId!)
          .toSet();
      return employees.map((emp) {
        if (emp.employeeId == null) return emp;
        final hasFace =
            emp.faceRegistered ?? registeredIds.contains(emp.employeeId);
        if (hasFace == emp.faceRegistered) return emp;
        return emp.copyWith(
          faceRegistered: hasFace,
          profileStatus: hasFace ? (emp.profileStatus ?? 'approved') : null,
        );
      }).toList();
    } catch (_) {
      return employees;
    }
  }

  /// Register a face for an employee directly from the kiosk.
  Future<bool> enrollFace({
    required int employeeId,
    required List<String> imagePaths,
    required List<String> captureTypes,
    String? notes,
  }) {
    return _repo.kioskEnrollFace(
      employeeId: employeeId,
      imagePaths: imagePaths,
      captureTypes: captureTypes,
      notes: notes,
    );
  }

  // ---------------------------------------------------------------------------
  // Device registration
  // ---------------------------------------------------------------------------

  /// Registers this tablet with the backend. Generates a persistent device
  /// UUID on first run and stores the returned device token.
  Future<bool> registerDevice() async {
    try {
      var deviceUuid = settings.deviceUuid;
      if (deviceUuid == null || deviceUuid.isEmpty) {
        deviceUuid = const Uuid().v4();
      }

      final info = await DeviceInfoPlugin().androidInfo;
      final package = await PackageInfo.fromPlatform();

      final request = DeviceRegistrationRequest(
        deviceUuid: deviceUuid,
        deviceName: info.model.isNotEmpty ? info.model : 'TTStaffPro Kiosk',
        deviceType: 'tablet-kiosk',
        platform: 'android',
        deviceModel: info.model,
        osVersion: '${info.version.release} (SDK ${info.version.sdkInt})',
        appVersion: package.version,
        mlRuntime: 'google_mlkit',
        // Associate the device with the company matched at login so the
        // backend does not fall back to company id 1.
        companyId: int.tryParse(settings.companyId ?? ''),
      );

      final result = await _repo.registerKioskDevice(request);
      if (result.deviceToken == null || result.deviceToken!.isEmpty) {
        return false;
      }
      await settings.saveDevice(uuid: deviceUuid, token: result.deviceToken!);

      // Sync device identity to the keys the shared AuthInterceptor reads so
      // it sends X-Device-UUID / X-Device-Token on events, sync and report.
      await setValue('face_device_uuid', deviceUuid);
      await setValue('face_device_token', result.deviceToken!);
      return true;
    } catch (e) {
      // Device registration may fail when offline; that is OK — the kiosk
      // still works and retries registration when connectivity returns.
      if (settings.deviceUuid == null) {
        await settings.saveDevice(uuid: const Uuid().v4(), token: '');
      }
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Profile package (on-device recognition)
  // ---------------------------------------------------------------------------

  /// Downloads the enrolled profile package and builds local signatures.
  Future<void> loadProfilePackage({bool force = false}) async {
    try {
      final version = await _repo.getProfilePackageVersion();
      final downloadRequired = version.downloadRequired ?? true;
      final newVersion = int.tryParse(version.packageVersion ?? '') ?? 0;

      if (!force &&
          profilesLoaded &&
          !downloadRequired &&
          newVersion <= _profileVersion) {
        return;
      }

      final profiles = await _repo.downloadProfilePackage();
      enrolledSignatures.clear();
      employeeNames.clear();

      final dir = await getApplicationDocumentsDirectory();
      final matcher = this.matcher;

      for (final profile in profiles) {
        final employeeId = profile.employeeId;
        if (employeeId == null) continue;
        final image = _frontImage(profile);
        final imageUrl = image == null ? null : _resolveImageUrl(image);
        if (imageUrl == null) continue;

        final fileName = 'profile_$employeeId.jpg';
        final localPath = await _downloadSafe(imageUrl, dir, fileName);
        if (localPath == null) continue;

        final face = await matcher.detectInFile(localPath);
        if (face == null) continue;

        enrolledSignatures[employeeId] = matcher.signatureOf(face);
        employeeNames[employeeId] = profile.employeeName ?? 'Employee $employeeId';
      }

      _profileVersion = newVersion;
      profilesLoaded = true;
    } catch (_) {
      // Keep whatever we already have; profile refresh is best-effort.
    }
  }

  /// The profile package returns relative storage paths (e.g.
  /// `face-attendance/profiles/1/x.jpg`) plus an absolute `imageUrl` when the
  /// backend provides one. Resolve a full URL so the image can be downloaded.
  String? _resolveImageUrl(FaceEnrollmentImageMetadata image) {
    final url = image.imageUrl;
    if (url != null && url.trim().isNotEmpty) return url.trim();

    final filePath = image.filePath;
    if (filePath == null || filePath.trim().isEmpty) return null;
    // APIRoutes.baseURL is e.g. https://ttstaffpro.in/api/V1/ → storage root.
    final base = APIRoutes.baseURL
        .replaceFirst(RegExp(r'/?api/?V1/?$'), '')
        .replaceFirst(RegExp(r'/?$'), '');
    return '$base/storage/${filePath.trim().replaceFirst(RegExp(r'^/'), '')}';
  }

  FaceEnrollmentImageMetadata? _frontImage(FaceProfileDetail profile) {
    final images = profile.images ?? [];
    if (images.isEmpty) return null;
    return images.firstWhere(
      (img) => img.captureType == 'front',
      orElse: () => images.first,
    );
  }

  Future<String?> _downloadSafe(
      String url, Directory dir, String fileName) async {
    try {
      return await downloadToDocuments(url, fileName);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Event upload (check-in / check-out)
  // ---------------------------------------------------------------------------

  /// Uploads a recognition event. Falls back to the offline queue when the
  /// network is unavailable or the server rejects the request.
  Future<RecognitionUploadResult?> uploadEvent({
    required String eventUuid,
    required String eventType,
    int? employeeId,
    required String recognitionStatus,
    double? confidenceScore,
    String? snapshotPath,
  }) async {
    final occurredAt = DateTime.now().toIso8601String();

    // Normalize to the server contract: 'unknown' -> 'unmatched', confidence
    // is 0-100 on the server (we work with 0-1 from the local matcher).
    final status =
        recognitionStatus == 'unknown' ? 'unmatched' : recognitionStatus;
    final score = confidenceScore == null
        ? null
        : (confidenceScore * 100).clamp(0, 100).toDouble();

    try {
      final result = await _repo.uploadRecognitionEvent(
        eventUuid: eventUuid,
        eventType: eventType,
        employeeId: employeeId,
        recognitionStatus: status,
        confidenceScore: score,
        livenessStatus: 'pass',
        spoofStatus: 'none',
        matchThreshold: 34,
        occurredAt: occurredAt,
        snapshotPath: snapshotPath,
      );
      return result;
    } catch (_) {
      // Offline — queue for later sync.
      await offlineStore.enqueue(PendingFaceEvent(
        eventUuid: eventUuid,
        eventType: eventType,
        employeeId: employeeId,
        recognitionStatus: status,
        confidenceScore: score,
        occurredAt: occurredAt,
        snapshotPath: snapshotPath,
      ));
      return null;
    }
  }

  /// Flushes the offline queue to the server.
  ///
  /// Each queued event is replayed through the single-event endpoint with
  /// `eventType=attendance` so the server resolves check-in/check-out exactly
  /// like it does for live scans. (The `device/sync-batch` endpoint only
  /// accepts explicit `checkin`/`checkout` values — it rejects `attendance` —
  /// and the queue stores the unresolved `attendance` type, so batching the
  /// raw queue would always fail validation.)
  Future<int> syncPendingEvents() async {
    final pending = offlineStore.allPending();
    if (pending.isEmpty) return 0;

    var synced = 0;
    for (final e in pending) {
      try {
        await _repo.uploadRecognitionEvent(
          eventUuid: e.eventUuid,
          eventType: e.eventType, // 'attendance' -> server resolves checkin/checkout
          employeeId: e.employeeId,
          recognitionStatus: e.recognitionStatus,
          confidenceScore: e.confidenceScore,
          livenessStatus: 'pass',
          spoofStatus: 'none',
          matchThreshold: 34,
          occurredAt: e.occurredAt,
          snapshotPath: e.snapshotPath,
        );
        await offlineStore.remove(e.eventUuid);
        synced++;
      } catch (_) {
        // Leave it queued; retry on the next sync pass.
      }
    }
    return synced;
  }

  // ---------------------------------------------------------------------------
  // Heartbeat
  // ---------------------------------------------------------------------------

  Future<void> sendHeartbeat() async {
    if (!settings.isDeviceRegistered) return;
    try {
      final battery = _readBatteryLevel();
      final heartbeat = DeviceHeartbeatBody(
        batteryLevel: battery,
        networkState: 'online',
        storageState: 'ok',
        appVersion: _appVersion ?? '1.0.0',
      );
      await _repo.sendDeviceHeartbeat(heartbeat);
      await settings.saveHeartbeat(DateTime.now().toIso8601String());
    } catch (_) {
      // Best-effort keep-alive.
    }
  }

  int _readBatteryLevel() => 100; // Hook point for platform battery plugin.

  String? _appVersion;

  Future<void> loadAppVersion() async {
    try {
      final package = await PackageInfo.fromPlatform();
      _appVersion = package.version;
    } catch (_) {}
  }

  /// Cleans up downloaded snapshot files older than [olderThanDays] days.
  Future<void> cleanupOldSnapshots({int olderThanDays = 30}) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
      await for (final entity in dir.list()) {
        if (entity is File &&
            entity.path.endsWith('.jpg') &&
            entity.statSync().modified.isBefore(cutoff)) {
          try {
            entity.deleteSync();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
