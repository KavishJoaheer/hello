import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../../config/constants/firebase_constants.dart';
import '../../domain/models/user_profile.dart';

/// Repository that handles all Firestore CRUD operations for user profiles.
///
/// Manages the `users` collection documents that contain profile data
/// including display name, photo URL, plant preferences, and location.
class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the users collection.
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirebaseConstants.usersCollection);

  // ---------------------------------------------------------------------------
  // READ
  // ---------------------------------------------------------------------------

  /// Fetches the [UserProfile] for [userId] from Firestore.
  ///
  /// Returns `null` if no document exists for that user.
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(doc);
    } catch (e) {
      debugPrint('ProfileRepository.getProfile error: $e');
      rethrow;
    }
  }

  /// Returns a real-time stream of the [UserProfile] for [userId].
  ///
  /// Emits `null` if the document does not exist.
  Stream<UserProfile?> watchProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // ---------------------------------------------------------------------------
  // CREATE / UPDATE
  // ---------------------------------------------------------------------------

  /// Creates or fully overwrites the profile document for the given
  /// [profile].
  Future<void> createProfile(UserProfile profile) async {
    try {
      await _usersCollection.doc(profile.uid).set(
            profile.toFirestore(),
            SetOptions(merge: false),
          );
    } catch (e) {
      debugPrint('ProfileRepository.createProfile error: $e');
      rethrow;
    }
  }

  /// Merges the given [data] into the existing profile document for
  /// [userId]. Fields not present in [data] are left unchanged.
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      data[FirebaseConstants.fieldUpdatedAt] = FieldValue.serverTimestamp();
      await _usersCollection.doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ProfileRepository.updateProfile error: $e');
      rethrow;
    }
  }

  /// Updates the display name for [userId].
  Future<void> updateDisplayName(String userId, String displayName) async {
    await updateProfile(userId, {'displayName': displayName.trim()});
  }

  /// Updates the plant preferences for [userId].
  Future<void> updatePreferences(
    String userId,
    PlantPreferences preferences,
  ) async {
    await updateProfile(userId, {'preferences': preferences.toMap()});
  }

  /// Updates the location for [userId].
  Future<void> updateLocation(
    String userId,
    UserLocation location,
  ) async {
    await updateProfile(userId, {'location': location.toMap()});
  }

  // ---------------------------------------------------------------------------
  // PROFILE PHOTO
  // ---------------------------------------------------------------------------

  /// Saves a profile photo locally for [userId] and updates the profile
  /// document with the local file path.
  ///
  /// Returns the local file path of the saved photo.
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(p.join(appDir.path, 'profile_photos'));
      if (!profileDir.existsSync()) {
        profileDir.createSync(recursive: true);
      }

      final ext = imageFile.path.split('.').last.toLowerCase();
      final destPath = p.join(profileDir.path, '$userId.$ext');
      final savedFile = await imageFile.copy(destPath);

      // Update the profile document with the local photo path.
      await updateProfile(userId, {'photoUrl': savedFile.path});

      return savedFile.path;
    } catch (e) {
      debugPrint('ProfileRepository.uploadProfilePhoto error: $e');
      rethrow;
    }
  }

  /// Deletes the profile photo for [userId] locally and clears
  /// the photoUrl field in Firestore.
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory(p.join(appDir.path, 'profile_photos'));

      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        final file = File(p.join(profileDir.path, '$userId.$ext'));
        if (file.existsSync()) {
          file.deleteSync();
          break;
        }
      }

      // Clear the photoUrl in Firestore.
      await updateProfile(userId, {'photoUrl': FieldValue.delete()});
    } catch (e) {
      debugPrint('ProfileRepository.deleteProfilePhoto error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------

  /// Deletes the entire profile document for [userId].
  Future<void> deleteProfile(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      debugPrint('ProfileRepository.deleteProfile error: $e');
      rethrow;
    }
  }
}
