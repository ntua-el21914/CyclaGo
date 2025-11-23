import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cyclago/main.dart'; // Import MainScaffold to return home
import 'package:cyclago/core/global_data.dart'; // Import global data to save posts

class PreviewScreen extends StatelessWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    // Colors from your code
    const Color primaryBlue = Color(0xFF1269C7);
    const Color greyBackground = Color(0xFFF6F9FC); // Light grey from your prev screens

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER: "Island Pass" ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'Island Pass',
                  style: GoogleFonts.hammersmithOne(
                    color: Colors.black,
                    fontSize: 32, // Matches your text style
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: primaryBlue),
            const SizedBox(height: 20),

            // --- THE MAIN CARD (Naxos + Image) ---
            // Matches your "Container width: 384, height: 200" logic
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Column(
                    children: [
                      // THE CARD
                      Container(
                        width: double.infinity,
                        // We let height wrap content so it fits the image
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primaryBlue, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header inside card: Icon + "Naxos"
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Circle Icon (Naxos)
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(width: 1, color: Colors.grey),
                                      image: const DecorationImage(
                                        // Use the captured image as the profile icon for now, or a placeholder
                                        image: NetworkImage("https://placehold.co/50x50"), 
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Naxos',
                                    style: GoogleFonts.hammersmithOne(
                                      color: Colors.black,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // THE CAPTURED IMAGE
                            // Matches your 390x200 container, but responsive
                            Container(
                              width: double.infinity,
                              height: 250, // Slightly taller to show the photo well
                              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(File(imagePath)), // Display captured photo
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- BOTTOM INPUT BAR ---
            // Matches your bottom area with the text field and send arrow
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  // Camera Icon Button (Left)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryBlue, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, color: primaryBlue, size: 30),
                  ),
                  const SizedBox(width: 10),

                  // Text Input Field
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Type your message...",
                        style: GoogleFonts.hammersmithOne(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 10),

                  // SEND BUTTON (Blue Arrow)
                  GestureDetector(
                    onTap: () {
                      // 1. INSERT LOGIC HERE: Save the image path to a list
                      // For this demo, we will add it to a global list (see step 2 below)
                      GlobalFeedData.posts.add(imagePath); 

                      // 2. Navigate back to the Main App (Tab 1 will now show the photo)
                      Navigator.pushAndRemoveUntil(
                        context, 
                        MaterialPageRoute(builder: (context) => const MainScaffold()),
                        (route) => false,
                      );
                    },
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF1269C7),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}