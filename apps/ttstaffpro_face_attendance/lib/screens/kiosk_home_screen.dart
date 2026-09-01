import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';
import 'company_login_screen.dart';
import 'kiosk_app_lock_settings_screen.dart';
import 'kiosk_register_face_screen.dart';
import 'kiosk_report_screen.dart';
import 'kiosk_scan_screen.dart';

/// Kiosk dashboard: company header, live clock, quick actions and sync status.
class KioskHomeScreen extends StatefulWidget {
  const KioskHomeScreen({super.key});

  @override
  State<KioskHomeScreen> createState() => _KioskHomeScreenState();
}

class _KioskHomeScreenState extends State<KioskHomeScreen> {
  late Timer _clockTimer;
  Timer? _heartbeatTimer;
  int _pendingCount = 0;
  bool _warmupStarted = false;

  /// How often the kiosk reports device health to the backend (the admin
  /// Devices screen expects a heartbeat roughly every 60s).
  static const Duration _heartbeatInterval = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Previously nothing ever scheduled sendHeartbeat(), so registered kiosks
    // always appeared offline/stale on the admin device-health screen.
    _startHeartbeat();
    _pendingCount = offlineStore.pendingCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _warmupStarted) return;
      _warmupStarted = true;
      _warmUp();
    });
  }

  /// Periodically reports device health (sendHeartbeat is a no-op until the
  /// device is registered, so it is safe to run even before login completes).
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      kioskService.sendHeartbeat();
    });
  }

  Future<void> _warmUp() async {
    try {
      await kioskService.loadProfilePackage();
      final synced = await kioskService.syncPendingEvents();
      if (!mounted) return;
      if (synced > 0 || offlineStore.pendingCount != _pendingCount) {
        setState(() => _pendingCount = offlineStore.pendingCount);
      }
    } catch (_) {
      // Keep the kiosk usable even when background sync/profile refresh fails.
      if (!mounted) return;
      setState(() => _pendingCount = offlineStore.pendingCount);
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    await kioskSettings.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await kioskSettings.setThemeMode(mode);
    kioskThemeMode.value = mode;
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    final now = DateTime.now();
    final timeStr = DateFormat('hh:mm:ss a').format(now);
    final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(now);

    return Scaffold(
      body: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: Stack(
          children: [
            // Soft brand glow
            Positioned(
              top: -140,
              right: -120,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KioskColors.primary.withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KioskColors.primaryLight.withValues(alpha: 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Header card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            c.surface,
                            c.surfaceAlt.withValues(alpha: 0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: c.border.withValues(alpha: 0.8),
                        ),
                        boxShadow: c.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: KioskColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: KioskColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  kioskSettings.companyName ?? 'TT Staff Pro',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: KioskColors.success,
                                        boxShadow: [
                                          BoxShadow(
                                            color: KioskColors.success
                                                .withValues(alpha: 0.6),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Face Attendance Kiosk',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: c.textSecondary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // App lock: configure the phone's native unlock.
                          _HeaderActionButton(
                            tooltip: kioskSettings.appLockEnabled
                                ? 'App Lock (Enabled)'
                                : 'App Lock (Disabled)',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const KioskAppLockSettingsScreen(),
                              ),
                            ),
                            backgroundColor: kioskSettings.appLockEnabled
                                ? KioskColors.primary.withValues(alpha: 0.12)
                                : null,
                            borderColor: kioskSettings.appLockEnabled
                                ? KioskColors.primary.withValues(alpha: 0.4)
                                : null,
                            child: Icon(
                              kioskSettings.appLockEnabled
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 18,
                              color: kioskSettings.appLockEnabled
                                  ? KioskColors.primary
                                  : c.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Theme selector: dark / light / system.
                          PopupMenuButton<ThemeMode>(
                            tooltip: 'Theme',
                            offset: const Offset(0, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: c.border),
                            ),
                            color: c.surface,
                            padding: EdgeInsets.zero,
                            onSelected: _setThemeMode,
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: ThemeMode.system,
                                child: ListTile(
                                  leading: Icon(Icons.brightness_auto_outlined),
                                  title: Text('System'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.light,
                                child: ListTile(
                                  leading: Icon(Icons.light_mode_outlined),
                                  title: Text('Light'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                              PopupMenuItem(
                                value: ThemeMode.dark,
                                child: ListTile(
                                  leading: Icon(Icons.dark_mode_outlined),
                                  title: Text('Dark'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            ],
                            child: Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.surfaceAlt.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: c.border.withValues(alpha: 0.8),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _themeIcon(kioskThemeMode.value),
                                size: 18,
                                color: c.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _HeaderActionButton(
                            tooltip: 'Logout',
                            onTap: _logout,
                            backgroundColor:
                                KioskColors.error.withValues(alpha: 0.08),
                            borderColor:
                                KioskColors.error.withValues(alpha: 0.25),
                            child: Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: KioskColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Clock card (brand gradient)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: KioskColors.brandGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: c.softGlow,
                      ),
                      child: Column(
                        children: [
                          Text(
                            timeStr,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Live attendance counter & last scan summary
                    ValueListenableBuilder<int>(
                      valueListenable: kioskService.todayScannedCount,
                      builder: (context, count, _) {
                        return ValueListenableBuilder<String?>(
                          valueListenable: kioskService.lastScannedInfo,
                          builder: (context, lastInfo, _) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: c.border.withValues(alpha: 0.9),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: KioskColors.primaryLight
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.how_to_reg_rounded,
                                      color: KioskColors.primaryLight,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Today Scanned: $count Marked',
                                          style: TextStyle(
                                            color: c.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          lastInfo != null
                                              ? 'Last: $lastInfo'
                                              : 'Ready for check-in / out',
                                          style: TextStyle(
                                            color: c.textSecondary,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (count > 0
                                              ? KioskColors.success
                                              : KioskColors.info)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      count > 0 ? 'Active' : 'Standby',
                                      style: TextStyle(
                                        color: count > 0
                                            ? KioskColors.success
                                            : KioskColors.info,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          _ActionListItem(
                            icon: Icons.face_retouching_natural,
                            title: 'Start Scan',
                            subtitle: 'Check-in / Check-out',
                            gradient: const [
                              Color(0xFF7C5CFF),
                              Color(0xFF4A6CFF),
                            ],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KioskScanScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActionListItem(
                            icon: Icons.person_add_alt_1_rounded,
                            title: 'Register Face',
                            subtitle: 'Add staff face',
                            gradient: const [
                              Color(0xFF22D97A),
                              Color(0xFF0EA5A8),
                            ],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const KioskRegisterFaceScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ActionListItem(
                            icon: Icons.insert_chart_outlined,
                            title: 'Daily Report',
                            subtitle: 'Date-wise attendance',
                            gradient: const [
                              Color(0xFF22D3EE),
                              Color(0xFF0EA5E9),
                            ],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const KioskReportScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sync status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pendingCount > 0
                                ? Icons.cloud_upload_outlined
                                : Icons.cloud_done_outlined,
                            size: 18,
                            color: _pendingCount > 0
                                ? KioskColors.warning
                                : KioskColors.success,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _pendingCount > 0
                                    ? '$_pendingCount event(s) pending sync'
                                    : 'All attendance events synced',
                                maxLines: 1,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Offline queue',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: c.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const KioskVersionFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionListItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: gradient.first.withValues(alpha: 0.12),
        highlightColor: gradient.first.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surfaceAlt, c.surface],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
            boxShadow: c.cardShadow,
          ),
          child: Row(
            children: [
              // Icon Badge with vibrant gradient & subtle glow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.35),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, size: 26, color: Colors.white),
              ),
              const SizedBox(width: 16),
              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Trailing arrow icon indicator
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.surface.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.border.withValues(alpha: 0.8),
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;

  const _HeaderActionButton({
    required this.child,
    required this.tooltip,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor ?? c.surfaceAlt.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor ?? c.border.withValues(alpha: 0.8),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

