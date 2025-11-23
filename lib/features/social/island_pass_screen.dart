import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cyclago/features/camera/camera_screen.dart';
// Import your global data
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
    
    // CHECK: Do we have photos?
    bool hasPhotos = GlobalFeedData.posts.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Island Pass', style: GoogleFonts.hammersmithOne(color: Colors.black, fontSize: 24)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: hasPhotos 
        ? _buildPhotoFeed(primaryBlue) // State B: Populated
        : _buildEmptyState(context, primaryBlue), // State A: Empty
    );
  }

  // --- STATE A: The Empty "Post to view" Screen ---
  Widget _buildEmptyState(BuildContext context, Color primaryBlue) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen())),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.camera_alt_rounded, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text("Post to view", style: GoogleFonts.hammersmithOne(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- STATE B: The List of Photos (Your Feed) ---
  Widget _buildPhotoFeed(Color primaryBlue) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120), // Space for Nav Bar
      itemCount: GlobalFeedData.posts.length,
      itemBuilder: (context, index) {
        // Show newest photos at the top (reverse the list)
        final imagePath = GlobalFeedData.posts[GlobalFeedData.posts.length - 1 - index];
        
        return Container(
          margin: const EdgeInsets.all(20),
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: FileImage(File(imagePath)), // Shows the photo you took
              fit: BoxFit.cover,
            ),
            border: Border.all(color: primaryBlue, width: 1),
          ),
        );
      },
    );
  }
}