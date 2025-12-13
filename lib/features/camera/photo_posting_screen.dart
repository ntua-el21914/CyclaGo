import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'preview_screen.dart'; // Βεβαιώσου ότι κάνεις import το PreviewScreen σου

class VerificationScreen extends StatelessWidget {
  final String imagePath;

  const VerificationScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: Colors.black, // Μαύρο φόντο για να φαίνεται ωραία η φώτο
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Η Φωτογραφία Full Screen
          Image.file(
            File(imagePath),
            fit: BoxFit.cover,
          ),

          // 2. Κουμπί "Πίσω" (Ακύρωση/Retake)
          Positioned(
            top: 50,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ),

          // 3. Κουμπί "Send" (Συνέχεια στο Preview)
          Positioned(
            bottom: 40,
            right: 30,
            child: InkWell(
              onTap: () {
                // REDIRECT ΣΤΟ PREVIEW SCREEN
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PreviewScreen(imagePath: imagePath),
                  ),
                );
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}