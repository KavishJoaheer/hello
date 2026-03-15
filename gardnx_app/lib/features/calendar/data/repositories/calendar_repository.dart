import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:gardnx_app/config/constants/api_constants.dart';
import 'package:gardnx_app/features/calendar/domain/models/planting_event.dart';
import 'package:gardnx_app/features/calendar/domain/models/task.dart';
import 'package:gardnx_app/features/plant_database/domain/models/plant.dart';

class CalendarRepository {
  final FirebaseFirestore _firestore;
  final Dio _dio;

  CalendarRepository({FirebaseFirestore? firestore, Dio? dio})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: ApiConstants.connectTimeout,
              receiveTimeout: ApiConstants.receiveTimeout,
            ));

  // ---- Backend: Generate calendar events from plant list -------------------

  /// Calls /calendar/generate with the correct request shape.
  ///
  /// [plants] are the Plant objects placed in the layout.
  /// Returns [PlantingEvent] objects ready to be saved to Firestore.
  Future<List<PlantingEvent>> generateCalendar({
    required String gardenId,
    required String bedId,
    required String bedName,
    required String region,
    required List<Plant> plants,
  }) async {
    if (plants.isEmpty) return [];

    final plantEntries = plants
        .map((p) => {
              'plant_id': p.id,
              'plant_name': p.name,
              'bed_name': bedName,
              'sowing_months': p.timing.sowMonths,
              'transplant_months': p.timing.transplantMonths,
              'harvest_months': p.timing.harvestMonths,
              'days_to_germination': 7,
              'days_to_harvest': p.timing.daysToMaturity,
            })
        .toList();

    try {
      final response = await _dio.post('/calendar/generate', data: {
        'plants': plantEntries,
        'garden_info': {
          'region': region,
          'latitude': -20.2,
          'longitude': 57.5,
        },
        'start_date': DateTime.now().toIso8601String().split('T')[0],
      });

      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data['events'] as List<dynamic>? ?? [];
        return raw.map((e) {
          final m = e as Map<String, dynamic>;
          return PlantingEvent(
            id: '',
            gardenId: gardenId,
            bedId: bedId,
            plantId: m['plant_id'] as String?,
            plantName: m['plant_name'] as String? ?? '',
            eventType: PlantingEventTypeExt.fromValue(
                m['event_type'] as String? ?? 'general'),
            date: DateTime.parse(m['start_date'] as String),
            notes: m['description'] as String?,
            isCompleted: false,
          );
        }).toList();
      }
    } on DioException {
      // Fall through — caller handles empty list gracefully.
    }
    return [];
  }

  // ---- Firestore: Events ---------------------------------------------------

  CollectionReference<Map<String, dynamic>> _eventsCollection(
          String gardenId) =>
      _firestore
          .collection('gardens')
          .doc(gardenId)
          .collection('events');

  Future<List<PlantingEvent>> getEvents(String gardenId) async {
    try {
      final snapshot = await _eventsCollection(gardenId)
          .orderBy('date')
          .get();
      return snapshot.docs
          .map((doc) =>
              PlantingEvent.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents(
      String gardenId, List<PlantingEvent> events) async {
    final batch = _firestore.batch();
    for (final event in events) {
      final data = event.toJson();
      data['saved_at'] = FieldValue.serverTimestamp();
      if (event.id.isNotEmpty) {
        batch.set(
            _eventsCollection(gardenId).doc(event.id), data);
      } else {
        batch.set(_eventsCollection(gardenId).doc(), data);
      }
    }
    await batch.commit();
  }

  Future<void> updateEventCompletion(
      String gardenId, String eventId, bool completed) async {
    await _eventsCollection(gardenId)
        .doc(eventId)
        .update({'is_completed': completed});
  }

  // ---- Firestore: Tasks ---------------------------------------------------

  CollectionReference<Map<String, dynamic>> _tasksCollection(
          String gardenId) =>
      _firestore
          .collection('gardens')
          .doc(gardenId)
          .collection('tasks');

  Future<List<PlantingTask>> getTasks(String gardenId) async {
    try {
      final snapshot =
          await _tasksCollection(gardenId).orderBy('due_date').get();
      return snapshot.docs
          .map((doc) =>
              PlantingTask.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlantingTask>> getUpcomingTasks(
      {int daysAhead = 14}) async {
    final now = DateTime.now();
    final until = now.add(Duration(days: daysAhead));
    try {
      // Query across all gardens by using collection group
      final snapshot = await _firestore
          .collectionGroup('tasks')
          .where('is_completed', isEqualTo: false)
          .where('due_date',
              isGreaterThanOrEqualTo: now.toIso8601String())
          .where('due_date',
              isLessThanOrEqualTo: until.toIso8601String())
          .orderBy('due_date')
          .limit(20)
          .get();
      return snapshot.docs
          .map((doc) =>
              PlantingTask.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(
      String gardenId, List<PlantingTask> tasks) async {
    final batch = _firestore.batch();
    for (final task in tasks) {
      final data = task.toJson();
      data['saved_at'] = FieldValue.serverTimestamp();
      if (task.id.isNotEmpty) {
        batch.set(_tasksCollection(gardenId).doc(task.id), data);
      } else {
        batch.set(_tasksCollection(gardenId).doc(), data);
      }
    }
    await batch.commit();
  }

  Future<void> completeTask(
      String gardenId, String taskId, bool completed) async {
    await _tasksCollection(gardenId).doc(taskId).update({
      'is_completed': completed,
      'completed_at': completed
          ? DateTime.now().toIso8601String()
          : null,
    });
  }

  Stream<List<PlantingTask>> tasksStream(String gardenId) {
    return _tasksCollection(gardenId)
        .orderBy('due_date')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) =>
                PlantingTask.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}
