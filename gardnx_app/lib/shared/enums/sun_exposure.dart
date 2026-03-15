/// Represents the level of sun exposure for a garden area or plant
/// requirement.
enum SunExposure {
  fullSun('Full Sun', 'full_sun'),
  partialShade('Partial Shade', 'partial_shade'),
  fullShade('Full Shade', 'full_shade');

  const SunExposure(this.displayName, this.value);

  /// Human-readable display name (e.g., `'Full Sun'`).
  final String displayName;

  /// API/database value (e.g., `'full_sun'`).
  final String value;

  /// Attempts to parse a [SunExposure] from a string [value].
  ///
  /// Matches against both [displayName] and [value]. Returns `null`
  /// if no match is found.
  static SunExposure? fromString(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase().trim();
    for (final exposure in SunExposure.values) {
      if (exposure.value == lower ||
          exposure.displayName.toLowerCase() == lower) {
        return exposure;
      }
    }
    return null;
  }
}
