import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingKey = 'onboarding_done';

/// Tracks whether the user has completed onboarding.
/// Starts as null (loading), then resolves to true/false.
final onboardingDoneProvider = StateProvider<bool?>((ref) => null);

/// Loads the onboarding flag from SharedPreferences and updates
/// [onboardingDoneProvider]. Wire this provider into the app root
/// by calling `ref.watch(_loadOnboardingProvider)` in the root widget.
final loadOnboardingProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool(_kOnboardingKey) ?? false;
  ref.read(onboardingDoneProvider.notifier).state = done;
});

/// Call this when the user finishes onboarding.
Future<void> markOnboardingDone(WidgetRef ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingKey, true);
  ref.read(onboardingDoneProvider.notifier).state = true;
}
