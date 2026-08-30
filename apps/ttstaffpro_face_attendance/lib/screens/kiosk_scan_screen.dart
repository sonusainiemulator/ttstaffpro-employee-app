import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _lastAction;
  bool _lastSuccess = false;
  int _scanCount = 0;

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

      final face = await _matcher.detectInFile(path);
      if (face == null) {
        if (mounted) {
          setState(() => _status = 'No face detected. Align within the frame.');
        }
        return;
      }

      final signature = _matcher.signatureOf(face);
      if (!signature.isLive) {
        if (mounted) {
          setState(
            () => _status = 'Please open your eyes and look at the camera.',
          );
        }
        return;
      }

      _scanCount++;
      if (!mounted) return;

      final match = kioskService.enrolledSignatures.isNotEmpty
          ? _matcher.bestMatch(signature, kioskService.enrolledSignatures)
          : null;

      if (match != null) {
        await _handleMatch(
          employeeId: match.employeeId,
          distance: match.distance,
          snapshotPath: path,
        );
      } else {
        // No local match — let the server try, or log an unknown event.
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
    required String snapshotPath,
  }) async {
    final name =
        kioskService.employeeNames[employeeId] ?? 'Employee $employeeId';
    setState(() => _status = 'Verifying $name...');

    final result = await kioskService.uploadEvent(
      eventUuid: const Uuid().v4(),
      eventType: 'attendance',
      employeeId: employeeId,
      recognitionStatus: 'matched',
      confidenceScore: (1 - distance).clamp(0, 1),
      snapshotPath: snapshotPath,
    );

    if (!mounted) return;
    if (result != null) {
      _showResult(
        success: true,
        name: name,
        action: result.attendanceAction ?? 'attendance updated',
      );
    } else {
      // Offline — queued for sync.
      _showResult(success: true, name: name, action: 'saved offline');
    }
  }

  Future<void> _handleUnknown(String snapshotPath) async {
    setState(() => _status = 'Scanning...');
    final result = await kioskService.uploadEvent(
      eventUuid: const Uuid().v4(),
      eventType: 'attendance',
      recognitionStatus: 'unknown',
      snapshotPath: snapshotPath,
    );

    if (!mounted) return;
    if (result != null && result.attendanceId != null) {
      _showResult(
        success: true,
        name: result.message ?? 'Attendance recorded',
        action: result.attendanceAction ?? 'ok',
      );
    } else if (result != null && (result.attendanceId == null)) {
      // Server processed but no attendance record (e.g. face not registered).
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

  /// Shows a result overlay for ~2.6s, then automatically re-arms the scanner.
  void _showResult({
    required bool success,
    required String name,
    required String action,
  }) {
    setState(() {
      _resultHold = true;
      _lastSuccess = success;
      _lastEmployeeName = name;
      _lastAction = action;
    });
    Timer(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      setState(() {
        _resultHold = false;
        _lastEmployeeName = null;
        _lastAction = null;
        _status = kioskService.enrolledSignatures.isEmpty
            ? 'Waiting for face...'
            : 'Look at the camera to check in / out';
      });
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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed camera preview (or standby message).
          if (_isCameraInitialized && _cameraController != null)
            _buildPreview()
          else
            _buildStandby(),
          // Legibility scrims (top + bottom).
          const _ScanScrim(alignment: Alignment.topCenter),
          const _ScanScrim(alignment: Alignment.bottomCenter),
          // Animated face guide.
          Center(child: _buildFaceGuide()),
          // Top bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildTopBar()),
          ),
          // Bottom: status bar OR result card.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _resultHold ? _buildResultCard() : _buildStatusBar(),
                    const KioskVersionFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Standby state before the camera is ready (or when it is unavailable).
  Widget _buildStandby() {
    final c = KioskTheme.of(context);
    return Container(
      color: c.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.face_retouching_natural,
              size: 64,
              color: KioskColors.primaryLight,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _status,
                style: TextStyle(color: c.textSecondary, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Exit',
              onPressed: _exit,
              icon: const Icon(Icons.close, color: Colors.white70),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kioskSettings.companyName ?? 'TT Staff Pro',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Face Attendance',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.face, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    '$_scanCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
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

  /// Live status pill shown while scanning (no result on screen).
  Widget _buildStatusBar() {
    final scanning =
        kioskService.enrolledSignatures.isNotEmpty &&
        _status.contains('Look at the camera');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (scanning)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: KioskColors.primaryLight,
              ),
            )
          else
            Icon(
              Icons.face_retouching_natural,
              size: 18,
              color: KioskColors.primaryLight,
            ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _status,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final color = _lastSuccess ? KioskColors.success : KioskColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _lastSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            _lastEmployeeName ?? '',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            _lastAction ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final controller = _cameraController!;
    return OrientationBuilder(
      builder: (context, orientation) {
        // Front-camera sensor is landscape; in portrait it is rotated to
        // display upright based on the device's sensor orientation (a fixed 3
        // only matches devices whose sensor reports 270°). In landscape the
        // preview already matches the screen.
        final turns = orientation == Orientation.portrait
            ? (controller.description.sensorOrientation / 90).round() % 4
            : 0;
        return RotatedBox(
          quarterTurns: turns,
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        );
      },
    );
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
