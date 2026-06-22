import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'package:open_core_hr/models/face_attendance/face_device_model.dart';
import 'package:open_core_hr/models/face_attendance/face_event_model.dart';

// Mock HTTP client adapter to intercept Dio requests
class MockHttpClientAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  // Ensure SharedPreferences is mocked for nb_utils
  Map<String, Object> values = <String, Object>{};
  SharedPreferences.setMockInitialValues(values);

  late FaceAttendanceRepository repository;
  late MockHttpClientAdapter mockAdapter;

  setUpAll(() async {
    // Ensure TestWidgetsFlutterBinding is initialized for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize nb_utils SharedPreferences
    await initialize();
    repository = FaceAttendanceRepository();
    
    // Remove NetworkInterceptor to avoid platform method channel dependency in unit tests
    repository.dioClient.dio.interceptors.removeWhere(
      (element) => element.runtimeType.toString() == 'NetworkInterceptor',
    );

    mockAdapter = MockHttpClientAdapter();
    repository.dioClient.dio.httpClientAdapter = mockAdapter;
  });

  group('FaceAttendanceRepository tests', () {
    test('getAdminProfiles parses list response successfully', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'profiles': [
            {
              'id': 1,
              'employeeId': 101,
              'employeeName': 'John Doe',
              'registrationMode': 'admin',
              'status': 'active',
              'approvalStatus': 'approved',
              'enrollmentVersion': 'v1',
              'lastSyncedAt': '2026-06-22T10:00:00Z',
            }
          ]
        }
      };

      mockAdapter.handler = (options) {
        expect(options.path, contains('face-attendance/admin/profiles'));
        expect(options.method, 'GET');
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final profiles = await repository.getAdminProfiles(search: 'John');
      expect(profiles, isNotEmpty);
      expect(profiles.first.id, 1);
      expect(profiles.first.employeeName, 'John Doe');
      expect(profiles.first.status, 'active');
    });

    test('getAdminProfileDetail parses detailed response successfully', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'id': 2,
          'employeeId': 102,
          'employeeName': 'Jane Smith',
          'registrationMode': 'admin',
          'status': 'active',
          'approvalStatus': 'approved',
          'enrollmentVersion': 'v2',
          'lastSyncedAt': '2026-06-22T11:00:00Z',
          'images': [
            {
              'imageUrl': 'https://example.com/face.jpg',
              'captureType': 'front',
              'qualityScore': 95.5,
            }
          ],
          'auditSummary': [
            {
              'remarks': 'Quality verified',
              'updatedBy': 'Admin',
              'updatedAt': '2026-06-22T12:00:00Z',
            }
          ],
          'assignedDevices': [
            {
              'deviceId': 'device_01',
              'deviceName': 'Main Entrance',
              'status': 'active',
            }
          ]
        }
      };

      mockAdapter.handler = (options) {
        expect(options.path, contains('face-attendance/admin/profiles/2'));
        expect(options.method, 'GET');
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final detail = await repository.getAdminProfileDetail(2);
      expect(detail.id, 2);
      expect(detail.employeeName, 'Jane Smith');
      expect(detail.images, isNotEmpty);
      expect(detail.images!.first.captureType, 'front');
      expect(detail.auditSummary!.first.remarks, 'Quality verified');
      expect(detail.assignedDevices!.first.deviceName, 'Main Entrance');
    });

    test('checkSelfEligibility parses eligibility correctly', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'canRegister': true,
          'employeeId': 154,
          'hasExistingProfile': false,
          'profileStatus': null,
          'requiresApproval': true,
          'registrationWindowOpen': true
        }
      };

      mockAdapter.handler = (options) {
        expect(options.path, contains('face-attendance/self/eligibility'));
        expect(options.method, 'GET');
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final eligibility = await repository.checkSelfEligibility();
      expect(eligibility.canRegister, isTrue);
      expect(eligibility.employeeId, 154);
      expect(eligibility.requiresApproval, isTrue);
    });

    test('registerKioskDevice works successfully', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'deviceId': 'TAB-DELHI-HQ-001',
          'deviceToken': 'tok_xyz123',
          'status': 'active',
          'assignedBranch': 3
        }
      };

      mockAdapter.handler = (options) {
        expect(options.path, contains('face-attendance/device/register'));
        expect(options.method, 'POST');
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final request = DeviceRegistrationRequest(
        deviceUuid: 'TAB-DELHI-HQ-001',
        deviceName: 'Delhi HQ Gate 1',
        deviceType: 'kiosk',
        platform: 'android',
        deviceModel: 'Samsung Galaxy Tab',
        osVersion: '14',
        appVersion: '1.0.0',
        mlRuntime: 'tflite',
        branchId: 3,
      );

      final result = await repository.registerKioskDevice(request);
      expect(result.deviceId, 'TAB-DELHI-HQ-001');
      expect(result.deviceToken, 'tok_xyz123');
      expect(result.assignedBranch, 3);
    });

    test('uploadOfflineSyncBatch parses response items successfully', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'batchUuid': 'batch_20260621_01',
          'recordsTotal': 2,
          'recordsSuccess': 2,
          'recordsFailed': 0,
          'results': [
            {
              'eventUuid': 'evt_001',
              'status': 'accepted',
            },
            {
              'eventUuid': 'evt_002',
              'status': 'accepted',
            }
          ]
        }
      };

      mockAdapter.handler = (options) {
        expect(options.path, contains('face-attendance/device/sync-batch'));
        expect(options.method, 'POST');
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final batchRequest = OfflineSyncBatchRequest(
        batchUuid: 'batch_20260621_01',
        sentAt: '2026-06-21T10:30:00Z',
        events: [
          OfflineSyncEvent(
            eventUuid: 'evt_001',
            eventType: 'checkin',
            employeeId: 154,
            recognitionStatus: 'matched',
            occurredAt: '2026-06-21T09:02:00Z',
          ),
          OfflineSyncEvent(
            eventUuid: 'evt_002',
            eventType: 'unknown',
            recognitionStatus: 'unmatched',
            occurredAt: '2026-06-21T09:05:00Z',
          ),
        ],
      );

      final result = await repository.uploadOfflineSyncBatch(batchRequest);
      expect(result.batchUuid, 'batch_20260621_01');
      expect(result.recordsTotal, 2);
      expect(result.results, isNotEmpty);
      expect(result.results!.first.eventUuid, 'evt_001');
      expect(result.results!.first.status, 'accepted');
    });

    test('getDashboardSummary parses summary successfully', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'presentEmployees': 120,
          'absentEmployees': 15,
          'lateEmployees': 5,
          'onLeaveEmployees': 3,
          'currentWorkforce': 138,
          'unknownFacesToday': 2,
          'spoofAttemptsToday': 0,
          'offlineDevices': 1
        }
      };

      mockAdapter.handler = (options) {
        expect(options.path, contains('face-attendance/admin/dashboard'));
        return ResponseBody.fromString(
          jsonEncode(jsonResponse),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final summary = await repository.getDashboardSummary();
      expect(summary.presentEmployees, 120);
      expect(summary.offlineDevices, 1);
      expect(summary.spoofAttemptsToday, 0);
    });

    test('getSettings and updateSettings parse config settings successfully', () async {
      final jsonResponse = {
        'statusCode': 200,
        'status': 'success',
        'data': {
          'defaultThreshold': 90,
          'minThreshold': 80,
          'maxThreshold': 99,
          'requireLiveness': true,
          'allowSelfRegistration': true,
          'selfRegistrationRequiresApproval': true,
          'snapshotRetentionDays': 30,
          'attendanceModes': ['face_only', 'face_pin']
        }
      };

      mockAdapter.handler = (options) {
        if (options.method == 'GET') {
          expect(options.path, contains('face-attendance/admin/settings'));
          return ResponseBody.fromString(
            jsonEncode(jsonResponse),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        } else {
          expect(options.path, contains('face-attendance/admin/settings'));
          expect(options.method, 'PUT');
          return ResponseBody.fromString(
            jsonEncode({'statusCode': 200, 'status': 'success', 'data': {}}),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
      };

      final settings = await repository.getSettings();
      expect(settings.defaultThreshold, 90);
      expect(settings.requireLiveness, isTrue);
      expect(settings.attendanceModes, contains('face_pin'));

      final updateResult = await repository.updateSettings(settings);
      expect(updateResult, isTrue);
    });

    test('AuthInterceptor injects device UUID and token when available', () async {
      // Set values in mocked SharedPreferences
      await setValue('face_device_uuid', 'uuid-test-999');
      await setValue('face_device_token', 'tok-test-888');

      mockAdapter.handler = (options) {
        expect(options.headers['X-Device-UUID'], 'uuid-test-999');
        expect(options.headers['X-Device-Token'], 'tok-test-888');
        return ResponseBody.fromString(
          jsonEncode({
            'statusCode': 200,
            'status': 'success',
            'data': {
              'canRegister': true,
              'employeeId': 154,
              'hasExistingProfile': false,
              'profileStatus': null,
              'requiresApproval': true,
              'registrationWindowOpen': true
            }
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      // Perform a dummy request
      final eligibility = await repository.checkSelfEligibility();
      expect(eligibility, isNotNull);
    });
  });
}
