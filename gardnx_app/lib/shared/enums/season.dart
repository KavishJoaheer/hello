/// Mauritius seasons used for planting calendar and climate-based
/// recommendations.
///
/// Mauritius has a tropical maritime climate with two primary seasons
/// and four gardening-relevant sub-seasons.
enum Season {
  /// Hot and wet season: December - March.
  /// Peak growing season for tropical vegetables and fruits.
  hotWet(
    'Hot Wet',
    'hot_wet',
    [12, 1, 2, 3],
    'Peak growing season - ideal for tropical crops',
  ),

  /// Cool transition: April - May.
  /// Harvest period and preparation for cool-season crops.
  coolTransition(
    'Cool Transition',
    'cool_transition',
    [4, 5],
    'Harvest period - prepare for cool-season planting',
  ),

  /// Cool and dry season: June - September.
  /// Best for leafy greens, root vegetables, and herbs.
  coolDry(
    'Cool Dry',
    'cool_dry',
    [6, 7, 8, 9],
    'Best for leafy greens, root vegetables, and herbs',
  ),

  /// Warm transition: October - November.
  /// Preparation period for summer planting.
  warmTransition(
    'Warm Transition',
    'warm_transition',
    [10, 11],
    'Preparation for summer planting season',
  );

  const Season(
    this.displayName,
    this.value,
    this.months,
    this.description,
  );

  /// Human-readable display name (e.g., `'Hot Wet'`).
  final String displayName;

  /// API/database value (e.g., `'hot_wet'`).
  final String value;

  /// Month numbers (1-12) that fall within this season.
  final List<int> months;

  /// Short description of what this season means for gardening.
  final String description;

  /// Returns the [Season] for the given [month] number (1-12).
  static Season fromMonth(int month) {
    for (final season in Season.values) {
      if (season.months.contains(month)) return season;
    }
    // Fallback (should not happen with valid month 1-12).
    return Season.hotWet;
  }

  /// Returns the current season based on today's date.
  static Season get current => fromMonth(DateTime.now().month);

  /// Attempts to parse a [Season] from a string [value].
  static Season? fromString(String? value) {
    if (value == null) return null;
    final lower = value.toLowerCase().trim();
    for (final season in Season.values) {
      if (season.value == lower ||
          season.displayName.toLowerCase() == lower) {
        return season;
      }
    }
    return null;
  }
}
