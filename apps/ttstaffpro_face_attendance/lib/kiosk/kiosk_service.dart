import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/api_routes.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'package:open_core_hr/models/face_attendance/face_device_model.dart';
import 'package:open_core_hr/models/face_attendance/face_event_model.dart';
import 'package:open_core_hr/models/face_attendance/face_profile_model.dart';
import 'package:open_core_hr/models/face_attendance/kiosk_model.dart';
import 'package:open_core_hr/utils/app_constants.dart';
import 'package:open_core_hr/utils/token_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'face_matcher.dart';
import 'kiosk_settings.dart';

/// Orchestrates the kiosk backend interactions:
/// device registration, profile-package loading (for on-device matching),
/// event upload and heartbeat.
class KioskService {
  // Created lazily: instantiating the repository eagerly at app startup would
  // touch SharedPreferences/Dio before the Flutter binding is ready and can
  // cause a white screen on launch.
  FaceAttendanceRepository? _repoInstance;
  FaceAttendanceRepository get _repo =>
      _repoInstance ??= FaceAttendanceRepository();

  final KioskSettings settings;
  final FaceMatcher matcher = FaceMatcher();

  /// Enrolled staff signatures keyed by employeeId.
  final Map<int, FaceSignature> enrolledSignatures = {};
  final Map<int, String> employeeNames = {};
  final Map<int, String> employeeCodes = {};
  final ValueNotifier<int> todayScannedCount = ValueNotifier<int>(0);
  final ValueNotifier<String?> lastScannedInfo = ValueNotifier<String?>(null);
  bool profilesLoaded = false;
  int _profileVersion = 0;

  /// Tracks employees whose face registration was removed/reset so old faces
  /// are not mistakenly restored or matched.
  final Set<int> _removedEmployeeIds = {};

  /// Tracks employees registered locally in this session so they remain active
  /// in memory and matched immediately even if the server profile package is
  /// still propagating.
  final Set<int> _locallyEnrolledEmployeeIds = {};

  void recordLocalScan({
    required String name,
    String? code,
    String? action,
  }) {
    todayScannedCount.value++;
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    lastScannedInfo.value = '$name • $timeStr';
  }

  KioskService({required this.settings});

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
    await TokenStorage.write(token);
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
      // Query both active and pending profiles so we have accurate status
      // across all staff.
      final results = await Future.wait([
        _repo.getAdminProfiles(perPage: 500, status: 'active'),
        _repo.getAdminProfiles(perPage: 500, status: 'pending'),
      ]);
      final profiles = [...results[0], ...results[1]];
      final profilesByEmployee = <int, FaceProfileSummary>{};
      for (final profile in profiles) {
        final employeeId = profile.employeeId;
        if (employeeId == null) continue;
        final status = (profile.status ?? '').toLowerCase().trim();
        final approval = (profile.approvalStatus ?? '').toLowerCase().trim();
        if (status == 'inactive' ||
            status == 'reset' ||
            status == 'removed' ||
            status == 'deleted' ||
            status == 'not_registered' ||
            approval == 'rejected') {
          continue;
        }

        // A user can have an old pending/active profile at the same time.
        // Do not let API ordering make the picker show the wrong state.
        final current = profilesByEmployee[employeeId];
        if (current == null ||
            _profilePriority(profile) > _profilePriority(current)) {
          profilesByEmployee[employeeId] = profile;
        }
      }
      return employees.map((emp) {
        final empId = emp.employeeId;
        if (empId == null) return emp;

        // If explicitly removed locally in this session and not re-enrolled:
        if (_removedEmployeeIds.contains(empId) &&
            !_locallyEnrolledEmployeeIds.contains(empId)) {
          return emp.copyWithFaceStatus(
            faceRegistered: false,
            profileStatus: 'not_registered',
            faceProfileId: null,
            faceApprovalStatus: null,
          );
        }

        // If enrolled locally in this session:
        if (_locallyEnrolledEmployeeIds.contains(empId)) {
          return emp.copyWithFaceStatus(
            faceRegistered: true,
            profileStatus: 'active',
            faceProfileId: emp.faceProfileId,
            faceApprovalStatus: 'approved',
          );
        }

        final profile = profilesByEmployee[empId];
        final profileStatus = (profile?.status ?? '').toLowerCase().trim();
        final approvalStatus =
            (profile?.approvalStatus ?? '').toLowerCase().trim();
        final approved =
            approvalStatus.isEmpty || approvalStatus == 'approved';
        final isApprovedActive =
            profile != null && approved && profileStatus == 'active';
        final isPending = profile != null &&
            !isApprovedActive &&
            (profileStatus == 'pending' || approvalStatus == 'pending');

        if (isApprovedActive) {
          return emp.copyWithFaceStatus(
            faceRegistered: true,
            profileStatus: 'active',
            faceProfileId: profile.id,
            faceApprovalStatus: 'approved',
          );
        } else if (isPending) {
          return emp.copyWithFaceStatus(
            faceRegistered: false,
            profileStatus: 'pending',
            faceProfileId: profile.id,
            faceApprovalStatus: 'pending',
          );
        } else {
          // No active or pending profile: employee is unregistered and can
          // register face again. Explicitly clear all status fields.
          return emp.copyWithFaceStatus(
            faceRegistered: false,
            profileStatus: 'not_registered',
            faceProfileId: null,
            faceApprovalStatus: null,
          );
        }
      }).toList();
    } catch (_) {
      return employees;
    }
  }

  int _profilePriority(FaceProfileSummary profile) {
    final status = (profile.status ?? '').toLowerCase().trim();
    final approval = (profile.approvalStatus ?? '').toLowerCase().trim();
    if (status == 'active' && (approval.isEmpty || approval == 'approved')) {
      return 3;
    }
    if (status == 'pending' || approval == 'pending') {
      return 2;
    }
    return 1;
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

  /// Immediately creates and enrolls a local face signature from a freshly
  /// captured front image so the newly registered employee can scan for
  /// attendance right away without waiting for backend package propagation.
  Future<bool> registerLocalFaceSignature({
    required int employeeId,
    required String name,
    required String imagePath,
    String? code,
  }) async {
    try {
      final face = await matcher.detectInFile(imagePath);
      if (face == null || !matcher.hasUsableLandmarks(face)) return false;
      final signature = matcher.signatureOf(face);
      if (!signature.isFrontal) return false;

      _removedEmployeeIds.remove(employeeId);
      _locallyEnrolledEmployeeIds.add(employeeId);

      enrolledSignatures[employeeId] = signature;
      employeeNames[employeeId] =
          name.trim().isNotEmpty ? name.trim() : 'Employee $employeeId';
      if (code != null && code.trim().isNotEmpty) {
        employeeCodes[employeeId] = code.trim();
      }

      // Also cache to documents directory so kiosk restart preserves it
      final dir = await getApplicationDocumentsDirectory();
      final targetFile = File('${dir.path}/profile_$employeeId.jpg');
      await File(imagePath).copy(targetFile.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deactivate an employee's current face profile from the admin kiosk.
  /// Purges in-memory signatures and cached files, then force refreshes.
  Future<bool> removeFace({
    required int profileId,
    int? employeeId,
  }) async {
    final ok = await _repo.resetProfile(profileId);
    if (ok) {
      if (employeeId != null) {
        _locallyEnrolledEmployeeIds.remove(employeeId);
        _removedEmployeeIds.add(employeeId);
        enrolledSignatures.remove(employeeId);
        employeeNames.remove(employeeId);
        employeeCodes.remove(employeeId);
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/profile_$employeeId.jpg');
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      await loadProfilePackage(force: true);
    }
    return ok;
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
      final newSignatures = <int, FaceSignature>{};
      final newNames = <int, String>{};

      final dir = await getApplicationDocumentsDirectory();
      final matcher = this.matcher;

      for (final profile in profiles) {
        final employeeId = profile.employeeId;
        if (employeeId == null) continue;
        // If employee was explicitly removed, do not resurrect their profile
        if (_removedEmployeeIds.contains(employeeId)) continue;

        final image = _frontImage(profile);
        final imageUrl = image == null ? null : _resolveImageUrl(image);
        if (imageUrl == null) continue;

        final fileName = 'profile_$employeeId.jpg';
        final localPath = await _downloadSafe(imageUrl, dir, fileName);
        if (localPath == null) continue;

        final face = await matcher.detectInFile(localPath);
        if (face == null) continue;

        // Only enroll a clean frontal reference with the key landmarks
        // present; a noisy / angled enrolled image would poison matching.
        if (!matcher.hasUsableLandmarks(face)) continue;
        final signature = matcher.signatureOf(face);
        if (!signature.isFrontal) continue;

        newSignatures[employeeId] = signature;
        newNames[employeeId] = profile.employeeName ?? 'Employee $employeeId';
      }

      // Preserve any locally enrolled employee signatures that aren't yet in
      // the backend package download so newly registered staff scan right away.
      for (final empId in enrolledSignatures.keys) {
        if (!_removedEmployeeIds.contains(empId) &&
            !newSignatures.containsKey(empId)) {
          newSignatures[empId] = enrolledSignatures[empId]!;
          if (employeeNames.containsKey(empId)) {
            newNames[empId] = employeeNames[empId]!;
          }
        }
      }

      // Also restore any cached profile files on disk that haven't been removed
      // and aren't in newSignatures yet (e.g. after app restart).
      try {
        final files = dir.listSync();
        for (final entity in files) {
          if (entity is File && entity.path.contains('profile_')) {
            final fileName = entity.uri.pathSegments.last;
            final match = RegExp(r'profile_(\d+)\.jpg').firstMatch(fileName);
            if (match != null) {
              final empId = int.tryParse(match.group(1)!);
              if (empId != null &&
                  !_removedEmployeeIds.contains(empId) &&
                  !newSignatures.containsKey(empId)) {
                final face = await matcher.detectInFile(entity.path);
                if (face != null && matcher.hasUsableLandmarks(face)) {
                  final sig = matcher.signatureOf(face);
                  if (sig.isFrontal) {
                    newSignatures[empId] = sig;
                    if (!newNames.containsKey(empId)) {
                      newNames[empId] =
                          employeeNames[empId] ?? 'Employee $empId';
                    }
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      // Atomically replace the signatures map
      enrolledSignatures.clear();
      enrolledSignatures.addAll(newSignatures);
      employeeNames.clear();
      employeeNames.addAll(newNames);

      await cacheEmployeeCodes();

      _profileVersion = newVersion;
      profilesLoaded = true;
    } catch (_) {
      // Keep whatever we already have; profile refresh is best-effort.
    }
  }

  /// Caches employee/student codes for rich result card display.
  Future<void> cacheEmployeeCodes() async {
    try {
      final emps = await getEmployees();
      for (final e in emps) {
        if (e.employeeId != null) {
          if (e.name != null && e.name!.trim().isNotEmpty) {
            employeeNames[e.employeeId!] = e.name!.trim();
          }
          if (e.code != null && e.code!.trim().isNotEmpty) {
            employeeCodes[e.employeeId!] = e.code!.trim();
          }
        }
      }
    } catch (_) {
      // Best effort
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
      final headers = <String, String>{};
      final token = getStringAsync('token');
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
      final tenantId = getStringAsync('tenant_id');
      if (tenantId.isNotEmpty) headers['X-Tenant-ID'] = tenantId;
      final deviceToken = settings.deviceToken ?? getStringAsync('face_device_token');
      if (deviceToken.isNotEmpty) headers['X-Device-Token'] = deviceToken;
      final deviceUuid = settings.deviceUuid ?? getStringAsync('face_device_uuid');
      if (deviceUuid.isNotEmpty) headers['X-Device-UUID'] = deviceUuid;

      return await downloadToDocuments(
        url,
        fileName,
        headers: headers.isNotEmpty ? headers : null,
      );
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Event upload (check-in / check-out)
  // ---------------------------------------------------------------------------

  /// Uploads a recognition event directly to the server.
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
      return null;
    }
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
