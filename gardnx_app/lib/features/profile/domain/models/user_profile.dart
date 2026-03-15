import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// PlantPreferences
// ---------------------------------------------------------------------------

/// Represents the gardening preferences selected by a user.
class PlantPreferences {
  /// The types of plants the user is interested in growing.
  final List<String> plantTypes;

  /// Self-reported experience level: beginner, intermediate, or advanced.
  final String experienceLevel;

  const PlantPreferences({
    this.plantTypes = const [],
    this.experienceLevel = 'beginner',
  });

  factory PlantPreferences.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PlantPreferences();
    return PlantPreferences(
      plantTypes: List<String>.from(map['plantTypes'] ?? []),
      experienceLevel: map['experienceLevel'] as String? ?? 'beginner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plantTypes': plantTypes,
      'experienceLevel': experienceLevel,
    };
  }

  PlantPreferences copyWith({
    List<String>? plantTypes,
    String? experienceLevel,
  }) {
    return PlantPreferences(
      plantTypes: plantTypes ?? this.plantTypes,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PlantPreferences) return false;
    if (other.experienceLevel != experienceLevel) return false;
    if (other.plantTypes.length != plantTypes.length) return false;
    for (int i = 0; i < plantTypes.length; i++) {
      if (other.plantTypes[i] != plantTypes[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(plantTypes),
        experienceLevel,
      );

  @override
  String toString() =>
      'PlantPreferences(plantTypes: $plantTypes, experienceLevel: $experienceLevel)';
}

// ---------------------------------------------------------------------------
// UserLocation
// ---------------------------------------------------------------------------

/// Represents the user's geographical location, optionally auto-detected.
class UserLocation {
  final double? latitude;
  final double? longitude;
  final String? region;
  final bool autoDetected;

  const UserLocation({
    this.latitude,
    this.longitude,
    this.region,
    this.autoDetected = false,
  });

  factory UserLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserLocation();
    return UserLocation(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      region: map['region'] as String?,
      autoDetected: map['autoDetected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'autoDetected': autoDetected,
    };
  }

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? region,
    bool? autoDetected,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      autoDetected: autoDetected ?? this.autoDetected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.region == region &&
        other.autoDetected == autoDetected;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, region, autoDetected);

  @override
  String toString() =>
      'UserLocation(lat: $latitude, lon: $longitude, region: $region, '
      'autoDetected: $autoDetected)';
}

// ---------------------------------------------------------------------------
// UserProfile
// ---------------------------------------------------------------------------

/// Full user profile stored in the Firestore `users` collection.
class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final PlantPreferences preferences;
  final UserLocation location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.preferences = const PlantPreferences(),
    this.location = const UserLocation(),
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [UserProfile] from a Firestore document snapshot.
  factory UserProfile.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      preferences: PlantPreferences.fromMap(
        data['preferences'] as Map<String, dynamic>?,
      ),
      location: UserLocation.fromMap(
        data['location'] as Map<String, dynamic>?,
      ),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Creates a [UserProfile] from a plain map.
  factory UserProfile.fromMap(Map<String, dynamic> map,
      {required String uid}) {
    return UserProfile(
      uid: uid,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      preferences: PlantPreferences.fromMap(
        map['preferences'] as Map<String, dynamic>?,
      ),
      location: UserLocation.fromMap(
        map['location'] as Map<String, dynamic>?,
      ),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt:
          (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts the profile to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'preferences': preferences.toMap(),
      'location': location.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Returns a copy with the given fields replaced.
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    PlantPreferences? preferences,
    UserLocation? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      preferences: preferences ?? this.preferences,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.preferences == preferences &&
        other.location == location &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
        uid,
        email,
        displayName,
        photoUrl,
        preferences,
        location,
        createdAt,
        updatedAt,
      );

  @override
  String toString() =>
      'UserProfile(uid: $uid, email: $email, displayName: $displayName, '
      'preferences: $preferences, location: $location)';
}
