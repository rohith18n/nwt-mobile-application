import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:nwt_app/utils/app_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Helper class for image compression and conversion
/// Handles compression to target size and base64 encoding
/// 
/// Important: All images are converted to JPEG format during compression.
/// This ensures compatibility with APIs that require jpg/jpeg format.
/// Input images can be in any format (PNG, JPG, etc.) and will be output as JPEG.
class ImageCompressionHelper {
  // Maximum file size in bytes for signature (10 MB = 10240 KB)
  static const int maxSignatureFileSizeBytes = 10 * 1024 * 1024;
  
  // Maximum file size in bytes for AOF (4 MB = 4096 KB)
  static const int maxAofFileSizeBytes = 4 * 1024 * 1024;
  
  // Initial quality for compression
  static const int initialQuality = 95;
  
  // Minimum quality threshold
  static const int minQuality = 20;
  
  // Quality decrement step
  static const int qualityStep = 10;

  /// Compresses an image and converts to JPEG format
  /// Returns compressed JPEG image bytes
  /// ALWAYS converts to JPEG format regardless of size
  static Future<Uint8List> compressImage({
    required Uint8List imageBytes,
    String? fileName,
    int maxSizeBytes = maxSignatureFileSizeBytes,
  }) async {
    try {
      final int originalSize = imageBytes.length;
      AppLogger.info(
        'Starting image compression and JPEG conversion - Original size: ${_formatBytes(originalSize)}',
        tag: 'ImageCompression',
      );

      // ALWAYS convert to JPEG format (even if under size limit)
      // Create temporary file for compression
      final tempDir = await getTemporaryDirectory();
      final targetFileName = fileName ?? 'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(path.join(tempDir.path, targetFileName));
      await tempFile.writeAsBytes(imageBytes);

      AppLogger.info(
        'Temporary file created at: ${tempFile.path}',
        tag: 'ImageCompression',
      );

      Uint8List? compressedBytes;
      int currentQuality = initialQuality;

      // Perform at least one compression to convert to JPEG format
      // Continue compressing if size exceeds limit
      while (currentQuality >= minQuality) {
        AppLogger.info(
          'Attempting JPEG conversion with quality: $currentQuality',
          tag: 'ImageCompression',
        );

        final result = await FlutterImageCompress.compressWithFile(
          tempFile.path,
          quality: currentQuality,
          format: CompressFormat.jpeg,
        );

        if (result == null) {
          AppLogger.error(
            'Compression failed at quality $currentQuality',
            tag: 'ImageCompression',
          );
          currentQuality -= qualityStep;
          continue;
        }

        compressedBytes = result;
        final compressedSize = compressedBytes.length;

        AppLogger.info(
          'JPEG size: ${_formatBytes(compressedSize)} (${((compressedSize / originalSize) * 100).toStringAsFixed(1)}% of original)',
          tag: 'ImageCompression',
        );

        // Check if compressed size is acceptable
        if (compressedSize <= maxSizeBytes) {
          AppLogger.info(
            'JPEG conversion successful - Final size: ${_formatBytes(compressedSize)}, Quality: $currentQuality',
            tag: 'ImageCompression',
          );
          break;
        }

        // Reduce quality for next iteration
        currentQuality -= qualityStep;
      }

      // Clean up temporary file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (e) {
        AppLogger.error(
          'Failed to delete temporary file: $e',
          tag: 'ImageCompression',
        );
      }

      // If compression failed to achieve target size, return best attempt
      if (compressedBytes == null || compressedBytes.length > maxSizeBytes) {
        AppLogger.warning(
          'Could not compress image to target size. Using best compression attempt.',
          tag: 'ImageCompression',
        );
        return compressedBytes ?? imageBytes;
      }

      return compressedBytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error during image compression: $e',
        tag: 'ImageCompression',
        error: e,
        stackTrace: stackTrace,
      );
      // Return original bytes if compression fails
      return imageBytes;
    }
  }

  /// Compresses image from memory bytes and converts to JPEG format
  /// More efficient for already loaded images
  /// ALWAYS converts to JPEG format regardless of size
  static Future<Uint8List> compressFromMemory({
    required Uint8List imageBytes,
    int maxSizeBytes = maxSignatureFileSizeBytes,
  }) async {
    try {
      final int originalSize = imageBytes.length;
      AppLogger.info(
        'Starting memory compression and JPEG conversion - Original size: ${_formatBytes(originalSize)}',
        tag: 'ImageCompression',
      );

      // ALWAYS convert to JPEG format (even if under size limit)
      // This ensures PNG images are converted to JPEG as required by API
      Uint8List? compressedBytes;
      int currentQuality = initialQuality;

      // Perform at least one compression to convert to JPEG format
      // Continue compressing if size exceeds limit
      bool firstCompression = true;
      
      while (currentQuality >= minQuality) {
        AppLogger.info(
          'Attempting JPEG conversion with quality: $currentQuality',
          tag: 'ImageCompression',
        );

        final result = await FlutterImageCompress.compressWithList(
          imageBytes,
          quality: currentQuality,
          format: CompressFormat.jpeg,
        );

        compressedBytes = result;
        final compressedSize = compressedBytes.length;

        AppLogger.info(
          'JPEG size: ${_formatBytes(compressedSize)} (${((compressedSize / originalSize) * 100).toStringAsFixed(1)}% of original)',
          tag: 'ImageCompression',
        );

        // Check if compressed size is acceptable
        if (compressedSize <= maxSizeBytes) {
          AppLogger.info(
            'JPEG conversion successful - Final size: ${_formatBytes(compressedSize)}, Quality: $currentQuality',
            tag: 'ImageCompression',
          );
          break;
        }

        // If first compression exceeded limit, continue reducing quality
        if (firstCompression) {
          firstCompression = false;
        }
        
        // Reduce quality for next iteration
        currentQuality -= qualityStep;
      }

      // If compression failed to achieve target size, return best attempt or original
      if (compressedBytes == null) {
        AppLogger.warning(
          'Compression returned null, returning original image',
          tag: 'ImageCompression',
        );
        return imageBytes;
      }
      
      if (compressedBytes.length > maxSizeBytes) {
        AppLogger.warning(
          'Could not compress image to target size. Using best compression attempt: ${_formatBytes(compressedBytes.length)}',
          tag: 'ImageCompression',
        );
      }

      return compressedBytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error during memory compression: $e',
        tag: 'ImageCompression',
        error: e,
        stackTrace: stackTrace,
      );
      // Return original bytes if compression fails
      return imageBytes;
    }
  }

  /// Converts image bytes to base64 string
  static String convertToBase64(Uint8List imageBytes) {
    try {
      final base64String = base64Encode(imageBytes);
      AppLogger.info(
        'Converted to base64 - Length: ${base64String.length} characters, Size: ${_formatBytes(imageBytes.length)}',
        tag: 'ImageCompression',
      );
      return base64String;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error converting to base64: $e',
        tag: 'ImageCompression',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Converts base64 string back to image bytes
  static Uint8List convertFromBase64(String base64String) {
    try {
      final imageBytes = base64Decode(base64String);
      AppLogger.info(
        'Converted from base64 - Size: ${_formatBytes(imageBytes.length)}',
        tag: 'ImageCompression',
      );
      return imageBytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error converting from base64: $e',
        tag: 'ImageCompression',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Compresses image and converts to base64 in one operation
  static Future<String> compressAndConvertToBase64({
    required Uint8List imageBytes,
    String? fileName,
    int maxSizeBytes = maxSignatureFileSizeBytes,
  }) async {
    try {
      AppLogger.info(
        'Starting compress and convert operation',
        tag: 'ImageCompression',
      );

      // Compress image
      final compressedBytes = await compressImage(
        imageBytes: imageBytes,
        fileName: fileName,
        maxSizeBytes: maxSizeBytes,
      );

      // Convert to base64
      final base64String = convertToBase64(compressedBytes);

      AppLogger.info(
        'Compress and convert completed - Final base64 length: ${base64String.length}',
        tag: 'ImageCompression',
      );

      return base64String;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error in compress and convert operation: $e',
        tag: 'ImageCompression',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Formats bytes to human-readable format
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  /// Validates if image size is within acceptable limits
  static bool isImageSizeValid(Uint8List imageBytes, {int maxSizeBytes = maxSignatureFileSizeBytes}) {
    return imageBytes.length <= maxSizeBytes;
  }

  /// Calculates file size in KB (rounded up to nearest multiple of 1024)
  /// As per API requirement: file_size must be in multiples of 1024 KB
  static int calculateFileSizeInKB(Uint8List imageBytes) {
    final sizeInBytes = imageBytes.length;
    final sizeInKB = (sizeInBytes / 1024).ceil();
    
    // Round up to nearest multiple of 1024
    final remainder = sizeInKB % 1024;
    final fileSizeKB = remainder == 0 ? sizeInKB : sizeInKB + (1024 - remainder);
    
    AppLogger.info(
      'File size calculation - Bytes: $sizeInBytes, KB: $sizeInKB, Rounded to multiple of 1024: $fileSizeKB KB',
      tag: 'ImageCompression',
    );
    
    return fileSizeKB;
  }

  /// Gets formatted size information for an image
  static Map<String, dynamic> getImageSizeInfo(Uint8List imageBytes, {int maxSizeBytes = maxSignatureFileSizeBytes}) {
    final size = imageBytes.length;
    return {
      'bytes': size,
      'formatted': _formatBytes(size),
      'isValid': isImageSizeValid(imageBytes, maxSizeBytes: maxSizeBytes),
      'percentageOfMax': ((size / maxSizeBytes) * 100).toStringAsFixed(1),
      'fileSizeKB': calculateFileSizeInKB(imageBytes),
    };
  }
}
