enum HighlightType { none, companion, incompatible, selected }

class GridCell {
  final int row;
  final int col;
  final String? plantId;
  final String? plantName;
  final HighlightType highlightType;

  const GridCell({
    required this.row,
    required this.col,
    this.plantId,
    this.plantName,
    this.highlightType = HighlightType.none,
  });

  bool get isEmpty => plantId == null;

  GridCell copyWith({
    int? row,
    int? col,
    String? plantId,
    String? plantName,
    HighlightType? highlightType,
  }) {
    return GridCell(
      row: row ?? this.row,
      col: col ?? this.col,
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      highlightType: highlightType ?? this.highlightType,
    );
  }

  GridCell cleared() => GridCell(row: row, col: col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GridCell && other.row == row && other.col == col);

  @override
  int get hashCode => Object.hash(row, col);
}
