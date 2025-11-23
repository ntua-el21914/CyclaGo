import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Your specific blue color
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. The Top Header "CyclaGo"
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CyclaGo',
          style: GoogleFonts.hammersmithOne(
            color: primaryBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
              backgroundColor: primaryBlue.withOpacity(0.1),
              child: Icon(Icons.person, color: primaryBlue),
            ),
          )
        ],
      ),
      
      // 2. The List of Cards
      body: ListView.separated(
        padding: const EdgeInsets.only(top: 20, left: 14, right: 14, bottom: 20),
        itemCount: 5, // Shows Day 1 to Day 5
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          // Passing 'index + 1' so it says "Day 1", "Day 2"...
          return FigmaTripCard(dayNumber: index + 1);
        },
      ),
    );
  }
}

// --- YOUR CUSTOM CARD WIDGET ---
// This uses the EXACT code structure you provided
class FigmaTripCard extends StatelessWidget {
  final int dayNumber;
  const FigmaTripCard({super.key, required this.dayNumber});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 384,
      height: 107,
      child: Stack(
        children: [
          // 1. The Main White Card (Bottom Layer)
          Positioned(
            left: 0,
            top: 27,
            child: Container(
              width: 384,
              height: 80,
              clipBehavior: Clip.antiAlias,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 1,
                    color: Color(0xFF1269C7),
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Stack(
                // This stack would hold inner content if needed
                children: [], 
              ),
            ),
          ),

          // 2. Icon Box 1 (Left)
          Positioned(
            left: 24,
            top: 14, // Moved up to overlap slightly like your design
            child: _buildIconContainer(Icons.beach_access),
          ),

          // 3. Icon Box 2 (Middle-Left)
          Positioned(
            left: 89,
            top: 14,
            child: _buildIconContainer(Icons.museum),
          ),

          // 4. Floating "Day X" Circle (Center Top)
          Positioned(
            left: 154,
            top: 0,
            child: Container(
              width: 75,
              height: 75,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 1, // Changed to 1 to match image style
                    color: Color(0xFF1269C7),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                    spreadRadius: 0,
                  )
                ],
              ),
              child: Text(
                "Day $dayNumber",
                style: GoogleFonts.hammersmithOne(
                  color: const Color(0xFF1269C7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          // 5. Icon Box 3 (Middle-Right)
          Positioned(
            left: 244,
            top: 14,
            child: _buildIconContainer(Icons.restaurant),
          ),

          // 6. Icon Box 4 (Right)
          Positioned(
            left: 309,
            top: 14,
            child: _buildIconContainer(Icons.local_activity),
          ),
        ],
      ),
    );
  }

  // Helper function to avoid repeating the Container code 4 times
  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 50,
      height: 50,
      decoration: ShapeDecoration(
        color: Colors.white, // Added white background so it covers the line behind it
        shape: RoundedRectangleBorder(
          // Removed border side to match the "clean" look inside the card, 
          // or add 'side: BorderSide(color: Color(0xFF1269C7))' if you want borders on icons too
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF1269C7),
        size: 24,
      ),
    );
  }
}