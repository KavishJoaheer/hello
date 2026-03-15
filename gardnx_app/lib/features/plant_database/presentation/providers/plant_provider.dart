import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/config/constants/api_constants.dart';
import 'package:gardnx_app/features/plant_database/domain/models/plant.dart';
import 'package:gardnx_app/features/plant_database/domain/models/companion_rule.dart';
import 'package:gardnx_app/features/plant_database/data/repositories/plant_repository.dart';

final plantRepositoryProvider =
    Provider<PlantRepository>((ref) => PlantRepository());

/// All plants (cached)
final allPlantsProvider = FutureProvider<List<Plant>>((ref) async {
  final repo = ref.read(plantRepositoryProvider);
  return repo.getAllPlants();
});

/// Single plant by id
final plantByIdProvider =
    FutureProvider.family<Plant?, String>((ref, id) async {
  final repo = ref.read(plantRepositoryProvider);
  return repo.getPlantById(id);
});

/// Companion plants for a given plant id
final companionPlantsProvider =
    FutureProvider.family<List<Plant>, String>((ref, plantId) async {
  final repo = ref.read(plantRepositoryProvider);
  return repo.getCompanionPlants(plantId);
});

/// Companion rules for a given plant id
final companionRulesForPlantProvider =
    FutureProvider.family<List<CompanionRule>, String>((ref, plantId) async {
  final repo = ref.read(plantRepositoryProvider);
  final companions = await repo.getCompanionsForPlant(plantId);
  final incompatibles = await repo.getIncompatiblesForPlant(plantId);
  return [...companions, ...incompatibles];
});

/// Plants suitable for current month
final plantsForCurrentMonthProvider = FutureProvider<List<Plant>>((ref) async {
  final repo = ref.read(plantRepositoryProvider);
  return repo.getPlantsForMonth(DateTime.now().month);
});

// ---------------------------------------------------------------------------
// Global plant search — queries the Perenual database via the backend.
// Returns [] when query is too short or the backend is unreachable.
// Keyed on query string; auto-disposed when the widget leaves the tree.
// ---------------------------------------------------------------------------

final _globalSearchDio = Provider<Dio>((ref) => Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    )));

/// Searches the Perenual global plant database through the backend.
/// Only fires for queries of 2+ characters.
final globalPlantSearchProvider =
    FutureProvider.family.autoDispose<List<Plant>, String>((ref, query) async {
  if (query.trim().length < 2) return [];

  try {
    final dio = ref.read(_globalSearchDio);
    final response = await dio.get<List<dynamic>>(
      '/plants/search',
      queryParameters: {'q': query.trim()},
    );
    final data = response.data ?? [];
    return data
        .map((e) => Plant.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return []; // backend offline — silent fallback
  } catch (_) {
    return [];
  }
});
