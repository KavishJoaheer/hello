/// Firestore collection/subcollection names and Firebase Storage path
/// constants used throughout the GardNx application.
class FirebaseConstants {
  FirebaseConstants._();

  // ---------------------------------------------------------------------------
  // Firestore collections
  // ---------------------------------------------------------------------------
  static const usersCollection = 'users';
  static const gardensCollection = 'gardens';
  static const plantsCollection = 'plants';
  static const climateCacheCollection = 'climate_cache';

  // ---------------------------------------------------------------------------
  // Firestore subcollections
  // ---------------------------------------------------------------------------
  static const bedsSubcollection = 'beds';
  static const layoutsSubcollection = 'layouts';

  // ---------------------------------------------------------------------------
  // Firebase Storage paths
  // ---------------------------------------------------------------------------
  static const photosStoragePath = 'photos';
  static const masksStoragePath = 'masks';
  static const profilePhotosPath = 'profile_photos';

  // ---------------------------------------------------------------------------
  // Firestore field names (commonly referenced)
  // ---------------------------------------------------------------------------
  static const fieldUserId = 'userId';
  static const fieldCreatedAt = 'createdAt';
  static const fieldUpdatedAt = 'updatedAt';
}
