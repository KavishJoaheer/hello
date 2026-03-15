import 'dart:ui';

import '../../../../config/theme/app_colors.dart';

/// Represents a detected zone within a garden photo segmentation result.
class GardenZone {
  final String zoneId;
  final String type;
  final double confidence;
  final List<Offset> polygon;
  final double areaSqMeters;
  final bool isSelected;

  const GardenZone({
    required this.zoneId,
    required this.type,
    this.confidence = 0.0,
    this.polygon = const [],
    this.areaSqMeters = 0.0,
    this.isSelected = false,
  });

  /// Returns the display color for this zone type, matching the backend
  /// ZoneType definitions and [AppColors] zone constants.
  Color get color {
    switch (type.toLowerCase()) {
      case 'soil':
      case 'bare_soil':
        return AppColors.zoneSoil;
      case 'lawn':
      case 'grass':
        return AppColors.zoneLawn;
      case 'path':
      case 'paved':
      case 'walkway':
        return AppColors.zonePath;
      case 'shade':
      case 'shaded':
        return AppColors.zoneShade;
      case 'existing_plant':
      case 'vegetation':
        return AppColors.zoneExistingPlant;
      case 'sun':
      case 'sunny':
      case 'full_sun':
        return AppColors.zoneSun;
      case 'background':
      default:
        return AppColors.zoneBackground;
    }
  }

  /// Returns a user-friendly display label for this zone type.
  String get displayLabel {
    switch (type.toLowerCase()) {
      case 'soil':
      case 'bare_soil':
        return 'Soil';
      case 'lawn':
      case 'grass':
        return 'Lawn';
      case 'path':
      case 'paved':
      case 'walkway':
        return 'Path';
      case 'shade':
      case 'shaded':
        return 'Shade';
      case 'existing_plant':
      case 'vegetation':
        return 'Vegetation';
      case 'sun':
      case 'sunny':
      case 'full_sun':
        return 'Full Sun';
      case 'background':
        return 'Background';
      default:
        return type;
    }
  }

  /// Creates a [GardenZone] from a JSON response map.
  factory GardenZone.fromJson(Map<String, dynamic> json) {
    final polygonJson = json['polygon'] as List<dynamic>? ?? [];
    return GardenZone(
      // Accept both camelCase (Firestore) and snake_case (backend API)
      zoneId: (json['zoneId'] ?? json['zone_id']) as String? ?? '',
      type: json['type'] as String? ?? 'background',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      polygon: polygonJson.map((p) {
        if (p is Map<String, dynamic>) {
          return Offset(
            (p['x'] as num?)?.toDouble() ?? 0.0,
            (p['y'] as num?)?.toDouble() ?? 0.0,
          );
        }
        if (p is List) {
          return Offset(
            (p[0] as num?)?.toDouble() ?? 0.0,
            (p[1] as num?)?.toDouble() ?? 0.0,
          );
        }
        return Offset.zero;
      }).toList(),
      areaSqMeters: ((json['areaSqMeters'] ?? json['area_sq_meters']) as num?)?.toDouble() ?? 0.0,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'zoneId': zoneId,
      'type': type,
      'confidence': confidence,
      'polygon': polygon
          .map((p) => {'x': p.dx, 'y': p.dy})
          .toList(),
      'areaSqMeters': areaSqMeters,
      'isSelected': isSelected,
    };
  }

  GardenZone copyWith({
    String? zoneId,
    String? type,
    double? confidence,
    List<Offset>? polygon,
    double? areaSqMeters,
    bool? isSelected,
  }) {
    return GardenZone(
      zoneId: zoneId ?? this.zoneId,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      polygon: polygon ?? this.polygon,
      areaSqMeters: areaSqMeters ?? this.areaSqMeters,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GardenZone && other.zoneId == zoneId;
  }

  @override
  int get hashCode => zoneId.hashCode;

  @override
  String toString() =>
      'GardenZone(id: $zoneId, type: $type, confidence: $confidence, '
      'area: $areaSqMeters, selected: $isSelected)';
}
