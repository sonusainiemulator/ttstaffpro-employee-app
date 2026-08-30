import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'kiosk_theme.dart';

/// Small app-version label ("v1.0.4") pinned to the bottom of kiosk screens.
///
/// Loads the version once from `PackageInfo` and renders it in a subtle,
/// theme-aware style. Non-critical: if the platform package lookup fails the
/// footer simply renders empty.
class KioskVersionFooter extends StatefulWidget {
  const KioskVersionFooter({super.key});

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
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Text(
        _version.isEmpty ? '' : 'v$_version',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: c.textMuted.withValues(alpha: 0.75),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
