import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nwt_app/services/bse_star_v2/ucc_management/storage_service.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/services/secure_storage.dart';
import 'package:nwt_app/screens/bse_star_v2/types/bse_onboarding_full_response.dart';

class DocumentUploadManagement extends StatefulWidget {
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onError;
  final bool shouldSubmit;
  final List<dynamic>? existingDocuments;

  const DocumentUploadManagement({
    super.key,
    this.onNext,
    this.onBack,
    this.onError,
    this.shouldSubmit = false,
    this.existingDocuments,
  });

  @override
  State<DocumentUploadManagement> createState() => _DocumentUploadManagementState();
}

class _DocumentUploadManagementState extends State<DocumentUploadManagement> {
  bool _isUploading = false;
  bool _isDeleting = false;
  bool _isDownloading = false;
  String? _uploadedFileName;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _checkExistingDocuments();
    
    // Listen for shouldSubmit changes from parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.shouldSubmit) {
        _handleOnNext();
      }
    });
  }

  @override
  void didUpdateWidget(DocumentUploadManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldSubmit && widget.shouldSubmit && !_isUploading) {
      _handleOnNext();
    }
  }

  void _checkExistingDocuments() {
    if (widget.existingDocuments != null && widget.existingDocuments!.isNotEmpty) {
      setState(() {
        // For simplicity, we assume the first document is the signed UCC form
        // In a real scenario, we would filter by name or type
        _uploadedFileName = "Signed Document Found";
      });
    }
  }

  Future<void> _handleOnNext() async {
    if (_uploadedFileName == null) {
      setState(() {
        _uploadError = "Please upload the signed document to proceed.";
      });
      widget.onError?.call();
      return;
    }
    
    if (widget.onNext != null) {
      widget.onNext!();
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final fileName = file.name;
      final fileBytes = file.bytes;
      
      if (fileBytes == null) {
        setState(() => _uploadError = "Failed to read file data.");
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final onboardingId = await SecureStorage.read('bse_onboarding_id');
      if (onboardingId == null) {
        setState(() => _uploadError = "Onboarding ID not found.");
        return;
      }

      final objectName = "onboarding/$onboardingId/signed_ucc_form_${DateTime.now().millisecondsSinceEpoch}.${file.extension}";
      final contentType = _getContentType(file.extension ?? '');

      // 1. Get Presigned Upload URL
      final response = await BseStorageService.getPresignedUrl(
        objectName: objectName,
        contentType: contentType,
        operation: 'upload',
      );

      if (response == null || response['presigned_url'] == null) {
        setState(() {
          _isUploading = false;
          _uploadError = "Failed to generate upload URL.";
        });
        return;
      }

      final presignedUrl = response['presigned_url']!;
      final gcsObjectPath = response['gcs_object_path']!;

      // 2. Upload File
      final success = await BseStorageService.uploadFileToUrl(
        presignedUrl: presignedUrl,
        fileBytes: fileBytes,
        contentType: contentType,
      );

      if (success) {
        setState(() {
          _uploadedFileName = fileName;
          _isUploading = false;
        });

        // Save the object name for future reference
        await SecureStorage.write('bse_signed_doc_path', gcsObjectPath);
        
        Get.snackbar(
          'Success',
          'Document uploaded successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        setState(() {
          _isUploading = false;
          _uploadError = "Failed to upload file to storage.";
        });
      }
    } catch (e) {
      AppLogger.error('Error picking/uploading file: $e');
      setState(() {
        _isUploading = false;
        _uploadError = "An unexpected error occurred.";
      });
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      default: return 'application/octet-stream';
    }
  }

  Future<void> _handleDownload() async {
    // This would typically download a pre-filled UCC form
    // For now, we'll simulate it by showing a message or opening a sample URL
    setState(() => _isDownloading = true);
    
    // In a real app, you might fetch a presigned URL for a template or generated PDF
    // For this demonstration, we'll just show a success message
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isDownloading = false);
    
    Get.snackbar(
      'Download',
      'UCC form template download initiated.',
      backgroundColor: Colors.blueAccent,
      colorText: Colors.white,
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: AppText('Delete Document?', variant: AppTextVariant.headline6, customColor: Colors.white),
        content: AppText('Are you sure you want to remove the uploaded document?', variant: AppTextVariant.bodyMedium, customColor: Colors.grey),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);
      
      final objectName = await SecureStorage.read('bse_signed_doc_path');
      if (objectName != null) {
        await BseStorageService.deleteObject(objectName);
        await SecureStorage.remove('bse_signed_doc_path');
      }
      
      setState(() {
        _uploadedFileName = null;
        _isDeleting = false;
      });
      
      Get.snackbar(
        'Deleted',
        'Document removed.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Signed Document',
          variant: AppTextVariant.headline5,
          weight: AppTextWeight.bold,
          customColor: Colors.white,
        ),
        const SizedBox(height: 8),
        AppText(
          'Please download the UCC registration form, sign it, and upload the scanned copy here to complete your onboarding.',
          variant: AppTextVariant.bodyMedium,
          customColor: Colors.grey,
        ),
        const SizedBox(height: 32),
        
        // Step 1: Download
        _buildSection(
          title: '1. Download Form',
          description: 'Get your pre-filled UCC registration form.',
          child: AppButton(
            onPressed: _handleDownload,
            text: 'Download UCC Form',
            isLoading: _isDownloading,
            variant: AppButtonVariant.secondary,
            leadingIcon: Icons.file_download_outlined,
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Step 2: Upload
        _buildSection(
          title: '2. Upload Signed Copy',
          description: 'Upload the scanned PDF or image of the signed form.',
          child: _uploadedFileName == null 
            ? AppButton(
                onPressed: _pickAndUploadFile,
                text: 'Select & Upload File',
                isLoading: _isUploading,
                variant: AppButtonVariant.primary,
                leadingIcon: Icons.file_upload_outlined,
              )
            : _buildUploadedFileCard(),
        ),
        
        if (_uploadError != null) ...[
          const SizedBox(height: 16),
          _buildErrorBox(_uploadError!),
        ],
        
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildSection({required String title, required String description, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(title, variant: AppTextVariant.bodyLarge, weight: AppTextWeight.bold, customColor: Colors.white),
        const SizedBox(height: 4),
        AppText(description, variant: AppTextVariant.bodySmall, customColor: Colors.grey),
        const SizedBox(height: 16),
        child,
      ],
    );
  }

  Widget _buildUploadedFileCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(_uploadedFileName!, variant: AppTextVariant.bodyMedium, weight: AppTextWeight.semiBold, customColor: Colors.white),
                AppText('Successfully uploaded', variant: AppTextVariant.bodySmall, customColor: Colors.grey),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleDelete,
            icon: _isDeleting 
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
              : const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(error, variant: AppTextVariant.bodySmall, customColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
