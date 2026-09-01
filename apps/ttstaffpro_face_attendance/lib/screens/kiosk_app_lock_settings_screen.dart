import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../kiosk/app_lock_service.dart';
import '../kiosk/kiosk_settings.dart';
import '../kiosk/kiosk_theme.dart';
import '../main.dart';

/// Settings for the app lock: turn it on/off and choose whether to use
/// biometrics only or the phone's whole native lock (pattern / PIN /
/// biometric). Includes a live "test unlock" so the user can verify it works.
class KioskAppLockSettingsScreen extends StatefulWidget {
  const KioskAppLockSettingsScreen({super.key});

  @override
  State<KioskAppLockSettingsScreen> createState() =>
      _KioskAppLockSettingsScreenState();
}

class _KioskAppLockSettingsScreenState
    extends State<KioskAppLockSettingsScreen> {
  bool _enabled = false;
  bool _biometricAvailable = false;
  bool _credentialAvailable = false;
  bool _checkingDevice = true;
  String _biometricNames = '';
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _enabled = kioskSettings.appLockEnabled;
    _loadDeviceCapabilities();
  }

  Future<void> _loadDeviceCapabilities() async {
    final service = AppLockService.instance;
    final biometrics = await service.hasBiometrics;
    final supported = await service.isSupported;
    final types = await service.enrolledBiometrics;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = biometrics;
      // A phone lock (pattern/PIN/password) counts as usable when the device
      // supports the prompt even if no biometric is enrolled.
      _credentialAvailable = supported || biometrics;
      _biometricNames = _describeBiometrics(types);
      _checkingDevice = false;
    });
  }

  String _describeBiometrics(List<BiometricType> types) {
    final names = <String>[];
    for (final t in types) {
      switch (t) {
        case BiometricType.fingerprint:
          names.add('Fingerprint');
          break;
        case BiometricType.face:
          names.add('Face');
          break;
        case BiometricType.iris:
          names.add('Iris');
          break;
        case BiometricType.strong:
          names.add('Strong biometric');
          break;
        case BiometricType.weak:
          names.add('Weak biometric');
          break;
      }
    }
    return names.join(', ');
  }

  Future<void> _toggle(bool value) async {
    // Guard: the app lock needs a real lock set up on the phone.
    if (value && !_biometricAvailable && !_credentialAvailable) {
      _showNoLockDialog();
      return;
    }
    await kioskSettings.setAppLock(
      enabled: value,
      method: kioskSettings.appLockMethod,
    );
    if (!mounted) return;
    setState(() => _enabled = value);
    // Applying the choice from the settings screen immediately re-locks the
    // app so the user experiences the lock right away.
    if (value) kioskLocked.value = true;
  }

  Future<void> _selectMethod(AppLockMethod method) async {
    if (method == AppLockMethod.biometric && !_biometricAvailable) {
      _showBiometricUnavailableDialog();
      return;
    }
    await kioskSettings.setAppLock(enabled: true, method: method);
    if (!mounted) return;
    setState(() => _enabled = true);
  }

  Future<void> _testUnlock() async {
    setState(() => _testing = true);
    final ok = await AppLockService.instance.authenticate(
      reason: 'This is a test — verify your app lock works',
      method: kioskSettings.appLockMethod,
    );
    if (!mounted) return;
    setState(() => _testing = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Unlock successful ✓'
                : 'Unlock cancelled or failed — check your phone lock settings.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showNoLockDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No phone lock set up'),
        content: const Text(
          'To use the app lock, first set a pattern, PIN or fingerprint in '
          'your phone Settings. The kiosk uses the lock you already set up '
          'on this phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBiometricUnavailableDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No biometrics on this phone'),
        content: const Text(
          'This phone has no fingerprint or face enrolled. Choose '
          '"Phone lock" so the kiosk can use your pattern or PIN instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Lock'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Intro card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: KioskColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.fingerprint,
                      color: KioskColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Protect the kiosk with the lock you already have on '
                      'this phone — fingerprint, face, pattern or PIN. '
                      'Nothing is stored in the app.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Main toggle
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: SwitchListTile(
                value: _enabled,
                onChanged: _toggle,
                activeTrackColor: KioskColors.primary,
                title: Text(
                  'Enable App Lock',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _enabled
                      ? 'Lock the kiosk when opened or resumed'
                      : 'Ask for the phone lock before using the kiosk',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Device capabilities
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This phone',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CapabilityRow(
                    icon: Icons.fingerprint,
                    label: 'Fingerprint / face',
                    value: _checkingDevice
                        ? 'Checking…'
                        : (_biometricAvailable
                              ? (_biometricNames.isEmpty
                                    ? 'Available'
                                    : _biometricNames)
                              : 'Not set up'),
                    ok: _biometricAvailable,
                  ),
                  const SizedBox(height: 10),
                  _CapabilityRow(
                    icon: Icons.pin_outlined,
                    label: 'Pattern / PIN',
                    value: _checkingDevice
                        ? 'Checking…'
                        : (_credentialAvailable ? 'Available' : 'Not set up'),
                    ok: _credentialAvailable,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Method selection (only when enabled)
            if (_enabled) ...[
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                      child: Text(
                        'Unlock method',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    RadioGroup<AppLockMethod>(
                      groupValue: kioskSettings.appLockMethod,
                      onChanged: (m) {
                        if (m != null) _selectMethod(m);
                      },
                      child: Column(
                        children: [
                          RadioListTile<AppLockMethod>(
                            value: AppLockMethod.phoneLock,
                            activeColor: KioskColors.primary,
                            title: const Text('Phone lock'),
                            subtitle: const Text(
                              'Pattern, PIN or biometric — whatever you set up',
                            ),
                          ),
                          RadioListTile<AppLockMethod>(
                            value: AppLockMethod.biometric,
                            activeColor: KioskColors.primary,
                            title: const Text('Biometric only'),
                            subtitle: const Text('Fingerprint or face'),
                            enabled: _biometricAvailable,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _testing ? null : _testUnlock,
                icon: _testing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_open_outlined),
                label: Text(_testing ? 'Unlocking…' : 'Test unlock'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool ok;

  const _CapabilityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    final color = ok ? KioskColors.success : KioskColors.warning;
    return Row(
      children: [
        Icon(icon, size: 20, color: c.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: c.textPrimary),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
