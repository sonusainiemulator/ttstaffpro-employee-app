import 'package:flutter_test/flutter_test.dart';
import 'package:open_core_hr/models/face_attendance/face_event_model.dart';

/// Verifies the recognition-event result parser handles the actual snake_case
/// payload returned by the backend (ApiResponse snake_cases all keys), so the
/// kiosk can show the real check-in / check-out action.
void main() {
  test('RecognitionUploadResult parses snake_case event payload', () {
    final result = RecognitionUploadResult.fromJson({
      'event_uuid': 'abc-123',
      'attendance_action': 'check_in',
      'attendance_id': 42,
      'message': 'Attendance recorded',
    });

    expect(result.eventUuid, 'abc-123');
    expect(result.attendanceAction, 'check_in');
    expect(result.attendanceId, 42);
    expect(result.message, 'Attendance recorded');
  });

  test('RecognitionUploadResult parses camelCase event payload', () {
    final result = RecognitionUploadResult.fromJson({
      'eventUuid': 'abc-124',
      'attendanceAction': 'check_out',
      'attendanceId': 43,
      'message': 'Check-out recorded',
    });

    expect(result.eventUuid, 'abc-124');
    expect(result.attendanceAction, 'check_out');
    expect(result.attendanceId, 43);
    expect(result.message, 'Check-out recorded');
  });

  test('RecognitionUploadResult tolerates a numeric-string attendance id', () {
    final result = RecognitionUploadResult.fromJson({
      'attendance_action': 'check_in',
      'attendance_id': '99',
    });

    expect(result.attendanceId, 99);
  });

  test('RecognitionUploadResult leaves absent fields null', () {
    final result = RecognitionUploadResult.fromJson(<String, dynamic>{});

    expect(result.eventUuid, isNull);
    expect(result.attendanceAction, isNull);
    expect(result.attendanceId, isNull);
    expect(result.message, isNull);
  });
}
