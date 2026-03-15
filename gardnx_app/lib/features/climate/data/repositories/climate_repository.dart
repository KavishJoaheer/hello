import 'package:dio/dio.dart';
import 'package:gardnx_app/features/climate/domain/models/climate_data.dart';

class ClimateRepository {
  final Dio _dio;
  static const String _baseUrl = 'https://api.gardnx.com/v1';

  ClimateRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: {'Content-Type': 'application/json'},
            ));

  Future<ClimateData> getCurrentClimate(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/climate/current',
        queryParameters: {'lat': lat, 'lon': lon},
      );
      if (response.statusCode == 200 && response.data != null) {
        return ClimateData.fromJson(response.data as Map<String, dynamic>);
      }
      return ClimateData.defaultMauritius();
    } on DioException catch (e) {
      // Fall back to defaults on any network/server error
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return ClimateData.defaultMauritius();
      }
      return ClimateData.defaultMauritius();
    } catch (_) {
      return ClimateData.defaultMauritius();
    }
  }

  Future<List<MonthlyClimate>> getMonthlyClimate(
      double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/climate/monthly',
        queryParameters: {'lat': lat, 'lon': lon},
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['monthly_data'] != null) {
          return (data['monthly_data'] as List<dynamic>)
              .map((e) =>
                  MonthlyClimate.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (data is List<dynamic>) {
          return data
              .map((e) =>
                  MonthlyClimate.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
      return _defaultMonthlyClimate();
    } on DioException {
      return _defaultMonthlyClimate();
    } catch (_) {
      return _defaultMonthlyClimate();
    }
  }

  List<MonthlyClimate> _defaultMonthlyClimate() {
    // Mauritius approximate monthly averages
    const defaults = [
      (1, 28.0, 218.0, 80.0),
      (2, 28.0, 196.0, 80.0),
      (3, 27.5, 183.0, 81.0),
      (4, 25.5, 97.0, 79.0),
      (5, 23.0, 57.0, 77.0),
      (6, 21.0, 48.0, 75.0),
      (7, 20.0, 52.0, 74.0),
      (8, 20.0, 46.0, 73.0),
      (9, 21.5, 38.0, 73.0),
      (10, 23.0, 42.0, 74.0),
      (11, 25.0, 68.0, 76.0),
      (12, 27.0, 149.0, 79.0),
    ];
    return defaults
        .map((d) => MonthlyClimate(
              month: d.$1,
              avgTempC: d.$2,
              avgRainfallMm: d.$3,
              avgHumidity: d.$4,
            ))
        .toList();
  }
}
