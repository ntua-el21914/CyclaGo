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
    'naxos': 'https://pixabay.com/get/gd4649f88280a1064bcb9373c30a8054bf02e08ce79ccd7951d9ed5eb90ccd2d4c647892abc7348d20c322f25348274b2_1920.jpg',
    'paros': 'https://pixabay.com/get/g55d51d33d091294199b237478ea4ffe35c7ce601a7027430ee0465ea75f9557c0665514c5650b6f95ba535babe5b73de_1920.jpg',
    'mykonos': 'https://pixabay.com/get/g7358abac9c1883288272be3caa5eb8c0c65d58fc1bee02386f55817f3df0a780edc691eb735f7c63e3a4ae30cfb729fc_1920.jpg',
    'santorini': 'https://pixabay.com/get/geb2909f1720ad603c9cb23d2e34346c390cde602072bbe89569597c665aeb513c777ee1653f7f6cbf9e469284673c66e_1920.jpg',
    'ios': 'https://pixabay.com/get/g972fa1664fbf7400fb7647604788250df7228df14d032f783d668de6f2b0e5845b5904fdc5d718bf5e01c8d813b27499_1920.jpg',
    'syros': 'https://pixabay.com/get/g4a470266ab095f09430c31b04d84da1c2561e75fa009da67ba8c6da13d082b97ae70f37c14cb5b377f38bdda79f94259_1920.jpg',
    'tinos': 'https://pixabay.com/get/g7e3b6cdb90c3af6dc195509adb6b0c7600b9686bf4ef2144568c2f256a1f35e1ed38a1c437fd3490bab4f1da4169022d_1920.jpg',
    'andros': 'https://pixabay.com/get/ga722f51388877fddf117a7e55b88a9d16c06f9b04eafb531d0fb69b3d1365800915485173cfd8800471fc2d43b0d34fd_1920.jpg',
    'kea': 'https://pixabay.com/get/g5119961a06b4117ad7f6a6fa9aa11709cff196c4cc47c3938f160c72d58e23dcfa0cfee60e68ec0781522fe2908f035f_1920.jpg',
    'kythnos': 'https://pixabay.com/get/g5119961a06b4117ad7f6a6fa9aa11709cff196c4cc47c3938f160c72d58e23dcfa0cfee60e68ec0781522fe2908f035f_1920.jpg',
    'serifos': 'https://pixabay.com/get/ga26a4613afc216b6a5c70c0d21af995e9148726a20daa4ad35844d3631742c7f7e13e28077617861ffd6e240a6dd248a_1920.jpg',
    'sifnos': 'https://pixabay.com/get/ga5c7aba9559daa35970b28e70c45f07ac3dbd62658a78059c8f64a62c64d12db0b558541e5685f666cec84ce677d9ec1_1920.jpg',
    'folégandros': 'https://pixabay.com/get/g064cfc85d3a733a3974c066fda9833a59a34805fff5b3449a756689ae6c1d3978de8840bbd83ee4892fb61025baa19dc_1920.jpg',
    'sikinos': 'https://pixabay.com/get/g4a470266ab095f09430c31b04d84da1c2561e75fa009da67ba8c6da13d082b97ae70f37c14cb5b377f38bdda79f94259_1920.jpg',
    'amorgos': 'https://pixabay.com/get/gb909f34210f400b399ee6de5fdca0a0319ee8768cc07cefe0252ae457c16cdab4bd9dabb4f259c9d8bbe50db0567e19e_1920.jpg',
    'anafi': 'https://pixabay.com/get/g51a95b19c9226c0ad9a3c422b4d1911af482215fe90d6fe022564b0e12b3f16df9011094121cacdca2c336fd3bc81d56_1920.jpg',
    'schinoussa': 'https://pixabay.com/get/g6141a8705169966883701c797cf977fc5a82ec136f87bef4ffb65d44dcdc2960f8da5b388348c55aa272dd4666d958f1_1920.jpg',
    'donoussa': 'https://pixabay.com/get/g939fa618676370a77cf78e8243a27e66a09aa290f54174e7b950ae0c7487a6bc5dfb2f6886b06844c902c868757a6b3a_1920.jpg',
    'kounoupas': 'https://pixabay.com/get/g5ae063d4b80e82a6548e5b12700af5f61aae66ec478455b363b9089b34fb2d1a7d9f9c7bf9f193c9cfb91d90c870fd5c_1920.jpg',
    'heraklia': 'https://pixabay.com/get/ge2fe909776bf9e2f03d8178a969ebbdb1b09e4103d4eb410fb0faad3fb654a5c9d95f177308be9c466cf8a30e94ac11c_1920.jpg',
    'k Koufonissi': 'https://pixabay.com/get/gdf61f6bd58b59d31be742fcbbdac21e569fbb04badd9bd7d07973f630e00b58095eb8c521c402c8c0d399e3e31382468_1920.jpg',
    'p Koufonissi': 'https://pixabay.com/get/g2cec497eee786cfc5277fe772213a0317acc9c6ed8ee991aaeeebb21adcd30b94af9205a1039ce87167f7ed5e75a3f3c_1920.jpg',
    'antiparos': 'https://pixabay.com/get/g2671736f7c32f6acb6ea38d4c7d5195eba1ce49774b407d3ff58ebef196126e86803ed1093625a1ee3bf0abbbf50a247_1920.jpg',
    'delos': 'https://pixabay.com/get/ged36fa3532a65f3e47ac9c9fc0821e0a31abaf4efb4a51b7072eb4e6b5f0798882f7a9fb70371b7eeae85f043dc553aa_1920.jpg',
    'rhenia': 'https://pixabay.com/get/g3c9a77a06a0875034bdbb63787a7637534eb2b38739d0d85ca25c3a780488fd4488b67213691ee7b4ecbd88c6e934f21_1920.jpg',
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
    'k Koufonissi': LatLng(36.9333, 25.6),
    'p Koufonissi': LatLng(36.9333, 25.6167),
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
      'k Koufonissi': 15000, // 15km
      'p Koufonissi': 10000, // 10km
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
