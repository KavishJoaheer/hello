import 'package:flutter/material.dart';

enum PlantingEventType { sow, transplant, harvest, water, fertilize, general }

extension PlantingEventTypeExt on PlantingEventType {
  String get label {
    switch (this) {
      case PlantingEventType.sow:
        return 'Sow';
      case PlantingEventType.transplant:
        return 'Transplant';
      case PlantingEventType.harvest:
        return 'Harvest';
      case PlantingEventType.water:
        return 'Water';
      case PlantingEventType.fertilize:
        return 'Fertilize';
      case PlantingEventType.general:
        return 'General';
    }
  }

  String get value {
    switch (this) {
      case PlantingEventType.sow:
        return 'sow';
      case PlantingEventType.transplant:
        return 'transplant';
      case PlantingEventType.harvest:
        return 'harvest';
      case PlantingEventType.water:
        return 'water';
      case PlantingEventType.fertilize:
        return 'fertilize';
      case PlantingEventType.general:
        return 'general';
    }
  }

  Color get color {
    switch (this) {
      case PlantingEventType.sow:
        return Colors.green;
      case PlantingEventType.transplant:
        return Colors.blue;
      case PlantingEventType.harvest:
        return Colors.orange;
      case PlantingEventType.water:
        return Colors.cyan;
      case PlantingEventType.fertilize:
        return Colors.purple;
      case PlantingEventType.general:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case PlantingEventType.sow:
        return Icons.grass;
      case PlantingEventType.transplant:
        return Icons.swap_horiz;
      case PlantingEventType.harvest:
        return Icons.cut;
      case PlantingEventType.water:
        return Icons.water_drop;
      case PlantingEventType.fertilize:
        return Icons.science;
      case PlantingEventType.general:
        return Icons.event;
    }
  }

  static PlantingEventType fromValue(String value) {
    switch (value) {
      case 'sow':
        return PlantingEventType.sow;
      case 'transplant':
        return PlantingEventType.transplant;
      case 'harvest':
        return PlantingEventType.harvest;
      case 'water':
        return PlantingEventType.water;
      case 'fertilize':
        return PlantingEventType.fertilize;
      default:
        return PlantingEventType.general;
    }
  }
}

class PlantingEvent {
  final String id;
  final String gardenId;
  final String? bedId;
  final String? plantId;
  final String plantName;
  final PlantingEventType eventType;
  final DateTime date;
  final String? notes;
  final bool isCompleted;

  const PlantingEvent({
    required this.id,
    required this.gardenId,
    this.bedId,
    this.plantId,
    required this.plantName,
    required this.eventType,
    required this.date,
    this.notes,
    this.isCompleted = false,
  });

  factory PlantingEvent.fromJson(Map<String, dynamic> json) => PlantingEvent(
        id: json['id'] as String? ?? '',
        gardenId: json['garden_id'] as String? ?? '',
        bedId: json['bed_id'] as String?,
        plantId: json['plant_id'] as String?,
        plantName: json['plant_name'] as String? ?? '',
        eventType: PlantingEventTypeExt.fromValue(
            json['event_type'] as String? ?? 'general'),
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
        isCompleted: json['is_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'garden_id': gardenId,
        'bed_id': bedId,
        'plant_id': plantId,
        'plant_name': plantName,
        'event_type': eventType.value,
        'date': date.toIso8601String(),
        'notes': notes,
        'is_completed': isCompleted,
      };

  PlantingEvent copyWith({
    String? id,
    String? gardenId,
    String? bedId,
    String? plantId,
    String? plantName,
    PlantingEventType? eventType,
    DateTime? date,
    String? notes,
    bool? isCompleted,
  }) {
    return PlantingEvent(
      id: id ?? this.id,
      gardenId: gardenId ?? this.gardenId,
      bedId: bedId ?? this.bedId,
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      eventType: eventType ?? this.eventType,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
