/// Utilities for Mauritius-specific season and date operations.
///
/// Mauritius has a tropical climate with two main seasons:
/// - **Summer (hot/wet):** November to April
/// - **Winter (cool/dry):** May to October
///
/// For more granular gardening advice, four sub-seasons are used:
/// - **Hot Wet:** December to March
/// - **Cool Transition:** April to May
/// - **Cool Dry:** June to September
/// - **Warm Transition:** October to November
class MauritiusDateUtils {
  MauritiusDateUtils._();

  /// Returns the primary season name for the given [month] (1-12).
  ///
  /// Returns either `'Summer'` or `'Winter'`.
  static String primarySeason(int month) {
    // Summer: November (11) through April (4)
    if (month >= 11 || month <= 4) return 'Summer';
    return 'Winter';
  }

  /// Returns the detailed sub-season name for the given [month] (1-12).
  static String detailedSeason(int month) {
    if (month >= 12 || (month >= 1 && month <= 3)) return 'Hot Wet';
    if (month == 4 || month == 5) return 'Cool Transition';
    if (month >= 6 && month <= 9) return 'Cool Dry';
    // October-November
    return 'Warm Transition';
  }

  /// Returns the primary season for the current date.
  static String currentPrimarySeason() => primarySeason(DateTime.now().month);

  /// Returns the detailed sub-season for the current date.
  static String currentDetailedSeason() => detailedSeason(DateTime.now().month);

  /// Returns the month name for the given [month] number (1-12).
  static String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    if (month < 1 || month > 12) return 'Unknown';
    return months[month - 1];
  }

  /// Returns the abbreviated month name (3 letters) for [month] (1-12).
  static String monthNameShort(int month) {
    final full = monthName(month);
    if (full.length < 3) return full;
    return full.substring(0, 3);
  }

  /// Returns true if the given [month] falls in the planting season
  /// for Mauritius (generally year-round, but optimal: Sep-Mar).
  static bool isOptimalPlantingMonth(int month) {
    return month >= 9 || month <= 3;
  }

  /// Returns the list of months in the current growing season as
  /// month numbers (1-12).
  static List<int> currentGrowingSeasonMonths() {
    final now = DateTime.now().month;
    if (now >= 11 || now <= 4) {
      // Summer season months
      return [11, 12, 1, 2, 3, 4];
    }
    // Winter season months
    return [5, 6, 7, 8, 9, 10];
  }

  /// Returns a human-readable relative date string (e.g., "Today",
  /// "Yesterday", "3 days ago", "Mar 15").
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    return '${monthNameShort(date.month)} ${date.day}';
  }

  /// Formats a [DateTime] as `dd MMM yyyy` (e.g., "15 Mar 2024").
  static String formatDayMonthYear(DateTime date) {
    return '${date.day} ${monthNameShort(date.month)} ${date.year}';
  }
}
