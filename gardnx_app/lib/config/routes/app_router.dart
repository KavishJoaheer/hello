import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/garden_analysis/presentation/screens/capture_screen.dart';
import '../../features/garden_analysis/presentation/screens/area_selection_screen.dart';
import '../../features/garden_analysis/presentation/screens/analysis_result_screen.dart';
import '../../features/manual_input/presentation/screens/manual_input_screen.dart';
import '../../features/plant_database/presentation/screens/plant_catalog_screen.dart';
import '../../features/plant_database/presentation/screens/plant_detail_screen.dart';
import '../../features/layout_planner/presentation/screens/recommendation_screen.dart';
import '../../features/layout_planner/presentation/screens/layout_editor_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/calendar/presentation/screens/task_list_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/manual_input/domain/models/manual_bed.dart';
import '../../features/garden_analysis/domain/models/garden_photo.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

// ---------------------------------------------------------------------------
// Route path constants
// ---------------------------------------------------------------------------
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String capture = '/garden/capture';
  static const String areaSelection = '/garden/area-selection';
  static const String analysisResult = '/garden/analysis-result';
  static const String manualInput = '/garden/manual-input';
  static const String recommend = '/garden/recommend';
  static const String layoutEditor = '/garden/layout';
  static const String plantCatalog = '/plants';
  static const String plantDetail = '/plants/:plantId';
  static const String calendar = '/calendar';
  static const String tasks = '/tasks';
  static const String profile = '/profile';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------
final appRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth + onboarding changes so GoRouter re-evaluates redirects.
  final notifier = _AuthNotifier();
  ref.listen(authStateProvider, (_, __) => notifier.notify());
  ref.listen(onboardingDoneProvider, (_, __) => notifier.notify());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: notifier,

    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final onboardingDone = ref.read(onboardingDoneProvider);
      final loc = state.matchedLocation;

      // While auth or onboarding state is still loading, hold on splash.
      if (authState.isLoading || onboardingDone == null) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // First-time user: show onboarding before login.
      if (onboardingDone == false && loc != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = loc == AppRoutes.login || loc == AppRoutes.register;
      final isSplash = loc == AppRoutes.splash;
      final isOnboarding = loc == AppRoutes.onboarding;

      // After onboarding, route normally.
      // Only redirect away from onboarding once it's actually been marked done.
      if (isOnboarding && onboardingDone == true) {
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }
      if (isOnboarding) return null; // still on onboarding, let it stay
      if (isSplash) return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
      if (isLoggedIn && isAuthRoute) return AppRoutes.home;
      return null;
    },

    routes: [
      // ---- Splash ----
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // ---- Onboarding ----
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // ---- Auth ----
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // ---- Home dashboard ----
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (_, __) => const HomeScreen(),
      ),

      // ---- Garden creation flow ----
      GoRoute(
        path: AppRoutes.capture,
        name: 'capture',
        builder: (_, __) => const CaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.areaSelection,
        name: 'areaSelection',
        builder: (context, state) {
          final photoPath = state.extra as String? ?? '';
          return AreaSelectionScreen(photoPath: photoPath);
        },
      ),
      GoRoute(
        path: AppRoutes.analysisResult,
        name: 'analysisResult',
        builder: (context, state) {
          // Navigate with: context.go(AppRoutes.analysisResult, extra: gardenPhoto)
          final photo = state.extra as GardenPhoto?;
          if (photo == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('No photo data provided.')),
            );
          }
          return AnalysisResultScreen(photo: photo);
        },
      ),
      GoRoute(
        path: AppRoutes.manualInput,
        name: 'manualInput',
        builder: (context, state) {
          final args = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
          return ManualInputScreen(
            gardenId: args['gardenId'] as String?,
            backgroundImagePath: args['imagePath'] as String?,
            initialBeds: args['initialBeds'] as List<ManualBed>?,
          );
        },
      ),

      // ---- Recommendation screen ----
      // Navigate with: context.go(AppRoutes.recommend, extra: {
      //   'bed': manualBed, 'gardenId': id, 'season': 'summer', 'region': 'north'
      // })
      GoRoute(
        path: AppRoutes.recommend,
        name: 'recommend',
        builder: (context, state) {
          final args = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
          return RecommendationScreen(
            bed: args['bed'] as ManualBed? ??
                ManualBed(
                  id: 'default',
                  name: 'Bed A',
                  widthCm: 200,
                  heightCm: 300,
                  sunExposure: 'full_sun',
                  soilType: 'loamy',
                ),
            gardenId: args['gardenId'] as String? ?? '',
            season: args['season'] as String? ?? 'summer',
            region: args['region'] as String? ?? 'north',
          );
        },
      ),

      // ---- Layout editor ----
      // Navigate with: context.go(AppRoutes.layoutEditor, extra: {
      //   'bed': manualBed, 'gardenId': id, 'season': 'summer',
      //   'region': 'north', 'selectedPlantIds': ['basil_001', ...]
      // })
      GoRoute(
        path: AppRoutes.layoutEditor,
        name: 'layoutEditor',
        builder: (context, state) {
          final args = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
          return LayoutEditorScreen(
            bed: args['bed'] as ManualBed? ??
                ManualBed(
                  id: 'default',
                  name: 'Bed A',
                  widthCm: 200,
                  heightCm: 300,
                  sunExposure: 'full_sun',
                  soilType: 'loamy',
                ),
            gardenId: args['gardenId'] as String? ?? '',
            season: args['season'] as String? ?? 'summer',
            region: args['region'] as String? ?? 'north',
            selectedPlantIds:
                List<String>.from(args['selectedPlantIds'] as List? ?? []),
          );
        },
      ),

      // ---- Plant catalog ----
      GoRoute(
        path: AppRoutes.plantCatalog,
        name: 'plantCatalog',
        builder: (_, __) => const PlantCatalogScreen(),
        routes: [
          GoRoute(
            path: ':plantId',
            name: 'plantDetail',
            builder: (context, state) => PlantDetailScreen(
              plantId: state.pathParameters['plantId'] ?? '',
            ),
          ),
        ],
      ),

      // ---- Calendar ----
      GoRoute(
        path: AppRoutes.calendar,
        name: 'calendar',
        builder: (_, __) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/tasks',
        name: 'tasks',
        builder: (context, state) {
          final gardenId = state.extra as String? ?? '';
          return TaskListScreen(gardenId: gardenId);
        },
      ),

      // ---- Profile ----
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (_, __) => const ProfileScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Route not found: ${state.matchedLocation}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// ---------------------------------------------------------------------------
// Simple ChangeNotifier that triggers GoRouter to re-evaluate redirects
// ---------------------------------------------------------------------------
class _AuthNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
