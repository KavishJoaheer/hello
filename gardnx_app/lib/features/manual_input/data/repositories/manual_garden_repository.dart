import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gardnx_app/features/manual_input/domain/models/manual_bed.dart';

class ManualGardenRepository {
  final FirebaseFirestore _firestore;

  ManualGardenRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _bedsCollection(String gardenId) =>
      _firestore.collection('gardens').doc(gardenId).collection('beds');

  Future<List<ManualBed>> getBeds(String gardenId) async {
    try {
      final snapshot = await _bedsCollection(gardenId).get();
      return snapshot.docs
          .map((doc) => ManualBed.fromFirestore(doc.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<ManualBed> addBed(String gardenId, ManualBed bed) async {
    final docRef = await _bedsCollection(gardenId).add(bed.toFirestore());
    return bed.copyWith(id: docRef.id);
  }

  Future<void> updateBed(String gardenId, ManualBed bed) async {
    await _bedsCollection(gardenId).doc(bed.id).update(bed.toFirestore());
  }

  Future<void> removeBed(String gardenId, String bedId) async {
    await _bedsCollection(gardenId).doc(bedId).delete();
  }

  Future<void> clearBeds(String gardenId) async {
    final snapshot = await _bedsCollection(gardenId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<String> createGarden(String name, String region, String userId) async {
    final docRef = await _firestore.collection('gardens').add({
      'name': name,
      'region': region,
      'userId': userId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateGardenTimestamp(String gardenId) async {
    await _firestore.collection('gardens').doc(gardenId).update({
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ManualBed>> bedsStream(String gardenId) {
    return _bedsCollection(gardenId).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ManualBed.fromFirestore(doc.data()))
              .toList(),
        );
  }
}
