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
  // Dynamic challenges - computed from user posts
  late Stream<QuerySnapshot> _unlockStatusStream;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageChanged);

    _eventsStream = FirebaseFirestore.instance.collection('events').snapshots();

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
                  _buildDynamicChallenges(primaryBlue),
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

  Widget _buildDynamicChallenges(Color blue) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int uniqueIslands = 0;
        int totalPosts = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalPosts = docs.length;
          
          // Count unique islands
          final islands = <String>{};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final island = data['island'] as String?;
            if (island != null) {
              islands.add(island);
            }
          }
          uniqueIslands = islands.length;
        }

        // Calculate progressive targets (increase by 5 each time goal is met)
        // Islands: base 5, Posts: base 10
        final int islandBase = 5;
        final int islandTarget = ((uniqueIslands ~/ islandBase) + 1) * islandBase;
        final int postBase = 10;
        final int postTarget = ((totalPosts ~/ postBase) + 1) * postBase;

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
                'Challenges',
                style: GoogleFonts.hammersmithOne(
                  color: blue,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              // Challenge 1: Visit Islands (progressive)
              _ChallengeCard(
                title: 'Visit $islandTarget Islands',
                progress: uniqueIslands,
                target: islandTarget,
                icon: Icons.flag,
              ),
              const SizedBox(height: 12),
              // Challenge 2: Make Posts (progressive)
              _ChallengeCard(
                title: 'Make $postTarget Posts',
                progress: totalPosts,
                target: postTarget,
                icon: Icons.camera_enhance,
              ),
            ],
          ),
        );
      },
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
    super.key,
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
  bool _showLockedError = false; // New state for the error feedback

  void _handleLongPress() {
    // IF LOCKED: Show "Island Pass Locked" error
    if (widget.isLocked) {
      setState(() => _showLockedError = true);

      // Revert the error text after 1.5 seconds
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showLockedError = false);
      });
      return;
    }

    // IF UNLOCKED: Proceed with sharing
    if (widget.onLongPress != null) {
      widget.onLongPress!();
      setState(() => _isJustShared = true);

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _isJustShared = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    const Color errorRed = Colors.redAccent;

    // Determine background color
    Color bgColor = Colors.white;
    if (_isJustShared) bgColor = primaryBlue;
    if (_showLockedError) bgColor = errorRed;

    // Determine content color (text and icons)
    Color contentColor = primaryBlue;
    if (widget.isLocked && !_showLockedError) contentColor = Colors.grey;
    if (_isJustShared || _showLockedError) contentColor = Colors.white;

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
                _showLockedError
                    ? "Island Pass Locked!"
                    : (_isJustShared ? "Event Shared!" : widget.title),
                style: GoogleFonts.hammersmithOne(
                  color: contentColor,
                  fontSize: 16,
                  fontWeight: (_isJustShared || _showLockedError)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Show icons only when in normal state
            if (!_isJustShared && !_showLockedError)
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
              Icon(
                _showLockedError
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// --- CHALLENGE CARD ---
class _ChallengeCard extends StatelessWidget {
  final String title;
  final int progress;
  final int target;
  final IconData icon;

  const _ChallengeCard({
    required this.title,
    required this.progress,
    required this.target,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    final bool isCompleted = progress >= target;
    final Color contentColor = isCompleted ? Colors.green : primaryBlue;

    return Container(
      width: double.infinity,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: contentColor, width: 1.5),
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
                '$progress/$target',
                style: GoogleFonts.hammersmithOne(
                  color: contentColor,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isCompleted ? Icons.check_circle : icon,
                size: 18,
                color: contentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
