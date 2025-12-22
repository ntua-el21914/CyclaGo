import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
import 'package:cyclago/features/social/group_chat_screen.dart';
import 'package:cyclago/core/global_data.dart';

class IslandPassScreen extends StatefulWidget {
  // Receive location status from MainScaffold
  final bool isLocationValid; 

  const IslandPassScreen({super.key, required this.isLocationValid});

  @override
  State<IslandPassScreen> createState() => _IslandPassScreenState();
}

class _IslandPassScreenState extends State<IslandPassScreen> {
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    // 1. INVALID LOCATION (Your exact design)
    if (!widget.isLocationValid) {
      return _buildInvalidLocationScreen(primaryBlue);
    }

    // 2. VALID LOCATION (Feed + Chat)
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
                          side: BorderSide(width: 3, color: primaryBlue),
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
                              // Since the check happens on MainScaffold, this might need a callback
                              // For now, it's visual, or you can use Navigator to reload MainScaffold
                              onTap: () {
                                // Optional: Trigger reload logic here
                                print("Retry clicked");
                              },
                              child: Container(
                                width: 130,
                                height: 40,
                                decoration: ShapeDecoration(
                                  color: primaryBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Try again?',
                                    style: GoogleFonts.hammersmithOne(
                                      color: Colors.white,
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
    // Dynamic Padding
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
                    if (hasPosted) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GroupChatScreen(islandName: "Naxos"),
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage("https://www.greeka.com/photos/cyclades/naxos/greeka_galleries/37-1024.jpg"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "Naxos Groupchat",
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
                      child: hasPosted 
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
        border: Border.all(color: primaryBlue, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CameraScreen()),
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

  // --- UNLOCKED FEED ---
  Widget _buildRealSocialFeed(Color primaryBlue, double bottomPadding) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBlue));
        }

        final docs = snapshot.data?.docs ?? [];
        
        if (docs.isEmpty) {
          return const Center(child: Text("No posts yet. Be the first!"));
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