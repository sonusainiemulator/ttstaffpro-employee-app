import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/screens/ChangePassword/change_password_screen.dart';
import 'package:open_core_hr/screens/FaceAttendance/face_attendance_admin_console_screen.dart';
import 'package:open_core_hr/screens/FaceAttendance/face_registration_admin_screen.dart';
import 'package:open_core_hr/screens/FaceAttendance/face_registration_screen.dart';
import 'package:open_core_hr/screens/Settings/modules_screen.dart';

import '../../main.dart';
import '../navigation_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Observer(
        builder: (_) {
          final isDark = appStore.isDarkModeOn;
          final theme = Theme.of(context);

          if (isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          return SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: ColoredBox(
                    color: theme.scaffoldBackgroundColor,
                    child: _buildContent(isDark),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  language.lblSettings,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Settings Section Cards
                _buildSettingsCard(
                  isDark: isDark,
                  title: language.lblRefreshAppConfiguration,
                  icon: Iconsax.refresh_circle,
                  onTap: () async {
                    await sharedHelper.refreshAppSettings();
                    toast(language.lblSettingsRefreshed);
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  isDark: isDark,
                  title: language.lblModulesStatus,
                  icon: Iconsax.setting_2,
                  onTap: () {
                    const ModulesScreen().launch(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingsCard(
                  isDark: isDark,
                  title: language.lblChangePassword,
                  icon: Iconsax.lock,
                  onTap: () {
                    const ChangePasswordScreen().launch(context);
                  },
                ),
                if (moduleService.isFaceAttendanceModuleEnabled()) ...[
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    isDark: isDark,
                    title: language.lblFaceAttendance,
                    icon: Iconsax.scanning,
                    subtitle: 'Add your face for kiosk check-in',
                    onTap: () {
                      const FaceRegistrationScreen().launch(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    isDark: isDark,
                    title: language.lblFaceAttendanceDevice,
                    icon: Iconsax.mobile,
                    subtitle: 'View done & pending registrations',
                    onTap: () {
                      const FaceRegistrationAdminScreen().launch(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    isDark: isDark,
                    title: 'Face Attendance Admin',
                    icon: Iconsax.chart,
                    subtitle: 'Dashboard, audit log, devices & settings',
                    onTap: () {
                      const FaceAttendanceAdminConsoleScreen().launch(context);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                // Theme Selector Section
                _buildThemeSelector(isDark),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Soft-tinted icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Iconsax.arrow_right_3,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDark) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Gradient Icon
            Row(
              children: [
                // Soft-tinted icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Iconsax.color_swatch,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Header Text
                Expanded(
                  child: Text(
                    language.lblChangeTheme,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Color Circles
            SizedBox(
              height: 50,
              child: ListView.builder(
                itemCount: appStore.availableThemes.length,
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  var color = appStore.availableThemes[index];
                  final isSelected = appStore.appColorPrimary == color;

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });
                      appStore.changeColorTheme(color);
                      setState(() {
                        isLoading = false;
                      });
                      toast(language.lblColorChangedSuccessfully);
                      if (!mounted) return;
                      const NavigationScreen().launch(context, isNewTask: true);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : (isDark
                                          ? Colors.grey[700]!
                                          : const Color(0xFFE5E7EB)),
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
