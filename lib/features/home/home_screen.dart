import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors from your design
    const Color backgroundColor = Color(0xFFF6F9FC);
    const Color primaryBlue = Color(0xFF1269C7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          // Padding matches the 'left: 14' from your raw code
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              // "Hello, Georgios"
              RichText(
                text: TextSpan(
                  style: GoogleFonts.hammersmithOne(
                    fontSize: 24,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(text: 'Hello,\n'),
                    TextSpan(
                      text: 'Georgios',
                      style: GoogleFonts.hammersmithOne(
                        fontSize: 32,
                        fontWeight: FontWeight.w400, // Specified in your code
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              // "Naxos" Title
              Text(
                'Naxos',
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 32,
                ),
              ),

              const SizedBox(height: 10),

              // Optional: Placeholder for the big image shown in raw code (604x340)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  image: const DecorationImage(
                    // Using a placeholder image for Naxos until you add your asset
                    image: NetworkImage("https://placehold.co/600x400/png?text=Naxos+Island"), 
                    fit: BoxFit.cover,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3F000000),
                      blurRadius: 4,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- EVENTS SECTION ---
              Text(
                'Events',
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 15),
              
              // Event Cards
              const _InfoCard(
                title: "Beach Sunset Party",
                subtitle: "Today • Agios Prokopios",
                icon: Icons.beach_access, // Using placeholder icon
              ),
              const SizedBox(height: 10),
              const _InfoCard(
                title: "Panigyri",
                subtitle: "Tomorrow • Chora",
                icon: Icons.music_note,
              ),
              const SizedBox(height: 10),
              const _InfoCard(
                title: "Diving Competition",
                subtitle: "Friday • Agios Prokopios",
                icon: Icons.scuba_diving,
              ),

              const SizedBox(height: 30),

              // --- CHALLENGES SECTION ---
              Text(
                'Challenges',
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 15),

              // Challenge Cards
              const _InfoCard(
                title: "Visit 5 Beaches",
                subtitle: "Progress: 2/5",
                icon: Icons.flag,
              ),
              const SizedBox(height: 10),
              const _InfoCard(
                title: "Photo Collection Master",
                subtitle: "Progress: 12/20",
                icon: Icons.camera_enhance,
              ),
              const SizedBox(height: 10),
              const _InfoCard(
                title: "Taste Local Cuisine",
                subtitle: "Progress: 1/10",
                icon: Icons.restaurant,
              ),

              // Extra space at bottom so the Floating Nav Bar doesn't cover the last item
              const SizedBox(height: 120), 
            ],
          ),
        ),
      ),
    );
  }
}

// --- REUSABLE CARD WIDGET ---
// This replaces that massive block of repeated Stack/Positioned code
class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF1269C7);

    return Container(
      width: double.infinity,
      height: 50, // Matches your raw code height
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Matches your borderRadius: 20
        border: Border.all(color: primaryBlue, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title
          Text(
            title,
            style: GoogleFonts.hammersmithOne(
              color: primaryBlue,
              fontSize: 15,
            ),
          ),
          // Subtitle (Date or Progress)
          Row(
            children: [
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: GoogleFonts.hammersmithOne(
                  color: primaryBlue,
                  fontSize: 12, // Slightly smaller to fit
                ),
              ),
              const SizedBox(width: 8),
              // Placeholder Icon until you fix your assets
              Icon(icon, size: 20, color: primaryBlue),
            ],
          ),
        ],
      ),
    );
  }
}