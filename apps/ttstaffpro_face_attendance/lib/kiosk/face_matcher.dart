import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Matching calibration
// ---------------------------------------------------------------------------
//
// The local matcher compares normalized facial-proportion ratios (distances
// between ML Kit landmarks, each divided by the inter-ocular distance). Those
// ratios are similar for all adult faces, so the identity distance between two
// *different* people is only marginally larger than the distance between two
// captures of the *same* person. Tuning is therefore conservative:
//
//  * kMatchThreshold  - a live face is only matched when it is *very* close to
//    an enrolled signature (≈ the typical inter-person distance is ~2x this).
//  * kMatchMargin     - the nearest enrolled face must also be clearly closer
//    than the second-nearest. When two enrolled employees are both "close" the
//    scan is treated as ambiguous and rejected — this is what stops random
//    faces being accepted as *someone*.
//  * Frontal gate     - only frontal faces (small yaw/pitch/roll) are matched;
//    side profiles and angled shots are rejected instead of mis-identified.
//  * Liveness gate    - both eyes must be open before an event is recorded.
//
// These values were calibrated with a Monte-Carlo simulation of enrolled
// galleries + live probes. The simulator showed the previous hard threshold of
// 0.32 accepted essentially every face (impostor accept rate ≈ 100 %), which
// was the "all face scans are accepted" bug. The values below keep the
// impostor accept rate in the low single digits while a genuine user is
// typically matched within a few scan frames (the kiosk rescans every 1.8 s).

/// Max identity distance (weighted Euclidean, 0 = identical) to accept a match.
const double kMatchThreshold = 0.08;

/// The best match must be at most 1/kMatchMargin as far as the second best.
const double kMatchMargin = 1.30;

/// Frontal-pose limits (degrees). Outside these the face is rejected.
const double kMaxYaw = 18;
const double kMaxPitch = 15;
const double kMaxRoll = 18;

/// Minimum eye-open probability for a "live" face.
const double kMinEyeOpen = 0.45;

/// Per-feature reliability weights (used by [FaceSignature.distanceTo]).
const List<double> _kFeatureWeights = [
  1.0, // noseToLeftEye
  1.0, // noseToRightEye
  1.0, // mouthWidth
  1.0, // noseToMouthL
  1.0, // noseToMouthR
  1.0, // eyeToMouthL
  1.0, // eyeToMouthR
  0.5, // mouthToChin (small, noisy)
  0.7, // cheekWidth
  0.5, // earToEar (noisy in frontal view)
  0.6, // faceWidthRatio
  0.6, // faceHeightRatio
];

/// Signature of a face used for lightweight on-device matching.
///
/// Uses normalized landmark distances so it is scale-invariant. Pose angles
/// and eye-open probabilities are carried for the frontal / liveness gates and
/// are NOT part of the identity distance.
class FaceSignature {
  /// Normalized facial-proportion ratios (each divided by inter-ocular dist).
  final List<double> features;

  final double leftEyeOpen;
  final double rightEyeOpen;

  /// Head pose in degrees (headEulerAngleY / X / Z from ML Kit).
  final double yaw;
  final double pitch;
  final double roll;

  FaceSignature({
    required this.features,
    this.leftEyeOpen = 1,
    this.rightEyeOpen = 1,
    this.yaw = 0,
    this.pitch = 0,
    this.roll = 0,
  }) {
    assert(features.length == _kFeatureWeights.length,
        'Expected ${_kFeatureWeights.length} features, got ${features.length}');
  }

  /// Weighted Euclidean distance between two signatures (0 = identical).
  double distanceTo(FaceSignature other) {
    final n = math.min(features.length, other.features.length);
    var s = 0.0;
    var wSum = 0.0;
    for (var i = 0; i < n; i++) {
      final w = _kFeatureWeights[i];
      final dx = features[i] - other.features[i];
      s += w * dx * dx;
      wSum += w;
    }
    return wSum == 0 ? double.infinity : math.sqrt(s / wSum);
  }

  /// Both eyes open (liveness check).
  bool get isLive => leftEyeOpen > kMinEyeOpen && rightEyeOpen > kMinEyeOpen;

  /// Face is (approximately) facing the camera.
  bool get isFrontal =>
      yaw.abs() <= kMaxYaw && pitch.abs() <= kMaxPitch && roll.abs() <= kMaxRoll;
}

/// Wraps the ML Kit face detector and provides matching utilities.
class FaceMatcher {
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
      enableContours: false,
    ),
  );

  /// Detects all faces in a captured file.
  Future<List<Face>> detectFaces(String path) async {
    final input = InputImage.fromFilePath(path);
    return _detector.processImage(input);
  }

  /// Detects faces in a captured file and returns the first face.
  Future<Face?> detectInFile(String path) async {
    final faces = await detectFaces(path);
    return faces.isEmpty ? null : faces.first;
  }

  /// Whether the detected face carries enough landmark information to build a
  /// meaningful signature (both eyes + nose + mouth corners must be present).
  bool hasUsableLandmarks(Face face) {
    final lm = face.landmarks;
    final present = <FaceLandmarkType>[
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
    ].where((t) => lm[t]?.position != null).length;
    return present >= 5 && face.boundingBox.width > 0;
  }

  /// Builds a normalized signature from a detected face.
  FaceSignature signatureOf(Face face) {
    double d(Point<int>? a, Point<int>? b) {
      if (a == null || b == null) return 0;
      return math.sqrt(
        math.pow(a.x - b.x, 2).toDouble() +
            math.pow(a.y - b.y, 2).toDouble(),
      );
    }

    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final mouthRight = face.landmarks[FaceLandmarkType.rightMouth]?.position;
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;
    final leftEar = face.landmarks[FaceLandmarkType.leftEar]?.position;
    final rightEar = face.landmarks[FaceLandmarkType.rightEar]?.position;

    // Reference distance: inter-ocular distance; falls back to face width so
    // we never divide by zero.
    final eyeDist = d(leftEye, rightEye);
    final ref =
        eyeDist > 0 ? eyeDist : math.max(face.boundingBox.width, 1).toDouble();

    return FaceSignature(
      features: <double>[
        d(nose, leftEye) / ref,
        d(nose, rightEye) / ref,
        d(mouthLeft, mouthRight) / ref,
        d(nose, mouthLeft) / ref,
        d(nose, mouthRight) / ref,
        d(leftEye, mouthLeft) / ref,
        d(rightEye, mouthRight) / ref,
        d(mouthLeft, mouthBottom) / ref,
        d(leftCheek, rightCheek) / ref,
        d(leftEar, rightEar) / ref,
        face.boundingBox.width / ref,
        face.boundingBox.height / ref,
      ],
      leftEyeOpen: face.leftEyeOpenProbability ?? 0,
      rightEyeOpen: face.rightEyeOpenProbability ?? 0,
      yaw: face.headEulerAngleY ?? 0,
      pitch: face.headEulerAngleX ?? 0,
      roll: face.headEulerAngleZ ?? 0,
    );
  }

  /// Strict identity match against the enrolled gallery.
  ///
  /// Returns the employeeId plus its distance and confidence only when:
  ///  1. the live face is live (eyes open) and frontal ([requireFrontal]),
  ///  2. the nearest enrolled signature is within [threshold], and
  ///  3. it is clearly closer than the second-nearest ([marginRatio]).
  ///
  /// Returns null otherwise (unknown person, ambiguous, side profile, ...).
  ({int employeeId, double distance, double confidence})? identify(
    FaceSignature live,
    Map<int, FaceSignature> enrolled, {
    double threshold = kMatchThreshold,
    double marginRatio = kMatchMargin,
    bool requireFrontal = true,
    bool requireLive = true,
  }) {
    if (enrolled.isEmpty) return null;
    if (requireLive && !live.isLive) return null;
    if (requireFrontal && !live.isFrontal) return null;

    final dists = enrolled.entries
        .map((e) => (id: e.key, d: live.distanceTo(e.value)))
        .toList()
      ..sort((a, b) => a.d.compareTo(b.d));

    final best = dists.first;
    if (best.d > threshold) return null;

    if (dists.length > 1) {
      final second = dists[1].d;
      // Reject when the second-nearest is not clearly farther away.
      if (second < best.d * marginRatio) return null;
    }

    final confidence = (1 - best.d).clamp(0.0, 1.0);
    return (employeeId: best.id, distance: best.d, confidence: confidence);
  }

  void close() => _detector.close();
}

/// Downloads a file from [url] into the app documents directory and returns
/// its local path. Used to fetch the enrolled profile snapshots for matching.
Future<String> downloadToDocuments(String url, String fileName) async {
  final uri = Uri.parse(url);
  final client = http.Client();
  try {
    final res = await client.get(uri);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes);
    return file.path;
  } finally {
    client.close();
  }
}
