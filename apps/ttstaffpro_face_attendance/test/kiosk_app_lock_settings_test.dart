// Verifies app-lock persistence in KioskSettings (enable flag + method).

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ttstaffpro_face_attendance/kiosk/kiosk_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('app lock defaults to disabled with phoneLock method', () async {
    final settings = KioskSettings();
    await settings.load();
    expect(settings.appLockEnabled, isFalse);
    expect(settings.appLockMethod, AppLockMethod.phoneLock);
  });

  test('setAppLock persists enabled flag and method across reload', () async {
    final settings = KioskSettings();
    await settings.load();

    await settings.setAppLock(enabled: true, method: AppLockMethod.biometric);
    expect(settings.appLockEnabled, isTrue);
    expect(settings.appLockMethod, AppLockMethod.biometric);

    final reloaded = KioskSettings();
    await reloaded.load();
    expect(reloaded.appLockEnabled, isTrue);
    expect(reloaded.appLockMethod, AppLockMethod.biometric);
  });

  test('resetAll clears the app lock preference', () async {
    final settings = KioskSettings();
    await settings.load();
    await settings.setAppLock(enabled: true, method: AppLockMethod.biometric);

    await settings.resetAll();
    expect(settings.appLockEnabled, isFalse);
    expect(settings.appLockMethod, AppLockMethod.phoneLock);
  });
}
