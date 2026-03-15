import 'package:flutter/material.dart';

/// Centralized color constants for the GardNx application.
///
/// Colors are organized by category: primary palette, semantic meanings,
/// and garden-specific zone colors that match the Python backend.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Primary palette - greens
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AD5E);
  static const Color primaryDark = Color(0xFF005005);
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryContainer = Color(0xFF002106);

  // ---------------------------------------------------------------------------
  // Secondary palette - earth/brown tones
  // ---------------------------------------------------------------------------
  static const Color secondary = Color(0xFF795548);
  static const Color secondaryLight = Color(0xFFA98274);
  static const Color secondaryDark = Color(0xFF4B2C20);
  static const Color secondaryContainer = Color(0xFFD7CCC8);
  static const Color onSecondary = Colors.white;
  static const Color onSecondaryContainer = Color(0xFF2E1503);

  // ---------------------------------------------------------------------------
  // Accent - coral/orange
  // ---------------------------------------------------------------------------
  static const Color accent = Color(0xFFFF7043);
  static const Color accentLight = Color(0xFFFFA270);
  static const Color accentDark = Color(0xFFC63F17);
  static const Color accentContainer = Color(0xFFFFCCBC);

  // ---------------------------------------------------------------------------
  // Surface and background
  // ---------------------------------------------------------------------------
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color background = Color(0xFFF1F8E9);
  static const Color scaffoldBackground = Color(0xFFFAFAFA);
  static const Color cardBackground = Colors.white;

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF49454F);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnDark = Colors.white;

  // ---------------------------------------------------------------------------
  // Semantic / feedback
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Colors.white;
  static const Color success = Color(0xFF388E3C);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color warning = Color(0xFFF9A825);
  static const Color warningContainer = Color(0xFFFFF9C4);
  static const Color info = Color(0xFF1976D2);
  static const Color infoContainer = Color(0xFFBBDEFB);

  // ---------------------------------------------------------------------------
  // Garden zone colors - matching Python backend ZoneType class
  // ---------------------------------------------------------------------------
  static const Color zoneBackground = Color(0xFFA5D6A7); // light green
  static const Color zoneSoil = Color(0xFF8D6E63);        // brown
  static const Color zoneLawn = Color(0xFF66BB6A);         // grass green
  static const Color zonePath = Color(0xFFBDBDBD);         // grey
  static const Color zoneShade = Color(0xFF78909C);        // blue-grey
  static const Color zoneExistingPlant = Color(0xFF4CAF50); // medium green
  static const Color zoneSun = Color(0xFFFFF176);          // sunny yellow

  // ---------------------------------------------------------------------------
  // Dividers / borders
  // ---------------------------------------------------------------------------
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFBDBDBD);
  static const Color borderLight = Color(0xFFE0E0E0);

  // ---------------------------------------------------------------------------
  // Shimmer loading
  // ---------------------------------------------------------------------------
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
}
