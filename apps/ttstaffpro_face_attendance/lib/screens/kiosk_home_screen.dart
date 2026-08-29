import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../kiosk/kiosk_theme.dart';
import '../main.dart';
import 'company_login_screen.dart';
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
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _pendingCount = offlineStore.pendingCount;
    _warmUp();
  }

  Future<void> _warmUp() async {
    await kioskService.loadProfilePackage();
    final synced = await kioskService.syncPendingEvents();
    if (mounted && synced > 0) {
      setState(() => _pendingCount = offlineStore.pendingCount);
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
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
        decoration: BoxDecoration(
          gradient: c.backgroundGradient,
        ),
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
                          horizontal: 16, vertical: 12),
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
                              color: KioskColors.primary
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: KioskColors.primary
                                      .withValues(alpha: 0.4)),
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
                            icon: Icon(Icons.logout,
                                color: c.textSecondary),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: _ActionCard(
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
                              icon: Icons.person_add_alt_1,
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionCard(
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sync status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                            child: Text(
                              _pendingCount > 0
                                  ? '$_pendingCount event(s) pending sync'
                                  : 'All attendance events synced',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: c.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _ActionCard({
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
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.surfaceAlt, c.surface],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(icon, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
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
