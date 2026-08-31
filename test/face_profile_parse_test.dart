import 'package:flutter_test/flutter_test.dart';
import 'package:open_core_hr/models/face_attendance/face_profile_model.dart';

/// Verifies the kiosk profile-package parser handles the actual snake_case
/// payload returned by the backend (ApiResponse snake_cases all keys).
void main() {
  // Exact shape returned by GET face-attendance/device/profile-package/download
  // (after the ApiResponse snake_case transform).
  final snakeCaseProfile = {
    'id': 1,
    'employee_id': 1,
    'user_id': 1,
    'employee_name': 'Admin User',
    'registration_mode': 'self',
    'enrollment_version': 1,
    'embedding_driver': 'pending',
    'embedding_payload': null,
    'embedding_hash': null,
    'updated_at': '2026-08-29T22:16:54+05:30',
    'images': [
      {
        'id': 1,
        'capture_type': 'front',
        'file_path': 'face-attendance/profiles/1/57kh7gT49gBRgAt5dWJ91ixgEaDuD58ozpcnUu4Y.jpg',
        'image_url': 'https://ttstaffpro.in/storage/face-attendance/profiles/1/57kh7gT49gBRgAt5dWJ91ixgEaDuD58ozpcnUu4Y.jpg',
        'quality_score': null,
        'is_primary': true,
      },
      {
        'id': 2,
        'capture_type': 'left',
        'file_path': 'face-attendance/profiles/1/qqg348JHWYNfT9117cBwT6Exctyb7CeA9Ft11zEd.jpg',
        'image_url': 'https://ttstaffpro.in/storage/face-attendance/profiles/1/qqg348JHWYNfT9117cBwT6Exctyb7CeA9Ft11zEd.jpg',
        'quality_score': null,
        'is_primary': false,
      },
      {
        'id': 3,
        'capture_type': 'right',
        'file_path': 'face-attendance/profiles/1/cH05HYKBWRxaKNeJZBn2RlTmgkOKSpI9AcpgUl7D.jpg',
        'image_url': 'https://ttstaffpro.in/storage/face-attendance/profiles/1/cH05HYKBWRxaKNeJZBn2RlTmgkOKSpI9AcpgUl7D.jpg',
        'quality_score': null,
        'is_primary': false,
      },
    ],
  };

  test('FaceProfileDetail parses snake_case profile-package payload', () {
    final profile = FaceProfileDetail.fromJson(snakeCaseProfile);

    expect(profile.employeeId, 1);
    expect(profile.employeeName, 'Admin User');
    expect(profile.registrationMode, 'self');
    expect(profile.enrollmentVersion, '1');
    expect(profile.images, isNotNull);
    expect(profile.images!.length, 3);
  });

  test('FaceEnrollmentImageMetadata parses snake_case image entries', () {
    final images = (snakeCaseProfile['images'] as List);
    final image = FaceEnrollmentImageMetadata.fromJson(
      images[0] as Map<String, dynamic>,
    );

    expect(image.captureType, 'front');
    expect(image.filePath, 'face-attendance/profiles/1/57kh7gT49gBRgAt5dWJ91ixgEaDuD58ozpcnUu4Y.jpg');
    expect(
      image.imageUrl,
      'https://ttstaffpro.in/storage/face-attendance/profiles/1/57kh7gT49gBRgAt5dWJ91ixgEaDuD58ozpcnUu4Y.jpg',
    );
  });

  test('FaceProfileDetail still parses camelCase payloads', () {
    final camelProfile = {
      'id': 2,
      'employeeId': 2,
      'employeeName': 'HR User',
      'registrationMode': 'admin',
      'enrollmentVersion': 1,
      'images': [
        {'imageUrl': 'https://x/storage/1.jpg', 'captureType': 'front'},
      ],
    };

    final profile = FaceProfileDetail.fromJson(camelProfile);
    expect(profile.employeeId, 2);
    expect(profile.employeeName, 'HR User');
    expect(profile.images!.first.imageUrl, 'https://x/storage/1.jpg');
    expect(profile.images!.first.captureType, 'front');
  });

  test('FaceProfileSummary parses snake_case admin-profiles payload', () {
    final summary = FaceProfileSummary.fromJson({
      'id': 5,
      'employee_id': '3',
      'employee_name': 'Kanhu Charan Tripathy',
      'registration_mode': 'kiosk',
      'status': 'active',
      'approval_status': 'approved',
      'enrollment_version': 1,
    });

    expect(summary.employeeId, 3);
    expect(summary.employeeName, 'Kanhu Charan Tripathy');
    expect(summary.approvalStatus, 'approved');
    expect(summary.status, 'active');
  });
}
