import 'package:gardnx_app/core/utils/date_utils.dart';

class MonthlyClimate {
  final int month;
  final double avgTempC;
  final double avgRainfallMm;
  final double avgHumidity;

  const MonthlyClimate({
    required this.month,
    required this.avgTempC,
    required this.avgRainfallMm,
    required this.avgHumidity,
  });

  factory MonthlyClimate.fromJson(Map<String, dynamic> json) => MonthlyClimate(
        month: json['month'] as int,
        avgTempC: (json['avg_temp_c'] as num).toDouble(),
        avgRainfallMm: (json['avg_rainfall_mm'] as num).toDouble(),
        avgHumidity: (json['avg_humidity'] as num? ?? 75.0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'avg_temp_c': avgTempC,
        'avg_rainfall_mm': avgRainfallMm,
        'avg_humidity': avgHumidity,
      };
}

class ClimateData {
  final double currentTempC;
  final double avgTempC;
  final double humidity;
  final double precipitationMm;
  final String season;
  final String subSeason;
  final List<MonthlyClimate> monthlyData;

  const ClimateData({
    required this.currentTempC,
    required this.avgTempC,
    required this.humidity,
    required this.precipitationMm,
    required this.season,
    required this.subSeason,
    required this.monthlyData,
  });

  factory ClimateData.fromJson(Map<String, dynamic> json) {
    final month = DateTime.now().month;
    return ClimateData(
      currentTempC: (json['current_temp_c'] as num? ?? 25.0).toDouble(),
      avgTempC: (json['avg_temp_c'] as num? ?? 25.0).toDouble(),
      humidity: (json['humidity'] as num? ?? 75.0).toDouble(),
      precipitationMm: (json['precipitation_mm'] as num? ?? 0.0).toDouble(),
      season: json['season'] as String? ?? MauritiusDateUtils.primarySeason(month),
      subSeason: json['sub_season'] as String? ?? MauritiusDateUtils.detailedSeason(month),
      monthlyData: (json['monthly_data'] as List<dynamic>? ?? [])
          .map((e) => MonthlyClimate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'current_temp_c': currentTempC,
        'avg_temp_c': avgTempC,
        'humidity': humidity,
        'precipitation_mm': precipitationMm,
        'season': season,
        'sub_season': subSeason,
        'monthly_data': monthlyData.map((m) => m.toJson()).toList(),
      };

  static ClimateData defaultMauritius() {
    final month = DateTime.now().month;
    return ClimateData(
      currentTempC: 27.0,
      avgTempC: 25.0,
      humidity: 78.0,
      precipitationMm: 5.0,
      season: MauritiusDateUtils.primarySeason(month),
      subSeason: MauritiusDateUtils.detailedSeason(month),
      monthlyData: [],
    );
  }
}
