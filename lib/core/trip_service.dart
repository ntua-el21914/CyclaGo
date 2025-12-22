import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TripService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's trips collection reference
  static CollectionReference<Map<String, dynamic>> _getTripsCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(userId).collection('trips');
  }

  /// Save a new trip to Firestore
  static Future<String> saveTrip({
    required String tripName,
    required String island,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final tripsCollection = _getTripsCollection();
    
    final docRef = await tripsCollection.add({
      'tripName': tripName,
      'island': island,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return docRef.id;
  }

  /// Get all trips for the current user
  static Stream<QuerySnapshot<Map<String, dynamic>>> getTripsStream() {
    return _getTripsCollection()
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get all trips as a Future (one-time fetch)
  static Future<List<Map<String, dynamic>>> getTrips() async {
    final snapshot = await _getTripsCollection()
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Delete a trip by ID
  static Future<void> deleteTrip(String tripId) async {
    await _getTripsCollection().doc(tripId).delete();
  }

  /// Update an existing trip
  static Future<void> updateTrip({
    required String tripId,
    String? tripName,
    String? island,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final updates = <String, dynamic>{};
    
    if (tripName != null) updates['tripName'] = tripName;
    if (island != null) updates['island'] = island;
    if (startDate != null) updates['startDate'] = Timestamp.fromDate(startDate);
    if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
    
    if (updates.isNotEmpty) {
      await _getTripsCollection().doc(tripId).update(updates);
    }
  }

  /// Save spot selections for a trip
  static Future<void> saveSpotSelections({
    required String tripId,
    required Map<String, List<String>> selections,
  }) async {
    await _getTripsCollection().doc(tripId).update({
      'spotSelections': selections,
    });
  }

  /// Get spot selections for a trip
  static Future<Map<String, List<String>>> getSpotSelections(String tripId) async {
    final doc = await _getTripsCollection().doc(tripId).get();
    final data = doc.data();
    
    if (data == null || !data.containsKey('spotSelections')) {
      return {};
    }
    
    final raw = data['spotSelections'] as Map<String, dynamic>;
    return raw.map((key, value) => MapEntry(key, List<String>.from(value)));
  }
}
