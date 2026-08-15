import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/constants/api.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/controllers/user_controller.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final String documentTitle;
  final VoidCallback onAcknowledged;

  const DocumentPreviewScreen({
    super.key,
    required this.documentTitle,
    required this.onAcknowledged,
  });

  @override
  State<DocumentPreviewScreen> createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  bool _isLoading = true;
  bool _isAcknowledged = false;
  String? _pdfPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateAndLoadPDF();
  }

  Future<void> _generateAndLoadPDF() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user data
      final userController = Get.find<UserController>();
      final user = userController.userData;
      
      final fullName = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();
      final pan = user?.pannumber ?? '';

      if (fullName.isEmpty || pan.isEmpty) {
        throw Exception('User name and PAN are required');
      }

      AppLogger.info('Generating RIA Agreement PDF for: $fullName, PAN: $pan', tag: 'DocumentPreview');

      // Call backend to generate PDF
      final response = await http.post(
        Uri.parse(ApiURLs.GENERATE_RIA_AGREEMENT),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': fullName,
          'pan': pan,
        }),
      );

      if (response.statusCode == 200) {
        // Save PDF to temporary file
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/RIA_Agreement_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _pdfPath = file.path;
          _isLoading = false;
        });

        AppLogger.info('PDF generated and saved: ${file.path}', tag: 'DocumentPreview');
      } else {
        throw Exception('Failed to generate PDF: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error generating PDF: $e', tag: 'DocumentPreview');
      setState(() {
        _errorMessage = 'Failed to generate document: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePDFToDownloads() async {
    if (_pdfPath == null) return;

    try {
      // Use app's external storage directory which doesn't require runtime permissions
      // This is accessible to the user via file manager
      Directory? saveDir;
      
      if (Platform.isAndroid) {
        // Get app's external storage directory (Android/data/com.app.name/files/Documents)
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          saveDir = Directory('${externalDir.path}/Documents');
          await saveDir.create(recursive: true);
        } else {
          throw Exception('Unable to access storage');
        }
      } else {
        // For iOS, use app documents directory
        saveDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'RIA_Agreement_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final newPath = '${saveDir.path}/$fileName';
      
      // Copy file to save directory
      final file = File(_pdfPath!);
      await file.copy(newPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PDF saved successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: Documents/$fileName',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      AppLogger.info('PDF saved to: $newPath', tag: 'DocumentPreview');
    } catch (e) {
      AppLogger.error('Error saving PDF: $e', tag: 'DocumentPreview');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        title: AppText(
          widget.documentTitle,
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
        actions: [
          if (_pdfPath != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _savePDFToDownloads,
              tooltip: 'Save PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating document...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _generateAndLoadPDF,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // PDF Viewer
                    Expanded(
                      child: SfPdfViewer.file(
                        File(_pdfPath!),
                        canShowScrollHead: true,
                        canShowScrollStatus: true,
                        enableDoubleTapZooming: true,
                      ),
                    ),

                    // Acknowledgment Section
                    Container(
                      padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkCardBG : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Acknowledgment Checkbox
                          CheckboxListTile(
                            value: _isAcknowledged,
                            onChanged: (value) {
                              setState(() {
                                _isAcknowledged = value ?? false;
                              });
                            },
                            title: AppText(
                              'I have read and understood the RIA Agreement',
                              variant: AppTextVariant.bodyMedium,
                              weight: AppTextWeight.medium,
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            activeColor: isDarkMode 
                                ? AppColors.darkButtonPrimaryBackground 
                                : AppColors.lightButtonPrimaryBackground,
                          ),
                          const SizedBox(height: 16),

                          // Proceed Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAcknowledged
                                  ? () {
                                      widget.onAcknowledged();
                                      Navigator.pop(context, _pdfPath);
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode 
                                    ? AppColors.darkButtonPrimaryBackground 
                                    : AppColors.lightButtonPrimaryBackground,
                                foregroundColor: isDarkMode 
                                    ? AppColors.darkButtonPrimaryText 
                                    : AppColors.lightButtonPrimaryText,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: isDarkMode 
                                    ? AppColors.darkButtonBorder 
                                    : AppColors.lightButtonBorder,
                              ),
                              child: const Text(
                                'Proceed to E-Sign',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    // Clean up temporary file
    if (_pdfPath != null) {
      try {
        final file = File(_pdfPath!);
        if (file.existsSync()) {
          // Don't delete immediately as it might be used for E-Sign
          // file.deleteSync();
        }
      } catch (e) {
        AppLogger.warning('Failed to cleanup temp file: $e', tag: 'DocumentPreview');
      }
    }
    super.dispose();
  }
}
