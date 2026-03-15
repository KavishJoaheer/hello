import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/climate/domain/models/climate_data.dart';
import 'package:gardnx_app/features/climate/presentation/providers/location_provider.dart';
import 'package:gardnx_app/features/climate/data/repositories/climate_repository.dart';

final climateRepositoryProvider =
    Provider<ClimateRepository>((ref) => ClimateRepository());

final currentClimateProvider = FutureProvider<ClimateData>((ref) async {
  final locationAsync = ref.watch(currentLocationProvider);
  return locationAsync.when(
    data: (location) async {
      final repo = ref.read(climateRepositoryProvider);
      return repo.getCurrentClimate(location.latitude, location.longitude);
    },
    loading: () async => ClimateData.defaultMauritius(),
    error: (_, __) async => ClimateData.defaultMauritius(),
  );
});

final monthlyClimateProvider =
    FutureProvider<List<MonthlyClimate>>((ref) async {
  final locationAsync = ref.watch(currentLocationProvider);
  return locationAsync.when(
    data: (location) async {
      final repo = ref.read(climateRepositoryProvider);
      return repo.getMonthlyClimate(location.latitude, location.longitude);
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});
