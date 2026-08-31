import 'package:flutter_test/flutter_test.dart';
import 'package:open_core_hr/models/face_attendance/face_dashboard_model.dart';
import 'package:open_core_hr/models/face_attendance/face_settings_model.dart';

/// Verifies the face-attendance admin console models parse the snake_case
/// payloads returned by the backend (ApiResponse snake_cases all keys).
void main() {
  test('FaceDashboardSummary parses snake_case dashboard payload', () {
    final d = FaceDashboardSummary.fromJson({
      'present_employees': 12,
      'absent_employees': 4,
      'late_employees': 2,
      'on_leave_employees': 1,
      'current_workforce': 17,
      'unknown_faces_today': 3,
      'spoof_attempts_today': 0,
      'offline_devices': 1,
    });

    expect(d.presentEmployees, 12);
    expect(d.absentEmployees, 4);
    expect(d.lateEmployees, 2);
    expect(d.onLeaveEmployees, 1);
    expect(d.currentWorkforce, 17);
    expect(d.unknownFacesToday, 3);
    expect(d.spoofAttemptsToday, 0);
    expect(d.offlineDevices, 1);
  });

  test('RecognitionAuditEntry parses snake_case paginator row', () {
    final e = RecognitionAuditEntry.fromJson({
      'event_uuid': 'abc-1',
      'employee_id': '3',
      'employee_name': 'Kanhu Charan Tripathy',
      'device_id': 'dev-1',
      'device_name': 'AC2001',
      'event_type': 'checkin',
      'recognition_status': 'matched',
      'confidence_score': 90.06,
      'occurred_at': '2026-08-31T14:02:57+05:30',
      'snapshot_url': 'https://ttstaffpro.in/storage/x.jpg',
    });

    expect(e.eventUuid, 'abc-1');
    expect(e.employeeId, 3);
    expect(e.employeeName, 'Kanhu Charan Tripathy');
    expect(e.deviceId, 'dev-1');
    expect(e.recognitionStatus, 'matched');
    expect(e.confidenceScore, closeTo(90.06, 0.001));
    expect(e.occurredAt, '2026-08-31T14:02:57+05:30');
  });

  test('DeviceHealthStatus parses snake_case device payload', () {
    final d = DeviceHealthStatus.fromJson({
      'device_id': 'dev-9',
      'device_name': 'AC2001',
      'status': 'active',
      'battery_level': 87,
      'network_state': 'online',
      'storage_state': 'ok',
      'last_heartbeat_at': '2026-08-31T13:00:00+05:30',
    });

    expect(d.deviceId, 'dev-9');
    expect(d.deviceName, 'AC2001');
    expect(d.status, 'active');
    expect(d.batteryLevel, 87);
    expect(d.networkState, 'online');
  });

  test('FaceModuleSettings parses snake_case settings payload', () {
    final s = FaceModuleSettings.fromJson({
      'default_threshold': 92,
      'min_threshold': 82,
      'max_threshold': 99,
      'require_liveness': true,
      'allow_self_registration': true,
      'self_registration_requires_approval': false,
      'snapshot_retention_days': 45,
      'attendance_modes': ['attendance'],
    });

    expect(s.defaultThreshold, 92);
    expect(s.minThreshold, 82);
    expect(s.selfRegistrationRequiresApproval, isFalse);
    expect(s.snapshotRetentionDays, 45);
    expect(s.attendanceModes, ['attendance']);
  });
}
