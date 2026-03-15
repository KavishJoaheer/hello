import 'garden_zone.dart';

/// Result of the AI segmentation analysis performed on a garden photo.
class SegmentationResult {
  final String segmentationId;
  final List<GardenZone> zones;
  final String? maskUrl;
  final int processingTimeMs;
  final bool fallbackRecommended;

  const SegmentationResult({
    required this.segmentationId,
    required this.zones,
    this.maskUrl,
    this.processingTimeMs = 0,
    this.fallbackRecommended = false,
  });

  /// Creates a [SegmentationResult] from a JSON response map.
  factory SegmentationResult.fromJson(Map<String, dynamic> json) {
    final zonesJson = json['zones'] as List<dynamic>? ?? [];
    return SegmentationResult(
      // Accept both camelCase (Firestore) and snake_case (backend API)
      segmentationId: (json['segmentationId'] ?? json['segmentation_id']) as String? ?? '',
      zones: zonesJson
          .map((z) => GardenZone.fromJson(z as Map<String, dynamic>))
          .toList(),
      maskUrl: (json['maskUrl'] ?? json['mask_url']) as String?,
      processingTimeMs: ((json['processingTimeMs'] ?? json['processing_time_ms']) as num?)?.toInt() ?? 0,
      fallbackRecommended: (json['fallbackRecommended'] ?? json['fallback_recommended']) as bool? ?? false,
    );
  }

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'segmentationId': segmentationId,
      'zones': zones.map((z) => z.toJson()).toList(),
      'maskUrl': maskUrl,
      'processingTimeMs': processingTimeMs,
      'fallbackRecommended': fallbackRecommended,
    };
  }

  /// Returns a copy with zones having updated selection states.
  SegmentationResult withZoneSelection(String zoneId, bool isSelected) {
    return SegmentationResult(
      segmentationId: segmentationId,
      zones: zones.map((z) {
        if (z.zoneId == zoneId) {
          return z.copyWith(isSelected: isSelected);
        }
        return z;
      }).toList(),
      maskUrl: maskUrl,
      processingTimeMs: processingTimeMs,
      fallbackRecommended: fallbackRecommended,
    );
  }

  /// Returns the list of currently selected zones.
  List<GardenZone> get selectedZones =>
      zones.where((z) => z.isSelected).toList();

  /// Returns the total area of selected zones.
  double get totalSelectedArea =>
      selectedZones.fold(0.0, (sum, z) => sum + z.areaSqMeters);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SegmentationResult &&
        other.segmentationId == segmentationId;
  }

  @override
  int get hashCode => segmentationId.hashCode;

  @override
  String toString() =>
      'SegmentationResult(id: $segmentationId, zones: ${zones.length}, '
      'fallback: $fallbackRecommended)';
}
