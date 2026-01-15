
class GlobalFeedData {
  // A simple list to hold the paths of photos you take
  static List<String> posts = []; 
}

// Add this to your global_data.dart or top of profile_screen.dart
class ProfileCache {
  static String? displayName;
  static String? bio;
  static String? profilePictureUrl;
  static int postCount = 0;
  static Map<String, List<Map<String, dynamic>>> postsByIsland = {};
  static DateTime? lastFetchTime;

  // Cache duration: 5 minutes
  static bool get isCacheValid {
    if (lastFetchTime == null) return false;
    return DateTime.now().difference(lastFetchTime!) < const Duration(minutes: 5);
  }

  static void clear() {
    lastFetchTime = null;
  }
}
