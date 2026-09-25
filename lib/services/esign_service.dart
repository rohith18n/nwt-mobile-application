import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/utils/logger.dart';

class ESignService {
  /// Upload a document for E-Sign
  /// Returns document_id
  static Future<Map<String, dynamic>> uploadDocument({
    required File pdfFile,
    String? documentName,
  }) async {
    AppLogger.info('========== DOCUMENT UPLOAD START ==========', tag: 'ESign');
    AppLogger.info('Uploading document for E-Sign', tag: 'ESign');
    AppLogger.info('  - File Path: ${pdfFile.path}', tag: 'ESign');
    AppLogger.info('  - File Name: ${documentName ?? "document.pdf"}', tag: 'ESign');
    AppLogger.info('  - File Size: ${await pdfFile.length()} bytes', tag: 'ESign');
    AppLogger.info('  - File Exists: ${await pdfFile.exists()}', tag: 'ESign');
    
    try {
      AppLogger.info('Creating multipart request...', tag: 'ESign');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiURLs.ESIGN_UPLOAD_DOCUMENT),
      );
      
      AppLogger.info('API URL: ${ApiURLs.ESIGN_UPLOAD_DOCUMENT}', tag: 'ESign');
      
      // Add file with explicit PDF content type
      AppLogger.info('Adding PDF file to request...', tag: 'ESign');
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          pdfFile.path,
          filename: documentName ?? 'document.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      );
      
      // Add document name if provided
      if (documentName != null) {
        AppLogger.info('Adding document_name field: $documentName', tag: 'ESign');
        request.fields['document_name'] = documentName;
      }
      
      AppLogger.info('Sending multipart request...', tag: 'ESign');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      AppLogger.info('---------- UPLOAD RESPONSE ----------', tag: 'ESign');
      AppLogger.info('Response Status Code: ${response.statusCode}', tag: 'ESign');
      AppLogger.info('Response Body:', tag: 'ESign');
      AppLogger.info(response.body, tag: 'ESign');
      AppLogger.info('-------------------------------------', tag: 'ESign');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        AppLogger.info('Parsing upload response...', tag: 'ESign');
        AppLogger.info('Response success flag: ${responseData['success']}', tag: 'ESign');
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          AppLogger.info('✅ Document uploaded successfully!', tag: 'ESign');
          AppLogger.info('Document ID: ${data['document_id']}', tag: 'ESign');
          AppLogger.info('========== DOCUMENT UPLOAD SUCCESS ==========', tag: 'ESign');
          return data;
        } else {
          final errorMessage = responseData['message'] ?? 'Failed to upload document';
          AppLogger.error('❌ Document upload failed: $errorMessage', tag: 'ESign');
          throw Exception(errorMessage);
        }
      } else {
        AppLogger.error('❌ Server error: ${response.statusCode}', tag: 'ESign');
        AppLogger.error('Response body: ${response.body}', tag: 'ESign');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('========== DOCUMENT UPLOAD FAILED ==========', tag: 'ESign');
      AppLogger.error('Error uploading document: $e', tag: 'ESign');
      AppLogger.error('Error type: ${e.runtimeType}', tag: 'ESign');
      rethrow;
    }
  }

  /// Create E-Sign request
  /// Returns verification_id and signing_link
  static Future<Map<String, dynamic>> createESignRequest({
    required String documentId,
    required String signerName,
    required String signerEmail,
    required String signerPhone,
    required String aadhaarLastFourDigits,
    List<Map<String, dynamic>>? signPositions,
    bool captureLocation = false,
    int linkExpiryDays = 7,
  }) async {
    AppLogger.info('========== E-SIGN REQUEST START ==========', tag: 'ESign');
    AppLogger.info('Creating E-Sign request with parameters:', tag: 'ESign');
    AppLogger.info('  - Document ID: $documentId', tag: 'ESign');
    AppLogger.info('  - Signer Name: $signerName', tag: 'ESign');
    AppLogger.info('  - Signer Email: $signerEmail', tag: 'ESign');
    AppLogger.info('  - Signer Phone: $signerPhone', tag: 'ESign');
    AppLogger.info('  - Aadhaar Last 4 Digits: $aadhaarLastFourDigits', tag: 'ESign');
    AppLogger.info('  - Sign Positions: ${signPositions != null ? json.encode(signPositions) : "null"}', tag: 'ESign');
    AppLogger.info('  - Capture Location: $captureLocation', tag: 'ESign');
    AppLogger.info('  - Link Expiry Days: $linkExpiryDays', tag: 'ESign');
    
    try {
      final requestBody = {
        'document_id': documentId,
        'signers': [
          {
            'name': signerName,
            'email': signerEmail,
            'phone': signerPhone,
            'aadhaar_last_four_digit': aadhaarLastFourDigits,
            'sign_positions': signPositions ?? [],
          }
        ],
        'notification_modes': ['email'],
        'auth_type': 'AADHAAR',
        'link_expiry_days': linkExpiryDays,
        'capture_location': captureLocation,
      };
      
      AppLogger.info('---------- REQUEST DETAILS ----------', tag: 'ESign');
      AppLogger.info('API URL: ${ApiURLs.ESIGN_CREATE_REQUEST}', tag: 'ESign');
      AppLogger.info('Request Headers: {"Content-Type": "application/json"}', tag: 'ESign');
      AppLogger.info('Request Body (JSON):', tag: 'ESign');
      AppLogger.info(json.encode(requestBody), tag: 'ESign');
      AppLogger.info('--------------------------------------', tag: 'ESign');
      
      AppLogger.info('Sending POST request to E-Sign API...', tag: 'ESign');
      final response = await http.post(
        Uri.parse(ApiURLs.ESIGN_CREATE_REQUEST),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      AppLogger.info('---------- RESPONSE RECEIVED ----------', tag: 'ESign');
      AppLogger.info('Response Status Code: ${response.statusCode}', tag: 'ESign');
      AppLogger.info('Response Body:', tag: 'ESign');
      AppLogger.info(response.body, tag: 'ESign');
      AppLogger.info('---------------------------------------', tag: 'ESign');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        AppLogger.info('Parsing response data...', tag: 'ESign');
        AppLogger.info('Response success flag: ${responseData['success']}', tag: 'ESign');
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          AppLogger.info('✅ E-Sign request created successfully!', tag: 'ESign');
          AppLogger.info('Verification ID: ${data['verification_id']}', tag: 'ESign');
          AppLogger.info('Signing Link: ${data['signing_link'] ?? data['link']}', tag: 'ESign');
          AppLogger.info('========== E-SIGN REQUEST SUCCESS ==========', tag: 'ESign');
          return data;
        } else {
          final errorMessage = responseData['message'] ?? 'Failed to create E-Sign request';
          AppLogger.error('❌ E-Sign request failed: $errorMessage', tag: 'ESign');
          throw Exception(errorMessage);
        }
      } else {
        AppLogger.error('❌ Server error: ${response.statusCode}', tag: 'ESign');
        AppLogger.error('Response body: ${response.body}', tag: 'ESign');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('========== E-SIGN REQUEST FAILED ==========', tag: 'ESign');
      AppLogger.error('Error creating E-Sign request: $e', tag: 'ESign');
      AppLogger.error('Error type: ${e.runtimeType}', tag: 'ESign');
      rethrow;
    }
  }

  /// Get E-Sign status
  static Future<Map<String, dynamic>> getESignStatus({
    required String verificationId,
  }) async {
    AppLogger.info('========== E-SIGN STATUS CHECK START ==========', tag: 'ESign');
    AppLogger.info('Checking E-Sign status', tag: 'ESign');
    AppLogger.info('  - Verification ID: $verificationId', tag: 'ESign');
    
    try {
      final url = ApiURLs.esignStatus(verificationId);
      AppLogger.info('API URL: $url', tag: 'ESign');
      AppLogger.info('Sending GET request...', tag: 'ESign');
      
      final response = await http.get(
        Uri.parse(url),
      );
      
      AppLogger.info('---------- STATUS RESPONSE ----------', tag: 'ESign');
      AppLogger.info('Response Status Code: ${response.statusCode}', tag: 'ESign');
      AppLogger.info('Response Body:', tag: 'ESign');
      AppLogger.info(response.body, tag: 'ESign');
      AppLogger.info('-------------------------------------', tag: 'ESign');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        AppLogger.info('Parsing status response...', tag: 'ESign');
        AppLogger.info('Response success flag: ${responseData['success']}', tag: 'ESign');
        
        if (responseData['success'] == true) {
          final data = responseData['data'];
          final status = data['status'];
          AppLogger.info('✅ E-Sign status retrieved successfully!', tag: 'ESign');
          AppLogger.info('Current Status: $status', tag: 'ESign');
          AppLogger.info('Full Status Data: ${json.encode(data)}', tag: 'ESign');
          AppLogger.info('========== E-SIGN STATUS CHECK SUCCESS ==========', tag: 'ESign');
          return data;
        } else {
          final errorMessage = responseData['message'] ?? 'Failed to get E-Sign status';
          AppLogger.error('❌ Status check failed: $errorMessage', tag: 'ESign');
          throw Exception(errorMessage);
        }
      } else {
        AppLogger.error('❌ Server error: ${response.statusCode}', tag: 'ESign');
        AppLogger.error('Response body: ${response.body}', tag: 'ESign');
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('========== E-SIGN STATUS CHECK FAILED ==========', tag: 'ESign');
      AppLogger.error('Error getting E-Sign status: $e', tag: 'ESign');
      AppLogger.error('Error type: ${e.runtimeType}', tag: 'ESign');
      rethrow;
    }
  }
}
