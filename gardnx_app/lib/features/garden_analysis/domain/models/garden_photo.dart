/// Represents a photo of a garden captured or selected by the user.
class GardenPhoto {
  final String id;
  final String userId;
  final String? imageUrl;
  final String? localPath;
  final int width;
  final int height;
  final DateTime createdAt;

  GardenPhoto({
    required this.id,
    required this.userId,
    this.imageUrl,
    this.localPath,
    this.width = 0,
    this.height = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a [GardenPhoto] from a Firestore document map.
  factory GardenPhoto.fromFirestore(Map<String, dynamic> map) {
    return GardenPhoto(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      localPath: map['localPath'] as String?,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Creates a [GardenPhoto] from a JSON response map.
  factory GardenPhoto.fromJson(Map<String, dynamic> json) {
    return GardenPhoto(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      localPath: json['localPath'] as String?,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  /// Converts to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'localPath': localPath,
      'width': width,
      'height': height,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() => toFirestore();

  GardenPhoto copyWith({
    String? id,
    String? userId,
    String? imageUrl,
    String? localPath,
    int? width,
    int? height,
    DateTime? createdAt,
  }) {
    return GardenPhoto(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GardenPhoto && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'GardenPhoto(id: $id, userId: $userId, imageUrl: $imageUrl)';
}
