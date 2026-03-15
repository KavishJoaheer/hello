import 'package:gardnx_app/features/layout_planner/domain/models/plant_placement.dart';
import 'package:gardnx_app/features/layout_planner/domain/models/layout_suggestion.dart';

class GardenLayout {
  final String? id;
  final String gardenId;
  final String bedId;
  final int gridRows;
  final int gridCols;
  final double cellSizeCm;
  final List<PlantPlacement> placements;
  final List<LayoutWarning> warnings;
  final DateTime? generatedAt;
  final double? utilizationPercent;

  const GardenLayout({
    this.id,
    required this.gardenId,
    required this.bedId,
    required this.gridRows,
    required this.gridCols,
    required this.cellSizeCm,
    this.placements = const [],
    this.warnings = const [],
    this.generatedAt,
    this.utilizationPercent,
  });

  factory GardenLayout.fromJson(Map<String, dynamic> json) {
    // Backend wraps grid dimensions inside 'statistics'
    final stats = json['statistics'] as Map<String, dynamic>? ?? {};
    return GardenLayout(
      id: json['id'] as String?,
      gardenId: json['garden_id'] as String? ?? '',
      bedId: json['bed_id'] as String? ?? '',
      gridRows: (json['grid_rows'] as int?) ??
          (stats['grid_rows'] as int?) ?? 5,
      gridCols: (json['grid_cols'] as int?) ??
          (stats['grid_cols'] as int?) ?? 5,
      cellSizeCm: ((json['cell_size_cm'] as num?) ??
          (stats['cell_size_cm'] as num?) ?? 30.0).toDouble(),
      placements: (json['placements'] as List<dynamic>? ?? [])
          .map((e) => PlantPlacement.fromJson(e as Map<String, dynamic>))
          .toList(),
      warnings: (json['warnings'] as List<dynamic>? ?? [])
          .map((e) => e is String
              ? LayoutWarning(type: 'general', message: e)
              : LayoutWarning.fromJson(e as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'] as String)
          : null,
      utilizationPercent:
          (json['utilization_percent'] as num?)?.toDouble() ??
          (stats['utilization_percent'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'garden_id': gardenId,
        'bed_id': bedId,
        'grid_rows': gridRows,
        'grid_cols': gridCols,
        'cell_size_cm': cellSizeCm,
        'placements': placements.map((p) => p.toJson()).toList(),
        'warnings': warnings.map((w) => w.toJson()).toList(),
        'generated_at': generatedAt?.toIso8601String(),
        'utilization_percent': utilizationPercent,
      };

  int get totalCells => gridRows * gridCols;

  int get occupiedCells =>
      placements.fold(0, (sum, p) => sum + p.cellsOccupied);

  double get actualUtilization =>
      totalCells > 0 ? occupiedCells / totalCells : 0;

  GardenLayout copyWith({
    String? id,
    String? gardenId,
    String? bedId,
    int? gridRows,
    int? gridCols,
    double? cellSizeCm,
    List<PlantPlacement>? placements,
    List<LayoutWarning>? warnings,
    DateTime? generatedAt,
    double? utilizationPercent,
  }) {
    return GardenLayout(
      id: id ?? this.id,
      gardenId: gardenId ?? this.gardenId,
      bedId: bedId ?? this.bedId,
      gridRows: gridRows ?? this.gridRows,
      gridCols: gridCols ?? this.gridCols,
      cellSizeCm: cellSizeCm ?? this.cellSizeCm,
      placements: placements ?? this.placements,
      warnings: warnings ?? this.warnings,
      generatedAt: generatedAt ?? this.generatedAt,
      utilizationPercent: utilizationPercent ?? this.utilizationPercent,
    );
  }
}
