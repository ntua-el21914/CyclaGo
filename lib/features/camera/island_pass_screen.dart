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
  String? _realUsername; // Stores the actual username from DB (e.g. "_GeoFlo")

  @override
  void initState() {
    super.initState();
    _resolveUsername();
  }

  // --- CRITICAL FIX: GET REAL USERNAME ---
  Future<void> _resolveUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Fetch the user document to get the exact username stored in DB
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          if (userDoc.exists && userDoc.data()!.containsKey('username')) {
            _realUsername = userDoc.data()!['username'];
          } else {
            // Fallback: Try Auth Display Name or Email
            _realUsername =
                user.displayName ?? user.email?.split('@')[0] ?? "Cyclist";
          }
        });
      }
    } catch (e) {
      print("Error resolving username: $e");
    }
  }

  void _showExpandedImage(List<Map<String, dynamic>> posts, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (BuildContext context) {
        return _IslandPassImageViewer(posts: posts, initialIndex: initialIndex);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    // 1. INVALID LOCATION
    if (!widget.isLocationValid) {
      return _buildInvalidLocationScreen(primaryBlue);
    }

    // 2. CHECK POST STATUS (Live Stream)
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildEmptyState(context, primaryBlue);

    // If we haven't found the real username yet, wait a moment or try with default
    final targetName = _realUsername ?? "Cyclist";
    final currentIsland = widget.currentIsland ?? 'Naxos';
    final twentyFourHoursAgo = DateTime.now().subtract(
      const Duration(hours: 24),
    );

    return StreamBuilder<QuerySnapshot>(
      // Query: Did *I* (using my real DB name) post here recently?
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('username', isEqualTo: targetName)
          .where('island', isEqualTo: currentIsland)
          .where(
            'timestamp',
            isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo),
          )
          .snapshots(),
      builder: (context, snapshot) {
        // Unlocked if Firestore has data OR local session has data
        bool isUnlocked =
            (snapshot.hasData && snapshot.data!.docs.isNotEmpty) ||
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
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      width: 364,
                      height: 650,
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 3, color: primaryBlue),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 180,
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 80,
                              color: primaryBlue,
                            ),
                          ),
                          Positioned(
                            left: 49,
                            top: 280,
                            child: Container(
                              width: 265,
                              height: 43,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 4,
                                    color: primaryBlue,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Invalid Location',
                                  style: GoogleFonts.hammersmithOne(
                                    color: primaryBlue,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 117,
                            top: 450,
                            child: GestureDetector(
                              onTap: _isRetrying
                                  ? null
                                  : () async {
                                      if (widget.onRetry != null) {
                                        setState(() => _isRetrying = true);
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );
                                        widget.onRetry!();
                                        if (mounted)
                                          setState(() => _isRetrying = false);
                                      }
                                    },
                              child: Container(
                                width: 130,
                                height: 40,
                                decoration: ShapeDecoration(
                                  color: _isRetrying
                                      ? Colors.white
                                      : primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: _isRetrying
                                        ? BorderSide(
                                            width: 2,
                                            color: primaryBlue,
                                          )
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Center(
                                  child: _isRetrying
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  primaryBlue,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          'Try again?',
                                          style: GoogleFonts.hammersmithOne(
                                            color: _isRetrying
                                                ? primaryBlue
                                                : Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // --- GROUP CHAT BUTTON ---
                    if (isUnlocked) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GroupChatScreen(islandName: displayIsland),
                            ),
                          );
                        },
                        child: Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: primaryBlue, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      DestinationService.getIslandImage(
                                        displayIsland,
                                      ),
                                    ),
                                    fit: BoxFit.cover,
                                    onError: (e, s) {},
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "$displayIsland Groupchat",
                                style: GoogleFonts.hammersmithOne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(right: 20.0),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Color(0xFF1269C7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- FEED or LOCKED STATE ---
                    Expanded(
                      child: isUnlocked
                          ? _buildRealSocialFeed(primaryBlue, bottomPadding)
                          : _buildEmptyState(context, primaryBlue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOCKED STATE ---
  Widget _buildEmptyState(BuildContext context, Color primaryBlue) {
    return Container(
      width: double.infinity,
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
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CameraScreen(currentIsland: widget.currentIsland),
                ),
              );
              // Refresh username and state when returning
              _resolveUsername();
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Post to view",
            style: GoogleFonts.hammersmithOne(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- UNLOCKED FEED ---
  Widget _buildRealSocialFeed(Color primaryBlue, double bottomPadding) {
    final String targetIsland = widget.currentIsland ?? 'Naxos';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('island', isEqualTo: targetIsland)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        final now = DateTime.now();
        final docs =
            snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (data['timestamp'] == null) return false;
              final Timestamp ts = data['timestamp'];
              return now.difference(ts.toDate()).inHours < 24;
            }).toList() ??
            [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "No posts in the last 24h.\nBe the first!",
              textAlign: TextAlign.center,
              style: GoogleFonts.hammersmithOne(),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.only(bottom: bottomPadding, top: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? '';
            // Use username from post, but default to 'Cyclist' only if missing
            final String username = data['username'] ?? 'Cyclist';
            final String? userId = data['userId'];

            // Prepare posts list for expanded viewer
            final postsList = docs
                .map((d) => d.data() as Map<String, dynamic>)
                .toList();

            return GestureDetector(
              onTap: () => _showExpandedImage(postsList, index),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: userId != null
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProfileScreen(userId: userId),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            "@$username",
                            style: GoogleFonts.hammersmithOne(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white.withOpacity(0.5),
                            ),
                          ),
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
