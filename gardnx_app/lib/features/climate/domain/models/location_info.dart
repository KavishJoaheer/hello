class LocationInfo {
  final double latitude;
  final double longitude;
  final String region;
  final bool autoDetected;
  final bool isInMauritius;
  final bool isFallback;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.region,
    this.autoDetected = false,
    this.isInMauritius = true,
    this.isFallback = false,
  });

  static const double _latMin = -20.53;
  static const double _latMax = -19.96;
  static const double _lonMin = 57.30;
  static const double _lonMax = 57.81;

  static bool checkIsInMauritius(double lat, double lon) {
    return lat >= _latMin && lat <= _latMax && lon >= _lonMin && lon <= _lonMax;
  }

  static String determineRegion(double lat, double lon) {
    if (lat > -20.1) return 'north';
    if (lat < -20.4) return 'south';
    if (lon > 57.65) return 'east';
    if (lon < 57.45) return 'west';
    return 'central';
  }

  factory LocationInfo.fromLatLon(double lat, double lon) {
    return LocationInfo(
      latitude: lat,
      longitude: lon,
      region: determineRegion(lat, lon),
      autoDetected: true,
      isInMauritius: checkIsInMauritius(lat, lon),
    );
  }

  static LocationInfo defaultNorth() => const LocationInfo(
        latitude: -20.16,
        longitude: 57.50,
        region: 'north',
        autoDetected: false,
        isInMauritius: true,
        isFallback: true,
      );

  LocationInfo copyWith({
    double? latitude,
    double? longitude,
    String? region,
    bool? autoDetected,
    bool? isInMauritius,
    bool? isFallback,
  }) {
    return LocationInfo(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      autoDetected: autoDetected ?? this.autoDetected,
      isInMauritius: isInMauritius ?? this.isInMauritius,
      isFallback: isFallback ?? this.isFallback,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'region': region,
        'auto_detected': autoDetected,
        'is_in_mauritius': isInMauritius,
        'is_fallback': isFallback,
      };

  factory LocationInfo.fromJson(Map<String, dynamic> json) => LocationInfo(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        region: json['region'] as String,
        autoDetected: json['auto_detected'] as bool? ?? false,
        isInMauritius: json['is_in_mauritius'] as bool? ?? true,
        isFallback: json['is_fallback'] as bool? ?? false,
      );
}
