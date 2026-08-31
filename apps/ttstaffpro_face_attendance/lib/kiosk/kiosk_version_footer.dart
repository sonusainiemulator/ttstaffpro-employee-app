import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'kiosk_theme.dart';

/// TT Staff Pro branded footer pinned to the bottom of kiosk screens:
/// "TT STAFF PRO | ttstaffpro.in" plus the current app version.
///
/// Loads the version once from `PackageInfo` and renders it in a subtle,
/// theme-aware style. Non-critical: if the platform package lookup fails the
/// version line simply renders empty (the brand line always shows).
class KioskVersionFooter extends StatefulWidget {
  const KioskVersionFooter({super.key, this.color});

  /// Optional color override — used on dark camera surfaces (e.g. the
  /// face-scan screen) where the theme's muted text would be hard to read.
  final Color? color;

  @override
  State<KioskVersionFooter> createState() => _KioskVersionFooterState();
}

class _KioskVersionFooterState extends State<KioskVersionFooter> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = info.version.trim();
      if (mounted && v.isNotEmpty) {
        setState(() => _version = v);
      }
    } catch (_) {
      // Ignore — version label is purely cosmetic.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = KioskTheme.of(context);
    final base = widget.color ?? c.textMuted.withValues(alpha: 0.9);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TT STAFF PRO  |  ttstaffpro.in',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: base,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (_version.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'App v$_version',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: base.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
