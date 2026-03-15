import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';

/// A centered [CircularProgressIndicator] with an optional message below it.
///
/// Use this as a full-screen loading state or within a smaller container.
class LoadingIndicator extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  /// Size of the spinner. Defaults to 40.
  final double size;

  /// Color of the spinner. Defaults to [AppColors.primary].
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                strokeWidth: 3.0,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppColors.primary,
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
