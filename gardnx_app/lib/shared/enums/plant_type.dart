import 'dart:ui';

/// Categorization of plants in the GardNx application.
///
/// Each type has a display name, an API/database value, and a brand color
/// used in the UI for badges, chips, and chart segments.
enum PlantType {
  vegetable('Vegetable', 'vegetable', Color(0xFF4CAF50)),
  herb('Herb', 'herb', Color(0xFF8BC34A)),
  fruit('Fruit', 'fruit', Color(0xFFFF9800)),
  flower('Flower', 'flower', Color(0xFFE91E63));

  const PlantType(this.displayName, this.value, this.color);

  /// Human-readable display name (e.g., `'Vegetable'`).
  final String displayName;

  /// API/database value (e.g., `'vegetable'`).
  final String value;

  /// Brand color associated with this plant type.
  final Color color;

  /// Attempts to parse a [PlantType] from a string [value].
  ///
  /// Matches against both [displayName] and [value]. Returns `null`
  /// if no match is found.
  static PlantType? fromString(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase().trim();
    for (final type in PlantType.values) {
      if (type.value == lower || type.displayName.toLowerCase() == lower) {
        return type;
      }
    }
    return null;
  }
}
