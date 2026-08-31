import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_core_hr/api/dio_api/exceptions/api_exceptions.dart';
import 'package:open_core_hr/models/face_attendance/kiosk_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../kiosk/kiosk_theme.dart';
import '../kiosk/kiosk_version_footer.dart';
import '../main.dart';
import 'company_login_screen.dart';

/// Kiosk admin face registration.
///
/// After the admin master login the operator can pick any employee of the
/// tenant and capture front / left / right face images. The profile is created
/// as active + approved, so it appears on the single face-scan screen for that
/// tenant (like a biometric device) and also works for the employee's own
/// mobile-app face scan.
class KioskRegisterFaceScreen extends StatefulWidget {
  const KioskRegisterFaceScreen({super.key});

  @override
  State<KioskRegisterFaceScreen> createState() =>
      _KioskRegisterFaceScreenState();
}

class _KioskRegisterFaceScreenState extends State<KioskRegisterFaceScreen> {
  // Phase A — employee picker.
  List<KioskEmployee> _employees = [];
  bool _loadingEmployees = true;
  String? _listError;
  bool _sessionError = false;
  KioskEmployee? _selected;

  // Phase B — face capture.
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _capturing = false;
  int _currentStep = 0; // 0=front, 1=left, 2=right
  final List<String> _capturedPaths = [];
  bool _uploading = false;
  bool _done = false;
  String _status = '';

  static const _steps = [
    (label: 'Front', icon: Icons.face_retouching_natural, type: 'front'),
    (label: 'Left', icon: Icons.rotate_left, type: 'left'),
    (label: 'Right', icon: Icons.rotate_right, type: 'right'),
  ];

  @override
  void dispose() {
    _cameraController?.dispose();
    // Keep the kiosk in portrait orientation for a consistent default view.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _loadingEmployees = true;
      _sessionError = false;
      _listError = null;
    });
    try {
      final employees = await kioskService.getEmployeesWithFaceStatus();
      if (!mounted) return;
      setState(() => _employees = employees);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sessionError = e is UnauthorizedException;
        _listError = _friendlyError(
          e,
          fallback: 'Could not load employees. Check connectivity.',
        );
      });
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  /// Maps an API exception to a message a kiosk operator can act on instead of
  /// hiding the real reason behind a generic connectivity message.
  String _friendlyError(Object e, {required String fallback}) {
    if (e is UnauthorizedException) {
      return 'Session expired. Please log in again.';
    }
    if (e is NetworkException || e is TimeoutException) {
      return 'Could not reach the server. Check connectivity and retry.';
    }
    if (e is ServerException) {
      return 'Server error. Please try again.';
    }
    if (e is ApiException && e.message.trim().isNotEmpty) {
      return e.message;
    }
    return fallback;
  }

  /// Clears the kiosk session and returns to the company login screen.
  Future<void> _goToLogin() async {
    await kioskSettings.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CompanyLoginScreen()),
      (route) => false,
    );
  }

  Future<void> _selectEmployee(KioskEmployee employee) async {
    // If this employee already has a registered face, surface it clearly
    // instead of letting the operator hit a confusing server error later.
    if (employee.faceRegistered == true) {
      final name =
          (employee.name ?? '').isNotEmpty ? employee.name! : 'this employee';
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Face already registered'),
          content: Text(
            '$name already has a registered face.\n\n'
            'Re-registering will replace the existing face. Do you want to '
            'continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Re-register'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _selected = employee);
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      setState(() => _status = 'Camera permission denied.');
      return;
    }
    await _initializeCamera();
    if (mounted && _isCameraInitialized) {
      setState(
        () => _status = 'Look straight at the camera and press capture.',
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _status = 'No camera found on this device.');
        return;
      }
      final frontCam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() => _status = 'Camera error: $e');
    }
  }

  /// Capture the current step. Requires a detectable face to accept the shot.
  Future<void> _capture() async {
    if (_capturing || !_isCameraInitialized || _cameraController == null) {
      return;
    }
    setState(() {
      _capturing = true;
      _status = 'Capturing ${_steps[_currentStep].label}...';
    });

    try {
      final file = await _cameraController!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/kiosk_enroll_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(file.path).copy(path);

      final face = await kioskService.matcher.detectInFile(path);
      if (face == null) {
        if (mounted) {
          setState(
            () =>
                _status = 'No face detected. Align within the frame and retry.',
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _capturedPaths.add(path);
        _currentStep++;
        if (_currentStep >= _steps.length) {
          _status = 'All captures done. Tap Register to save.';
        } else {
          _status =
              'Look ${_steps[_currentStep].label} and press capture again.';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _status = 'Capture failed, retrying...');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _register() async {
    if (_uploading || _selected == null) return;
    setState(() {
      _uploading = true;
      _status = 'Registering face...';
    });
    try {
      final ok = await kioskService.enrollFace(
        employeeId: _selected!.employeeId!,
        imagePaths: List.of(_capturedPaths),
        captureTypes: _steps.map((s) => s.type).toList(),
        notes: 'Registered from kiosk',
      );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _done = ok;
        _status = ok
            ? 'Face registered successfully!'
            : 'Registration failed. Please retry.';
      });

      if (ok) {
        // Return to the employee picker and reload so the just-registered
        // employee immediately shows "Registered" instead of staying stale.
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          _backToPicker();
          _loadEmployees();
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        // If the employee already has a registered face, tell the operator it
        // is a duplicate instead of a generic server error.
        _status = _selected?.faceRegistered == true
            ? 'Duplicate face — this employee is already registered.'
            : _friendlyError(
                e,
                fallback: 'Registration failed. Please retry.',
              );
      });
    }
  }

  void _backToPicker() {
    setState(() {
      _selected = null;
      _currentStep = 0;
      _capturedPaths.clear();
      _done = false;
      _status = '';
    });
    _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selected == null ? _buildEmployeePicker() : _buildCaptureScreen(),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase A — employee picker
  // ---------------------------------------------------------------------------

  Widget _buildEmployeePicker() {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    return Container(
      width: MediaQuery.sizeOf(context).width,
      height: MediaQuery.sizeOf(context).height,
      decoration: BoxDecoration(gradient: c.backgroundGradient),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: c.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Register Face',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loadingEmployees ? null : _loadEmployees,
                    icon: const Icon(Icons.refresh),
                    color: c.textSecondary,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Select an employee to register their face. They can then check '
                'in / out on this kiosk or with their mobile app.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loadingEmployees
                  ? const Center(child: CircularProgressIndicator())
                  : _listError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 56,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 12),
                            Text(_listError!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loadEmployees,
                              child: const Text('Retry'),
                            ),
                            if (_sessionError) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _goToLogin,
                                child: const Text('Log in again'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : _employees.isEmpty
                  ? Center(
                      child: Text(
                        'No active employees found.',
                        style: TextStyle(color: c.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _employees.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final emp = _employees[index];
                        return _EmployeeTile(
                          employee: emp,
                          onTap: () => _selectEmployee(emp),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 4),
            const KioskVersionFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phase B — camera capture + register
  // ---------------------------------------------------------------------------

  Widget _buildCaptureScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isCameraInitialized && _cameraController != null)
            _buildPreview()
          else
            Container(
              color: KioskTheme.of(context).background,
              child: const Center(child: CircularProgressIndicator()),
            ),
          // Scrims.
          const _CaptureScrim(alignment: Alignment.topCenter),
          const _CaptureScrim(alignment: Alignment.bottomCenter),
          // Top bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(child: _buildTopBar()),
          ),
          // Step indicator.
          Positioned(
            top: 110,
            left: 24,
            right: 24,
            child: _buildStepIndicator(),
          ),
          // Bottom: status + actions.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _done ? _buildDoneCard() : _buildCaptureActions(),
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

  Widget _buildPreview() {
    final controller = _cameraController!;
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: CameraPreview(controller),
    );
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
              tooltip: 'Back',
              onPressed: _uploading ? null : _backToPicker,
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selected?.name ?? 'Employee',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _selected?.email ?? '',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0)
            Container(
              width: 28,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: i <= _currentStep ? KioskColors.primary : Colors.white24,
            ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < _currentStep
                  ? KioskColors.success
                  : (i == _currentStep ? KioskColors.primary : Colors.white24),
            ),
            child: Center(
              child: i < _currentStep
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCaptureActions() {
    final ready = _currentStep >= _steps.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 14),
          if (!ready)
            SizedBox(
              width: 76,
              height: 76,
              child: FilledButton(
                onPressed: _capturing ? null : _capture,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  backgroundColor: KioskColors.primary,
                ),
                child: _capturing
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _steps[_currentStep].icon,
                        size: 34,
                        color: Colors.white,
                      ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _uploading ? null : _register,
                    icon: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(
                      _uploading ? 'Registering...' : 'Register Face',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: KioskColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _uploading ? null : _backToPicker,
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDoneCard() {
    final success = _done;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            success ? KioskColors.success : KioskColors.error,
            (success ? KioskColors.success : KioskColors.error).withValues(
              alpha: 0.8,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: Colors.white,
            size: 44,
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _backToPicker,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Register Another'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single employee row in the picker list.
class _EmployeeTile extends StatelessWidget {
  final KioskEmployee employee;
  final VoidCallback onTap;

  const _EmployeeTile({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = KioskTheme.of(context);
    final initial = (employee.name ?? '?').trim().isNotEmpty
        ? employee.name!.trim()[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
            boxShadow: c.cardShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: KioskColors.primary.withValues(alpha: 0.18),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: KioskColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name ?? 'Employee ${employee.employeeId}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [employee.code, employee.email]
                          .whereType<String>()
                          .where((s) => s.isNotEmpty)
                          .join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: c.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _FaceStatusChip(registered: employee.faceRegistered == true),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status caption shown under each employee: green “Face Registered”
/// when the employee already has an approved face profile, neutral
/// “Unregistered” otherwise.
class _FaceStatusChip extends StatelessWidget {
  final bool registered;

  const _FaceStatusChip({required this.registered});

  @override
  Widget build(BuildContext context) {
    final color = registered ? KioskColors.success : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            registered ? Icons.check_circle : Icons.person_off_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            registered ? 'Face Registered' : 'Unregistered',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A vertical gradient scrim for camera legibility.
class _CaptureScrim extends StatelessWidget {
  final Alignment alignment;
  const _CaptureScrim({required this.alignment});

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
