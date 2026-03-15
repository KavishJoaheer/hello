import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/plant_database/domain/models/plant.dart';
import 'package:gardnx_app/features/plant_database/domain/models/plant_filter.dart';
import 'package:gardnx_app/features/plant_database/presentation/providers/plant_provider.dart';

class PlantFilterNotifier extends StateNotifier<PlantFilter> {
  PlantFilterNotifier() : super(const PlantFilter());

  void setSearchQuery(String query) {
    if (query.isEmpty) {
      state = state.clearSearch();
    } else {
      state = state.copyWith(searchQuery: query);
    }
  }

  void toggleCategory(String category) {
    final current = List<String>.from(state.categories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(categories: current);
  }

  void toggleSunRequirement(String sun) {
    final current = List<String>.from(state.sunRequirements);
    if (current.contains(sun)) {
      current.remove(sun);
    } else {
      current.add(sun);
    }
    state = state.copyWith(sunRequirements: current);
  }

  void toggleWaterNeed(String water) {
    final current = List<String>.from(state.waterNeeds);
    if (current.contains(water)) {
      current.remove(water);
    } else {
      current.add(water);
    }
    state = state.copyWith(waterNeeds: current);
  }

  void toggleDifficulty(String difficulty) {
    final current = List<String>.from(state.difficultyLevels);
    if (current.contains(difficulty)) {
      current.remove(difficulty);
    } else {
      current.add(difficulty);
    }
    state = state.copyWith(difficultyLevels: current);
  }

  void setMinSuitability(double? score) {
    state = state.copyWith(minSuitabilityScore: score);
  }

  void setNativeOnly(bool? value) {
    state = state.copyWith(isNativeOnly: value);
  }

  void reset() {
    state = const PlantFilter();
  }
}

final plantFilterProvider =
    StateNotifierProvider<PlantFilterNotifier, PlantFilter>(
  (ref) => PlantFilterNotifier(),
);

/// Derived provider: all plants filtered by current filter state
final filteredPlantsProvider = Provider<AsyncValue<List<Plant>>>((ref) {
  final filter = ref.watch(plantFilterProvider);
  final allAsync = ref.watch(allPlantsProvider);

  return allAsync.when(
    data: (plants) => AsyncData(filter.apply(plants)),
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
  );
});

/// Active filter count (for badge display)
final activeFilterCountProvider = Provider<int>((ref) {
  final filter = ref.watch(plantFilterProvider);
  int count = 0;
  if (filter.categories.isNotEmpty) count++;
  if (filter.sunRequirements.isNotEmpty) count++;
  if (filter.waterNeeds.isNotEmpty) count++;
  if (filter.difficultyLevels.isNotEmpty) count++;
  if (filter.minSuitabilityScore != null) count++;
  if (filter.isNativeOnly == true) count++;
  return count;
});
