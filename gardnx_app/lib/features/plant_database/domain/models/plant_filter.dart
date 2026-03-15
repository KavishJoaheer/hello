import 'package:gardnx_app/features/plant_database/domain/models/plant.dart';

class PlantFilter {
  final String? searchQuery;
  final List<String> categories;
  final List<String> sunRequirements;
  final List<String> waterNeeds;
  final List<String> difficultyLevels;
  final List<int> sowMonths;
  final double? minSuitabilityScore;
  final bool? isNativeOnly;

  const PlantFilter({
    this.searchQuery,
    this.categories = const [],
    this.sunRequirements = const [],
    this.waterNeeds = const [],
    this.difficultyLevels = const [],
    this.sowMonths = const [],
    this.minSuitabilityScore,
    this.isNativeOnly,
  });

  bool get isEmpty =>
      (searchQuery == null || searchQuery!.isEmpty) &&
      categories.isEmpty &&
      sunRequirements.isEmpty &&
      waterNeeds.isEmpty &&
      difficultyLevels.isEmpty &&
      sowMonths.isEmpty &&
      minSuitabilityScore == null &&
      isNativeOnly == null;

  PlantFilter copyWith({
    String? searchQuery,
    List<String>? categories,
    List<String>? sunRequirements,
    List<String>? waterNeeds,
    List<String>? difficultyLevels,
    List<int>? sowMonths,
    double? minSuitabilityScore,
    bool? isNativeOnly,
  }) {
    return PlantFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      sunRequirements: sunRequirements ?? this.sunRequirements,
      waterNeeds: waterNeeds ?? this.waterNeeds,
      difficultyLevels: difficultyLevels ?? this.difficultyLevels,
      sowMonths: sowMonths ?? this.sowMonths,
      minSuitabilityScore: minSuitabilityScore ?? this.minSuitabilityScore,
      isNativeOnly: isNativeOnly ?? this.isNativeOnly,
    );
  }

  PlantFilter clearSearch() => PlantFilter(
        categories: categories,
        sunRequirements: sunRequirements,
        waterNeeds: waterNeeds,
        difficultyLevels: difficultyLevels,
        sowMonths: sowMonths,
        minSuitabilityScore: minSuitabilityScore,
        isNativeOnly: isNativeOnly,
      );

  PlantFilter reset() => const PlantFilter();

  bool matches(Plant plant) {
    if (searchQuery != null && searchQuery!.trim().isNotEmpty) {
      final q = searchQuery!.trim().toLowerCase();
      bool nameMatch = plant.name.toLowerCase().contains(q);
      bool scientificMatch = plant.scientificName.toLowerCase().contains(q);
      bool descMatch = plant.description.toLowerCase().contains(q);
      bool tagMatch = plant.tags.any((t) => t.toLowerCase().contains(q));
      
      if (!nameMatch && !scientificMatch && !descMatch && !tagMatch) {
        return false;
      }
    }

    if (categories.isNotEmpty && !categories.contains(plant.category.toLowerCase())) {
      return false;
    }

    if (sunRequirements.isNotEmpty &&
        !sunRequirements.contains(plant.conditions.sunRequirement)) {
      return false;
    }

    if (waterNeeds.isNotEmpty &&
        !waterNeeds.contains(plant.conditions.waterNeeds)) {
      return false;
    }

    if (difficultyLevels.isNotEmpty &&
        !difficultyLevels.contains(plant.difficultyLevel)) {
      return false;
    }

    if (sowMonths.isNotEmpty) {
      final hasMatch = sowMonths
          .any((m) => plant.timing.sowMonths.contains(m));
      if (!hasMatch) return false;
    }

    if (minSuitabilityScore != null &&
        plant.suitabilityScore < minSuitabilityScore!) {
      return false;
    }

    if (isNativeOnly == true && !plant.isNative) {
      return false;
    }

    return true;
  }

  List<Plant> apply(List<Plant> plants) =>
      plants.where(matches).toList();
}
