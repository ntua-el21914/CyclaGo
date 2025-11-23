import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IslandPassScreen extends StatelessWidget {
  const IslandPassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Island Pass',
          style: GoogleFonts.hammersmithOne(
            color: Colors.black, 
            fontSize: 24, 
            fontWeight: FontWeight.bold
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Container(
          width: double.infinity,
          height: 600, // Or use MediaQuery for full height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryBlue, // The blue border from your image
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // The Camera Icon
              Icon(
                Icons.camera_alt_rounded,
                size: 80,
                color: primaryBlue,
              ),
              const SizedBox(height: 10),
              // The Text
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
        ),
      ),
    );
  }
}