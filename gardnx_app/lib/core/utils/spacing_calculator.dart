import 'dart:math' as math;

import '../../config/constants/plant_constants.dart';

/// Result of a spacing calculation containing the number of plants
/// that can fit in a bed and the recommended layout grid.
class SpacingResult {
  /// Total number of plants that fit in the bed.
  final int totalPlants;

  /// Number of rows.
  final int rows;

  /// Number of columns.
  final int columns;

  /// Actual spacing between plants in centimeters.
  final double spacingCm;

  /// Actual spacing between rows in centimeters.
  final double rowSpacingCm;

  /// Leftover margin on the width axis (centimeters).
  final double widthMarginCm;

  /// Leftover margin on the height axis (centimeters).
  final double heightMarginCm;

  const SpacingResult({
    required this.totalPlants,
    required this.rows,
    required this.columns,
    required this.spacingCm,
    required this.rowSpacingCm,
    required this.widthMarginCm,
    required this.heightMarginCm,
  });

  @override
  String toString() =>
      'SpacingResult(plants: $totalPlants, rows: $rows, cols: $columns, '
      'spacing: ${spacingCm}cm, rowSpacing: ${rowSpacingCm}cm)';
}

/// Calculator for plant spacing within garden beds.
///
/// Given bed dimensions and plant spacing requirements, computes how many
/// plants can fit and their optimal arrangement.
class SpacingCalculator {
  SpacingCalculator._();

  /// Calculates how many plants can fit in a bed of [bedWidthCm] x
  /// [bedHeightCm] with the given [plantSpacingCm] between plants and
  /// [rowSpacingCm] between rows.
  ///
  /// An optional [edgeMarginCm] specifies the minimum distance from the
  /// bed edge to the first/last plant (defaults to half the plant spacing).
  static SpacingResult calculateGrid({
    required double bedWidthCm,
    required double bedHeightCm,
    required double plantSpacingCm,
    double? rowSpacingCm,
    double? edgeMarginCm,
  }) {
    final effectiveRowSpacing =
        rowSpacingCm ?? plantSpacingCm;
    final margin = edgeMarginCm ?? (plantSpacingCm / 2);

    // Usable dimensions after accounting for edge margins.
    final usableWidth = bedWidthCm - (2 * margin);
    final usableHeight = bedHeightCm - (2 * margin);

    if (usableWidth <= 0 || usableHeight <= 0) {
      return const SpacingResult(
        totalPlants: 0,
        rows: 0,
        columns: 0,
        spacingCm: 0,
        rowSpacingCm: 0,
        widthMarginCm: 0,
        heightMarginCm: 0,
      );
    }

    // Number of columns along the width.
    final columns = (usableWidth / plantSpacingCm).floor() + 1;

    // Number of rows along the height.
    final rows = (usableHeight / effectiveRowSpacing).floor() + 1;

    // Actual margins (centering the grid in the bed).
    final actualWidthUsed =
        (columns > 1) ? (columns - 1) * plantSpacingCm : 0.0;
    final actualHeightUsed =
        (rows > 1) ? (rows - 1) * effectiveRowSpacing : 0.0;

    final widthMargin = (bedWidthCm - actualWidthUsed) / 2;
    final heightMargin = (bedHeightCm - actualHeightUsed) / 2;

    return SpacingResult(
      totalPlants: math.max(0, rows * columns),
      rows: math.max(0, rows),
      columns: math.max(0, columns),
      spacingCm: plantSpacingCm,
      rowSpacingCm: effectiveRowSpacing,
      widthMarginCm: widthMargin,
      heightMarginCm: heightMargin,
    );
  }

  /// Validates that the given spacing values are within acceptable bounds.
  static bool isSpacingValid(double spacingCm) {
    return spacingCm >= PlantConstants.defaultMinSpacingCm &&
        spacingCm <= PlantConstants.defaultMaxSpacingCm;
  }

  /// Validates that bed dimensions are within acceptable bounds.
  static bool areDimensionsValid(double widthCm, double heightCm) {
    return widthCm >= PlantConstants.minBedDimensionCm &&
        widthCm <= PlantConstants.maxBedDimensionCm &&
        heightCm >= PlantConstants.minBedDimensionCm &&
        heightCm <= PlantConstants.maxBedDimensionCm;
  }

  /// Returns the recommended spacing in centimeters for a given plant,
  /// taking the average of [minSpacingCm] and [maxSpacingCm].
  static double recommendedSpacing(
      double minSpacingCm, double maxSpacingCm) {
    return (minSpacingCm + maxSpacingCm) / 2.0;
  }

  /// Calculates the total planting area required for [plantCount] plants
  /// with the given [spacingCm], returned in square meters.
  static double requiredAreaSqMeters(int plantCount, double spacingCm) {
    if (plantCount <= 0 || spacingCm <= 0) return 0;
    final side = math.sqrt(plantCount.toDouble()) * spacingCm;
    return (side * side) / 10000.0;
  }
}
