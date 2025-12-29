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
    'K Koufonissi',
    'P Koufonissi',
    'Antiparos',
    'Delos',
    'Rhenia',
  ];

  // Island images for dynamic display
  static const Map<String, String> _islandImages = {
    'naxos': 'https://images.greeka.com/resized/user_images/marketka84/1920/php2CPhPN.jpg',
    'paros': 'https://www.aegeanislands.gr/app/uploads/2020/06/shutterstock_367041155-1.jpg',
    'mykonos': 'https://images.greeka.com/resized/user_images/dannyb/580/phphdV9bR.jpg',
    'santorini': 'https://www.greeka.com/village_beach/photos/135/oia-top-1-1280.jpg',
    'ios': 'https://images.greeka.com/resized/user_images/dannyb/580/phpi8bES0.jpg',
    'syros': 'https://www.greeka.com/photos/cyclades/syros/greeka_galleries/54-480.jpg',
    'tinos': 'https://pixabay.com/get/g26c6496b34f9702dd73ff0c42bf66aeddda83e2f679e697e6dd3bc0079041557ec4a00e053452f74b782745f7ba22d57_1920.jpg',
    'andros': 'https://pixabay.com/get/g84b11516b4921a37e90cd908afde3e5e1bf315e4545b6ff792020cf4fbd33c277b9dc8e8c982f547f0823440e921289c_1920.jpg',
    'kea': 'https://pixabay.com/get/g939fa618676370a77cf78e8243a27e66a09aa290f54174e7b950ae0c7487a6bc5dfb2f6886b06844c902c868757a6b3a_1920.jpg',
    'kythnos': 'https://pixabay.com/get/g4798b7b8feed01683382b335305f1576a10010b5accf3d38ab4e4b4146c9c7d53f44badc95e4d7c6e65973d12f31fd50_1920.jpg',
    'serifos': 'https://pixabay.com/get/gcc0566d7ead7e04383242e895a357b7f176f0f1c3f89605627fec7b81fbcbbf046edacef7a39b0277ebb59fef748caa2_1920.jpg',
    'sifnos': 'https://pixabay.com/get/g652b04d19dfe8dcc7edf15cf35e9f1d3501b7192af12196ef822716b7928af2e1c799bba28b02681927298a242b3c4f2_1920.jpg',
    'folégandros': 'https://pixabay.com/get/gda6aac7558017a998b026988a744ed34965e9812e2672705edce2bad65511198ccf4c4ce4404ad58522da4cfb7658d82_1920.png',
    'sikinos': 'https://pixabay.com/get/g57bd65ec225b30492686b49b1eb6c50bd9024bc987cb039b7d9b10b021fc029bc868f5221369f23b88c40b9b25f4ba22_1920.jpg',
    'amorgos': 'https://pixabay.com/get/g292ca4f5cca7190b3e07ac1752e3002090e84aa98177309df3220b10898f4021d9cd46f9a0522deacd519b45aaeac00d_1920.jpg',
    'anafi': 'https://pixabay.com/get/g64e6235ed9d0b669d5917ddf265751073d791eec2a737f00f4b69e8103db569574df1e3cba4d2168d43435e8e9bca9f0_1920.jpg',
    'schinoussa': 'https://pixabay.com/get/gade7201bb4718bd0c43b6c16510dcbd860e14a562779e34b359d1bfc0ab670629e0cc6648e09fbe35aedfe3152803f5c_1920.jpg',
    'donoussa': 'https://pixabay.com/get/gb6e76bae368d38ed6351ef784149f0118068700110284e6da0c69b5b3437706d548b87de8f9b3958f365b16d2c0c9431_1920.jpg',
    'kounoupas': 'https://pixabay.com/get/g26bb619e90f64db48bbfaa21970b4873a842e2cc8cf7a7d3af7b73ddab06ae71bd6f1a1b926d0f7116b5b702ef79679f_1920.jpg',
    'heraklia': 'https://pixabay.com/get/g262d80c55ffd1aca34bd63ef18c3f6a062339328f4febbf26c44b6fb1973d4d0f524ada2245ac7266b92ff9e136e44c9_1920.jpg',
    'kato koufonissi': 'https://pixabay.com/get/g961bc9daa3e2939fca8c07b50282a19ec5724f1f6dc5022eb096d9620bb08c10797b609d485342f2d1ea80cab3eeea57_1920.jpg',
    'ano koufonissi': 'https://pixabay.com/get/g0ba89cc99c550796bccf3e77cb70e05d42c91e139384f932c33430feb650c7b6ccd9cce3f6ebf5fb3349cf76f9164bd8_1920.jpg',
    'antiparos': 'https://pixabay.com/get/g9813842c61b187e9ac0875afa5cd7d0e19d23cdc5f8b096aa8836e69b423820344e667d91ed9cba39c9e19dd6c90cb56_1920.jpg',
    'delos': 'https://pixabay.com/get/g07f234c939bec8e6cd4fd5cd11759623b8f0ba3b39d1cc5e4c87d52f780d7a065a3224aef3bc2180141a4fde7a71cfaf_1920.jpg',
    'rhenia': 'https://pixabay.com/get/g7101a58ce594a4722f543ee1b8c60cb6a58e6e39c7bcb9bac5df89838fd2f21813f31e3cbb09d0dbe15cd21602a0c3c8_1920.jpg',
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
