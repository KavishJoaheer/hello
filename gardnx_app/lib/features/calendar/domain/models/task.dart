import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityExt on TaskPriority {
  String get value {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }

  static TaskPriority fromValue(String value) {
    switch (value) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }
}

class PlantingTask {
  final String id;
  final String gardenId;
  final String? bedId;
  final String? plantId;
  final String? plantName;
  final String description;
  final DateTime dueDate;
  final String taskType; // 'sow', 'transplant', 'harvest', 'water', etc.
  final bool isCompleted;
  final String priority; // 'low', 'medium', 'high'
  final DateTime? completedAt;

  const PlantingTask({
    required this.id,
    required this.gardenId,
    this.bedId,
    this.plantId,
    this.plantName,
    required this.description,
    required this.dueDate,
    required this.taskType,
    this.isCompleted = false,
    this.priority = 'medium',
    this.completedAt,
  });

  bool get isOverdue =>
      !isCompleted &&
      dueDate.isBefore(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day));

  factory PlantingTask.fromJson(Map<String, dynamic> json) => PlantingTask(
        id: json['id'] as String? ?? '',
        gardenId: json['garden_id'] as String? ?? '',
        bedId: json['bed_id'] as String?,
        plantId: json['plant_id'] as String?,
        plantName: json['plant_name'] as String?,
        description: json['description'] as String? ?? '',
        dueDate: DateTime.parse(json['due_date'] as String),
        taskType: json['task_type'] as String? ?? 'general',
        isCompleted: json['is_completed'] as bool? ?? false,
        priority: json['priority'] as String? ?? 'medium',
        completedAt: json['completed_at'] != null
            ? DateTime.tryParse(json['completed_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'garden_id': gardenId,
        'bed_id': bedId,
        'plant_id': plantId,
        'plant_name': plantName,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'task_type': taskType,
        'is_completed': isCompleted,
        'priority': priority,
        'completed_at': completedAt?.toIso8601String(),
      };

  PlantingTask copyWith({
    String? id,
    String? gardenId,
    String? bedId,
    String? plantId,
    String? plantName,
    String? description,
    DateTime? dueDate,
    String? taskType,
    bool? isCompleted,
    String? priority,
    DateTime? completedAt,
  }) {
    return PlantingTask(
      id: id ?? this.id,
      gardenId: gardenId ?? this.gardenId,
      bedId: bedId ?? this.bedId,
      plantId: plantId ?? this.plantId,
      plantName: plantName ?? this.plantName,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      taskType: taskType ?? this.taskType,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlantingTask && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
