import '../base_repository.dart';
import '../../api_routes.dart';
import 'package:flutter/foundation.dart';
import '../../../models/Document/document_request_model.dart';
import '../../../models/Document/document_type_model.dart';

/// Repository for Document Requests API
/// Handles all employee document request operations
class DocumentRequestRepository extends BaseRepository {
  /// Get all document requests for the authenticated employee
  Future<Map<String, dynamic>?> getMyDocumentRequests({
    String? status,
    int? documentTypeId,
    String? date,
    int page = 1,
    int perPage = 15,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };

    if (status != null) queryParams['status'] = status;
    if (documentTypeId != null) {
      queryParams['document_type_id'] = documentTypeId;
    }
    if (date != null) queryParams['date'] = date;

    return await safeApiCall(
      () => dioClient.get('document-requests', queryParameters: queryParams),
      parser: (data) {
        final responseData = data['data'];
        final documentRequests = responseData['document_requests'];
        final meta = documentRequests['meta'];

        return {
          'data': (documentRequests['data'] as List? ?? [])
              .map((item) => DocumentRequestModel.fromJson(item))
              .toList(),
          'current_page': meta['current_page'] ?? 1,
          'last_page': meta['last_page'] ?? 1,
          'total': meta['total'] ?? 0,
          'per_page': meta['per_page'] ?? 15,
        };
      },
    );
  }

  /// Get statistics for my document requests
  Future<DocumentRequestStatistics?> getMyStatistics() async {
    return await safeApiCall(
      () => dioClient.get('document-requests/statistics'),
      parser: (data) {
        return DocumentRequestStatistics.fromJson(
          data['data']['statistics'],
        );
      },
    );
  }

  /// Get available document types for requesting
  Future<List<DocumentTypeModel>> getAvailableDocumentTypes() async {
    // Prefer new endpoint, then gracefully fallback to legacy endpoint/shape.
    try {
      if (kDebugMode) {
        debugPrint('[DocumentTypes] Trying endpoint: document-requests/document-types');
      }
      return await safeApiCall(
        () => dioClient.get('document-requests/document-types'),
        parser: (data) {
          final dynamic root = data['data'];
          final List rawList = (root is Map<String, dynamic>)
              ? (root['document_types'] as List? ?? [])
              : (root as List? ?? []);

          if (kDebugMode) {
            debugPrint('[DocumentTypes] New endpoint success. Raw count: ${rawList.length}');
          }

          return rawList
              .whereType<Map>()
              .map((item) => DocumentTypeModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id != null)
              .toList();
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DocumentTypes] New endpoint failed: $e');
        debugPrint('[DocumentTypes] Falling back to endpoint: ${APIRoutes.getDocumentTypesURL}');
      }
      return await safeApiCall(
        () => dioClient.get(APIRoutes.getDocumentTypesURL),
        parser: (data) {
          final List rawList = data['data'] as List? ?? [];
          if (kDebugMode) {
            debugPrint('[DocumentTypes] Legacy endpoint success. Raw count: ${rawList.length}');
          }
          return rawList
              .whereType<Map>()
              .map((item) => DocumentTypeModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.id != null)
              .toList();
        },
      );
    }
  }

  /// Request a new document
  Future<DocumentRequestModel?> requestDocument({
    required int documentTypeId,
    String? remarks,
  }) async {
    try {
      return await safeApiCall(
        () => dioClient.post('document-requests', data: {
          'document_type_id': documentTypeId,
          if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks,
        }),
        parser: (data) {
          return DocumentRequestModel.fromJson(
            data['data']['document_request'],
          );
        },
      );
    } catch (_) {
      return await safeApiCall(
        () => dioClient.post(APIRoutes.createDocumentRequestURL, data: {
          'typeId': documentTypeId,
          'comments': remarks ?? '',
        }),
        parser: (data) {
          final dynamic responseData = data['data'];
          if (responseData is Map<String, dynamic>) {
            return DocumentRequestModel.fromJson(responseData);
          }
          return DocumentRequestModel(
            id: 0,
            status: 'pending',
            requestedDate: DateTime.now().toIso8601String(),
          );
        },
      );
    }
  }

  /// Get single document request details
  Future<DocumentRequestModel?> getDocumentRequest(int id) async {
    return await safeApiCall(
      () => dioClient.get('document-requests/$id'),
      parser: (data) {
        return DocumentRequestModel.fromJson(data['data']);
      },
    );
  }

  /// Cancel a pending document request
  Future<bool> cancelDocumentRequest(int id) async {
    final response = await safeApiCallWithResponse(
      () => dioClient.post('document-requests/$id/cancel'),
    );
    return response?.status == 'success';
  }

  /// Get download URL for generated document
  Future<Map<String, String>?> getDownloadUrl(int id) async {
    return await safeApiCall(
      () => dioClient.get('document-requests/$id/download'),
      parser: (data) {
        final downloadData = data['data'];
        return {
          'file_url': downloadData['file_url'] ?? '',
          'file_name': downloadData['file_name'] ?? '',
        };
      },
    );
  }

  /// Download document file
  Future<void> downloadDocument({
    required int id,
    required String savePath,
    Function(int, int)? onProgress,
  }) async {
    final downloadInfo = await getDownloadUrl(id);
    if (downloadInfo == null || downloadInfo['file_url'] == null) {
      throw Exception('Download URL not available');
    }

    await dioClient.downloadFile(
      downloadInfo['file_url']!,
      savePath,
      onReceiveProgress: onProgress,
    );
  }
}
