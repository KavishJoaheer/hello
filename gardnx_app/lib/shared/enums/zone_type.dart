import 'dart:ui';

import '../../config/theme/app_colors.dart';

/// Zone types identified during garden image segmentation.
///
/// Colors match the Python backend `ZoneType` class to ensure consistent
/// visual representation between analysis results and the Flutter UI.
enum ZoneType {
  background(
    'Background',
    'background',
    AppColors.zoneBackground,
    'Areas outside the garden boundaries',
  ),
  soil(
    'Soil',
    'soil',
    AppColors.zoneSoil,
    'Bare soil suitable for planting',
  ),
  lawn(
    'Lawn',
    'lawn',
    AppColors.zoneLawn,
    'Grass or lawn areas',
  ),
  path(
    'Path',
    'path',
    AppColors.zonePath,
    'Walkways, paths, or paved areas',
  ),
  shade(
    'Shade',
    'shade',
    AppColors.zoneShade,
    'Shaded areas from trees or structures',
  ),
  existingPlant(
    'Existing Plant',
    'existing_plant',
    AppColors.zoneExistingPlant,
    'Areas with existing vegetation',
  ),
  sun(
    'Sun',
    'sun',
    AppColors.zoneSun,
    'Areas receiving full sunlight',
  );

  const ZoneType(
    this.displayName,
    this.value,
    this.color,
    this.description,
  );

  /// Human-readable display name (e.g., `'Existing Plant'`).
  final String displayName;

  /// API/database value (e.g., `'existing_plant'`).
  final String value;

  /// Color used to render this zone type in the UI and overlay masks.
  final Color color;

  /// Short description of what this zone type represents.
  final String description;

  /// Whether this zone type represents a plantable area.
  bool get isPlantable => this == soil || this == sun;

  /// Attempts to parse a [ZoneType] from a string [value].
  static ZoneType? fromString(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase().trim();
    for (final zone in ZoneType.values) {
      if (zone.value == lower || zone.displayName.toLowerCase() == lower) {
        return zone;
      }
    }
    return null;
  }
}
