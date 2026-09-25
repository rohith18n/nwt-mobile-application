import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';
import 'package:nwt_app/screens/mfc_v2/mfc_qr_display_screen.dart';

/// Full-screen WebView for MF Central with automatic QR code detection
class MFCWebViewScreen extends StatefulWidget {
  final String mfCentralUrl;
  final String? reqId;
  final String? clientRefNo;

  const MFCWebViewScreen({
    super.key,
    this.mfCentralUrl = 'https://mfcentral.com',
    this.reqId,
    this.clientRefNo,
  });

  @override
  State<MFCWebViewScreen> createState() => _MFCWebViewScreenState();
}

class _MFCWebViewScreenState extends State<MFCWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  double progress = 0;
  bool isLoading = true;
  String? loadError;
  bool _hasNavigatedToQR = false;
  int? _lastLoggedProgress;

  static const String _logTag = 'MFCWebView';
  static const Duration _qrDetectionInterval = Duration(seconds: 2);
  static const Duration _qrDetectionTimeout = Duration(seconds: 60);

  DateTime? _webViewLoadTime;

  @override
  void dispose() {
    webViewController?.dispose();
    super.dispose();
  }

  /// JavaScript code to detect QR code on the page
  String get _qrDetectionScript => '''
    (function() {
      console.log('=== QR Detection Script Running ===');
      
      // Try multiple strategies to find QR code
      
      // Strategy 1: Look for all images on the page
      const allImages = document.querySelectorAll('img');
      console.log('Total images found: ' + allImages.length);
      
      // Strategy 2: Look for canvas elements
      const allCanvas = document.querySelectorAll('canvas');
      console.log('Total canvas found: ' + allCanvas.length);
      
      // Strategy 3: Look for SVG elements
      const allSvg = document.querySelectorAll('svg');
      console.log('Total SVG found: ' + allSvg.length);
      
      // Check all images
      for (let i = 0; i < allImages.length; i++) {
        const img = allImages[i];
        const src = img.src || '';
        const alt = img.alt || '';
        const className = img.className || '';
        const width = img.width || img.naturalWidth || 0;
        const height = img.height || img.naturalHeight || 0;
        
        console.log('Image ' + i + ' details:');
        console.log('  src: ' + src.substring(0, 100));
        console.log('  alt: ' + alt);
        console.log('  className: ' + className);
        console.log('  width: ' + width);
        console.log('  height: ' + height);
        console.log('  naturalWidth: ' + img.naturalWidth);
        console.log('  naturalHeight: ' + img.naturalHeight);
        
        // If image has src, extract it regardless of size (for testing)
        // We'll be more lenient - just check if src exists and is not empty
        if (src && src.length > 10) {
          console.log('Found image with valid src, extracting...');
          console.log('Image src length: ' + src.length);
          
          // If it's already a data URL (base64), use it directly
          if (src.startsWith('data:')) {
            console.log('Image is already base64, sending to Flutter...');
            window.flutter_inappwebview.callHandler('qrCodeDetected', src);
            return true;
          }
          
          // If it's a URL, convert to base64
          console.log('Converting URL image to base64...');
          console.log('Image naturalWidth: ' + img.naturalWidth + ', naturalHeight: ' + img.naturalHeight);
          
          // Use the existing image element instead of creating a new one
          if (img.complete && img.naturalWidth > 0) {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');
            
            // Use natural dimensions to get full quality
            canvas.width = img.naturalWidth || img.width;
            canvas.height = img.naturalHeight || img.height;
            
            console.log('Canvas size: ' + canvas.width + 'x' + canvas.height);
            
            try {
              ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
              const base64 = canvas.toDataURL('image/png');
              console.log('Converted to base64, total length: ' + base64.length);
              console.log('Base64 starts with: ' + base64.substring(0, 50));
              console.log('Base64 ends with: ' + base64.substring(base64.length - 50));
              
              // Send to Flutter
              console.log('Sending base64 to Flutter handler...');
              window.flutter_inappwebview.callHandler('qrCodeDetected', base64);
              console.log('Base64 sent to Flutter successfully');
            } catch(e) {
              console.log('Failed to convert to base64: ' + e);
              console.log('Error stack: ' + e.stack);
              // Fallback to URL if conversion fails
              window.flutter_inappwebview.callHandler('qrCodeDetected', src);
            }
          } else {
            console.log('Image not fully loaded, using URL fallback');
            window.flutter_inappwebview.callHandler('qrCodeDetected', src);
          }
          return true;
        } else if (src) {
          console.log('Image src too short: ' + src.length + ' chars');
        }
      }
      
      // Check all canvas elements
      for (let i = 0; i < allCanvas.length; i++) {
        const canvas = allCanvas[i];
        try {
          const dataUrl = canvas.toDataURL();
          if (dataUrl && dataUrl.length > 100) {
            console.log('Found QR in canvas, extracting...');
            window.flutter_inappwebview.callHandler('qrCodeDetected', dataUrl);
            return true;
          }
        } catch(e) {
          console.log('Canvas toDataURL failed: ' + e);
        }
      }
      
      console.log('No QR code found in this check');
      return false;
    })();
  ''';

  void _startQRDetection() {
    if (_hasNavigatedToQR) return;

    _webViewLoadTime = DateTime.now();

    // Start periodic QR detection
    Future.delayed(_qrDetectionInterval, _checkForQRCode);
  }

  Future<void> _checkForQRCode() async {
    if (_hasNavigatedToQR || !mounted) return;

    // Check timeout
    if (_webViewLoadTime != null &&
        DateTime.now().difference(_webViewLoadTime!) > _qrDetectionTimeout) {
      AppLogger.info(
        'QR detection timeout after ${_qrDetectionTimeout.inSeconds} seconds',
        tag: _logTag,
      );
      return;
    }

    try {
      final result = await webViewController?.evaluateJavascript(
        source: _qrDetectionScript,
      );

      AppLogger.info(
        'QR detection check result: $result',
        tag: _logTag,
      );

      // Continue checking if QR not found
      if (result != true && mounted && !_hasNavigatedToQR) {
        Future.delayed(_qrDetectionInterval, _checkForQRCode);
      }
    } catch (e) {
      AppLogger.error(
        'Error checking for QR code: $e',
        tag: _logTag,
      );
      // Continue checking despite error
      if (mounted && !_hasNavigatedToQR) {
        Future.delayed(_qrDetectionInterval, _checkForQRCode);
      }
    }
  }

  void _navigateToQRDisplay(String qrBase64) {
    if (_hasNavigatedToQR) return;
    _hasNavigatedToQR = true;

    final detectionTime = _webViewLoadTime != null
        ? DateTime.now().difference(_webViewLoadTime!).inSeconds
        : 0;

    AppLogger.info(
      'Navigating to QR display screen (detected in ${detectionTime}s)',
      tag: _logTag,
    );

    if (mounted) {
      Get.off(
        () => MFCQRDisplayScreen(
          qrCodeBase64: qrBase64,
          reqId: widget.reqId,
          clientRefNo: widget.clientRefNo,
        ),
        transition: Transition.rightToLeft,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(widget.mfCentralUrl);
    if (widget.mfCentralUrl.isEmpty || uri == null) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppText(
                  'Invalid MF Central URL.',
                  variant: AppTextVariant.bodyMedium,
                  colorType: AppTextColorType.secondary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          InAppWebView(
            key: webViewKey,
            initialUrlRequest: URLRequest(url: WebUri(uri.toString())),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              javaScriptEnabled: true,
              cacheEnabled: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              verticalScrollBarEnabled: true,
              horizontalScrollBarEnabled: true,
              transparentBackground: false,
              supportZoom: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36',
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;

              // Register JavaScript handler for QR code detection
              controller.addJavaScriptHandler(
                handlerName: 'qrCodeDetected',
                callback: (args) {
                  if (args.isNotEmpty) {
                    final qrBase64 = args[0] as String;

                    // Log the base64 QR code data with length and preview
                    final preview = qrBase64.length > 200 
                        ? '${qrBase64.substring(0, 200)}...' 
                        : qrBase64;
                    
                    final ending = qrBase64.length > 100
                        ? qrBase64.substring(qrBase64.length - 100)
                        : '';
                    
                    AppLogger.info(
                      'QR Code detected - Total Length: ${qrBase64.length} chars',
                      tag: 'mfc_qr',
                    );
                    
                    AppLogger.info(
                      'QR Code starts: $preview',
                      tag: 'mfc_qr',
                    );
                    
                    AppLogger.info(
                      'QR Code ends: ...$ending',
                      tag: 'mfc_qr',
                    );
                    
                    // Verify it's a complete base64 image
                    final isComplete = qrBase64.startsWith('data:image/') && 
                                      qrBase64.length > 1000;
                    
                    AppLogger.info(
                      'Base64 appears complete: $isComplete',
                      tag: 'mfc_qr',
                    );

                    // Navigate to QR display screen with FULL base64
                    _navigateToQRDisplay(qrBase64);
                  }
                },
              );

              AppLogger.info(
                'WebView created for MF Central',
                tag: _logTag,
              );
            },
            onLoadStart: (controller, url) {
              if (!mounted) return;
              setState(() {
                isLoading = true;
                loadError = null;
              });
              AppLogger.info(
                'Load started: $url',
                tag: _logTag,
              );
            },
            onLoadStop: (controller, url) async {
              if (!mounted) return;
              setState(() {
                isLoading = false;
                loadError = null;
              });

              AppLogger.info(
                'Load stopped: $url',
                tag: _logTag,
              );

              // Start QR detection after page loads
              _startQRDetection();
            },
            onLoadError: (controller, url, code, message) {
              if (!mounted) return;
              setState(() {
                isLoading = false;
                loadError = message;
              });
              AppLogger.error(
                'Load error: url=$url code=$code message=$message',
                tag: _logTag,
              );
            },
            onProgressChanged: (controller, progress) {
              if (!mounted) return;
              setState(() => this.progress = progress / 100);
              final pct = (progress / 10).round() * 10;
              if ((pct == 50 || pct == 100) &&
                  (_lastLoggedProgress == null || pct != _lastLoggedProgress)) {
                _lastLoggedProgress = pct;
                AppLogger.info(
                  'Progress: $pct%',
                  tag: _logTag,
                );
              }
            },
            onConsoleMessage: (controller, consoleMessage) {
              AppLogger.info(
                'Console: ${consoleMessage.message}',
                tag: _logTag,
              );
            },
          ),
          if (loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      'Failed to load MF Central: $loadError',
                      variant: AppTextVariant.bodyMedium,
                      colorType: AppTextColorType.secondary,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          else if (isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress > 0 ? progress : null,
                    color: AppColors.info,
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    'Loading MF Central... ${(progress * 100).toInt()}%',
                    variant: AppTextVariant.bodyMedium,
                    colorType: AppTextColorType.secondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left, size: 32),
          ),
          const AppText(
            "MFC",
            variant: AppTextVariant.headline6,
            weight: AppTextWeight.semiBold,
          ),
          const WhatsAppSupportButton(size: 20, color: AppColors.darkPrimary),
        ],
      ),
    );
  }
}
