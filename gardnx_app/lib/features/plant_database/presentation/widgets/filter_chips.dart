import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/plant_database/presentation/providers/plant_filter_provider.dart';

class PlantFilterChips extends ConsumerWidget {
  const PlantFilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(plantFilterProvider);
    final notifier = ref.read(plantFilterProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final categoryOptions = [
      ('vegetable', 'Vegetables', Icons.eco),
      ('herb', 'Herbs', Icons.spa),
      ('fruit', 'Fruits', Icons.apple),
      ('flower', 'Flowers', Icons.local_florist),
    ];

    final sunOptions = [
      ('full_sun', 'Full Sun', Icons.wb_sunny),
      ('partial_shade', 'Part Shade', Icons.wb_cloudy),
      ('full_shade', 'Full Shade', Icons.cloud),
    ];

    final waterOptions = [
      ('low', 'Low Water', Icons.water_drop_outlined),
      ('medium', 'Medium Water', Icons.water_drop),
      ('high', 'High Water', Icons.waves),
    ];

    final difficultyOptions = [
      ('easy', 'Easy', Icons.sentiment_satisfied),
      ('medium', 'Medium', Icons.sentiment_neutral),
      ('hard', 'Hard', Icons.sentiment_dissatisfied),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Reset chip (shown when any filter active)
          if (!filter.isEmpty) ...[
            ActionChip(
              avatar: Icon(Icons.clear, size: 14, color: colorScheme.error),
              label: const Text('Clear'),
              onPressed: notifier.reset,
              backgroundColor: colorScheme.errorContainer.withOpacity(0.3),
            ),
            const SizedBox(width: 6),
          ],

          // Category chips
          for (final opt in categoryOptions) ...[
            FilterChip(
              avatar: Icon(opt.$3, size: 14),
              label: Text(opt.$2),
              selected: filter.categories.contains(opt.$1),
              onSelected: (_) => notifier.toggleCategory(opt.$1),
            ),
            const SizedBox(width: 6),
          ],

          const _Divider(),

          // Sun chips
          for (final opt in sunOptions) ...[
            FilterChip(
              avatar: Icon(opt.$3, size: 14),
              label: Text(opt.$2),
              selected: filter.sunRequirements.contains(opt.$1),
              onSelected: (_) => notifier.toggleSunRequirement(opt.$1),
            ),
            const SizedBox(width: 6),
          ],

          const _Divider(),

          // Water chips
          for (final opt in waterOptions) ...[
            FilterChip(
              avatar: Icon(opt.$3, size: 14),
              label: Text(opt.$2),
              selected: filter.waterNeeds.contains(opt.$1),
              onSelected: (_) => notifier.toggleWaterNeed(opt.$1),
            ),
            const SizedBox(width: 6),
          ],

          const _Divider(),

          // Difficulty chips
          for (final opt in difficultyOptions) ...[
            FilterChip(
              avatar: Icon(opt.$3, size: 14),
              label: Text(opt.$2),
              selected: filter.difficultyLevels.contains(opt.$1),
              onSelected: (_) => notifier.toggleDifficulty(opt.$1),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: VerticalDivider(
        width: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
