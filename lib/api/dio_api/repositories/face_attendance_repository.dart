import 'package:dio/dio.dart';
import '../../../models/face_attendance/face_profile_model.dart';
import '../../../models/face_attendance/face_eligibility_model.dart';
import '../../../models/face_attendance/face_device_model.dart';
import '../../../models/face_attendance/face_event_model.dart';
import '../../../models/face_attendance/face_dashboard_model.dart';
import '../../../models/face_attendance/face_settings_model.dart';
import '../../../models/face_attendance/kiosk_model.dart';
import '../../api_routes.dart';
import '../base_repository.dart';

class FaceAttendanceRepository extends BaseRepository {
  static final FaceAttendanceRepository _instance = FaceAttendanceRepository._internal();
  factory FaceAttendanceRepository() => _instance;
  FaceAttendanceRepository._internal();

  // ==========================================
  // 2) Admin Enrollment APIs
  // ==========================================

  /// List employee face profiles
  Future<List<FaceProfileSummary>> getAdminProfiles({
    String? search,
    String? status,
    String? approvalStatus,
    int? branchId,
    int? departmentId,
    int? page,
    int? perPage,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (search != null) queryParameters['search'] = search;
    if (status != null) queryParameters['status'] = status;
    if (approvalStatus != null) queryParameters['approvalStatus'] = approvalStatus;
    if (branchId != null) queryParameters['branchId'] = branchId;
    if (departmentId != null) queryParameters['departmentId'] = departmentId;
    if (page != null) queryParameters['page'] = page;
    if (perPage != null) queryParameters['perPage'] = perPage;

    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminProfiles, queryParameters: queryParameters),
      parser: (data) {
        // The endpoint may return a `{ profiles: [...] }` body or a Laravel
        // paginator `{ data: [...] }`. Unwrap whichever shape is present so
        // profile rows are never dropped by a cast error.
        final dataMap = data as Map<String, dynamic>;
        final payload = dataMap['data'];
        List<dynamic> list;
        if (payload is List) {
          list = payload;
        } else if (payload is Map) {
          final items =
              payload['profiles'] ?? payload['data'] ?? payload['items'];
          list = items is List ? items : const [];
        } else {
          list = const [];
        }
        return list
            .map((e) => FaceProfileSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      showError: true,
    );
  }

  /// Get employee face profile by ID
  Future<FaceProfileDetail> getAdminProfileDetail(int profileId) async {
    final path = '${APIRoutes.adminProfiles}/$profileId';
    return await safeApiCall(
      () => dioClient.get(path),
      parser: (data) {
        final details = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return FaceProfileDetail.fromJson(details);
      },
      showError: true,
    );
  }

  /// Create face profile from admin panel (multipart upload)
  Future<bool> createAdminProfile({
    required int employeeId,
    required List<String> imagePaths,
    required List<String> captureTypes,
    String? notes,
    bool? requireApproval,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('employeeId', employeeId.toString()));
    formData.fields.add(const MapEntry('registrationMode', 'admin'));
    if (notes != null) formData.fields.add(MapEntry('notes', notes));
    if (requireApproval != null) {
      formData.fields.add(MapEntry('requireApproval', requireApproval.toString()));
    }

    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images[]',
        await MultipartFile.fromFile(path),
      ));
    }

    for (final type in captureTypes) {
      formData.fields.add(MapEntry('captureTypes[]', type));
    }

    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.adminProfiles,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Update or re-enroll face profile (multipart upload)
  Future<bool> reEnrollAdminProfile({
    required int profileId,
    required List<String> imagePaths,
    String? notes,
    bool deactivatePreviousVersion = true,
  }) async {
    final path = '${APIRoutes.adminProfiles}/$profileId/re-enroll';
    final formData = FormData();
    if (notes != null) formData.fields.add(MapEntry('notes', notes));
    formData.fields.add(MapEntry('deactivatePreviousVersion', deactivatePreviousVersion.toString()));

    for (final imagePath in imagePaths) {
      formData.files.add(MapEntry(
        'images[]',
        await MultipartFile.fromFile(imagePath),
      ));
    }

    return await safeApiCall(
      () => dioClient.post(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Approve face profile
  Future<bool> approveProfile(int profileId, {required String remarks}) async {
    final path = '${APIRoutes.adminProfiles}/$profileId/approve';
    return await safeApiCall(
      () => dioClient.post(path, data: {'remarks': remarks}),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Reject face profile
  Future<bool> rejectProfile(int profileId, {required String remarks}) async {
    final path = '${APIRoutes.adminProfiles}/$profileId/reject';
    return await safeApiCall(
      () => dioClient.post(path, data: {'remarks': remarks}),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Reset employee face registration
  Future<bool> resetProfile(int profileId) async {
    final path = '${APIRoutes.adminProfiles}/$profileId/reset';
    return await safeApiCall(
      () => dioClient.post(path, data: {}),
      parser: (data) => true,
      showError: true,
    );
  }

  // ==========================================
  // 3) Self Registration APIs
  // ==========================================

  /// Check self-registration eligibility
  Future<FaceEligibility> checkSelfEligibility() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.selfEligibility),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return FaceEligibility.fromJson(body);
      },
      showError: true,
    );
  }

  /// Submit self face registration (multipart upload)
  Future<bool> submitSelfRegistration({
    required List<String> imagePaths,
    required List<String> captureTypes,
    String? notes,
  }) async {
    final formData = FormData();
    if (notes != null) formData.fields.add(MapEntry('notes', notes));

    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images[]',
        await MultipartFile.fromFile(path),
      ));
    }

    for (final type in captureTypes) {
      formData.fields.add(MapEntry('captureTypes[]', type));
    }

    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.selfRegister,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Refresh own face profile (multipart upload)
  Future<bool> refreshSelfProfile({
    required List<String> imagePaths,
    String? notes,
  }) async {
    final formData = FormData();
    if (notes != null) formData.fields.add(MapEntry('notes', notes));

    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images[]',
        await MultipartFile.fromFile(path),
      ));
    }

    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.selfRefresh,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Get own face profile status
  Future<OwnFaceProfileStatus> getSelfProfileStatus() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.selfProfile),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return OwnFaceProfileStatus.fromJson(body);
      },
      showError: true,
    );
  }

  // ==========================================
  // 4) Self Registration Access Management
  // ==========================================

  /// Grant self-registration access
  Future<bool> grantSelfRegistrationAccess({
    required int userId,
    required int employeeId,
    required String remarks,
  }) async {
    final path = '${APIRoutes.adminProfilesSelfReg}/grant';
    return await safeApiCall(
      () => dioClient.post(
        path,
        data: {
          'userId': userId,
          'employeeId': employeeId,
          'remarks': remarks,
        },
      ),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Revoke self-registration access
  Future<bool> revokeSelfRegistrationAccess({
    required int userId,
    required int employeeId,
    required String remarks,
  }) async {
    final path = '${APIRoutes.adminProfilesSelfReg}/revoke';
    return await safeApiCall(
      () => dioClient.post(
        path,
        data: {
          'userId': userId,
          'employeeId': employeeId,
          'remarks': remarks,
        },
      ),
      parser: (data) => true,
      showError: true,
    );
  }

  /// List self registration access audit logs
  Future<List<dynamic>> getSelfRegistrationAudits({
    int? userId,
    int? employeeId,
    String? status,
    int? page,
  }) async {
    final path = '${APIRoutes.adminProfilesSelfReg}/audits';
    final queryParameters = <String, dynamic>{};
    if (userId != null) queryParameters['userId'] = userId;
    if (employeeId != null) queryParameters['employeeId'] = employeeId;
    if (status != null) queryParameters['status'] = status;
    if (page != null) queryParameters['page'] = page;

    return await safeApiCall(
      () => dioClient.get(path, queryParameters: queryParameters),
      parser: (data) => (data['data'] ?? data) as List,
      showError: true,
    );
  }

  // ==========================================
  // 5) Device Management APIs
  // ==========================================

  /// Register kiosk device
  Future<DeviceRegistrationResult> registerKioskDevice(DeviceRegistrationRequest request) async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.deviceRegister, data: request.toJson()),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return DeviceRegistrationResult.fromJson(body);
      },
      showError: true,
    );
  }

  /// Device heartbeat
  Future<bool> sendDeviceHeartbeat(DeviceHeartbeatBody heartbeat) async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.deviceHeartbeat, data: heartbeat.toJson()),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Get assigned profile package version
  Future<ProfilePackageVersion> getProfilePackageVersion() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.deviceProfilePackage),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return ProfilePackageVersion.fromJson(body);
      },
      showError: true,
    );
  }

  /// Download profile package.
  ///
  /// Server returns `data: { meta: {...}, package: { generated_at, profiles:
  /// [...] } }`. Unwrap `data.package.profiles`; fall back to a bare list for
  /// older/alternate payloads.
  Future<List<FaceProfileDetail>> downloadProfilePackage() async {
    final path = '${APIRoutes.deviceProfilePackage}/download';
    return await safeApiCall(
      () => dioClient.get(path),
      parser: (data) {
        final map = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        final package = (map['package'] as Map<String, dynamic>?) ?? map;
        final list = (package['profiles'] as List?) ?? const [];
        return list
            .map((e) => FaceProfileDetail.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      showError: true,
    );
  }

  /// Revoke device
  Future<bool> revokeDevice(String deviceId) async {
    final path = '${APIRoutes.faceAttendanceBase}/device/$deviceId/revoke';
    return await safeApiCall(
      () => dioClient.post(path, data: {}),
      parser: (data) => true,
      showError: true,
    );
  }

  // ==========================================
  // 6) Recognition and Attendance APIs
  // ==========================================

  /// Upload single recognition event (multipart upload)
  Future<RecognitionUploadResult> uploadRecognitionEvent({
    required String eventUuid,
    required String eventType,
    int? employeeId,
    required String recognitionStatus,
    double? confidenceScore,
    String? livenessStatus,
    String? spoofStatus,
    double? matchThreshold,
    required String occurredAt,
    double? latitude,
    double? longitude,
    String? snapshotPath,
    String? payloadJson,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('eventUuid', eventUuid));
    formData.fields.add(MapEntry('eventType', eventType));
    if (employeeId != null) formData.fields.add(MapEntry('employeeId', employeeId.toString()));
    formData.fields.add(MapEntry('recognitionStatus', recognitionStatus));
    if (confidenceScore != null) formData.fields.add(MapEntry('confidenceScore', confidenceScore.toString()));
    if (livenessStatus != null) formData.fields.add(MapEntry('livenessStatus', livenessStatus));
    if (spoofStatus != null) formData.fields.add(MapEntry('spoofStatus', spoofStatus));
    if (matchThreshold != null) formData.fields.add(MapEntry('matchThreshold', matchThreshold.toString()));
    formData.fields.add(MapEntry('occurredAt', occurredAt));
    if (latitude != null) formData.fields.add(MapEntry('latitude', latitude.toString()));
    if (longitude != null) formData.fields.add(MapEntry('longitude', longitude.toString()));
    if (payloadJson != null) formData.fields.add(MapEntry('payloadJson', payloadJson));

    if (snapshotPath != null) {
      formData.files.add(MapEntry(
        'snapshot',
        await MultipartFile.fromFile(snapshotPath),
      ));
    }

    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.deviceEvents,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) {
        final dataMap = data as Map<String, dynamic>;
        final body = (dataMap['data'] as Map<String, dynamic>?) ?? dataMap;
        // ApiResponse wraps the payload under `data` and keeps the
        // human-readable `message` at the top level — surface it when the
        // event payload itself has no message.
        if (body['message'] == null && dataMap['message'] != null) {
          body['message'] = dataMap['message'];
        }
        return RecognitionUploadResult.fromJson(body);
      },
      showError: true,
    );
  }

  /// Upload offline sync batch
  Future<OfflineSyncBatchResult> uploadOfflineSyncBatch(OfflineSyncBatchRequest request) async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.deviceSyncBatch, data: request.toJson()),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return OfflineSyncBatchResult.fromJson(body);
      },
      showError: true,
    );
  }

  /// Get event ack state
  Future<String> getEventAckState(String eventUuid) async {
    final path = '${APIRoutes.faceAttendanceBase}/device/events/$eventUuid';
    return await safeApiCall(
      () => dioClient.get(path),
      parser: (data) => (data['data']?['status'] ?? data['status'] ?? data).toString(),
      showError: true,
    );
  }

  // ==========================================
  // 7) Dashboard and Audit APIs
  // ==========================================

  /// Get dashboard summary
  Future<FaceDashboardSummary> getDashboardSummary() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminDashboard),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return FaceDashboardSummary.fromJson(body);
      },
      showError: true,
    );
  }

  /// Get recognition audit log
  Future<List<RecognitionAuditEntry>> getRecognitionAuditLog({
    String? date,
    int? employeeId,
    String? deviceId,
    String? recognitionStatus,
    String? eventType,
    int? page,
    int? perPage,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (date != null) queryParameters['date'] = date;
    if (employeeId != null) queryParameters['employeeId'] = employeeId;
    if (deviceId != null) queryParameters['deviceId'] = deviceId;
    if (recognitionStatus != null) queryParameters['recognitionStatus'] = recognitionStatus;
    if (eventType != null) queryParameters['eventType'] = eventType;
    if (page != null) queryParameters['page'] = page;
    if (perPage != null) queryParameters['perPage'] = perPage;

    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminAuditLog, queryParameters: queryParameters),
      parser: (data) {
        final list = (data['data'] ?? data) as List;
        return list.map((e) => RecognitionAuditEntry.fromJson(e as Map<String, dynamic>)).toList();
      },
      showError: true,
    );
  }

  /// Get failed recognitions
  Future<List<FailedRecognitionEntry>> getFailedRecognitions() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminFailedRecognitions),
      parser: (data) {
        final list = (data['data'] ?? data) as List;
        return list.map((e) => FailedRecognitionEntry.fromJson(e as Map<String, dynamic>)).toList();
      },
      showError: true,
    );
  }

  /// Get spoof events
  Future<List<SpoofEventEntry>> getSpoofEvents() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminSpoofEvents),
      parser: (data) {
        final list = (data['data'] ?? data) as List;
        return list.map((e) => SpoofEventEntry.fromJson(e as Map<String, dynamic>)).toList();
      },
      showError: true,
    );
  }

  /// Get device health list
  Future<List<DeviceHealthStatus>> getDevicesHealthList() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminDevicesHealth),
      parser: (data) {
        final list = (data['data'] ?? data) as List;
        return list.map((e) => DeviceHealthStatus.fromJson(e as Map<String, dynamic>)).toList();
      },
      showError: true,
    );
  }

  // ==========================================
  // 8) Configuration APIs
  // ==========================================

  /// Get module settings
  Future<FaceModuleSettings> getSettings() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.adminSettings),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return FaceModuleSettings.fromJson(body);
      },
      showError: true,
    );
  }

  /// Update module settings
  Future<bool> updateSettings(FaceModuleSettings settings) async {
    return await safeApiCall(
      () => dioClient.put(APIRoutes.adminSettings, data: settings.toJson()),
      parser: (data) => true,
      showError: true,
    );
  }

  // ==========================================
  // 9) Kiosk (wall-mounted tablet) APIs
  // ==========================================

  /// Match the company name typed on the kiosk login screen.
  Future<KioskCompanyMatchResult> kioskCompanyMatch(String companyName) async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.kioskCompanyMatch, data: {'companyName': companyName}),
      parser: (data) => KioskCompanyMatchResult.fromJson(data as Map<String, dynamic>),
      showError: true,
    );
  }

  /// Master login for the single-point kiosk tablet.
  Future<KioskLoginResult> kioskLogin({
    required String companyId,
    required String username,
    required String password,
  }) async {
    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.kioskLogin,
        data: {
          'companyId': companyId,
          'username': username,
          'password': password,
        },
      ),
      parser: (data) => KioskLoginResult.fromJson(data as Map<String, dynamic>),
      showError: true,
    );
  }

  /// Exchange a master token + device for a scoped device token.
  Future<String?> kioskDeviceToken({
    required String companyId,
    required String deviceUuid,
  }) async {
    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.kioskDeviceToken,
        data: {
          'companyId': companyId,
          'deviceUuid': deviceUuid,
        },
      ),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ?? data as Map<String, dynamic>;
        return (body['deviceToken'] ?? body['token'])?.toString();
      },
      showError: true,
    );
  }

  /// Fetch the date-wise staff attendance report for the kiosk.
  Future<KioskDailyReport> getKioskDailyReport(String date) async {
    return await safeApiCall(
      () => dioClient.get(
        APIRoutes.kioskReport,
        queryParameters: {'date': date},
      ),
      parser: (data) => KioskDailyReport.fromJson(data as Map<String, dynamic>),
      showError: true,
    );
  }

  /// List the tenant's active employees so the admin can register faces.
  Future<List<KioskEmployee>> kioskEmployees() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.kioskEmployees),
      parser: (data) {
        final body = (data['data'] as Map<String, dynamic>?) ??
            data as Map<String, dynamic>;
        final list = (body['employees'] as List?) ?? const [];
        return list
            .map((e) => KioskEmployee.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      showError: true,
    );
  }

  /// Register a face for an employee directly from the kiosk (multipart).
  Future<bool> kioskEnrollFace({
    required int employeeId,
    required List<String> imagePaths,
    required List<String> captureTypes,
    String? notes,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('employeeId', employeeId.toString()));
    if (notes != null) formData.fields.add(MapEntry('notes', notes));

    for (final path in imagePaths) {
      formData.files.add(MapEntry(
        'images[]',
        await MultipartFile.fromFile(path),
      ));
    }

    for (final type in captureTypes) {
      formData.fields.add(MapEntry('captureTypes[]', type));
    }

    return await safeApiCall(
      () => dioClient.post(
        APIRoutes.kioskEnroll,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => true,
      showError: true,
    );
  }
}
