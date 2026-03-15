import 'package:flutter/material.dart';
import 'package:gardnx_app/features/calendar/domain/models/task.dart';

class TaskCard extends StatelessWidget {
  final PlantingTask task;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onCheckboxChanged,
    this.onTap,
  });

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]}';
  }

  IconData _taskTypeIcon(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'sow':
        return Icons.grass;
      case 'transplant':
        return Icons.swap_horiz;
      case 'harvest':
        return Icons.cut;
      case 'water':
        return Icons.water_drop;
      case 'fertilize':
        return Icons.science;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priority = TaskPriorityExt.fromValue(task.priority);
    final priorityColor = priority.color;
    final isOverdue = task.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isOverdue
            ? BorderSide(color: colorScheme.error.withOpacity(0.4), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Priority stripe
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),

              // Task type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isOverdue
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _taskTypeIcon(task.taskType),
                  color: isOverdue
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.plantName != null &&
                        task.plantName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.plantName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isOverdue
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOverdue
                              ? 'Overdue: ${_formatDate(task.dueDate)}'
                              : _formatDate(task.dueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOverdue
                                ? colorScheme.error
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isOverdue
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priority.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Checkbox
              Checkbox(
                value: task.isCompleted,
                onChanged: onCheckboxChanged,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
