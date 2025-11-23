import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('My Trip', style: GoogleFonts.hammersmithOne(color: primaryBlue)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      // This ListView contains the 5 cards from your Figma code
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        separatorBuilder: (c, i) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          return SizedBox(
            height: 110, 
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // CARD BODY
                Positioned(
                  top: 30, left: 0, right: 0, bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: primaryBlue, width: 1),
                      boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Placeholder icons until you add your PNGs
                        Icon(Icons.beach_access, color: primaryBlue),
                        Icon(Icons.museum, color: primaryBlue),
                        Icon(Icons.restaurant, color: primaryBlue),
                        Icon(Icons.local_activity, color: primaryBlue),
                      ],
                    ),
                  ),
                ),
                // FLOATING DAY LABEL
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 75, height: 75,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryBlue, width: 1),
                      boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))],
                    ),
                    child: Center(
                      child: Text("Day ${index + 1}", 
                        style: GoogleFonts.hammersmithOne(color: primaryBlue, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}