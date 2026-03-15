import 'package:flutter/material.dart';
import 'package:gardnx_app/features/layout_planner/domain/models/garden_layout.dart';
import 'package:gardnx_app/features/layout_planner/domain/models/plant_placement.dart';

// Plant type to color mapping
class PlantColorMap {
  static const List<Color> _palette = [
    Color(0xFF66BB6A), // green
    Color(0xFF42A5F5), // blue
    Color(0xFFFF7043), // orange
    Color(0xFFAB47BC), // purple
    Color(0xFF26C6DA), // cyan
    Color(0xFFEC407A), // pink
    Color(0xFF8D6E63), // brown
    Color(0xFFFFCA28), // amber
  ];

  static Color forPlant(String plantId, int index) {
    return _palette[index % _palette.length];
  }
}

class GardenGridWidget extends StatefulWidget {
  final GardenLayout layout;
  final String? selectedPlacementId;
  final Set<String>? companionPlantIds;
  final Set<String>? incompatiblePlantIds;
  final void Function(int row, int col)? onCellTap;
  final void Function(String placementId)? onPlacementTap;

  const GardenGridWidget({
    super.key,
    required this.layout,
    this.selectedPlacementId,
    this.companionPlantIds,
    this.incompatiblePlantIds,
    this.onCellTap,
    this.onPlacementTap,
  });

  @override
  State<GardenGridWidget> createState() => _GardenGridWidgetState();
}

class _GardenGridWidgetState extends State<GardenGridWidget> {
  late Map<String, int> _plantColorIndex;

  @override
  void initState() {
    super.initState();
    _buildColorMap();
  }

  @override
  void didUpdateWidget(GardenGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout.placements != widget.layout.placements) {
      _buildColorMap();
    }
  }

  void _buildColorMap() {
    _plantColorIndex = {};
    int idx = 0;
    for (final p in widget.layout.placements) {
      if (!_plantColorIndex.containsKey(p.plantId)) {
        _plantColorIndex[p.plantId] = idx++;
      }
    }
  }

  void _handleTap(Offset localPosition, double cellSize) {
    final col = (localPosition.dx / cellSize).floor();
    final row = (localPosition.dy / cellSize).floor();

    if (row < 0 ||
        row >= widget.layout.gridRows ||
        col < 0 ||
        col >= widget.layout.gridCols) return;

    // Check if a placement was tapped
    for (final p in widget.layout.placements) {
      if (p.occupies(row, col)) {
        widget.onPlacementTap?.call(p.id);
        return;
      }
    }
    widget.onCellTap?.call(row, col);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        final cellByWidth = maxWidth / widget.layout.gridCols;
        final cellByHeight = maxHeight / widget.layout.gridRows;
        final cellSize = cellByWidth < cellByHeight ? cellByWidth : cellByHeight;

        final gridWidth = cellSize * widget.layout.gridCols;
        final gridHeight = cellSize * widget.layout.gridRows;

        return Center(
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition, cellSize),
            child: SizedBox(
              width: gridWidth,
              height: gridHeight,
              child: CustomPaint(
                painter: GardenGridPainter(
                  layout: widget.layout,
                  cellSize: cellSize,
                  plantColorIndex: _plantColorIndex,
                  selectedPlacementId: widget.selectedPlacementId,
                  companionPlantIds: widget.companionPlantIds ?? {},
                  incompatiblePlantIds:
                      widget.incompatiblePlantIds ?? {},
                ),
                size: Size(gridWidth, gridHeight),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GardenGridPainter extends CustomPainter {
  final GardenLayout layout;
  final double cellSize;
  final Map<String, int> plantColorIndex;
  final String? selectedPlacementId;
  final Set<String> companionPlantIds;
  final Set<String> incompatiblePlantIds;

  GardenGridPainter({
    required this.layout,
    required this.cellSize,
    required this.plantColorIndex,
    this.selectedPlacementId,
    required this.companionPlantIds,
    required this.incompatiblePlantIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw empty cells
    _drawEmptyCells(canvas);

    // 2. Draw plant cells
    for (final placement in layout.placements) {
      _drawPlacement(canvas, placement);
    }

    // 3. Draw grid lines on top
    _drawGridLines(canvas, size);
  }

  void _drawEmptyCells(Canvas canvas) {
    final emptyPaint = Paint()..color = const Color(0xFFF5F0E8);
    for (int r = 0; r < layout.gridRows; r++) {
      for (int c = 0; c < layout.gridCols; c++) {
        final rect = Rect.fromLTWH(
            c * cellSize, r * cellSize, cellSize, cellSize);
        canvas.drawRect(rect, emptyPaint);
      }
    }
  }

  void _drawGridLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    for (int c = 0; c <= layout.gridCols; c++) {
      canvas.drawLine(
        Offset(c * cellSize, 0),
        Offset(c * cellSize, size.height),
        paint,
      );
    }
    for (int r = 0; r <= layout.gridRows; r++) {
      canvas.drawLine(
        Offset(0, r * cellSize),
        Offset(size.width, r * cellSize),
        paint,
      );
    }
  }

  void _drawPlacement(Canvas canvas, PlantPlacement placement) {
    final colorIdx = plantColorIndex[placement.plantId] ?? 0;
    final baseColor = PlantColorMap.forPlant(placement.plantId, colorIdx);
    final isSelected = placement.id == selectedPlacementId;
    final isCompanion = companionPlantIds.contains(placement.plantId);
    final isIncompatible = incompatiblePlantIds.contains(placement.plantId);

    final rect = Rect.fromLTWH(
      placement.startCol * cellSize,
      placement.startRow * cellSize,
      placement.colSpan * cellSize,
      placement.rowSpan * cellSize,
    );

    // Fill
    final fillPaint = Paint()
      ..color = baseColor.withOpacity(isSelected ? 0.85 : 0.65);
    canvas.drawRect(rect, fillPaint);

    // Companion border (green glow)
    if (isCompanion) {
      final companionPaint = Paint()
        ..color = Colors.green.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(rect.deflate(1.5), companionPaint);
    }

    // Incompatible border (red glow)
    if (isIncompatible) {
      final incompatiblePaint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRect(rect.deflate(1.5), incompatiblePaint);
    }

    // Selection border
    if (isSelected) {
      final selPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRect(rect.deflate(1.25), selPaint);
    }

    // Plant initial label
    final initials = _getInitials(placement.plantName);
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: _contrastColor(baseColor),
          fontSize: (cellSize * 0.35).clamp(8.0, 20.0),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  Color _contrastColor(Color bg) {
    return bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(GardenGridPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.cellSize != cellSize ||
      oldDelegate.selectedPlacementId != selectedPlacementId ||
      oldDelegate.companionPlantIds != companionPlantIds ||
      oldDelegate.incompatiblePlantIds != incompatiblePlantIds;
}
