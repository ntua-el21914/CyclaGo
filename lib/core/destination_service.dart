import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

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

  // All 23 Cyclades islands
  static const List<String> _islands = [
    'Naxos',
    'Paros',
    'Mykonos',
    'Santorini',
    'Ios',
    'Syros',
    'Tinos',
    'Andros',
    'Kea',
    'Kythnos',
    'Serifos',
    'Sifnos',
    'Folégandros',
    'Sikinos',
    'Amorgos',
    'Anafi',
    'Schinoussa',
    'Donoussa',
    'Kounoupas',
    'Heraklia',
    'Kato Koufonissi',
    'Ano Koufonissi',
    'Antiparos',
    'Delos',
    'Rhenia',
  ];

  // Island images for dynamic display
static const Map<String, String> _islandImages = {
  // --- Major Islands (Unsplash - High Quality, Royalty Free) ---
  'naxos': 'https://images.greeka.com/resized/user_images/marketka84/1920/php2CPhPN.jpg',
  'paros': 'https://www.aegeanislands.gr/app/uploads/2020/06/shutterstock_367041155-1.jpg',
  'mykonos': 'https://images.greeka.com/resized/user_images/dannyb/580/phphdV9bR.jpg',
  'santorini': 'https://www.greeka.com/village_beach/photos/135/oia-top-1-1280.jpg',
  'ios': 'https://www.aegeanislands.gr/app/uploads/2020/06/shutterstock_346259042-1-1618x1080.jpg', 
  
  // --- Medium Islands (Wikimedia Commons - Stable File Paths) ---
  'syros': 'https://commons.wikimedia.org/wiki/Special:FilePath/Ermoupoli,_Syros_island,_Greece.jpg',
  'tinos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Saint_Sostis_church_in_Tinos_island,_Greece.jpg',
  'andros': 'https://commons.wikimedia.org/wiki/Special:FilePath/Chora_Andros_from_Archaeological_Museum,_090592.jpg',
  'kea': 'https://commons.wikimedia.org/wiki/Special:FilePath/Ioulis_at_Kea_(Tzia)_Island_-_panoramio_(1).jpg',
  'kythnos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Kolona_beach,_Kythnos_2018_n2.jpg',
  'serifos': 'https://commons.wikimedia.org/wiki/Special:FilePath/%CE%A7%CF%8E%CF%81%CE%B1_%CE%A3%CE%B5%CF%81%CE%AF%CF%86%CE%BF%CF%85_9771.jpg', // Encoded filename
  'sifnos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Church_of_the_Seven_Martyrs_01.jpg',
  'folégandros': 'https://commons.wikimedia.org/wiki/Special:FilePath/Chora_of_Folegandros,_076078.jpg',
  'sikinos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Moni_Zoodochos_Pigi,_Sikinos,_247994.jpg',
  'amorgos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Hozoviotissa_Monastery.jpg',
  'anafi': 'https://commons.wikimedia.org/wiki/Special:FilePath/Kalamos_from_Chora,_Anafi,_176420.jpg',
  'antiparos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Antiparos_Beach.jpg',

  // --- Small / Obscure Islands (Specific verified Commons files) ---
  'schinoussa': 'https://commons.wikimedia.org/wiki/Special:FilePath/Schinoussa_Mersini_060565.jpg',
  'donoussa': 'https://commons.wikimedia.org/wiki/Special:FilePath/Donoussa,_085174.jpg',
  'heraklia': 'https://commons.wikimedia.org/wiki/Special:FilePath/The_small_port_of_Irakleia_island_(Cyclades).jpg',
  'kato koufonissi': 'https://commons.wikimedia.org/wiki/Special:FilePath/Kato_Koufonisi_beach,_190073.jpg',
  'ano koufonissi': 'https://commons.wikimedia.org/wiki/Special:FilePath/Koufonisi_Pori.jpg',
  'kounoupas': 'https://commons.wikimedia.org/wiki/Special:FilePath/Dodekanese%2CKounoupas1.jpg', // Note: Tiny islet off Astypalaia
  'delos': 'https://commons.wikimedia.org/wiki/Special:FilePath/Terrace_of_the_Lions_Delos_130058.jpg',
  'rhenia': 'https://commons.wikimedia.org/wiki/Special:FilePath/Rinia_south_coast_bight_beach.jpg',
};

  // Island centers for location validation
  static const Map<String, LatLng> _islandCenters = {
    'naxos': LatLng(37.1032, 25.3764),
    'paros': LatLng(37.0857, 25.1489),
    'mykonos': LatLng(37.4467, 25.3289),
    'santorini': LatLng(36.3932, 25.4615),
    'ios': LatLng(36.7236, 25.2822),
    'syros': LatLng(37.4433, 24.9394),
    'tinos': LatLng(37.5375, 25.1634),
    'andros': LatLng(37.8333, 24.9333),
    'kea': LatLng(37.6167, 24.3333),
    'kythnos': LatLng(37.3833, 24.4167),
    'serifos': LatLng(37.15, 24.5),
    'sifnos': LatLng(36.9667, 24.7),
    'folégandros': LatLng(36.6167, 24.9167),
    'sikinos': LatLng(36.6833, 25.1167),
    'amorgos': LatLng(36.8333, 25.9),
    'anafi': LatLng(36.35, 25.7833),
    'schinoussa': LatLng(36.8734, 25.5089),
    'donoussa': LatLng(37.1, 25.8167),
    'kounoupas': LatLng(36.8833, 25.5167),
    'heraklia': LatLng(36.8167, 25.45),
    'kato koufonissi': LatLng(36.9333, 25.6),
    'ano koufonissi': LatLng(36.9333, 25.6167),
    'antiparos': LatLng(37.0394, 25.0828),
    'delos': LatLng(37.3967, 25.2689),
    'rhenia': LatLng(37.45, 25.3167),
  };

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

  /// Get the allowed radius in meters for location validation on an island
  static double getIslandRadius(String islandName) {
    // Define radii per island (in meters)
    const Map<String, double> islandRadii = {
      'naxos': 50000, // 50km
      'paros': 40000, // 40km
      'mykonos': 30000, // 30km
      'santorini': 35000, // 35km
      'ios': 25000, // 25km
      'syros': 30000, // 30km
      'tinos': 35000, // 35km
      'andros': 40000, // 40km
      'kea': 20000, // 20km
      'kythnos': 25000, // 25km
      'serifos': 25000, // 25km
      'sifnos': 30000, // 30km
      'folégandros': 20000, // 20km
      'sikinos': 15000, // 15km
      'amorgos': 35000, // 35km
      'anafi': 30000, // 30km
      'schinoussa': 10000, // 10km
      'donoussa': 10000, // 10km
      'kounoupas': 5000, // 5km
      'heraklia': 15000, // 15km
      'kato Koufonissi': 15000, // 15km
      'ano Koufonissi': 10000, // 10km
      'antiparos': 20000, // 20km
      'delos': 5000, // 5km
      'rhenia': 10000, // 10km
    };
    return islandRadii[islandName.toLowerCase()] ?? 50000; // Default 50km
  }

  /// Get the island centers map
  static Map<String, LatLng> get islandCenters => _islandCenters;

  /// Get the island images map
  static Map<String, String> get islandImages => _islandImages;

  /// Get the image URL for a specific island
  static String getIslandImage(String islandName) {
    return _islandImages[islandName.toLowerCase()] ?? 'https://www.greeka.com/photos/cyclades/naxos/greeka_galleries/37-1024.jpg';
  }

  /// Get the list of islands
  static List<String> get islands => _islands;
  static String? findNearestIsland(double userLat, double userLng) {
    String? nearestIsland;
    double minDistance = double.infinity;
    const Distance distance = Distance();

    for (var entry in _islandCenters.entries) {
      final d = distance.as(
        LengthUnit.Kilometer,
        LatLng(userLat, userLng),
        entry.value,
      );
      if (d < minDistance) {
        minDistance = d;
        nearestIsland = entry.key;
      }
    }

    // Only return if within the island's radius
    if (nearestIsland != null && minDistance * 1000 <= getIslandRadius(nearestIsland)) {
      // Convert to proper case (e.g., 'naxos' -> 'Naxos')
      return _islands.firstWhere(
        (island) => island.toLowerCase() == nearestIsland,
        orElse: () => nearestIsland!,
      );
    }
    return null;
  }
}
