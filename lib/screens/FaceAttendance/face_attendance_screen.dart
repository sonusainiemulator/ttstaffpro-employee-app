import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';

import '../../main.dart';
import 'blink_eyes.dart';
import 'face_attendance_store.dart';

/// A naive storage for “enrolled” face data
class LocalFaceData {
  // Path of captured face image
  String? imagePath;
  // Landmarks for naive matching
  Map<FaceLandmarkType, Point<int>>? landmarks;

  LocalFaceData({this.imagePath, this.landmarks});
}

class FaceAttendanceScreen extends StatefulWidget {
  const FaceAttendanceScreen({super.key});

  @override
  State<FaceAttendanceScreen> createState() => _FaceAttendanceScreenState();
}

class _FaceAttendanceScreenState extends State<FaceAttendanceScreen> {
  // Camera
  late List<CameraDescription> _cameras;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // ML Kit FaceDetector
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // needed for eyeOpenProbability, smilingProbability
      enableLandmarks: true,
      enableTracking: true,
      enableContours: false,
    ),
  );

  // Data for “enrolled” face
  LocalFaceData? _enrolledFace;

  // Captured images for multi-image V1 enrollment
  final List<String> _capturedImagePaths = [];
  final List<String> _captureTypes = ['front', 'left', 'right'];
  int _currentStep = 0; // 0 = front, 1 = left, 2 = right, 3 = ready to submit

  // Are we in “enroll” mode or “verify” mode?
  bool _enrollMode = true;

  // Status message
  String _infoText = "Loading face profile status...";

  // For a naive “liveness” check
  bool _livenessPassed = false;

  bool _isEnrolled = true;

  // Instance of our enrollment store using V1 APIs
  final FaceEnrollmentStore _store = FaceEnrollmentStore();

  @override
  void initState() {
    super.initState();
    // Keep the default mobile face-registration view in the user’s native
    // portrait orientation instead of rotating the camera preview.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initializeCamera();
    _loadEnrollOption();
    // Try to load enrollment from server (if already enrolled)
    _loadEnrollmentFromServer();
  }

  Future<void> _loadEnrollOption() async {
    _isEnrolled = await _store.isEnrolled();
    setState(() {
      if (!_isEnrolled) {
        _infoText = "Look straight into the camera and press 'Capture Front'.";
      }
    });
  }

  void _loadEnrollmentFromServer() async {
    final data = await _store.getEnrollment();
    if (data != null) {
      setState(() {
        _enrolledFace = data;
        _infoText = "Face enrolled. Press 'Verify Face' to verify.";
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  // Camera Initialization
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      setState(() {
        _infoText = "No camera found on this device.";
      });
      return;
    }

    // Use the front camera for face detection
    final frontCam = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _infoText = "Error initializing camera: $e";
      });
    }
  }

  /// Capture Face (Step-by-step)
  Future<void> _captureFaceStep() async {
    if (!_isCameraInitialized) return;
    try {
      final XFile file = await _cameraController!.takePicture();
      // Bake the EXIF rotation into the pixels so the saved/uploaded image is
      // upright on every device (some sensors return rotated pixels).
      final File uprightFile =
          await FlutterExifRotation.rotateImage(path: file.path);
      final inputImage = InputImage.fromFilePath(uprightFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _infoText = "No face detected. Please position your face inside the circle.";
        });
        return;
      }

      final face = faces.first;

      // Check naive liveness
      final bool isLive = _checkLiveness(face);
      _livenessPassed = isLive;

      if (!isLive) {
        setState(() {
          _infoText = "Liveness check failed! Make sure your eyes are open and look at the camera.";
        });
        return;
      }

      // Save image to a permanent location
      final savedPath = await _saveImageLocally(uprightFile);

      setState(() {
        _capturedImagePaths.add(savedPath);
        _currentStep++;
        if (_currentStep < 3) {
          final nextType = _captureTypes[_currentStep].toUpperCase();
          _infoText = "Captured ${_captureTypes[_currentStep - 1].toUpperCase()}! Now turn your face to the $nextType and press 'Capture $nextType'.";
        } else {
          _infoText = "All captures completed. Press 'Submit Face Registration'.";
        }
      });
    } catch (e) {
      setState(() {
        _infoText = "Capture error: $e";
      });
    }
  }

  /// Submit self registration to V1 API
  Future<void> _submitFaceRegistration() async {
    if (_capturedImagePaths.length < 3) return;
    setState(() {
      _infoText = "Uploading enrollment profiles to server...";
    });

    try {
      final success = await _store.submitRegistration(
        imagePaths: _capturedImagePaths,
        captureTypes: _captureTypes,
      );

      if (success) {
        setState(() {
          _isEnrolled = true;
          _enrollMode = false;
          _infoText = "Face registration submitted successfully! Press 'Verify Face' to verify.";
        });
        _loadEnrollOption();
        _loadEnrollmentFromServer();
      } else {
        setState(() {
          _infoText = "Upload failed. Please press the refresh icon to reset and try again.";
        });
      }
    } catch (e) {
      setState(() {
        _infoText = "Submission error: $e";
      });
    }
  }

  /// Verify Face
  Future<void> _verifyFace() async {
    if (!_isCameraInitialized) return;
    if (_enrolledFace == null) {
      setState(() {
        _infoText = "No enrolled face. Please capture first!";
      });
      return;
    }

    try {
      final XFile file = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          _infoText = "No face detected for verification. Try again.";
        });
        return;
      }

      final face = faces.first;

      // Check naive liveness again
      final bool isLive = _checkLiveness(face);
      if (!isLive) {
        setState(() {
          _infoText = "Verification failed, face not 'live' (eyes closed?).";
        });
        return;
      }

      // Landmarks for the new face
      final newLandmarks = <FaceLandmarkType, Point<int>>{};
      for (final type in FaceLandmarkType.values) {
        final lm = face.landmarks[type];
        if (lm != null) {
          newLandmarks[type] = lm.position;
        }
      }

      // Compare with enrolled face data naively
      final isMatch = _naiveCompareFaces(_enrolledFace!.landmarks!, newLandmarks);
      setState(() {
        if (isMatch) {
          _infoText = "Face MATCHED & Liveness OK! Attendance success!";
          toast('Face verified successfully');
          finish(context, true);
        } else {
          _infoText = "Face did NOT match!";
        }
      });
    } catch (e) {
      setState(() {
        _infoText = "Verification error: $e";
      });
    }
  }

  /// Save image to local document directory
  Future<String> _saveImageLocally(File file) async {
    final docDir = await getApplicationDocumentsDirectory();
    final newPath = '${docDir.path}/face_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newFile = await file.copy(newPath);
    return newFile.path;
  }

  /// Very naive method: if leftEyeOpen & rightEyeOpen > 0.5 => “live”
  bool _checkLiveness(Face face) {
    final leftProb = face.leftEyeOpenProbability ?? -1.0;
    final rightProb = face.rightEyeOpenProbability ?? -1.0;
    return (leftProb > 0.5 && rightProb > 0.5);
  }

  /// Naive face matching by comparing the distance between left & right eyes.
  bool _naiveCompareFaces(Map<FaceLandmarkType, Point<int>> enrolled,
      Map<FaceLandmarkType, Point<int>> current) {
    if (!enrolled.containsKey(FaceLandmarkType.leftEye) ||
        !enrolled.containsKey(FaceLandmarkType.rightEye) ||
        !current.containsKey(FaceLandmarkType.leftEye) ||
        !current.containsKey(FaceLandmarkType.rightEye)) {
      return false;
    }

    final leftEyeE = enrolled[FaceLandmarkType.leftEye]!;
    final rightEyeE = enrolled[FaceLandmarkType.rightEye]!;
    final distE = _distance(leftEyeE, rightEyeE);

    final leftEyeC = current[FaceLandmarkType.leftEye]!;
    final rightEyeC = current[FaceLandmarkType.rightEye]!;
    final distC = _distance(leftEyeC, rightEyeC);

    final ratio = distC / distE;
    return ratio > 0.9 && ratio < 1.1;
  }

  double _distance(Point<int> p1, Point<int> p2) {
    final dx = (p1.x - p2.x).toDouble();
    final dy = (p1.y - p2.y).toDouble();
    return sqrt(dx * dx + dy * dy);
  }

  // Keep the face-registration preview in the natural portrait orientation the
  // user expects. We intentionally do not auto-rotate the preview when the
  // device is held upright.
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Center(
        child: Text(
          _infoText,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    final ratio = _cameraController!.value.aspectRatio;
    return AspectRatio(
      aspectRatio: ratio,
      child: CameraPreview(_cameraController!),
    );
  }

  // The face outline overlay (oval).
  Widget _buildFaceOutline() {
    return Center(
      child: Container(
        width: 220,
        height: 270,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          border: Border.all(color: appStore.appColorPrimary, width: 3),
          borderRadius: BorderRadius.circular(150),
        ),
      ),
    );
  }

  // Row of captured thumbnails to show step-by-step progress
  Widget _buildCapturedThumbnails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final type = _captureTypes[index].toUpperCase();
          final hasImage = _capturedImagePaths.length > index;
          return Column(
            children: [
              Container(
                width: 70,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  border: Border.all(
                    color: _currentStep == index ? appStore.appColorPrimary : Colors.white24,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          File(_capturedImagePaths[index]),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Icon(
                          index == 0
                              ? Icons.face
                              : index == 1
                                  ? Icons.chevron_left
                                  : Icons.chevron_right,
                          color: Colors.white60,
                          size: 28,
                        ),
                      ),
              ),
              4.height,
              Text(
                type,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top AppBar row.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Face Attendance',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // Reset enrollment locally
                        setState(() {
                          _enrollMode = true;
                          _capturedImagePaths.clear();
                          _currentStep = 0;
                          _infoText = "Look straight into the camera and press 'Capture Front'.";
                          _enrolledFace = null;
                          _livenessPassed = false;
                        });
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Camera Preview area inside a rounded container.
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCameraPreview(),
                      _buildFaceOutline(),
                      if (!_livenessPassed) BlinkingEyes(),
                    ],
                  ),
                ),
              ),
              if (!_isEnrolled) _buildCapturedThumbnails(),
              // Information text container.
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _infoText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Buttons row.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (!_isEnrolled)
                      Expanded(
                        child: _currentStep < 3
                            ? ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrangeAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _captureFaceStep,
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Capture ${_captureTypes[_currentStep].toUpperCase()}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              )
                            : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _submitFaceRegistration,
                                icon: const Icon(
                                  Icons.cloud_upload,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Submit Face Registration",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                      ),
                    if (_isEnrolled)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _verifyFace,
                          icon: const Icon(
                            Icons.verified_user,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Verify Face",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
