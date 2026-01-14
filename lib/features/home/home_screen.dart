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
    _getCurrentIsland();
  }

  void _onPageChanged() {
    setState(() => _currentPage = _pageController.page ?? 0);
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => _displayName = doc.data()?['username'] ?? 'Cyclist');
      }
    }
  }

  void _selectRandomIslands({String? currentIsland}) {
    List<String> all = List<String>.from(DestinationService.islands);
    all.shuffle();
    if (currentIsland != null) {
      all.removeWhere((i) => i.toLowerCase() == currentIsland.toLowerCase());
      all.insert(0, currentIsland);
      _currentIslandName = currentIsland;
    }
    if (mounted) setState(() => _selectedIslands = all.take(4).toList());
  }

  Future<void> _getCurrentIsland() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String? island = DestinationService.findNearestIsland(
        position.latitude,
        position.longitude,
      );
      if (island != null && mounted) {
        _selectRandomIslands(currentIsland: island);
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      }
    } catch (e) {
      print("Loc Error: $e");
    }
  }

  // --- SHARING LOGIC ---
  Future<void> _shareEventToChat(String title, String subtitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentIslandName == null) await _getCurrentIsland();
    final String islandDoc = (_currentIslandName ?? "Naxos").toLowerCase();

    try {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(islandDoc)
          .collection('messages')
          .add({
            'text': "📢 Event: $title ($subtitle)",
            'senderId': user.uid,
            'senderName': _displayName,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Sharing failed: $e");
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
                  bool itemLocked = !isPassUnlocked && isEvent;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InfoCard(
                      title: data['title'] ?? '',
                      subtitle: data['subtitle'] ?? '',
                      icon: _getIconData(data['icon'] ?? ''),
                      isLocked: itemLocked,
                      // Pass the logic to the card
                      onLongPress: isEvent
                          ? () => _shareEventToChat(
                              data['title'],
                              data['subtitle'],
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

// --- ANIMATED CARD ---
class _InfoCard extends StatefulWidget {
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
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _isJustShared = false;

  void _handleLongPress() {
    if (widget.isLocked || widget.onLongPress == null) {
      if (widget.isLocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Unlock Island Pass to share!"),
          ),
        );
      }
      return;
    }

    // 1. Call the Firebase Logic
    widget.onLongPress!();

    // 2. Animate the UI
    setState(() => _isJustShared = true);

    // 3. Revert UI
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _isJustShared = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    final Color bgColor = _isJustShared ? primaryBlue : Colors.white;
    final Color contentColor = widget.isLocked
        ? Colors.grey
        : (_isJustShared ? Colors.white : primaryBlue);

    return GestureDetector(
      onLongPress: _handleLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: contentColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _isJustShared ? "Event Shared!" : widget.title,
                style: GoogleFonts.hammersmithOne(
                  color: contentColor,
                  fontSize: 16,
                  fontWeight: _isJustShared
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_isJustShared)
              Row(
                children: [
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.hammersmithOne(
                      color: contentColor,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    widget.isLocked ? Icons.lock_outline : widget.icon,
                    size: 18,
                    color: contentColor,
                  ),
                ],
              )
            else
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
