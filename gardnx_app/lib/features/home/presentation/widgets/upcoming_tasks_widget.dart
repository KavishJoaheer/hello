import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/calendar/presentation/providers/task_provider.dart';
import 'package:gardnx_app/features/calendar/domain/models/task.dart';

class UpcomingTasksWidget extends ConsumerWidget {
  const UpcomingTasksWidget({super.key});

  Color _priorityColor(String priority, ColorScheme colorScheme) {
    switch (priority.toLowerCase()) {
      case 'high':
        return colorScheme.error;
      case 'medium':
        return Colors.orange;
      default:
        return colorScheme.primary;
    }
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

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tasksAsync = ref.watch(upcomingTasksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Upcoming Tasks',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full task list
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        tasksAsync.when(
          data: (tasks) {
            if (tasks.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        'No upcoming tasks',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final shown = tasks.take(5).toList();
            return Column(
              children: shown
                  .map((task) => _TaskMiniCard(
                        task: task,
                        priorityColor: _priorityColor(task.priority, colorScheme),
                        icon: _taskTypeIcon(task.taskType),
                        dueDateLabel: _formatDueDate(task.dueDate),
                      ))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Could not load tasks',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskMiniCard extends StatelessWidget {
  final PlantingTask task;
  final Color priorityColor;
  final IconData icon;
  final String dueDateLabel;

  const _TaskMiniCard({
    required this.task,
    required this.priorityColor,
    required this.icon,
    required this.dueDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isOverdue = dueDateLabel == 'Overdue';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: priorityColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: priorityColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (task.plantName != null)
                    Text(
                      task.plantName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              dueDateLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
