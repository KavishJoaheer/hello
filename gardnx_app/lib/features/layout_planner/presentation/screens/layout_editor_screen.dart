import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/calendar/data/repositories/calendar_repository.dart';
import 'package:gardnx_app/features/calendar/domain/models/planting_event.dart';
import 'package:gardnx_app/features/calendar/domain/models/task.dart';
import 'package:gardnx_app/features/calendar/presentation/providers/calendar_provider.dart';
import 'package:gardnx_app/features/layout_planner/domain/models/plant_placement.dart';
import 'package:gardnx_app/features/layout_planner/presentation/providers/layout_provider.dart';
import 'package:gardnx_app/features/layout_planner/presentation/widgets/garden_grid_painter.dart';
import 'package:gardnx_app/features/layout_planner/presentation/widgets/plant_palette.dart';
import 'package:gardnx_app/features/layout_planner/presentation/widgets/spacing_guide.dart';
import 'package:gardnx_app/features/manual_input/domain/models/manual_bed.dart';
import 'package:gardnx_app/features/plant_database/domain/models/plant.dart';
import 'package:gardnx_app/features/plant_database/presentation/providers/plant_provider.dart';

class LayoutEditorScreen extends ConsumerStatefulWidget {
  final ManualBed bed;
  final String gardenId;
  final String season;
  final String region;
  final List<String> selectedPlantIds;

  const LayoutEditorScreen({
    super.key,
    required this.bed,
    required this.gardenId,
    required this.season,
    required this.region,
    required this.selectedPlantIds,
  });

  @override
  ConsumerState<LayoutEditorScreen> createState() =>
      _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen> {
  bool _isGenerating = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLayout();
      _autoGenerate();
    });
  }

  void _initLayout() {
    final cellSize = 30.0;
    final rows =
        (widget.bed.heightCm / cellSize).floor().clamp(1, 20);
    final cols =
        (widget.bed.widthCm / cellSize).floor().clamp(1, 20);
    ref.read(layoutNotifierProvider.notifier).initEmpty(
          gardenId: widget.gardenId,
          bedId: widget.bed.id,
          rows: rows,
          cols: cols,
          cellSizeCm: cellSize,
        );
  }

  Future<void> _autoGenerate() async {
    setState(() => _isGenerating = true);
    try {
      final repo = ref.read(layoutRepositoryProvider);
      final layout = await repo.generateLayout(
        gardenId: widget.gardenId,
        bedId: widget.bed.id,
        widthCm: widget.bed.widthCm,
        heightCm: widget.bed.heightCm,
        selectedPlantIds: widget.selectedPlantIds,
        sunExposure: widget.bed.sunExposure,
        season: widget.season,
      );
      ref.read(layoutNotifierProvider.notifier).setLayout(layout);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not auto-generate. Try adding plants manually.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final layoutId = await ref
          .read(layoutNotifierProvider.notifier)
          .saveCurrentLayout();
      if (layoutId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layout saved!')),
        );
        // Fire-and-forget: generate calendar in the background.
        // A failure here must not affect the already-saved layout.
        _generateAndSaveCalendar();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save layout.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generateAndSaveCalendar() async {
    final layout = ref.read(layoutNotifierProvider);
    if (layout == null || layout.placements.isEmpty) return;

    // Resolve Plant objects for every unique plantId in the saved layout.
    final plantIds =
        layout.placements.map((p) => p.plantId).toSet();
    final allPlants = ref.read(allPlantsProvider).value ?? [];
    final plants =
        allPlants.where((p) => plantIds.contains(p.id)).toList();
    if (plants.isEmpty) return;

    try {
      final calRepo = ref.read(calendarRepositoryProvider);

      final events = await calRepo.generateCalendar(
        gardenId: widget.gardenId,
        bedId: widget.bed.id,
        bedName: widget.bed.name,
        region: widget.region,
        plants: plants,
      );
      if (events.isEmpty) return;

      // Derive PlantingTask objects from events on the client side.
      final tasks = events.map((e) {
        final daysUntil =
            e.date.difference(DateTime.now()).inDays;
        final priority =
            daysUntil <= 7 ? 'high' : (daysUntil <= 30 ? 'medium' : 'low');
        return PlantingTask(
          id: '',
          gardenId: widget.gardenId,
          bedId: widget.bed.id,
          plantId: e.plantId,
          plantName: e.plantName,
          description:
              e.notes ?? '${e.eventType.label}: ${e.plantName}',
          dueDate: e.date,
          taskType: e.eventType.value,
          priority: priority,
        );
      }).toList();

      await calRepo.saveEvents(widget.gardenId, events);
      await calRepo.saveTasks(widget.gardenId, tasks);

      // Set active garden so calendar tab loads these events.
      ref.read(activeGardenIdProvider.notifier).state = widget.gardenId;
      // Refresh the calendar so the next visit shows the new events.
      ref.invalidate(gardenEventsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planting calendar updated!')),
        );
      }
    } catch (_) {
      // Calendar generation is best-effort — silently ignore failures.
    }
  }

  void _showPlantPalette() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlantPalette(
        onPlantSelected: (plant) {
          Navigator.of(context).pop();
          _addPlantToGrid(plant);
        },
      ),
    );
  }

  void _addPlantToGrid(Plant plant) {
    final layout = ref.read(layoutNotifierProvider);
    if (layout == null) return;

    // Find first empty cell
    for (int r = 0; r < layout.gridRows; r++) {
      for (int c = 0; c < layout.gridCols; c++) {
        bool occupied = false;
        for (final p in layout.placements) {
          if (p.occupies(r, c)) {
            occupied = true;
            break;
          }
        }
        if (!occupied) {
          final placement = PlantPlacement(
            id: '${plant.id}_${r}_$c',
            plantId: plant.id,
            plantName: plant.name,
            startRow: r,
            startCol: c,
            rowSpan: plant.spacing.gridCellsRequired > 1 ? 2 : 1,
            colSpan: plant.spacing.gridCellsRequired > 1 ? 2 : 1,
          );
          final added =
              ref.read(layoutNotifierProvider.notifier).addPlacement(placement);
          if (!added && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No space available for this plant.')),
            );
          }
          return;
        }
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grid is full!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = ref.watch(layoutNotifierProvider);
    final selectedId = ref.watch(selectedPlacementIdProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bed.name),
        actions: [
          if (layout != null && layout.placements.isNotEmpty)
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.save_outlined),
                    onPressed: _save,
                    tooltip: 'Save layout',
                  ),
        ],
      ),
      body: Column(
        children: [
          // Grid
          Expanded(
            child: layout == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: GardenGridWidget(
                      layout: layout,
                      selectedPlacementId: selectedId,
                      onPlacementTap: (id) {
                        ref.read(selectedPlacementIdProvider.notifier).state =
                            selectedId == id ? null : id;
                      },
                      onCellTap: (row, col) {
                        ref.read(selectedPlacementIdProvider.notifier).state =
                            null;
                      },
                    ),
                  ),
          ),

          // Bottom panel
          if (layout != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SpacingGuide(layout: layout),
            ),
            if (selectedId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove selected plant'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                    onPressed: () {
                      ref
                          .read(layoutNotifierProvider.notifier)
                          .removePlacement(selectedId);
                      ref.read(selectedPlacementIdProvider.notifier).state =
                          null;
                    },
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'palette',
            onPressed: _showPlantPalette,
            tooltip: 'Add plant',
            child: const Icon(Icons.local_florist),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'generate',
            onPressed: _isGenerating ? null : _autoGenerate,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high),
            label: const Text('Auto-Generate'),
          ),
        ],
      ),
    );
  }
}
