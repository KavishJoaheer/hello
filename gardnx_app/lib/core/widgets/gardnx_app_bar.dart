import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// A styled AppBar for the GardNx application.
///
/// Provides a consistent look and feel across all screens with the
/// GardNx brand colors and Material 3 styling.
class GardNxAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text displayed in the center of the app bar.
  final String title;

  /// Optional leading widget. If null, the default back button is used
  /// when there is a route to pop.
  final Widget? leading;

  /// Optional list of action widgets on the right side.
  final List<Widget>? actions;

  /// Whether to center the title. Defaults to true.
  final bool centerTitle;

  /// Whether to automatically imply a leading back button. Defaults to true.
  final bool automaticallyImplyLeading;

  /// Optional bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  /// Background color override. Defaults to the theme surface color.
  final Color? backgroundColor;

  /// Elevation override. Defaults to 0.
  final double elevation;

  const GardNxAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: leading,
      actions: actions,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      elevation: elevation,
      scrolledUnderElevation: 1,
      surfaceTintColor: AppColors.primary,
      bottom: bottom,
      iconTheme: const IconThemeData(
        color: AppColors.primary,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
