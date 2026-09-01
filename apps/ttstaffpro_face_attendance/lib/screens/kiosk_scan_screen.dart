import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import '../kiosk/face_matcher.dart';
import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';

/// Requirement 5 & 6: wall-mounted always-on face scan screen.
///
/// - No screen sleep (wakelock + immersive + FLAG_KEEP_SCREEN_ON).
/// - Continuously scans; on a matched face it uploads a recognition event and
///   the server responds with check-in / check-out.
/// - Automatically re-arms after every scan so many staff can clock in one
///   after another without touching the tablet.
/// - Offline events are queued locally and synced later.
class KioskScanScreen extends StatefulWidget {
  const KioskScanScreen({super.key});

  @override
  State<KioskScanScreen> createState() => _KioskScanScreenState();
}

class _KioskScanScreenState extends State<KioskScanScreen>
    with SingleTickerProviderStateMixin {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _busy = false;
  bool _resultHold = false;

  final FaceMatcher _matcher = kioskService.matcher;
  Timer? _scanTimer;

  /// Drives the pulsing face-guide + scanning line.
  late final AnimationController _pulseAnim;

  String _status = 'Starting camera...';
  String? _lastEmployeeName;
  String? _lastEmployeeCode;
  String? _lastAction;
  bool _lastSuccess = false;
  int _scanCount = 0;
  bool _isTorchOn = false;

  /// Tracks the last successful scan so the same person standing in front of
  /// the camera is not immediately scanned again (which would flip their
  /// check-in into a check-out while they are still reading the result).
  int? _lastScannedEmployeeId;
  DateTime? _lastScanAt;
  static const Duration _rescanCooldown = Duration(seconds: 5);

  /// Throttles "unknown face" uploads so a stranger standing in front of the
  /// kiosk does not spam the server with an event every scan frame.
  DateTime? _lastUnknownAt;
  static const Duration _unknownCooldown = Duration(seconds: 4);

  /// How long the success/result card stays on screen before the scanner
  /// re-arms. 3 seconds keeps the line moving fast in schools and offices.
  static const Duration _resultHoldDuration = Duration(seconds: 3);
  Timer? _resultTimer;
  int _resultSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Keep the kiosk in the user's native portrait orientation. Do not rotate
    // the preview for landscape mounting or sensor-driven view changes on the
    // face-scan screen.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status != PermissionStatus.granted) {
      setState(() => _status = 'Camera permission denied.');
      return;
    }
    await _initializeCamera();
    if (!mounted) return;
    if (kioskService.enrolledSignatures.isEmpty) {
      await kioskService.loadProfilePackage();
    }
    if (!mounted) return;
    setState(() {
      _status = kioskService.enrolledSignatures.isEmpty
          ? 'Waiting for face...'
          : 'Look at the camera to check in / out';
    });
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(
      const Duration(milliseconds: 1800),
      (_) => _scan(),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _status = 'No camera found on this device.');
        return;
      }
      final frontCam = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );
      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() => _status = 'Camera error: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      _isTorchOn = !_isTorchOn;
      await _cameraController!.setFlashMode(
        _isTorchOn ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() {});
    } catch (_) {
      // Best effort on devices without front torch
    }
  }

  void _dismissResultNow() {
    _resultTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _resultHold = false;
      _lastEmployeeName = null;
      _lastEmployeeCode = null;
      _lastAction = null;
      _resultSecondsLeft = 0;
      _status = kioskService.enrolledSignatures.isEmpty
          ? 'Waiting for face...'
          : 'Look at the camera to check in / out';
    });
  }

  // ---------------------------------------------------------------------------
  // Scan loop
  // ---------------------------------------------------------------------------

  Future<void> _scan() async {
    if (_busy || _resultHold || !_isCameraInitialized || !mounted) return;
    _busy = true;
    try {
      final XFile file = await _cameraController!.takePicture();
      if (!mounted) return;
      final path = await _saveTemp(file);

      final faces = await _matcher.detectFaces(path);
      if (faces.isEmpty) {
        if (mounted) {
          setState(() => _status = 'No face detected. Align within the frame.');
        }
        return;
      }
      if (faces.length > 1) {
        HapticFeedback.vibrate();
        if (mounted) {
          setState(() => _status = 'Only one person at a time, please.');
        }
        return;
      }
      final face = faces.first;

      final signature = _matcher.signatureOf(face);
      if (!signature.isLive) {
        HapticFeedback.selectionClick();
        if (mounted) {
          setState(
            () => _status = 'Please open your eyes and look at the camera.',
          );
        }
        return;
      }
      if (!signature.isFrontal) {
        HapticFeedback.selectionClick();
        if (mounted) {
          setState(
            () => _status = 'Look straight at the camera to check in / out.',
          );
        }
        return;
      }

      _scanCount++;
      if (!mounted) return;

      final match = kioskService.enrolledSignatures.isNotEmpty
          ? _matcher.identify(signature, kioskService.enrolledSignatures)
          : null;

      if (match != null) {
        final now = DateTime.now();
        final cooldownActive = _lastScannedEmployeeId == match.employeeId &&
            _lastScanAt != null &&
            now.difference(_lastScanAt!) < _rescanCooldown;
        if (cooldownActive) {
          // The same employee was just scanned — ignore this frame so their
          // check-in is not immediately turned into a check-out while they are
          // still standing in front of the camera.
          if (mounted) {
            setState(
              () => _status = 'Scan complete. Please step aside for the next person.',
            );
          }
          return;
        }
        _lastScannedEmployeeId = match.employeeId;
        _lastScanAt = now;

        // Instant audio & haptic confirmation
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.mediumImpact();

        await _handleMatch(
          employeeId: match.employeeId,
          distance: match.distance,
          confidence: match.confidence,
          snapshotPath: path,
        );
      } else {
        // No confident local match — log an unknown event for admin review
        // instead of guessing an identity, but throttle it so a lingering
        // stranger does not spam the server with an event every frame.
        final now = DateTime.now();
        final throttled = _lastUnknownAt != null &&
            now.difference(_lastUnknownAt!) < _unknownCooldown;
        if (throttled) {
          if (mounted) {
            setState(() => _status = 'Face not recognized. Please try again.');
          }
          return;
        }
        _lastUnknownAt = now;
        await _handleUnknown(path);
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Scan error, retrying...');
    } finally {
      _busy = false;
    }
  }

  Future<void> _handleMatch({
    required int employeeId,
    required double distance,
    required double confidence,
    required String snapshotPath,
  }) async {
    final name =
        kioskService.employeeNames[employeeId] ?? 'Employee $employeeId';
    final code = kioskService.employeeCodes[employeeId];
    setState(() => _status = 'Verifying $name...');

    final result = await kioskService.uploadEvent(
      eventUuid: const Uuid().v4(),
      eventType: 'attendance',
      employeeId: employeeId,
      recognitionStatus: 'matched',
      confidenceScore: confidence,
      snapshotPath: snapshotPath,
    );

    if (!mounted) return;
    final action = _actionLabel(result?.attendanceAction);
    kioskService.recordLocalScan(name: name, code: code, action: action);

    if (result != null) {
      _showResult(
        success: true,
        name: name,
        code: code,
        action: action,
      );
    } else {
      // Offline — queued for sync.
      _showResult(
        success: true,
        name: name,
        code: code,
        action: 'Saved Offline',
      );
    }
  }

  /// Maps the server's attendance action to a clear, human-readable label so
  /// staff can tell at a glance whether they checked in or out.
  String _actionLabel(String? action) {
    switch ((action ?? '').toLowerCase().replaceAll('-', '_')) {
      case 'check_in':
      case 'checkin':
        return 'Check-in recorded';
      case 'check_out':
      case 'checkout':
        return 'Check-out recorded';
      case '':
        return 'attendance updated';
      default:
        return action!;
    }
  }

  Future<void> _handleUnknown(String snapshotPath) async {
    HapticFeedback.vibrate();
    setState(() => _status = 'Scanning...');
    final result = await kioskService.uploadEvent(
      eventUuid: const Uuid().v4(),
      eventType: 'attendance',
      recognitionStatus: 'unknown',
      snapshotPath: snapshotPath,
    );

    if (!mounted) return;
    if (result != null && result.attendanceId != null) {
      SystemSound.play(SystemSoundType.click);
      _showResult(
        success: true,
        name: result.message ?? 'Attendance recorded',
        action: _actionLabel(result.attendanceAction),
      );
    } else if (result != null && (result.attendanceId == null)) {
      _showResult(
        success: false,
        name: 'Face not registered',
        action: 'Please register your face first',
      );
    } else {
      // Offline.
      _showResult(
        success: true,
        name: 'Event saved',
        action: 'will sync when online',
      );
    }
  }

  /// Shows a result overlay for [_resultHoldDuration] (3s) with a live
  /// countdown, then automatically re-arms the scanner.
  void _showResult({
    required bool success,
    required String name,
    String? code,
    required String action,
  }) {
    _resultTimer?.cancel();
    setState(() {
      _resultHold = true;
      _lastSuccess = success;
      _lastEmployeeName = name;
      _lastEmployeeCode = code;
      _lastAction = action;
      _resultSecondsLeft = _resultHoldDuration.inSeconds;
    });

    _resultTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resultSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _resultHold = false;
          _lastEmployeeName = null;
          _lastEmployeeCode = null;
          _lastAction = null;
          _resultSecondsLeft = 0;
          _status = kioskService.enrolledSignatures.isEmpty
              ? 'Waiting for face...'
              : 'Look at the camera to check in / out';
        });
      } else {
        setState(() => _resultSecondsLeft--);
      }
    });
  }

  Future<String> _saveTemp(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final newPath =
        '${dir.path}/kiosk_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(file.path).copy(newPath);
    return newPath;
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _resultTimer?.cancel();
    _pulseAnim.dispose();
    _cameraController?.dispose();
    _matcher.close();
    // Restore the kiosk to its locked portrait dashboard.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Future<void> _exit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit scan mode?'),
        content: const Text('The kiosk will return to the dashboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KioskTheme.of(context).background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Themed branded background (no full-bleed camera).
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 12),
                // Framed "device screen" that holds the camera preview, the
                // face guide and the live hint / result card — matching the
                // wall-mounted tablet look of the product poster.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildDeviceScreen(),
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: KioskVersionFooter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Themed gradient background with soft brand glows (no full-bleed camera).
  Widget _buildBackground() {
    final c = KioskTheme.of(context);
    return Container(
      decoration: BoxDecoration(gradient: c.backgroundGradient),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _glowOrb(KioskColors.primaryLight.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _glowOrb(KioskColors.primaryLight.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }

  /// Standby state before the camera is ready (or when it is unavailable).
  Widget _buildStandby() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.face_retouching_natural,
              size: 56,
              color: Colors.white38,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _status.isEmpty ? 'Starting camera…' : _status,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The framed "device screen" that contains the camera preview, the face
  /// guide and the live hint / result card — the poster’s wall-mounted tablet
  /// look instead of a full-bleed camera.
  Widget _buildDeviceScreen() {
    final c = KioskTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.border, width: 3),
        boxShadow: c.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            _buildPreview()
          else
            _buildStandby(),
          // Legibility scrims (top + bottom) over the camera.
          const _ScanScrim(alignment: Alignment.topCenter),
          const _ScanScrim(alignment: Alignment.bottomCenter),
          // Animated face guide.
          Center(child: _buildFaceGuide()),
          // Bottom overlay inside the screen: result card or live hint.
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _resultHold ? _buildResultCard() : _buildInViewHint(),
          ),
        ],
      ),
    );
  }

  /// Compact live-status pill shown over the camera while scanning.
  Widget _buildInViewHint() {
    final scanning =
        kioskService.enrolledSignatures.isNotEmpty &&
        _status.contains('Look at the camera');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (scanning)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: KioskColors.primaryLight,
              ),
            )
          else
            const Icon(
              Icons.face_retouching_natural,
              size: 16,
              color: KioskColors.primaryLight,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Animated oval face guide with corner brackets + scanning line.
  /// The kiosk remains locked to portrait; the guide stays upright to match the
  /// user’s natural device orientation and avoid distorted face capture.
  Widget _buildFaceGuide() {
    return _faceGuideContent();
  }

  Widget _faceGuideContent() {
    const guideW = 260.0;
    const guideH = 320.0;
    final accent = _lastSuccess
        ? KioskColors.success
        : (_resultHold ? KioskColors.error : KioskColors.primaryLight);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        final t = _pulseAnim.value;
        final glow = 0.35 + (t * 0.35);
        return SizedBox(
          width: guideW,
          height: guideH,
          child: Stack(
            children: [
              // Oval guide.
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(guideH / 2),
                    border: Border.all(
                      color: accent.withValues(alpha: glow + 0.3),
                      width: 3 + (t * 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: glow * 0.6),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              // Corner brackets.
              ..._cornerBrackets(accent, 26),
              // Scanning line.
              Positioned(
                left: 16,
                right: 16,
                top: 24 + (guideH - 48) * t,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        accent.withValues(alpha: 0.9),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Four L-shaped brackets at the corners of the face guide.
  List<Widget> _cornerBrackets(Color color, double len) {
    Widget bracket(double w, double h) => Container(
      width: len,
      height: len,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.9), width: 4),
          top: BorderSide(color: color.withValues(alpha: 0.9), width: 4),
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
      ),
    );

    return [
      Positioned(top: 0, left: 0, child: bracket(0, 0)),
      Positioned(
        top: 0,
        right: 0,
        child: Transform.rotate(
          angle: 1.5708, // 90°
          child: bracket(0, 0),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Transform.rotate(
          angle: 3.14159, // 180°
          child: bracket(0, 0),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Transform.rotate(
          angle: 4.71239, // 270°
          child: bracket(0, 0),
        ),
      ),
    ];
  }

  Widget _buildTopBar() {
    final c = KioskTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: c.cardShadow,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Exit',
              onPressed: _exit,
              icon: Icon(Icons.close, color: c.textSecondary),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 26,
                height: 26,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TT STAFF PRO',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    kioskSettings.companyName ?? 'Face Attendance Kiosk',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: _isTorchOn ? 'Turn flashlight off' : 'Turn flashlight on',
              onPressed: _toggleTorch,
              icon: Icon(
                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                color: _isTorchOn ? Colors.amber : c.textSecondary,
              ),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: KioskColors.primaryLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.face, size: 14, color: KioskColors.primaryLight),
                  const SizedBox(width: 4),
                  Text(
                    '$_scanCount',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// Success / failure card shown over the framed camera — matches the
  /// "Face Verified / Attendance Marked / Welcome {name}!" result card on the
  /// product poster.
  Widget _buildResultCard() {
    final color = _lastSuccess ? KioskColors.success : KioskColors.error;
    // Live timestamp, matching the "Face Verified / Attendance Marked" poster.
    final timeStr = DateFormat('hh:mm a').format(DateTime.now());
    final title = _lastSuccess ? 'Face Verified' : 'Face Not Verified';
    final subtitle = _lastSuccess ? 'Attendance Marked' : (_lastAction ?? '');

    return GestureDetector(
      onTap: _dismissResultNow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.88)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _lastSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 38,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              _lastSuccess
                  ? 'Welcome ${_lastEmployeeName ?? ''}'
                  : (_lastEmployeeName ?? ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (_lastSuccess &&
                _lastEmployeeCode != null &&
                _lastEmployeeCode!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ID / Roll No: $_lastEmployeeCode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app_rounded, size: 12, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(
                    'Next scan in ${_resultSecondsLeft}s • Tap to skip',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    // The camera plugin's CameraPreview already applies the correct rotation
    // and aspect ratio for the locked portrait orientation. Wrapping it in an
    // extra RotatedBox based on the raw sensor orientation double-rotated the
    // image, which made upright faces appear lying sideways in the live view.
    return CameraPreview(_cameraController!);
  }
}

/// A vertical gradient scrim used to keep UI legible over the camera.
class _ScanScrim extends StatelessWidget {
  final Alignment alignment;
  const _ScanScrim({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final fromTop = alignment == Alignment.topCenter;
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: Alignment.center,
            colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
          ),
        ),
      ),
    );
  }
}
