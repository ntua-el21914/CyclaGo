import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
import 'package:cyclago/features/social/group_chat_screen.dart';
import 'package:cyclago/core/global_data.dart';
import 'package:cyclago/core/destination_service.dart';

class IslandPassScreen extends StatefulWidget {
  // Receive location status from MainScaffold
  final bool isLocationValid;
  final VoidCallback? onRetry;
  final String? currentIsland;

  const IslandPassScreen({super.key, required this.isLocationValid, this.onRetry, this.currentIsland});

  @override
  State<IslandPassScreen> createState() => _IslandPassScreenState();
}

class _IslandPassScreenState extends State<IslandPassScreen> {
  bool _isRetrying = false;
  bool _hasPostedRecently = false;

  @override
  void initState() {
    super.initState();
    _checkRecentPost();
  }

  @override
  void didUpdateWidget(IslandPassScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset retry state when location validation changes
    if (oldWidget.isLocationValid != widget.isLocationValid) {
      _isRetrying = false;
    }
    // Check recent post when island changes
    if (oldWidget.currentIsland != widget.currentIsland) {
      _checkRecentPost();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check recent post when screen becomes visible again
    _checkRecentPost();
  }

  Future<void> _checkRecentPost() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      final currentIsland = widget.currentIsland ?? 'Naxos';
      
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user.uid)
          .where('island', isEqualTo: currentIsland)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _hasPostedRecently = querySnapshot.docs.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking recent posts: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    // If user has posted recently in this island OR has valid location, show unlocked screen
    final bool shouldShowUnlocked = _hasPostedRecently || widget.isLocationValid;

    // 1. INVALID LOCATION (Your exact design)
    if (!shouldShowUnlocked && !widget.isLocationValid) {
      return _buildInvalidLocationScreen(primaryBlue);
    }

    // 2. VALID LOCATION (Feed + Chat) or user has posted recently
    return _buildValidIslandPass(primaryBlue);
  }

  // --- ❌ INVALID LOCATION SCREEN (Fixed Width/Height) ---
  Widget _buildInvalidLocationScreen(Color primaryBlue) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
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
                    color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Error Content
            Expanded(
              // SingleChildScrollView prevents error on small screens if height 600 is too big
              child: SingleChildScrollView( 
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      width: 364, // Fixed Width from your code
                      height: 600, // Fixed Height from your code
                      clipBehavior: Clip.antiAlias,
                      decoration: ShapeDecoration(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1.5, color: primaryBlue),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 1. Icon (Centered horizontally)
                          Positioned(
                            left: 0, 
                            right: 0,
                            top: 180,
                            child: Icon(Icons.warning_amber_rounded, size: 80, color: primaryBlue),
                          ),

                          // 2. "Invalid Location" Box
                          Positioned(
                            left: 49,
                            top: 280,
                            child: Container(
                              width: 265,
                              height: 43,
                              decoration: ShapeDecoration(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(width: 4, color: primaryBlue),
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

                          // 3. "Try again?" Button (Clickable)
                          Positioned(
                            left: 117, // Centered roughly (364 - 130) / 2
                            top: 450,
                            child: GestureDetector(
                              onTap: _isRetrying ? null : () async {
                                if (widget.onRetry != null) {
                                  setState(() => _isRetrying = true);
                                  await Future.delayed(const Duration(milliseconds: 100)); // Small delay for UI feedback
                                  widget.onRetry!();
                                  // Note: We don't set _isRetrying = false here because the parent will rebuild when location check completes
                                } else {
                                  print("Retry clicked");
                                }
                              },
                              child: Container(
                                width: 130,
                                height: 40,
                                decoration: ShapeDecoration(
                                  color: _isRetrying ? Colors.white : primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: _isRetrying ? BorderSide(width: 2, color: primaryBlue) : BorderSide.none,
                                  ),
                                ),
                                child: Center(
                                  child: _isRetrying
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1269C7)),
                                        ),
                                      )
                                    : Text(
                                        'Try again?',
                                        style: GoogleFonts.hammersmithOne(
                                          color: _isRetrying ? primaryBlue : Colors.white,
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

  // --- ✅ VALID SCREEN (FEED + CHAT) ---
  Widget _buildValidIslandPass(Color primaryBlue) {
    bool hasPosted = GlobalFeedData.posts.isNotEmpty;
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 100;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(width: 1, color: primaryBlue)),
              ),
              child: Center(
                child: Text(
                  'Island Pass',
                  style: GoogleFonts.hammersmithOne(
                    color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // --- GROUP CHAT BUTTON ---
                    if (_hasPostedRecently) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(islandName: widget.currentIsland ?? "Naxos"),
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
                              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3)),
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
                                    image: NetworkImage(DestinationService.getIslandImage(widget.currentIsland ?? "Naxos")),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "${widget.currentIsland} Groupchat",
                                style: GoogleFonts.hammersmithOne(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(right: 20.0),
                                child: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1269C7)),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],

                    // --- FEED AREA ---
                    Expanded(
                      child: _buildRealSocialFeed(primaryBlue, bottomPadding),
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
        border: Border.all(color: primaryBlue, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraScreen(currentIsland: widget.currentIsland)),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 50, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Post to view",
            style: GoogleFonts.hammersmithOne(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  // --- COOLDOWN STATE (Posted recently, can't post again today) ---
  Widget _buildCooldownState(Color primaryBlue) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 60, color: primaryBlue),
          const SizedBox(height: 20),
          Text(
            "You've already posted today!",
            style: GoogleFonts.hammersmithOne(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Come back tomorrow to post again",
            style: GoogleFonts.hammersmithOne(
              fontSize: 16, color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // --- UNLOCKED FEED ---
  Widget _buildRealSocialFeed(Color primaryBlue, double bottomPadding) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('island', isEqualTo: widget.currentIsland ?? 'Naxos')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        final docs = snapshot.data?.docs ?? [];
        
        // If user has posted recently but no posts are showing yet, show loading
        if (docs.isEmpty && _hasPostedRecently) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryBlue),
                const SizedBox(height: 20),
                Text(
                  "Loading your post...",
                  style: GoogleFonts.hammersmithOne(
                    fontSize: 16, 
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        if (docs.isEmpty) {
          return _buildEmptyState(context, primaryBlue);
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
            final String username = data['username'] ?? 'Cyclist';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
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
                      errorBuilder: (context, error, stackTrace) {
                         return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey));
                      },
                    ),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12, left: 12,
                      child: Text(
                        "@$username",
                        style: GoogleFonts.hammersmithOne(
                          color: Colors.white, 
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}