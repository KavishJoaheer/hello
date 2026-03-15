import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// A reusable error display widget with an icon, message, and optional
/// retry button.
///
/// Use this for full-screen error states or inline error indicators.
class AppErrorWidget extends StatelessWidget {
  /// The error message to display.
  final String message;

  /// Optional callback for the retry button. If null, no button is shown.
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to `'Try Again'`.
  final String retryLabel;

  /// Icon displayed above the message. Defaults to [Icons.error_outline].
  final IconData icon;

  /// Color of the icon. Defaults to [AppColors.error].
  final Color? iconColor;

  /// Size of the icon. Defaults to 64.
  final double iconSize;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline,
    this.iconColor,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
