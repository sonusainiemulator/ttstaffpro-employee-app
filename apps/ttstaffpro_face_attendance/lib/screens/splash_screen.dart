import 'dart:async';

import 'package:flutter/material.dart';

import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';
import 'company_login_screen.dart';
import 'kiosk_home_screen.dart';

/// Decides where the kiosk starts: if a company + master session is active it
/// goes straight to the kiosk home, otherwise to the company login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Hard fallback: even if _bootstrap is interrupted for any reason, the
    // kiosk must never stay stuck on the splash — navigate after 5s max.
    Timer(const Duration(seconds: 5), () {
      if (mounted) _route();
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Warm up the device identity + enrolled profiles in the background.
    unawaited(_warmUp());
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _route();
  }

  void _route() {
    if (_navigated || !mounted) return;
    _navigated = true;
    if (kioskSettings.isCompanyLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
      );
    }
  }

  Future<void> _warmUp() async {
    if (kioskSettings.isDeviceRegistered) {
      await kioskService.loadProfilePackage();
    }
  }

  void unawaited(Future<void> future) {
    future.ignore();
  }

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Container(
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing glass logo chip
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [c.surfaceAlt, c.surface],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: KioskColors.primary.withValues(alpha: 0.45),
                        width: 1.5,
                      ),
                      boxShadow: c.softGlow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 112,
                        height: 112,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'TTStaffPro',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Face Attendance Kiosk',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: KioskColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: KioskVersionFooter(),
            ),
          ],
        ),
      ),
    );
  }
}
