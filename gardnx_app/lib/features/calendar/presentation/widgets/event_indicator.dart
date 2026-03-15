import 'package:flutter/material.dart';
import 'package:gardnx_app/features/calendar/domain/models/planting_event.dart';

class EventIndicator extends StatelessWidget {
  final PlantingEventType eventType;
  final double size;

  const EventIndicator({
    super.key,
    required this.eventType,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: eventType.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: eventType.color.withOpacity(0.3),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

/// Shows a row of up to 3 event indicator dots for a calendar cell.
class EventIndicatorRow extends StatelessWidget {
  final List<PlantingEvent> events;
  final double dotSize;

  const EventIndicatorRow({
    super.key,
    required this.events,
    this.dotSize = 6,
  });

  @override
  Widget build(BuildContext context) {
    final shown = events.take(3).toList();
    final hasMore = events.length > 3;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...shown.map((e) => EventIndicator(
              eventType: e.eventType,
              size: dotSize,
            )),
        if (hasMore)
          Container(
            width: dotSize,
            height: dotSize,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
