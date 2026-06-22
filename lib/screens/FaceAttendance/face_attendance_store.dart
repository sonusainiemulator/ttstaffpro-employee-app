import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_core_hr/api/dio_api/repositories/face_attendance_repository.dart';
import 'face_attendance_screen.dart'; // To access LocalFaceData

class FaceEnrollmentStore {
  final FaceAttendanceRepository _repository = FaceAttendanceRepository();

  Future<bool> isEnrolled() async {
    try {
      final eligibility = await _repository.checkSelfEligibility();
      return eligibility.hasExistingProfile == true;
    } catch (e) {
      print("Error fetching enrollment eligibility: $e");
      return false;
    }
  }

  /// Sends the enrollment data (multiple face images and capture types) to the server.
  Future<bool> submitRegistration({
    required List<String> imagePaths,
    required List<String> captureTypes,
    String? notes,
  }) async {
    try {
      return await _repository.submitSelfRegistration(
        imagePaths: imagePaths,
        captureTypes: captureTypes,
        notes: notes,
      );
    } catch (e) {
      print("Error sending enrollment: $e");
      return false;
    }
  }

  /// Gets the enrollment data from the server.
  Future<LocalFaceData?> getEnrollment() async {
    try {
      final status = await _repository.getSelfProfileStatus();
      if (status.images == null || status.images!.isEmpty) {
        return null;
      }

      // Find the front image if possible, otherwise use the first one
      final frontImage = status.images!.firstWhere(
        (img) => img.captureType == 'front',
        orElse: () => status.images!.first,
      );

      final imageUrl = frontImage.imageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }

      // Download the image and fix its orientation.
      final imagePath = await _downloadImage(imageUrl);

      // Re-run face detection on the fixed image to get updated landmarks.
      final inputImage = InputImage.fromFilePath(imagePath);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true,
          enableContours: false,
        ),
      );
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isNotEmpty) {
        final face = faces.first;
        final landmarkMap = <FaceLandmarkType, Point<int>>{};
        for (final type in FaceLandmarkType.values) {
          final lm = face.landmarks[type];
          if (lm != null) {
            landmarkMap[type] = lm.position;
          }
        }
        return LocalFaceData(imagePath: imagePath, landmarks: landmarkMap);
      }
      return null;
    } catch (e) {
      print("Error fetching enrollment: $e");
      return null;
    }
  }

  /// Helper: Download image from a URL and save it locally.
  Future<String> _downloadImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    final bytes = response.bodyBytes;
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/downloaded_enrollment.jpg';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    // Rotate the image correctly using flutter_exif_rotation.
    final fixedFile = await FlutterExifRotation.rotateImage(path: file.path);

    return fixedFile.path;
  }
}
