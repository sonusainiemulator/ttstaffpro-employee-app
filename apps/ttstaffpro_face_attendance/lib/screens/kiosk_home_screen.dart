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
                    // Header card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.border),
                        boxShadow: c.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: KioskColors.primary.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: KioskColors.primary.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kioskSettings.companyName ?? 'TT Staff Pro',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Face Attendance Kiosk',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // App lock: configure the phone's native unlock.
                          IconButton(
                            tooltip: 'App Lock',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    const KioskAppLockSettingsScreen(),
                              ),
                            ),
                            icon: Icon(
                              kioskSettings.appLockEnabled
                                  ? Icons.lock
                                  : Icons.lock_open,
                              color: c.textSecondary,
                            ),
                          ),
                          // Theme selector: dark / light / system.
                          PopupMenuButton<ThemeMode>(
                            tooltip: 'Theme',
                            icon: Icon(
                              _themeIcon(kioskThemeMode.value),
                              color: c.textSecondary,
                            ),
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
                          ),
                          IconButton(
                            tooltip: 'Logout',
                            onPressed: _logout,
                            icon: Icon(Icons.logout, color: c.textSecondary),
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
                    const SizedBox(height: 20),
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
