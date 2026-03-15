import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/garden_zone.dart';

/// Renders a semi-transparent overlay of detected garden zones on top of
/// a photo.
///
/// Each zone polygon is drawn with its type-specific color. Selected zones
/// are highlighted with a thicker border and higher opacity. Tapping on
/// a zone triggers the [onZoneTap] callback.
class SegmentationOverlay extends StatelessWidget {
  final List<GardenZone> zones;
  final Set<String> selectedZoneIds;
  final void Function(String zoneId) onZoneTap;

  const SegmentationOverlay({
    super.key,
    required this.zones,
    required this.selectedZoneIds,
    required this.onZoneTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            _handleTap(details.localPosition, constraints.biggest);
          },
          child: CustomPaint(
            painter: _SegmentationPainter(
              zones: zones,
              selectedZoneIds: selectedZoneIds,
            ),
            size: constraints.biggest,
          ),
        );
      },
    );
  }

  void _handleTap(Offset tapPosition, Size canvasSize) {
    // Check zones in reverse order (top-most drawn last).
    for (int i = zones.length - 1; i >= 0; i--) {
      final zone = zones[i];
      if (zone.polygon.isEmpty) continue;

      // Scale polygon to canvas size and check if tap is inside.
      final path = Path();
      final scaledPoints = zone.polygon
          .map((p) => Offset(p.dx * canvasSize.width, p.dy * canvasSize.height))
          .toList();

      if (scaledPoints.isEmpty) continue;

      path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
      for (int j = 1; j < scaledPoints.length; j++) {
        path.lineTo(scaledPoints[j].dx, scaledPoints[j].dy);
      }
      path.close();

      if (path.contains(tapPosition)) {
        onZoneTap(zone.zoneId);
        return;
      }
    }
  }
}

class _SegmentationPainter extends CustomPainter {
  final List<GardenZone> zones;
  final Set<String> selectedZoneIds;

  _SegmentationPainter({
    required this.zones,
    required this.selectedZoneIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final zone in zones) {
      if (zone.polygon.isEmpty) continue;

      final isSelected = selectedZoneIds.contains(zone.zoneId);

      // Scale polygon points from normalised (0-1) to canvas coordinates.
      final scaledPoints = zone.polygon
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList();

      final path = Path();
      path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);
      for (int i = 1; i < scaledPoints.length; i++) {
        path.lineTo(scaledPoints[i].dx, scaledPoints[i].dy);
      }
      path.close();

      // Fill
      final fillPaint = Paint()
        ..color = zone.color.withValues(alpha: isSelected ? 0.45 : 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Stroke
      final strokePaint = Paint()
        ..color = isSelected
            ? zone.color
            : zone.color.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.0 : 1.5;
      canvas.drawPath(path, strokePaint);

      // Label
      if (isSelected) {
        final center = _computeCentroid(scaledPoints);
        _drawLabel(canvas, zone.displayLabel, center);
      }
    }
  }

  Offset _computeCentroid(List<Offset> points) {
    double cx = 0, cy = 0;
    for (final p in points) {
      cx += p.dx;
      cy += p.dy;
    }
    return Offset(cx / points.length, cy / points.length);
  }

  void _drawLabel(Canvas canvas, String label, Offset position) {
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    )
      ..pushStyle(ui.TextStyle(
        color: Colors.white,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 3,
          ),
        ],
      ))
      ..addText(label);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 100));

    // Background pill
    final bgRect = Rect.fromCenter(
      center: position,
      width: paragraph.longestLine + 12,
      height: paragraph.height + 6,
    );
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(6)),
      bgPaint,
    );

    canvas.drawParagraph(
      paragraph,
      Offset(
        position.dx - paragraph.longestLine / 2,
        position.dy - paragraph.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SegmentationPainter oldDelegate) {
    return oldDelegate.zones != zones ||
        oldDelegate.selectedZoneIds != selectedZoneIds;
  }
}
