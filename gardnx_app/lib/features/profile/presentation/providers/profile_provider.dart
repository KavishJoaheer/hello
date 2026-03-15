import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/user_profile.dart';

/// Provides a singleton instance of [ProfileRepository].
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ProfileRepository(firestore: firestore);
});

/// Streams the [UserProfile] for the currently signed-in user.
///
/// Emits `null` when no user is signed in or the profile document
/// does not exist yet.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value(null);

  final repo = ref.watch(profileRepositoryProvider);
  return repo.watchProfile(user.uid);
});

/// Provides the current user's profile as a [Future].
///
/// Useful for one-shot reads rather than streams.
final userProfileFutureProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return null;

  final repo = ref.read(profileRepositoryProvider);
  return repo.getProfile(user.uid);
});

/// Notifier that manages profile update operations.
///
/// Tracks loading/error state for profile mutations such as updating
/// the display name, preferences, or uploading a photo.
class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final ProfileRepository _repository;
  final String? _userId;

  ProfileNotifier(this._repository, this._userId)
      : super(const AsyncData(null));

  /// Updates the display name.
  Future<void> updateDisplayName(String displayName) async {
    if (_userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updateDisplayName(_userId, displayName),
    );
  }

  /// Updates plant preferences.
  Future<void> updatePreferences(PlantPreferences preferences) async {
    if (_userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updatePreferences(_userId, preferences),
    );
  }

  /// Updates location.
  Future<void> updateLocation(UserLocation location) async {
    if (_userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.updateLocation(_userId, location),
    );
  }

  /// Uploads a new profile photo.
  Future<void> uploadProfilePhoto(File imageFile) async {
    if (_userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.uploadProfilePhoto(_userId, imageFile),
    );
  }

  /// Deletes the current profile photo.
  Future<void> deleteProfilePhoto() async {
    if (_userId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteProfilePhoto(_userId),
    );
  }
}

/// Provides the [ProfileNotifier] for the currently signed-in user.
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  final user = ref.watch(currentFirebaseUserProvider);
  return ProfileNotifier(repo, user?.uid);
});
