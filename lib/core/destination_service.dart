import 'package:cloud_firestore/cloud_firestore.dart';

/// Model class for a destination (beach, restaurant, landmark)
class Destination {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? description;
  final String? imageUrl;
  final String category; // 'beaches', 'restaurants', 'landmarks'
  final Map<String, dynamic>? extras; // For category-specific fields

  Destination({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.description,
    this.imageUrl,
    required this.category,
    this.extras,
  });

  factory Destination.fromFirestore(DocumentSnapshot doc, String category) {
    final data = doc.data() as Map<String, dynamic>;
    return Destination(
      id: doc.id,
      name: data['name'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      description: data['description'],
      imageUrl: data['imageUrl'],
      category: category,
      extras: data,
    );
  }
}

class DestinationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the document reference for an island
  static DocumentReference<Map<String, dynamic>> _getIslandDoc(String islandName) {
    // Convert island name to lowercase for Firestore document ID
    final docId = islandName.toLowerCase().replaceAll(' ', '_');
    return _firestore.collection('destinations').doc(docId);
  }

  /// Get all beaches for an island
  static Future<List<Destination>> getBeaches(String islandName) async {
    return _getDestinations(islandName, 'beaches');
  }

  /// Get all restaurants for an island
  static Future<List<Destination>> getRestaurants(String islandName) async {
    return _getDestinations(islandName, 'restaurants');
  }

  /// Get all landmarks for an island
  static Future<List<Destination>> getLandmarks(String islandName) async {
    return _getDestinations(islandName, 'landmarks');
  }

  /// Get all destinations of a specific category for an island
  static Future<List<Destination>> _getDestinations(String islandName, String category) async {
    try {
      final snapshot = await _getIslandDoc(islandName)
          .collection(category)
          .get();

      return snapshot.docs
          .map((doc) => Destination.fromFirestore(doc, category))
          .toList();
    } catch (e) {
      print('Error fetching $category for $islandName: $e');
      return [];
    }
  }

  /// Get all destinations for an island (all categories combined)
  static Future<Map<String, List<Destination>>> getAllDestinations(String islandName) async {
    final beaches = await getBeaches(islandName);
    final restaurants = await getRestaurants(islandName);
    final landmarks = await getLandmarks(islandName);

    return {
      'beaches': beaches,
      'restaurants': restaurants,
      'landmarks': landmarks,
    };
  }

  /// Get island metadata (name, description, etc.)
  static Future<Map<String, dynamic>?> getIslandInfo(String islandName) async {
    try {
      final doc = await _getIslandDoc(islandName).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching island info for $islandName: $e');
      return null;
    }
  }

  /// Stream of destinations for real-time updates
  static Stream<List<Destination>> getDestinationsStream(String islandName, String category) {
    return _getIslandDoc(islandName)
        .collection(category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Destination.fromFirestore(doc, category))
            .toList());
  }
}
