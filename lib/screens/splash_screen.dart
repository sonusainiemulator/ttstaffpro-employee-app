import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:open_core_hr/models/OnBoarding/my_onboarding_screen.dart';
import 'package:open_core_hr/screens/Permission/permissions_screen.dart';
import 'package:open_core_hr/screens/OfflineMode/offline_mode_screen.dart';
import 'package:open_core_hr/screens/SettingUp/setting_up_screen.dart';
import 'package:open_core_hr/screens/navigation_screen.dart';
import 'package:open_core_hr/screens/server_unreachable_screen.dart';
import 'package:open_core_hr/utils/app_images.dart';
import 'package:open_core_hr/utils/app_widgets.dart';

import '../main.dart';
import '../utils/app_constants.dart';
import 'package:open_core_hr/api/api_routes.dart';
import 'org_choose_screen.dart';

class SplashScreen extends StatefulWidget {
  static String tag = '/SplashScreen';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());

      bool isAnyConnection = connectivityResult.any((element) =>
          element == ConnectivityResult.mobile ||
          element == ConnectivityResult.wifi);

      if (isAnyConnection) {
        print('SplashScreen: baseURL is "${APIRoutes.baseURL}"');
        // Check if baseURL is still placeholder
        if (APIRoutes.baseURL.contains('{your_website_url}')) {
          print('SplashScreen: baseURL is placeholder, skipping settings refresh');
        } else {
          // Fetch app settings first to get SaaS mode status
          try {
            await sharedHelper.refreshAppSettings();
          } catch (e) {
            log('Error fetching app settings: $e');
            // Continue with cached/default values
          }
        }
        if (getBoolAsync(isLoggedInPref)) {
          // Validate tenant exists for SaaS mode
          if (getIsSaaSMode()) {
            String tenantId = getStringAsync(tenantPref);
            if (tenantId.isEmpty) {
              // No tenant selected, go to org selection
              if (mounted) const OrgChooseScreen().launch(context, isNewTask: true);
              return;
            }
          }

          await moduleService.refreshModuleSettings();

          FirebaseCrashlytics.instance.setUserIdentifier(
            getStringAsync(
              sharedHelper.getEmail(),
            ),
          );

          if (!mounted) return;

          // Check if user needs to complete onboarding
          if (sharedHelper.isAccountOnboarding()) {
            toast('Please complete the onboarding process');
            MyOnboardingScreen().launch(context, isNewTask: true);
            return;
          }

          // Go to main app - permission check handled in NavigationScreen
          const NavigationScreen().launch(context, isNewTask: true);
        } else {
          if (!mounted) return;
          if (getIsSaaSMode()) {
            const OrgChooseScreen().launch(context, isNewTask: true);
          } else {
            const SettingUpScreen().launch(context, isNewTask: true);
          }
        }
      } else {
        if (!mounted) return;
        const OfflineModeScreen().launch(context, isNewTask: true);
      }
    } catch (e) {
      log('Exception at splash screen: $e');
      if (!mounted) return;
      if (getBoolAsync(isLoggedInPref) && getBoolAsync(isTrackingOnPref)) {
        const OfflineModeScreen().launch(context, isNewTask: true);
      } else {
        //Logout user if token is expired
        if (e.toString().contains('Please login again')) {
          log('Token expired');
          if (getIsSaaSMode()) {
            sharedHelper.logoutAlt();
            if (!mounted) return;
            const OrgChooseScreen().launch(context, isNewTask: true);
          } else {
            sharedHelper.logoutAlt();
            if (!mounted) return;
            const SettingUpScreen().launch(context, isNewTask: true);
          }
        } else {
          const ServerUnreachableScreen().launch(context, isNewTask: true);
        }
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appStore.isDarkModeOn;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                : [const Color(0xFF696CFF), const Color(0xFF8B7EFF)], // Premium Primary Gradient
          ),
        ),
        child: Stack(
          children: [
            // Background blur or patterns could be added here
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  // Logo Section
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with glassmorphism container
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              appLogoWhiteImg,
                              height: 110,
                              width: 110,
                            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                             .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut),
                          ),
                          const SizedBox(height: 40),
                          // App Name
                          Text(
                            mainAppName,
                            style: boldTextStyle(
                              size: 32,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
                          const SizedBox(height: 12),
                          // Tagline
                          Text(
                            'AI Powered Enterprise Suite',
                            style: secondaryTextStyle(
                              size: 16,
                              color: Colors.white.withOpacity(0.9),
                              weight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
                          const SizedBox(height: 60),
                          // Premium Loading Indicator
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ),
                  ),
                  // Footer Credits
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      children: [
                        Text(
                          "POWERED BY",
                          style: secondaryTextStyle(
                            size: 10,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 2,
                          ),
                        ),
                        8.height,
                        FooterSignature(
                          textColor: Colors.white.withOpacity(0.9),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1000.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
