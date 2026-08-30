import 'package:flutter/material.dart';

import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';
import 'master_login_screen.dart';

/// Requirement 1: match the TT Staff Pro company name on login.
///
/// The kiosk operator types the company name; the backend matches it
/// (fuzzy/autocomplete supported server-side) and the kiosk proceeds to the
/// master login for that company.
class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _matchCompany() async {
    final companyName = _controller.text.trim();
    if (companyName.isEmpty) {
      setState(() => _error = 'Please enter the company name.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await kioskService.matchCompany(companyName);
      if (!mounted) return;

      if (result.ok && result.company != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MasterLoginScreen()),
        );
      } else {
        setState(() {
          _error =
              result.message ?? 'Company not found. Please check the name.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Show the real reason (DNS / SSL / timeout) so setup issues are visible
      // on the tablet instead of a generic message.
      setState(() {
        _error = 'Could not reach the server.\n$e';
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
            // Soft brand glow orbs
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
                          children: [
                            Text(
                              'TT Staff Pro',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Face Attendance Kiosk',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _controller,
                              textCapitalization: TextCapitalization.words,
                              cursorColor: KioskColors.primary,
                              style: TextStyle(color: c.textPrimary),
                              decoration: InputDecoration(
                                labelText: 'Company Name',
                                labelStyle: TextStyle(color: c.textSecondary),
                                hintText: 'Enter registered company name',
                                hintStyle: TextStyle(color: c.textMuted),
                                prefixIcon: const Icon(
                                  Icons.storefront_outlined,
                                  size: 20,
                                  color: KioskColors.primaryLight,
                                ),
                                filled: true,
                                fillColor: c.backgroundAlt,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
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
                                  borderSide: const BorderSide(
                                    color: KioskColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _matchCompany(),
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
                              width: double.infinity,
                              height: 52,
                              child: FilledButton.icon(
                                onPressed: _loading ? null : _matchCompany,
                                icon: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward),
                                label: Text(
                                  _loading ? 'Matching...' : 'Continue',
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
}
