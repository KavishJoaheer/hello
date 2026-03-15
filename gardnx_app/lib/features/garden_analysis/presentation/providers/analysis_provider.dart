import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/analysis_repository.dart';
import '../../domain/models/garden_photo.dart';
import '../../domain/models/segmentation_result.dart';

// ---------------------------------------------------------------------------
// Upload state
// ---------------------------------------------------------------------------

/// Represents the state of photo upload operation.
class UploadState {
  final bool isUploading;
  final double progress;
  final GardenPhoto? photo;
  final String? error;

  const UploadState({
    this.isUploading = false,
    this.progress = 0.0,
    this.photo,
    this.error,
  });

  UploadState copyWith({
    bool? isUploading,
    double? progress,
    GardenPhoto? photo,
    String? error,
  }) {
    return UploadState(
      isUploading: isUploading ?? this.isUploading,
      progress: progress ?? this.progress,
      photo: photo ?? this.photo,
      error: error,
    );
  }
}

class UploadNotifier extends StateNotifier<UploadState> {
  final AnalysisRepository _repository;
  final String? _userId;

  UploadNotifier(this._repository, this._userId)
      : super(const UploadState());

  Future<void> uploadPhoto(
    File imageFile, {
    Rect? cropRect,
  }) async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated.');
      return;
    }

    state = state.copyWith(isUploading: true, progress: 0.0, error: null);

    try {
      final photo = await _repository.uploadPhoto(
        imageFile: imageFile,
        userId: _userId,
        cropRect: cropRect,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(progress: sent / total);
          }
        },
      );

      state = state.copyWith(
        isUploading: false,
        progress: 1.0,
        photo: photo,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        error: e is AppException ? e.message : e.toString(),
      );
    }
  }

  void reset() {
    state = const UploadState();
  }
}

final uploadProvider =
    StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final repo = ref.watch(analysisRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return UploadNotifier(repo, user?.uid);
});

// ---------------------------------------------------------------------------
// Segmentation state
// ---------------------------------------------------------------------------

class SegmentationState {
  final bool isAnalyzing;
  final SegmentationResult? result;
  final String? error;

  const SegmentationState({
    this.isAnalyzing = false,
    this.result,
    this.error,
  });

  SegmentationState copyWith({
    bool? isAnalyzing,
    SegmentationResult? result,
    String? error,
  }) {
    return SegmentationState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      error: error,
    );
  }
}

class SegmentationNotifier extends StateNotifier<SegmentationState> {
  final AnalysisRepository _repository;

  SegmentationNotifier(this._repository)
      : super(const SegmentationState());

  Future<void> analyzePhoto(String photoId) async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final result = await _repository.segmentPhoto(photoId: photoId);
      state = state.copyWith(
        isAnalyzing: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchResult(String segmentationId) async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final result = await _repository.getResult(
        segmentationId: segmentationId,
      );
      state = state.copyWith(
        isAnalyzing: false,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const SegmentationState();
  }
}

final segmentationProvider =
    StateNotifierProvider<SegmentationNotifier, SegmentationState>((ref) {
  final repo = ref.watch(analysisRepositoryProvider);
  return SegmentationNotifier(repo);
});

// ---------------------------------------------------------------------------
// Selected zones
// ---------------------------------------------------------------------------

class SelectedZonesNotifier extends StateNotifier<Set<String>> {
  SelectedZonesNotifier() : super({});

  void toggleZone(String zoneId) {
    if (state.contains(zoneId)) {
      state = {...state}..remove(zoneId);
    } else {
      state = {...state, zoneId};
    }
  }

  void selectAll(List<String> zoneIds) {
    state = {...zoneIds};
  }

  void clearSelection() {
    state = {};
  }
}

final selectedZonesProvider =
    StateNotifierProvider<SelectedZonesNotifier, Set<String>>((ref) {
  return SelectedZonesNotifier();
});

// ---------------------------------------------------------------------------
// Garden creation flow
// ---------------------------------------------------------------------------

class GardenCreationState {
  final bool isSaving;
  final String? gardenId;
  final String? error;
  final String gardenName;

  const GardenCreationState({
    this.isSaving = false,
    this.gardenId,
    this.error,
    this.gardenName = '',
  });

  GardenCreationState copyWith({
    bool? isSaving,
    String? gardenId,
    String? error,
    String? gardenName,
  }) {
    return GardenCreationState(
      isSaving: isSaving ?? this.isSaving,
      gardenId: gardenId ?? this.gardenId,
      error: error,
      gardenName: gardenName ?? this.gardenName,
    );
  }
}

class GardenCreationNotifier extends StateNotifier<GardenCreationState> {
  final AnalysisRepository _repository;
  final String? _userId;

  GardenCreationNotifier(this._repository, this._userId)
      : super(const GardenCreationState());

  void setName(String name) {
    state = state.copyWith(gardenName: name);
  }

  Future<void> saveGarden({
    required GardenPhoto photo,
    required SegmentationResult segmentation,
    required Set<String> selectedZoneIds,
  }) async {
    if (_userId == null) {
      state = state.copyWith(error: 'User not authenticated.');
      return;
    }

    if (state.gardenName.trim().isEmpty) {
      state = state.copyWith(error: 'Please enter a garden name.');
      return;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final gardenId = await _repository.saveGarden(
        userId: _userId,
        name: state.gardenName.trim(),
        photo: photo,
        segmentation: segmentation,
        selectedZoneIds: selectedZoneIds.toList(),
      );

      state = state.copyWith(
        isSaving: false,
        gardenId: gardenId,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = const GardenCreationState();
  }
}

final gardenCreationProvider =
    StateNotifierProvider<GardenCreationNotifier, GardenCreationState>((ref) {
  final repo = ref.watch(analysisRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  return GardenCreationNotifier(repo, user?.uid);
});
