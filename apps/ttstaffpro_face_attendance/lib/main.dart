import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_core_hr/api/api_routes.dart';
import 'package:open_core_hr/utils/token_storage.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'kiosk/kiosk_service.dart';
import 'kiosk/kiosk_settings.dart';
import 'kiosk/kiosk_theme.dart';
import 'kiosk/offline_store.dart';
import 'screens/splash_screen.dart';

/// Global kiosk state shared across screens.
KioskSettings kioskSettings = KioskSettings();
OfflineStore offlineStore = OfflineStore();
KioskService kioskService = KioskService(
  settings: kioskSettings,
  offlineStore: offlineStore,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch any uncaught async error so the app never dies to a white screen.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('KIOSK-ERROR: ${details.exceptionAsString()}');
  };

  await runZonedGuarded(() async {
    // Watchdog: a wall-mounted kiosk must never sit on a blank/native splash.
    // If any init step hangs (wakelock, Hive, platform channel), force the app
    // up after a fixed delay instead of leaving the tablet stuck.
    final initialized = await Future.any<bool>([
      _initializeApp().then((_) => true),
      Future<void>.delayed(const Duration(seconds: 12)).then((_) => false),
    ]);
    if (!initialized) {
      debugPrint('KIOSK-INIT-WATCHDOG: init exceeded 12s — forcing start');
      runApp(const KioskApp());
    }
  }, (e, st) {
    debugPrint('KIOSK-UNCAUGHT: $e\n$st');
  });
}

/// Runs the (potentially blocking) startup work and calls [runApp] once done.
Future<void> _initializeApp() async {
  try {
    // Initialize nb_utils shared preferences FIRST — every setValue /
    // getStringAsync call crashes with LateInitializationError until this
    // runs (this was the white-screen bug: setValue('baseurl') was called
    // before nb_utils' `initialize()`).
    await initialize();

    // Restore the master API token from secure storage into memory before any
    // API call so a restarted kiosk keeps its authenticated session.
    await TokenStorage.restore();

    // Always point the API client at the production base URL — never rely on
    // a possibly-stale 'baseurl' pref on a fresh tablet install.
    await setValue('baseurl', APIRoutes.baseURL);

    // Kiosk mode: keep the screen awake and hide system chrome (immersive).
    await WakelockPlus.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    // Local persistence.
    await Hive.initFlutter();
    await offlineStore.init();
    await kioskSettings.load();
    // Start with the user's persisted appearance choice (dark / light / system).
    kioskThemeMode.value = kioskSettings.themeMode;
    await kioskService.loadAppVersion();

    runApp(const KioskApp());
  } catch (e, st) {
    // Show the error instead of a blank white screen.
    debugPrint('KIOSK-INIT-ERROR: $e\n$st');
    runApp(_ErrorApp(message: e.toString()));
  }
}

/// Simple fallback screen that surfaces a startup error on the tablet.
class _ErrorApp extends StatelessWidget {
  final String message;
  const _ErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFB3261E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Startup error:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app the instant the user toggles dark/light/system.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: kioskThemeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'TTStaffPro Face Attendance Kiosk',
          debugShowCheckedModeBanner: false,
          // Full user-selectable appearance: dark / light / system.
          theme: KioskTheme.themeFor(Brightness.light),
          darkTheme: KioskTheme.themeFor(Brightness.dark),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
