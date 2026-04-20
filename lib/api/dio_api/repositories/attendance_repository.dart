import 'package:open_core_hr/api/api_routes.dart';
import 'package:open_core_hr/api/result.dart';
import 'package:open_core_hr/models/status/status_response.dart';
import '../base_repository.dart';

/// Repository for attendance related API calls using Dio.
class AttendanceRepository extends BaseRepository {
  /// Check current attendance status from GET /attendance/checkStatus.
  Future<StatusResponse?> checkAttendanceStatus() async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.checkAttendanceStatus),
      parser: (data) {
        final body = data['data'] as Map<String, dynamic>? ?? data as Map<String, dynamic>;
        return StatusResponse.fromJson(body);
      },
      showError: false,
    );
  }

  /// Start or stop break from POST /attendance/startStopBreak.
  Future<bool> startStopBreak() async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.startStopBreak, data: {}),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Check in or check out from POST /attendance/checkInOut.
  Future<Result> checkInOut(Map<String, dynamic> req) async {
    try {
      await safeApiCall(
        () => dioClient.post(APIRoutes.checkInOut, data: req),
        showError: true,
      );
      return Result()
        ..isSuccess = true
        ..message = 'Success';
    } catch (e) {
      return Result()
        ..isSuccess = false
        ..message = e.toString();
    }
  }

  /// Verify static QR code
  Future<bool> verifyQr(String code) async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.verifyQr, data: code),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Verify dynamic QR code
  Future<bool> verifyDynamicQr(String code) async {
    return await safeApiCall(
      () => dioClient.post(APIRoutes.verifyDynamicQr, data: {'code': code}),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Validate IP address 
  Future<bool> validateIpAddress(String ip) async {
    return await safeApiCall(
      () => dioClient.get(APIRoutes.validateIpAddress, queryParameters: {'ipAddress': ip}),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Validate Geofence 
  Future<bool> validateGeofence(double lat, double long) async {
     return await safeApiCall(
      () => dioClient.get(APIRoutes.validateGeoLocation, queryParameters: {
        'latitude': lat.toString(),
        'longitude': long.toString(),
      }),
      parser: (data) => true,
      showError: true,
    );
  }

  /// Set early checkout reason
  Future<bool> setEarlyCheckoutReason(String reason) async {
     return await safeApiCall(
      () => dioClient.post(APIRoutes.setEarlyCheckoutReason, data: reason),
      parser: (data) => true,
      showError: true,
    );
  }
}

