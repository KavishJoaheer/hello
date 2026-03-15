import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gardnx_app/features/calendar/domain/models/planting_event.dart';
import 'package:gardnx_app/features/calendar/data/repositories/calendar_repository.dart';

final calendarRepositoryProvider =
    Provider<CalendarRepository>((ref) => CalendarRepository());

// Current garden id context
final activeGardenIdProvider = StateProvider<String?>((ref) => null);

// Events for active garden
final gardenEventsProvider =
    FutureProvider<List<PlantingEvent>>((ref) async {
  final gardenId = ref.watch(activeGardenIdProvider);
  if (gardenId == null) return [];
  final repo = ref.read(calendarRepositoryProvider);
  return repo.getEvents(gardenId);
});

// Events grouped by day (for table_calendar markerBuilder)
final eventsByDayProvider =
    Provider<Map<DateTime, List<PlantingEvent>>>((ref) {
  final eventsAsync = ref.watch(gardenEventsProvider);
  return eventsAsync.when(
    data: (events) {
      final map = <DateTime, List<PlantingEvent>>{};
      for (final event in events) {
        final day = DateTime(
            event.date.year, event.date.month, event.date.day);
        map.putIfAbsent(day, () => []).add(event);
      }
      return map;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// StateNotifier for managing events with local mutations
class CalendarEventsNotifier
    extends StateNotifier<AsyncValue<List<PlantingEvent>>> {
  final CalendarRepository _repo;
  final String gardenId;

  CalendarEventsNotifier(this._repo, this.gardenId)
      : super(const AsyncLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final events = await _repo.getEvents(gardenId);
      state = AsyncData(events);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reload() => _load();

  Future<void> toggleEventCompletion(PlantingEvent event) async {
    final current = state.value;
    if (current == null) return;
    final updated = event.copyWith(isCompleted: !event.isCompleted);
    state = AsyncData(
      current.map((e) => e.id == event.id ? updated : e).toList(),
    );
    await _repo.updateEventCompletion(
        gardenId, event.id, updated.isCompleted);
  }
}

final calendarEventsNotifierProvider = StateNotifierProvider.family<
    CalendarEventsNotifier,
    AsyncValue<List<PlantingEvent>>,
    String>(
  (ref, gardenId) => CalendarEventsNotifier(
    ref.read(calendarRepositoryProvider),
    gardenId,
  ),
);

// Selected calendar day
final selectedCalendarDayProvider =
    StateProvider<DateTime>((ref) => DateTime.now());
