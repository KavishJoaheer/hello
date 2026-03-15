/// Constants related to plant spacing, Mauritius geography, and default
/// garden configuration values.
class PlantConstants {
  PlantConstants._();

  // ---------------------------------------------------------------------------
  // Mauritius bounding box
  // ---------------------------------------------------------------------------
  /// South-west corner latitude of Mauritius bounding box.
  static const double mauritiusLatMin = -20.525;

  /// North-east corner latitude of Mauritius bounding box.
  static const double mauritiusLatMax = -19.968;

  /// South-west corner longitude of Mauritius bounding box.
  static const double mauritiusLonMin = 57.307;

  /// North-east corner longitude of Mauritius bounding box.
  static const double mauritiusLonMax = 57.807;

  /// Center latitude of Mauritius (approximate).
  static const double mauritiusCenterLat = -20.2485;

  /// Center longitude of Mauritius (approximate).
  static const double mauritiusCenterLon = 57.5522;

  // ---------------------------------------------------------------------------
  // Default spacing values (centimeters)
  // ---------------------------------------------------------------------------
  /// Default minimum spacing between plants in centimeters.
  static const double defaultMinSpacingCm = 15.0;

  /// Default maximum spacing between plants in centimeters.
  static const double defaultMaxSpacingCm = 90.0;

  /// Default row spacing in centimeters.
  static const double defaultRowSpacingCm = 30.0;

  /// Minimum bed dimension in centimeters.
  static const double minBedDimensionCm = 30.0;

  /// Maximum bed dimension in centimeters.
  static const double maxBedDimensionCm = 1000.0;

  // ---------------------------------------------------------------------------
  // Plant type information
  // ---------------------------------------------------------------------------
  /// Available plant type identifiers.
  static const List<String> plantTypes = [
    'vegetable',
    'herb',
    'fruit',
    'flower',
  ];

  /// Human-readable labels for plant types.
  static const Map<String, String> plantTypeLabels = {
    'vegetable': 'Vegetable',
    'herb': 'Herb',
    'fruit': 'Fruit',
    'flower': 'Flower',
  };

  /// Experience levels available for user preferences.
  static const List<String> experienceLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];

  /// Human-readable labels for experience levels.
  static const Map<String, String> experienceLevelLabels = {
    'beginner': 'Beginner',
    'intermediate': 'Intermediate',
    'advanced': 'Advanced',
  };

  // ---------------------------------------------------------------------------
  // Image constraints
  // ---------------------------------------------------------------------------
  /// Maximum image width for uploads (pixels).
  static const int maxImageWidth = 1920;

  /// Maximum image height for uploads (pixels).
  static const int maxImageHeight = 1080;

  /// Maximum file size for image uploads (bytes) - 10 MB.
  static const int maxImageSizeBytes = 10 * 1024 * 1024;

  /// JPEG compression quality (0-100).
  static const int imageCompressionQuality = 85;
}
