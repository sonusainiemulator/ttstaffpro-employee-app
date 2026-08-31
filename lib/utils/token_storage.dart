import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nb_utils/nb_utils.dart';

import 'app_constants.dart';

/// Minimal abstraction over the secure-storage backend so tests can inject an
/// in-memory fake (the plugin's method channel is unavailable in `flutter test`).
abstract class SecureTokenBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Default backend backed by the platform Keystore / Keychain via
/// [FlutterSecureStorage].
class FlutterSecureTokenBackend implements SecureTokenBackend {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Stores the API auth token in platform-secure storage (Android Keystore /
/// iOS Keychain) instead of plaintext SharedPreferences — required for a
/// production HRMS that carries payroll/HR data.
///
/// A synchronous in-memory cache backs the legacy sync read paths
/// (`buildHeader()` / `AuthInterceptor`), so those call sites stay sync. On any
/// secure-storage failure the helper transparently falls back to the old
/// SharedPreferences behaviour, so login can never break.
class TokenStorage {
  TokenStorage._();

  /// Swap in a fake for tests.
  static SecureTokenBackend backend = FlutterSecureTokenBackend();

  static String? _cached;

  /// Synchronous read used by sync header builders (memory first, then the
  /// legacy prefs copy for older installs / fallback).
  static String? get cached {
    if (_cached != null && _cached!.isNotEmpty) return _cached;
    return getStringAsync(tokenPref);
  }

  /// Loads the token into memory and migrates any legacy prefs copy out of
  /// plaintext. Call once at startup, before `runApp`.
  static Future<void> restore() async {
    try {
      final secured = await backend.read(tokenPref);
      if (secured != null && secured.isNotEmpty) {
        _cached = secured;
        // Clean up the legacy plaintext copy now that we have the secure one.
        await removeKey(tokenPref);
        return;
      }
    } catch (_) {
      // Secure storage unavailable — fall through to the prefs copy.
    }
    _cached = getStringAsync(tokenPref);
  }

  /// Persists [token] securely and updates the memory cache. Null-safe: an
  /// empty token is ignored so callers can pass `user.token` directly.
  static Future<void> write(String? token) async {
    if (token == null || token.isEmpty) return;
    _cached = token;
    try {
      await backend.write(tokenPref, token);
      // Never keep the plaintext copy once the secure one exists.
      await removeKey(tokenPref);
    } catch (_) {
      // Secure storage failed — keep the legacy prefs copy so login works.
      await setValue(tokenPref, token);
    }
  }

  /// Removes the token from secure storage, memory and prefs.
  static Future<void> clear() async {
    _cached = null;
    try {
      await backend.delete(tokenPref);
    } catch (_) {}
    await removeKey(tokenPref);
  }

  /// Clears the in-memory cache (used by tests so the static state does not
  /// leak between cases).
  static void resetCacheForTesting() {
    _cached = null;
  }
}
