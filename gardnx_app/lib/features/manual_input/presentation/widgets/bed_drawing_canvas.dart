import 'package:flutter/material.dart';
import 'package:gardnx_app/features/manual_input/domain/models/manual_bed.dart';

class BedDrawingCanvas extends StatefulWidget {
  final List<ManualBed> beds;
  final String? selectedBedId;
  final void Function(Rect rect) onBedDrawn;
  final void Function(String bedId) onBedSelected;
  final void Function(String bedId, Rect newRect) onBedMoved;

  const BedDrawingCanvas({
    super.key,
    required this.beds,
    required this.selectedBedId,
    required this.onBedDrawn,
    required this.onBedSelected,
    required this.onBedMoved,
  });

  @override
  State<BedDrawingCanvas> createState() => _BedDrawingCanvasState();
}

class _BedDrawingCanvasState extends State<BedDrawingCanvas> {
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _isDragging = false;

  // For moving a selected bed
  String? _movingBedId;
  Offset? _moveDelta;

  static const double _minSize = 30.0;

  String? _hitTest(Offset position) {
    // Iterate in reverse so topmost bed is selected first
    for (final bed in widget.beds.reversed) {
      if (bed.rect.contains(position)) return bed.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final pos = details.localPosition;
        final hitId = _hitTest(pos);

        if (hitId != null) {
          // Select and start move
          widget.onBedSelected(hitId);
          setState(() {
            _movingBedId = hitId;
            _moveDelta = pos;
            _isDragging = false;
          });
        } else {
          // Start drawing new bed
          setState(() {
            _dragStart = pos;
            _dragCurrent = pos;
            _isDragging = true;
            _movingBedId = null;
          });
        }
      },
      onPanUpdate: (details) {
        final pos = details.localPosition;
        if (_movingBedId != null && _moveDelta != null) {
          final bed = widget.beds.firstWhere(
            (b) => b.id == _movingBedId,
            orElse: () => widget.beds.first,
          );
          final delta = pos - _moveDelta!;
          final newRect = bed.rect.shift(delta);
          setState(() => _moveDelta = pos);
          widget.onBedMoved(_movingBedId!, newRect);
        } else if (_isDragging) {
          setState(() => _dragCurrent = pos);
        }
      },
      onPanEnd: (_) {
        if (_isDragging && _dragStart != null && _dragCurrent != null) {
          final rect = Rect.fromPoints(_dragStart!, _dragCurrent!);
          if (rect.width >= _minSize && rect.height >= _minSize) {
            widget.onBedDrawn(rect);
          }
        }
        setState(() {
          _dragStart = null;
          _dragCurrent = null;
          _isDragging = false;
          _movingBedId = null;
          _moveDelta = null;
        });
      },
      onTapUp: (details) {
        final hitId = _hitTest(details.localPosition);
        if (hitId != null) {
          widget.onBedSelected(hitId);
        }
      },
      child: CustomPaint(
        painter: _BedCanvasPainter(
          beds: widget.beds,
          selectedBedId: widget.selectedBedId,
          draftRect: _isDragging && _dragStart != null && _dragCurrent != null
              ? Rect.fromPoints(_dragStart!, _dragCurrent!)
              : null,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BedCanvasPainter extends CustomPainter {
  final List<ManualBed> beds;
  final String? selectedBedId;
  final Rect? draftRect;

  const _BedCanvasPainter({
    required this.beds,
    required this.selectedBedId,
    this.draftRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid background
    _drawGrid(canvas, size);

    // Draw existing beds
    for (final bed in beds) {
      _drawBed(canvas, bed, isSelected: bed.id == selectedBedId);
    }

    // Draw draft rectangle
    if (draftRect != null) {
      final draftPaint = Paint()
        ..color = Colors.green.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      final draftBorderPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawRect(draftRect!, draftPaint);
      canvas.drawRect(draftRect!, draftBorderPaint);

      // Size label
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '${draftRect!.width.toInt()}x${draftRect!.height.toInt()} px',
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        draftRect!.center -
            Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawBed(Canvas canvas, ManualBed bed, {required bool isSelected}) {
    final fillPaint = Paint()
      ..color = bed.color.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.amber : bed.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 2;

    final rrect =
        RRect.fromRectAndRadius(bed.rect, const Radius.circular(6));
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Selection handle corners
    if (isSelected) {
      _drawCornerHandles(canvas, bed.rect);
    }

    // Label
    if (bed.rect.width > 40 && bed.rect.height > 24) {
      final labelPainter = TextPainter(
        text: TextSpan(
          text: bed.name,
          style: TextStyle(
            color: _contrastColor(bed.color),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: bed.rect.width - 8);

      labelPainter.paint(
        canvas,
        bed.rect.center -
            Offset(labelPainter.width / 2, labelPainter.height / 2),
      );
    }

    // Dimensions label below bed
    if (bed.rect.width > 60) {
      final dimPainter = TextPainter(
        text: TextSpan(
          text: '${bed.widthCm}x${bed.heightCm}cm',
          style: TextStyle(
            color: bed.color.withOpacity(0.8),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      dimPainter.paint(
        canvas,
        Offset(
          bed.rect.left + (bed.rect.width - dimPainter.width) / 2,
          bed.rect.bottom + 2,
        ),
      );
    }
  }

  void _drawCornerHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.fill;
    const r = 5.0;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(corner, r, handlePaint);
    }
  }

  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(_BedCanvasPainter oldDelegate) =>
      oldDelegate.beds != beds ||
      oldDelegate.selectedBedId != selectedBedId ||
      oldDelegate.draftRect != draftRect;
}
