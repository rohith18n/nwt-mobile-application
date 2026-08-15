import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/services/esign_service.dart';
import 'package:nwt_app/utils/logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/screens/advisory/esign_webview_screen.dart';

class ESignDocumentScreen extends StatefulWidget {
  final String documentTitle;
  final String? pdfFilePath; // Optional: if PDF already exists
  final String signerName;
  final String signerEmail;
  final String signerPhone;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const ESignDocumentScreen({
    super.key,
    required this.documentTitle,
    this.pdfFilePath,
    required this.signerName,
    required this.signerEmail,
    required this.signerPhone,
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<ESignDocumentScreen> createState() => _ESignDocumentScreenState();
}

class _ESignDocumentScreenState extends State<ESignDocumentScreen> {
  bool _isProcessing = false;
  bool _isUploading = false;
  bool _isPickingFile = false;
  String? _errorMessage;
  String? _verificationId;
  String? _signingLink;
  bool _isWaitingForSignature = false;
  String? _documentId;
  File? _selectedPdfFile;
  final TextEditingController _aadhaarController = TextEditingController();

  @override
  void dispose() {
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _pickPdfFile() async {
    try {
      setState(() {
        _isPickingFile = true;
        _errorMessage = null;
      });

      // Add small delay to allow UI to update
      await Future.delayed(const Duration(milliseconds: 100));

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      setState(() {
        _isPickingFile = false;
      });

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedPdfFile = File(result.files.single.path!);
          _errorMessage = null;
        });
        AppLogger.info('PDF selected: ${result.files.single.name}', tag: 'ESign');
      }
    } catch (e) {
      AppLogger.error('Error picking PDF: $e', tag: 'ESign');
      setState(() {
        _isPickingFile = false;
        _errorMessage = 'Failed to select PDF file';
      });
    }
  }

  Future<void> _initiateESign() async {
    if (_aadhaarController.text.length != 4) {
      setState(() {
        _errorMessage = 'Please enter last 4 digits of Aadhaar';
      });
      return;
    }

    // Check if we have a PDF file
    if (_selectedPdfFile == null && widget.pdfFilePath == null) {
      setState(() {
        _errorMessage = 'Please select a PDF document first';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Upload document if not already uploaded
      if (_documentId == null) {
        AppLogger.info('Uploading document to Cashfree...', tag: 'ESign');
        
        // Show upload progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading PDF document...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }
        
        final pdfFile = _selectedPdfFile ?? File(widget.pdfFilePath!);
        final uploadResult = await ESignService.uploadDocument(
          pdfFile: pdfFile,
          documentName: widget.documentTitle,
        );

        _documentId = uploadResult['document_id'].toString();
        AppLogger.info('Document uploaded, ID: $_documentId', tag: 'ESign');
        
        // Hide upload progress
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        setState(() {
          _isUploading = false;
        });
      }

      // Step 2: Create E-Sign request with the document_id
      AppLogger.info('Creating E-Sign request with document_id: $_documentId', tag: 'ESign');
      
      // Define static sign positions
      final signPositions = [
        {
          "page": 1,
          "top_left_x_coordinate": 100,
          "bottom_right_x_coordinate": 200,
          "top_left_y_coordinate": 180,
          "bottom_right_y_coordinate": 120
        }
      ];
      
      final result = await ESignService.createESignRequest(
        documentId: _documentId!,
        signerName: widget.signerName,
        signerEmail: widget.signerEmail,
        signerPhone: widget.signerPhone,
        aadhaarLastFourDigits: _aadhaarController.text,
        signPositions: signPositions,
        captureLocation: false,
        linkExpiryDays: 7,
      );

      setState(() {
        _verificationId = result['verification_id'];
        _signingLink = result['signing_link'] ?? result['link'];
        _isProcessing = false;
        _isWaitingForSignature = true;
      });

      // Step 3: Open signing link
      if (_signingLink != null) {
        await _openSigningLink();
      }
    } catch (e) {
      AppLogger.error('Error initiating E-Sign: $e', tag: 'ESign');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to initiate E-Sign. Please try again.';
      });
    }
  }

  Future<void> _openSigningLink() async {
    if (_signingLink == null) return;

    try {
      // Open in custom WebView screen with themed app bar
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ESignWebViewScreen(
            url: _signingLink!,
            title: 'Sign ${widget.documentTitle}',
          ),
        ),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify if you completed the signature'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error opening signing link: $e', tag: 'ESign');
      setState(() {
        _errorMessage = 'Failed to open signing link';
      });
    }
  }

  Future<void> _checkSignatureStatus() async {
    // User clicked "I Have Completed Signing" - proceed to payment gateway
    AppLogger.info('User completed E-Sign, proceeding to payment gateway', tag: 'ESign');

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Call onSuccess callback
      widget.onSuccess?.call();
      
      // Close E-Sign screen and return 'payment' to indicate payment should be initiated
      if (mounted) {
        Navigator.pop(context, 'payment');
        
        AppLogger.info('E-Sign completed, payment flow will be initiated', tag: 'ESign');
      }
      
    } catch (e) {
      AppLogger.error('Error proceeding to payment: $e', tag: 'ESign');
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to proceed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: AppText(
          'E-Sign Document',
          variant: AppTextVariant.headline6,
          weight: AppTextWeight.semiBold,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizing.scaffoldHorizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              const SizedBox(height: 24),
              
              // Document Info Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.documentTitle,
                            style: TextStyle(
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      isDarkMode: isDarkMode,
                      label: 'Signer Name',
                      value: widget.signerName,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      isDarkMode: isDarkMode,
                      label: 'Email',
                      value: widget.signerEmail,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      isDarkMode: isDarkMode,
                      label: 'Phone',
                      value: widget.signerPhone,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (!_isWaitingForSignature) ...[
                // Show upload option only when no PDF is provided (Risk Profiling)
                // For RIA Agreement, PDF is already generated, so just show it's ready
                if (widget.pdfFilePath == null) ...[
                  Text(
                    'Select PDF Document',
                    style: TextStyle(
                      color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _isPickingFile ? null : _pickPdfFile,
                    icon: _isPickingFile
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _selectedPdfFile != null ? Icons.check_circle : Icons.upload_file,
                            color: _selectedPdfFile != null ? Colors.green : null,
                          ),
                    label: Text(
                      _isPickingFile
                          ? 'Opening file picker...'
                          : _selectedPdfFile != null 
                              ? 'PDF Selected: ${_selectedPdfFile!.path.split('/').last}'
                              : 'Choose PDF File',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      side: BorderSide(
                        color: _selectedPdfFile != null 
                            ? Colors.green 
                            : (isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Document already provided (RIA Agreement)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Document Ready',
                                style: TextStyle(
                                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.pdfFilePath!.split('/').last,
                                style: TextStyle(
                                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Aadhaar Input
                Text(
                  'Last 4 digits of Aadhaar',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter last 4 digits',
                    hintStyle: TextStyle(
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? AppColors.darkCardBG : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode ? AppColors.darkButtonBorder : AppColors.lightButtonBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDarkMode ? AppColors.darkButtonPrimaryBackground : AppColors.lightButtonPrimaryBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
              
              if (_isWaitingForSignature) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.blue, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Waiting for Signature',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please complete the signature in the browser',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _openSigningLink,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Reopen Signing Link'),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              if (!_isWaitingForSignature)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _initiateESign,
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
                    child: _isProcessing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isUploading ? 'Uploading PDF...' : 'Processing...',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Proceed to Sign',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              
              if (_isWaitingForSignature)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _checkSignatureStatus,
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
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'I Have Completed Signing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required bool isDarkMode,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
