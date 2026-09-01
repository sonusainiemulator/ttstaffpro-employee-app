import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'kiosk_settings.dart';

/// Thin wrapper around the device's NATIVE lock via the `local_auth` plugin.
///
/// Nothing is stored inside the kiosk — the phone's own security settings
/// (fingerprint / face / pattern / PIN) decide how the app is unlocked. This is
/// the "use the lock I already set up on my phone" behaviour.
class AppLockService {
  AppLockService._();

  /// Shared instance used across the kiosk screens.
  static final AppLockService instance = AppLockService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device has ANY biometrics enrolled (fingerprint / face).
  Future<bool> get hasBiometrics async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Whether the phone supports the native auth prompt at all (it has a lock
  /// set up: biometrics OR pattern/PIN/password).
  Future<bool> get isSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// The biometrics actually enrolled on this phone (shown in settings).
  Future<List<BiometricType>> get enrolledBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return <BiometricType>[];
    }
  }

  /// True if the chosen [method] can actually be used on this device.
  Future<bool> canUseLock(AppLockMethod method) async {
    final biometrics = await hasBiometrics;
    if (method == AppLockMethod.biometric) return biometrics;
    // phoneLock: any native lock works (biometric or pattern/PIN/password).
    return biometrics || await isSupported;
  }

  /// Prompts the phone's native unlock dialog.
  ///
  /// Returns true only when the user successfully authenticates. [method]
  /// controls whether the prompt is restricted to biometrics or may fall back
  /// to the device credential (pattern / PIN / password).
  Future<bool> authenticate({
    required String reason,
    AppLockMethod method = AppLockMethod.phoneLock,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          // phoneLock keeps the native fallback to pattern/PIN/password;
          // biometric-only restricts to fingerprint / face.
          biometricOnly: method == AppLockMethod.biometric,
          // Re-show the prompt instead of failing if the dialog was obscured.
          stickyAuth: true,
          // Let the OS show its own "use pattern / PIN" fallback UI.
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      // local_auth 2.x surfaces failures as PlatformException with codes like
      // NotEnrolled / NotAvailable / LockedOut / UserCanceled.
      debugPrint('AppLock auth failed: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('AppLock auth error: $e');
      return false;
    }
  }
}
