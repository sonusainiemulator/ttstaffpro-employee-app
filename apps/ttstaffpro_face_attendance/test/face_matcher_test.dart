import 'dart:math' as math;
import 'dart:math' show Point;
import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:ttstaffpro_face_attendance/kiosk/face_matcher.dart';

/// Average human facial-proportion ratios (normalized to inter-ocular dist).
const List<double> _meanFeatures = <double>[
  1.00, // noseToLeftEye
  1.00, // noseToRightEye
  1.10, // mouthWidth
  0.95, // noseToMouthL
  0.95, // noseToMouthR
  1.10, // eyeToMouthL
  1.10, // eyeToMouthR
  0.42, // mouthToChin
  1.50, // cheekWidth
  2.05, // earToEar
  2.00, // faceWidth
  2.45, // faceHeight
];

/// Builds a signature from the mean face, adding [delta] to every feature
/// (a uniform delta produces a weighted distance of exactly [delta]).
FaceSignature sig({
  double delta = 0,
  double leftEyeOpen = 1,
  double rightEyeOpen = 1,
  double yaw = 0,
  double pitch = 0,
  double roll = 0,
}) {
  return FaceSignature(
    features: [for (final f in _meanFeatures) f + delta],
    leftEyeOpen: leftEyeOpen,
    rightEyeOpen: rightEyeOpen,
    yaw: yaw,
    pitch: pitch,
    roll: roll,
  );
}

void main() {
  final matcher = FaceMatcher();

  group('FaceSignature.distanceTo', () {
    test('identical signatures have distance 0', () {
      final s = sig();
      expect(s.distanceTo(s), 0);
      expect(s.distanceTo(sig()), 0);
    });

    test('a uniform feature delta equals the weighted distance', () {
      final a = sig(delta: 0.02);
      expect(sig().distanceTo(a), closeTo(0.02, 1e-9));
      final b = sig(delta: 0.10);
      expect(sig().distanceTo(b), closeTo(0.10, 1e-9));
    });

    test('same person (small delta) is much closer than a stranger', () {
      final stranger = sig(delta: 0.12);
      final genuine = sig(delta: 0.02);
      expect(genuine.distanceTo(sig()), lessThan(kMatchThreshold));
      expect(stranger.distanceTo(sig()), greaterThan(kMatchThreshold));
    });
  });

  group('FaceSignature gates', () {
    test('isLive requires both eyes open', () {
      expect(sig().isLive, isTrue);
      expect(sig(leftEyeOpen: 0.9, rightEyeOpen: 0.8).isLive, isTrue);
      expect(sig(leftEyeOpen: 0.1).isLive, isFalse);
      expect(sig(rightEyeOpen: 0.1).isLive, isFalse);
    });

    test('isFrontal rejects strong yaw / pitch / roll', () {
      expect(sig().isFrontal, isTrue);
      expect(sig(yaw: 10).isFrontal, isTrue);
      expect(sig(yaw: 30).isFrontal, isFalse);
      expect(sig(pitch: 20).isFrontal, isFalse);
      expect(sig(roll: 40).isFrontal, isFalse);
    });
  });

  group('FaceMatcher.identify', () {
    test('matches a genuine face to the right employee', () {
      // Two enrolled employees; the probe belongs to employee 1.
      final enrolled = <int, FaceSignature>{
        1: sig(),
        2: sig(delta: 0.25),
      };
      final probe = sig(delta: 0.02);

      final match = matcher.identify(probe, enrolled);
      expect(match, isNotNull);
      expect(match!.employeeId, 1);
      expect(match.distance, closeTo(0.02, 1e-9));
      expect(match.confidence, closeTo(0.98, 1e-9));
    });

    test('REGRESSION: a stranger is NOT accepted (all-faces-accepted bug)', () {
      final enrolled = <int, FaceSignature>{1: sig()};
      // Different person: features shifted ~12% → distance 0.12 > threshold.
      final stranger = sig(delta: 0.12);
      expect(stranger.distanceTo(sig()), greaterThan(kMatchThreshold));
      expect(matcher.identify(stranger, enrolled), isNull);
    });

    test('ambiguous face (two enrolled equally close) is rejected', () {
      final enrolled = <int, FaceSignature>{
        1: sig(),
        2: sig(delta: 0.06),
      };
      // Probe sits midway between the two enrolled signatures.
      final probe = sig(delta: 0.03);
      expect(probe.distanceTo(sig()), closeTo(0.03, 1e-9));
      expect(probe.distanceTo(sig(delta: 0.06)), closeTo(0.03, 1e-9));
      expect(matcher.identify(probe, enrolled), isNull);
    });

    test('rejects a side-profile even when features are a perfect match', () {
      final enrolled = <int, FaceSignature>{1: sig()};
      final probe = sig(delta: 0.0, yaw: 30);
      expect(matcher.identify(probe, enrolled), isNull);
    });

    test('rejects a closed-eye (non-live) face', () {
      final enrolled = <int, FaceSignature>{1: sig()};
      final probe = sig(delta: 0.0, leftEyeOpen: 0.1);
      expect(matcher.identify(probe, enrolled), isNull);
    });

    test('returns null for an empty gallery', () {
      expect(matcher.identify(sig(), <int, FaceSignature>{}), isNull);
    });

    test('honours an explicit threshold override', () {
      final enrolled = <int, FaceSignature>{1: sig()};
      final probe = sig(delta: 0.10); // distance 0.10
      expect(matcher.identify(probe, enrolled), isNull);
      expect(
        matcher.identify(
          probe,
          enrolled,
          threshold: 0.12,
          marginRatio: 1.0,
        ),
        isNotNull,
      );
    });

    test('honours marginRatio override (tighter margin rejects more)', () {
      final enrolled = <int, FaceSignature>{
        1: sig(),
        2: sig(delta: 0.05),
      };
      // Probe is close to employee 1 (0.02) but employee 2 is only 0.03 away.
      final probe = sig(delta: 0.02);
      // Default margin 1.30: second(0.03) < best(0.02)*1.30 (0.026)? No → accept.
      expect(matcher.identify(probe, enrolled)?.employeeId, 1);
      // Very tight margin 2.0: second(0.03) < best(0.02)*2.0 (0.04)? Yes → reject.
      expect(
        matcher.identify(probe, enrolled, marginRatio: 2.0),
        isNull,
      );
    });
  });

  group('FaceMatcher.signatureOf / hasUsableLandmarks', () {
    FaceLandmark lm(FaceLandmarkType t, Point<int> p) =>
        FaceLandmark(type: t, position: p);

    Face buildFace({
      bool eyes = true,
      bool nose = true,
      bool mouth = true,
    }) {
      return Face(
        boundingBox: Rect.fromLTWH(50, 50, 200, 250),
        landmarks: {
          FaceLandmarkType.leftEye:
              eyes ? lm(FaceLandmarkType.leftEye, const Point<int>(100, 100)) : null,
          FaceLandmarkType.rightEye:
              eyes ? lm(FaceLandmarkType.rightEye, const Point<int>(200, 100)) : null,
          FaceLandmarkType.noseBase:
              nose ? lm(FaceLandmarkType.noseBase, const Point<int>(150, 150)) : null,
          FaceLandmarkType.leftMouth:
              mouth ? lm(FaceLandmarkType.leftMouth, const Point<int>(130, 220)) : null,
          FaceLandmarkType.rightMouth:
              mouth ? lm(FaceLandmarkType.rightMouth, const Point<int>(170, 220)) : null,
        },
        contours: const {},
        headEulerAngleX: 0,
        headEulerAngleY: 0,
        headEulerAngleZ: 0,
        leftEyeOpenProbability: 1.0,
        rightEyeOpenProbability: 1.0,
      );
    }

    test('signatureOf normalizes landmark distances by inter-ocular distance', () {
      final s = matcher.signatureOf(buildFace());
      final ref = 100.0; // eye distance
      final noseToEye = math.sqrt(50 * 50 + 50 * 50) / ref;
      expect(s.features[0], closeTo(noseToEye, 1e-6)); // noseToLeftEye
      expect(s.features[1], closeTo(noseToEye, 1e-6)); // noseToRightEye
      expect(s.features[2], closeTo(40 / ref, 1e-6)); // mouthWidth
      expect(s.features[10], closeTo(2.0, 1e-6)); // faceWidth / ref
      expect(s.features[11], closeTo(2.5, 1e-6)); // faceHeight / ref
      expect(s.isFrontal, isTrue);
      expect(s.isLive, isTrue);
    });

    test('hasUsableLandmarks requires the key landmarks', () {
      expect(matcher.hasUsableLandmarks(buildFace()), isTrue);
      expect(matcher.hasUsableLandmarks(buildFace(eyes: false)), isFalse);
      expect(matcher.hasUsableLandmarks(buildFace(nose: false)), isFalse);
      expect(matcher.hasUsableLandmarks(buildFace(mouth: false)), isFalse);
    });
  });
}
