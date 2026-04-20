import 'package:dio/dio.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../utils/app_constants.dart';
import '../../../main.dart';

/// Interceptor to handle authentication and tenant context
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getStringAsync(tokenPref);
    final tenantId = getStringAsync(tenantPref);

    if (token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add tenant ID header for SaaS mode
    if (getIsSaaSMode() && tenantId.isNotEmpty) {
      options.headers['X-Tenant-ID'] = tenantId;
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      log('Auth Error (401): ${err.requestOptions.path}');
      log('Token used: ${err.requestOptions.headers['Authorization']}');
      log('Tenant used: ${err.requestOptions.headers['X-Tenant-ID']}');
      
      // Handle unauthorized access by logging out
      sharedHelper.logoutAlt();
    }
    super.onError(err, handler);
  }
}