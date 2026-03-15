import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../providers/analysis_provider.dart';
import '../providers/camera_provider.dart';
import '../../../climate/presentation/providers/location_provider.dart';
import 'analysis_result_screen.dart';
import 'area_selection_screen.dart';

/// Screen for capturing or selecting a garden photo for AI analysis.
///
/// Provides a camera button, gallery picker, permission handling,
/// upload progress, and navigation to the analysis result screen.
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  static const routeName = '/garden/capture';

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  @override
  void initState() {
    super.initState();
    // Check permissions on screen load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraPermissionProvider.notifier).checkPermissions();
    });
  }

  Future<void> _handleTakePhoto() async {
    final permNotifier = ref.read(cameraPermissionProvider.notifier);
    final granted = await permNotifier.requestCameraPermission();

    if (!granted) {
      if (!mounted) return;
      _showPermissionDeniedDialog('Camera');
      return;
    }

    await ref.read(imagePickerProvider.notifier).takePhoto();
    _onImageSelected();
  }

  Future<void> _handlePickGallery() async {
    final permNotifier = ref.read(cameraPermissionProvider.notifier);
    final granted = await permNotifier.requestGalleryPermission();

    if (!granted) {
      // On some platforms gallery access doesn't need explicit permission.
      // Try picking anyway.
    }

    await ref.read(imagePickerProvider.notifier).pickFromGallery();
    _onImageSelected();
  }

  Future<void> _onImageSelected() async {
    final imageState = ref.read(imagePickerProvider);

    if (imageState.selectedImage != null) {
      // Check for location fallback before proceeding
      final locationInfo = ref.read(currentLocationProvider).valueOrNull;
      if (locationInfo != null && locationInfo.isFallback) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Denied'),
            content: const Text(
                'GardNx could not get your exact location. Plant recommendations will default to the North region. You can update this later in your profile.\n\nContinue anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
        if (proceed != true || !mounted) return;
      }

      // Navigate to area selection
      final rect = await Navigator.of(context).push<Rect>(
        MaterialPageRoute(
          builder: (_) => AreaSelectionScreen(
            photoPath: imageState.selectedImage!.path,
          ),
        ),
      );

      if (rect != null && mounted) {
        // Start upload with the selected bounding box
        ref.read(uploadProvider.notifier).uploadPhoto(
              imageState.selectedImage!,
              cropRect: rect,
            );
      }
    }
  }

  void _showPermissionDeniedDialog(String permission) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$permission Permission Required'),
        content: Text(
          'GardNx needs $permission access to analyze your garden. '
          'Please grant permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(cameraPermissionProvider.notifier).openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imagePickerProvider);
    final uploadState = ref.watch(uploadProvider);
    final permState = ref.watch(cameraPermissionProvider);

    // Navigate to analysis result when upload succeeds.
    ref.listen<UploadState>(uploadProvider, (prev, next) {
      if (next.photo != null && prev?.photo == null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnalysisResultScreen(photo: next.photo!),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Garden'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ----- Camera icon / preview -----
              _buildPhotoPreview(imageState),

              const SizedBox(height: 32),

              // ----- Upload progress -----
              if (uploadState.isUploading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: uploadState.progress > 0
                          ? uploadState.progress
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Uploading... ${(uploadState.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // ----- Error message -----
              if (uploadState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          uploadState.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (imageState.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          imageState.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ----- Permanently denied banner -----
              if (permState.permanentlyDenied) ...[
                Card(
                  color: AppColors.warningContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Permissions required',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Camera or gallery access was denied. '
                                'Please enable it in settings.',
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  ref
                                      .read(
                                          cameraPermissionProvider.notifier)
                                      .openSettings();
                                },
                                child: const Text('Open Settings'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ----- Take Photo button -----
              FilledButton.icon(
                onPressed: uploadState.isUploading ? null : _handleTakePhoto,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Take Photo'),
              ),

              const SizedBox(height: 12),

              // ----- Choose from Gallery button -----
              OutlinedButton.icon(
                onPressed:
                    uploadState.isUploading ? null : _handlePickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Gallery'),
              ),

              // ----- Manual mode button (shown when image selected) -----
              if (imageState.selectedImage != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.manualInput,
                      extra: <String, dynamic>{
                        'imagePath': imageState.selectedImage!.path,
                      },
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Skip Upload — Edit Manually'),
                ),
              ],

              const Spacer(flex: 3),

              // ----- Hint text -----
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Take a photo of your garden for AI analysis.\n'
                  'For best results, capture the entire area from above.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(ImagePickerState imageState) {
    if (imageState.selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(
          imageState.selectedImage!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      child: Icon(
        Icons.camera_alt_rounded,
        size: 64,
        color: AppColors.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
