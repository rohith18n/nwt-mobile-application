import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/auth/auth.dart';

class BseStorageService {
  static const String _tag = 'BseStorageService';

  /// Fetches a presigned URL for upload or download
  static Future<Map<String, String>?> getPresignedUrl({
    required String objectName,
    required String contentType,
    required String operation, // 'upload' or 'download'
  }) async {
    try {
      AppLogger.info(
        'Fetching presigned URL for $operation: $objectName',
        tag: _tag,
      );

      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return null;
      }

      final payload = {
        "object_name": objectName,
        "content_type": contentType,
        "operation": operation,
      };

      final response = await http.post(
        Uri.parse(ApiURLs.STORAGE_PRESIGNED_URL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      AppLogger.info('Presigned URL API status: ${response.body}', tag: _tag);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final url = jsonData['presigned_url'] ??
            jsonData['url'] ??
            jsonData['data']?['url'];
        final path = jsonData['gcs_object_path'] ??
            jsonData['object_name'] ??
            objectName;

        if (url != null) {
          return {
            'presigned_url': url.toString(),
            'gcs_object_path': path.toString(),
          };
        }
        return null;
      } else {
        AppLogger.error(
          'Failed to get presigned URL: ${response.body}',
          tag: _tag,
        );
        return null;
      }
    } catch (e) {
      AppLogger.error('Exception in getPresignedUrl: $e', tag: _tag);
      return null;
    }
  }

  /// Deletes an object from storage
  static Future<bool> deleteObject(String objectName) async {
    try {
      AppLogger.info('Deleting object: $objectName', tag: _tag);

      final authService = AuthService();
      final token = await authService.getAuthToken();
      if (token == null) {
        AppLogger.error('No auth token available', tag: _tag);
        return false;
      }

      final payload = {"object_name": objectName};

      final response = await http.delete(
        Uri.parse(ApiURLs.STORAGE_OBJECT),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      AppLogger.info(
        'Delete object API status: ${response.statusCode}',
        tag: _tag,
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      AppLogger.error('Exception in deleteObject: $e', tag: _tag);
      return false;
    }
  }

  /// Directly uploads file bytes to a presigned URL using PUT method
  static Future<bool> uploadFileToUrl({
    required String presignedUrl,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    try {
      AppLogger.info('Uploading file to presigned URL', tag: _tag);

      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      );

      AppLogger.info('File upload status: ${response.statusCode}', tag: _tag);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.error('Exception in uploadFileToUrl: $e', tag: _tag);
      return false;
    }
  }
}
