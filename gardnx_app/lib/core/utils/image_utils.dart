import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants/plant_constants.dart';

/// Utilities for image compression, validation, and dimension calculations.
class ImageUtils {
  ImageUtils._();

  /// Picks an image from the given [source] (camera or gallery) and returns
  /// the [XFile], or `null` if the user cancelled.
  ///
  /// The image is automatically constrained to [PlantConstants.maxImageWidth]
  /// and [PlantConstants.maxImageHeight].
  static Future<XFile?> pickImage({
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    final picker = ImagePicker();
    try {
      final xFile = await picker.pickImage(
        source: source,
        maxWidth: (maxWidth ?? PlantConstants.maxImageWidth).toDouble(),
        maxHeight: (maxHeight ?? PlantConstants.maxImageHeight).toDouble(),
        imageQuality: imageQuality ?? PlantConstants.imageCompressionQuality,
      );
      return xFile;
    } catch (e) {
      debugPrint('ImageUtils.pickImage error: $e');
      return null;
    }
  }

  /// Checks whether the file at [path] is within the maximum allowed size.
  static Future<bool> isFileSizeValid(String path) async {
    try {
      final file = File(path);
      final sizeBytes = await file.length();
      return sizeBytes <= PlantConstants.maxImageSizeBytes;
    } catch (e) {
      debugPrint('ImageUtils.isFileSizeValid error: $e');
      return false;
    }
  }

  /// Returns the file size in a human-readable format (KB, MB, etc.).
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Calculates a scaled size that fits within [maxWidth] x [maxHeight]
  /// while preserving the aspect ratio of [originalWidth] x [originalHeight].
  static ({double width, double height}) fitDimensions({
    required double originalWidth,
    required double originalHeight,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (originalWidth <= maxWidth && originalHeight <= maxHeight) {
      return (width: originalWidth, height: originalHeight);
    }

    final widthRatio = maxWidth / originalWidth;
    final heightRatio = maxHeight / originalHeight;
    final ratio = math.min(widthRatio, heightRatio);

    return (
      width: (originalWidth * ratio).roundToDouble(),
      height: (originalHeight * ratio).roundToDouble(),
    );
  }

  /// Converts pixel dimensions to centimeters given a known [pixelsPerCm].
  static double pixelsToCm(double pixels, double pixelsPerCm) {
    if (pixelsPerCm <= 0) return 0;
    return pixels / pixelsPerCm;
  }

  /// Converts centimeters to pixel dimensions given a known [pixelsPerCm].
  static double cmToPixels(double cm, double pixelsPerCm) {
    return cm * pixelsPerCm;
  }

  /// Calculates the area in square meters from width and height in centimeters.
  static double areaSqMeters(double widthCm, double heightCm) {
    return (widthCm * heightCm) / 10000.0;
  }

  /// Returns the file extension from a path (lowercase, without dot).
  static String getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return '';
    return path.substring(lastDot + 1).toLowerCase();
  }

  /// Validates that the file at [path] has an accepted image extension.
  static bool isValidImageExtension(String path) {
    final ext = getFileExtension(path);
    return ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].contains(ext);
  }
}
