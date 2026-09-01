import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the kiosk asks the user to unlock, using the phone's OWN native lock
/// (fingerprint / face / pattern / PIN) that is already configured on the
/// device — nothing is stored inside the kiosk.
enum AppLockMethod {
  /// Restrict to biometrics only (fingerprint / Face ID).
  biometric('Biometric (fingerprint / face)'),

  /// Use whatever the phone has set up: pattern / PIN / biometric.
  phoneLock('Phone lock (pattern / PIN / biometric)');

  final String label;
  const AppLockMethod(this.label);
}

/// Persisted settings for the kiosk tablet.
///
/// Stores the matched company, the master session and the registered device
/// identity so that the kiosk can restore its session across restarts
/// (wall-mounted tablet use case).
class KioskSettings {
  static const String _companyId = 'kiosk_company_id';
  static const String _companyName = 'kiosk_company_name';
  static const String _companyLogoUrl = 'kiosk_company_logo_url';
  static const String _tenantId = 'kiosk_tenant_id';
  static const String _masterToken = 'kiosk_master_token';
  static const String _deviceUuid = 'kiosk_device_uuid';
  static const String _deviceToken = 'kiosk_device_token';
  static const String _lastHeartbeatAt = 'kiosk_last_heartbeat_at';
  static const String _themeMode = 'kiosk_theme_mode';
  static const String _appLockEnabled = 'kiosk_app_lock_enabled';
  static const String _appLockMethod = 'kiosk_app_lock_method';

  String? companyId;
  String? companyName;
  String? companyLogoUrl;

  /// The tenant identifier sent as the `X-Tenant-ID` header.
  String? tenantId;
  String? masterToken;
  String? deviceUuid;
  String? deviceToken;
  String? lastHeartbeatAt;

  /// User-selected appearance: dark / light / system (persisted).
  ThemeMode themeMode = ThemeMode.system;

  /// When true, opening / returning to the kiosk asks for the phone's native
  /// unlock (fingerprint / face / pattern / PIN) before showing the app.
  bool appLockEnabled = false;

  /// Which native unlock the kiosk should request (persisted).
  AppLockMethod appLockMethod = AppLockMethod.phoneLock;

  /// True when a company + master session has been established.
  bool get isCompanyLoggedIn => (companyId?.isNotEmpty ?? false) && (masterToken?.isNotEmpty ?? false);

  /// True when the device is registered with the backend.
  bool get isDeviceRegistered =>
      (deviceUuid?.isNotEmpty ?? false) && (deviceToken?.isNotEmpty ?? false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    companyId = prefs.getString(_companyId);
    companyName = prefs.getString(_companyName);
    companyLogoUrl = prefs.getString(_companyLogoUrl);
    tenantId = prefs.getString(_tenantId);
    masterToken = prefs.getString(_masterToken);
    deviceUuid = prefs.getString(_deviceUuid);
    deviceToken = prefs.getString(_deviceToken);
    lastHeartbeatAt = prefs.getString(_lastHeartbeatAt);
    themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == prefs.getString(_themeMode),
      orElse: () => ThemeMode.system,
    );
    appLockEnabled = prefs.getBool(_appLockEnabled) ?? false;
    appLockMethod = AppLockMethod.values.firstWhere(
      (m) => m.name == prefs.getString(_appLockMethod),
      orElse: () => AppLockMethod.phoneLock,
    );
  }

  /// Persists the user's chosen appearance (dark / light / system).
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeMode, mode.name);
  }

  /// Persists the app-lock preference (enabled flag + unlock method).
  Future<void> setAppLock({
    required bool enabled,
    required AppLockMethod method,
  }) async {
    appLockEnabled = enabled;
    appLockMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockEnabled, enabled);
    await prefs.setString(_appLockMethod, method.name);
  }

  Future<void> saveCompany({
    required String id,
    required String name,
    String? logoUrl,
    String? tenantId,
  }) async {
    companyId = id;
    companyName = name;
    companyLogoUrl = logoUrl;
    this.tenantId = tenantId ?? id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyId, id);
    await prefs.setString(_companyName, name);
    await prefs.setString(_tenantId, this.tenantId!);
    if (logoUrl != null) await prefs.setString(_companyLogoUrl, logoUrl);
  }

  Future<void> saveMasterSession(String token) async {
    masterToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_masterToken, token);
  }

  Future<void> saveDevice({
    required String uuid,
    required String token,
  }) async {
    deviceUuid = uuid;
    deviceToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceUuid, uuid);
    await prefs.setString(_deviceToken, token);
  }

  Future<void> saveHeartbeat(String isoTime) async {
    lastHeartbeatAt = isoTime;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastHeartbeatAt, isoTime);
  }

  /// Clears the master session (logout) but keeps the device identity.
  Future<void> clearSession() async {
    masterToken = null;
    companyId = null;
    companyName = null;
    companyLogoUrl = null;
    tenantId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_masterToken);
    await prefs.remove(_companyId);
    await prefs.remove(_companyName);
    await prefs.remove(_companyLogoUrl);
    await prefs.remove(_tenantId);
  }

  /// Fully resets the kiosk back to the company-login screen.
  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    companyId = null;
    companyName = null;
    companyLogoUrl = null;
    tenantId = null;
    masterToken = null;
    deviceUuid = null;
    deviceToken = null;
    lastHeartbeatAt = null;
    appLockEnabled = false;
    appLockMethod = AppLockMethod.phoneLock;
  }
}
