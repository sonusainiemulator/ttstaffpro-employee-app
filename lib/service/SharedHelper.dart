import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_unique_id/flutter_device_unique_id_platform_interface.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/network_utils.dart';
import 'package:open_core_hr/models/OnBoarding/my_onboarding_screen.dart';
import 'package:open_core_hr/models/Settings/app_settings_model.dart';
import 'package:open_core_hr/screens/Login/LoginScreen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vibration/vibration.dart';

import '../main.dart';
import '../screens/Permission/permissions_screen.dart';
import '../screens/org_choose_screen.dart';
import '../utils/app_constants.dart';

class SharedHelper {
  void vibrate() async {
    var result = await Vibration.hasVibrator();
    if (result ?? false) {
      Vibration.vibrate();
    }
  }

  Future<String> setAppVersionToPref() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    var versionString = '$version build($buildNumber)';
    setValue(appVersionPref, versionString);
    return versionString;
  }

  String getFullName() {
    return '${getStringAsync(firstNamePref)} ${getStringAsync(lastNamePref)}';
  }

  String getPhoneNumber() {
    return getStringAsync(phoneNumberPref);
  }

  String getProfileImage() {
    return getStringAsync(avatarPref);
  }

  String getDesignation() {
    var designation = getStringAsync(designationPref);
    return designation == '' ? 'N/A' : designation;
  }

  bool hasProfileImage() {
    return getStringAsync(avatarPref) != '';
  }

  String getEmployeeCode() {
    var code = getStringAsync(employeeCodePref);
    return code == '' ? 'N/A' : code;
  }

  String getEmail() {
    return getStringAsync(emailPref);
  }

  String getCompanyAddress() {
    return getStringAsync(appCompanyAddressPref);
  }

  String getCompanyName() {
    return getStringAsync(appCompanyNamePref);
  }

  bool isLoggingOut = false;
  
  void logout(BuildContext context) async {
    log('SharedHelper: logout called.');
    if (isLoggingOut) {
      log('SharedHelper: logout already in progress, skipping redundant trigger.');
      return;
    }
    isLoggingOut = true;
    
    // Preserve SaaS mode before clearing preferences
    final wasSaaSMode = getIsSaaSMode();
    log('SharedHelper: wasSaaSMode during logout = $wasSaaSMode');

    await clearSharedPref();
    
    isLoggingOut = false;
    log('SharedHelper: Navigating to ${wasSaaSMode ? 'OrgChooseScreen' : 'LoginScreen'}');
    if (wasSaaSMode) {
      const OrgChooseScreen().launch(context, isNewTask: true);
    } else {
      const LoginScreen().launch(context, isNewTask: true);
    }
    
    toast('Logged out successfully');
  }

  void logoutAlt() async {
    log('SharedHelper: logoutAlt called.');
    if (isLoggingOut) {
      log('SharedHelper: logoutAlt already in progress, skipping redundant trigger.');
      return;
    }
    isLoggingOut = true;
    
    final wasSaaSMode = getIsSaaSMode();
    log('SharedHelper: wasSaaSMode during logoutAlt = $wasSaaSMode');
    
    // Clear preferences but capture what we need first
    await clearSharedPref();
    
    // Re-set initial states if needed
    await setValue(isLoggedInPref, false);
    
    if (navigatorKey.currentState != null) {
      log('SharedHelper: Navigating to ${wasSaaSMode ? 'OrgChooseScreen' : 'LoginScreen'}');
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => wasSaaSMode ? const OrgChooseScreen() : const LoginScreen(),
        ),
        (route) => false,
      );
    } else {
      log('SharedHelper: navigatorKey.currentState is NULL, cannot navigate via navigatorKey.');
    }
    
    isLoggingOut = false;
    toast('Session expired. Please login again.');
  }

  Future<String?> getDeviceId() async {
    String? uuid;
    try {
      uuid = await FlutterDevicePlatform.instance.getUniqueId();
    } catch (e) {
      uuid = null;
    }

    return uuid;
  }

  // Device validation removed - only needed for Field Sales app

  Future<void> setAppSettings(AppSettingsModel settings) async {
    // SaaS Mode - await to ensure it's set before any API calls
    await setValue(isSaaSModePref, settings.isSaaSMode ?? false);

    // Demo Mode - await to ensure it's set before any API calls
    await setValue(isDemoModePref, settings.isDemoMode ?? false);

    // Store server base URL for socket service and other uses
    // Derived from central API URL
    await setValue('serverBaseUrl', getServerBaseUrl());

    // App Settings
    setValue(privacyPolicyUrlPref, settings.privacyPolicyUrl);
    setValue(appCurrencyPref, settings.currency);
    setValue(appCurrencySymbolPref, settings.currencySymbol);
    setValue(appDistanceUnitPref, settings.distanceUnit);
    setValue(appCountryPhoneCodePref, settings.countryPhoneCode);

    // Support Settings
    setValue(appSupportEmailPref, settings.supportEmail);
    setValue(appSupportPhonePref, settings.supportPhone);
    setValue(appSupportWhatsAppPref, settings.supportWhatsapp);
    setValue(appWebsiteUrlPref, settings.website);

    // Company Settings
    setValue(appCompanyNamePref, settings.companyName);
    setValue(appCompanyLogoPref, settings.companyLogo);
    setValue(appCompanyAddressPref, settings.companyAddress);
    setValue(appCompanyPhonePref, settings.companyPhone);
    setValue(appCompanyEmailPref, settings.companyEmail);
    setValue(appCompanyWebsitePref, settings.companyWebsite);
    setValue(appCompanyCountryPref, settings.companyCountry);
    setValue(appCompanyStatePref, settings.companyState);
  }

  bool isSettingsRefreshed() {
    return getBoolAsync(isSettingsRefreshedPref);
  }

  String getUserInitials() {
    String firstName = getStringAsync(firstNamePref);
    String lastName = getStringAsync(lastNamePref);
    String initials = '';
    if (firstName.isNotEmpty) {
      initials += firstName.substring(0, 1).toUpperCase();
    }
    if (lastName.isNotEmpty) {
      initials += lastName.substring(0, 1).toUpperCase();
    }
    if (initials.isEmpty) {
      initials = '?';
    }
    return initials;
  }

  Future refreshAppSettings({
    bool refreshUser = true,
    bool logoutOnUnauthorized = true,
  }) async {
    var appSettings = await apiService.getAppSettings();
    if (appSettings != null) {
      await setAppSettings(appSettings);
      setValue(isSettingsRefreshedPref, true);
    }
    if (refreshUser && getBoolAsync(isLoggedInPref)) {
      await refreshUserData(logoutOnUnauthorized: logoutOnUnauthorized);
    }
  }

  Future refreshUserData({bool logoutOnUnauthorized = true}) async {
    var user = await apiService.me(
      logoutOnUnauthorized: logoutOnUnauthorized,
    );
    if (user != null) {
      await setValue(firstNamePref, user.firstName);
      await setValue(lastNamePref, user.lastName);
      await setValue(genderPref, user.gender);
      if (!user.avatar.isEmptyOrNull) {
        await setValue(avatarPref, user.avatar ?? '');
      }
      await setValue(locationActivityTrackingEnabledPref,
          user.locationActivityTrackingEnabled);
      await setValue(employeeCodePref, user.employeeCode);
      await setValue(approverPref, user.isApprover);
      await setValue(addressPref, user.address);
      await setValue(phoneNumberPref, user.phoneNumber);
      await setValue(alternateNumberPref, user.alternateNumber);
      await setValue(statusPref, user.status);
      await setValue(emailPref, user.email);
      await setValue(designationPref, user.designation);
    }
  }

  Future<void> routeBasedOnStatus(BuildContext context, String status) async {
    // Ensure app settings are refreshed before routing
    await refreshAppSettings(refreshUser: false);

    if (!context.mounted) return;

    if (status.toLowerCase() == 'onboarding') {
      toast('Please complete the onboarding process');
      const MyOnboardingScreen().launch(context, isNewTask: true);
      return;
    } else if (status.toLowerCase() == 'active') {
      // Skip device verification for Employee App - go directly to permissions
      const PermissionScreen().launch(context, isNewTask: true);
    } else {
      toast('Unknown status. Please contact your administrator.');
    }
  }

  bool isAccountActive() {
    var status = getStringAsync(statusPref);
    return status.toLowerCase() == 'active';
  }

  bool isAccountOnboarding() {
    var status = getStringAsync(statusPref);
    return status.toLowerCase() == 'onboarding';
  }

  void login() async {
    addFirebaseToken();
  }

  void addFirebaseToken() {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    messaging
        .getToken()
        .then((value) => apiService.addFirebaseToken(platformName(), value!));
    messaging.subscribeToTopic('announcement');
    messaging.subscribeToTopic('chat');
    messaging.subscribeToTopic('attendance');
    messaging.subscribeToTopic('general');

    setValue(notiAnnouncementPref, true);
    setValue(notiAttendancePref, true);
    setValue(notiGeneralPref, true);
  }
}
