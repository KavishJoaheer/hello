import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/calendar/domain/models/task.dart';
import 'package:gardnx_app/features/calendar/presentation/providers/task_provider.dart';
import 'package:gardnx_app/features/calendar/presentation/widgets/task_card.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  final String gardenId;

  const TaskListScreen({super.key, required this.gardenId});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksNotifierProvider(widget.gardenId));
    final notifier =
        ref.read(tasksNotifierProvider(widget.gardenId).notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Overdue'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: tasksAsync.when(
        data: (_) => TabBarView(
          controller: _tabController,
          children: [
            _TaskTabContent(
              tasks: notifier.upcoming,
              emptyMessage: 'No upcoming tasks',
              emptyIcon: Icons.check_circle_outline,
              notifier: notifier,
            ),
            _TaskTabContent(
              tasks: notifier.overdue,
              emptyMessage: 'No overdue tasks',
              emptyIcon: Icons.celebration,
              notifier: notifier,
              overdueHighlight: true,
            ),
            _TaskTabContent(
              tasks: notifier.completed,
              emptyMessage: 'No completed tasks yet',
              emptyIcon: Icons.hourglass_empty,
              notifier: notifier,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              const Text('Failed to load tasks'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => notifier.reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTabContent extends StatelessWidget {
  final List<PlantingTask> tasks;
  final String emptyMessage;
  final IconData emptyIcon;
  final TasksNotifier notifier;
  final bool overdueHighlight;

  const _TaskTabContent({
    required this.tasks,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.notifier,
    this.overdueHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => notifier.reload(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskCard(
            task: task,
            onCheckboxChanged: (value) => notifier.toggleCompletion(task),
          );
        },
      ),
    );
  }
}
