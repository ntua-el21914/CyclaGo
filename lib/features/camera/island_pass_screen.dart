import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
import 'package:cyclago/features/social/group_chat_screen.dart';
import 'package:cyclago/core/global_data.dart';
import 'package:cyclago/core/destination_service.dart';

class IslandPassScreen extends StatefulWidget {
  // Receive location status and data from MainScaffold
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
  bool _hasPostedRecently = false;
  bool _isLoadingPostCheck = true;

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

  // --- 🕒 24-HOUR POST CHECK LOGIC ---
  Future<void> _checkRecentPost() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingPostCheck = false);
        return;
      }

      final twentyFourHoursAgo = DateTime.now().subtract(const Duration(hours: 24));
      final currentIsland = widget.currentIsland ?? 'Naxos';

      // Check if this specific user has posted on this specific island in the last 24h
      // Note: You should ensure your upload process saves 'userId' or 'username' to the post document.
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          // Assuming you saved 'userId' (recommended). If you saved 'username', change to: .where('username', isEqualTo: user.displayName)
          .where('userId', isEqualTo: user.uid) 
          .where('island', isEqualTo: currentIsland)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(twentyFourHoursAgo))
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _hasPostedRecently = querySnapshot.docs.isNotEmpty;
          _isLoadingPostCheck = false;
        });
      }
    } catch (e) {
      print('Error checking recent posts: $e');
      if (mounted) setState(() => _isLoadingPostCheck = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    // 1. INVALID LOCATION (Priority 1)
    // If location is invalid AND they haven't unlocked it via posting recently
    if (!widget.isLocationValid && !_hasPostedRecently) {
      return _buildInvalidLocationScreen(primaryBlue);
    }

    // 2. LOADING POST STATUS
    if (_isLoadingPostCheck) {
       return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    // 3. VALID LOCATION (Check if Locked or Unlocked based on posting)
    return _buildValidIslandPass(primaryBlue);
  }

  // --- ❌ INVALID LOCATION SCREEN ---
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
              child: SingleChildScrollView( 
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      width: 364, // Fixed Width
                      height: 600, // Fixed Height
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
                          // 1. Icon
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

                          // 3. "Try again?" Button
                          Positioned(
                            left: 117, 
                            top: 450,
                            child: GestureDetector(
                              onTap: _isRetrying ? null : () async {
                                if (widget.onRetry != null) {
                                  setState(() => _isRetrying = true);
                                  // Give UI time to update to loading state
                                  await Future.delayed(const Duration(milliseconds: 100)); 
                                  widget.onRetry!();
                                  // Note: _isRetrying remains true until the parent widget (MainScaffold) 
                                  // updates the isLocationValid parameter, causing this widget to rebuild.
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
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
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

  // --- ✅ VALID SCREEN (Handles Locked vs Unlocked Internally) ---
  Widget _buildValidIslandPass(Color primaryBlue) {
    // Dynamic Padding
    final double bottomPadding = MediaQuery.of(context).padding.bottom + 100;
    final String displayIsland = widget.currentIsland ?? "Naxos";

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

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // --- GROUP CHAT BUTTON (Only visible if Unlocked) ---
                    if (_hasPostedRecently) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(islandName: displayIsland),
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
                              // Island Icon (Dynamic)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    // Use dynamic image if available
                                    image: NetworkImage(
                                      DestinationService.getIslandImage(displayIsland)
                                    ),
                                    fit: BoxFit.cover,
                                    // Fallback if image fails
                                    onError: (e, s) {}, 
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "$displayIsland Groupchat",
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
                      child: _hasPostedRecently
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

  // --- LOCKED STATE (Camera Button) ---
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
            onTap: () async {
              // 1. Go to Camera Screen to take photo & upload
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraScreen(currentIsland: widget.currentIsland)),
              );
              // 2. When they come back (after posting), refresh the 24h check
              _checkRecentPost();
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

  // --- UNLOCKED FEED (Last 24h Posts) ---
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

        // Filter 24h client-side to ensure it works even without complex Firestore indexes
        final now = DateTime.now();
        final docs = snapshot.data?.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['timestamp'] == null) return false;
          final Timestamp ts = data['timestamp'];
          // Keep posts newer than 24h
          return now.difference(ts.toDate()).inHours < 24;
        }).toList() ?? [];
        
        if (docs.isEmpty) {
          return Center(child: Text("No posts in the last 24h.\nBe the first!", textAlign: TextAlign.center, style: GoogleFonts.hammersmithOne()));
        }

        return GridView.builder(
          padding: EdgeInsets.only(bottom: bottomPadding, top: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? '';
            
            // --- USERNAME LOGIC IS HERE ---
            // It tries to get 'username' from Firestore. If missing, defaults to 'Cyclist'.
            final String username = data['username'] ?? 'Cyclist'; 

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.black,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey)),
                    ),

                    // Gradient for text visibility
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),

                    // Username Display
                    Positioned(
                      bottom: 12, left: 12,
                      child: Text(
                        "@$username",
                        style: GoogleFonts.hammersmithOne(
                          color: Colors.white, 
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            const Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black),
                          ],
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