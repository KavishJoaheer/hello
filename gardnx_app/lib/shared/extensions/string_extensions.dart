import '../enums/plant_type.dart';

/// Extension methods on [String] for common text transformations
/// used throughout the GardNx application.
extension StringExtensions on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: `'hello world'` becomes `'Hello world'`.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes the first letter of every word in the string.
  ///
  /// Example: `'hello world'` becomes `'Hello World'`.
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Converts a snake_case or kebab-case string to a display-friendly
  /// title case string.
  ///
  /// Example: `'full_sun'` becomes `'Full Sun'`.
  String get snakeToTitle {
    return replaceAll('_', ' ').replaceAll('-', ' ').titleCase;
  }

  /// Attempts to convert this string to a [PlantType] enum value.
  ///
  /// Returns `null` if no matching value is found.
  PlantType? toPlantType() {
    final lower = toLowerCase().trim();
    for (final type in PlantType.values) {
      if (type.value == lower || type.displayName.toLowerCase() == lower) {
        return type;
      }
    }
    return null;
  }

  /// Returns `true` if this string represents a valid email address.
  bool get isValidEmail {
    return RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(trim());
  }

  /// Truncates the string to [maxLength] characters, appending an
  /// ellipsis if truncated.
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Returns the string with leading and trailing whitespace removed,
  /// or `null` if the result is empty.
  String? get nullIfEmpty {
    final trimmed = trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
