import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/manual_input/domain/models/manual_bed.dart';
import 'package:gardnx_app/features/manual_input/data/repositories/manual_garden_repository.dart';

// Repository provider
final manualGardenRepositoryProvider =
    Provider<ManualGardenRepository>((ref) => ManualGardenRepository());

// State notifier for list of ManualBed objects
class ManualInputNotifier extends StateNotifier<List<ManualBed>> {
  ManualInputNotifier() : super([]);

  /// Add a new bed to the list.
  void addBed(ManualBed bed) {
    state = [...state, bed];
  }

  /// Update an existing bed by id.
  void updateBed(ManualBed updated) {
    state = [
      for (final bed in state)
        if (bed.id == updated.id) updated else bed,
    ];
  }

  /// Remove a bed by id.
  void removeBed(String bedId) {
    state = state.where((b) => b.id != bedId).toList();
  }

  /// Clear all beds.
  void clear() {
    state = [];
  }

  /// Replace the entire list (e.g. after loading from Firestore).
  void setAll(List<ManualBed> beds) {
    state = beds;
  }

  /// Add a bed drawn by dragging on the canvas.
  void addDrawnBed({
    required Rect rect,
    required int index,
  }) {
    final id = 'bed_${DateTime.now().millisecondsSinceEpoch}_$index';
    const colors = [
      Color(0xFF8D6E63),
      Color(0xFF66BB6A),
      Color(0xFF42A5F5),
      Color(0xFFFF7043),
      Color(0xFFAB47BC),
    ];
    final color = colors[state.length % colors.length];
    final bed = ManualBed(
      id: id,
      name: 'Bed ${state.length + 1}',
      widthCm: 100,
      heightCm: 100,
      rect: rect,
      color: color,
    );
    addBed(bed);
  }
}

final manualInputProvider =
    StateNotifierProvider<ManualInputNotifier, List<ManualBed>>(
  (ref) => ManualInputNotifier(),
);

// The currently selected bed id (for editing)
final selectedBedIdProvider = StateProvider<String?>((ref) => null);

// Derived: selected bed object
final selectedBedProvider = Provider<ManualBed?>((ref) {
  final selectedId = ref.watch(selectedBedIdProvider);
  if (selectedId == null) return null;
  final beds = ref.watch(manualInputProvider);
  try {
    return beds.firstWhere((b) => b.id == selectedId);
  } catch (_) {
    return null;
  }
});
