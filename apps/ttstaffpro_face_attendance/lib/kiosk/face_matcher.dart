import 'dart:io';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Signature of a face used for lightweight on-device matching.
///
/// Uses normalized landmark distances so it is scale-invariant. This is a
/// pragmatic client-side matcher; the server remains the source of truth for
/// authoritative recognition (it has the full enrolled profile images).
class FaceSignature {
  final double leftRightEye;
  final double noseToLeftEye;
  final double noseToRightEye;
  final double mouthWidth;
  final double noseToMouth;
  final double eyeToMouth;
  final double leftEyeOpen;
  final double rightEyeOpen;

  FaceSignature({
    required this.leftRightEye,
    required this.noseToLeftEye,
    required this.noseToRightEye,
    required this.mouthWidth,
    required this.noseToMouth,
    required this.eyeToMouth,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
  });

  /// Euclidean distance between two signatures (0 = identical).
  double distanceTo(FaceSignature other) {
    final dx = leftRightEye - other.leftRightEye;
    final dy = noseToLeftEye - other.noseToLeftEye;
    final dz = noseToRightEye - other.noseToRightEye;
    final dw = mouthWidth - other.mouthWidth;
    final du = noseToMouth - other.noseToMouth;
    final dv = eyeToMouth - other.eyeToMouth;
    return math.sqrt(dx * dx + dy * dy + dz * dz + dw * dw + du * du + dv * dv);
  }

  /// Checks liveness using the eye-open probabilities.
  bool get isLive =>
      (leftEyeOpen > 0.45 && rightEyeOpen > 0.45);
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

  /// Detects faces in a captured file and returns the first face.
  Future<Face?> detectInFile(String path) async {
    final input = InputImage.fromFilePath(path);
    final faces = await _detector.processImage(input);
    return faces.isEmpty ? null : faces.first;
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

    // Reference distance: eyes, falls back to face width to avoid div-by-zero.
    final eyeDist = d(leftEye, rightEye);
    final ref = eyeDist > 0 ? eyeDist : math.max(face.boundingBox.width, 1);

    return FaceSignature(
      leftRightEye: eyeDist / ref,
      noseToLeftEye: d(nose, leftEye) / ref,
      noseToRightEye: d(nose, rightEye) / ref,
      mouthWidth: d(mouthLeft, mouthRight) / ref,
      noseToMouth: (d(nose, mouthLeft) + d(nose, mouthRight)) / (2 * ref),
      eyeToMouth: (d(leftEye, mouthLeft) + d(rightEye, mouthRight)) / (2 * ref),
      leftEyeOpen: face.leftEyeOpenProbability ?? 0,
      rightEyeOpen: face.rightEyeOpenProbability ?? 0,
    );
  }

  /// Finds the best enrolled signature match above [threshold].
  ///
  /// Returns the employeeId and similarity distance, or null when no match.
  ({int employeeId, double distance})? bestMatch(
    FaceSignature live,
    Map<int, FaceSignature> enrolled, {
    double threshold = 0.32,
  }) {
    ({int id, double distance})? best;
    for (final entry in enrolled.entries) {
      final dist = live.distanceTo(entry.value);
      if (dist <= threshold) {
        if (best == null || dist < best.distance) {
          best = (id: entry.key, distance: dist);
        }
      }
    }
    return best == null ? null : (employeeId: best.id, distance: best.distance);
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
