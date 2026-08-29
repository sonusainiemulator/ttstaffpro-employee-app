// Basic smoke tests for the TTStaffPro Face Attendance kiosk app.

import 'package:flutter_test/flutter_test.dart';

import 'package:ttstaffpro_face_attendance/kiosk/kiosk_settings.dart';
import 'package:ttstaffpro_face_attendance/main.dart';

void main() {
  test('kiosk app entrypoint builds', () {
    expect(const KioskApp(), isNotNull);
  });

  test('kiosk settings starts empty', () {
    final settings = KioskSettings();
    expect(settings.isCompanyLoggedIn, isFalse);
    expect(settings.isDeviceRegistered, isFalse);
  });
}
