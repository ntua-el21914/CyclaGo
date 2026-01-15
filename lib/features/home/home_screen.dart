import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
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
  // This will now be handled inside the build to remain island-specific
  Stream<QuerySnapshot>? _islandSpecificUnlockStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedIslands.isNotEmpty) {
      for (var island in _selectedIslands) {
        final imageUrl = DestinationService.islandImages[island.toLowerCase()];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          precacheImage(NetworkImage(imageUrl), context);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _pageController.addListener(_onPageChanged);

    _eventsStream = FirebaseFirestore.instance.collection('events').snapshots();

    Future.microtask(() {
      _fetchUserName();
      _selectRandomIslands();
      _getCurrentIsland();
    });
  }

  // --- LOGIC: CREATE STREAM ONLY FOR CURRENT ISLAND ---
  void _updateUnlockStream() {
    final user = FirebaseAuth.instance.currentUser;
    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));

    if (user != null && _currentIslandName != null) {
      setState(() {
        _islandSpecificUnlockStream = FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: user.uid)
            .where('island', isEqualTo: _currentIslandName) // CRITICAL FILTER
            .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
            .snapshots();
      });
    }
  }

  void _onPageChanged() {
    setState(() => _currentPage = _pageController.page ?? 0);
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
      _updateUnlockStream(); // Update the lock check whenever the island changes
    }
    if (mounted) setState(() => _selectedIslands = all.take(4).toList());
  }

  Future<void> _getCurrentIsland() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(accuracy: LocationAccuracy.medium),
        timeLimit: const Duration(seconds: 5),
      );
      String? island = DestinationService.findNearestIsland(position.latitude, position.longitude);
      if (island != null && mounted) {
        _selectRandomIslands(currentIsland: island);
        if (_pageController.hasClients) _pageController.jumpToPage(0);
      }
    } catch (e) {
      debugPrint("Loc Error: $e");
    }
  }

  Future<void> _shareEventToChat(String title, String subtitle, bool isUnlocked) async {
    if (!isUnlocked || _currentIslandName == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('destinations')
          .doc(_currentIslandName!.toLowerCase())
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
      // Listen to the island-specific stream
      stream: _islandSpecificUnlockStream,
      builder: (context, unlockSnapshot) {
        // Master Logic: Locked if NO post on THIS island in 24h
        bool isUnlocked = (unlockSnapshot.hasData && unlockSnapshot.data!.docs.isNotEmpty);

        return Scaffold(
          backgroundColor: const Color(0xFFF6F9FC),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.hammersmithOne(fontSize: 24, color: Colors.black),
                      children: [
                        const TextSpan(text: 'Hello,\n'),
                        TextSpan(text: _displayName, style: const TextStyle(fontSize: 32)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 330,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _selectedIslands.length,
                      itemBuilder: (context, index) => _buildIslandCard(_selectedIslands[index], primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPageIndicator(primaryBlue),
                  const SizedBox(height: 30),
                  _buildFirebaseSection("Events", _eventsStream, primaryBlue, true, isUnlocked),
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

  Widget _buildFirebaseSection(String title, Stream<QuerySnapshot> stream, Color blue, bool isEvent, bool isPassUnlocked) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: blue, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.hammersmithOne(color: blue, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool itemLocked = isEvent && !isPassUnlocked;
                  bool isFarAway = _currentIslandName == null;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InfoCard(
                      title: data['title'] ?? '',
                      subtitle: data['subtitle'] ?? '',
                      icon: _getIconData(data['icon'] ?? ''),
                      isLocked: itemLocked,
                      isFarAway: isFarAway,
                      onLongPress: () => _shareEventToChat(data['title'], data['subtitle'], isPassUnlocked),
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
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: user.uid).snapshots(),
      builder: (context, snapshot) {
        int uniqueIslands = 0;
        int totalPosts = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalPosts = docs.length;
          final islands = <String>{};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final island = data['island'] as String?;
            if (island != null) islands.add(island);
          }
          uniqueIslands = islands.length;
        }

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
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Challenges', style: GoogleFonts.hammersmithOne(color: blue, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _ChallengeCard(title: 'Visit $islandTarget Islands', progress: uniqueIslands, target: islandTarget, icon: Icons.flag),
              const SizedBox(height: 12),
              _ChallengeCard(title: 'Make $postTarget Posts', progress: totalPosts, target: postTarget, icon: Icons.camera_enhance),
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
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.grey[200]),
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
              child: Text(name, style: GoogleFonts.hammersmithOne(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(Color blue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_selectedIslands.length, (index) => Container(
        width: 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(shape: BoxShape.circle, color: index == _currentPage.round() ? blue : Colors.grey.withOpacity(0.3)),
      )),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'beach': return Icons.beach_access;
      case 'music': return Icons.music_note;
      case 'scuba': return Icons.scuba_diving;
      case 'flag': return Icons.flag;
      case 'camera': return Icons.camera_enhance;
      case 'restaurant': return Icons.restaurant;
      default: return Icons.star_border;
    }
  }
}

class _InfoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isLocked;
  final bool isFarAway;
  final VoidCallback onLongPress;

  const _InfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isLocked,
    required this.isFarAway,
    required this.onLongPress,
  });

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _isJustShared = false;
  bool _showLockedError = false;
  bool _showFarAwayError = false;

  void _handleLongPress() {
    if (widget.isFarAway) {
      HapticFeedback.vibrate();
      setState(() => _showFarAwayError = true);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _showFarAwayError = false);
      });
      return; 
    }

    if (widget.isLocked) {
      HapticFeedback.vibrate();
      setState(() => _showLockedError = true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showLockedError = false);
      });
      return; 
    }

    widget.onLongPress();
    setState(() => _isJustShared = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _isJustShared = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    const Color errorRed = Colors.redAccent;
    const Color lockedGrey = Color(0xFFBDBDBD);

    String displayText = widget.title;
    if (_showFarAwayError) displayText = "You are far from the Cyclades!";
    if (_showLockedError) displayText = "Island Pass Locked!";
    if (_isJustShared) displayText = "Event Shared!";

    bool hasActiveError = _showFarAwayError || _showLockedError;

    Color bgColor = Colors.white;
    if (_isJustShared) bgColor = primaryBlue;
    if (hasActiveError) bgColor = errorRed;

    Color contentColor = primaryBlue;
    if (widget.isLocked) contentColor = lockedGrey;
    if (_isJustShared || hasActiveError) contentColor = Colors.white;

    Color borderColor = widget.isLocked ? lockedGrey : primaryBlue;
    if (_isJustShared || hasActiveError) borderColor = Colors.transparent;

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
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.hammersmithOne(
                  color: contentColor,
                  fontSize: _showFarAwayError ? 13 : 16,
                  fontWeight: (_isJustShared || hasActiveError) ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!_isJustShared && !hasActiveError)
              Row(
                children: [
                  Text(widget.subtitle, style: GoogleFonts.hammersmithOne(color: contentColor, fontSize: 13)),
                  const SizedBox(width: 10),
                  Icon(widget.isLocked ? Icons.lock_outline : widget.icon, size: 18, color: contentColor),
                ],
              )
            else
              Icon(
                hasActiveError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

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
              style: GoogleFonts.hammersmithOne(color: contentColor, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Text('$progress/$target', style: GoogleFonts.hammersmithOne(color: contentColor, fontSize: 13)),
              const SizedBox(width: 10),
              Icon(isCompleted ? Icons.check_circle : icon, size: 18, color: contentColor),
            ],
          ),
        ],
      ),
    );
  }
}