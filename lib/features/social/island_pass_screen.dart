import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
import 'package:cyclago/features/social/chat_screen.dart'; // Ensure you have this file from previous steps
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
    
    // Determine state: Empty or Populated
    bool hasPhotos = GlobalFeedData.posts.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Island Pass',
          style: GoogleFonts.hammersmithOne(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Removes back button if present
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 1. THE NAXOS GROUP CHAT BUTTON (Always Visible)
            GestureDetector(
              onTap: () {
                // Navigate to the Chat Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(islandName: "Naxos"),
                  ),
                );
              },
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // Rounded pill shape
                  border: Border.all(color: primaryBlue, width: 1),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    // Circle Avatar (Island Icon)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                           // Placeholder image for Naxos icon
                          image: NetworkImage("https://placehold.co/50x50/png?text=N"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Text
                    Text(
                      "Naxos",
                      style: GoogleFonts.hammersmithOne(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. THE FEED CONTENT (Empty vs Populated)
            Expanded(
              child: hasPhotos 
                ? _buildPhotoFeed(primaryBlue) 
                : _buildEmptyState(context, primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  // --- STATE A: Empty "Post to view" ---
  Widget _buildEmptyState(BuildContext context, Color primaryBlue) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 120), // Space for Nav Bar
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue, width: 2),
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

  // --- STATE B: The Photo Feed ---
  Widget _buildPhotoFeed(Color primaryBlue) {
    // Dummy data for "other people's photos" to mix with yours
    final List<String> dummyImages = [
      "https://placehold.co/400x300/png?text=Beach+Vibes",
      "https://placehold.co/400x300/png?text=Sunset",
      "https://placehold.co/400x300/png?text=Party",
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      // Combine your real photos + dummy photos
      itemCount: GlobalFeedData.posts.length + dummyImages.length,
      itemBuilder: (context, index) {
        ImageProvider imageProvider;
        
        // Logic to show newest first (Your photos at top, dummy at bottom)
        if (index < GlobalFeedData.posts.length) {
          // Your captured photos (Local Files)
          // Reverse index to show newest first
          final path = GlobalFeedData.posts[GlobalFeedData.posts.length - 1 - index];
          imageProvider = FileImage(File(path));
        } else {
          // Dummy photos (Network)
          final dummyIndex = index - GlobalFeedData.posts.length;
          imageProvider = NetworkImage(dummyImages[dummyIndex]);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
            // Optional: Keep blue border if you want consistency
            // border: Border.all(color: primaryBlue, width: 1), 
          ),
        );
      },
    );
  }
}