import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
import 'package:cyclago/features/social/group_chat_screen.dart';
import 'package:cyclago/features/profile/profile_screen.dart';
import 'package:cyclago/core/global_data.dart';
import 'package:cyclago/core/destination_service.dart';

class IslandPassScreen extends StatefulWidget {
  final bool isLocationValid;
  final VoidCallback? onRetry;
  final String? currentIsland;

  const IslandPassScreen({
    super.key,
    required this.isLocationValid,
    this.onRetry,
    this.currentIsland,
  });

  @override
  State<IslandPassScreen> createState() => _IslandPassScreenState();
}

class _IslandPassScreenState extends State<IslandPassScreen> {
  bool _isRetrying = false;
  String? _realUsername;

  // --- DELOADING: Pre-define Streams ---
  late Stream<QuerySnapshot> _unlockCheckStream;
  late Stream<QuerySnapshot> _socialFeedStream;

  @override
  void initState() {
    super.initState();
    
    // 1. Initialize streams IMMEDIATELY to avoid LateInitializationError
    final user = FirebaseAuth.instance.currentUser;
    final targetIsland = widget.currentIsland ?? 'Naxos';
    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));

    // Stream to check if the user themselves has unlocked the pass
    _unlockCheckStream = FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: user?.uid) // Faster to query by UID than username
        .where('island', isEqualTo: targetIsland)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
        .snapshots();

    // Stream for the general social feed grid
    _socialFeedStream = FirebaseFirestore.instance
        .collection('posts')
        .where('island', isEqualTo: targetIsland)
        .orderBy('timestamp', descending: true)
        .snapshots();

    // 2. Heavy work in microtask to keep Main Thread clean
    Future.microtask(() {
      _resolveUsername();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 3. PRE-CACHE the island groupchat image to avoid flickering
    final islandImg = DestinationService.getIslandImage(widget.currentIsland ?? "Naxos");
    precacheImage(NetworkImage(islandImg), context);
  }

  Future<void> _resolveUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          if (userDoc.exists && userDoc.data()!.containsKey('username')) {
            _realUsername = userDoc.data()!['username'];
          } else {
            _realUsername = user.displayName ?? user.email?.split('@')[0] ?? "Cyclist";
          }
        });
      }
    } catch (e) {
      debugPrint("Error resolving username: $e");
    }
  }

  Future<void> _refreshFeed() async {
    final user = FirebaseAuth.instance.currentUser;
    final targetIsland = widget.currentIsland ?? 'Naxos';
    final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));

    setState(() {
      _unlockCheckStream = FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user?.uid)
          .where('island', isEqualTo: targetIsland)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .snapshots();

      _socialFeedStream = FirebaseFirestore.instance
          .collection('posts')
          .where('island', isEqualTo: targetIsland)
          .orderBy('timestamp', descending: true)
          .snapshots();
    });

    await _resolveUsername();
  }

  void _showExpandedImage(List<Map<String, dynamic>> posts, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) => _IslandPassImageViewer(posts: posts, initialIndex: initialIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    if (!widget.isLocationValid) return _buildInvalidLocationScreen(primaryBlue);
    if (FirebaseAuth.instance.currentUser == null) return _buildEmptyState(context, primaryBlue);

    return StreamBuilder<QuerySnapshot>(
      stream: _unlockCheckStream,
      builder: (context, snapshot) {
        // Pass is unlocked if Firestore has a recent post OR local session has one
        bool isUnlocked = (snapshot.hasData && snapshot.data!.docs.isNotEmpty) || 
                          GlobalFeedData.posts.isNotEmpty;

        return _buildValidIslandPass(primaryBlue, isUnlocked);
      },
    );
  }

  // --- ❌ INVALID LOCATION SCREEN ---
  Widget _buildInvalidLocationScreen(Color primaryBlue) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(primaryBlue),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height - 280,
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryBlue, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 80, color: primaryBlue),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryBlue, width: 3),
                        ),
                        child: Text('Invalid Location', style: GoogleFonts.hammersmithOne(color: primaryBlue, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: _isRetrying ? null : () async {
                          if (widget.onRetry != null) {
                            setState(() => _isRetrying = true);
                            await Future.delayed(const Duration(milliseconds: 500));
                            widget.onRetry!();
                            if (mounted) setState(() => _isRetrying = false);
                          }
                        },
                        child: Container(
                          width: 130, height: 40,
                          decoration: BoxDecoration(
                            color: _isRetrying ? Colors.white : primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                            border: _isRetrying ? Border.all(color: primaryBlue, width: 2) : null,
                          ),
                          child: Center(
                            child: _isRetrying
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(primaryBlue)))
                              : Text('Try again?', style: GoogleFonts.hammersmithOne(color: _isRetrying ? primaryBlue : Colors.white, fontSize: 18)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ✅ MAIN SCREEN ---
  Widget _buildValidIslandPass(Color primaryBlue, bool isUnlocked) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 100;
    final String displayIsland = widget.currentIsland ?? "Naxos";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(primaryBlue),
            Expanded(
              child: RefreshIndicator(
                color: primaryBlue,
                onRefresh: _refreshFeed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        if (isUnlocked) ...[
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => GroupChatScreen(islandName: displayIsland)));
                            },
                            child: Container(
                              height: 60, width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: primaryBlue, width: 1.5),
                                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: NetworkImage(DestinationService.getIslandImage(displayIsland)),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text("$displayIsland Groupchat", style: GoogleFonts.hammersmithOne(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                                  const Spacer(),
                                  const Padding(padding: EdgeInsets.only(right: 20.0), child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1269C7))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        isUnlocked
                            ? _buildRealSocialFeed(primaryBlue, bottomPadding)
                            : _buildEmptyState(context, primaryBlue),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color primaryBlue) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height - 280,
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => CameraScreen(currentIsland: widget.currentIsland)));
              _resolveUsername();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.camera_alt_rounded, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text("Post to view", style: GoogleFonts.hammersmithOne(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildRealSocialFeed(Color primaryBlue, double bottomPadding) {
    return StreamBuilder<QuerySnapshot>(
      stream: _socialFeedStream, // Use the pre-defined stream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        final now = DateTime.now();
        final docs = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['timestamp'] == null) return false;
          final Timestamp ts = data['timestamp'];
          return now.difference(ts.toDate()).inHours < 24;
        }).toList() ?? [];

        if (docs.isEmpty) {
          return Center(child: Text("No posts in the last 24h.\nBe the first!", textAlign: TextAlign.center, style: GoogleFonts.hammersmithOne()));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding, top: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? '';
            final String username = data['username'] ?? 'Cyclist';
            final String? userId = data['userId'];
            final postsList = docs.map((d) => d.data() as Map<String, dynamic>).toList();

            return GestureDetector(
              onTap: () => _showExpandedImage(postsList, index),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey))),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.black.withOpacity(0.8), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
                        ),
                      ),
                      Positioned(
                        bottom: 12, left: 12,
                        child: GestureDetector(
                          onTap: userId != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId))) : null,
                          child: Text("@$username", style: GoogleFonts.hammersmithOne(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: Colors.white.withOpacity(0.5))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(width: 1.5, color: primaryBlue))),
      child: Center(child: Text('Island Pass', style: GoogleFonts.hammersmithOne(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold))),
    );
  }
}


  Widget _buildHeader(Color primaryBlue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(width: 1.5, color: primaryBlue)),
      ),
      child: Center(
        child: Text(
          'Island Pass',
          style: GoogleFonts.hammersmithOne(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }


// Image viewer for expanded post images in Island Pass
class _IslandPassImageViewer extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final int initialIndex;

  const _IslandPassImageViewer({
    required this.posts,
    required this.initialIndex,
  });

  @override
  State<_IslandPassImageViewer> createState() => _IslandPassImageViewerState();
}

class _IslandPassImageViewerState extends State<_IslandPassImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.posts.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  final post = widget.posts[index];
                  final imageUrl = post['imageUrl'] as String?;
                  if (imageUrl == null) return const SizedBox();

                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1269C7),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Username and Date below the image
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                final userId = widget.posts[_currentIndex]['userId'];
                if (userId != null) {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(userId: userId),
                    ),
                  );
                }
              },
              child: Text(
                '@${widget.posts[_currentIndex]['username'] ?? 'Cyclist'}',
                style: GoogleFonts.hammersmithOne(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(widget.posts[_currentIndex]['timestamp']),
              style: GoogleFonts.hammersmithOne(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            // Page indicator dots
            if (widget.posts.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.posts.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? const Color(0xFF1269C7)
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
