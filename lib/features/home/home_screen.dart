import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../main.dart';
import '../../core/destination_service.dart';
import '../../core/global_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = "";
  List<String> _selectedIslands = [];
  late PageController _pageController;
  double _currentPage = 0.0;

  // FIX: Initialize as null so we can check if location is ready
  String? _currentIslandName;

  late Stream<QuerySnapshot> _eventsStream;
  late Stream<QuerySnapshot> _challengesStream;
  late Stream<QuerySnapshot> _unlockStatusStream;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageChanged);

    _eventsStream = FirebaseFirestore.instance.collection('events').snapshots();
    _challengesStream = FirebaseFirestore.instance
        .collection('challenges')
        .snapshots();

    final user = FirebaseAuth.instance.currentUser;
    final twentyFourHoursAgo = DateTime.now().subtract(
      const Duration(hours: 24),
    );

    _unlockStatusStream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: user?.uid)
        .where(
          'timestamp',
          isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo),
        )
        .snapshots();

    _fetchUserName();
    _selectRandomIslands();
    // Start getting location immediately
    _getCurrentIsland();
  }

  void _selectRandomIslands({String? currentIsland}) {
    List<String> allIslands = List<String>.from(DestinationService.islands);
    allIslands.shuffle();

    if (currentIsland != null) {
      allIslands.removeWhere(
        (island) => island.toLowerCase() == currentIsland.toLowerCase(),
      );
      allIslands.insert(0, currentIsland);
      _currentIslandName = currentIsland; // Update the tracking variable
    }

    if (mounted) {
      setState(() {
        _selectedIslands = allIslands.take(4).toList();
      });
    }
  }

  Future<void> _getCurrentIsland() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        String? island = DestinationService.findNearestIsland(
          position.latitude,
          position.longitude,
        );

        if (island != null && mounted) {
          _selectRandomIslands(currentIsland: island);
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        }
      }
    } catch (e) {
      print("Location error: $e");
    }
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0;
    });
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _displayName = doc.data()?['username'] ?? 'Cyclist';
        });
      }
    }
  }

  // --- UPDATED SHARE LOGIC ---
  void _shareEventToChat(String title, String subtitle, bool isUnlocked) async {
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating, // Makes it float above the bottom
          margin: const EdgeInsets.only(
            bottom: 110,
            left: 20,
            right: 20,
          ), // Positions it above the nav bar
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Text(
            "Island Pass Locked! Post a photo to share.",
            style: GoogleFonts.hammersmithOne(),
          ),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ensure we have the location before sending
    if (_currentIslandName == null) {
      await _getCurrentIsland();
    }

    final String targetIsland = _currentIslandName ?? "Naxos";

    try {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(targetIsland.toLowerCase())
          .collection('messages')
          .add({
            'text': "📢 Event: $title ($subtitle)",
            'senderId': user.uid,
            'senderName': _displayName,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // --- SUCCESS POP UP AT BOTTOM ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            // Margin bottom 110 matches your page padding to sit perfectly above the Nav Bar
            margin: const EdgeInsets.only(bottom: 110, left: 20, right: 20),
            backgroundColor: const Color(0xFF1269C7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Shared to $targetIsland Chat!",
                    style: GoogleFonts.hammersmithOne(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Sharing error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return StreamBuilder<QuerySnapshot>(
      stream: _unlockStatusStream,
      builder: (context, unlockSnapshot) {
        bool isUnlocked =
            (unlockSnapshot.hasData && unlockSnapshot.data!.docs.isNotEmpty) ||
            GlobalFeedData.posts.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFF6F9FC),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 130,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.hammersmithOne(
                        fontSize: 24,
                        color: Colors.black,
                      ),
                      children: [
                        const TextSpan(text: 'Hello,\n'),
                        TextSpan(
                          text: _displayName,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 330,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _selectedIslands.length,
                      itemBuilder: (context, index) => _buildIslandCard(
                        _selectedIslands[index],
                        primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPageIndicator(primaryBlue),
                  const SizedBox(height: 30),

                  _buildFirebaseSection(
                    "Events",
                    _eventsStream,
                    primaryBlue,
                    true,
                    isUnlocked,
                  ),
                  const SizedBox(height: 30),
                  _buildFirebaseSection(
                    "Challenges",
                    _challengesStream,
                    primaryBlue,
                    false,
                    isUnlocked,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFirebaseSection(
    String title,
    Stream<QuerySnapshot> stream,
    Color blue,
    bool isEvent,
    bool isPassUnlocked,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: blue, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.hammersmithOne(
              color: blue,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool isItemLocked = !isPassUnlocked && isEvent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InfoCard(
                      title: data['title'] ?? '',
                      subtitle: data['subtitle'] ?? '',
                      icon: _getIconData(data['icon'] ?? ''),
                      isLocked: isItemLocked,
                      // The share logic now uses the latest location data
                      onLongPress: isEvent
                          ? () => _shareEventToChat(
                              data['title'],
                              data['subtitle'],
                              isPassUnlocked,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIslandCard(String name, Color blue) {
    final imageUrl = DestinationService.islandImages[name.toLowerCase()] ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty) Image.network(imageUrl, fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.1)),
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                name,
                style: GoogleFonts.hammersmithOne(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(Color blue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _selectedIslands.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentPage.round()
                ? blue
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'beach':
        return Icons.beach_access;
      case 'music':
        return Icons.music_note;
      case 'scuba':
        return Icons.scuba_diving;
      case 'flag':
        return Icons.flag;
      case 'camera':
        return Icons.camera_enhance;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.star_border;
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLocked;
  final VoidCallback? onLongPress;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLocked,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    Color contentColor = isLocked ? Colors.grey : primaryBlue;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        width: double.infinity,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: contentColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.hammersmithOne(
                  color: contentColor,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Text(
                  subtitle,
                  style: GoogleFonts.hammersmithOne(
                    color: contentColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  isLocked ? Icons.lock_outline : icon,
                  size: 18,
                  color: contentColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
