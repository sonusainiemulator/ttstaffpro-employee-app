import 'package:flutter/material.dart';

import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';
import 'kiosk_home_screen.dart';

/// Requirement 5: admin login for a single-point face attendance tablet.
///
/// Master login uses the TENANT ADMIN credentials (email + password — the same
/// as the TTStaffPro employee app), so there is no confusion between the tenant
/// admin login and the kiosk master login. After login the tablet registers
/// itself as a device and enters the always-on kiosk.
class MasterLoginScreen extends StatefulWidget {
  const MasterLoginScreen({super.key});

  @override
  State<MasterLoginScreen> createState() => _MasterLoginScreenState();
}

class _MasterLoginScreenState extends State<MasterLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your admin email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final companyId = kioskSettings.companyId ?? '';
      final result = await kioskService.masterLogin(
        companyId: companyId,
        username: username,
        password: password,
      );
      if (!mounted) return;

      if (!result.ok || result.masterToken == null) {
        setState(() {
          _error = result.message ?? 'Invalid admin credentials.';
        });
        return;
      }

      await kioskService.activateMasterSession();

      // Register this tablet as a kiosk device (idempotent).
      await kioskService.registerDevice();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KioskHomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Login failed. Please check your connection and credentials.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: MediaQuery.sizeOf(context).width,
        height: MediaQuery.sizeOf(context).height,
        decoration: BoxDecoration(gradient: c.backgroundGradient),
        child: Stack(
          children: [
            // App version footer (pinned to the bottom).
            const Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: KioskVersionFooter(),
            ),
            Positioned(
              top: -120,
              right: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KioskColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KioskColors.primaryLight.withValues(alpha: 0.08),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glass logo chip
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [c.surfaceAlt, c.surface],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: KioskColors.primary.withValues(alpha: 0.4),
                          ),
                          boxShadow: c.softGlow,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 92,
                            height: 92,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Glass login card
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: c.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: c.border),
                          boxShadow: c.cardShadow,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.arrow_back),
                                  color: c.textPrimary,
                                ),
                                const Spacer(),
                              ],
                            ),
                            Text(
                              'Admin Login',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Use your TTStaffPro admin login for ${kioskSettings.companyName ?? 'this company'}',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _usernameController,
                              keyboardType: TextInputType.emailAddress,
                              textCapitalization: TextCapitalization.none,
                              cursorColor: KioskColors.primary,
                              style: TextStyle(color: c.textPrimary),
                              decoration: _kioskInputDecoration(
                                label: 'Admin Email',
                                icon: Icons.alternate_email,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              onSubmitted: (_) => _login(),
                              cursorColor: KioskColors.primary,
                              style: TextStyle(color: c.textPrimary),
                              decoration: _kioskInputDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    size: 20,
                                  ),
                                  color: c.textSecondary,
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: KioskColors.error,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _login,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login),
                                label: Text(
                                  _loading ? 'Signing in...' : 'Start Kiosk',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: KioskColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _kioskInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    final c = KioskTheme.of(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: c.textSecondary),
      prefixIcon: Icon(icon, size: 20, color: KioskColors.primaryLight),
      suffixIcon: suffix,
      filled: true,
      fillColor: c.backgroundAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: KioskColors.primary, width: 2),
      ),
    );
  }
}
