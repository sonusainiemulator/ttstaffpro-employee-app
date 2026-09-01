import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../kiosk/app_lock_service.dart';
import '../kiosk/kiosk_settings.dart';
import '../kiosk/kiosk_theme.dart';
import '../main.dart';

/// Full-screen lock shown above the ENTIRE kiosk (over every route) whenever
/// [kioskLocked] is true. It asks the phone's native unlock (fingerprint /
/// face / pattern / PIN) and clears the flag on success.
class AppLockOverlay extends StatefulWidget {
  const AppLockOverlay({super.key});

  @override
  State<AppLockOverlay> createState() => _AppLockOverlayState();
}

class _AppLockOverlayState extends State<AppLockOverlay> {
  bool _unlocking = false;
  bool _failed = false;
  bool _noLockAvailable = false;
  String _hint = '';

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final method = kioskSettings.appLockMethod;
    final usable = await AppLockService.instance.canUseLock(method);
    if (!mounted) return;
    setState(() {
      _noLockAvailable = !usable;
      _hint = method == AppLockMethod.biometric
          ? 'Use your fingerprint or face to unlock'
          : 'Use your phone lock — pattern, PIN or biometric';
    });
    if (usable) {
      // Wait for the route/overlay to settle before showing the system prompt.
      WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
    }
  }

  Future<void> _unlock() async {
    if (!mounted || _unlocking) return;
    setState(() {
      _unlocking = true;
      _failed = false;
    });
    final ok = await AppLockService.instance.authenticate(
      reason: 'Unlock TTStaffPro Kiosk to continue',
      method: kioskSettings.appLockMethod,
    );
    if (!mounted) return;
    if (ok) {
      kioskLocked.value = false;
    } else {
      setState(() {
        _unlocking = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    return Material(
      color: c.background,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'TTStaffPro Kiosk',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _noLockAvailable
                        ? 'No lock is set up on this phone yet'
                        : 'Locked',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: KioskColors.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _noLockAvailable
                        ? 'Set a pattern, PIN or fingerprint in your phone '
                            'Settings first, then come back and unlock.'
                        : _hint,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Big unlock button.
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _noLockAvailable ? null : _unlock,
                      borderRadius: BorderRadius.circular(64),
                      child: Ink(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          gradient: KioskColors.brandGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: KioskColors.primary.withValues(alpha: 0.45),
                              offset: const Offset(0, 8),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: _unlocking
                            ? const Padding(
                                padding: EdgeInsets.all(36),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _noLockAvailable
                                    ? Icons.lock_outline
                                    : Icons.fingerprint,
                                size: 52,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_noLockAvailable)
                    FilledButton.icon(
                      onPressed: openAppSettings,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('Open phone Settings'),
                    )
                  else if (_failed)
                    Column(
                      children: [
                        Text(
                          'Could not verify your identity.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: KioskColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _unlock,
                          icon: const Icon(Icons.lock_open_outlined),
                          label: const Text('Try again'),
                        ),
                      ],
                    )
                  else
                    Text(
                      _unlocking ? 'Checking…' : 'Tap the fingerprint to unlock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
