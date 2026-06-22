import 'package:open_core_hr/api/api_routes.dart';
import 'package:open_core_hr/api/dio_api/base_repository.dart';

class ProfileRepository extends BaseRepository {
  static final ProfileRepository _instance = ProfileRepository._internal();
  factory ProfileRepository() => _instance;
  ProfileRepository._internal();

  /// Update editable profile fields (phone, alternateNumber, address, gender).
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      await safeApiCall(
        () => dioClient.put(APIRoutes.updateProfile, data: data),
        showError: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Upload a new avatar image. Returns the new avatar URL on success.
  Future<String?> uploadAvatar(String filePath) async {
    try {
      final response = await dioClient.uploadFile(
        APIRoutes.uploadAvatar,
        filePath: filePath,
        fieldName: 'avatar',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          return (data['data']?['avatar'] ?? data['avatar'])?.toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
