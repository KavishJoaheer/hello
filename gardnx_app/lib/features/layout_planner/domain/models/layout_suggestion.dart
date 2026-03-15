import 'package:gardnx_app/features/layout_planner/domain/models/plant_placement.dart';

class LayoutSuggestion {
  final String plantId;
  final String plantName;
  final double suitabilityScore;
  final List<String> reasons;
  final List<String> companionNames;
  final int maxCount;
  final List<PlantPlacement>? suggestedPlacements;

  const LayoutSuggestion({
    required this.plantId,
    required this.plantName,
    required this.suitabilityScore,
    required this.reasons,
    this.companionNames = const [],
    required this.maxCount,
    this.suggestedPlacements,
  });

  factory LayoutSuggestion.fromJson(Map<String, dynamic> json) =>
      LayoutSuggestion(
        plantId: json['plant_id'] as String,
        plantName: json['plant_name'] as String,
        suitabilityScore:
            (json['suitability_score'] as num? ?? 0.8).toDouble(),
        reasons:
            (json['reasons'] as List<dynamic>? ?? []).cast<String>(),
        companionNames:
            (json['companion_names'] as List<dynamic>? ?? []).cast<String>(),
        maxCount: json['max_count'] as int? ?? 1,
        suggestedPlacements: (json['suggested_placements'] as List<dynamic>?)
            ?.map((e) =>
                PlantPlacement.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'plant_id': plantId,
        'plant_name': plantName,
        'suitability_score': suitabilityScore,
        'reasons': reasons,
        'companion_names': companionNames,
        'max_count': maxCount,
        'suggested_placements':
            suggestedPlacements?.map((p) => p.toJson()).toList(),
      };
}

class LayoutWarning {
  final String type; // 'spacing', 'companion', 'climate', 'capacity'
  final String message;
  final String? plantId;
  final int? row;
  final int? col;

  const LayoutWarning({
    required this.type,
    required this.message,
    this.plantId,
    this.row,
    this.col,
  });

  factory LayoutWarning.fromJson(Map<String, dynamic> json) => LayoutWarning(
        type: json['type'] as String? ?? 'general',
        message: json['message'] as String,
        plantId: json['plant_id'] as String?,
        row: json['row'] as int?,
        col: json['col'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'message': message,
        'plant_id': plantId,
        'row': row,
        'col': col,
      };
}
