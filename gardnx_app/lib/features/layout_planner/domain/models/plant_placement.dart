class PlantPlacement {
  final String id;
  final String plantId;
  final String plantName;
  final int startRow;
  final int startCol;
  final int rowSpan;
  final int colSpan;
  final int count;
  final String? notes;

  const PlantPlacement({
    required this.id,
    required this.plantId,
    required this.plantName,
    required this.startRow,
    required this.startCol,
    this.rowSpan = 1,
    this.colSpan = 1,
    this.count = 1,
    this.notes,
  });

  int get cellsOccupied => rowSpan * colSpan;

  factory PlantPlacement.fromJson(Map<String, dynamic> json) =>
      PlantPlacement(
        id: json['id'] as String? ??
            '${json['plant_id']}_${json['start_row']}_${json['start_col']}',
        plantId: json['plant_id'] as String? ?? '',
        plantName: json['plant_name'] as String? ?? '',
        startRow: (json['start_row'] as int?) ?? 0,
        startCol: (json['start_col'] as int?) ?? 0,
        rowSpan: json['row_span'] as int? ?? 1,
        colSpan: json['col_span'] as int? ?? 1,
        count: json['count'] as int? ?? 1,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'plant_id': plantId,
        'plant_name': plantName,
        'start_row': startRow,
        'start_col': startCol,
        'row_span': rowSpan,
        'col_span': colSpan,
        'count': count,
        'notes': notes,
      };

  PlantPlacement copyWith({
    String? id,
    String? plantId,
    String? plantName,
    int? startRow,
    int? startCol,
    int? rowSpan,
    int? colSpan,
    int? count,
    String? notes,
  }) {
    return PlantPlacement(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      startRow: startRow ?? this.startRow,
      startCol: startCol ?? this.startCol,
      rowSpan: rowSpan ?? this.rowSpan,
      colSpan: colSpan ?? this.colSpan,
      count: count ?? this.count,
      notes: notes ?? this.notes,
    );
  }

  bool occupies(int row, int col) {
    return row >= startRow &&
        row < startRow + rowSpan &&
        col >= startCol &&
        col < startCol + colSpan;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlantPlacement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
