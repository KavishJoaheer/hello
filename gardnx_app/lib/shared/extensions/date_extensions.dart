import '../../core/utils/date_utils.dart';

/// Extension methods on [DateTime] for season detection, month names,
/// and common formatting patterns used throughout GardNx.
extension DateExtensions on DateTime {
  // ---------------------------------------------------------------------------
  // Season helpers
  // ---------------------------------------------------------------------------

  /// Returns the primary Mauritius season (`'Summer'` or `'Winter'`).
  String get primarySeason => MauritiusDateUtils.primarySeason(month);

  /// Returns the detailed Mauritius sub-season (e.g., `'Hot Wet'`).
  String get detailedSeason => MauritiusDateUtils.detailedSeason(month);

  /// Whether this date falls in the optimal planting window for Mauritius.
  bool get isOptimalPlanting => MauritiusDateUtils.isOptimalPlantingMonth(month);

  // ---------------------------------------------------------------------------
  // Month name helpers
  // ---------------------------------------------------------------------------

  /// Full month name (e.g., `'January'`).
  String get monthName => MauritiusDateUtils.monthName(month);

  /// Abbreviated month name (e.g., `'Jan'`).
  String get monthNameShort => MauritiusDateUtils.monthNameShort(month);

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  /// Formats as `dd MMM yyyy` (e.g., `'15 Mar 2024'`).
  String get formattedDayMonthYear =>
      MauritiusDateUtils.formatDayMonthYear(this);

  /// Returns a human-readable relative date (e.g., `'Today'`, `'3 days ago'`).
  String get relativeDate => MauritiusDateUtils.relativeDate(this);

  /// Formats as `HH:mm` (24-hour).
  String get formattedTime {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Formats as `dd/MM/yyyy`.
  String get formattedSlashDate {
    final d = day.toString().padLeft(2, '0');
    final mo = month.toString().padLeft(2, '0');
    return '$d/$mo/$year';
  }

  // ---------------------------------------------------------------------------
  // Comparison helpers
  // ---------------------------------------------------------------------------

  /// Whether this date is the same calendar day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Whether this date is today.
  bool get isToday => isSameDay(DateTime.now());

  /// Whether this date is yesterday.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(yesterday);
  }

  /// Whether this date is tomorrow.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return isSameDay(tomorrow);
  }

  /// Returns the start of the day (midnight).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Returns the end of the day (23:59:59.999).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Returns the number of days remaining in the current month.
  int get daysRemainingInMonth {
    final lastDay = DateTime(year, month + 1, 0).day;
    return lastDay - day;
  }
}
