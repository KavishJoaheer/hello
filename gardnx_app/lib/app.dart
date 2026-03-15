import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'features/onboarding/presentation/providers/onboarding_provider.dart';

/// Root widget for the GardNx application.
class GardNxApp extends ConsumerWidget {
  const GardNxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load onboarding flag early so the router redirect can check it.
    ref.watch(loadOnboardingProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MYGarden Planner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
