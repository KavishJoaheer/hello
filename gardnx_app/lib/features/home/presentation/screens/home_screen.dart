import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../calendar/presentation/screens/calendar_screen.dart';
import '../../../plant_database/presentation/screens/plant_catalog_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/garden_summary_card.dart';
import '../widgets/upcoming_tasks_widget.dart';

// ---------------------------------------------------------------------------
// Bottom-nav index state
// ---------------------------------------------------------------------------
final _navIndexProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Real-time gardens stream from Firestore
// ---------------------------------------------------------------------------
final _gardenSummariesProvider =
    StreamProvider.autoDispose<List<GardenSummary>>((ref) {
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) return Stream.value([]);

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('gardens')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        final summaries = snap.docs.map((doc) {
          final data = doc.data();
          return GardenSummary(
            id: doc.id,
            name: data['name'] as String? ?? 'My Garden',
            bedCount: (data['bedCount'] as int?) ?? 0,
            lastUpdated: data['updatedAt'] != null
                ? (data['updatedAt'] as Timestamp).toDate()
                : DateTime.now(),
            imageUrl: data['imageUrl'] as String?,
          );
        }).toList();
        summaries.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        return summaries;
      });
});

// ---------------------------------------------------------------------------
// HomeScreen
// ---------------------------------------------------------------------------
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(_navIndexProvider);

    return PopScope(
      canPop: currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && currentIndex != 0) {
          ref.read(_navIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: const [
            _DashboardTab(),
            PlantCatalogScreen(),
            CalendarScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (index) =>
              ref.read(_navIndexProvider.notifier).state = index,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_florist_outlined),
              selectedIcon: Icon(Icons.local_florist),
              label: 'Plants',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard tab
// ---------------------------------------------------------------------------
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gardensAsync = ref.watch(_gardenSummariesProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('My Gardens'),
            backgroundColor: colorScheme.surface,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // ---- Gardens list ----
          gardensAsync.when(
            data: (gardens) {
              if (gardens.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyGardensState(
                    onCreateTap: () => context.push(AppRoutes.capture),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: gardens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) => GardenSummaryCard(
                    garden: gardens[index],
                    onTap: () {
                      // Navigate to layout editor with this garden
                      context.push(
                        AppRoutes.manualInput,
                        extra: <String, dynamic>{'gardenId': gardens[index].id},
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text('Failed to load gardens.',
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(_gardenSummariesProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---- Upcoming tasks section ----
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            sliver: const SliverToBoxAdapter(
              child: UpcomingTasksWidget(),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.only(bottom: 96),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.capture),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('New Garden'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state widget
// ---------------------------------------------------------------------------
class _EmptyGardensState extends StatelessWidget {
  final VoidCallback onCreateTap;

  const _EmptyGardensState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.yard_outlined,
                size: 52,
                color: colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No gardens yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo of your garden to get started.\n'
              'Our AI will analyse it and suggest what to plant.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Create My First Garden'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.manualInput, extra: <String, dynamic>{}),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Or set up manually'),
            ),
          ],
        ),
      ),
    );
  }
}
