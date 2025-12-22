import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
import 'package:cyclago/features/social/group_chat_screen.dart';
import 'package:cyclago/core/global_data.dart';

class IslandPassScreen extends StatefulWidget {
  const IslandPassScreen({super.key});

  @override
  State<IslandPassScreen> createState() => _IslandPassScreenState();
}

class _IslandPassScreenState extends State<IslandPassScreen> {
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);
    
    // THE GATE: Check if user has posted at least once locally
    bool hasPosted = GlobalFeedData.posts.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      
      // Wrap body in SafeArea
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM HEADER WITH BLUE BOTTOM BORDER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    width: 1,
                    color: primaryBlue,
                  ),
                ),
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
            ),

            // --- MAIN BODY CONTENT ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    // --- 1. NAXOS GROUP CHAT BUTTON (CONDITIONAL) ---
                    // This block only appears if 'hasPosted' is TRUE (Unlocked)
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
                              // Naxos Icon (Stable Version)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage("https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Portara_Naxos_01.jpg/640px-Portara_Naxos_01.jpg"),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Text(
                                "Naxos Groupchat",
                                style: GoogleFonts.hammersmithOne(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(right: 20.0),
                                child: Icon(Icons.arrow_forward_ios, size: 16, color: primaryBlue),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Spacing below the button
                    ],

                    // --- 2. THE FEED CONTENT ---
                    Expanded(
                      child: hasPosted 
                        ? _buildRealSocialFeed(primaryBlue)
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

  // --- STATE A: LOCKED (Post to view) ---
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

  // --- STATE B: UNLOCKED (Real Firestore Data) ---
 // --- STATE B: UNLOCKED (Real Firestore Data) ---
  Widget _buildRealSocialFeed(Color primaryBlue) {
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
          padding: const EdgeInsets.only(bottom: 120, top: 10),
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
                // REMOVED IMAGE FROM HERE
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)
                ],
              ),
              child: Stack(
                fit: StackFit.expand, // Ensures image fills the container
                children: [
                  // 1. IMAGE WIDGET (Supports errorBuilder)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                         return Container(
                           color: Colors.grey[200], 
                           child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))
                         );
                      },
                    ),
                  ),

                  // 2. GRADIENT OVERLAY
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),

                  // 3. USERNAME TEXT
                  Positioned(
                    bottom: 10, left: 10,
                    child: Text(
                      "@$username",
                      style: GoogleFonts.hammersmithOne(
                        color: Colors.white, 
                        fontSize: 12,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}