import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../Utils/app_constants.dart';
import '../../utils/design_system.dart';
import '../../main.dart';
import '../Login/LoginScreen.dart';
import 'package:open_core_hr/api/api_routes.dart';
import '../navigation_screen.dart';

class SettingUpScreen extends StatefulWidget {
  const SettingUpScreen({super.key});

  @override
  State<SettingUpScreen> createState() => _SettingUpScreenState();
}

class _SettingUpScreenState extends State<SettingUpScreen> {
  bool isDeviceVerified = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await sharedHelper.setAppVersionToPref();

    // Check if baseURL is still placeholder
    if (APIRoutes.baseURL.contains('{your_website_url}')) {
      log('baseURL is still placeholder, skipping settings refresh');
    } else {
      await sharedHelper.refreshAppSettings();
      await moduleService.refreshModuleSettings();
    }

    await checkDeviceByUid();

    if (getBoolAsync(isLoggedInPref)) {
      if (!mounted) return;

      // Go to main app - permission check handled in NavigationScreen
      const NavigationScreen().launch(context, isNewTask: true);
    } else {
      if (!mounted) return;
      LoginScreen(
        isDeviceVerified: isDeviceVerified,
      ).launch(context, isNewTask: true);
    }
  }

  Future checkDeviceByUid() async {
    if (!moduleService.isUidLoginModuleEnabled()) return;
    try {
      var deviceId = await sharedHelper.getDeviceId();
      if (!deviceId.isEmptyOrNull) {
        isDeviceVerified = await apiService.checkDeviceUid(deviceId!);
      }
    } catch (e) {
      log('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Observer(
        builder: (_) {
          return Container(
            decoration: BoxDecoration(
              color: appStore.isDarkModeOn ? AppDesignSystem.neutral900 : AppDesignSystem.backgroundColor,
            ),
            child: Stack(
              children: [
                // Ornaments
                if (!appStore.isDarkModeOn)
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppDesignSystem.primaryColor.withOpacity(0.05),
                      ),
                    ),
                  ),

                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            language.lblSettingUp,
            style: boldTextStyle(
              size: 20,
              color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: appStore.isDarkModeOn ? AppDesignSystem.neutral800 : white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: AppDesignSystem.shadowMedium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppDesignSystem.primaryColor.withOpacity(0.05),
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.easeInOut),
                SizedBox(
                  height: 140,
                  child: Lottie.asset(
                    'assets/animations/system-setting.json',
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            32.height,
            Text(
              '${language.lblSettingThingsUpPleaseWait}...',
              style: boldTextStyle(
                size: 20,
                color: appStore.isDarkModeOn ? white : AppDesignSystem.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            12.height,
            Text(
              '${language.lblThisWillOnlyTakeAFewSeconds}.',
              style: secondaryTextStyle(
                size: 14,
                color: AppDesignSystem.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            40.height,
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryColor),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildLoadingCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Lottie Animation with purple gradient background
            Stack(
              alignment: Alignment.center,
              children: [
                // Purple gradient circular background
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF696CFF).withOpacity(0.2),
                        const Color(0xFF5457E6).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Lottie Animation
                SizedBox(
                  height: 200,
                  child: Lottie.asset(
                    'assets/animations/system-setting.json',
                    repeat: false,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Status Text
            Text(
              '${language.lblSettingThingsUpPleaseWait}...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${language.lblThisWillOnlyTakeAFewSeconds}.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Purple Circular Progress Indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? const Color(0xFF696CFF) : const Color(0xFF5457E6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
