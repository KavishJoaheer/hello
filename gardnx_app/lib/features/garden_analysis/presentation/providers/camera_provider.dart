import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------------
// Permission state
// ---------------------------------------------------------------------------

/// Tracks camera and gallery permission status.
class CameraPermissionState {
  final bool cameraGranted;
  final bool galleryGranted;
  final bool permanentlyDenied;
  final bool isChecking;

  const CameraPermissionState({
    this.cameraGranted = false,
    this.galleryGranted = false,
    this.permanentlyDenied = false,
    this.isChecking = false,
  });

  CameraPermissionState copyWith({
    bool? cameraGranted,
    bool? galleryGranted,
    bool? permanentlyDenied,
    bool? isChecking,
  }) {
    return CameraPermissionState(
      cameraGranted: cameraGranted ?? this.cameraGranted,
      galleryGranted: galleryGranted ?? this.galleryGranted,
      permanentlyDenied: permanentlyDenied ?? this.permanentlyDenied,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class CameraPermissionNotifier extends StateNotifier<CameraPermissionState> {
  CameraPermissionNotifier() : super(const CameraPermissionState());

  /// Checks the current permission status without requesting.
  Future<void> checkPermissions() async {
    state = state.copyWith(isChecking: true);

    final cameraStatus = await Permission.camera.status;
    final galleryStatus = await Permission.photos.status;

    state = state.copyWith(
      isChecking: false,
      cameraGranted: cameraStatus.isGranted,
      galleryGranted: galleryStatus.isGranted || galleryStatus.isLimited,
      permanentlyDenied:
          cameraStatus.isPermanentlyDenied ||
          galleryStatus.isPermanentlyDenied,
    );
  }

  /// Requests camera permission.
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();

    state = state.copyWith(
      cameraGranted: status.isGranted,
      permanentlyDenied: status.isPermanentlyDenied,
    );

    return status.isGranted;
  }

  /// Requests gallery/photos permission.
  Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();

    state = state.copyWith(
      galleryGranted: status.isGranted || status.isLimited,
      permanentlyDenied: status.isPermanentlyDenied,
    );

    return status.isGranted || status.isLimited;
  }

  /// Opens app settings so the user can manually grant permissions.
  Future<void> openSettings() async {
    await openAppSettings();
  }
}

final cameraPermissionProvider =
    StateNotifierProvider<CameraPermissionNotifier, CameraPermissionState>(
        (ref) {
  return CameraPermissionNotifier();
});

// ---------------------------------------------------------------------------
// Image picker state
// ---------------------------------------------------------------------------

/// State for the image selection process.
class ImagePickerState {
  final bool isPicking;
  final File? selectedImage;
  final String? error;

  const ImagePickerState({
    this.isPicking = false,
    this.selectedImage,
    this.error,
  });

  ImagePickerState copyWith({
    bool? isPicking,
    File? selectedImage,
    String? error,
  }) {
    return ImagePickerState(
      isPicking: isPicking ?? this.isPicking,
      selectedImage: selectedImage ?? this.selectedImage,
      error: error,
    );
  }
}

class ImagePickerNotifier extends StateNotifier<ImagePickerState> {
  final ImagePicker _picker;

  ImagePickerNotifier() : _picker = ImagePicker(), super(const ImagePickerState());

  /// Takes a photo using the device camera.
  Future<void> takePhoto() async {
    state = state.copyWith(isPicking: true, error: null);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (photo != null) {
        state = state.copyWith(
          isPicking: false,
          selectedImage: File(photo.path),
        );
      } else {
        state = state.copyWith(isPicking: false);
      }
    } catch (e) {
      state = state.copyWith(
        isPicking: false,
        error: 'Failed to capture photo: ${e.toString()}',
      );
    }
  }

  /// Picks an image from the device gallery.
  Future<void> pickFromGallery() async {
    state = state.copyWith(isPicking: true, error: null);

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (image != null) {
        state = state.copyWith(
          isPicking: false,
          selectedImage: File(image.path),
        );
      } else {
        state = state.copyWith(isPicking: false);
      }
    } catch (e) {
      state = state.copyWith(
        isPicking: false,
        error: 'Failed to pick image: ${e.toString()}',
      );
    }
  }

  /// Clears the selected image.
  void clearImage() {
    state = const ImagePickerState();
  }
}

final imagePickerProvider =
    StateNotifierProvider<ImagePickerNotifier, ImagePickerState>((ref) {
  return ImagePickerNotifier();
});
