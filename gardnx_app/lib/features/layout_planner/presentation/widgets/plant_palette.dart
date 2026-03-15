import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/plant_database/domain/models/plant.dart';
import 'package:gardnx_app/features/plant_database/presentation/providers/plant_provider.dart';
class PlantPalette extends ConsumerStatefulWidget {
  final void Function(Plant plant) onPlantSelected;

  const PlantPalette({super.key, required this.onPlantSelected});

  @override
  ConsumerState<PlantPalette> createState() => _PlantPaletteState();
}

class _PlantPaletteState extends ConsumerState<PlantPalette> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allPlantsProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text('Add Plants',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search plants...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: allAsync.when(
                data: (plants) {
                  final filtered = _query.isEmpty
                      ? plants
                      : plants
                          .where((p) =>
                              p.name.toLowerCase().contains(_query) ||
                              p.category.toLowerCase().contains(_query))
                          .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('No plants found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final plant = filtered[index];
                      return _PlantPaletteItem(
                        plant: plant,
                        onTap: () => widget.onPlantSelected(plant),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlantPaletteItem extends StatelessWidget {
  final Plant plant;
  final VoidCallback onTap;

  const _PlantPaletteItem({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        child: Text(
          plant.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
              color: colorScheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(plant.name),
      subtitle: Text(
        plant.category,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.grid_4x4, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 2),
          Text(
            '${plant.spacing.gridCellsRequired}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Icon(Icons.add_circle_outline, color: colorScheme.primary),
        ],
      ),
      onTap: onTap,
    );
  }
}
